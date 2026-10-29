#!/usr/bin/env bash
# Notarize and staple build/TermHere.app.
# One-time setup:
#   xcrun notarytool store-credentials "TermHere-notary" --apple-id <id> --team-id Z8NL57N2AP
set -euo pipefail
cd "$(dirname "$0")/.."

PROFILE="${NOTARY_PROFILE:-TermHere-notary}"
APP="build/TermHere.app"
ZIP="build/TermHere.zip"

ditto -c -k --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
