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
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>com.codemate.app.oauth</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>codemate</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
PLIST_EOF

# Plain ad-hoc signing (no real certificate, no hardened runtime) -- fine
# for local testing of everything EXCEPT Sign in with Apple. Do not add
# --options runtime / --entitlements here: macOS's code-integrity checks
# (AMFI) outright SIGKILL an ad-hoc-signed process at launch if it claims
# the com.apple.developer.applesignin entitlement without a real Apple-
# issued signing chain to back it up -- confirmed while building this (exit
# 137). That entitlement only belongs in Scripts/notarize.sh's real,
# Developer-ID-signed build.
#
# To test Sign in with Apple before you've done Apple Developer Portal
# setup + gotten a Developer ID certificate: open Package.swift in Xcode
# and run from there instead. Xcode can provision a development
# certificate + entitlement automatically while you're signed into your
# Apple ID in Xcode's own settings, which this shell script can't
# replicate. Google sign-in needs a real OAuth client ID either way
# (AuthManager.swift) regardless of how you build.
codesign --force --deep --sign - "$APP" 2>/dev/null || true

echo "Built $APP"
echo "Launch with: open $APP"
