---
name: jobs-git-repository
description: 当任务涉及 JobsMacEnvVarConfigs、Git 仓库结构、.gitmodules 多平台子模块、父子仓 README、Markdown 目录过滤器、嵌套仓库、SourceTree 逐层提交推送、GitHub / Gitee 分支映射、OC main / byPods 与独立快照例外、脚本安装/升级入口或仓库级配置同步规则时使用。
---

# Jobs [**Git**](https://git-scm.com/) 仓库规则

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#%E5%89%8D%E8%A8%80)
- [一、Git 仓库规则](#jobs-toc-heading-2)
  - [1.1、🌍JobsMacEnvVarConfigs 仓库](#jobs-toc-heading-3)
  - [1.2、仓库级 Shell 脚本统一整改](#jobs-toc-heading-4)
  - [1.3、父仓子模块的 Git 元数据集中管理](#jobs-toc-heading-5)
  - [1.4、父子仓的多平台配置与 README 速览](#submodule-multi-platform)
    - [1.4.1、Git 克隆与拉取的来源显示](#git-source-logging)
  - [1.5、逐层推送的单本地分支与双平台同步](#jobs-toc-heading-8)
  - [1.6、OC 双工作目录与 Gitee 独立快照例外](#oc-main-bypods-snapshot)
  - [1.7、每个 Git 仓库的 README 与脚本概述](#repository-readme-contract)
  - [1.8、Markdown 目录过滤器的仓库接入与验证](#markdown-toc-git)

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

> 本技能由 `💻JobsCodexConfigs/AGENTS.md` 拆分而来，保留原有 Jobs 工作规范。只有当前任务命中本技能描述时才加载本文件，避免把所有细则长期塞进全局上下文。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、Git 仓库规则 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-3" data-jobs-toc="v2">1.1、🌍JobsMacEnvVarConfigs 仓库 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 处理 `🌍JobsMacEnvVarConfigs` 仓库或其安装 / 升级入口前，必须完整读取同级附件[JobsMacEnvVarConfigs 路径约定](./路径约定-JobsMacEnvVarConfigs.md)，按其中的入口职责、同名目录和能力同步规则执行。

### <span id="jobs-toc-heading-4" data-jobs-toc="v2">1.2、仓库级 Shell 脚本统一整改 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 批量扫描多个仓库或目录前，先识别嵌套关系并对真实路径去重，避免同一脚本被重复改写。
- 开始修改前必须检查各 Git 工作区和子模块状态；已有改动一律保留，在其基础上继续工作，不得通过回滚或覆盖换取批量处理便利。
- 扫描时默认跳过 `.git`、`node_modules`、`Pods`、`.dart_tool`、`build` 和 `DerivedData`，同时识别扩展名与真实文件类型不一致的替身、书签或二进制文件。
- 区分可独立执行的入口脚本与仅供 `source` 的函数库；入口脚本的 `main()` 必须服从 `jobs-macos-shell` 的“高层步骤集中编排、每个函数调用带职责注释、禁止单次转调包装”规范，函数库不得为了形式统一而强加入口。
- 批量改写前后都要按脚本真实解释器执行静态语法检查，并单独审计 `main()` 结构；出现既有失败时记录基线，整改不得引入新增失败。

### <span id="jobs-toc-heading-5" data-jobs-toc="v2">1.3、父仓子模块的 Git 元数据集中管理 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 当父仓通过 `.gitmodules` 和 gitlink 管理独立子仓时，Jobs 默认将子仓元数据集中保存在父仓实际 Git 目录（`git rev-parse --git-dir`）下的 `modules/` 中；子仓工作目录根部使用 `.git` 文件指向对应元数据目录。这是子模块的本地管理布局，不改变子仓独立提交历史、远端或分支。
- 开始整理前，先核对父仓 `.gitmodules`、gitlink、子模块路径和 `git submodule status`，并记录父仓及子仓的工作区状态。仅处理已登记且当前检出存在的子模块；保留已有源码改动、未跟踪文件、提交和远端，不用元数据整理顺带提交、推送或更新子仓。
- 对已登记但子仓内部仍有 `.git` 文件夹的路径，使用 [**Git**](https://git-scm.com/) 提供的 `git submodule absorbgitdirs` 迁移管理目录，不手工移动或重建 Git 元数据。

  ```shell
  git submodule absorbgitdirs -- <子模块路径>
  ```

- 如果父仓 `modules/` 中对应目标目录已存在且非空，Git 会拒绝覆盖。先检查其 `core.worktree`、HEAD、refs 和当前工作树指针；确认属于失效遗留元数据后，完整保留到唯一的隔离备份路径，再让 Git 命令迁移当前子仓。无法确认归属或仍有有效工作树引用时立即停止，不删除、不覆盖、不合并两套元数据。
- 整理后确认子仓根部 `.git` 是包含有效 `gitdir:` 目标的文件；通过 `git -C <子模块路径> rev-parse --show-toplevel --git-dir --show-superproject-working-tree` 和 `git submodule status` 核对工作目录、元数据位置、父仓关系及提交号，并复查父仓和子仓状态，确保源码、索引和既有改动没有被改变。
- 未登记为子模块的嵌套独立仓库继续保留自己的 `.git` 文件夹。把它登记成子模块会改变父仓的跟踪关系，必须先得到用户明确要求；登记完成后再按本节整理。链接工作树也可能使用 `.git` 指针文件，但其元数据位于 `worktrees/`，不按子模块方式迁移。

### 1.4、<span id="submodule-multi-platform">父子仓的多平台配置与 README 速览</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 新建、维护或迁移 Jobs 自维护父子仓时，必须同时考虑 `.gitmodules`、gitlink、实际父子远端和相关生成 / 下载 / 引用修复入口，按任意托管平台兼容设计，不把 [**GitHub**](https://github.com)、[**Gitee**](https://gitee.com) 两个平台写成白名单；同样适用于 [**GitLab**](https://gitlab.com) 和自建服务。已有单平台项目继续保留其明确约束，不借地址适配自动新增远端或接管未登记的嵌套仓库。
- 同站点、同 namespace 的兄弟子仓优先使用 `../真实仓名.git`。相对地址以父仓远端的仓库 URL 为基准，继承平台、namespace、协议和端口，不按磁盘目录拼接。自动相对化前，核对全部已配置目标线路的父子远端与真实仓名；跨 namespace、平台间仓名不同、缺少映射或服务端点不能确认时，保留明确地址并报告，不能机械替换 host / owner、从本地目录猜远端、忽略非默认端口或自动切回 GitHub。
- `path` 只决定本地目录，`url` 使用真实远端仓名。目录与仓名不同时必须在 README 明示，例如：

  ```ini
  [submodule "SourceTree.command"]
      path = SourceTree.command
      url = ../SourceTree.sh.git
      branch = main
  ```

- 修改相关脚本时，保留已有 section、URL、branch（包括原本未设置的状态）和扩展字段；新增字段只补缺，不因子仓当前 `origin` 是绝对地址而覆盖共享相对地址。保留各工具原有的增量关联或目录对齐职责，不把修复登记用的相对 URL 写进子仓 `origin`。
- 区分父仓默认远端与脚本显式选择的下载 remote；只增加 remote 不代表切换默认线路。多层子模块逐层以各自父仓地址解析，不能让顶层 URL 的命令行配置覆盖递归传播到所有层。支持任意主机的 HTTPS、scp SSH、`ssh://`、多层 namespace 与显式端口，无法证明跨协议端口对应关系时保留明确地址。
- 原生 `.gitmodules` 每个子模块只有一个克隆 URL，不提供多 URL 自动探活切换。目标平台必须已有对应子仓及父仓 gitlink 引用的提交；`branch` 用于远端分支跟踪，不能用分支名或相同文件树代替固定提交可达性。未知镜像和未部署平台只作为标注清楚的示例，不声称已存在、可访问或通过克隆验证。
- 父仓及相关脚本 README 必须靠前放置“当前真实配置 → 不同父仓地址解析结果表 → 必要前提与例外”，按[README 功能覆盖与示例规范](../jobs-markdown-docs/SKILL.md#readme-examples-first)编写，不能仅讲原理或只链接审计报告。当前能力优先；历史对照仅在用户要求或当前迁移操作确需时保留，新建仓库和生成示例分别如实标注。
- URL 处理或配置写入逻辑有改动时，使用隔离仓库核对多种托管地址、SSH 端口、多层 namespace、跨组织 / 异名、递归解析和既有字段保留；区分离线解析与真实远端访问证据。复查相关 README 例子、链接和代码围栏。验证不授权业务仓提交、推送、创建镜像或改写历史。

#### 1.4.1、<span id="git-source-logging">Git 克隆与拉取的来源显示</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 涉及克隆 / 拉取的 Git 自动化入口遵循[通用来源日志规范](../jobs-macos-shell/SKILL.md#script-source-logging)，涉及 remote 选择时同时显示其名称与 URL。父子仓流程还要显示父仓线路，并在每个子仓克隆 / 拉取前突出子仓名、平台 / 主机与完整来源 URL，分支确定后在对应传输前显示；成功结果带来源与提交号，失败指向对应仓库和来源。平台名只作展示，任意自建主机、端口和 namespace 均按真实地址保留，不把平台名做成下载白名单。
- 父子仓流程先按当前下载逻辑解析 `.gitmodules` 与所选父 remote，再用与该操作一致的配置作用域展开 `url.*.insteadOf`；改写前后不同时展示“解析地址”和“拉取地址”。`git ls-remote --get-url` 只做本地展开，不访问远端，不能据此声称下载或镜像已验证。首次 `clone` 不读取父仓 local 配置，来源展示须屏蔽父仓 local 重写并保留适用的系统、全局与进程规则；已有子仓 `fetch` 使用该子仓自身作用域。不要把父仓本地重写套到首次克隆上。
- 已能读取 `.gitmodules` 的递归子仓，在更新前逐层核对并显示来源；未初始化子仓按克隆作用域，已初始化子仓按自身作用域。首次原生递归克隆中尚未取得的下层配置交由 Git 输出注册 URL，不能提前猜测，或把下载后的核对日志写成“下载前已确认”。
- 来源显示与参数、错误返回、提交 / 推送策略分开维护。用临时仓库和受控命令核对首次克隆 / 已有子仓的配置作用域、多平台与端口、递归来源、打印时序及脱敏，不运行真实业务入口验收日志。
- 修改下载配置当前 Git 子模块入口及其同名副本前，必须完整读取同级附件[子模块下载入口路径约定](./路径约定-子模块下载入口.md)，同步用户指定范围内的副本与 README 示例。

### <span id="jobs-toc-heading-8" data-jobs-toc="v2">1.5、逐层推送的单本地分支与双平台同步 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 维护、排障或运行 [**Sourcetree**](https://www.sourcetreeapp.com/) 逐层空白提交并 Push 入口前，必须完整读取同级附件[逐层推送路径约定](./路径约定-SourceTree逐层推送.md)，执行单本地工作分支、双平台映射、失败停止及隔离验证要求；命中 OC 新旧工程时还必须读取下节[专用例外](#oc-main-bypods-snapshot)。

### 1.6、<span id="oc-main-bypods-snapshot">OC 双工作目录与 Gitee 独立快照例外</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 处理 OC 新旧工程的本地目录、分支映射、快照同步或相关规则前，必须完整读取同级附件[OC 双工程与 Gitee 快照路径约定](./路径约定-OC双工程与Gitee快照.md#oc-main-bypods-snapshot)；固定映射、现有 `Gitee@snapshot` 例外和只读核验边界均以该附件为准，不能套用通用逐层双远端整合。

### 1.7、<span id="repository-readme-contract">每个 Git 仓库的 README 与脚本概述</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- Jobs 自维护的每个实际 Git 工作树根目录都必须有 `README.md`，父仓、子模块和嵌套独立仓库同样适用；父仓文档不能替代子仓文档。识别 `.git` 目录和有效指针文件，并以实际工作树根目录去重，不把每个被 Git 跟踪的普通子目录都当成独立仓库。
- 已有 `README.md` 就在原文上增量补齐，不另建平行说明、不覆盖用户改动；缺失时才创建。遵循[不限格式的原文保护规则](../jobs-markdown-docs/SKILL.md#existing-document-preservation)：整理目录和格式不代表获准全文重写，修改前留快照、改后核对用户明确授权删除范围之外的实质内容仍在。README 必须说明当前真实目录结构及主要目录职责，可用简短目录树或路径 / 职责表；子仓标清独立管理关系并链接其 README，缓存、产物和第三方目录按实际边界说明。
  - 用户指出原文缺失、或本地版本不足以确认时，不能只以本地 `HEAD` 为保留基线；读取用户指定远程的真实默认 / 指定分支并保存内容快照，再比较工作区、本地历史与远程原文。远程读取只作查证，优先在临时目录取内容，不借恢复执行业务工作树的覆盖、重置、提交或推送。
- 仓库管理可运行脚本时，根 README 必须逐个简明概述其入口，包内已有专属 README 也不能代替根文档的用途与流程概述。只覆盖本仓维护的入口，父仓不展开子仓全部脚本；内部模块、仅供 `source` 的函数库、测试、供应商和生成脚本不机械套用用户操作流程。
- 功能颗粒度、历史叙述清理，以及独立功能 / 关键目录的就近 README 与上级入口，统一按[README 功能覆盖规范](../jobs-markdown-docs/SKILL.md#readme-examples-first)执行；不能只列目录或执行里程碑，遗漏实际模式、选项及使用边界。
- 当前任务新增或实际维护的 `Scripts/`、`scripts/` 等脚本目录必须同时维护就近的 `README.md`：写明该目录职责、真实文件结构、各实际脚本用途与入口、运行依赖、必要风险和产物 / 日志位置，并使用相对链接。根 README 负责总览，不能代替目录内说明；目录 README 也不替代根文档概述。已有内容增量补齐，不为满足本条扫描改写当前任务以外的脚本目录。
- 脚本概述以 `JobsGenesis/README.md` 第六章经用户确认的版式为准：完整脚本名的相对链接直接作为无编号三级标题；紧随顶格 `> **目的：** ...`；再用顶格无编号列表按执行先后写关键里程碑，条件和菜单分支缩进两个空格，写清最后结果。该类脚本三级标题不额外加序号或上下导航，步骤不用数字；这是通用文档标题规则的明确例外。
- 以源码和现有配套文档核对真实行为，简述中保留必要的确认方式、覆盖 / 删除范围、联网、提交或推送条件；不能把所有脚本套成同一模板能力，也不能仅列文件名、入口表或让用户跳转后才知道脚本做什么。三个子模块脚本保留各自独立条目，只描述当前仓真实存在的入口。
- 批量整改先逐仓记录已有工作区与 README 状态，跳过 Git 元数据、依赖、构建产物及第三方源码，不为文档任务移动脚本或修改仓库关联。交付前复查所有目标 Git 根均有 README、目录条目符合磁盘布局、实际入口概述齐全、相对链接和锚点有效，并做渲染预览；静态核对不代表已运行有副作用的业务脚本。

### 1.8、<span id="markdown-toc-git">[**Markdown**](https://markdown.cn) 目录过滤器的仓库接入与验证</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 用户确认的标准为本地编辑及拉取 / 检出后保留 `[toc]`、整文件暂存自动生成按标题层级缩进且默认收起的远端折叠目录，当前机器普通新克隆首次落盘即为 `[toc]`。目录识别、手写目录迁移、正文保护与用户自有 Skills 文档的适用边界，以 [Markdown 动态与折叠目录规则](../jobs-markdown-docs/SKILL.md#markdown-toc-filter)为主归属；本节只管 Git 接入，无目录文档不强加目录。
- 按真实 Git 工作树根目录分组并去重，识别 `.git` 目录、子模块指针文件和链接工作树；父仓不登记子仓文件，不把嵌套独立仓库当普通目录，更不为目录任务改变 `.gitmodules`、gitlink、分支或远端。非 Git 目录、未检出的子模块及所有权不明目标单列报告。
  - 任务中发现普通目录已初始化为独立 Git（如 `git init` 后）、已登记或迁移为子模块，或工作树 / 实际 Git 元数据位置已变化时，重新解析受影响的 Git 根、Git 目录与文档归属；即使文档路径未变，也不能沿用父仓或变更前的验证结论。发现变化只触发复检，不授权初始化仓库或登记子模块。
  - 对本任务范围内含有效标签的文档，按新归属对账父子仓的精确清单、属性、各仓自包含工具及有效驱动与配置来源；父仓移除的登记仅限已归子仓的路径。新仓不自动继承父仓 local 配置；仅 `absorbgitdirs` 迁移可能保留原配置，健康时保留并复检，不一律重装。缺失或失效项按本节接入流程补齐，重新 `verify`；涉及正常暂存与发布时，仍须按后文执行原始索引 `check`，目录任务本身不扩大暂存、提交或推送授权。
- 每个目标根目录携带可独立克隆使用的转换工具、精确文档清单和就近说明，当前约定采用 `.jobs-markdown-toc/MarkdownToc.mjs`、`.jobs-markdown-toc/manifest.json`（`version: 1` 与 `files`）和 `.jobs-markdown-toc/README.md`；可保留仓内已有兼容入口，但实际 local 驱动统一指向本仓自包含目录，不依赖原型仓库或本机绝对工具路径。共享 `.gitattributes` 只在成对受控注释块内登记清单中的仓库相对精确路径，正确转义空格和特殊字符，不用 `*.md` / `**/*.md` 泛化；新增或移动文档须先检测有效标签再更新清单与注册。模板及受控清单部署入口见 [Markdown Skill 的维护资源](../jobs-markdown-docs/SKILL.md#markdown-toc-filter)。
- 安装前检查现有属性与 `filter.jobs-markdown-toc` 的有效配置来源，覆盖 `clean`、`smudge`、`required` 和可能优先的 `process`；遇到其它过滤器、非本工具的同名配置、异常受控标记或高优先级属性冲突时保留原状并报告，不静默接管。仅允许有明确自身安装记录的配置升级；写前备份受影响的精确字段、清单、属性块和已有工具。
- 驱动默认限定本仓 `git config --local`，安装时解析健康的 Node.js 可执行文件并正确引用带空格路径；换机、仓库移动或 Node.js 路径变化后重新检测并复检。默认不改全局 / 系统 Git 配置、`core.hooksPath` 或已有 hook，不为自动刷新附加新的提交 / 推送动作。
- 用户明确要求当前机器新克隆无需仓内安装即还原 `[toc]` 时，必须在首次克隆前完成机器条件注册：全局配置仅增加 `includeIf "hasconfig:remote.*.url:<精确仓库地址>"` 的受控引用，驱动与经过审查的转换工具放在受信任的机器侧目录，首次检出不执行下载仓库中的脚本。只登记已核实、获准远端的精确 URL，协议及 `.git` 后缀变体逐项列明，不用通配主机、组织、仓名或无条件全局过滤器扩大范围；清单和属性仍精确限定文档。注册前检查 Git 条件支持与有效配置来源，备份本轮精确字段及工具，保留既有配置；提供只撤销本轮引用与文件的入口，不全量覆盖全局配置。换机须重新注册；单仓实验仅覆盖该仓，后续明确授权指定根推广时，按已核实的实际 Git 根及远端增量登记，无需逐仓重复确认。机器注册与仓内 local 安装独立，不能声称后者随克隆传播或扩大到未授权来源。
- 过滤器根据标准输入转换；`%f` 只供定位与清单校验，不用它读取工作区正文。目录在重新整文件 `git add` / SourceTree 暂存时由 `clean` 生成；正常提交使用索引，普通 `push` 发送已有提交，不能靠提交或推送刷新目录。安装对本地标签形态的受控文档更新修改时间，使 Git 的 stat cache 失效，后续正常整文件 `git add` 即可采用新过滤器，无需手工 `--renormalize`。安装不自动暂存、重置或检出，保留暂存内容、模式、阶段、用户 flags 与部分暂存状态；只允许下述受控 stat 缓存刷新，已有提交 / 暂存中的目录仍由用户在正常暂存流程中更新。
- `smudge` 在 Git 实际将受控文档写入工作区时执行，包括检出，以及 `pull` 合并 / 快进中确实需要写入该文档的步骤；`fetch`、已是最新的 `pull`、只更新其它文件的 `pull` 与仅配置驱动都不会重写旧文档。先检查有效属性和 `clean` / `smudge` / `required` / `process` 配置，不能因磁盘仍是生成目录就断言缺少 smudge，也不能把“pull 成功”当成本地标签已恢复。
- 子模块下载 / 同步入口按每个实际 Git 根检查有效的 `filter.jobs-markdown-toc.smudge`：非空配置存在时执行该仓 `.jobs-markdown-toc/MarkdownToc.mjs restore`，再严格 `verify`；未配置或显式禁用时显示跳过，不自动 install、不注册机器驱动、不强加目录。入口仓与所选递归子仓均适用，只拉取和维护模式保持一致；已有工作树在源码状态判定前安全还原，同步后再检查，即使没有新提交也执行已配置的还原流程。只处理当前磁盘正文，保留真实 HEAD、暂存对象 / mode / stage / flags；未完成 Git 操作、冲突或锁先停止。已配置但工具 / Node 不可用、process 冲突或 restore / verify 失败时停止并报告具体仓库，不能降级为跳过或宣称已恢复。Node 仅在配置存在时需要，不求值执行配置中的任意 Shell 文本。
  - 首次克隆若从本地预检对象库复制，使用 `clone --no-checkout`，先设置计划中的真实 remote URL，再安全首次 checkout，使按真实远端的条件驱动在第一次写文件时生效；保持预检 SHA、分支上游、元数据归集与无二次联网约束。不能临时通配注册缓存 URL，不能靠下载后 restore 冒充首次 smudge 成功；下载入口的显式还原步骤与首次检出验证分别验收。测试直接覆盖该入口的真实递归执行链，包含有配置的首次两层检出 / 无更新旧生成态恢复，以及无配置跳过且不执行工具；普通 clone 的测试不能代替临时对象库克隆路径。
- 未条件注册机器的新克隆首次安装或旧生成目录遗留时，以磁盘当前内容安全恢复 `[toc]`，保留未提交正文、已有标题与手写 `<details>`；不能从 `HEAD` / index 取旧正文覆盖，不能用强制 checkout / restore / reset 清空本地改动。独立恢复入口（如工具支持的 `restore`）只处理清单内当前文件，全部预检通过后才写入；不改变暂存内容、模式、阶段、用户 flags、部分暂存状态或 Git 配置，异常结构、符号链接、跨仓路径等不可靠输入保留并报告。安装已集成安全恢复时可运行仓内 `install` 原地还原，沿用同一保护边界；两者均无此能力时先在目标工具实现并隔离验证，不给出尚未实现的命令。
- 从发布态恢复标签后，即使 diff 为空且实际 Git clean 后的 blob OID 与索引一致，旧 stat 缓存的尺寸也可能造成假 `M` 并阻断 pull。安装 / 恢复可受控刷新这类路径的缓存：持有真实 `index.lock`，复制索引至临时索引，仅处理普通 stage 0 且经实际 Git clean 校验等于已有 OID 的路径；在临时索引更新后，核对全量 OID / mode / stage 与用户 flags 不变，并确认正文及真实索引没有并发修改，再原子写回缓存。单独无路径 `update-index --refresh` 不能作为已修复的证据；也不能直接对真实索引传路径刷新而意外暂存正文。内容不等、部分暂存或冲突路径保留其索引条目，并发变化时停止写回并报告，不能借缓存刷新自动 `git add`。
- 仓库首次接入须先在 [**SourceTree**](https://www.sourcetreeapp.com/) 审查差异，再由用户正常整文件暂存清单内全部文档（包括正文未改的旧文档与新增说明），并将根 `.gitattributes`、完整 `.jobs-markdown-toc/` 工具目录及本仓实际改动的兼容入口、测试或 CI 文件一并纳入同一待发布提交，最后对全部清单执行 `check`；不使用全部暂存混入无关修改，也不代用户暂存、提交或推送。安装不会更新已有 index blob 或提交，不能给出只暂存一份 README 就能完成首次接入的示例。已接入仓库在未注册机器的新克隆安装一次后按日常流程操作；本机已条件注册且精确命中远端时无需再安装。日常只需将改过的受控文档整文件暂存。新增或移动含标签文档时，先增量更新清单与根 `.gitattributes` 精确路径，再按实际安装方式更新注册、运行 `verify`，正常暂存文档及对应清单、属性改动后执行 `check`。
- SourceTree 与命令行均以整文件暂存为推荐入口；部分暂存、`git add -p` 或网页改标题可能使正文与目录不同步。提供索引检查命令，从原始 index blob 读取清单内已暂存文件，将其重新计算后比较，不能拿工作区内容或再次经过过滤器的结果冒充索引校验；未跟踪 / 尚不在 index 的新清单文件单列提示，不误报已通过提交检查。
- 仓内说明须区分未注册机器的一次仓内安装与已条件注册机器的新克隆自动还原；恢复旧生成态仍只转换当前内容并保护已有正文。若提供机器注册入口，写清精确远端范围、受信任工具位置、依赖检查及独立撤回方式，不用仓内 `uninstall` 冒充机器注册已撤销。已有 CI 按本仓流程整合目录校验，缺失时提供可调用检查入口；不批量强塞某个平台流水线、不自动提交目录修复，不声称仅凭本地配置能覆盖网页编辑和所有客户端。
- 过滤器目录的 `README.md` 必须给出可复制的实际命令及执行目录，覆盖 `install`、`status`、`check`、`verify`、`preview [仓库相对文档路径]` 与 `uninstall`；工具具备安全恢复入口时，补齐 `restore` 的用途和命令。以当前 `MarkdownToc.mjs` 为例，在其同级目录使用 `node ./MarkdownToc.mjs install`。`check` 检查清单内全部原始索引版本，`verify` 只读检查工作区；两者不刷新真实索引缓存。预览示例选用清单中真实文档，并说明安装 / 恢复 / 卸载影响范围、依赖与产物。
- 本地验收同时核对转换字节往返和磁盘形态：当前内容必须已是 `smudge(当前内容)` 的结果，恢复有效目录标签，且不残留本工具生成的目录与标题包装。只有 `smudge(clean(原文))` 往返通过不够，旧版 `verify` 可能接受生成态；先核对该仓实际实现，必要时单独检查或增强只读验证，再报告结果。严格本地验证不等于原始索引 `check`，更不等于托管平台渲染通过。
- 仓内 `uninstall` 先核对文档和现行配置，按安装记录恢复本工具 local 字段，在工作区保留最新折叠目录；共享工具、清单与 `.gitattributes` 登记保留供重新安装。机器条件注册需独立撤回，仍生效时不能声称目录已停止自动转换。用户明确要求完整撤销仓库接入时，才依据备份精确恢复受控属性块及本工具文件，并保留用户后加内容；发现配置已被外部修改时停止冲突项并报告，不全量覆盖 `.git/config` 或 `.gitattributes`。保留已暂存 / 已提交内容，不借卸载清空索引或删除历史目录；批量安装失败时按每仓记录精确恢复本轮已改项目。
- 验证使用隔离仓库或 `GIT_INDEX_FILE` 指向的临时索引，覆盖真实暂存 / 检出、中文和空格路径、标题增删改、幂等与字节往返、异常标记、冲突保护、重装 / 卸载和部分暂存失配；校验无标签与第三方文件未被匹配，真实工作区 / 索引及原有属性配置未受损。
- 验收机器注册的“新克隆即还原”必须直接执行普通 `git clone` 并使用首次检出结果，不先运行仓内 `install`、不设置 local 过滤器、不以事后 restore / checkout 代替；同时核对磁盘为 `[toc]` 且无自有包装、原始 index / `HEAD` 是生成态、整文件暂存生成目录、`git status` 干净及配置来源符合精确条件。覆盖并行检出、仓内脚本故意失败仍可转换、错误远端不生效、撤回条件引用后新克隆恢复生成态。隔离远端可证明 Git 首次检出流程，真实托管远端与各平台渲染另记实测证据。
- 补齐安装后的拉取恢复能力时，在独立临时仓库配本地 bare remote 与两个克隆：发布端提交生成目录，接收端新克隆安装后不得出现假 `M`，再通过 `pull --ff-only` 成功接收标题 / 正文更新，核对原始 index / `HEAD` 是生成态、磁盘为标签态且正文一致；该结果只证明安装后的拉取，不得冒充未安装的新克隆验收。另测已有生成态只运行无更新 `pull` 不会自动恢复、从当前文件安全恢复可保留未提交正文，以及缓存刷新保留部分暂存和用户 flags。临时索引能证明 clean / index 转换，不能单独证明真实 pull。
- 用户要求先单仓实验时，先交付该仓实测证据；确认推广后，以验收仓的实现为基准同步共享模板、部署器和指定范围内的目标仓库，并覆盖用户明确纳入的自有 Skills 文档，不以旧实验限制阻止已授权推广。用户区分源仓与下载验收副本时，代码、工具与说明在指定源仓维护，下载副本默认只读；不直接改样本或运行 restore / install 后冒充首次克隆成功。验证当前源仓代码使用独立新目录，远端发布验收也从全新普通克隆取得结果；未提交的源仓改动不能声称已随远端下载。交付分别报告扫描命中、已接入、排除 / 冲突、已验证和待实际平台验收的数量，不把未提交的接入或临时索引通过当成远端已生效。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
