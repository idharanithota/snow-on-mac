#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
app="build/SnowOnMac.app"
mkdir -p "$app/Contents/MacOS" build/module-cache
xcrun swiftc Sources/SnowOnMac/*.swift -swift-version 5 -O \
  -target "$(uname -m)-apple-macosx13.0" \
  -module-cache-path build/module-cache \
  -o "$app/Contents/MacOS/SnowOnMac" -framework Cocoa -framework CoreGraphics
cp Resources/Info.plist "$app/Contents/Info.plist"
codesign --force --sign - "$app"
printf 'Built %s\n' "$app"
