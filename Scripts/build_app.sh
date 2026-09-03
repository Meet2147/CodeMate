#!/bin/bash
# Builds CodeMate.app as a real macOS app bundle (icon, Info.plist) from the
# Swift package, for local testing outside Xcode. For App Store / notarized
# distribution, use Xcode's own archive flow instead (open Package.swift).
set -euo pipefail
cd "$(dirname "$0")/.."

echo "Building (debug)..."
swift build

APP="build/CodeMate.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp .build/debug/CodeMate "$APP/Contents/MacOS/CodeMate"
cp Marketing/icon/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>CodeMate</string>
    <key>CFBundleDisplayName</key>
    <string>CodeMate</string>
    <key>CFBundleIdentifier</key>
    <string>com.codemate.app</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>CodeMate</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.education</string>
</dict>
</plist>
PLIST_EOF

echo "Built $APP"
echo "Launch with: open $APP"
