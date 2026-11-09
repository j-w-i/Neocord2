# SwiftcordLegacy provenance

Vendored from the clean canonical repository `/Users/jwalr/Desktop/SwiftcordLegacy`,
commit `923a269c54c7bdc359d64baef3eeb982660529cd`.
Source was copied without `.git`, `.build`, `.swiftpm`, or `.DS_Store`.
The canonical source contains no LICENSE file; existing source notices remain.

Project-local changes include iOS 5 compile adaptations: native Foundation
HTTP backports supplied by the installed custom SDK, local SocketRocket and
NSJSONSerialization-for-Swift package dependencies, legacy dispatch priorities,
a closure-based LegacyWorkItem (public DispatchWorkItem alias retained), and
old-OS UIKit paths where required. The iOS 6 vendor identifier is accessed via
availability-gated NSObject KVC to avoid the custom armv7 compiler's NSUUID
return-ABI crash; iOS 5 uses the existing random UUID fallback. Percent escaping
uses the same native NSString operation as the removed Compat helper; base64
uses the SDK's native Data API. SocketRocket remains the real gateway backend;
no SDK WebSocket implementation or FoundationCompatKit dependency is used.

Gateway lifecycle repair (2026-11-09): capped exponential reconnect backoff,
stop/logout cancellation, stale-socket and generation guards, serialized lifecycle
state, and invalid non-resumable session clearing. TLS/trust settings and endpoint
are unchanged. See Tests/FocusedRetry for runnable policy/cancellation tests.

The upstream Package.resolved remote pins were omitted: both dependencies are
project-owned relative packages. The sibling NSJSONSerialization-for-Swift
package records its own pinned-source provenance.
