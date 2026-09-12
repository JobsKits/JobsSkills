---
name: jobs-macos-shell
description: 当任务涉及 MacOS 原生 Shell、zsh、.sh、.command、内置自述、防误触确认、函数拆分、main 入口编排、Homebrew、自检、批量脚本、压缩包输出或 Sourcetree 自定义动作脚本时使用。
---

# Jobs MacOS Shell 脚本规范

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[toc]

---

## 🔥 <font id=前言>前言</font>

> 本技能由 `💻JobsCodexConfigs/AGENTS.md` 拆分而来，保留原有 Jobs 工作规范。只有当前任务命中本技能描述时才加载本文件，避免把所有细则长期塞进全局上下文。

## 一、MacOS Shell 脚本（`.sh` / `.command`） <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 1.1、脚本基座

- 新写或升级脚本时，默认使用：

  ```shell
  # shell: zsh
  ```

- 默认添加：

  ```shell
  setopt NO_NOMATCH
  ```

- 脚本路径和日志路径按 Jobs 标准写法：

  ```shell
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
  SCRIPT_PATH="${SCRIPT_DIR}/$(basename -- "$0")"
  SCRIPT_BASENAME=$(basename "$0" | sed 's/\.[^.]*$//')
  LOG_FILE="$TMPDIR/${SCRIPT_BASENAME}.log"
  : > "$LOG_FILE"
  ```

- 脚本必须结构化、模块化：基础路径、彩色日志、通用交互、路径处理、环境检查、业务逻辑分块写函数，最后只在 `main` 里编排调用。

  ```shell
  main() {
    show_script_intro_and_wait # 首先打印脚本内置自述并等待用户确认。
    check_environment # 确认后检查当前任务依赖的命令和环境。
    run_business # 环境无误后执行脚本核心业务。
  }

  main "$@"
  ```

- 文件顶部只保留声明与定义，例如 shebang、常量、变量、数组、只读配置和函数定义；除最终的 `main "$@"` 入口调用外，不允许把真实执行语句散落在函数外。
- `setopt`、`autoload`、`source`、日志文件清空、`trap` 注册、环境探测、目录创建或切换、文件读写、命令执行以及 `if` / `case` / 循环等运行逻辑，都必须封装到初始化函数或职责明确的业务函数中，再由 `main()` 集中调用。
- 仅供其它脚本 `source` 的函数库如果确实需要加载时初始化，应把初始化逻辑集中到一个模块初始化函数，并在文件末尾保留唯一一次初始化调用；不能在文件各处散落执行语句。

