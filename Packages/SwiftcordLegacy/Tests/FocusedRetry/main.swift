import Foundation
import Dispatch

// Run with Tests/FocusedRetry/run.sh; no UIKit, SocketRocket, network or app build.
var checks = 0
func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    checks += 1
    precondition(condition(), message)
}

var policy = GatewayRetryPolicy()
expect(policy.scheduleRetry() == nil, "stopped policy must not retry")
expect(policy.start(), "initial start")
expect(!policy.start(), "start is idempotent")
var expected: [TimeInterval] = [1, 2, 4, 8, 16, 30, 30, 30]
for delay in expected {
    let retry = policy.scheduleRetry()!
    expect(retry.delay == delay, "capped exponential delay")
    expect(policy.scheduleRetry() == nil, "only one pending retry")
    expect(!policy.start(), "start must not bypass pending delay")
    expect(!policy.consumeRetry(ticket: retry.ticket &+ 1), "wrong ticket ignored")
    expect(policy.consumeRetry(ticket: retry.ticket), "current ticket executes")
    expect(!policy.consumeRetry(ticket: retry.ticket), "ticket executes only once")
}
policy.authenticated()
let resetRetry = policy.scheduleRetry()!
expect(resetRetry.delay == 1, "authenticated session resets backoff")
policy.stop()
expect(!policy.consumeRetry(ticket: resetRetry.ticket), "stop cancels pending ticket")
expect(policy.scheduleRetry() == nil, "logout cannot retry")
expect(policy.start(), "explicit restart allowed")
let replacementRetry = policy.scheduleRetry()!
expect(replacementRetry.delay == 1, "explicit start resets backoff")
expect(!policy.consumeRetry(ticket: resetRetry.ticket), "old ticket cannot consume replacement")
expect(policy.pendingTicket == replacementRetry.ticket, "old work preserves replacement")
expect(policy.consumeRetry(ticket: replacementRetry.ticket), "replacement still executes")

// Stress cap arithmetic over a long offline period without sleeping.
for _ in 0..<10000 {
    let retry = policy.scheduleRetry()!
    expect(retry.delay >= 1 && retry.delay <= 30, "retry delay remains bounded")
    expect(policy.consumeRetry(ticket: retry.ticket), "consume offline retry")
}

// Model the exact lock/ticket ownership used by Gateway. The identity token
// stands in for SRWebSocket; stale callbacks must not mutate the new attempt.
final class LifecycleHarness {
    let lock = NSRecursiveLock()
    var policy = GatewayRetryPolicy()
    var item: LegacyWorkItem?
    var socket: NSObject?
    var opens = 0
    var acceptedCallbacks = 0

    func locked<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
    func start() {
        locked {
            guard policy.start() else { return }
            socket = NSObject()
            opens += 1
        }
    }
    func fail(socket oldSocket: NSObject) {
        locked {
            guard policy.isRunning, socket === oldSocket,
                  let retry = policy.scheduleRetry() else { return }
            socket = nil
            item = LegacyWorkItem { [weak self] in
                guard let self = self else { return }
                self.locked {
                    guard self.policy.consumeRetry(ticket: retry.ticket) else { return }
                    self.item = nil
                    self.socket = NSObject()
                    self.opens += 1
                }
            }
        }
    }
    func stop() {
        locked {
            policy.stop()
            item?.cancel()
            item = nil
            socket = nil
        }
    }
    func callback(socket oldSocket: NSObject) {
        locked {
            guard policy.isRunning, socket === oldSocket else { return }
            acceptedCallbacks += 1
        }
    }
}
let lifecycle = LifecycleHarness()
lifecycle.start()
let oldSocket = lifecycle.socket!
lifecycle.fail(socket: oldSocket)
let pending = lifecycle.item!
lifecycle.fail(socket: oldSocket)
expect(lifecycle.item === pending, "duplicate failure does not replace pending retry")
expect(lifecycle.opens == 1, "failure does not immediately open another socket")
pending.perform()
expect(lifecycle.opens == 2, "one retry opens one socket")
lifecycle.callback(socket: oldSocket)
expect(lifecycle.acceptedCallbacks == 0, "old socket callback ignored")
lifecycle.callback(socket: lifecycle.socket!)
expect(lifecycle.acceptedCallbacks == 1, "current socket callback accepted")
lifecycle.fail(socket: lifecycle.socket!)
let cancelled = lifecycle.item!
lifecycle.stop()
cancelled.perform()
expect(lifecycle.opens == 2, "cancelled LegacyWorkItem does not reopen")

// A work item may already be executing when stop wins the lock. Tickets must
// still reject it; LegacyWorkItem cancellation alone cannot guarantee this.
var racingPolicy = GatewayRetryPolicy()
_ = racingPolicy.start()
let racingTicket = racingPolicy.scheduleRetry()!.ticket
let raceLock = NSRecursiveLock()
let began = DispatchSemaphore(value: 0)
let proceed = DispatchSemaphore(value: 0)
let finished = DispatchSemaphore(value: 0)
var reopened = false
let executing = LegacyWorkItem {
    began.signal()
    proceed.wait()
    raceLock.lock()
    reopened = racingPolicy.consumeRetry(ticket: racingTicket)
    raceLock.unlock()
    finished.signal()
}
DispatchQueue.global().async { executing.perform() }
expect(began.wait(timeout: .now() + 5) == .success, "work item began")
raceLock.lock()
racingPolicy.stop()
executing.cancel()
raceLock.unlock()
proceed.signal()
expect(finished.wait(timeout: .now() + 5) == .success, "work item completed")
expect(!reopened, "already executing item cannot reopen after stop")

// Concurrent duplicate failure callbacks serialize to a single retry ticket.
for _ in 0..<100 {
    let concurrent = LifecycleHarness()
    concurrent.start()
    let socket = concurrent.socket!
    DispatchQueue.concurrentPerform(iterations: 32) { _ in
        concurrent.fail(socket: socket)
    }
    expect(concurrent.opens == 1, "concurrent failures do not immediately reconnect")
    expect(concurrent.item != nil, "one pending retry remains")
    concurrent.item!.perform()
    expect(concurrent.opens == 2, "concurrent failures create just one reconnect")
    concurrent.stop()
}
print("PASS: \(checks) focused reconnect checks")
