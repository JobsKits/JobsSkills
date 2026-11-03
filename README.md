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

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
