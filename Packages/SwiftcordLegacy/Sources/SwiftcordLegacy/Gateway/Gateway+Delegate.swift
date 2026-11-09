import Foundation
import SocketRocket

// MARK: - SRWebSocketDelegate
extension Gateway: SRWebSocketDelegate {
    public func webSocketDidOpen(_ webSocket: SRWebSocket!) {
        withLifecycleLock {
            guard isCurrentSocket(webSocket) else { return }
            isConnected = true
            // Keep resume intent and failure count until authenticated READY/RESUMED.
            print("[Gateway] ✅ Connected")
        }
    }

    public func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
        guard let text = message as? String else { return }
        payloadQueue.async { [weak self, weak webSocket] in
            guard let self = self else { return }
            self.withLifecycleLock {
                // Validate at consumption time, not only when queued: stop or a
                // replacement socket may have overtaken this payload.
                guard self.isCurrentSocket(webSocket) else { return }
                self.handlePayload(Payload(with: text))
            }
        }
    }

    public func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        withLifecycleLock {
            guard isCurrentSocket(webSocket) else { return }
            isConnected = false
            let description = error?.localizedDescription ?? "unknown error"
            print("[Gateway] ❌ Connection failed:", description)
            if description.contains("4004") {
                stop()
                onInvalidToken?()
            } else {
                reconnect()
            }
        }
    }

    public func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        withLifecycleLock {
            guard isCurrentSocket(webSocket) else { return }
            print("[Gateway] 🔴 Closed with code \(code), reason: \(reason ?? "none")")
            if code == 4004 {
                stop()
                onInvalidToken?()
            } else {
                reconnect()
            }
        }
    }
}
