# scoop-dsh

> 面向 **DeepSeek Harness（dsh）爆发后社区新作**的 Scoop bucket。第三方仓库，与 Scoop 官方无关。

Scoop 官方 bucket 收录门槛高、审核慢，一大批最近才冒出来的小工具一直进不去。这个 bucket 的目标很简单：
**让"刚出炉、还没人打包"的 Windows 工具能一条命令装上，并且自动跟版本。**

## 已收录

| 软件 | 版本 | 说明 |
| --- | --- | --- |
| [pane](https://github.com/LBEILC/Pane) | 0.1.209 | Windows 11 启动器 / 鼠标手势 / 剪贴板工具。上游只有自制的 .NET 安装壳（GUI），本 manifest 直接从中抽出内嵌 payload 解包，所以不需要管理员权限，也不写系统注册表。装完请在「设置 → 关于」关掉自带自动更新，改用 `scoop update pane` |
| [purrge](https://github.com/RabbittuX/purrge) | 0.3.4 | AI 磁盘清理助手（Windows/macOS）。官方只发 PowerShell Gallery 模块，这里用原生 Scoop 方式拆包：把 nupkg 解到 app 目录、生成 `purrge` 包装器，数据仍在 `%PURRGE_HOME%`（默认 `~/.purrge`）。需要 Python 3.8+
| [gitport-github](https://github.com/zhidian-cmd/gitport-github) | 0.5.1 | GitHub 加速器（本机代理 + 托盘，接管系统代理、退出自动还原）。单文件 exe，`bin` 暴露 `gitport-github` 命令，`-tray` 开机驻留
| [workbuddy-switch](https://github.com/changexbc/workbuddy-switch) | 0.1.62 | WorkBuddy/CodeBuddy 多账号切换（Tauri）。Windows 只有 NSIS 安装器，静默装到 Scoop 目录，卸载走安装器自带 uninstall.exe
| [zen-gate](https://github.com/LAGcomcom/zen-gate) | 1.9.3 | 把 OpenCode Zen 免费模型接进各种 Agent 的托盘网关（Go 单文件 exe，双击即用）
| [tick-stock-panel](https://github.com/shy3130/tick-stock-panel) | 0.3.24 | A 股自建量化工作台（TSP）。Inno Setup 安装包，静默装到 Scoop 目录、卸载走 unins000.exe
| [minidock](https://github.com/wang01116/MiniDock) | 1.6.5 | 极简 Windows dock 栏，单文件 exe（下载即改名 MiniDock.exe）
| [contextmenumgr](https://github.com/PLFJY/ContextMenuMgr) | 1.7.10 | Win11 右键菜单管理器（自包含便携 zip） |
| [gezi-quark-downloader](https://github.com/huaotem-bot/gezi-quark-downloader) | 2.3.1 | 夸克网盘下载器（win64 zip） |
| [imewlconverter](https://github.com/studyzy/imewlconverter) | 3.6.0 | 深蓝词库转换，CLI + GUI（win-x64 zip） |
| [jietuba](https://github.com/1003129155/jietuba) | 2.2.1 | 截图 + 剪贴板历史（lite x64 zip） |
| [inputtip](https://github.com/abgox/InputTip) | 3.6.12 | 输入法状态提示（单文件 exe） |
| [serpent](https://github.com/dolag233/Serpent) | 0.3.3 | 个人资产管理（portable zip） |
| [2.4g-battery-viewer](https://github.com/yszyszysz233/2.4G-battery-viewer) | f0e983e | 读 2.4G 无线鼠标/耳机电量（纯 Python 源码包，生成 battery-viewer / battery-viewer-tray 两个命令）
- [airi](https://github.com/moeru-ai/airi) | 0.14.1 | AI 虚拟角色桌面伴侣（electron-builder NSIS，静默装 + 自带卸载器）
- [msime-windows](https://github.com/metasequoiaime/msime-windows) | 0.13.1 | 水杉输入法（Inno Setup；TSF 输入法需官方安装器注册，另需 VC++ 2015-2022 x64）
- [yunx-desktop](https://github.com/tidain/YunX-Desktop) | 1.3.3 | 云汐网盘聚合下载端（Inno Setup）
- [mihome-windows](https://github.com/huanyuejue/MiHome-Windows) | 0.5.0 | 米家设备 Windows 客户端（便携 zip，extract_dir=MiHome-Windows）
- [gezi-quark-downloader](https://github.com/huaotem-bot/gezi-quark-downloader) | 2.3.1 | 鸽子下载（便携 zip，扁平 GeZi.exe）
- [jietuba](https://github.com/1003129155/jietuba) | 2.2.1 | 截图/剪贴板工具（便携 zip，扁平 jietuba_lite.exe；tag 形如 release-x.y.z）
| [kazumi](https://github.com/Predidit/Kazumi) | 2.4.2 | 番剧采集/在线观看（Flutter，扁平 zip 便携） |
| [animeko](https://github.com/open-ani/animeko) | 6.4.0 | 弹幕追番平台（zip 内单根目录 Ani/） |
| [algermusicplayer](https://github.com/algerkong/AlgerMusicPlayer) | 5.1.0 | 第三方音乐播放器（NSIS 静默安装） |
| [deskbox](https://github.com/Tianyu199509/DeskBox) | 1.5.9 | Windows 桌面整理（Inno Setup 静默安装） |
| [codex-plus-plus](https://github.com/BigPizzaV3/CodexPlusPlus) | 2.1.4 | Codex++：AI 编程 Agent 统一管理应用（万物皆拓展 + 本地网关供应商池）。便携 zip 内只有 codex-plus-plus.exe，无安装器、不需管理员权限 |

## 安装与使用

```pwsh
scoop bucket add dsh https://github.com/yhweb/scoop-dsh
scoop install dsh/<app>
```

## 收录标准

收：

- 近半年社区新造、官方 bucket（Main / Extras / Versions / Nonportable）尚未收录的 Windows 工具
- 能拿到**稳定的 Windows 二进制**（zip / exe / msi / 单文件），安装方式标准
- 开源或免费可用；优先能写出 `checkver` + `autoupdate` 的（写出即可永久自动跟版本）
- 中文界面/中文文档完全没问题 —— 这正是官方 Main/Extras 最常拒的一类

不收：

- **纯 npm 包形态的 dsh 插件**（那类直接 `dsh plugin add <pkg>`，塞进 Scoop 反而多一层壳）
- 需要管理员权限的系统级组件（这类请提给官方 `Nonportable`）
- 破解版、注入/外挂类用途、无稳定下载源（只给网盘链接）的东西

## 自动化（本仓库自带，无需人肉跟版本）

| 机制 | 触发 | 作用 |
| --- | --- | --- |
| Excavator | `cron: 20 */4 * * *`（每 4 小时）+ 手动 | 全量 `checkver -Update`，把新版本直接推到 `main` |
| Issue Handler | 新建 issue / 打 `verify` 标签 | hash 报错自动重算，并开 `<app>: Fix hash` PR 关联 issue |
| PR Checker | PR 打开 / 评论 `/verify` | schema、格式 lint、description/license、checkhashes、checkver、autoupdate 全量校验 |
| CI | push / PR | `powershell` + `pwsh` 双矩阵跑 Pester（`bin/test.ps1`） |

工作流来自 Scoop 官方 [BucketTemplate](https://github.com/ScoopInstaller/BucketTemplate) + [ScoopInstaller/GithubActions](https://github.com/ScoopInstaller/GithubActions)。

## 新增一个包

1. 复制 `bucket/app-name.json.template` → `bucket/<app>.json`，按需删字段
2. 本地把四道关跑一遍：

```pwsh
.\bin\formatjson.ps1    <app> -Dir bucket   # 格式 lint
.\bin\checkhashes.ps1   <app> -Dir bucket   # hash 是否真对
.\bin\checkver.ps1      <app> -Dir bucket   # 能否抓到当前版本
.\bin\checkver.ps1      <app> -Dir bucket -Update   # autoupdate 能否正确改写 URL
scoop install .\bucket\<app>.json            # 真装一遍，再 scoop uninstall <app>
```

3. 提 PR，标题格式：`<app>: Add version <x.y.z>`（更新已有包用 `<app>: Update to version <x.y.z>`）

## 目录结构

```
bucket/       manifest 正文，每个 app 一个 json
bin/          校验脚本（formatjson / checkhashes / checkurls / checkver / missing-checkver / test）
deprecated/   已下线 manifest 归档
scripts/      辅助资源（.reg、配置片段等）
.github/      自动化工作流与 issue/PR 模板
```

## 待收录候选（滚动清单）

调研中看到、但还没落 manifest 的方向，欢迎开 issue 认领或直接提 PR：

- dsh 生态里的**独立 CLI / 桌面工具**：多数目前只发 npm 包或仅 macOS 产物，需要挑出真带 Windows 二进制的
- TrafficMonitor 插件类（DLL 形态）：需要 `pre_install` 把 DLL 塞进插件目录，属于"可做但要单独设计"的一类
- 各类新出的 AI 终端 / 本地模型小工具：优先选 GitHub Releases 里有 zip/exe 且天生带校验和的

## 说明

- 本仓库个人维护，manifest 准确性由本仓库负责；版本跟随上游发布，不做长期版本钉死（需要旧版本请提 issue）。
- 收录 = **能装** + **能自动更新**；两者缺一不进 `bucket/`。
