---
name: jobs-markdown-docs
description: 当任务涉及已有文档的增量编辑与内容保护（不限文件格式），或 Markdown、README 及项目统计、技术文档、[toc] 动态与折叠目录、表格、流程图、外链、专有名词链接、文档封面和文档结构时使用。
---

# Jobs [**Markdown**](https://markdown.cn) 文档规范

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#jobs-toc-heading-1)
- [一、Markdown 文档（\*.md）](#jobs-toc-heading-2)
  - [1.1、整体风格](#jobs-toc-heading-3)
  - [1.2、代码块与缩进](#jobs-toc-heading-4)
  - [1.3、外链、表格与流程图](#jobs-toc-heading-5)
    - [1.3.1、专有名词固定超链接](#jobs-toc-heading-6)
  - [1.4、README 固定内容与示例优先](#readme-examples-first)
  - [1.5、本地动态目录与远端折叠目录](#markdown-toc-filter)
- [二、已有文档的增量编辑与原文保护（不限格式）](#existing-document-preservation)

</details>
<!-- jobs-toc:end -->

---

## <span id="jobs-toc-heading-1" data-jobs-toc="v2">🔥 <span id="前言">前言</span></span><!-- jobs-toc:heading-end -->

> 本技能由 `💻JobsCodexConfigs/AGENTS.md` 拆分而来，保留原有 Jobs 工作规范。只有当前任务命中本技能描述时才加载本文件，避免把所有细则长期塞进全局上下文。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、[**Markdown**](https://markdown.cn) 文档（`*.md`） <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-3" data-jobs-toc="v2">1.1、整体风格 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- Jobs 的 `.md` 文档默认使用中文技术笔记风格，结构清楚、标题醒目、能直接复制命令执行。
- 修改 `AGENTS.md` 本身时，也必须反哺本文件：把它当成普通 [**Markdown**](https://markdown.cn) 技术文档同步套用本章规则，专有名词按固定链接表补链，归属于上一条的补充内容必须右缩进。
- `SKILL.md` 同样属于 `*.md` 文档，必须完整遵守本技能的封面、目录、标题编号、外链、缩进和底部锚点规则；不能因为它同时承载 Skill 元数据就跳过 Markdown 公约。
- `SKILL.md` 的 YAML front matter 必须保持在文件第一行；关闭 front matter 后，再依次写一级标题、封面、`[toc]`、分隔线和“前言”。
- 每个独立 Markdown 文档都重新计算标题序号：正文二级标题必须从 `## 一、...` 开始连续递增，不能继承来源文档或拆分前文档的旧章节号；三级标题同步从 `### 1.1、...` 开始，并与所属二级标题保持一致；四级标题使用 `#### 1.1.1、...`，标题层级必须和编号层级一致。
- `*.md` 文档头部必须有图形化展示。默认使用 2D 封面；只有文档主题明确需要空间感、地球、模型、三维可视化时，才使用 3D 效果。2D 和 3D 二选一，不要在同一篇文档头部堆叠两套封面。

  - 2D 封面统一使用 [**Picsum**](https://picsum.photos) 随机图，当前固定代码如下：

    ```markdown
    ![Jobs出品，必属精品](https://picsum.photos/1500/400)
    ```

  - 3D 效果统一使用 `iframe`，当前固定代码如下：

    ```html
    <iframe
      src="https://dragonir.github.io/3d/#/earth"
      title="Jobs出品，必属精品"
      width="100%"
      height="400"
      style="border:0; display:block;"
      allowfullscreen>
    </iframe>
    ```

  - 常规 Markdown / README / AGENTS 文档优先使用 2D 封面，兼容性最好；如果目标平台不支持 `iframe`，3D 效果必须回退为 2D 封面。

  ```markdown
  # `标题`

  ![Jobs出品，必属精品](https://picsum.photos/1500/400)

  [toc]

  ---
  ```

- `前言` 是二级标题，但不参与中文序号：

  ```markdown
  ## 🔥 <font id=前言>前言</font>
  ```

- 正文二级标题优先使用中文编号：`## 一、...`、`## 二、...`。
- 三级标题使用阿拉伯编号：`### 2.1、...`、`### 2.2、...`。
  - 仓库 README 的脚本概述是明确例外：脚本名链接直接作无编号三级标题，不加标题上下导航；目的引用与无编号时序列表的完整约定见 [Git 仓库 README 规范](../jobs-git-repository/SKILL.md#repository-readme-contract)。
- 中文正文中的步骤、次序和数字列表统一使用顿号 `、`，例如 `1、iOS 逆向究竟在研究什么`；不要写成 `1.iOS ...` 或 `1. iOS ...`。即使 Markdown 支持 `1.` 原生有序列表，Jobs 中文文档仍优先使用 `1、` 并在相邻条目之间保留空行。版本号、小数、域名、代码、命令输出和引用的英文原文不受此规则影响。
- 长文档按[动态与折叠目录规则](#markdown-toc-filter)维护可点击章节目录，并在流程、状态、权限、规则、异常处理等跨章节引用处补充必要内链；不额外维护一份重复的手写总目录，也不为无关词语堆叠内链。
- 内链统一使用相对地址：同一文档使用 `#章节锚点`，跨文件使用以当前 Markdown 所在目录为基准的 `./文件.md`、`../目录/文件.md`，必要时追加 `#章节锚点`；不写本机绝对路径或 `file://`。外部官方链接仍使用完整 HTTPS 地址。
- 除文档主标题和“前言”外，正文每个二级及以下标题末尾都必须追加两个导航链接：第一个返回 `#前言`，第二个跳转到文末 `#🔚`。标题文字本身承载章节锚点；需要稳定的文章内跳转时，在标题文字的非空 HTML 元素上设置唯一、语义明确的 `id`，内链使用同一 `id`，不依赖渲染器自动生成的标题编号或 slug，不另加空锚点。
- 文档没有单独的“前言”时，将 `#前言` 目标加到现有文档主标题；若没有一级标题，则加到第一个正文标题上，不虚构前言正文，也不插入空锚点。
- 两个导航链接统一使用以下格式；文末须存在对应的 `🔚` 锚点，并提供返回前言的入口：

  ```markdown
  [工单流程](#work-order-flow)

  ## 一、<span id="work-order-flow">工单流程</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

  <a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
  ```

- 交付前检查文章内链接目标存在且 `id` 唯一；实际预览核对目录、跨章节内链及标题上下导航的跳转，不把 `[toc]` 指令本身视为导航已可用。

### <span id="jobs-toc-heading-4" data-jobs-toc="v2">1.2、代码块与缩进 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 命令示例统一使用 fenced code block，并标注语言。
- 凡是内容属于上一条说明的补充、示例或展开，都必须向右缩进两个空格，让视觉层级归属于上一条；包括代码块、表格、引用、图片、[**Mermaid**](https://mermaid.js.org) 流程图、子列表。
- bullet 下方的代码块必须缩进两个空格，让代码块视觉上归属于这条说明；不要让代码块顶到页面左边。

  ````markdown
  - 只要涉及“升级 / 更新 / upgrade / update”，都必须遵守这条规则。

    ```shell
    ask_any_to_run() {
      local message="$1"
      local answer=""
      read -r "?${message}（直接回车跳过；输入任意字符后回车执行）：" answer
      [[ -n "$answer" ]]
    }
    ```
  ````

- bullet 下方的表格必须写成上一条的子内容：上一条 bullet 结束后保留空行，表格每一行源码都以两个空格开头，格式必须像下面这样，不要顶格写表格。

  ````markdown
  - 如果用户明确给了新的官方链接，以用户最新指定为准，顺手更新这张表。

    | 推荐写法                            | 识别别名          | 固定链接                  |
    | ----------------------------------- | ----------------- | ------------------------- |
    | [**Markdown**](https://markdown.cn) | `Markdown` / `md` | `https://markdown.cn`     |
    | [**Mermaid**](https://mermaid.js.org) | `Mermaid`         | `https://mermaid.js.org`  |
  ````

- [**Markdown**](https://markdown.cn) 中的路径、命令、文件名、变量名都用反引号包起来，例如 `LOG_FILE`、`$TMPDIR/脚本名.log`、`README.md`。

### <span id="jobs-toc-heading-5" data-jobs-toc="v2">1.3、外链、表格与流程图 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 正文中出现可识别的外部产品、第三方工具、框架、语言或平台时，第一次出现必须使用官方链接并加粗名称，格式为 `[**名称**](URL)`，例如 [**Homebrew**](https://brew.sh/)、[**Flutter**](https://flutter.dev/)、[**CocoaPods**](https://cocoapods.org/)、[**Mermaid**](https://mermaid.js.org)。后续出现时可按阅读需要继续加链接。
- 标题、表格、正文均按首次出现原则加链接；代码块、命令、路径、文件名里的字面量不要加链接。
- 表格用于阶段说明、参数说明、目录统计、命令清单；表头短一点，内容能扫读。
- Markdown 文档中的业务流程、操作流程、状态流转和交互时序统一使用 [**Mermaid**](https://mermaid.js.org)，以标注 `mermaid` 的 fenced code block 保留可编辑源码；根据表达内容选用 `flowchart`、`stateDiagram-v2` 或 `sequenceDiagram`。属于上一条说明的图与代码围栏同样右缩进两个空格。

  ```mermaid
  flowchart TD
      A[提交工单] --> B{审核通过?}
      B -->|是| C[派单维修]
      B -->|否| D[补充资料]
      D --> A
  ```

- 流程图必须与正文的节点、状态、分支条件和异常路径一致；交付前检查代码围栏闭合，并在支持 Mermaid 的预览中验图。无法渲染时说明未完成视觉验证，保留源码，不将截图作为唯一交付。
- 对用户有风险的地方要写明白，不要藏在代码块后面。危险动作必须在文档里说明确认方式，例如“必须输入 `YES` 才会继续”。
- 文档语气可以保留 Jobs 风格短句，例如“Jobs出品，必属精品”“我是有底线的”，但正文要优先服务操作，不堆装饰。

#### <span id="jobs-toc-heading-6" data-jobs-toc="v2">1.3.1、专有名词固定超链接 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 写 [**Markdown**](https://markdown.cn) / README / AGENTS 这类技术文档时，外部产品和第三方专有名词必须在正文第一次出现时写成 `[**名称**](官方URL)`；下表固定名称必须使用给定链接。需要强调或便于点击时，后续也可以继续加链接。
- 用户指定需要下划线的专有名词，仍须保留加粗超链接；例如 <u>[**Swift**](https://www.swift.org/)</u> 应写成 `<u>[**Swift**](https://www.swift.org/)</u>`。
- 同一个工具有多个常见写法时，正文优先使用“推荐写法”；括号里的别名只用于识别，不强行改代码块里的命令。
- 代码块、命令、路径、文件名、变量名里的字面量不要加超链接，例如 `brew install fzf`、`Podfile`、`python3`、`go-task/tap/go-task`。
- 如果用户明确给了新的官方链接，以用户最新指定为准，顺手更新这张表。

  | 推荐写法                                                               | 识别别名                                              | 固定链接                                           |
  | ------------------------------------------------------------------ | ------------------------------------------------- | ---------------------------------------------- |
  | [**Markdown**](https://markdown.cn)                                | `Markdown` / `md`                                 | `https://markdown.cn`                          |
  | <u>[**Swift**](https://www.swift.org/)</u>                          | `Swift`                                           | `https://www.swift.org/`                       |
  | [**Go**](https://go.dev/)                                           | `Go`                                              | `https://go.dev/`                              |
  | [**TiDB**](https://docs.pingcap.com/tidb/stable/)                   | `TiDB`                                            | `https://docs.pingcap.com/tidb/stable/`        |
  | [**SnapKit**](https://github.com/SnapKit/SnapKit)                   | `SnapKit`                                         | `https://github.com/SnapKit/SnapKit`           |
  | [**Dart**](https://dart.dev)                                       | `Dart`                                            | `https://dart.dev`                             |
  | [**Flutter**](https://flutter.dev/)                                | `Flutter`                                         | `https://flutter.dev/`                         |
  | [**Ruby**](https://www.ruby-lang.org)                              | `Ruby`                                            | `https://www.ruby-lang.org`                    |
  | [**Homebrew**](https://brew.sh/)                                   | `Homebrew` / `brew`                               | `https://brew.sh/`                             |
  | [**Gem**](https://rubygems.org/)                                   | `Gem` / `gem` / `RubyGems`                        | `https://rubygems.org/`                        |
  | [**CocoaPods**](https://cocoapods.org/)                            | `CocoaPods` / `Cocoapods` / `pod`                 | `https://cocoapods.org/`                       |
  | [**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) | `Objective-C` / `OC`                             | `https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html` |
  | [**git-lfs**](https://git-lfs.com/)                                | `git-lfs` / `Git LFS`                             | `https://git-lfs.com/`                         |
  | [**gh**](https://formulae.brew.sh/formula/gh)                      | `gh` / `GitHub CLI`                               | `https://formulae.brew.sh/formula/gh`          |
  | [**nushell**](https://www.nushell.sh/)                             | `nushell` / `nu`                                  | `https://www.nushell.sh/`                      |
  | [**rbenv**](https://formulae.brew.sh/formula/rbenv)                | `rbenv`                                           | `https://formulae.brew.sh/formula/rbenv`       |
  | [**Node.js**](https://nodejs.org)                                  | `node` / `Node.js`                                | `https://nodejs.org`                           |
  | [**jenv**](https://www.jenv.be)                                    | `jenv`                                            | `https://www.jenv.be`                          |
  | [**fvm**](https://fvm.app)                                         | `fvm`                                             | `https://fvm.app`                              |
  | [**pnpm**](https://pnpm.io/)                                       | `pnpm`                                            | `https://pnpm.io/`                             |
  | [**Python**](https://www.python.org)                               | `python` / `python3` / `Python`                   | `https://www.python.org`                       |
  | [**fastlane**](https://fastlane.tools)                             | `fastlane`                                        | `https://fastlane.tools`                       |
  | [**MySQL**](https://www.mysql.com)                                 | `mysql` / `MySQL`                                 | `https://www.mysql.com`                        |
  | [**Hugo**](https://gohugo.io)                                      | `hugo` / `Hugo`                                   | `https://gohugo.io`                            |
  | [**OpenJDK**](https://openjdk.org)                                 | `openjdk` / `OpenJDK`                             | `https://openjdk.org`                          |
  | [**yt-dlp**](https://ytdlp.online)                                 | `yt-dlp`                                          | `https://ytdlp.online`                         |
  | [**FFmpeg**](https://ffmpeg.org)                                   | `ffmpeg` / `FFmpeg`                               | `https://ffmpeg.org`                           |
  | [**go-task**](https://formulae.brew.sh/formula/go-task)            | `go-task` / `tap/go-task` / `go-task/tap/go-task` | `https://formulae.brew.sh/formula/go-task`     |
  | [**uv**](https://formulae.brew.sh/formula/uv)                      | `uv`                                              | `https://formulae.brew.sh/formula/uv`          |
  | [**fzf**](https://formulae.brew.sh/formula/fzf)                    | `fzf`                                             | `https://formulae.brew.sh/formula/fzf`         |
  | [**lazygit**](https://lazygit.dev)                                 | `lazygit`                                         | `https://lazygit.dev`                          |
  | [**dufs**](https://formulae.brew.sh/formula/dufs)                  | `dufs`                                            | `https://formulae.brew.sh/formula/dufs`        |
  | [**Codex**](https://openai.com/codex)                              | `codex` / `Codex`                                 | `https://openai.com/codex`                     |
  | [**CodeGraph**](https://github.com/colbymchenry/codegraph)          | `codegraph` / `CodeGraph`                        | `https://github.com/colbymchenry/codegraph`    |
  | [**Understand Anything**](https://github.com/Lum1104/Understand-Anything) | `Understand Anything` / `Understand-Anything` / `understand-anything` | `https://github.com/Lum1104/Understand-Anything` |
  | [**Mermaid**](https://mermaid.js.org)                              | `Mermaid`                                         | `https://mermaid.js.org`                       |
  | [**Picsum**](https://picsum.photos)                                | `Picsum` / `picsum.photos`                       | `https://picsum.photos`                       |
  | [**Hammerspoon**](https://www.hammerspoon.org)                     | `Hammerspoon`                                     | `https://www.hammerspoon.org`                  |
  | [**VLC**](https://www.videolan.org/vlc)                            | `VLC`                                             | `https://www.videolan.org/vlc`                 |
  | [**trex**](https://formulae.brew.sh/cask/trex)                     | `trex`                                            | `https://formulae.brew.sh/cask/trex`           |
  | [**Visual Studio Code**](https://code.visualstudio.com)            | `Visual Studio Code` / `VS Code` / `code`         | `https://code.visualstudio.com`                |
  | [**Android Studio**](https://developer.android.com/studio?hl=zh-c) | `Android Studio`                                  | `https://developer.android.com/studio?hl=zh-c` |
  | [**GitHub**](https://github.com)                                   | `GitHub` / `github`                               | `https://github.com`                           |
  | [**Xcode**](https://developer.apple.com/xcode)                     | `Xcode`                                           | `https://developer.apple.com/xcode`            |
  | [**pip**](https://pip.pypa.io)                                     | `pip`                                             | `https://pip.pypa.io`                          |
  | [**JobsKits**](https://github.com/JobsKits)                        | `JobsKits`                                        | `https://github.com/JobsKits`                  |
  | [**JobsDocs Shell 脚本代码片段**](https://github.com/JobsKits/JobsDocs/blob/main/🔥Shell脚本代码片段.md/Shell脚本代码片段.md) | `Shell脚本代码片段` / `JobsDocs 脚本片段`        | `https://github.com/JobsKits/JobsDocs/blob/main/🔥Shell脚本代码片段.md/Shell脚本代码片段.md` |

### 1.4、<span id="readme-examples-first">README 固定内容与示例优先</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 每个 Jobs 自维护 [**Git**](https://git-scm.com/) 父仓、子仓的根目录都必须有 `README.md`，已有原文补齐真实目录结构和本仓脚本用途 / 执行里程碑，具体范围与版式统一遵循 [Git 仓库 README 规范](../jobs-git-repository/SKILL.md#repository-readme-contract)。
- 软件工程项目顶层 `README.md` 的统计要求独立维护在同目录的 [README 项目统计条款](./README规范-项目统计条款.md)。编写或维护项目 README，或处理统计口径、前后端规模、第三方依赖、业务文件占比时，必须先读取该附属规范，再按本文件的格式规则排版；条款保留为独立文件，不合并进本文件。已有 `.codegraph/` 时优先使用其资料，无索引时直接依据源码和项目配置核实，不因统计或绘图主动初始化索引。
- 每个可双击脚本目录优先放同名脚本和 `README.md`；Python 工具系列如果采用外层多平台入口脚本 + 内层 Python 工程结构，不要求每个 `.bat` / `.command` 单独配套 `README.md`，由外层总 `README.md` 统一说明各入口。
- 当前任务新增或实际维护的 `Scripts/`、`scripts/` 等脚本目录，就近补齐目录内 `README.md`，不能只用父目录说明代替；目录职责、实际入口及风险的内容边界见 [Git 仓库与脚本 README 规范](../jobs-git-repository/SKILL.md#repository-readme-contract)。只处理本任务命中目录，不据此批量改写无关脚本目录。
- 脚本 README 是 Jobs 脚本“三层自述”的第一层：它位于脚本文件之外，通常与主脚本平级，面向用户运行前阅读；它必须描述脚本行为特征，但不能替代脚本头部注释自述和运行时内置自述。
- README 用中文说明，适合用户双击前先看懂：用途、适用场景、执行前检查、操作流程、是否有风险、日志位置、常见问题。
- 涉及配置、改动或操作结果的 README，优先在前言后或首个详细章节前给出结论、真实代码 / 配置和结果对照表，再解释原理；采用“原写法 → 当前真实写法 → 实际运行或解析结果”时，原写法必须有真实依据。新建仓库、原本已正确的配置及生成示例直接说明现状，不能虚构历史。速览必须独立讲清要点，不能只甩报告链接。
- 父仓 / 子仓 README 的速览必须包含本仓或登记本仓的直接父仓实际 `.gitmodules` 小段、“父仓地址 → 子仓解析地址”表，以及 `path` 为本地目录、`url` 为真实仓名的区别；尚未登记时标明是拟生成示例，不为叶子子仓伪造 `.gitmodules`。列出已配置线路；其它托管平台、自建服务或端口示例明确标注未部署 / 未验证，缺映射时只写未配置，不把假设镜像写成真实地址。Git 配置与例外归[父子仓多平台规范](../jobs-git-repository/SKILL.md#submodule-multi-platform)，文档随实际行为同步。
- 将镜像与固定提交须存在、跨组织 / 异名的明确地址例外等成立前提，紧邻示例简短写明；后面的理论和风险章节补充细节，不让读者先通读长文才能判断例子是否适用。交付前逐项对账实际配置、结果表、链接与锚点。
- 技术文档优先包含这些块，按需要取舍：`前言`、`适用场景`、`运行方式`、`执行前检查`、`脚本执行命令`、`流程图`、`日志文件`、`常见问题`、`风险说明`、`未执行声明`。
- README 里凡是涉及项目内文件、脚本、产物、目录树和命令参数的路径，默认以当前 `README.md` 所在目录为基准写相对路径，例如 `./启动脚本.command`、`./项目目录/README.md`；不要把 `$HOME` 这类本机绝对路径写进可交付 README。确实位于当前目录树外的日志、缓存或系统位置，只写文件名和位置说明，例如“系统临时目录中的 `脚本名.log`”，避免写死绝对路径。
- README 不写成变更日志，不使用“本次更新”“本次升级内容”“本次已按某标准升级”这类阶段性口吻。需要说明改造结果时，要改写成全量描述：脚本目标、适用场景、完整运行行为、环境兼容策略、交互规则、日志路径、风险边界和排查方式。
- 修改或升级任何配套 `README.md` 的脚本、命令或生成器时，必须在同一任务中同步对账 README；至少检查用途、能力边界、参数与默认值、依赖、交互、执行流程、日志、产物路径、风险、流程图和验证状态，不能只改实现不改文档。
- README 如果包含 `VS`、竞品或第三方工具对比，每次上游脚本升级都必须重新核对双方当前能力、版本基线、官方链接、对比矩阵和选型结论；不允许只修改日期，或沿用未经复核的旧结论。
- 上述同步要求属于本 Skill 的通用维护规则，不要在每个具体 README 中重复写“强制维护规则”；具体 README 只保留该文档当前需要展示的真实内容和对比结果。

### 1.5、<span id="markdown-toc-filter">本地动态目录与远端折叠目录</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- Jobs 用 [**Typora**](https://typora.io/) 编辑时，本地继续保留独占行的 `[toc]`，让编辑器随标题实时生成目录；通过 [**Git clean / smudge 过滤器**](https://git-scm.com/docs/gitattributes#_filter)在暂存与检出时自动转换。手写静态链接或每次人工运行刷新命令不算完成该方案。仓库接入、暂存边界和卸载统一遵循[Git 目录过滤器规则](../jobs-git-repository/SKILL.md#markdown-toc-git)。

  | 环节 | 文档形态与刷新时机 |
  | --- | --- |
  | 本地编辑 | 保留 `[toc]`，目录由编辑器动态展示。 |
  | 整文件暂存 | `clean` 从 Git 传入的该版完整正文生成最新链接，写入自有标记包裹的折叠目录。 |
  | 远端浏览 | 默认收起的 `<details>` / `<summary>`，点击展开后跳转章节。 |
  | 检出 | `smudge` 还原各位置的原目录标签及大小写，并撤销自有标题包装。 |

- 接入范围只包括用户指定目录内、Jobs 自有或明确接管、正文含有效 `[toc]` 的 `.md`；标签大小写均识别，合法多个标签按原位置分别生成同一目录，并逐字保留 `[toc]` / `[TOC]` 等原写法供检出还原。已接入文件的自有生成块视为对应标签的发布形态。代码围栏、缩进代码、行内代码、注释、原始 HTML 示例及说明文字中出现的字面量不计。没有有效标签的文件不新增目录、不修改；未来新文档也先检测标签再登记，不能用 `*.md` 广泛过滤替代受控范围。第三方、供应商、生成文档和所有权不明文件继续排除。
- `clean` 只能转换标准输入的内容，不回读工作区同名文件；按该版正文的标题层级生成目录，排除代码示例、注释与目录自身，标题中的返回前言 / 文末导航不进入目录名称。已有唯一语义 `id` 仅在目标渲染器保留时复用，不能依赖可能被剥离的旧 HTML 元素。发布形态需要稳定锚点时，可用自有标记包裹标题文字的非空 `span`，由 `smudge` 完整还原；验证平台差异、中文、重复标题和特殊字符，不插入空锚点、不改写工作区标题。
- 每个目录位置使用本工具专属、成对且可识别的生成块标记，例如 `<!-- jobs-toc:start -->` / `<!-- jobs-toc:end -->`；`smudge` 只撤销本工具的目录块与可逆标题包装，不移除用户自写的 `<details>`、锚点或其它目录。合法多个标签不能合并或删减；嵌套、孤立、错序的生成标记、异常结构或不能可靠解析时停止并报告，不能猜测性删除内容。转换必须幂等，且 `smudge(clean(原文))` 逐字节还原原文，包括标签大小写、BOM、换行形式和文件末尾换行；自有转换范围外的正文、示例、图片、链接与已有改动保持不变。
- 折叠展示分别以 [**GitHub 官方说明**](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/organizing-information-with-collapsed-sections)与 [**GitLab 官方说明**](https://docs.gitlab.com/user/markdown/#collapsible-section)为依据；[**Gitee**](https://gitee.com)或自建服务按目标渲染器实际预览验证，不把本地预览或某一平台通过写成所有平台已验收。
- 新克隆须按仓库内工具安装一次，过滤器 local 配置不会随克隆传播；安装后以现有工作区内容恢复本地标签，不用强制检出覆盖未提交正文。[**Node.js**](https://nodejs.org) 路径变化或换机后重新检测依赖并复检配置。过滤器工具目录自带 `README.md`，按 [Git 目录过滤器规则](../jobs-git-repository/SKILL.md#markdown-toc-git)提供可复制安装、状态、索引检查、只读验证、预览和卸载命令，区分仓库首次接入时审查并整文件暂存全清单与配套工具文件、日常仅整文件暂存改动文档的流程，不替用户自动暂存。新增或移动含标签文档须更新清单与精确属性后重新安装、验证；仅获准处理含标签文档时，不为追加说明修改无标签业务 README。用户明确要求的工具 / `Scripts` 目录说明按授权单独补齐。
- 批量处理先只读列出命中文档、归属 Git 根、排除项与既有状态，写前留快照，改后验证字节往返、标题增删改后的目录、原有章节及导航仍在。用隔离仓库或独立临时索引验证暂存 / 检出，不操作真实暂存区，不因接入自动提交或推送；暂存检查与平台实测的完成程度分别报告。
- 维护或接入 `.jobs-markdown-toc/` 时，先读取 [完整模板说明](./assets/markdown-toc/README.md)，复用同目录的 [自包含转换工具](./assets/markdown-toc/MarkdownToc.mjs)、[受控清单模板](./assets/markdown-toc/manifest.json)和说明文档三件套。模板清单只登记随包的工具 README；目标仓库的其它文档按有效标签与所有权核实后增量登记，保留已有清单，不照搬来源仓库的文件名单。批量部署使用 [受控清单部署器](./scripts/deploy-markdown-toc.mjs)，由审核清单生成目标 `manifest.json`，不临时重写同类转换逻辑。先审核含 `root`、`candidates`、`excluded` 的 JSON 清单，候选项逐个给出 `path`、`repoRoot`、`sha256` 和 `approved: true`；不从目录根自动推定全部文件获准。部署器校验范围与盘点后变化，默认仅生成计划报告，添加 `--apply` 才写入各仓。

  在本 Skill 目录运行，清单和报告文件名按当前任务替换；先核对计划，再对同一审核清单执行部署：

  ```shell
  node ./scripts/deploy-markdown-toc.mjs \
    --inventory ./已审核目录清单.json \
    --report ./目录部署计划.json

  node ./scripts/deploy-markdown-toc.mjs \
    --inventory ./已审核目录清单.json \
    --report ./目录部署结果.json \
    --apply
  ```

## 二、<span id="existing-document-preservation">已有文档的增量编辑与原文保护（不限格式）</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 对任何已有内容的文档，默认只增量补充或局部编辑；适用于 Markdown、纯文本、Word、PDF、表格、演示文稿及在线文档，不能把旧正文、历史记录或原有章节用新稿整份覆盖。只有用户主动、明确要求覆盖或全文重写时，才可在其指定范围内替换；“整理、优化、完善、升级、统一格式”本身不构成清空原文的授权。
- 写入前先读取当前文档，保留可核对的原文快照或版本，确定本次修改位置；保留用户已有改动，以及与本任务无关的正文、表格、附件、批注和结构。读取不全或格式不能可靠解析时，不得生成一份新稿直接盖掉原件；先补齐读取或采用能够保留原内容的局部操作。
- 优先使用追加、精确补丁、段落 / 单元格 / 页面级编辑。工具只能提交整份内容时，必须从完整原文合并本次改动，再写回合并结果；不能以新生成的概要或模板代替原文。写入前复读当前版本，检测到并发变化时重新合并，不用旧快照覆盖更新。
- 修改后对照快照或版本差异，除用户明确授权替换 / 删除的范围外，确认原有实质内容仍在、新内容处于预期位置，且格式、链接、附件等未被误删；富文本和分页文档同时预览结果。发现误删只从已核实版本恢复误删部分，保留本轮及并发新增内容，再补充本次内容，不整份回滚；核查来源可包括本地历史及用户指定远程，不能仅凭本地当前版本断言旧内容不存在。
- 各格式专项工作流继续负责具体读写与渲染方法，本节负责共同的原文保护边界；仓库 README 的目录和脚本说明同时遵循 [Git 仓库 README 规范](../jobs-git-repository/SKILL.md#repository-readme-contract)。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
