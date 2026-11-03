---
name: jobs-markdown-docs
description: 当任务涉及已有文档的增量编辑与内容保护（不限文件格式），或 Markdown、README、软件项目需求与交付文档、项目统计、技术文档、[toc] 动态与折叠目录、表格、流程图、外链、专有名词链接、文档封面和文档结构时使用。
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
  - [1.4、README 功能覆盖、操作颗粒度与示例](#readme-examples-first)
  - [1.5、本地动态目录与远端折叠目录](#markdown-toc-filter)
- [二、已有文档的增量编辑与原文保护（不限格式）](#existing-document-preservation)
- [三、软件项目需求与交付文档](#software-project-documents)

</details>
<!-- jobs-toc:end -->

---

## <span id="jobs-toc-heading-1" data-jobs-toc="v2">🔥 <span id="前言">前言</span></span><!-- jobs-toc:heading-end -->

> 本技能由 `💻JobsCodexConfigs/AGENTS.md` 拆分而来，保留原有 Jobs 工作规范。只有当前任务命中本技能描述时才加载本文件，避免把所有细则长期塞进全局上下文。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、[**Markdown**](https://markdown.cn) 文档（`*.md`） <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-3" data-jobs-toc="v2">1.1、整体风格 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- Jobs 的 `.md` 文档默认使用中文技术笔记风格，结构清楚、标题醒目、能直接复制命令执行。
- README 排版保持紧凑：同一正文段落不为固定列宽或纯视觉布局人为提行，删除重复空行；连续单行列表项可紧凑排列，但不合并不同段落、步骤或列表项，不把清楚的多段说明压成长句。
- 标题、段落、列表、代码块、表格和 HTML 块之间保留语义或渲染需要的空行，段落式中文步骤仍按本节约定分隔。代码围栏及缩进代码内部、命令续行、表格行、目录树、引用和用于硬换行的行尾双空格或反斜杠保持原意；`<br>`、空段落或空标签只有核实仅承担多余留白且不含锚点、布局或其它语义后才删除。清理后对比预览，不能靠全局删空行或盲目拼行压缩文档。
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
- 外链和文件链接的显示文字使用可读名称，普通文档链接目标中的中文、emoji 优先保留可读 Unicode 字符；已有百分号编码属于 URL 转义，不直接视为字符集损坏，只在确认目标不变时还原中文、emoji 的编码，避免正文暴露长串 `%E...` 或未解析的 `[标签](路径)`。签名 URL、查询串及具有结构含义的保留字符编码不盲目解码，不能为美观改变地址语义。
- Markdown 链接目标含空格或括号时使用 `[标签](<相对路径>)`，例如 `[脚本说明](<./中文目录 (示例)/README.md>)`；文件名含 ASCII 方括号时转义显示文字中的 `\[`、`\]`，目标仍按真实路径填写。HTML 链接使用带引号的 `href`，不把 Markdown 链接嵌进 HTML 链接标签。修改后以当前文档目录为基准核对本地目标及片段，预览确认显示文字、点击目标和标题中的链接均正确，没有语法泄漏；远程访问及目标平台渲染未验证时如实说明。
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

### 1.4、<span id="readme-examples-first">README 功能覆盖、操作颗粒度与示例</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- README 首先回答“目标程序现在能做什么、各项功能做到哪一步、怎样使用、结果和限制是什么”。前言后靠前放当前功能总览；按源码、入口和真实配置核对功能覆盖，不能以版本说明、历史修复记录、验证批次、文件名清单或笼统用途代替现有能力说明。
- 独立功能逐项展开到用户可以选择和操作的颗粒度：模式、子命令、菜单分支、参数 / 选项及默认值、输入与适用范围、输出 / 产物、依赖、确认与取消方式、持久化或删除等副作用、限制、失败处理及可复制示例。只描述实际存在的能力；不适用项省略，尚未实现或未验证的能力明确标注，不能为了填表虚构功能。
- 脚本中的单选、多选及菜单优先使用 [**fzf**](https://formulae.brew.sh/formula/fzf)，按 [Shell 选择器与子层返回公约](../jobs-macos-shell/SKILL.md#script-fzf-selection)实现；配套 README 写清真实按键、选择层级及 `←` 返回上一层、默认值、空选 / 取消、依赖和缺失时处理方式，不把模式或列表选择与执行确认混为一谈。
- 每个 Jobs 自维护 [**Git**](https://git-scm.com/) 父仓、子仓的根目录都必须有 `README.md`，已有原文补齐真实目录结构和本仓脚本功能 / 运行流程，具体范围与版式统一遵循 [Git 仓库 README 规范](../jobs-git-repository/SKILL.md#repository-readme-contract)。
- 本任务范围内每个独立功能目录和关键目录都维护就近的 `README.md`，说明本目录职责、实际入口和能力边界；上级 README 提供简短功能概述及相对链接。根总览、目录说明与功能说明分层对账，不能只在顶层罗列路径。尊重现有分组，不为文档移动源码或机械地给缓存、第三方、生成目录及无独立职责的小目录补空文档。
- 软件工程项目顶层 `README.md` 的统计要求独立维护在同目录的 [README 项目统计条款](./README规范-项目统计条款.md)。编写或维护项目 README，或处理统计口径、前后端规模、第三方依赖、业务文件占比时，必须先读取该附属规范，再按本文件的格式规则排版；条款保留为独立文件，不合并进本文件。已有 `.codegraph/` 时优先使用其资料，无索引时直接依据源码和项目配置核实，不因统计或绘图主动初始化索引。
- 每个 Jobs 自维护脚本默认遵守[脚本同名包装与命名主规则](../jobs-macos-shell/SKILL.md#script-package-naming)：完整文件名（含后缀）的目录内放真正脚本及对应 `README.md`，只有用户明确拒绝时才采用其例外。Python 工具、内部辅助及测试脚本不自动豁免；父级或工具总 README 提供导航，不能替代各脚本说明。平台 / 应用宿主前缀与外部语言运行时脚本的区分按该主规则执行。
- 维护 `OS@Extension` 下的管理入口、目录结构或相关 README 时，必须先读取同目录附件 [OS@Extension 脚本布局](./README规范-OS@Extension脚本布局.md)；只对附件列出的用户明确要求裸露的管理入口应用该专项例外及就近 README，不推广到其它脚本或仓库。
- 当前任务新增或实际维护的 `Scripts/`、`scripts/` 等脚本目录，就近补齐目录内 `README.md`，不能只用父目录说明代替；目录职责、实际入口及风险的内容边界见 [Git 仓库与脚本 README 规范](../jobs-git-repository/SKILL.md#repository-readme-contract)。只处理本任务命中目录，不据此批量改写无关脚本目录。
- 脚本 README 是 Jobs 脚本“三层自述”的第一层：它位于脚本文件之外，通常与主脚本平级，面向用户运行前阅读；它必须描述脚本行为特征，但不能替代脚本头部注释自述和运行时内置自述。
- README 用中文面向运行前阅读，围绕当前功能组织适用场景、执行前检查、操作流程、日志和常见问题；功能总览中的每项能力都能定位到对应入口和详细说明。
- 涉及配置或操作结果的 README，优先给当前真实代码 / 配置、用法与实际运行或解析结果表，再解释原理和必要边界。历史改写前后对照不作为默认章节；只有用户明确要求历史，或当前迁移操作确需旧配置作输入时才保留必要对照，真实依据和适用条件须写明。速览必须独立讲清当前要点，不能只甩报告链接。
- 父仓 / 子仓 README 的速览必须包含本仓或登记本仓的直接父仓实际 `.gitmodules` 小段、“父仓地址 → 子仓解析地址”表，以及 `path` 为本地目录、`url` 为真实仓名的区别；尚未登记时标明是拟生成示例，不为叶子子仓伪造 `.gitmodules`。列出已配置线路；其它托管平台、自建服务或端口示例明确标注未部署 / 未验证，缺映射时只写未配置，不把假设镜像写成真实地址。Git 配置与例外归[父子仓多平台规范](../jobs-git-repository/SKILL.md#submodule-multi-platform)，文档随实际行为同步。
- 将镜像与固定提交须存在、跨组织 / 异名的明确地址例外等成立前提，紧邻示例简短写明；后面的理论和风险章节补充细节，不让读者先通读长文才能判断例子是否适用。交付前逐项对账实际配置、结果表、链接与锚点。
- 技术文档优先包含这些块，按需要取舍：`前言`、`适用场景`、`运行方式`、`执行前检查`、`脚本执行命令`、`流程图`、`日志文件`、`常见问题`、`风险说明`、`未执行声明`。
- README 里凡是涉及项目内文件、脚本、产物、目录树和命令参数的路径，默认以当前 `README.md` 所在目录为基准写相对路径，例如 `./启动脚本.command`、`./项目目录/README.md`；不要把 `$HOME` 这类本机绝对路径写进可交付 README。确实位于当前目录树外的日志、缓存或系统位置，只写文件名和位置说明，例如“系统临时目录中的 `脚本名.log`”，避免写死绝对路径。
- 用户关心目标程序的功能覆盖和颗粒度；除明确要求保留历史外，README 不写升级 / 修复历史、日期批次或“本次更新 / 修复了 / 新增了 / 旧版问题”等交付叙事。已有此类段落先核对其中仍有效的能力、兼容边界、风险和排查方法，将其归入对应的当前功能说明，再移除历史叙事，不能连同实质能力一起机械删除。当前验证范围及尚未验证的限制可简短说明，不堆历次测试数量、调试过程或修复流水账。
- 修改或升级任何配套 `README.md` 的脚本、命令或生成器时，必须在同一任务中同步对账 README；按实际入口 / 模式逐项核对功能清单、能力边界、参数与默认值、依赖、交互、执行流程、日志、产物路径、副作用、失败处理、流程图和验证状态。交付前确认源码中的用户可用能力均有说明、关键目录有就近 README 和上级入口，不能只改实现或只删历史而漏掉功能。
- README 如果包含 `VS`、竞品或第三方工具对比，每次上游脚本升级都必须重新核对双方当前能力、版本基线、官方链接、对比矩阵和选型结论；不允许只修改日期，或沿用未经复核的旧结论。
- 上述同步要求属于本 Skill 的通用维护规则，不要在每个具体 README 中重复写“强制维护规则”；具体 README 只保留该文档当前需要展示的真实内容和对比结果。

### 1.5、<span id="markdown-toc-filter">本地动态目录与远端折叠目录</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 用户确认的标准是：本地编辑及拉取 / 检出后保留独占行的 `[toc]`，远端展示按标题层级缩进、默认收起的可折叠目录。本地用 [**Typora**](https://typora.io/) 随标题实时生成目录，通过 [**Git clean / smudge 过滤器**](https://git-scm.com/docs/gitattributes#_filter)在暂存与检出时自动转换；当前机器的新克隆须在首次落盘时直接得到 `[toc]`。手写静态链接或每次人工运行刷新命令不算完成该方案。仓库接入、机器条件注册、暂存边界和卸载统一遵循[Git 目录过滤器规则](../jobs-git-repository/SKILL.md#markdown-toc-git)。

  | 环节 | 文档形态与刷新时机 |
  | --- | --- |
  | 本地编辑 | 保留 `[toc]`，目录由编辑器动态展示。 |
  | 整文件暂存 | `git add` / SourceTree 整文件暂存触发 `clean`，从 Git 传入的该版完整正文生成按标题层级缩进、由自有标记包裹的折叠目录。 |
  | 提交与推送 | 正常提交使用已暂存版本，`push` 发送已有提交；不能靠推送刷新目录。 |
  | 远端浏览 | 默认收起的 `<details>` / `<summary>`，展开后看到有层级缩进的章节链接。 |
  | 本机已条件注册的新克隆 | 普通 `git clone` 的首次检出即还原 `[toc]`；条件须精确命中已登记远端，并使用受信任的机器侧转换工具，不需先运行仓内 `install`。 |
  | 未注册机器的新克隆 | 仓库 local 配置不会随克隆传播，首次检出保留远端生成态；审查仓内工具并安装一次后安全恢复当前文件。不能承诺任意机器克隆后立即为 `[toc]`。 |
  | 检出与拉取 | Git 实际把受控文档写入工作区时运行 `smudge`，还原各位置的原目录标签及大小写，并撤销自有标题包装；`pull` 仅在合并 / 快进需要写入该文档时触发。 |
  | 既有本地生成目录 | 仅配置过滤器、`fetch` 或无须重写该文档的 `pull` 都不会恢复磁盘内容；按仓内安全恢复入口转换当前文件，再验收本地形态。 |

- 接入范围是用户明确指定目录内、Jobs 自有或已接管、已有章节目录的 `.md`：有效独占行 `[toc]` 及本工具自有生成块直接登记，标签大小写均识别，合法多个标签按原位置分别生成同一目录并保留原写法。代码围栏、缩进代码、行内代码、注释、原始 HTML 示例及说明文字中的字面量不计；代码目录树、路径职责表和普通站内链接也不视为章节目录。无目录文档不强加目录，新增文档先确认有效标签再登记，不用 `*.md` 广泛过滤。第三方、供应商、生成文档和所有权不明文件排除。
  - 用户授权将已有手写章节目录统一为本标准时，先逐项核对目录链接与实际标题及锚点，确认独立目录区域和边界；只将可可靠识别的目录区替换为 `[toc]`，写前留原文快照，改后逐项核对章节可达、非目录正文及原有手写说明逐字保留。混有正文、失效链接、边界不明或不能可靠识别的目录保留并报告，不能用宽泛正则删除列表或 `<details>`。该迁移是接入前的受控编辑，日常 `smudge` 仍只处理本工具标记。
  - 用户自有 Skills 的 `SKILL.md`、同级附件、references 与模板说明中的已有目录执行同一标准，保持 YAML front matter 在首行；按各自实际 Git 根登记，软链接按真实路径去重，不能因挂在父仓就误登为父仓文件。外部插件缓存、系统 Skills、上游第三方 Skills 和外援软链接不套用 Jobs 文档改写。
- `clean` 只能转换标准输入的内容，不回读工作区同名文件；按该版正文的标题层级生成目录，排除代码示例、注释与目录自身，标题中的返回前言 / 文末导航不进入目录名称。已有唯一语义 `id` 仅在目标渲染器保留时复用，不能依赖可能被剥离的旧 HTML 元素。发布形态需要稳定锚点时，可用自有标记包裹标题文字的非空 `span`，由 `smudge` 完整还原；验证平台差异、中文、重复标题和特殊字符，不插入空锚点、不改写工作区标题。
- 每个目录位置使用本工具专属、成对且可识别的生成块标记，例如 `<!-- jobs-toc:start -->` / `<!-- jobs-toc:end -->`；`smudge` 只撤销本工具的目录块与可逆标题包装，不移除用户自写的 `<details>`、锚点或其它目录。合法多个标签不能合并或删减；嵌套、孤立、错序的生成标记、异常结构或不能可靠解析时停止并报告，不能猜测性删除内容。转换必须幂等，且 `smudge(clean(原文))` 逐字节还原原文，包括标签大小写、BOM、换行形式和文件末尾换行；自有转换范围外的正文、示例、图片、链接与已有改动保持不变。
- 折叠展示分别以 [**GitHub 官方说明**](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/organizing-information-with-collapsed-sections)与 [**GitLab 官方说明**](https://docs.gitlab.com/user/markdown/#collapsible-section)为依据；[**Gitee**](https://gitee.com)或自建服务按目标渲染器实际预览验证，不把本地预览或某一平台通过写成所有平台已验收。
- 仓内保持 local 安装能力；对用户已授权推广且要求当前机器新克隆立即还原的范围，按 [Git 目录过滤器规则](../jobs-git-repository/SKILL.md#markdown-toc-git)逐仓核实并完成机器条件注册，只覆盖获准的精确远端，无需按仓反复索取同一授权。未注册机器须审查仓内工具并安装一次，不能承诺配置随克隆传播。验收“新克隆即还原”必须直接普通 `git clone`，在未运行仓内 `install`、未设置 local 过滤器时检查磁盘已为 `[toc]`、原始 index / `HEAD` 为生成态、整文件暂存能生成目录且状态干净；先安装后再拉取成功只能证明安装后的流程。[**Node.js**](https://nodejs.org) 路径变化或换机后重新检测依赖并复检配置。
- 在子模块下载 / 同步入口中，按各仓有效配置执行条件还原：有目录过滤器才调用本仓安全 `restore` 并严格检查，无配置则跳过且不自动安装。原文、暂存及错误边界与临时对象库首次检出时序，统一遵循 [Git 目录过滤器规则](../jobs-git-repository/SKILL.md#markdown-toc-git)；文档须区分“已还原”与“无配置已跳过”，不能把同步成功写成所有 Markdown 已恢复。
- 首次安装或修复既有生成态时，以现有工作区内容安全恢复本地标签，不用强制检出覆盖未提交正文。安装 / 恢复须保留暂存内容、模式、阶段、用户 flags 与部分暂存状态；为消除形态恢复造成的假修改，可按上述 Git 规则受控刷新 stat 缓存，只读验证不执行该刷新。过滤器工具目录自带 `README.md`，按 Git 规则分别说明机器条件注册与仓内安装的适用范围，并提供可复制安装、状态、索引检查、只读验证、预览和卸载命令；区分仓库首次接入时审查并整文件暂存全清单与配套工具文件、日常仅整文件暂存改动文档的流程，不替用户自动暂存。新增或移动含标签文档须更新清单与精确属性后按实际安装方式更新注册、验证；仅获准处理含标签文档时，不为追加说明修改无标签业务 README。用户明确要求的工具 / `Scripts` 目录说明按授权单独补齐。
- 批量处理先只读列出命中文档、归属 Git 根、排除项与既有状态，写前留快照，改后验证字节往返、标题增删改后的目录、原有章节及导航仍在。用隔离仓库或独立临时索引验证暂存 / 检出；涉及拉取恢复时按 [Git 验收边界](../jobs-git-repository/SKILL.md#markdown-toc-git)实测 `pull`，不能只验证转换函数。用户要求先单仓实验时，先完成验收；随后明确确认推广，便以验收仓的转换、安装 / 恢复和首次克隆能力为基准，同步复用模板并在指定根及用户自有 Skills 范围执行，不再用已完成的实验限制阻止推广，也不扩展到未指定来源。验证不操作真实暂存区，不因接入自动提交或推送；本地接入、索引检查、远端已发布和平台渲染分别报告。
- 维护或接入 `.jobs-markdown-toc/` 时，先读取 [完整模板说明](./assets/markdown-toc/README.md)，复用同目录的 [自包含转换工具](./assets/markdown-toc/MarkdownToc.mjs)、[受控清单模板](./assets/markdown-toc/manifest.json)和说明文档三件套；模板须与已验收基准同步，不能把旧版仅验证往返的能力当作新标准。模板清单只登记随包的工具 README；目标仓库按目录形态与所有权核实后增量登记，保留已有清单，不照搬来源仓库文件名单。批量部署使用 [受控清单部署器](./scripts/deploy-markdown-toc.mjs)，不临时重写同类转换逻辑。先审核含 `root`、`candidates`、`excluded` 的 JSON 清单，候选项逐个给出 `path`、`repoRoot`、`sha256` 和 `approved: true`；用户指定根的批量授权涵盖筛选后的自有目标，不把该目录未经筛选的全部文件自动标为获准。部署器校验范围与盘点后变化，默认仅生成计划报告，添加 `--apply` 才写入各仓。
  - 当前机器首次克隆自动还原使用 [精确远端注册器](./scripts/register-markdown-toc.mjs)，从已审核清单的 Git 根读取实际远端，先生成计划再按授权安装受信任机器副本；状态检查与精确撤回使用其自身记录。运行方式、依赖、报告和影响范围见 [维护脚本说明](./scripts/README.md)，不以仓内 `uninstall` 代替机器注册撤回。

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

- 对任何已有内容的文档，默认只增量补充或局部编辑；适用于 Markdown、纯文本、Word、PDF、表格、演示文稿及在线文档，不能把旧正文、历史记录或原有章节用新稿整份覆盖。用户主动、明确要求删除、替换或全文重写时，按其指定范围执行；“整理、优化、完善、升级、统一格式”本身不构成清空原文的授权。用户明确要求移除 README 的升级 / 修复历史时，应按[功能覆盖规则](#readme-examples-first)保留当前实质能力并完成清理，不能用本节的一般保护要求阻止已授权删除。
- 写入前先读取当前文档，保留可核对的原文快照或版本，确定本次修改位置；保留用户已有改动，以及与本任务无关的正文、表格、附件、批注和结构。读取不全或格式不能可靠解析时，不得生成一份新稿直接盖掉原件；先补齐读取或采用能够保留原内容的局部操作。
- 优先使用追加、精确补丁、段落 / 单元格 / 页面级编辑。工具只能提交整份内容时，必须从完整原文合并本次改动，再写回合并结果；不能以新生成的概要或模板代替原文。写入前复读当前版本，检测到并发变化时重新合并，不用旧快照覆盖更新。
- 修改后对照快照或版本差异，除用户明确授权替换 / 删除的范围外，确认原有实质内容仍在、新内容处于预期位置，且格式、链接、附件等未被误删；富文本和分页文档同时预览结果。发现误删只从已核实版本恢复误删部分，保留本轮及并发新增内容，再补充本次内容，不整份回滚；核查来源可包括本地历史及用户指定远程，不能仅凭本地当前版本断言旧内容不存在。
- 各格式专项工作流继续负责具体读写与渲染方法，本节负责共同的原文保护边界；仓库 README 的目录和脚本说明同时遵循 [Git 仓库 README 规范](../jobs-git-repository/SKILL.md#repository-readme-contract)。

## 三、<span id="software-project-documents">软件项目需求与交付文档</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 用户提供从零开发前后端软件的原始需求，或补填后要求二次回归时，使用独立的 [jobs-software-project](../jobs-software-project/SKILL.md)。完整规范和可补填模板由该 Skill 维护，本文件只负责文档格式及原文保护。
- 编制需求、技术评审、分级验收、部署或交接说明时，按任务读取[开发与交付规范](../jobs-software-project/软件项目开发与交付规范.md)的命中章节。缺失信息留白、不确定信息标红；前端路线未明确时先询问，保留用户补填和已有项目确认结论。
- 普通文档局部编辑不触发整套项目摸排，也不因范本默认路线自动改造现有工程；技术版本与平台能力使用时重新核验。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
