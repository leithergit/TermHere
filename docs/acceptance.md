# TermHere 手工验收清单

## 安装
- [ ] `scripts/build.sh` 成功；`codesign --verify --deep --strict build/TermHere.app` 通过
- [ ] 复制到 `/Applications`，运行一次；界面显示脚本 "Installed"
- [ ] `~/Library/Application Scripts/com.xionggaoli.termhere.FinderExtension/TermHere.scpt` 存在
- [ ] 点击 "Open Extension Settings" 或 `pluginkit -e use -i com.xionggaoli.termhere.FinderExtension` 启用；状态变为 Enabled（必要时 `killall Finder`）
- [ ] 宿主 "Test" 按钮：首次弹出自动化授权（TermHere → iTerm2），允许后 iTerm2 在 ~ 打开新 Tab

## 菜单出现位置
- [ ] 文件夹空白处右键：出现 "New iTerm2 Window Here" / "New iTerm2 Tab Here"，带 iTerm2 图标
- [ ] 选中文件夹右键：出现两项，cd 到该文件夹
- [ ] 选中文件右键：cd 到其父目录
- [ ] 多选右键：cd 到第一个选中项（文件则其父目录）
- [ ] 桌面空白处右键同样可用
- [ ] 侧边栏等其它菜单类型不出现这两项

## 路径转义
- [ ] 含空格目录
- [ ] 含单引号目录（如 `it's here`）
- [ ] 含 `$`、反引号、双引号、反斜杠的目录
- [ ] 中文 / emoji 目录
- [ ] 每种情况下 `pwd` 与目标一致，且终端已 `clear`

## iTerm2 状态
- [ ] 未运行 + Window：iTerm2 启动，仅一个窗口（无多余空窗），已 cd
- [ ] 未运行 + Tab：同上，回退为窗口
- [ ] 运行但无窗口 + Tab：新建窗口
- [ ] 运行且有窗口 + Window：新增窗口
- [ ] 运行且有窗口 + Tab：当前窗口新增标签页
- [ ] 每次操作后 iTerm2 被激活到前台

## 错误处理
- [ ] 删除 Application Scripts 下的 .scpt 后点击菜单：`log stream --predicate 'subsystem == "com.xionggaoli.termhere"'` 有错误日志；若已授权通知则有系统通知
- [ ] 在 系统设置 > 隐私与安全 > 自动化 中拒绝 Finder/扩展对 iTerm2 的控制后点击：日志有错误，不崩溃
- [ ] 重新运行宿主 App 可恢复脚本

## 公证（发布前）
- [ ] `xcrun notarytool store-credentials "TermHere-notary" ...` 后运行 `scripts/notarize.sh`；`spctl -a -vv build/TermHere.app` 显示 accepted
