# TermHere

[English](README.md) | 简体中文

在 Finder 里右键空白处、文件夹或文件，就能用 **iTerm2** 打开这个位置：

- **New iTerm2 Window Here**：在新窗口中打开
- **New iTerm2 Tab Here**：在新标签页中打开

| 右键位置 | 打开的目录 |
|---|---|
| Finder 窗口空白处 | 当前窗口所在目录 |
| 文件夹 | 该文件夹 |
| 文件 | 文件所在目录 |
| 多选 | 第一个选中项（规则同上） |

iTerm2 没运行时会先启动它，并直接用它启动时开的那个窗口，不会多出一个空窗口。iTerm2 没有窗口时，点「Tab Here」会改为新建窗口。

## 系统要求

- macOS 13 及以上
- 已安装 [iTerm2](https://iterm2.com)

## 安装

1. 打开 `TermHere-<版本>.dmg`，把 **TermHere** 拖进 **Applications**。
2. 从「应用程序」打开一次 **TermHere**，它会安装用来控制 iTerm2 的脚本。
3. 点 **Open Extension Settings**，在「系统设置 → 通用 → 登录项与扩展 → Finder」中打开 **TermHere**。
4. 点 **Test: open iTerm2 tab in ~**，系统询问是否允许 TermHere 控制 iTerm2 时，点「允许」。
5. 在 Finder 里右键，选 **New iTerm2 Window Here** 或 **New iTerm2 Tab Here**。第一次使用时，系统会再问一次是否允许 *Finder 扩展* 控制 iTerm2。这和第 4 步不是同一个权限，也要点「允许」。

设置完成后 TermHere 不用一直开着，Finder 扩展会自己运行。

## 常见问题

| 现象 | 解决办法 |
|---|---|
| 右键菜单里没有这两项 | 确认第 3 步已经打开扩展，然后运行 `killall Finder`。 |
| 菜单项出现了两遍 | 系统里登记了两份扩展，比如构建目录里还有一份。运行 `scripts/uninstall.sh`，再从 DMG 重新安装。 |
| 点了没反应 | 到「系统设置 → 隐私与安全性 → 自动化 → TermHere」里允许控制 iTerm，然后在 TermHere 里点 **Reinstall**。 |
| 收到 TermHere 出错的通知 | 打开 TermHere App，状态区和 **Test** 按钮会显示原因。 |
| 菜单或扩展未出现在系统设置中 | 请确认从“应用程序”文件夹启动 TermHere，而不是从 DMG 或构建目录。退出其他副本，然后打开一次 `/Applications/TermHere.app`。 |

查看日志：运行 `log stream --predicate 'subsystem BEGINSWITH "com.xionggaoli.termhere"'`。

## 卸载

```bash
scripts/uninstall.sh             # 列出要清理的内容，确认后执行
scripts/uninstall.sh -y          # 不询问，直接执行
scripts/uninstall.sh --keep-app  # 只重置设置，保留 App
scripts/uninstall.sh --dry-run   # 只打印要执行的命令
```

脚本会做这些事：
1. 注销系统里登记的所有扩展副本。
2. 重置自动化权限。
3. 删除已安装的脚本、沙盒容器和偏好设置。
4. 删除 `/Applications/TermHere.app`。
5. 重启 Finder。

通知权限需要你到「系统设置 → 通知」里手动删除。

## 工作原理

Finder 空白处的右键菜单只能由 **Finder Sync 扩展** 添加，Quick Action（快速操作）和 Services（服务）都不会出现在那里。扩展运行在沙盒里，不能直接用 AppleScript 控制 iTerm2，所以它通过 `NSUserAppleScriptTask` 运行 `~/Library/Application Scripts/com.xionggaoli.termhere.FinderExtension/` 下的 `TermHere.scpt`。这个脚本由宿主 App 安装，负责打开窗口或标签页，并执行 `cd '<路径>' && clear`。路径经过 shell 转义，含空格、引号或中文都没问题。

```
App/                   宿主 App（SwiftUI，引导设置、安装脚本）
  Resources/TermHere.applescript
FinderExtension/       Finder Sync 扩展（沙盒）
Packages/TermHereCore/ 纯逻辑：目标目录解析、shell 转义、Apple Event 构造（有单元测试）
scripts/               构建、公证、DMG、图标、卸载
docs/                  设计文档与手工验收清单
```

## 从源码构建

需要 Xcode 和 [XcodeGen](https://github.com/yonaskolb/XcodeGen)（`brew install xcodegen`）。

```bash
cd Packages/TermHereCore && swift test && cd -   # 单元测试
scripts/build.sh                                  # → build/TermHere.app（Release，Developer ID 签名）
scripts/notarize.sh                               # 公证 App 并附上公证票据
scripts/make-dmg.sh                               # → build/TermHere-<版本>.dmg（已签名、已公证）
swift scripts/make-icon.swift                     # 重新生成 App 图标
```

第一次公证前，先把凭据存进钥匙串：

```bash
xcrun notarytool store-credentials TermHere-notary \
  --key /path/to/AuthKey_XXXXXXXXXX.p8 --key-id XXXXXXXXXX --issuer <Issuer ID>
# 或：--apple-id <Apple ID> --team-id <Team ID>（配合 App 专用密码）
```

签名用的 Team 是 `Z8NL57N2AP`，Bundle ID 是 `com.xionggaoli.termhere`。用自己的账号构建时，要改 `project.yml` 和 scripts 里的对应值。

日常使用不要直接从 `build/` 里打开 App。系统会把那个路径的扩展登记下来，之后再装一份到「应用程序」，右键菜单就会出现重复项。
