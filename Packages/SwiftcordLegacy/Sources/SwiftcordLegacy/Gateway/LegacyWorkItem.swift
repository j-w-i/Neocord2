import Foundation
import Dispatch

/// Cancellable closure work for the iOS 5 dispatch APIs. Unlike the system
/// DispatchWorkItem this never creates an iOS 8 dispatch_block_t.
public final class LegacyWorkItem {
    private let block: () -> Void
    private let lock = NSLock()
    private var cancelled = false

    public var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    public init(_ block: @escaping () -> Void) {
        self.block = block
    }

    /// Cancellation suppresses work that has not begun, not an executing closure.
    public func perform() {
        guard !isCancelled else { return }
        block()
    }

    public func cancel() {
        lock.lock()
        cancelled = true
        lock.unlock()
    }
}

public extension DispatchQueue {
    func async(execute workItem: LegacyWorkItem) {
        async { workItem.perform() }
    }

    func asyncAfter(deadline: DispatchTime, execute workItem: LegacyWorkItem) {
        asyncAfter(deadline: deadline) { workItem.perform() }
    }
}
