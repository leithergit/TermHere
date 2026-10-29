# TermHere — Finder 右键「New iTerm2 Window/Tab Here」

> 来源：2026-10-28 grilling 会话，全部决策已与用户确认（Q1–Q15）。

## 1. 目标

在 Finder 任意目录的空白处右键（以及选中文件/文件夹右键）时，菜单中出现：

- **New iTerm2 Window Here**
- **New iTerm2 Tab Here**

点击后在 iTerm2 中打开新窗口/标签页并 `cd` 到目标目录。

## 2. 关键决策

| # | 决策 |
|---|---|
| Q1 | 采用 Finder Sync Extension（唯一能在空白处右键加菜单的方案），Swift 实现，监控 `/` |
| Q2 | 两项都要，一级菜单，英文标题 |
| Q3 | 选中项也显示：文件夹→该文件夹；文件→父目录；多选→取第一个 |
| Q4 | 扩展通过 `NSUserAppleScriptTask` 调用宿主安装的 `.scpt` 驱动 iTerm2 |
| Q5 | `write text "cd '<转义路径>' && clear"` |
| Q6 | Tab 模式下 iTerm2 未运行/无窗口 → 回退为窗口；冷启动时复用启动窗口，不留多余空窗 |
| Q7 | 先自用，但签名按 Developer ID + 公证配置好 |
| Q8 | 宿主 App：非沙盒、普通单窗口引导 App（扩展状态、脚本安装、测试按钮），无菜单栏/自启 |
| Q9 | Bundle ID `com.xionggaoli.termhere` / `com.xionggaoli.termhere.FinderExtension`，Team `Z8NL57N2AP` |
| Q10 | 最低 macOS 13 |
| Q11 | 菜单项带 iTerm2 图标（运行时读取，失败则无图标）；不做工具栏按钮 |
| Q12 | XcodeGen 管理工程（`.xcodeproj` 不入库）；纯逻辑抽成本地 Swift Package，TDD |
| Q13 | 轻量流程：本文档 → developer → tester → DEVLOG；分支 `feat/finder-sync` |
| Q14 | 错误：`os_log` + 系统通知（尽力而为，未授权则仅日志） |
| Q15 | 打开后 iTerm2 `activate`；App 图标先用简单生成图标 |

## 3. 结构

```
TermHere/
├── project.yml                     # XcodeGen
├── Packages/TermHereCore/          # 本地 SwiftPM，纯逻辑，`swift test` 可跑
│   ├── Sources/TermHereCore/
│   │   ├── OpenMode.swift          # enum OpenMode { window, tab }
│   │   ├── TargetResolver.swift    # 目标目录解析
│   │   ├── ShellEscaper.swift      # 单引号转义
│   │   └── ScriptInvocation.swift  # 生成 cd 命令 + NSAppleEventDescriptor
│   └── Tests/TermHereCoreTests/
├── App/                            # 宿主 App（SwiftUI，非沙盒）
│   └── Resources/TermHere.applescript
├── FinderExtension/                # Finder Sync 扩展（沙盒）
├── scripts/build.sh                # xcodegen + xcodebuild Release
├── scripts/notarize.sh             # notarytool（keychain profile 占位）
└── docs/acceptance.md              # 手工验收清单
```

## 4. 数据流

```
Finder 右键 → FinderSync.menu(for: kind)
   kind ∈ {.contextualMenuForContainer, .contextualMenuForItems}，其它返回 nil
   菜单项 tag 编码 mode
点击 → action(sender)
   targetedURL / selectedItemURLs → TargetResolver → 目录 URL
   ScriptInvocation.command(for: dir)  →  "cd '<escaped>' && clear"
   ScriptInvocation.event(handler: mode, command:) → NSAppleEventDescriptor
   NSUserAppleScriptTask(url: ~/Library/Application Scripts/<extID>/TermHere.scpt).execute(withAppleEvent:)
   失败 → os_log + UNUserNotification（尽力）
```

## 5. TermHereCore 接口

```swift
public enum OpenMode: Int { case window = 1, tab = 2
    public var handlerName: String { "openwindow" / "opentab" } }   // AppleScript 子程序名（小写）

public enum MenuContext { case container, items }

public enum TargetResolver {
    /// container：用 targetedURL；items：selected 第一个，文件夹用自身，文件用父目录；
    /// selected 为空时回退 targetedURL。返回 nil 表示无法确定。
    public static func resolve(context: MenuContext, targetedURL: URL?, selectedURLs: [URL],
                               isDirectory: (URL) -> Bool) -> URL?
}

public enum ShellEscaper {
    /// 'abc' ；单引号 → '\'' ；支持空格、$、`、"、\、换行、中文、emoji
    public static func singleQuoted(_ s: String) -> String
}

public enum ScriptInvocation {
    public static func command(for directory: URL) -> String     // "cd '<path>' && clear"
    /// 'ascr'/'psbr' 事件，keyASSubroutineName('snam') = handlerName，direct object = [command]
    public static func event(mode: OpenMode, command: String) -> NSAppleEventDescriptor
}
```

## 6. AppleScript（TermHere.applescript）

- 使用 `application id "com.googlecode.iterm2"`。
- `on openwindow(cmd)` / `on opentab(cmd)`。
- 逻辑：
  - 未运行：启动并等待最多 ~5s 出现窗口；有窗口则直接在其 current session `write text cmd`（复用启动窗口，不再新建）；仍无窗口则 `create window with default profile`。
  - 已运行：window → `create window with default profile`；tab → 无窗口则建窗口，否则 `tell current window to create tab with default profile`。
  - 最后 `activate`。
- 构建时用 `osacompile` 编译为 `TermHere.scpt` 放入宿主 App Resources。

## 7. 宿主 App

- 启动时把 `TermHere.scpt` 复制到 `~/Library/Application Scripts/com.xionggaoli.termhere.FinderExtension/`（覆盖）。
- 界面：扩展状态（`FIFinderSyncController.isExtensionEnabled`）+「打开扩展设置」（`showExtensionManagementInterface()`）；脚本状态 +「重新安装」；「测试」按钮（宿主用 `NSAppleScript` 执行同一脚本 opentab 到 `~`，显示错误）。注意：自动化权限按进程归属，扩展首次在 Finder 使用时还会单独弹一次。
- `NSAppleEventsUsageDescription` 写入两个 target 的 Info.plist。

## 8. 扩展

- `FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]`
- 沙盒 entitlement：`com.apple.security.app-sandbox`。
- 图标：`NSWorkspace.urlForApplication(withBundleIdentifier: "com.googlecode.iterm2")` → `icon(forFile:)` 缩到 16×16，失败为 nil。

## 9. 签名 / 构建

- `DEVELOPMENT_TEAM = Z8NL57N2AP`，Hardened Runtime 开启，`MACOSX_DEPLOYMENT_TARGET = 13.0`。
- Debug：`Apple Development`；Release：`Developer ID Application`，Manual 签名。
- `scripts/build.sh` 产出 `build/TermHere.app`；安装：复制到 `/Applications`，运行一次，`pluginkit -e use -i com.xionggaoli.termhere.FinderExtension` 或在系统设置启用。

## 10. 测试

- 自动化：`cd Packages/TermHereCore && swift test` 覆盖 §5 全部规则（TDD 先写失败测试）。
- 构建验证：`scripts/build.sh` 成功，`codesign --verify --deep --strict` 通过。
- 手工：`docs/acceptance.md`（空白处/文件夹/文件/多选、含空格与单引号路径、iTerm2 未运行/无窗口/已运行、权限拒绝时的错误提示）。
