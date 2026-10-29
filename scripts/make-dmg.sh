#!/usr/bin/env bash
# Package the notarized build/TermHere.app into a signed, notarized DMG.
# Prerequisites: scripts/build.sh && scripts/notarize.sh have succeeded.
# Usage: scripts/make-dmg.sh   (set SKIP_NOTARIZE=1 to only build + sign)
set -euo pipefail
cd "$(dirname "$0")/.."

PROFILE="${NOTARY_PROFILE:-TermHere-notary}"
IDENTITY="Developer ID Application: XIONGGAO LI (Z8NL57N2AP)"
APP="build/TermHere.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")"
DMG="build/TermHere-$VERSION.dmg"
STAGING="build/dmg-staging"

xcrun stapler validate "$APP" >/dev/null || { echo "error: $APP is not notarized/stapled; run scripts/notarize.sh first" >&2; exit 1; }

rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"
ditto "$APP" "$STAGING/TermHere.app"
ln -s /Applications "$STAGING/Applications"

hdiutil create -volname "TermHere $VERSION" -srcfolder "$STAGING" -fs HFS+ -format UDZO -ov "$DMG"
rm -rf "$STAGING"

codesign --force --timestamp --sign "$IDENTITY" "$DMG"
codesign --verify --strict "$DMG"

if [[ "${SKIP_NOTARIZE:-0}" != "1" ]]; then
  xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait
  xcrun stapler staple "$DMG"
  xcrun stapler validate "$DMG"
  spctl -a -vvv -t open --context context:primary-signature "$DMG"
fi

echo "Built: $DMG"
