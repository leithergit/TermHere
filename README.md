# TermHere

English | [简体中文](README.zh-CN.md)

Right-click anywhere in Finder — on empty space, a folder, or a file — and open that location in **iTerm2**:

- **New iTerm2 Window Here**
- **New iTerm2 Tab Here**

| Where you right-click | Opens in |
|---|---|
| Empty space in a Finder window | The folder that window is showing |
| A folder | That folder |
| A file | The folder containing the file |
| Several items | The first selected item (rules above) |

If iTerm2 isn't running, it is launched and its startup window is reused (no stray empty window). If there is no iTerm2 window, "Tab Here" opens a new window instead.

## Requirements

- macOS 13 or later
- [iTerm2](https://iterm2.com) installed

## Install

1. Open `TermHere-<version>.dmg` and drag **TermHere** into **Applications**.
2. Launch **TermHere** from Applications once. It installs the helper script that drives iTerm2.
3. Click **Open Extension Settings** and enable **TermHere** under *System Settings → General → Login Items & Extensions → Finder*.
4. Click **Test: open iTerm2 tab in ~** and choose **Allow** when macOS asks to let TermHere control iTerm2.
5. Right-click in Finder and pick **New iTerm2 Window Here** or **New iTerm2 Tab Here**. The first time, macOS asks again to allow the *Finder extension* to control iTerm2. This is a separate permission from step 4, so allow it too.

After setup you don't need to keep TermHere open; the Finder extension runs on its own.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Menu items don't appear | Make sure the extension is enabled (step 3), then run `killall Finder`. |
| Menu items appear twice | Two copies of the extension are registered, e.g. one in a build folder. Run `scripts/uninstall.sh`, then reinstall from the DMG. |
| Nothing happens on click | Allow Automation under *System Settings → Privacy & Security → Automation → TermHere → iTerm*. Then click **Reinstall** in the TermHere app. |
| A notification says TermHere failed | Open the TermHere app. The status section and **Test** button show the cause. |
| Menu or extension missing from System Settings | Make sure you launch TermHere from Applications, not from the DMG or a build folder. Quit any other copies, then open `/Applications/TermHere.app` once. |

To see logs, run `log stream --predicate 'subsystem BEGINSWITH "com.xionggaoli.termhere"'`.

## Uninstall

```bash
scripts/uninstall.sh             # asks for confirmation
scripts/uninstall.sh -y          # no prompt
scripts/uninstall.sh --keep-app  # reset settings, keep the app
scripts/uninstall.sh --dry-run   # show what would be done
```

The script unregisters every copy of the extension and resets the Automation permissions. It removes the installed script, the sandbox container, and preferences, deletes `/Applications/TermHere.app`, and restarts Finder. You have to remove the notification permission yourself in *System Settings → Notifications*.

## How it works

Finder only lets a **Finder Sync extension** add items to the right-click menu on empty space; Quick Actions and Services don't appear there. The extension is sandboxed, so it can't script iTerm2 directly. Instead it runs `TermHere.scpt` through `NSUserAppleScriptTask` from `~/Library/Application Scripts/com.xionggaoli.termhere.FinderExtension/`, and the host app installs the script there. The script opens a window or tab and runs `cd '<path>' && clear`. The path is shell-escaped, so spaces, quotes, and non-ASCII names are safe.

```
App/                   host app (SwiftUI, setup UI, installs the script)
  Resources/TermHere.applescript
FinderExtension/       Finder Sync extension (sandboxed)
Packages/TermHereCore/ pure logic: target resolution, shell escaping, Apple Event building (unit-tested)
scripts/               build, notarize, DMG, icon, uninstall
docs/                  design and manual acceptance checklist
```

## Building from source

Requires Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```bash
cd Packages/TermHereCore && swift test && cd -   # unit tests
scripts/build.sh                                  # → build/TermHere.app (Release, Developer ID signed)
scripts/notarize.sh                               # notarize + staple the app
scripts/make-dmg.sh                               # → build/TermHere-<version>.dmg (signed, notarized)
swift scripts/make-icon.swift                     # regenerate the app icon
```

Before notarizing for the first time, store your credentials in the keychain:

```bash
xcrun notarytool store-credentials TermHere-notary \
  --key /path/to/AuthKey_XXXXXXXXXX.p8 --key-id XXXXXXXXXX --issuer <Issuer ID>
# or: --apple-id <Apple ID> --team-id <Team ID>  (with an app-specific password)
```

Signing uses Team `Z8NL57N2AP` and the bundle ID `com.xionggaoli.termhere`. Change them in `project.yml` and the scripts if you build under your own account.

Don't open the app directly from `build/` for day-to-day use. macOS registers the extension at that path, and you end up with duplicate menu items once you also install a copy in Applications.
