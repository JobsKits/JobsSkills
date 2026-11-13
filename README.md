# `Codex` 用户级 `Skills`

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#%E5%89%8D%E8%A8%80)
- [一、目录职责](#jobs-toc-heading-2)
- [二、Git 管理边界](#jobs-toc-heading-3)
- [三、外援软链接溯源](#jobs-toc-heading-4)
- [四、溯源与恢复检查](#jobs-toc-heading-5)
- [五、主文件与路径专项附件](#path-specific-attachments)
- [六、软件项目从零到一](#software-project-workflow)
- [七、前端视觉设计与评审 Skills](#frontend-design-skills)

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

> 本仓库维护 [**JobsSkills**](https://github.com/JobsKits/JobsSkills) 用户级 `Skills`；现行基准工作树 `~/.agents/skills` 供 [**Codex**](https://openai.com/codex) 直接加载，`💻JobsCodexConfigs/skills` 是配置父仓的子模块挂载。Jobs 自有 `Skill`、外部安装的 `Skill` 和外援软链接可以同时出现，但必须分清所有权、上游来源和 [**Git**](https://git-scm.com/) 跟踪边界。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、目录职责 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 唯一标准仓库是 `https://github.com/JobsKits/JobsSkills`，`~/.agents/skills` 是现行、内容最完整的基准工作树。
- `💻JobsCodexConfigs/skills` 仅作为 `JobsCodexConfigs` 父仓对本仓库的 Git 子模块挂载点，便于父仓记录所使用的 `JobsSkills` 版本；它不是可以反向覆盖现行工作树的备份源。
- 外援 `Skill` 依旧由其上游仓库管理源码和版本；本仓库只记录来源和运行态链接映射。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、Git 管理边界 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

| 类型 | Git 处理 | 信息来源 |
| --- | --- | --- |
| Jobs 自有 `Skill` | 在本仓库中跟踪完整内容 | `JobsSkills` |
| 外部安装的实体目录 | 按各自安装器、锁定文件或上游仓库溯源 | 例如 `~/.agents/.skill-lock.json` |
| 外援软链接 | 不进入 Git 索引，在 `.gitignore` 中按精确名称忽略 | 本文档的来源和映射表 |

Git 对软链接只保存“目标路径字符串”，不保存链接目标的内容。当软链接指向仓库外的本机绝对路径时，直接提交会使克隆结果依赖特定机器目录。因此本目录使用“`.gitignore` 排除运行态链接 + `README.md` 保留溯源信息”的组合方式。

`.gitignore` 中使用完整链接名称，不使用 `/understand*` 之类的宽泛规则，避免误伤以后新增的同前缀自有 `Skill`。

## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、外援软链接溯源 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 上游项目：[**Understand Anything**](https://github.com/Lum1104/Understand-Anything)
- 上游 Git 地址：`https://github.com/Lum1104/Understand-Anything.git`
- 本地检出目录：`~/.understand-anything/repo`
- 链接源目录：`~/.understand-anything/repo/understand-anything-plugin/skills`
- 已核验基线：`5c1e35f90be029efb012a41e1122b08abef5cbb2`

| 运行态链接 | 上游子目录 |
| --- | --- |
| `understand` | `understand-anything-plugin/skills/understand` |
| `understand-chat` | `understand-anything-plugin/skills/understand-chat` |
| `understand-dashboard` | `understand-anything-plugin/skills/understand-dashboard` |
| `understand-diff` | `understand-anything-plugin/skills/understand-diff` |
| `understand-domain` | `understand-anything-plugin/skills/understand-domain` |
| `understand-explain` | `understand-anything-plugin/skills/understand-explain` |
| `understand-knowledge` | `understand-anything-plugin/skills/understand-knowledge` |
| `understand-onboard` | `understand-anything-plugin/skills/understand-onboard` |

## <span id="jobs-toc-heading-5" data-jobs-toc="v2">四、溯源与恢复检查 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

1、检查上游地址和当前版本：

  ```shell
  git -C "$HOME/.understand-anything/repo" remote -v
  git -C "$HOME/.understand-anything/repo" rev-parse HEAD
  ```

2、检查运行态链接：

  ```shell
  for skill_name in understand understand-chat understand-dashboard understand-diff understand-domain understand-explain understand-knowledge understand-onboard; do
    printf '%s -> %s\n' "$skill_name" "$(readlink "$skill_name")"
  done
  ```

3、链接失效时，先恢复上游仓库，再按本文档映射表重建链接；软链接不进入本仓库 Git 索引，也不把外援源码复制进 Jobs 自有 `Skill` 内容。

## 五、<span id="path-specific-attachments">主文件与路径专项附件</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- Jobs 自有 Skill 的通用规则保留在 `SKILL.md`；绑定具体仓库或固定文件路径的内容提取为同一文件夹内、与 `SKILL.md` 同级的独立附件，主文件保留命中范围下的必读链接。维护边界见 [配置审计规范](./jobs-codex-config-audit/SKILL.md)。
- 附件不另注册为 Skill，也不将其它仓库的路径例外扩大成通用规则。例如 README Skill 的 [OS@Extension 脚本布局](./jobs-markdown-docs/README规范-OS@Extension脚本布局.md)只管理指定安装 / 卸载入口；现有 [项目统计条款](./jobs-markdown-docs/README规范-项目统计条款.md)继续独立保留。

  ```text
  jobs-markdown-docs/
  ├── SKILL.md
  ├── README规范-项目统计条款.md
  └── README规范-OS@Extension脚本布局.md
  ```

## 六、<span id="software-project-workflow">软件项目从零到一</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 独立入口：[jobs-software-project](./jobs-software-project/SKILL.md)，可通过 `$jobs-software-project` 调用，接收原始需求、询问未明确的前端路线、生成留白／红字文档，并在用户补填后进行二次回归。
- [开发与交付规范](./jobs-software-project/软件项目开发与交付规范.md)和[可补填模板](./jobs-software-project/项目需求与开发评审模板.md)由该 Skill 集中维护；文档、Flutter、Python、Shell、OC、Swift 与 Podspec 技能按命中范围引用，不重复保存规范全文。

## 七、<span id="frontend-design-skills">前端视觉设计与评审 Skills</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

> 用户于 2026-11-12 授权安装以下四项；前端范围覆盖 Web 和移动 App。完整来源、固定提交及文件摘要见 [安装锁定清单](./frontend-skills.lock.json)。

| 调用入口／实体目录 | 上游来源 | 安装基线 | 用途 |
| --- | --- | --- | --- |
| `$ui-ux-pro-max`／`ui-ux-pro-max/` | [**UI UX Pro Max**](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) | `6ae86f61f520d6ca229d2f40e070410638c908c5` | 跨端设计系统；包含 [**SwiftUI**](https://developer.apple.com/xcode/swiftui/)、[**Jetpack Compose**](https://developer.android.com/compose)、[**Flutter**](https://flutter.dev/)、[**React Native**](https://reactnative.dev/) 专项数据 |
| `$impeccable`／`impeccable/` | [**Impeccable**](https://github.com/pbakaus/impeccable) | `c1e0e5492fbb524f5df84d635ecfae7dc438ec45` | 视觉设计、点评与精修；包含原生 iOS／Android 评审和适配指南 |
| `$frontend-design`／`frontend-design/` | [**Anthropic frontend-design**](https://github.com/anthropics/skills/tree/main/skills/frontend-design) | `2c5958ecac7cee2b583967a2c4981d0f4a75c579` | 视觉方向、字体、配色与构图 |
| `$web-design-guidelines`／`web-design-guidelines/` | [**Vercel web-design-guidelines**](https://github.com/vercel-labs/agent-skills/tree/main/skills/web-design-guidelines) | `1a2c79d4e6c4a2283dc2c614b6538cbe1ed5ca62` | Web 界面规范检查，使用时联网获取最新规则 |

- 四项均为外部安装的实体目录，保留上游所有权；`.gitignore` 按上述四个精确目录排除内容，仓库仅跟踪本节与安装锁定清单。当前运行态与备份态保存完整实体副本；新机器仅克隆本仓不会自动获得这些被忽略的目录，应依据清单从固定提交重装，并重新核对两态内容。
- UI UX Pro Max 的入口由同一提交的官方 Codex 模板以全局模式生成，脚本使用 `~/.agents/skills/ui-ux-pro-max/scripts/search.py`，保留完整数据、脚本与参考资料；不依赖 Claude 专属环境变量。[**UIKit**](https://developer.apple.com/documentation/uikit)／[**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) 未列为其专项技术栈，只复用通用设计规则，由既有 Jobs 语言 Skill 落地。
- Impeccable 保留完整 `agents/`、`reference/` 和 `scripts/`，附带经官方摘要核验的 [**MacOS**](https://www.apple.com/macos/) arm64 引擎 `0.1.22`；未安装自动 hooks，也未运行 live 模式。其它平台可按上游启动器机制获取对应固定版本引擎。
- 业务体验由既有 `jobs-frontend-experience` 组织，外部 Skill 提供适用的视觉与评审指导，实际代码继续遵守各平台 Jobs Skill 和用户已确认的项目约束。按任务加载，避免将四份规则同时套入每次任务。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
