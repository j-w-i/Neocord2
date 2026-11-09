import Foundation

class Bucket {
    private let limit: Int
    private let interval: TimeInterval
    private var queueItems: [DispatchWorkItem] = []
    private var counter = 0
    private let queue = DispatchQueue(label: "gateway.bucket.queue")
    
    // This version tracks a generation to discard old items on reconnect
    private var generation = 0
    
    init(limit: Int, interval: TimeInterval) {
        self.limit = limit
        self.interval = interval
    }
    
    func queue(_ item: DispatchWorkItem) {
        queue.async {
            let itemGeneration = self.generation
            self.queueItems.append(item)
            self.processQueue(for: itemGeneration)
        }
    }
    
    private func processQueue(for itemGeneration: Int) {
        // A stale callback owns neither the current capacity nor queued work.
        guard itemGeneration == generation else { return }
        guard !queueItems.isEmpty else { return }
        guard counter < limit else { return }
        
        counter += 1
        let item = queueItems.removeFirst()
        item.perform()
        
        queue.asyncAfter(deadline: .now() + interval) {
            guard itemGeneration == self.generation else { return }
            self.counter -= 1
            self.processQueue(for: itemGeneration)
        }
    }
    
    // Call this on reconnect
    func reset() {
        queue.async {
            self.queueItems.removeAll()
            self.counter = 0
            self.generation += 1 // increment generation so old items are ignored
        }
    }
}

