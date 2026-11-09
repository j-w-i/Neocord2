# Focused gateway retry tests

From the SwiftcordLegacy package directory:

```sh
bash Tests/FocusedRetry/run.sh
```

Requires a host Swift compiler and Foundation/Dispatch. Compiles only
`GatewayRetryPolicy.swift`, the existing `LegacyWorkItem.swift`, and the standalone
`main.swift`; no package dependency resolution, UIKit, socket connection, device
call, or whole-app build. Prints a temporary output directory and a PASS count.

Coverage includes 1/2/4/8/16/30-second capped growth, long offline runs, one pending
retry, idempotent start, one-use/stale tickets, authenticated reset, stop/restart,
legacy cancellation, already-executing cancellation races, stale socket identity,
and concurrent duplicate failure callbacks. The lifecycle harness mirrors
Gateway's lock/ticket/identity integration; it is not a SocketRocket integration
test. The production policy and LegacyWorkItem are compiled directly.

Gateway lifecycle rules:

- `NSRecursiveLock` serializes socket identity checks, retry policy, socket
  open/close, heartbeat state, identify state, and queued sends. Socket callbacks
  validate identity inside the lock; queued payloads validate when consumed.
- Stop invalidates the retry ticket and clears socket identity before closing.
  LegacyWorkItem cancellation is supplementary: a started closure must also pass
  the ticket check under the lock before opening a socket.
- All retries (failure, close, server request, missed ACK) use one policy. Backoff
  resets on authenticated READY/RESUMED, not a transport open, preventing an
  open/fail loop from resetting to the smallest delay.
- Timers, delayed identifies, queued sends, and reconnect notifications reject
  old generations/sockets. The lock must never be held while synchronously
  dispatching to another queue. Callback users should not synchronously wait on
  another thread that is entering the gateway.

Not covered: real SocketRocket callbacks, TLS, iOS 5 runtime/link availability,
network reachability, Discord protocol integration, app build, and the client's
pre-existing asynchronous READY parsing/model mutations outside Gateway. TLS
configuration is unchanged. Backoff is deterministic (no jitter).
