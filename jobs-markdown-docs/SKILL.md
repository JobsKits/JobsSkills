---
name: jobs-markdown-docs
description: 当任务涉及 Markdown、README、技术文档、表格、流程图、外链、专有名词链接、文档封面和文档结构时使用。
---

# Jobs Markdown 文档规范

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[toc]

---

## 🔥 <font id=前言>前言</font>

> 本技能由 `💻JobsCodexConfigs/AGENTS.md` 拆分而来，保留原有 Jobs 工作规范。只有当前任务命中本技能描述时才加载本文件，避免把所有细则长期塞进全局上下文。

## 一、[**Markdown**](https://markdown.cn) 文档（`*.md`） <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 1.1、整体风格

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
- 中文正文中的步骤、次序和数字列表统一使用顿号 `、`，例如 `1、iOS 逆向究竟在研究什么`；不要写成 `1.iOS ...` 或 `1. iOS ...`。即使 Markdown 支持 `1.` 原生有序列表，Jobs 中文文档仍优先使用 `1、` 并在相邻条目之间保留空行。版本号、小数、域名、代码、命令输出和引用的英文原文不受此规则影响。
- 长文档可以保留锚点和上下跳转链接：

  ```markdown
  ## 一、升级标准 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

  <a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
  ```

### 1.2、代码块与缩进

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

### 1.3、外链、表格与流程图

- 能外链的第三方工具、框架、语言、平台，优先用官方链接，并按 Jobs 文档习惯写成 `[**名称**](URL)`，例如 [**Homebrew**](https://brew.sh/)、[**Flutter**](https://flutter.dev/)、[**CocoaPods**](https://cocoapods.org/)、[**Mermaid**](https://mermaid.js.org)。
- 标题、表格、正文第一次出现第三方名词时可以直接加链接；代码块、命令、路径、文件名里的字面量不要加链接。
- 表格用于阶段说明、参数说明、目录统计、命令清单；表头短一点，内容能扫读。
- 复杂流程优先使用 [**Mermaid**](https://mermaid.js.org)。
- 对用户有风险的地方要写明白，不要藏在代码块后面。危险动作必须在文档里说明确认方式，例如“必须输入 `YES` 才会继续”。
- 文档语气可以保留 Jobs 风格短句，例如“Jobs出品，必属精品”“我是有底线的”，但正文要优先服务操作，不堆装饰。

#### 1.3.1、专有名词固定超链接

- 写 [**Markdown**](https://markdown.cn) / README / AGENTS 这类技术文档时，遇到下表里的专有名词，正文第一次出现时优先写成 `[**名称**](URL)`；需要强调或便于点击时，后续也可以继续加链接。
- 同一个工具有多个常见写法时，正文优先使用“推荐写法”；括号里的别名只用于识别，不强行改代码块里的命令。
- 代码块、命令、路径、文件名、变量名里的字面量不要加超链接，例如 `brew install fzf`、`Podfile`、`python3`、`go-task/tap/go-task`。
- 如果用户明确给了新的官方链接，以用户最新指定为准，顺手更新这张表。

  | 推荐写法                                                               | 识别别名                                              | 固定链接                                           |
  | ------------------------------------------------------------------ | ------------------------------------------------- | ---------------------------------------------- |
  | [**Markdown**](https://markdown.cn)                                | `Markdown` / `md`                                 | `https://markdown.cn`                          |
  | [**Swift**](https://www.swift.org/)                                | `Swift`                                           | `https://www.swift.org/`                       |
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

### 1.4、README 固定内容

- 每个可双击脚本目录优先放同名脚本和 `README.md`；Python 工具系列如果采用外层多平台入口脚本 + 内层 Python 工程结构，不要求每个 `.bat` / `.command` 单独配套 `README.md`，由外层总 `README.md` 统一说明各入口。
- 脚本 README 是 Jobs 脚本“三层自述”的第一层：它位于脚本文件之外，通常与主脚本平级，面向用户运行前阅读；它必须描述脚本行为特征，但不能替代脚本头部注释自述和运行时内置自述。
- README 用中文说明，适合用户双击前先看懂：用途、适用场景、执行前检查、操作流程、是否有风险、日志位置、常见问题。
- 技术文档优先包含这些块，按需要取舍：`前言`、`适用场景`、`运行方式`、`执行前检查`、`脚本执行命令`、`流程图`、`日志文件`、`常见问题`、`风险说明`、`未执行声明`。
- README 里凡是涉及项目内文件、脚本、产物、目录树和命令参数的路径，默认以当前 `README.md` 所在目录为基准写相对路径，例如 `./启动脚本.command`、`./项目目录/README.md`；不要把 `$HOME` 这类本机绝对路径写进可交付 README。确实位于当前目录树外的日志、缓存或系统位置，只写文件名和位置说明，例如“系统临时目录中的 `脚本名.log`”，避免写死绝对路径。
- README 不写成变更日志，不使用“本次更新”“本次升级内容”“本次已按某标准升级”这类阶段性口吻。需要说明改造结果时，要改写成全量描述：脚本目标、适用场景、完整运行行为、环境兼容策略、交互规则、日志路径、风险边界和排查方式。
- 修改或升级任何配套 `README.md` 的脚本、命令或生成器时，必须在同一任务中同步对账 README；至少检查用途、能力边界、参数与默认值、依赖、交互、执行流程、日志、产物路径、风险、流程图和验证状态，不能只改实现不改文档。
- README 如果包含 `VS`、竞品或第三方工具对比，每次上游脚本升级都必须重新核对双方当前能力、版本基线、官方链接、对比矩阵和选型结论；不允许只修改日期，或沿用未经复核的旧结论。
- 上述同步要求属于本 Skill 的通用维护规则，不要在每个具体 README 中重复写“强制维护规则”；具体 README 只保留该文档当前需要展示的真实内容和对比结果。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
