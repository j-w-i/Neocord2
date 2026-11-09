#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# No package/app build: compile only the Foundation policy, legacy dispatch
# compatibility shim and standalone test entry point. Keep output out of repo.
OUT="$(mktemp -d "${TMPDIR:-/tmp}/swiftcord-retry.XXXXXX")"
printf 'Focused test output directory: %s\n' "$OUT"
swiftc -swift-version 5 \
  "$ROOT/Sources/SwiftcordLegacy/Gateway/GatewayRetryPolicy.swift" \
  "$ROOT/Sources/SwiftcordLegacy/Gateway/LegacyWorkItem.swift" \
  "$ROOT/Tests/FocusedRetry/main.swift" \
  -o "$OUT/retry-tests"
"$OUT/retry-tests"
