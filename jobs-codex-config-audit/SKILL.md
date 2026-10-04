---
name: jobs-codex-config-audit
description: 当任务涉及 Codex 的 AGENTS.md、用户级 Skills、JobsCodexConfigs / JobsSkills 仓库关系、规则去重压缩、语义防回退、中文数字序号、专有名词链接、子模块一致性或每周配置巡检时使用。
---

# Jobs Codex 配置审计

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[toc]

---

## 🔥 <font id=前言>前言</font>

> 本技能维护 Jobs 的 [**Codex**](https://openai.com/codex) 全局指导与专项 Skills。目标是减少重复上下文、修正文档规范漂移，并保持 `JobsCodexConfigs`、`JobsSkills`、子模块指针和用户级运行位置的边界清晰；“压缩”只能消除表达重复，不能删除触发条件、工程边界、例外、验证步骤或 Jobs 特征。

## 一、唯一配置源与允许范围 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 1.1、分开维护两个标准仓库 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

全局指导标准源：

```text
/Users/jobs/Documents/Github/JobsGenesis/JobsConfigOS/💻JobsCodexConfigs
└── AGENTS.md
```

用户级 Skills 标准源与现行基准工作树：

```text
/Users/jobs/.agents/skills/
```

该工作树的远端必须是 `https://github.com/JobsKits/JobsSkills`。`JobsCodexConfigs/skills` 只是 `JobsSkills` 子模块挂载，父仓只跟踪 `.gitmodules` 和 gitlink；不得把子模块或历史备份反向覆盖现行基准工作树，也不得把 Obsidian Vault 整体拷进 Skill。

### 1.2、先保护已有工作区 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

审计开始先执行只读检查：

```shell
git -C /Users/jobs/Documents/Github/JobsGenesis/JobsConfigOS/💻JobsCodexConfigs status --short
git -C /Users/jobs/Documents/Github/JobsGenesis/JobsConfigOS/💻JobsCodexConfigs diff -- AGENTS.md
git -C /Users/jobs/.agents/skills status --short
git -C /Users/jobs/.agents/skills diff
```

已有改动属于用户。只修改本任务命中的规则，不回滚、不覆盖、不借审计顺手重写其它 Skill。

## 二、“去重但不减能力”的硬边界 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 2.1、先建立语义账本，再决定是否删除 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

每条候选重复规则先拆为六个字段：

| 字段 | 必须保留的内容 |
| --- | --- |
| 触发条件 | 什么任务、文件或目录命中 |
| 必须动作 | Codex 实际要做什么 |
| 禁止边界 | 绝对不能做什么 |
| 例外 | 什么情况下不应用 |
| 验证 | 怎样证明动作完成且没有回退 |
| 所有权 | 规则应该归 AGENTS 还是哪个 Skill |

只有六个字段都能在保留位置找到等价表达，才允许删除重复句。找不到等价承载时保留原规则并标记为“有意重复”。

### 2.2、允许压缩的内容 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 同一文件中连续出现、语义完全相同的句子。
- 只重复口号、背景或显而易见解释，不携带行为约束的段落。
- AGENTS 中已经由专项 Skill 完整承载的实现细节；AGENTS 保留触发索引和全局边界。
- 多个 Skill 中完全相同的 Markdown 外观规则；收口到 `jobs-markdown-docs`，专项 Skill 只保留必须遵守该规范的声明。

### 2.3、禁止以“去重”为名删除 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- Jobs 代码所有权边界与第三方排除规则。
- `JobsCodexConfigs`、`JobsSkills`、子模块指针和现行基准工作树的方向。
- `.command` 防误触、自述、日志、安装 / 更新确认和 `main` 入口规则。
- [**Swift**](https://www.swift.org/) / Objective-C DSL、“一镜到底”和返回对象类型约束。
- Markdown 首次出现专有名词的固定官方链接。
- 中文序号使用顿号 `、` 的书写习惯。
- 构建、语法、Dry Run、SourceTree 或 CodeGraph 等验证步骤。
- 规则中的例外，例如带行尾注释的 `return` 不应用 `};return`。

这些内容即使在多个文件中看似相近，也可能处在不同触发范围；没有完成语义账本前不得合并。

## 三、Markdown 防回退基线 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 3.1、序号统一使用中文顿号 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

在中文说明、流程和列表中：

```markdown
1、iOS 逆向究竟在研究什么
2、Mach-O 为什么重要
```

不要写成：

```markdown
1. iOS 逆向究竟在研究什么
2. Mach-O 为什么重要
```

版本号、域名、小数、代码、命令输出和英文原文不受此规则影响。Markdown 原生有序列表语法不是豁免理由；Jobs 文档优先保持中文顿号风格。

### 3.2、固定名词链接必须保留 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

审计至少确认 `jobs-markdown-docs/SKILL.md` 仍存在下列固定表项：

- `[**Swift**](https://www.swift.org/)`
- `[**Codex**](https://openai.com/codex)`
- `[**Understand Anything**](https://github.com/Lum1104/Understand-Anything)`
- `[**Markdown**](https://markdown.cn)`
- `[**Xcode**](https://developer.apple.com/xcode)`

固定表存在只是第一层；独立技术文档正文第一次出现这些名词时仍应补链。代码块、命令、路径、文件名和变量名中的字面量不加链接。

### 3.3、独立文档结构 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

`AGENTS.md` 和 Jobs 本人维护或已明确接管的每个 `SKILL.md` 至少检查；第三方实体目录与外援软链接只核对清单、来源和 Git 边界，不把 Jobs 文档样式强加给上游内容：

- YAML front matter 仅对 `SKILL.md` 强制，且必须位于第一行。
- 一级标题、2D 封面、`[toc]`、分隔线和前言顺序正确。
- 正文二级标题从 `## 一、` 连续编号。
- 三级标题使用 `### 1.1、`。
- 底部保留“我是有底线的”回顶锚点。

## 四、审计工作流 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 4.1、运行只读审计 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

先执行本 Skill 自带脚本：

```shell
zsh ./jobs-codex-config-audit/scripts/audit_codex_configs.zsh
```

脚本只读输出结构、中文句号序号、固定链接、防重复候选、两个仓库状态和子模块指针差异；它不会自动删除、修改、提交或部署文件。

### 4.2、人工判断语义重复 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

对脚本给出的候选项逐条检查：

1、同一条规则是否只是表达相近，实际适用范围不同。

2、是否一个是全局边界，一个是专项落地步骤。

3、是否一个包含另一个没有的例外或验证。

4、删掉后，单独加载目标 Skill 时是否仍能完成任务。

5、把保留位置和搜索证据写进审计结论。

### 4.3、做最小编辑 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 全局行为留在 `AGENTS.md`，细节放对应 Skill。
- 一条规则只选一个主归属；其它位置保留短触发引用，不复制全文。
- 不为了减少行数把清晰步骤压成含糊长句。
- 长文件只有在触发范围清晰且可以独立加载时才拆分 reference；不要把关键硬约束藏到不会被读取的文件。

### 4.4、验证编辑结果 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

```shell
python3 /Users/jobs/.codex/skills/.system/skill-creator/scripts/quick_validate.py ./jobs-codex-config-audit
zsh -n ./jobs-codex-config-audit/scripts/audit_codex_configs.zsh
zsh ./jobs-codex-config-audit/scripts/audit_codex_configs.zsh
```

再检查：

```shell
git -C /Users/jobs/.agents/skills diff --check
git -C /Users/jobs/.agents/skills diff
git -C /Users/jobs/Documents/Github/JobsGenesis/JobsConfigOS/💻JobsCodexConfigs diff --check
git -C /Users/jobs/Documents/Github/JobsGenesis/JobsConfigOS/💻JobsCodexConfigs diff -- AGENTS.md .gitmodules skills
```

必须人工阅读最终 Diff，确认没有把“减少字数”误当成“完成优化”。

## 五、仓库、子模块与注入一致性 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 5.1、维护原则 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

全局规则只在 `JobsCodexConfigs/AGENTS.md` 中维护，专项规则只在现行 `JobsSkills` 工作树中维护。修改 `JobsSkills` 后先单独提交、推送子仓，再在 `JobsCodexConfigs` 中更新 `skills` 子模块指针；不在父仓保留第二份直接跟踪的 Skills 文件。

配置注入脚本只部署 `AGENTS.md`，并扫描现行 `JobsSkills` 生成受控注册块；不复制、删除或覆盖 `JobsSkills` 工作树。

### 5.2、部署后验证 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

```shell
cmp ./AGENTS.md /Users/jobs/.codex/AGENTS.md
git -C /Users/jobs/.agents/skills remote get-url origin
git -C /Users/jobs/Documents/Github/JobsGenesis/JobsConfigOS/💻JobsCodexConfigs submodule status -- skills
```

子模块检出可以暂时落后于现行 `JobsSkills` 工作树，但必须显式报告两者提交号；不得用落后的子模块反向覆盖现行基准。

## 六、每周任务的完成定义 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 6.1、每周审计必须输出 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- `JobsCodexConfigs` 与 `JobsSkills` 两个 Git 状态和本轮明确修改范围。
- 结构违规、中文序号违规和固定链接基线结果。
- 重复候选及“合并 / 保留为有意重复”的判断。
- 被修改规则的语义账本和防回退说明。
- Skill 校验、Shell 语法和 Diff 检查结果。
- `AGENTS.md` 部署一致性、`JobsSkills` 远端与子模块指针；未同步时说明原因。

### 6.2、每周审计不得自动做 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 不删除未知 Skill、第三方 Skill 或插件缓存。
- 不修改 `.codex/skills/.system` 与插件安装目录。
- 不提交、不推送、不清理工作区。
- 不把临时观察写进永久规则。
- 不因“本周无变化”制造格式性改动。

无安全可合并项时，结论应是“审计完成，无需修改”，而不是为了让任务看起来有产出而删内容。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
