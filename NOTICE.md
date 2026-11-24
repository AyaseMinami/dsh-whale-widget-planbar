# NOTICE

## 这是什么

本仓库是 [dsh-whale-widget](https://github.com/MeteorNOX/DeepSeek-Balance-Whale-Widget)
的**非官方补丁**，与作者 MeteorNOX 没有隶属关系，也不代表上游立场。
它不发布 npm 包，只提供「在本机已安装的 0.4.2 上打补丁」所需的文本替换、脚本和文档。

仓库内容：

| 路径 | 作用 |
|---|---|
| `pairs.json` | 7 组「查找 → 替换」，含上游代码的上下文片段 |
| `apply-planbar.ps1` | 把替换应用到指定的 `assets/whale-widget.js` |
| `install.ps1` | 解析 `DSH_HOME`、必要时安装上游 0.4.2、再调用上面那个脚本 |
| `planbar.patch` | 同一改动的参考 diff（可读、可审） |
| `docs/planbar-preview.webp` | 卡片本体渲染图，见下 |
| `docs/preview.html` | 生成上图的最小页面（真实补丁函数 + 桩数据） |
| `tools/gen-pairs.mjs` | 从 diff 重新生成 `pairs.json` 的小工具 |

## 上游许可与归属

上游代码按 **MIT** 发布，`Copyright (c) 2026 MeteorNOX`（见上游 `LICENSE`）。
`pairs.json` / `planbar.patch` 里包含上游代码片段，因此本仓库保留上游版权声明，
补丁部分与文档按 MIT 分发，全文见 [LICENSE](LICENSE)。

## 美术素材不在本仓库

上游 `assets/**` 下的图片 / 动图 / 音效，以及 `icon.png`，**不在 MIT 覆盖范围内**
（上游 `PROVENANCE.md` 明确「不授予再许可」）。本仓库**不包含、也不再分发**这些文件。

`docs/planbar-preview.webp` 是用补丁后的 `bubblePlanBarEl()` 配桩数据渲染出来的
**卡片本体**，没有角色原画、气泡贴图或任何音效；生成页面在 `docs/preview.html`。

## 改了哪里

`assets/whale-widget.js`，6 处逻辑改动、7 组替换：

1. `setVersionLabel`：菜单版号追加 `+planbar2`
2. `bubbleModuleSummary` / `bubbleModuleListLabel`：`planbar` 模块显示为「额度条·<模型名>」
3. 模块调色板：多窗口额度模型旁增加「额度条·<模型名>」芯片
4. `bubbleRowContentOf`：`planbar` 的文本层留空
5. 新增 `bubblePlanBarEl(mod, hostEl)`：标题 / 大号剩余百分比 / 轨道 / 重置倒计时
6. `bubbleRowsTo`：`planbar` 独占一整行，不再按容器宽拉满

没有新增网络请求：数据仍来自挂件自带的 `apiPlanOf(modelId)`。

## 权利主张 / Takedown

如果上游或任何权利人认为本仓库有不妥，请开一条 issue 说明**文件**与**理由**；
核实后会立即修改或移除，不附加其它条件。
