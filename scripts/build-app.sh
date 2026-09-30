#!/usr/bin/env bash
# Builds build/EyeYoga.app from the SwiftPM executable; no Xcode needed.
set -euo pipefail

cd "$(dirname "$0")/.."
swift build -c release
bin="$(swift build -c release --show-bin-path)/EyeYoga"

app=build/EyeYoga.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin" "$app/Contents/MacOS/EyeYoga"
cp Resources/PressStart2P-Regular.ttf Resources/OFL.txt "$app/Contents/Resources/"

cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key><string>at.herofresh.eyeyoga</string>
    <key>CFBundleExecutable</key><string>EyeYoga</string>
    <key>CFBundleName</key><string>Eye Yoga</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$app"
echo "Built $app"
