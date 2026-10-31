<!-- 标题格式：<app>: Add version <x.y.z> 或 <app>: Update to version <x.y.z> -->

- [ ] 只改动了一个 manifest（及其相关 scripts/ 资源）
- [ ] 本地跑过 `bin/formatjson.ps1`、`bin/checkhashes.ps1`、`bin/checkver.ps1`（有 checkver 时带 `-Update`）
- [ ] 本地真实安装 + 卸载验证过
- [ ] `description` / `license` 已填，`license` 用 SPDX 标识符
- [ ] 写了 `checkver` 与 `autoupdate`（无法自动跟版本的请在 PR 里说明原因）

Closes #XXXX
