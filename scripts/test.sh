#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/module-cache
xcrun swiftc Sources/SnowOnMac/SnowWorld.swift Tests/main.swift \
  -swift-version 5 -Onone -module-cache-path build/module-cache \
  -o build/SnowTests -framework Cocoa -framework CoreGraphics
./build/SnowTests
