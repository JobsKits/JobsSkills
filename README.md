# `Codex` 用户级 `Skills`

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[toc]

---

## 🔥 <font id=前言>前言</font>

> 本仓库管理 [**JobsSkills**](https://github.com/JobsKits/JobsSkills)，可作为 [**Codex**](https://openai.com/codex) 用户级 `Skills` 的运行工作树，也可挂载为配置父仓的子模块。Jobs 自有 `Skill`、外部安装的 `Skill` 和外援软链接可以同时出现，但必须分清所有权、上游来源和 [**Git**](https://git-scm.com/) 跟踪边界。

## 一、目录职责 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 唯一标准仓库是 `https://github.com/JobsKits/JobsSkills`，`~/.agents/skills` 是现行、内容最完整的基准工作树。
- `💻JobsCodexConfigs/skills` 是 `JobsCodexConfigs` 父仓对本仓库的 Git 子模块挂载点，便于父仓记录所使用的 `JobsSkills` 版本；自动配置注入不反向覆盖现行工作树。需要手动同步时，使用本目录 `同步Skills.command` 明确选择方向和范围，预览确认后执行。
- 外援 `Skill` 依旧由其上游仓库管理源码和版本；本仓库只记录来源和运行态链接映射。

## 二、Git 管理边界 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| 类型 | Git 处理 | 信息来源 |
| --- | --- | --- |
| Jobs 自有 `Skill` | 在本仓库中跟踪完整内容 | `JobsSkills` |
| 外部安装的实体目录 | 按各自安装器、锁定文件或上游仓库溯源 | 例如 `~/.agents/.skill-lock.json` |
| 外援软链接 | 不进入 Git 索引，在 `.gitignore` 中按精确名称忽略 | 本文档的来源和映射表 |

Git 对软链接只保存“目标路径字符串”，不保存链接目标的内容。当软链接指向仓库外的本机绝对路径时，直接提交会使克隆结果依赖特定机器目录。因此本目录使用“`.gitignore` 排除运行态链接 + `README.md` 保留溯源信息”的组合方式。

`.gitignore` 中使用完整链接名称，不使用 `/understand*` 之类的宽泛规则，避免误伤以后新增的同前缀自有 `Skill`。

## 三、外援软链接溯源 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

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

## 四、溯源与恢复检查 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

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

3、链接失效时，先恢复上游仓库，再按本文档映射表重建链接；软链接不进入本仓库 Git 索引，也不把外援源码混入 Jobs 自有 `Skill` 内容。手动同步外援 `Skill` 时生成独立实体副本，来源仍按上游映射追溯。

## 五、双向选择同步 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

在本目录双击 `同步Skills.command`，或在终端运行：

```shell
./同步Skills.command
```

脚本中的仓库端按脚本自身位置解析，系统端使用当前用户的 `.agents/skills`。两种方向互为相反操作：

| 选项 | 同步方向 |
| --- | --- |
| `1`（默认） | 系统用户级 Skills → 当前目录 |
| `2` | 当前目录 → 系统用户级 Skills |

1、先阅读脚本内置自述，按回车继续；`Ctrl+C` 随时取消。

2、选择方向后，由 [**fzf**](https://formulae.brew.sh/formula/fzf) 展示源端可同步的 `Skill` 包。第一项为“全部同步”，默认光标停在这一项，直接回车即全部同步；输入名称搜索，`Tab` / `Shift+Tab` 多选，回车提交所选项，`Esc` 取消。

3、查看所选包和变更预览，输入 `YES` 后执行；其它输入取消。同步按内容校验，以源端同名内容为准，保留目标端独有文件；已有目标先完整备份。源端软链接复制为实体，目标端软链接安全替换，不写入其上游目录。

4、只处理包含 `SKILL.md` 的包；包内嵌套 `Skill` 和配套资源一起同步。根目录的 `.git`、`.gitignore`、`README.md`、同步脚本，以及内置 `.system` 和插件缓存不在全选范围内；包内 Git 元数据及常见构建缓存同样排除。

5、脚本不创建提交、推送或更新父仓 gitlink。同步产生的文件变更由各自工作树正常管理；外援名称的现有精确忽略规则继续有效。

只查看计划时运行 `./同步Skills.command --dry-run`；仍需选择方向和范围，但不安装依赖、不备份或复制。用法说明为 `./同步Skills.command --help`，帮助模式不写文件。目标包中发现 `.git` 时停止，保护嵌套仓库。

日志是系统临时目录中的 `同步Skills.log`，每次运行重新写入。持久备份默认保存在当前用户 `.local/state/jobs-skills-sync/backups/`，也遵循已设置的 `XDG_STATE_HOME`；每次生成唯一的 `YYYY.MM.DD HH-mm-ss.随机后缀` 目录。`original/` 保存原始目录和软链接结构，`resolved/` 保存链接解引用后的完整实体快照，`同步说明.txt` 记录方向、两端路径和所选包。需要恢复实体内容时使用 `resolved/`；需要恢复原链接时先确认其上游仍存在，再使用 `original/`。

依赖仅为可用的 `fzf`、`rsync` 和系统工具。缺失或损坏的 `fzf` 可经现有 [**Homebrew**](https://brew.sh/) 安装或修复：回车跳过，输入任意字符确认；脚本先检查 Homebrew 和 Command Line Tools，安装后复检，失败后停止同步，不自动安装整套环境。

隔离验证或使用其它工作树时可覆盖以下环境变量；路径须为绝对路径，两端须已存在，状态目录不能放在任一 Skills 树内或脚本的父 Git 工作树内：

| 环境变量 | 作用 |
| --- | --- |
| `JOBS_SKILLS_SYNC_SYSTEM_DIR` | 系统用户级 Skills 根目录 |
| `JOBS_SKILLS_SYNC_REPO_DIR` | 当前仓库 Skills 根目录 |
| `JOBS_SKILLS_SYNC_STATE_DIR` | 日志以外的持久状态及备份根目录 |

每个包通过同文件系统暂存目录合并并重命名切换。途中失败立即停止，已完成的其它包不会自动回滚；完整备份与失败现场保留，具体路径显示在日志中。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➔点我回到首页</a>
