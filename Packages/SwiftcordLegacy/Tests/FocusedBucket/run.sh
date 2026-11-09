#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# Compile production sources directly, retaining the iOS 5 LegacyWorkItem alias.
# No package resolution, UIKit/SocketRocket dependency, or app build.
OUT="$(mktemp -d "${TMPDIR:-/tmp}/swiftcord-bucket.XXXXXX")"
printf 'Focused test output directory: %s\n' "$OUT"
swiftc -swift-version 5 \
  "${BUCKET_SOURCE:-$ROOT/Sources/SwiftcordLegacy/Gateway/Bucket.swift}" \
  "$ROOT/Sources/SwiftcordLegacy/Gateway/LegacyWorkItem.swift" \
  "$ROOT/Tests/FocusedBucket/main.swift" \
  -o "$OUT/bucket-tests"
"$OUT/bucket-tests" "$@"