- 优先写原生 Shell，能用 MacOS 自带工具解决就不引入 [**Python**](https://www.python.org) / [**Node.js**](https://nodejs.org/) / [**Ruby**](https://www.ruby-lang.org/) 依赖。
- 涉及批量文件处理时，使用 `find ... -print0` + `while IFS= read -r -d ''`，路径必须全程加引号，兼容空格、中文、括号和特殊符号。
- 涉及文本替换时，优先使用 `grep -Fq`；复杂替换可以使用 `perl`，避免脆弱的 `sed` 转义。

### 1.2、彩色日志

- 新脚本默认带这一组函数；已有脚本按原风格补齐即可。

  ```shell
  log()            { echo -e "$1" | tee -a "$LOG_FILE"; }
  color_echo()     { log "\033[1;32m$1\033[0m"; }         # 正常绿色输出
  info_echo()      { log "\033[1;34mℹ $1\033[0m"; }       # 信息
  success_echo()   { log "\033[1;32m✔ $1\033[0m"; }       # 成功
  warn_echo()      { log "\033[1;33m⚠ $1\033[0m"; }       # 警告
  warm_echo()      { log "\033[1;33m$1\033[0m"; }         # 温馨提示
  note_echo()      { log "\033[1;35m➤ $1\033[0m"; }       # 说明
  error_echo()     { log "\033[1;31m✖ $1\033[0m"; }       # 错误
  err_echo()       { log "\033[1;31m$1\033[0m"; }         # 错误纯文本
  debug_echo()     { log "\033[1;35m🐞 $1\033[0m"; }      # 调试
  highlight_echo() { log "\033[1;36m🔹 $1\033[0m"; }      # 高亮
  gray_echo()      { log "\033[0;90m$1\033[0m"; }         # 次要信息
  bold_echo()      { log "\033[1m$1\033[0m"; }            # 加粗
  underline_echo() { log "\033[4m$1\033[0m"; }            # 下划线
  ```

- 终端输出和日志落盘必须同步，排查时能直接看 `$TMPDIR/脚本名.log`。
- 成功、警告、错误要有明确前缀。失败分支不要静默吞掉，至少输出失败命令或目标路径。

### 1.3、交互约定

- MacOS `.sh` / `.command` 脚本统一采用“三层自述”标准，三层各自服务不同场景，不能互相替代：
  1、**外部 README 自述**：脚本所在目录可配套 `README.md`，与主脚本平级，用中文描述脚本行为特征、适用场景、运行方式、风险边界、日志位置和常见问题；它面向运行前阅读。是否新增 README 取决于用户要求、现有目录约定和脚本复杂度，但已存在时必须随脚本行为同步维护。

  2、**脚本头部注释自述**：脚本文件内部在 shebang（例如 `# shell: zsh`）下一行必须紧跟一段注释自述；这段注释不参与运行时输出，用于打开源码时快速理解脚本名称、核心用途、影响范围和运行提示。

  3、**运行时内置自述**：脚本运行后第一件事必须打印写死在脚本内部的自述正文；无论后续流程是安装、清理、Git 操作、打包还是打开应用，都必须先展示脚本名称、核心用途、影响范围、取消方式/运行策略和日志位置，再根据运行入口决定是否等待回车。
- 运行时内置自述必须直接写在脚本函数中，例如 `show_script_intro_and_wait()`；不能只 `cat README.md`，也不能只依赖脚本头部注释。
- `show_script_intro_and_wait()` 不得在运行时读取、拼接或转发任意 `README.md`；README 只负责静态阅读，脚本运行时展示内容必须作为固定文本直接维护在脚本源码内部。
- 脚本头部注释自述必须紧跟 shebang，中间不插入空行、`setopt`、变量声明或其它代码。推荐格式：

  ```shell
  # shell: zsh
  # 脚本自述：
  # - 脚本名称：脚本文件名
  # - 核心用途：一句话说明脚本解决什么问题。
  # - 影响范围：说明可能修改的项目、环境、文件或 Git 状态。
  # - 运行提示：运行后会先打印内置自述；终端模式确认后继续，Sourcetree 模式无交互连续执行。
  ```

- 每个可独立运行的文本脚本都必须内置简明自述，不能把 `README.md`、网络文档或外部模板作为唯一说明来源。配套 `README.md` 可以存在，但它只是可选的扩展文档，不能替代脚本内置自述。
- 普通脚本以及脱离 Sourcetree 后在终端独立运行的 Sourcetree 脚本，每次运行时都必须先打印内置自述，再等待用户按回车确认；确认前不能执行安装、删除、写文件、修改索引或环境配置等真实业务。用户可以按 `Ctrl+C` 取消，防止双击或误调用后直接产生副作用。
- 由 Sourcetree 自定义动作实际发起的脚本属于明确例外：仍然打印内置自述，但不能等待回车或发起任何交互，必须完成参数校验后从一而终执行到结束。
- 内置自述保持简明扼要，至少说明脚本名称、核心用途、主要影响范围和取消方式；高风险脚本还应点明关键风险与日志位置。

  ```shell
  # 打印脚本内置自述，并等待用户明确确认后再继续。
  show_script_intro_and_wait() {
    clear
    highlight_echo "============================== 脚本自述 =============================="
    note_echo "当前脚本：${SCRIPT_PATH}"
    note_echo "核心用途：这里用一两句话说明脚本解决什么问题。"
    warn_echo "影响范围：这里说明可能修改的文件、环境或 Git 状态。"
    gray_echo "取消方式：按 Ctrl+C 终止，不会继续执行后续业务。"
    highlight_echo "======================================================================="
    echo ""
    read -r "?👉 已了解脚本用途与影响，按回车继续；按 Ctrl+C 取消：" _
  }
  ```

- 普通安装 / 更新 / 升级 / 自检类操作统一为：直接回车跳过，输入任意字符后回车执行。
- 只要涉及“升级 / 更新 / upgrade / update”，都必须遵守这条规则；不要写成“回车执行升级，输入任意字符跳过”。

  ```shell
  ask_any_to_run() {
    local message="$1"
    local answer=""
    read -r "?${message}（直接回车跳过；输入任意字符后回车执行）：" answer
    [[ -n "$answer" ]]
  }
  ```

- 危险操作必须要求输入 `YES`，不能把回车设计成执行。

  ```shell
  confirm_yes() {
    echo ""
    warn_echo "⚠ $1"
    gray_echo "危险操作必须输入 YES 后回车；其它输入一律取消。"
    local input=""
    IFS= read -r "input?➤ "
    [[ "$input" == "YES" ]]
  }
  ```

- 用户拖入路径时，必须去除首尾引号、回车，并兼容多个路径。

  ```shell
  strip_outer_quotes() {
    local value="$1"
    value="${value%$'\r'}"
    value="${value%$'\n'}"
    value="${value#\"}"
    value="${value%\"}"
    value="${value#\'}"
    value="${value%\'}"
    print -r -- "$value"
  }
  ```

### 1.4、[**Homebrew**](https://brew.sh/) / MacOS 环境

- [**Homebrew**](https://brew.sh/) 相关脚本必须识别 Apple Silicon 和 Intel：

  ```shell
  get_cpu_arch() {
    [[ "$(uname -m)" == "arm64" ]] && echo "arm64" || echo "x86_64"
  }
  ```

- 查找 `brew` 时按顺序兼容：`command -v brew`、`/opt/homebrew/bin/brew`、`/usr/local/bin/brew`；已经能调用 `brew` 时，再用 `brew --prefix` 校验真实前缀。
- 写入 shellenv 时必须防重复追加，使用明显的 header / footer 块。
- 写入配置后要让当前终端立即生效：`eval "$shellenv_cmd"`。
- 已安装 [**Homebrew**](https://brew.sh/) 时，不自动执行 `brew update && brew upgrade && brew cleanup && brew doctor && brew -v`，必须询问用户。
- 涉及 CLT、[**Xcode**](https://developer.apple.com/xcode/)、[**CocoaPods**](https://cocoapods.org/)、[**Flutter**](https://flutter.dev/)、[**Android Studio**](https://developer.android.com/studio?hl=zh-c)、[**Java**](https://www.java.com/)、[**Ruby**](https://www.ruby-lang.org/)、[**Node.js**](https://nodejs.org/) 等工具链时，先检查再执行，失败时输出下一步排查方向。

### 1.5、脚本目录 / README / 批量输出

- 不强制每个 `.sh` / `.command` 都使用“同名文件夹 + 主脚本 + README.md”的结构；应先尊重现有仓库目录、调用路径和同类脚本组织方式，不能仅为了形式统一而批量迁移脚本。
- 只有用户明确要求独立打包、批量整理、压缩包交付，或当前项目已经采用“一脚本一目录”约定时，才使用同名文件夹包裹结构。
- 使用同名文件夹时，文件夹名与脚本完整文件名保持一致并保留后缀，例如：

  ```text
  【MacOS】⚙️运行授权.command/
  ├── 【MacOS】⚙️运行授权.command
  └── README.md
  ```

- README 可以使用仓库级公共文档，也可以为复杂、独立交付或高风险脚本提供专属文档；是否单独创建由用户要求、现有项目约定和脚本复杂度共同决定。README 是否存在，都不影响脚本必须内置自述。
- 编写脚本配套 `README.md` 时必须同时加载 `jobs-markdown-docs`，按 Jobs Markdown 规范生成；README 使用中文全量说明，不写成变更日志。
- 脚本如果在内置自述之外还要补充读取某个 `README.md`，该文档路径必须稳定可解析；同目录不是无条件要求，但脚本移动后必须同步修正读取路径。
- 如果原始输入是散落脚本，整理时优先保留原脚本名；只在明显错误、重复或不符合 Jobs 命名时，才做最小必要改名。
- 批量升级脚本时，默认做结构优化：统一 `# shell: zsh`、路径变量、彩色日志、自述阻塞、防误触、`main "$@"`、[**Homebrew**](https://brew.sh/) 自检和升级交互；只有命中本节约定时才额外调整目录和 README。
- 输出压缩包前应做静态检查和结构检查；无法执行 MacOS 专属命令时，README 或最终说明里写清楚“未实际执行”。

### 1.6、Shell 验证

- Shell 脚本优先做静态检查：

  ```shell
  zsh -n '脚本名.command'
  ```

- 修改 `.command` 后确认 shebang、`SCRIPT_DIR` / `LOG_FILE`、内置自述、回车确认、`main "$@"`、路径引号、危险操作 `YES` 确认、普通升级动作不是默认执行。


### 1.7、脚本运行策略与自检定义

- 本节只补充 1.3 中自述 / 交互规则的运行策略：入口脚本必须先进入 `show_script_intro_and_wait()` 或等价函数；确认前不得执行环境安装、文件写入、Git 索引修改或其它真实业务。
- 日志初始化、`setopt`、`trap` 注册、参数解析、路径切换等准备逻辑要排在自述确认之后；确需提前准备的展示变量，只能下沉到无副作用的展示准备函数中。
- Sourcetree 脚本必须支持双运行模式：明确识别为 Sourcetree 自定义动作时，打印自述后无交互连续执行；同一脚本在系统终端独立运行时，打印自述并等待回车确认。
- 不能仅凭 `! -t 0`、`TERM=dumb` 或输出不是 TTY 就判定为 Sourcetree；这些条件只能决定输出降级。跳过回车必须以明确的 Sourcetree 运行态识别结果为准。
- 非 Sourcetree 且没有可交互标准输入时，应报错退出并提示改用终端执行，不能静默跳过确认后继续真实业务。

- 新写脚本时优先参考 [**JobsDocs Shell 脚本代码片段**](https://github.com/JobsKits/JobsDocs/blob/main/🔥Shell脚本代码片段.md/Shell脚本代码片段.md)，但不要机械复制；必须结合当前脚本职责做最小必要改造。

- 每个方法 / 函数在定义处都必须写简短注释，说明这个方法 / 函数负责什么；注释服务维护，不写无意义的逐行翻译，也不能只用分隔线代替职责说明。

- 方法职责注释必须在方法定义正上方单独占一行；注释与方法定义之间不留空行，注释与上一个内容体之间也不留空行。上一个方法结束的 `}` 后，下一行直接写下一个方法的职责注释，保持方法区连续紧凑。

  ```shell
  previous_method() {
    return 0
  }
  # 处理下一项独立业务职责。
  next_method() {
    return 0
  }
  ```

- `main` 是唯一入口收口点，并直接负责编排脚本的高层业务步骤；复杂实现继续下沉到职责明确的独立函数。

- `main()` 只允许由若干行“单行函数调用 + 同行尾部职责注释”组成；除这类行外，不允许出现其它可执行内容，也不再为每个调用额外占用一行前置注释。
- `main()` 内禁止出现 `local` / `typeset`、普通赋值、`if` / `case` / `for` / `while` / `until`、`&&` / `||` 条件组合、命令替换、重定向、`return` / `exit`、直接系统命令或多行调用。参数可以原样传给单行函数调用，例如 `run_original_logic "$@"`。
- 退出码捕获、成功与失败分支、循环处理、状态汇总和返回值传播必须整体下沉到职责明确的函数；`main()` 只调用该函数，不在入口中展开实现。
- `main()` 内每个函数调用都必须在调用行尾写 `#` 注释，说明“这一步做什么”或“为什么现在调用”；禁止只依赖函数定义处注释，也禁止把调用职责注释放到上一行。

- 只有当完整流程需要被复用，或额外的流程分层确实能表达独立职责时，才定义 `run_main_flow()`；如果 `main()` 里只有一行 `run_main_flow "$@"`，应删除这层无意义转发，把其中的高层调用直接移入 `main()`。

- 如果确实保留 `run_main_flow()`，其中每个高层函数调用也必须写同行尾部业务职责注释；关键赋值、`trap` 和流程控制应优先继续封装，避免入口编排函数重新膨胀。

- 流程注释必须描述业务职责和顺序意图，不写“调用某某方法”这类重复代码字面的无效注释。

- 下面这种 `main()` 只转调一次 `run_main_flow "$@"` 的双层包装属于禁止写法：

  ```shell
  # 编排完整业务流程。
  run_main_flow() {
    show_script_intro_and_wait
    run_business "$@"
  }
  # 仅转调完整流程的冗余入口。
  main() {
    run_main_flow "$@"
  }
  ```

- 应直接去掉 `run_main_flow()` 这一层包裹，把它的高层调用移入 `main()`；`main "$@"` 传入的参数仍可在 `main()` 内直接使用：

  ```shell
  # 编排脚本自述和核心业务流程。
  main() {
    show_script_intro_and_wait # 打印内置自述，并按真实运行入口决定是否等待确认。
    run_business "$@" # 执行脚本核心业务，并继续透传入口参数。
  }
  ```

- 仅供其它脚本 `source` 的函数库可以不定义 `main()`；可以独立执行的入口脚本必须使用该收口形式。

- 脚本最后固定使用 `main "$@"` 收口：

  ```shell
  # 编排脚本说明、环境检查和核心业务。
  main() {
    show_script_intro_and_wait # 打印脚本内置自述并等待回车，防止误触后直接执行。
    check_environment # 检查当前任务依赖的命令和运行环境，失败时提前终止。
    run_business # 环境确认无误后执行当前脚本的核心业务。
  }

  main "$@"
  ```

- 自检类脚本的定义统一为：检测目标是否存在；如果已经存在，则进入升级 / 更新逻辑；如果没有检测到已安装，则安装最新版本。
- 自检、安装、升级都必须先检查再执行，并遵守交互确认：普通动作不能默认执行，危险动作必须输入 `YES`；新写或升级脚本继续统一使用 `# shell: zsh`，除非目标环境明确不是 MacOS / zsh。

#### 1.7.1、依赖链完整性与条件式自愈

- 当目标命令依赖运行时、包管理器或系统引导工具时，编码前先画出当前执行路径的完整依赖链或依赖图，区分必须同时满足的依赖和可以互相替代的安装来源。不能只检查最末端命令，例如通过 npm 安装或升级 [**CodeGraph**](https://github.com/colbymchenry/codegraph) 时，应识别 `CodeGraph → npm → Node.js → Homebrew → bash / curl / Command Line Tools` 这条可恢复链。
- “已安装”不等于“可用”。`command -v` 只负责发现候选路径；每一层还必须通过 `--version`、只读状态命令或等价的最小健康检查验证真实可执行性。PATH 中存在残缺 shim、损坏安装或不可执行文件时，统一按该层不可用处理。
- 每一层统一采用“发现候选 → 验证可用 → 缺失或损坏时安装 / 修复 → 刷新当前进程环境 → 再次验证”的闭环；只有当前依赖返回成功，才允许进入下一层或最终业务。安装后必须重新解析 PATH、Homebrew `shellenv`、npm 全局 bin 等当前会话环境，不能假设重新打开终端后才生效。
- 即使最终目标命令已经可用，只要本次操作实际包含依赖特定通道的升级、同步或修复，也必须检查该执行路径所需的上游依赖；例如 CodeGraph 升级依赖 npm 时，不能因为 `codegraph --version` 成功就跳过 npm / Node.js 健康检查。
- 只沿缺失或损坏的分支向上溯源。已有健康依赖或等价可用来源必须复用，不重复安装，不为了形式完整强制引入当前路径不需要的包管理器；修复动作必须幂等，健康环境重复运行时不产生写入。
- 每一层安装或修复最多执行一次并立即复检，禁止无限递归或无边界重试。复检仍失败时必须停止下游动作，明确输出失败层级、候选路径、失败命令或退出码以及人工排查方向，不能带病继续执行最终业务。
- 完整依赖链自检不扩张执行权限。只读发现和健康检查可以自动完成；安装、修复、升级等写操作必须属于用户明确请求或当前入口已经清楚声明的行为，并继续遵守普通动作确认和危险操作 `YES` 门禁。
- 验证此类脚本时，除 `zsh -n` 外，还要覆盖“全链健康、末端缺失但上游健康、多层连续缺失、安装失败、安装后复检失败”五类分支。优先使用隔离 PATH 或假命令验证分支；用户未要求真实安装时，不得把实际包管理器安装 / 升级当成测试。

- 批量整改后必须同时扫描四类结构问题：一是函数外是否仍有散落执行语句，二是 `main()` 是否严格只含“单行函数调用 + 行尾职责注释”，三是每个调用是否都有同行业务职责注释，四是 `main()` 的第一条函数调用是否为运行时内置自述；不能只做 `zsh -n` 就视为完成。


### 1.8、Sourcetree 自定义动作脚本兼容

- 所有 Sourcetree 自定义动作脚本固定采用双位置维护：运行目录为 `/Users/jobs/SourceTree.command`，备灾目录为 `/Users/jobs/Documents/Github/JobsGenesis/SourceTree.command`。新增、修改或重命名脚本包时，必须按相同相对路径同步两边的 `.command`、同名 `README.md` 和脚本行为文档，不能只改其中一处。
- 双位置同步后必须使用 `cmp` 或内容哈希确认对应文件完全一致；修改 `.command` 时，还必须对运行副本与备灾副本分别执行 `zsh -n`。任一位置缺失、内容不一致或语法校验失败，都不能视为任务完成。
- 新增或修改 Sourcetree 脚本的默认完成定义必须包含“已经实际挂载到当前用户 Sourcetree 自定义操作”：同时更新脚本包内和 `~/Library/Application Support/SourceTree/actions.plist` 中的动作配置，确保动作目标指向运行副本、仓库动作参数为 `$REPO`，并在 Sourcetree 运行时完成重载验证。只交付脚本、README 或待用户手工配置步骤，一律不能标记完成。
- Codex 负责动作目标路径、参数、仓库 / 文件动作类型、输出窗口策略、执行权限、双位置脚本副本和配置安装；用户最多只需要在 Sourcetree 中按个人偏好修改菜单显示标题。更新已存在动作时，应按稳定目标路径识别并保留用户当前显示标题；只有用户明确要求时才改名，避免用脚本默认标题覆盖用户定制。
- 修改任何现行 `actions.plist` 前必须创建带时间戳的可恢复备份；修改后校验 plist 可解档、动作唯一、目标脚本存在且可执行。Sourcetree 正在运行时按安全方式重启或重新加载，再从当前用户配置中反查动作名称、`$REPO` 参数和目标路径，证明菜单已经挂载。
- `Sourcetree` 自定义动作运行 `.command` 时，环境可能和系统终端双击运行不同：`TERM` 可能为空、`$0` 可能只是脚本名而不是绝对路径、标准输入可能不可交互、输出窗口可能不解析 ANSI 彩色码。
- 写 `SourceTree.command` 目录下的脚本时，必须显式探测运行环境；只有明确确认由 Sourcetree 发起时，才进入无交互连续执行模式，不要影响用户双击脚本后在系统终端里的正常交互体验。
- Sourcetree 模式必须从一而终：禁止调用 `read`、`select`、`fzf` 选择、`YES` 确认或任何需要外界输入的交互；所需目标应来自自定义动作参数、当前工作目录、环境变量或安全默认值。必要参数缺失时直接打印错误并退出，不能停在输入等待状态。
- 终端独立运行模式必须保留防误触：打印相同的脚本内置自述并等待用户回车，确认后才进入与 Sourcetree 模式共用的真实业务流程。
- Sourcetree 识别应组合检查相关环境变量、脚本解析路径和父进程链；`! -t 0`、`! -t 1`、`TERM=dumb`、`NO_COLOR` 只能用于判断交互能力或纯文本输出，不能单独作为 Sourcetree 身份依据。
- 凡是 Sourcetree 脚本，只要识别为 Sourcetree 自定义动作，就必须在任何 `log`、`color_echo`、`highlight_echo`、`note_echo`、内置自述或外部命令输出之前完成纯文本输出初始化；第一屏自述也不能出现 `[0m`、`\033[0m` 或任何 ANSI 控制字符。
- Sourcetree 纯文本初始化必须至少设置 `PLAIN_OUTPUT=1`，并导出 `NO_COLOR=1`、`FORCE_COLOR=0`、`CLICOLOR=0`、`ANSI_COLORS_DISABLED=1`、`npm_config_color=false`；脚本自身日志要通过 `strip_ansi_stream` 或等价函数剥离 ANSI，外部命令输出也必须经过同一类过滤后再显示和写入日志。
- `configure_output_mode`、`prepare_plain_output_context` 或等价函数必须在 `show_script_intro_and_wait()` 里打印第一行内容之前调用一次，也要在运行时初始化函数中再次调用，保证 SourceTree、非 TTY、`TERM=dumb`、`NO_COLOR` 等场景都不会漏出颜色转义码。

  ```shell
  # 识别脚本是否由 Sourcetree 自定义动作实际发起。
  is_sourcetree_runtime() {
    env | grep -Eqi '^SOURCETREE|^SOURCE_TREE' && return 0

    local pid="$PPID"
    local command_name=""
    local guard=0
    while [[ -n "$pid" && "$pid" != "0" && "$guard" -lt 8 ]]; do
      command_name="$(ps -o comm= -p "$pid" 2>/dev/null || true)"
      [[ "$command_name" == *SourceTree* || "$command_name" == *Sourcetree* ]] && return 0
      pid="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ' || true)"
      guard=$((guard + 1))
    done
    return 1
  }
  # 打印内置自述，并按真实运行入口决定是否等待回车。
  show_script_intro_and_wait() {
    highlight_echo "============================== 脚本内置自述 =============================="
    note_echo "脚本名称：${SCRIPT_BASENAME}"
    note_echo "核心用途：这里简要说明 Sourcetree 动作将执行的业务。"
    note_echo "运行策略：Sourcetree 内无交互连续执行；终端独立运行需回车确认。"
    gray_echo "日志文件：${LOG_FILE}"
    highlight_echo "============================================================================"

    if [[ "${IS_SOURCETREE_RUNTIME:-0}" == "1" ]]; then
      gray_echo "已识别为 Sourcetree 自定义动作，将跳过交互并连续执行。"
      return 0
    fi
    if [[ ! -t 0 ]]; then
      error_echo "当前不是 Sourcetree，且没有可交互输入；请在终端中重新运行。"
      return 1
    fi
    read -r "?👉 已了解脚本用途与影响，按回车继续；按 Ctrl+C 取消：" _
  }
  ```

- `SCRIPT_DIR` 不能只依赖 `dirname "$0"`；当 `$0` 不是绝对路径时，要按脚本名从 `~/SourceTree.command/脚本名/脚本名` 和 `../../../../JobsGenesis/SourceTree.command/脚本名/脚本名` 兜底找回真实脚本目录，确保脚本能定位自身目录和配套静态文档路径，不能退化成根目录路径；运行时自述仍以内置文本为准，不能在运行时 `cat`、拼接或依赖外部 `README.md`。
- 调用 `clear` 前必须确认是完整终端，例如同时满足 `-t 1`、`TERM` 非空且不是 `dumb`，并且不是 `Sourcetree` 瘦身环境；否则跳过 `clear`，避免出现 `TERM environment variable not set.`。
- 彩色日志必须支持纯文本降级：如果检测到 `Sourcetree`、非 TTY、`TERM=dumb` 或用户设置 `NO_COLOR`，不要输出 `\033` 这类 ANSI 转义码，避免日志和 SourceTree 窗口里出现 `[0m` 乱码；此规则对所有 SourceTree 脚本强制生效。
- `Sourcetree` 脚本如果会递归处理工程目录，默认跳过 `.git`、`Pods`、`.dart_tool`、`build`、`DerivedData`，并在最后输出总数、失败数和日志路径；只要有子任务失败，脚本最终也要返回失败状态，方便 `Sourcetree` 判断执行结果。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
