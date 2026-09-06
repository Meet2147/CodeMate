#!/bin/bash
# Signs, notarizes, and staples CodeMate.app for direct (outside the Mac
# App Store) distribution. Run this instead of build_app.sh's ad-hoc
# `codesign --sign -` once you're ready to actually hand the .app to
# someone else -- an unsigned/ad-hoc-signed or un-notarized build will be
# blocked or scare-screened by Gatekeeper on any other Mac.
#
# ONE-TIME SETUP (all done at developer.apple.com / in Keychain Access):
#   1. Enroll in the Apple Developer Program ($99/yr) if you haven't.
#   2. Create a "Developer ID Application" certificate (Certificates,
#      Identifiers & Profiles > Certificates) and let it install into your
#      login keychain.
#   3. Create an app-specific password for notarization:
#      `xcrun notarytool store-credentials "codemate"
#         --apple-id "you@example.com" --team-id TEAMID --password "app-specific-password"`
#      (generate the app-specific password at appleid.apple.com; TEAMID is
#      on the Membership page of developer.apple.com)
#
# Usage: ./Scripts/notarize.sh "Developer ID Application: Your Name (TEAMID)"
set -euo pipefail
cd "$(dirname "$0")/.."

SIGNING_IDENTITY="${1:?Usage: Scripts/notarize.sh \"Developer ID Application: Your Name (TEAMID)\"}"
APP="build/CodeMate.app"
ZIP="build/CodeMate.zip"

[ -d "$APP" ] || { echo "Run Scripts/build_app.sh first."; exit 1; }

echo "Codesigning with entitlements..."
codesign --force --deep --options runtime \
  --entitlements CodeMate.entitlements \
  --sign "$SIGNING_IDENTITY" "$APP"

echo "Verifying signature..."
codesign --verify --deep --strict --verbose=2 "$APP"

echo "Zipping for notarization..."
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "Submitting to Apple's notary service (this can take a few minutes)..."
xcrun notarytool submit "$ZIP" --keychain-profile "codemate" --wait

echo "Stapling the notarization ticket..."
xcrun stapler staple "$APP"

echo "Done. Verify with: spctl -a -vvv -t install \"$APP\""
echo "Distribute the .app (zipped or in a .dmg) -- it will open without a Gatekeeper warning."
