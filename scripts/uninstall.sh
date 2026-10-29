#!/usr/bin/env bash
# Uninstall TermHere and reset everything it left on this Mac:
# Finder extension registrations, Automation (Apple Events) permissions,
# installed AppleScript, extension sandbox container, app preferences,
# and /Applications/TermHere.app.
#
# Usage: scripts/uninstall.sh [-y] [--keep-app] [--dry-run]
#   -y          don't ask for confirmation
#   --keep-app  keep /Applications/TermHere.app (only reset settings)
#   --dry-run   print what would be done without doing it
set -uo pipefail

APP_ID="com.xionggaoli.termhere"
EXT_ID="com.xionggaoli.termhere.FinderExtension"
APP_PATH="/Applications/TermHere.app"

ASSUME_YES=0 KEEP_APP=0 DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    -y|--yes) ASSUME_YES=1 ;;
    --keep-app) KEEP_APP=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

run() {
  echo "+ $*"
  [[ $DRY_RUN == 1 ]] || "$@" || echo "  (ignored: exit $?)"
}

# Every registered copy of the extension (e.g. build/ and /Applications).
EXT_PATHS=()
while IFS= read -r p; do
  [[ -n "$p" ]] && EXT_PATHS+=("$p")
done < <(pluginkit -mAv -i "$EXT_ID" 2>/dev/null | awk -F'\t' '/\.appex$/ {print $NF}')

echo "TermHere uninstall"
echo "  extension registrations: ${#EXT_PATHS[@]}"
for p in "${EXT_PATHS[@]}"; do echo "    $p"; done
[[ $KEEP_APP == 1 ]] || echo "  app: $APP_PATH $([[ -d $APP_PATH ]] && echo '(present)' || echo '(not installed)')"
echo

if [[ $ASSUME_YES == 0 && $DRY_RUN == 0 ]]; then
  read -r -p "Proceed? [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
fi

# Quit the host app if it is running.
run osascript -e "tell application id \"$APP_ID\" to quit" 2>/dev/null

# Disable and unregister the Finder extension.
run pluginkit -e ignore -i "$EXT_ID"
for p in "${EXT_PATHS[@]}"; do
  run pluginkit -r "$p"
done

# Automation permissions ("control iTerm2") for app and extension.
run tccutil reset AppleEvents "$APP_ID"
run tccutil reset AppleEvents "$EXT_ID"

# Installed script, extension sandbox container, app preferences.
run rm -rf "$HOME/Library/Application Scripts/$EXT_ID"
run rm -rf "$HOME/Library/Containers/$EXT_ID"
run defaults delete "$APP_ID"

if [[ $KEEP_APP == 0 && -d "$APP_PATH" ]]; then
  run rm -rf "$APP_PATH"
fi

run killall Finder

echo
echo "Done. Notification permission (if granted) must be removed manually:"
echo "  System Settings → Notifications → TermHere"
