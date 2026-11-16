# Jobs 外源 UI Skills 使用与换机恢复

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#%E5%89%8D%E8%A8%80)
- [一、实际使用与阶段分工](#usage)
- [二、用户级外源 UI Skills](#user-skills)
- [三、界面相关插件与条件入口](#plugin-skills)
- [四、换机恢复与环境核验](#restore)

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

> 本附件由[从零到一 Skill](./SKILL.md)在项目包含界面设计、实现或评审时加载，记录现用外源 UI 能力及恢复入口。业务体验由 [jobs-frontend-experience](../jobs-frontend-experience/SKILL.md)组织，外源指导按适用端和任务阶段落地；保留用户指定的视觉、技术路线及本期范围。

## 一、<span id="usage">实际使用与阶段分工</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 新建或整体设计界面时，加载 `ui-ux-pro-max` 形成适用的设计系统和组件依据，结合 `frontend-design` 落实字体、色彩、构图与内容层级；原生端仅复用适用的通用设计判断，具体实现继续遵守对应 Jobs 语言 Skill。
- 界面实现、精修或评审时加载 `impeccable` 的适用规则，检查视觉层次、响应布局、主题、长文案和状态反馈；Web 规范审查再加载 `web-design-guidelines` 并按其入口获取当前规则。制作动效时加载 `motion-design`，落实时序、缓动、打断与弱化动效；没有动效任务不为使用 Skill 制造动画。
- 对明确限定的小修，只加载命中的指导并处理本期问题，不重走整套产品设计；已确认的样式和交互优先。项目记录实际采用的 Skill、使用阶段、产生的设计决定和截图／交互检查依据，不把“已安装”写成“已应用”。
- 外源规则相互重叠时，按用户要求、Jobs 业务／工程边界和任务适用性取舍；不要为凑齐名单同时加载全部插件，也不因某个 Skill 默认技术栈而替换已选技术。

## 二、<span id="user-skills">用户级外源 UI Skills</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

下表五项为当前保留入口；名称、用途和恢复分工在本附件维护，版本／提交／启停状态仍以全局公约 `AGENTS.md` 的“外源用户级 Skills 现用清单”和[前端安装锁](../frontend-skills.lock.json)为准，不另造一套版本常量。增加、替换或弃用 UI Skill 时，同任务更新公约与本表，移除弃用项，不累积历史安装列表。

| Skill 与本地入口 | 用途 | 来源与恢复依据 |
| --- | --- | --- |
| [frontend-design](../frontend-design/SKILL.md) | 视觉方向、字体、配色与构图 | [**Anthropic Skills**](https://github.com/anthropics/skills)，`skills/frontend-design`；按前端安装锁的提交与内容摘要独立恢复 |
| [ui-ux-pro-max](../ui-ux-pro-max/SKILL.md) | 跨端 UI／UX、设计系统与栈专项数据 | [**UI UX Pro Max**](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)，`.claude/skills/ui-ux-pro-max`；按锁定提交恢复完整数据与脚本，入口采用同提交的官方 [**Codex**](https://openai.com/codex) 全局模板 |
| [impeccable](../impeccable/SKILL.md) | 界面设计、精修与 Web／原生评审 | [**Impeccable**](https://github.com/pbakaus/impeccable)，`.agents/skills/impeccable`；按前端安装锁恢复完整目录，配套引擎依目标系统／架构核验 |
| [web-design-guidelines](../web-design-guidelines/SKILL.md) | Web 规范与无障碍审查 | [**Vercel Agent Skills**](https://github.com/vercel-labs/agent-skills)，`skills/web-design-guidelines`；入口按锁恢复，审查规则按锁中的 `remoteRules` 及 Skill 指令联网获取，入口固定提交不代表远端规则固定 |
| [motion-design](../motion-design/SKILL.md) | 动效、缓动与编排 | [**LottieFiles Motion Design Skill**](https://github.com/LottieFiles/motion-design-skill)，`skills/motion-design`；现有完整目录由 [**JobsSkills**](https://github.com/JobsKits/JobsSkills) 跟踪，随仓恢复，版本依据 Skill 元数据与现用公约 |

前四项是被 `.gitignore` 精确排除的外部实体目录，单独拉取 JobsSkills 不会生成它们；锁文件已随仓跟踪。Impeccable 的 Skill 版本与引擎版本是两层依据，不能混写；换机不照搬原机器的二进制、自动 hooks 或连接配置。

## 三、<span id="plugin-skills">界面相关插件与条件入口</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

插件按任务触发，不是每个业务项目的依赖。插件来源市场、当前保留版本和完整入口以公约“插件分发 Skills 现用清单”为准；恢复使用“插件名＋来源市场”，不把缓存路径当安装包，也不因本轮没有注入某入口就认定已经弃用。

| 插件／来源 | 使用条件与 Skill 入口 |
| --- | --- |
| `figma@openai-curated-remote` | 涉及 [**Figma**](https://www.figma.com/) 设计文件、设计系统、设计转代码或反向导入时，按任务读取 `figma-design-to-code`、`figma-code-connect`、`figma-code-workflows`、`figma-create-new-file`、`figma-generate-design`、`figma-generate-library`、`figma-implement-motion`、`figma-swiftui`、`figma-spec`；相应工具动作另读取其强制前置 `figma-use`、`figma-use-figjam`、`figma-use-motion`、`figma-use-slides`、`figma-generate-diagram`、`figma-generative-plugins` 或 `figma-shaders` |
| `product-design@openai-curated-remote` | 主要任务是设计探索、研究、审计、复刻或原型时，经 `index` 路由到 `get-context`、`user-context`、`research`、`ideate`、`audit`、`image-to-code`、`url-to-code`、`design-qa`、`share`；普通局部代码实现不自动改走原型或发布流程 |
| `sites@openai-curated-remote` | 用户选择 Sites 网站／托管交付时使用 `sites`，已有 Site 改编使用 `sites-remix`；不把普通本地仓库实现擅自变成账号连接或网站发布 |
| `visualize@openai-curated-remote`／`visualize@openai-bundled` | `visualize` 用于会话内交互说明、比较和预览；两种来源分别核对，以当前环境实际可用者为准，不把示意图当成已实现的业务 UI |
| `work-pets@openai-curated-remote` | 仅明确要求 ChatGPT Work 模式宠物时使用 `pets`、`create-pet`、`update-pet`；这是特定宿主的视觉定制，不给普通业务项目增加宠物功能 |

系统自带的图像等能力按目标环境提供，不混入手工外源实体清单；Jobs 自有体验、登录动效及语言 Skill 也不冒充外源安装项。

## 四、<span id="restore">换机恢复与环境核验</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 先按当前公约恢复全局指导和 JobsSkills 现行工作树；后续版本同步通过正常 [**Git**](https://git-scm.com/) 拉取，先核对目标仓库、远端、分支和工作区，保留未提交内容。日常只维护运行态，不反向复制备份、不强制重置或自动提交／推送；拉取成功也不等于忽略目录与插件已经恢复。
- 根据前端安装锁的 `repo`、`sourcePath`、`commit`、`contentSha256` 和模板依据独立恢复四项实体；保留数据、脚本、参考资料及许可。平台引擎另按目标系统／架构校验官方来源和摘要，记录与旧平台的合理差异，不能为了目录哈希一致运行旧架构二进制。已跟踪的 `motion-design` 随仓恢复后核对元数据及目录完整性。
- 插件通过目标机器当前 Codex 的插件管理按插件名与来源市场恢复，核对实际安装／启用资料及当前可用工具／Skill。需要服务连接的重新由本人授权；不复制旧机器缓存、Cookie、Token 或连接凭据。插件未启用、工具不可用、只有残留缓存分别记录，不能标作已恢复。
- 核对 Skill 可读取、引用资源存在、数据／检索脚本和所需平台引擎可用；仅在会话已有授权内恢复环境。缺项如实记录，继续不依赖该项的工作，不静默降级后宣称已按该 Skill 完成。环境平行指规则、来源和版本依据可复现，目标系统路径和平台二进制仍须在本机解析与复检。
- 实际项目的采用记录填写[评审模板](./项目需求与开发评审模板.md#frontend)；换机恢复结果、缺项和验证边界有依据。本文记录恢复办法，不意味着本次已执行安装、拉取、启用或发布。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
