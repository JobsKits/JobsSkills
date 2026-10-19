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

- 处理 `🌍JobsMacEnvVarConfigs` 仓库时，先分清根目录入口脚本和 `scripts/` 下的解耦脚本，不要把二者混成一类。
- `scripts/` 是存放解耦脚本代码的目录；这里面的脚本主文件名对应终端里的命令名，脚本文件统一以 `.command` 作为后缀。
- `scripts/` 下每一个具体的 `*.command` 脚本，都必须由同名文件夹包裹，并且每个脚本文件夹内都必须放置这个脚本对应的 `README.md`。

  ```text
  scripts/
  ├── install.command/
  │   ├── install.command
  │   └── README.md
  └── update.command/
      ├── update.command
      └── README.md
  ```

- `scripts/install.command/install.command` 和仓库根目录下的 `install.command/install.command` 不是同一个职责：

  | 入口位置 | 核心职责 | 处理原则 |
  | -------- | -------- | -------- |
  | `scripts/install.command/install.command` | 利用 `zsh` 配置安装 [**MacOS**](https://www.apple.com/macos/) 系统的各种自定义依赖。 | 面向依赖安装和本机环境构建。 |
  | `install.command/install.command` | 将 `JobsMacEnvVarConfigs` 内容同步到系统。 | 主要瞄准终端 `zsh` 配置同步。 |

- `scripts/update.command/update.command` 是全员升级入口；凡是 `scripts/install.command/install.command` 新增、删除或调整安装能力，都必须同步更新升级入口，保持安装与升级能力平行，不允许只改安装不改升级。
- 写或改这个仓库的脚本时，要随时对照安装与升级两个入口：安装负责“从无到有”，升级负责“已有环境持续更新”，两者覆盖的工具链和交互顺序应尽量一致。

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
- 父仓及相关脚本 README 必须靠前放置“真实配置 / 改写前后对照 → 不同父仓地址解析结果表 → 必要前提与例外”，按[README 示例优先规范](../jobs-markdown-docs/SKILL.md#readme-examples-first)编写，不能仅讲原理或只链接审计报告。只有确有历史变更时才写“以前”；原本已是相对地址、新建仓库和生成示例分别如实标注。
- URL 处理或配置写入逻辑有改动时，使用隔离仓库核对多种托管地址、SSH 端口、多层 namespace、跨组织 / 异名、递归解析和既有字段保留；区分离线解析与真实远端访问证据。复查相关 README 例子、链接和代码围栏。验证不授权业务仓提交、推送、创建镜像或改写历史。

#### 1.4.1、<span id="git-source-logging">Git 克隆与拉取的来源显示</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 涉及克隆 / 拉取的 Git 自动化入口遵循[通用来源日志规范](../jobs-macos-shell/SKILL.md#script-source-logging)，涉及 remote 选择时同时显示其名称与 URL。父子仓流程还要显示父仓线路，并在每个子仓克隆 / 拉取前突出子仓名、平台 / 主机与完整来源 URL，分支确定后在对应传输前显示；成功结果带来源与提交号，失败指向对应仓库和来源。平台名只作展示，任意自建主机、端口和 namespace 均按真实地址保留，不把平台名做成下载白名单。
- 父子仓流程先按当前下载逻辑解析 `.gitmodules` 与所选父 remote，再用与该操作一致的配置作用域展开 `url.*.insteadOf`；改写前后不同时展示“解析地址”和“拉取地址”。`git ls-remote --get-url` 只做本地展开，不访问远端，不能据此声称下载或镜像已验证。首次 `clone` 不读取父仓 local 配置，来源展示须屏蔽父仓 local 重写并保留适用的系统、全局与进程规则；已有子仓 `fetch` 使用该子仓自身作用域。不要把父仓本地重写套到首次克隆上。
- 已能读取 `.gitmodules` 的递归子仓，在更新前逐层核对并显示来源；未初始化子仓按克隆作用域，已初始化子仓按自身作用域。首次原生递归克隆中尚未取得的下层配置交由 Git 输出注册 URL，不能提前猜测，或把下载后的核对日志写成“下载前已确认”。
- 来源显示与参数、错误返回、提交 / 推送策略分开维护。修改 `【MacOS】⏬下载配置当前Git子模块.command` 时查齐用户指定范围内全部同名副本，统一来源日志并保留各仓清单；对应 README 展示真实平台和完整地址的运行例子。用临时仓库和受控命令核对首次克隆 / 已有子仓的配置作用域、多平台与端口、递归来源、打印时序及脱敏，不运行真实业务入口验收日志。

### <span id="jobs-toc-heading-8" data-jobs-toc="v2">1.5、逐层推送的单本地分支与双平台同步 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- `【MacOS@SourceTree】🚀逐层空白提交并Push.command` 的常用场景是“大 Git 套小 Git”：每个父仓、子仓各自维护一份代码和一个已有本地工作分支，同步到 [**GitHub**](https://github.com) 与 [**Gitee**](https://gitee.com) 各自的主分支。维护、排障和运行此脚本都必须遵守本节。
- 保持原有本地工作分支，不因托管平台不同而额外创建本地 `gitee`、镜像、同步、备份、救援或临时分支；不能通过 `branch`、`checkout -b`、`switch -c/-C`、`update-ref refs/heads/...` 等路径绕过。游离 HEAD 只允许恢复到明确的已有本地分支；分支不存在或目标不明确时，在清理和提交前停止。
- 两个平台的远端主分支名称可以不同，按各仓已确认的配置分别映射；例如同一个本地 `main` 可同步 GitHub 的 `main` 与 Gitee 的 `gitee`。远端别名、远端跟踪引用和本地分支是不同概念；配置 `gitee` remote 或获取 `refs/remotes/gitee/...` 不要求建立本地 `gitee` 分支。
- 先获取并整合全部已配置目标线路的历史，再用同一最终 `HEAD` 分别显式推送到 `refs/heads/<该平台主分支>`，逐条核验提交号一致；只有单条已配置线路的子仓继续按单线处理，不自动创建远端仓库。禁止将额外本地分支带到远端，禁止 `push --all`、`push --mirror` 或通配推送 `refs/heads/*`。无法确定映射、整合冲突或推送失败时停止，不创建替代分支、不强推。
- 已存在的额外本地或远端分支不属于本规则的自动清理授权；保留并报告，不擅自删除或改名。OC 新旧工程的固定映射及现有独立快照按[专用例外](#oc-main-bypods-snapshot)处理，不借通用逐层脚本建立辅助分支或合并两套历史。
- 修改分支相关逻辑后，用隔离仓库核对运行前后本地分支名称集合不增加、正常分支不切换、两端只更新指定主分支且最终提交号一致；同时覆盖远端主分支异名、游离态已有 / 缺失本地分支、失败停止的路径。不用真实业务仓库的提交或推送验证规则。

### 1.6、<span id="oc-main-bypods-snapshot">OC 双工作目录与 Gitee 独立快照例外</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- OC 新旧工程由两个磁盘目录中的独立本地 Git 仓库管理，两处各自拥有独立 Git 元数据，同一托管平台上共用远端仓库地址，以分支区分工程形态。用户于 2026-10-16 再次确认下列职责映射，不能套用通用的 Gitee 远端目标统一为 `gitee` 的命名规则。

  | 本地工作目录 | 日常工作分支 | GitHub 远端分支 | Gitee 远端分支 |
  | --- | --- | --- | --- |
  | `/Users/jobs/Documents/Github/JobsBaseConfig/JobsBaseConfig@JobsOCBaseConfigDemo`，功能集成主工程 | `main` | `main` | `main` |
  | `/Users/jobs/Documents/Github/JobsOCBaseConfigDemo@ByPods`，功能下沉本地 Pod | `byPods` | `byPods` | `byPods`，发布源为现有本地 `Gitee@snapshot` |

- `Gitee@snapshot` 的原因是当时 Gitee 旧历史与仓库容量问题，已有报告记录服务端 `Repo size ... exceeds quota` 拒绝。用户选择 GitHub 保留完整历史，Gitee 从当前已提交文件树建立独立零点，该分支专门承载已授权的独立发布链。证据位于新工程 `ScriptsByDevTools/gitee_snapshot.command/README.md` 的容量问题及零点快照说明，不把历史故障扩写为未经核验的当前平台限额。
- 专用同步复用 `byPods` 已提交文件树：首次快照没有父提交，后续只延续快照父链，树未变化时复用现有快照提交。两边追求文件树一致，提交号和历史可以不同；禁止将完整 `byPods` 历史、其它分支或标签混入 Gitee 的快照发布链，也不为追求相同 HEAD 而合并两条历史。
- 开发、提交和拉取 GitHub 始终使用 `byPods`；推送映射固定为 `byPods → origin/byPods`、`Gitee@snapshot → gitee/byPods`。快照只供专用同步及发布，不用切换到该分支开发，不发布到 GitHub，也不在远端创建同名 `Gitee@snapshot`。现有专用 hook 和推送映射必须保留，不运行通用逐层双远端整合去绕过它们。
- 本地分支职责限定为：旧工程工作分支 `main`，新工程工作分支 `byPods` 加已有发布分支 `Gitee@snapshot`。后者是仅属于新工程的明确例外，不推广到其它仓库；不得自动为两处补建对方的工作分支或再建立 `gitee`、同步、备份、救援分支。远端跟踪引用不计为本地工作分支。
- 保留 `Gitee@snapshot` 的大小写和 `@`；它由既有快照链改名而来。旧名称 `codex/gitee-snapshot`、`gitee-snapshot` 已淘汰，安装或同步时先识别并复用现有分支标记、有效配置和快照根标记，多候选或映射不明确时停止，不能因旧配置重建旧名称或生成第二条快照链。
- 对其它已有本地分支先核验用途和独有提交并报告；新增、删除、改名或重写历史须有用户明确授权。远端地址由两处共用，清空仓库或删除远端 `main` / `byPods` 会影响另一工程，不能从本地分支整理推导远端清理授权。
- 上表定义分支职责，不证明两平台当前都已同步。先只读核对两处 Git 身份、当前分支、upstream、push refspec、快照开关及目标；只读梳理时按需使用 `ls-remote` 确认服务端，不运行安装器、同步脚本、hook、fetch 或 push，也不自动补建缺失远端分支。仅要求提炼原因或写入规则时，只修改规则文档。

### 1.7、<span id="repository-readme-contract">每个 Git 仓库的 README 与脚本概述</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- Jobs 自维护的每个实际 Git 工作树根目录都必须有 `README.md`，父仓、子模块和嵌套独立仓库同样适用；父仓文档不能替代子仓文档。识别 `.git` 目录和有效指针文件，并以实际工作树根目录去重，不把每个被 Git 跟踪的普通子目录都当成独立仓库。
- 已有 `README.md` 就在原文上增量补齐，不另建平行说明、不覆盖已有内容和用户改动；缺失时才创建。遵循[不限格式的原文保护规则](../jobs-markdown-docs/SKILL.md#existing-document-preservation)：整理目录和格式不代表获准全文重写，修改前留快照、改后核对原有正文与章节仍在。README 必须说明当前真实目录结构及主要目录职责，可用简短目录树或路径 / 职责表；子仓标清独立管理关系并链接其 README，缓存、产物和第三方目录按实际边界说明。
  - 用户指出原文缺失、或本地版本不足以确认时，不能只以本地 `HEAD` 为保留基线；读取用户指定远程的真实默认 / 指定分支并保存内容快照，再比较工作区、本地历史与远程原文。远程读取只作查证，优先在临时目录取内容，不借恢复执行业务工作树的覆盖、重置、提交或推送。
- 仓库管理可运行脚本时，根 README 必须逐个简明概述其入口，包内已有专属 README 也不能代替根文档的用途与流程概述。只覆盖本仓维护的入口，父仓不展开子仓全部脚本；内部模块、仅供 `source` 的函数库、测试、供应商和生成脚本不机械套用用户操作流程。
- 当前任务新增或实际维护的 `Scripts/`、`scripts/` 等脚本目录必须同时维护就近的 `README.md`：写明该目录职责、真实文件结构、各实际脚本用途与入口、运行依赖、必要风险和产物 / 日志位置，并使用相对链接。根 README 负责总览，不能代替目录内说明；目录 README 也不替代根文档概述。已有内容增量补齐，不为满足本条扫描改写当前任务以外的脚本目录。
- 脚本概述以 `JobsGenesis/README.md` 第六章经用户确认的版式为准：完整脚本名的相对链接直接作为无编号三级标题；紧随顶格 `> **目的：** ...`；再用顶格无编号列表按执行先后写关键里程碑，条件和菜单分支缩进两个空格，写清最后结果。该类脚本三级标题不额外加序号或上下导航，步骤不用数字；这是通用文档标题规则的明确例外。
- 以源码和现有配套文档核对真实行为，简述中保留必要的确认方式、覆盖 / 删除范围、联网、提交或推送条件；不能把所有脚本套成同一模板能力，也不能仅列文件名、入口表或让用户跳转后才知道脚本做什么。三个子模块脚本保留各自独立条目，只描述当前仓真实存在的入口。
- 批量整改先逐仓记录已有工作区与 README 状态，跳过 Git 元数据、依赖、构建产物及第三方源码，不为文档任务移动脚本或修改仓库关联。交付前复查所有目标 Git 根均有 README、目录条目符合磁盘布局、实际入口概述齐全、相对链接和锚点有效，并做渲染预览；静态核对不代表已运行有副作用的业务脚本。

### 1.8、<span id="markdown-toc-git">[**Markdown**](https://markdown.cn) 目录过滤器的仓库接入与验证</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 用户确认的日常方式为本地 `[toc]` 动态目录、整文件暂存自动生成远端折叠目录；标签识别、生成块、正文保护及平台验收以 [Markdown 动态与折叠目录规则](../jobs-markdown-docs/SKILL.md#markdown-toc-filter)为主归属。本节只管 Git 接入，不要求把所有 `.md` 都纳入；无有效标签的文档不登记、不添目录。
- 按真实 Git 工作树根目录分组并去重，识别 `.git` 目录、子模块指针文件和链接工作树；父仓不登记子仓文件，不把嵌套独立仓库当普通目录，更不为目录任务改变 `.gitmodules`、gitlink、分支或远端。非 Git 目录、未检出的子模块及所有权不明目标单列报告。
  - 任务中发现普通目录已初始化为独立 Git（如 `git init` 后）、已登记或迁移为子模块，或工作树 / 实际 Git 元数据位置已变化时，重新解析受影响的 Git 根、Git 目录与文档归属；即使文档路径未变，也不能沿用父仓或变更前的验证结论。发现变化只触发复检，不授权初始化仓库或登记子模块。
  - 对本任务范围内含有效标签的文档，按新归属对账父子仓的精确清单、属性、各仓自包含工具及有效 local 驱动；父仓移除的登记仅限已归子仓的路径。新仓不自动继承父仓 local 配置；仅 `absorbgitdirs` 迁移可能保留原配置，健康时保留并复检，不一律重装。缺失或失效项按本节接入流程补齐，重新 `verify`；涉及正常暂存与发布时，仍须按后文执行原始索引 `check`，目录任务本身不扩大暂存、提交或推送授权。
- 每个目标根目录携带可独立克隆使用的转换工具、精确文档清单和就近说明，当前约定采用 `.jobs-markdown-toc/MarkdownToc.mjs`、`.jobs-markdown-toc/manifest.json`（`version: 1` 与 `files`）和 `.jobs-markdown-toc/README.md`；可保留仓内已有兼容入口，但实际 local 驱动统一指向本仓自包含目录，不依赖原型仓库或本机绝对工具路径。共享 `.gitattributes` 只在成对受控注释块内登记清单中的仓库相对精确路径，正确转义空格和特殊字符，不用 `*.md` / `**/*.md` 泛化；新增或移动文档须先检测有效标签再更新清单与注册。模板及受控清单部署入口见 [Markdown Skill 的维护资源](../jobs-markdown-docs/SKILL.md#markdown-toc-filter)。
- 安装前检查现有属性与 `filter.jobs-markdown-toc` 的有效配置来源，覆盖 `clean`、`smudge`、`required` 和可能优先的 `process`；遇到其它过滤器、非本工具的同名配置、异常受控标记或高优先级属性冲突时保留原状并报告，不静默接管。仅允许有明确自身安装记录的配置升级；写前备份受影响的精确字段、清单、属性块和已有工具。
- 驱动配置限定本仓 `git config --local`，安装时解析健康的 Node.js 可执行文件并正确引用带空格路径；换机、仓库移动或 Node.js 路径变化后重新安装并复检。不改全局 / 系统 Git 配置、`core.hooksPath` 或已有 hook，不为自动刷新附加新的提交 / 推送动作。
- 过滤器根据标准输入转换；`%f` 只供定位与清单校验，不用它读取工作区正文。刷新发生在重新整文件暂存时；普通 `push` 只发送已有提交，不会重新生成目录。安装对本地标签形态的受控文档只更新修改时间，使 Git 的 stat cache 失效，正文与真实索引不变，后续正常整文件 `git add` 即可采用新过滤器，无需手工 `--renormalize`。安装不自动暂存、重置、检出或改写真实索引；已有提交 / 暂存中的目录须由用户在正常暂存流程中更新。
- 仓库首次接入须先在 [**SourceTree**](https://www.sourcetreeapp.com/) 审查差异，再由用户正常整文件暂存清单内全部文档（包括正文未改的旧文档与新增说明），并将根 `.gitattributes`、完整 `.jobs-markdown-toc/` 工具目录及本仓实际改动的兼容入口、测试或 CI 文件一并纳入同一待发布提交，最后对全部清单执行 `check`；不使用全部暂存混入无关修改，也不代用户暂存、提交或推送。安装不会刷新已有 index 或提交，不能给出只暂存一份 README 就能完成首次接入的示例。已接入仓库的新克隆安装一次后按日常流程操作；日常只需将改过的受控文档整文件暂存。新增或移动含标签文档时，先增量更新清单与根 `.gitattributes` 精确路径，再运行 `install`、`verify`，正常暂存文档及对应清单、属性改动后执行 `check`。
- SourceTree 与命令行均以整文件暂存为推荐入口；部分暂存、`git add -p` 或网页改标题可能使正文与目录不同步。提供索引检查命令，从原始 index blob 读取清单内已暂存文件，将其重新计算后比较，不能拿工作区内容或再次经过过滤器的结果冒充索引校验；未跟踪 / 尚不在 index 的新清单文件单列提示，不误报已通过提交检查。
- 新克隆的一次安装须在仓内说明中写清，恢复本地标签时只转换当前内容并保护已有正文。已有 CI 按本仓流程整合目录校验，缺失时提供可调用检查入口；不批量强塞某个平台流水线、不自动提交目录修复，不声称仅凭本地配置能覆盖网页编辑和所有客户端。
- 过滤器目录的 `README.md` 必须给出可复制的实际命令及执行目录，覆盖 `install`、`status`、`check`、`verify`、`preview [仓库相对文档路径]` 与 `uninstall`；以当前 `MarkdownToc.mjs` 为例，在其同级目录使用 `node ./MarkdownToc.mjs install`。`check` 检查清单内全部原始索引版本，`verify` 只读检查工作区转换与往返；清楚区分两者，不能把工作区验证通过称作已暂存目录通过。预览示例选用清单中真实文档，并说明安装 / 卸载影响范围、依赖与产物。
- `uninstall` 先核对文档和现行配置，按安装记录恢复本工具 local 字段，在工作区保留最新折叠目录；共享工具、清单与 `.gitattributes` 登记保留供重新安装，后续目录不再自动刷新。用户明确要求完整撤销仓库接入时，才依据备份精确恢复受控属性块及本工具文件，并保留用户后加内容；发现配置已被外部修改时停止冲突项并报告，不全量覆盖 `.git/config` 或 `.gitattributes`。保留已暂存 / 已提交内容，不借卸载清空索引或删除历史目录；批量安装失败时按每仓记录精确恢复本轮已改项目。
- 验证使用隔离仓库或 `GIT_INDEX_FILE` 指向的临时索引，覆盖真实暂存 / 检出、中文和空格路径、标题增删改、幂等与字节往返、异常标记、冲突保护、重装 / 卸载和部分暂存失配；校验无标签与第三方文件未被匹配，真实工作区 / 索引及原有属性配置未受损。交付分别报告扫描命中、已接入、排除 / 冲突、已验证和待实际平台验收的数量，不把未提交的接入当成远端已生效。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
