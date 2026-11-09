import Foundation

/// Pure state machine; its owner must serialize every access (Gateway uses its
/// lifecycleLock). Tickets make cancellation safe even after a work item starts.
struct GatewayRetryPolicy {
    struct Retry {
        let ticket: UInt64
        let delay: TimeInterval
    }

    private(set) var isRunning = false
    private(set) var generation: UInt64 = 0
    private(set) var pendingTicket: UInt64?
    private var nextDelay: TimeInterval
    private let initialDelay: TimeInterval
    private let maximumDelay: TimeInterval

    init(initialDelay: TimeInterval = 1, maximumDelay: TimeInterval = 30) {
        precondition(initialDelay > 0 && initialDelay.isFinite)
        precondition(maximumDelay >= initialDelay && maximumDelay.isFinite)
        self.initialDelay = initialDelay
        self.maximumDelay = maximumDelay
        self.nextDelay = initialDelay
    }

    /// Explicit start is idempotent, including while a retry is pending.
    mutating func start() -> Bool {
        guard !isRunning else { return false }
        isRunning = true
        generation &+= 1
        nextDelay = initialDelay
        return true
    }

    mutating func stop() {
        isRunning = false
        pendingTicket = nil
        generation &+= 1
        nextDelay = initialDelay
    }

    mutating func scheduleRetry() -> Retry? {
        guard isRunning, pendingTicket == nil else { return nil }
        generation &+= 1
        pendingTicket = generation
        let retry = Retry(ticket: generation, delay: nextDelay)
        nextDelay = min(maximumDelay, nextDelay * 2)
        return retry
    }

    mutating func consumeRetry(ticket: UInt64) -> Bool {
        guard isRunning, pendingTicket == ticket else { return false }
        pendingTicket = nil
        generation &+= 1
        return true
    }

    /// Reset only after authenticated READY/RESUMED, never just TCP/WebSocket open.
    mutating func authenticated() {
        guard isRunning, pendingTicket == nil else { return }
        nextDelay = initialDelay
    }
}
