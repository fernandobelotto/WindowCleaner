#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
output="$(mktemp -d)"
trap 'rm -rf "$output"' EXIT
xcrun swiftc -swift-version 6 WindowCleaner/Updates/PrivateUpdateTransport.swift WindowCleaner/Updates/PrivateUpdateAccess.swift Tests/Updater/TransportFixtures.swift -o "$output/transport-tests"
"$output/transport-tests"
