# DEVLOG

## 2026-10-28 — TermHere 初版（Finder 右键 New iTerm2 Window/Tab Here）

**本次完成**
- grilling 确认全部设计决策（Q1–Q15），写入 `docs/designs/termhere.md`
- 实现：TermHereCore（SwiftPM，34 个单测全绿）、Finder Sync 扩展、宿主引导 App、`TermHere.applescript`、XcodeGen `project.yml`、`scripts/build.sh`、`scripts/notarize.sh`、`docs/acceptance.md`
- tester 两轮独立验证：clean build 成功；Developer ID 签名、Hardened Runtime、安全时间戳、无 get-task-allow；扩展沙盒
- 修复 tester 发现的问题：公证阻断项 ×2、菜单上下文改为在 `menu(for:)` 记录、相对 URL、冷启动 session 竞态、通知授权逻辑

**未完成 / 阻塞**
- 未做运行时验证：扩展在 Finder 中的加载、AppleScript 实际驱动 iTerm2、自动化权限弹窗、通知（需用户按 `docs/acceptance.md` 手工验收）
- Debug 配置（Apple Development 签名）未构建过
- 未公证（`notarize.sh` 需先 `xcrun notarytool store-credentials TermHere-notary`）

**下次起点建议**
1. `cp -R build/TermHere.app /Applications/` → 打开一次 → 启用扩展 → 跑验收清单
2. 根据实测问题修复（AppleScript 冷启动行为最可能需要调）

**当前状态**
- 分支 `feat/finder-sync`，尚无提交，所有文件未跟踪
- 无环境变量改动

## 2026-10-28（续）— App 图标

- 新增 `scripts/make-icon.swift`：CoreGraphics 绘制「终端窗口 `>_` + 前置右键菜单（高亮项带 `>`）」图标，生成 AppIcon.appiconset 全部 10 个尺寸
- Release 重新构建成功，`AppIcon.icns` 已打包，codesign 校验通过
- 状态：仍在 `feat/finder-sync`，未提交

## 2026-10-28（续）— 公证与 DMG

- 用户已存 `TermHere-notary` 凭据并完成 App 公证；`spctl` 显示 `source=Notarized Developer ID`
- 新增 `scripts/make-dmg.sh`：hdiutil 打包（App + Applications 链接）→ Developer ID 签名 → notarytool 公证 → staple
- 产物 `build/TermHere-1.0.dmg`（430K），公证 Accepted（submission ca11fce7-9a34-4062-b659-53202831da4f），staple 成功，Gatekeeper accepted
- 已知：hdiutil create/attach 在 macOS 27 报弃用警告，目前仍可用
- 未完成：Finder 运行时手工验收仍待用户执行；仍未提交

## 2026-10-28（续）— 卸载脚本

- 新增 `scripts/uninstall.sh`（`-y` / `--keep-app` / `--dry-run`）：自动发现并注销所有已登记的扩展副本、重置 AppleEvents 权限、删除脚本/沙盒容器/偏好、删除 /Applications/TermHere.app、重启 Finder
- 仅 dry-run 验证过，未实际执行

## 2026-10-28（续）— README

- 新增 `README.md`（英文）与 `README.zh-CN.md`（中文），互相链接：用途、安装、排障、卸载、原理、构建
- 发现 `docs/AuthKey_TCK2T6739Z.p8`（公证私钥）在项目目录内；已在 `.gitignore` 加 `*.p8`，建议用户移出项目

## 2026-10-28（续）— 修复：扩展在系统设置中不出现（v1.0.1）

- 根因：PlugInKit 对同一 bundle ID 只保留一条登记，最后启动的副本胜出；用户经 Spotlight 启动了 build/ 副本。另 `uninstall.sh` 的 `pluginkit -e ignore` 跨重装持久化
- 修复：uninstall 改 `-e default`；App 启动时检查位置（InstallLocation，10 个新测试），不在「应用程序」则提示并可交接到 /Applications 副本（需 createsNewApplicationInstance）；在「应用程序」时 `pluginkit -a` 自身扩展
- 验证：44 测试全绿；运行时验证弹窗、交接、登记切换；tester PASS（遗留 LOW：大小写/符号链接、onAppear 重复弹窗、pluginkit 无超时）
- 版本 1.0.1 (2)
