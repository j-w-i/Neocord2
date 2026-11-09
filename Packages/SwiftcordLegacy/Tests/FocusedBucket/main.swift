import Foundation
import Dispatch

// Match Gateway.swift without compiling UIKit/SocketRocket or the whole app.
public typealias DispatchWorkItem = LegacyWorkItem

private let interval: TimeInterval = 0.16
private let tolerance: TimeInterval = 0.015

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

private func wait(_ semaphore: DispatchSemaphore, _ message: String) {
    expect(semaphore.wait(timeout: .now() + 3) == .success, message)
}

// A bounded semaphore wait, not a busy loop, lets dispatch timers become due.
private func elapse(_ duration: TimeInterval) {
    let timer = DispatchSemaphore(value: 0)
    DispatchQueue.global().asyncAfter(deadline: .now() + duration) { timer.signal() }
    wait(timer, "timing checkpoint completed")
}

private final class Record {
    private let lock = NSLock()
    private var entries: [(Int, TimeInterval)] = []
    let completed = DispatchSemaphore(value: 0)

    func append(_ id: Int) {
        lock.lock()
        entries.append((id, ProcessInfo.processInfo.systemUptime))
        lock.unlock()
        completed.signal()
    }

    func snapshot() -> [(Int, TimeInterval)] {
        lock.lock()
        defer { lock.unlock() }
        return entries
    }
}

private func testCurrentRateLimit() {
    let bucket = Bucket(limit: 2, interval: interval)
    let record = Record()
    for id in 0..<5 {
        bucket.queue(DispatchWorkItem { record.append(id) })
    }
    for _ in 0..<5 { wait(record.completed, "current queued item was not dropped") }
    let entries = record.snapshot()
    expect(entries.map { $0.0 } == Array(0..<5), "current work executes exactly once in FIFO order")
    for index in 2..<5 {
        expect(entries[index].1 - entries[index - 2].1 >= interval - tolerance,
               "current generation respects the two-item interval limit")
    }
    print("PASS: current generation rate limit and FIFO")
}

private func testResetWithPendingOldReplenishment() {
    let bucket = Bucket(limit: 2, interval: interval)
    let oldStarted = DispatchSemaphore(value: 0)
    let blockerStarted = DispatchSemaphore(value: 0)
    let releaseBlocker = DispatchSemaphore(value: 0)
    let record = Record()

    bucket.queue(DispatchWorkItem { oldStarted.signal() })
    wait(oldStarted, "old item started")
    // This second old item holds the serial queue while the FIRST item's
    // replenishment becomes due. Its own replenishment is not scheduled yet.
    bucket.queue(DispatchWorkItem {
        blockerStarted.signal()
        wait(releaseBlocker, "test released old blocking item")
    })
    wait(blockerStarted, "old blocking item started")
    bucket.queue(DispatchWorkItem { record.append(-1) }) // reset must discard this
    bucket.reset()
    for id in 0..<5 {
        bucket.queue(DispatchWorkItem { record.append(id) })
    }
    // reset and current submissions are enqueued BEFORE the stale callback.
    // Holding the serial queue until the timer is due makes this ordering
    // independent of how quickly the host happens to run the test process.
    elapse(interval * 2)
    releaseBlocker.signal()

    for _ in 0..<5 { wait(record.completed, "reset did not drop current queued work") }
    let entries = record.snapshot()
    expect(entries.map { $0.0 } == Array(0..<5), "only old pending work is discarded on reset")
    for index in 2..<5 {
        expect(entries[index].1 - entries[index - 2].1 >= interval - tolerance,
               "stale replenishment cannot release current capacity early")
    }
    elapse(interval * 2)
    expect(record.snapshot().count == 5, "no duplicate or old queued work after reset")
    print("PASS: due old replenishments are no-ops; current work survives reset")
}

private func testResetEmptyGenerationCannotCreateNegativeCapacity() {
    let bucket = Bucket(limit: 1, interval: interval)
    let oldStarted = DispatchSemaphore(value: 0)
    let record = Record()
    bucket.queue(DispatchWorkItem { oldStarted.signal() })
    wait(oldStarted, "old item started before empty reset")
    bucket.reset()
    bucket.reset() // multiple resets must also invalidate the same old timer
    elapse(interval * 2)
    // If the stale timer decremented zero to -1, two items would now run
    // immediately, observably violating a limit of one.
    for id in 0..<3 {
        bucket.queue(DispatchWorkItem { record.append(id) })
    }
    for _ in 0..<3 { wait(record.completed, "post-empty-reset item executed") }
    let entries = record.snapshot()
    expect(entries.map { $0.0 } == Array(0..<3), "empty resets preserve current FIFO work")
    for index in 1..<3 {
        expect(entries[index].1 - entries[index - 1].1 >= interval - tolerance,
               "old timers cannot make the counter negative or grant extra capacity")
    }
    print("PASS: empty and repeated resets cannot create negative capacity")
}

switch CommandLine.arguments.dropFirst().first {
case "--pending-reset":
    testResetWithPendingOldReplenishment()
case "--empty-reset":
    testResetEmptyGenerationCannotCreateNegativeCapacity()
default:
    testCurrentRateLimit()
    testResetWithPendingOldReplenishment()
    testResetEmptyGenerationCannotCreateNegativeCapacity()
}
print("All selected focused Bucket tests passed")
