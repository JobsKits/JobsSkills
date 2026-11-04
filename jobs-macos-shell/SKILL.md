---
name: jobs-macos-shell
description: 当任务涉及 MacOS 原生 Shell、zsh、.sh、.command、内置自述、防误触确认、函数拆分、main 入口编排、Homebrew、自检、批量脚本、压缩包输出、Sourcetree 自定义动作脚本，或系统右键功能的 MacOS / Windows 双端范围、独立工程与安装卸载管理面板时使用。
---

# Jobs [**MacOS**](https://www.apple.com/macos/) Shell 脚本规范

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#%E5%89%8D%E8%A8%80)
- [一、MacOS Shell 脚本（.sh / .command）](#jobs-toc-heading-2)
  - [1.1、脚本基座](#jobs-toc-heading-3)
  - [1.2、彩色日志](#jobs-toc-heading-4)
    - [1.2.1、来源显示是常规脚本习惯](#script-source-logging)
  - [1.3、交互约定](#jobs-toc-heading-6)
    - [1.3.1、选择器优先使用 fzf，子层可返回](#script-fzf-selection)
  - [1.4、Homebrew / MacOS 环境](#jobs-toc-heading-8)
  - [1.5、脚本同名包装、平台与宿主命名](#script-package-naming)
  - [1.6、Shell 验证](#jobs-toc-heading-10)
  - [1.7、脚本运行策略与自检定义](#jobs-toc-heading-11)
    - [1.7.1、依赖链完整性与条件式自愈](#jobs-toc-heading-12)
    - [1.7.2、SDK 环境先决条件与持续自动获取](#sdk-acquisition-retry)
    - [1.7.3、Flutter SDK 下载前网络检测与自动选路](#flutter-sdk-network-routing)
  - [1.8、Sourcetree 自定义动作脚本兼容](#jobs-toc-heading-15)
  - [1.9、网络代理选择、回溯与恢复](#network-proxy-recovery)
  - [1.10、部署与反部署脚本成对](#paired-deployment-rollback)

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

> 本技能由 `💻JobsCodexConfigs/AGENTS.md` 拆分而来，保留原有 Jobs 工作规范。只有当前任务命中本技能描述时才加载本文件，避免把所有细则长期塞进全局上下文。

命中系统右键菜单或 `OS@Extension` 功能任务时，必须先读取 [系统右键菜单双端与独立安装规范](./系统右键菜单双端与独立安装规范.md)，据此确定平台范围、独立安装单元和各端管理面板边界。

涉及后端部署入口、部署脚本或部署手册时，必须按任务读取共用[《软件项目开发与交付规范》的部署方案](../jobs-software-project/软件项目开发与交付规范.md#deployment)、[本地部署与内网穿透](../jobs-software-project/软件项目开发与交付规范.md#local-tunnel)及[运维责任](../jobs-software-project/软件项目开发与交付规范.md#operations)中的命中章节，不无条件加载全文。普通 Shell 小修改不因此增加部署任务；保留既有项目确认范围，操作系统、数据库、工具及服务生命周期按当前目标重新核验。

完整 0 到 1 项目先按[主 Skill](../jobs-software-project/SKILL.md)生成需求与评审文档；前端路线未明确时询问“标准型／通用型／混合型”。缺失项留白、不确定项用红字标记，不把规范默认路线视为已确认方案。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、MacOS Shell 脚本（`.sh` / `.command`） <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-3" data-jobs-toc="v2">1.1、脚本基座 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 新写或升级脚本时，默认使用：

  ```shell
  # shell: zsh
  ```

- 默认添加：

  ```shell
  setopt NO_NOMATCH
  ```

- 脚本引用项目内文件、资源、目标目录或配套脚本时，必须以脚本自身目录（如 `SCRIPT_DIR`）或明确计算的项目根目录为基准构造相对路径，不依赖启动时的工作目录；禁止把开发机绝对路径（如 `/Users/...`、`/home/...` 或盘符路径）固化为运行依赖。用户配置、缓存和临时目录从 `HOME`、`TMPDIR` 等运行环境动态解析；系统约定目录或命令路径、运行时解析得到的绝对路径及用户显式传入路径可按需使用。
- <span id="portable-app-resources">App / GUI 跨机交付</span>优先将启动必需的管理器与资源放进 App Bundle，并从包内定位。通过 [**AirDrop**](https://support.apple.com/guide/mac-help/use-airdrop-to-send-items-to-nearby-apple-devices-mh35868/mac) 等方式分发时，[**macOS**](https://www.apple.com/macos/) 的 AppTranslocation 可能使 App 在隔离路径运行；相对路径本身不能保证 App 外部、原本同级的 `Scripts` 仍可访问。确需外置依赖时，用运行时显式传入的位置或原生目录选择取得并校验实际配套目录，不把隔离后的 App 父目录当作唯一依据。
- 构建时源码目录不能作为默认或回退路径写入启动器、配置或产物。找不到依赖时报告实际解析位置和缺失项，避免将路径错误一律误报为目录缺失；不以自动清除 `com.apple.quarantine`、关闭 Gatekeeper 或调用私有 API 恢复原始路径作为寻址修复。

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
- <span id="script-portable-self-contained">部署与反部署脚本以“移植过去即可使用”为交付要求。</span>按声明的项目／脚本包相对结构复制到目标机器后，用户应能直接运行目标平台原生入口；不得为了复用或生成脚本，额外要求用户配置与业务无关的 Python、Node.js、Ruby 等环境，或先执行开发期生成器才能得到可用入口。
- 部署自述、资源原点与清单、互斥锁、进程身份、退出清理、备份恢复等核心控制逻辑直接内嵌到各平台部署／反部署脚本，使用该平台原生 Shell／PowerShell。允许为自包含保留必要冗余，不因减少重复而抽出必须随身加载的生命周期函数库或状态模块；同一修复查齐授权范围内的全部副本，同源实现做内容核对，不同语言实现做行为等价验证。
- 自包含按实际交付边界验收：业务源码、锁清单、发布包及明确声明的资源仍按原项目布局提供；业务真正需要的 SDK、数据库和工具由入口按既有授权自检、准备与复检，不新增与部署业务无关的解释器要求。快捷入口仍可转交本平台唯一实施脚本，复用其自述与确认，不复制整套实施流程。
- 验证完整交付目录复制／改名、中文空格路径、工程外工作目录、脱离旧函数库仍可部署和反部署，以及取消、失败、中断、重复执行和旧状态清单兼容；保留[配对反部署](#paired-deployment-rollback)的归属、数据与危险确认边界。测试工具自身的依赖与交付脚本依赖分开记录，不为验证安装、停止或卸载用户真实部署。
- 涉及批量文件处理时，使用 `find ... -print0` + `while IFS= read -r -d ''`，路径必须全程加引号，兼容空格、中文、括号和特殊符号。
- 涉及文本替换时，优先使用 `grep -Fq`；复杂替换可以使用 `perl`，避免脆弱的 `sed` 转义。

### <span id="jobs-toc-heading-4" data-jobs-toc="v2">1.2、彩色日志 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

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

#### 1.2.1、<span id="script-source-logging">来源显示是常规脚本习惯</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 新建或维护涉及下载、安装 / 升级、克隆 / 拉取、从其它路径复制 / 同步的 Jobs 自维护脚本时，在对应操作前突出显示“正在处理什么、从哪里取得、放到哪里”。已有脚本沿用原日志风格，来源块与外部命令进度分开，不能只显示文件名、目录名、包名或 remote 别名。
- 来源至少包含对象名称、平台 / 主机或本地源路径、完整 URL 或明确的软件源；有目标路径、版本、分支时一并显示。包管理器尚未解析最终下载 URL 时，先显示已确认的软件源与包 / 版本，并标明地址待解析；得到实际地址后再补充，不猜测。切换镜像或回退来源时，在下一次尝试前更新来源块；成功结果保留最终采用的来源，失败信息关联失败的来源。
- 配置地址与本次实际使用地址不同时分别列出，地址展示必须来自当前命令和生效配置。仅完成本地规则展开时如实标注，不把它等同于已验证的 HTTP 重定向终点、代理出口或真实网络访问；不能为了打印来源额外安装依赖、联网探测或修改网络 / [**Git**](https://git-scm.com/) 配置。
- 来源块在支持颜色的终端醒目显示，落盘保留可直接搜索的纯文本；[**Sourcetree**](https://www.sourcetreeapp.com/)、非 TTY、`TERM` 为空 / `dumb`、`NO_COLOR` 或既有纯文本模式下不输出 ANSI。URL 中的凭据、Token、查询参数与其它敏感字段脱敏，展示副本不得回写成业务地址。
- 同名脚本有多个自维护副本时，在用户指定范围内查齐并同步来源日志实现，保留各自清单、路径、参数、交互及已有改动；只同步共同行为，不能用整文件覆盖不同业务。已有配套 README 同步靠前放置与真实输出一致的例子。Git 来源的地址解析、作用域与递归边界见 [Git 来源显示规范](../jobs-git-repository/SKILL.md#git-source-logging)。
- 以隔离展示片段或临时夹具核对来源先于真实传输、切换来源后的结果、脱敏与纯文本日志；不为预览日志运行真实安装、目录删除、同步覆盖、提交或推送。日志改动保持原业务语义，发现其它问题另行说明。

结构示例（域名仅作示例，未部署）：

```text
━━━━━━━━━━ 来源｜下载 ━━━━━━━━━━
📦 对象：tool.zip
🌐 平台 / 主机：downloads.example.com
📥 来源地址：https://downloads.example.com/releases/tool.zip
📂 目标位置：./cache/tool.zip
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### <span id="jobs-toc-heading-6" data-jobs-toc="v2">1.3、交互约定 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- MacOS `.sh` / `.command` 脚本统一采用“三层自述”标准，三层各自服务不同场景，不能互相替代：

  1、**外部 README 自述**：每个脚本按[同名包装与命名规则](#script-package-naming)配套同目录 `README.md`，面向运行前阅读；按[README 功能覆盖规范](../jobs-markdown-docs/SKILL.md#readme-examples-first)说明当前能力与使用颗粒度，并在上级文档提供入口。独立功能和关键目录继续维护总览，不能代替各脚本自己的说明；已有 README 随脚本行为同步维护。

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

- 每个可独立运行的文本脚本都必须内置简明自述，不能把 `README.md`、网络文档或外部模板作为唯一说明来源。配套 `README.md` 负责运行前的扩展说明，不能替代脚本内置自述。
- 普通脚本以及脱离 Sourcetree 后在终端独立运行的 Sourcetree 脚本，每次运行时都必须先打印内置自述，再等待用户按回车确认；确认前不能执行安装、删除、写文件、修改索引或环境配置等真实业务。用户可以按 `Ctrl+C` 取消，防止双击或误调用后直接产生副作用。
- 由 Sourcetree 自定义动作实际发起的脚本属于明确例外：仍然打印内置自述，但动作进程不能等待回车或发起任何交互，必须完成参数校验后连续执行或转交独立终端；需要危险确认时遵循 1.8 的终端承接规则。
- 内置自述保持简明扼要，至少说明脚本名称、核心用途、主要影响范围和取消方式；高风险脚本还应点明关键风险与日志位置。

- `.command` 的运行时自述统一视觉层级：脚本标题、分节标题使用红色加粗（`\033[1;31m`）；序号后的说明正文使用蓝色且不加粗（`\033[0;34m`），其余自述正文同样保持蓝色常规字重。每行结束使用 `\033[0m` 复位，正文必须显式清除前一标题的粗体，不能沿用通用日志函数的粗体蓝色 / 紫色样式。
- 颜色仅作用于自述展示，不改写业务日志的成功 / 警告 / 错误配色，也不改变原有确认和运行策略。兼容既有编号；新增自述使用 `1、` 等中文顿号编号。缺少自述的自有入口需先补齐用途、影响范围和回车确认，再进入真实业务；仅供 `source` 的模块不增加阻塞交互，转发入口复用内层自述，避免重复确认。
- 自述颜色必须保留纯文本降级：Sourcetree、非 TTY、`TERM` 为空 / `dumb` 或设置 `NO_COLOR` 时，不输出 ANSI 转义码。只过滤纯展示输出，禁止把含 `read`、状态赋值或业务操作的整段函数放进管道。验证时隔离运行展示片段，检查红色粗体标题、蓝色非粗体编号正文及纯文本输出；不得为预览配色执行安装、清理、推送等真实业务。

  ```shell
  # 仅渲染自述：标题红色加粗，编号正文蓝色常规字重；非彩色终端输出纯文本。
  jobs_intro_style() {
    local intro_color=0
    if [ -t 1 ] && [ -n "${TERM:-}" ] && [ "${TERM:-}" != dumb ] &&
       [ -z "${NO_COLOR+x}" ] && [ "${PLAIN_OUTPUT:-0}" != 1 ] &&
       [ "${IS_SOURCETREE_RUNTIME:-0}" != 1 ]; then
      intro_color=1
    fi
    /usr/bin/awk -v color="$intro_color" -v role="${1:-body}" '
      BEGIN { esc = sprintf("%c", 27) }
      {
        gsub(esc "\\[[0-9;]*m", "")
        gsub(/\\(033|e|x1[bB])\[[0-9;]*m/, "")
        if (!color || $0 ~ /^[[:space:]]*$/) { print; next }
        numbered = ($0 ~ /^[[:space:]➤ℹ🔹✔⚠]*([0-9]+[、.)）]|[0-9]+️⃣|[-•])/)
        heading = ($0 ~ /^[[:space:]]*#{1,6}[[:space:]]/ || $0 ~ /[：:][[:space:]]*$/ || $0 ~ /^[[:space:]]*[=━─-]{3}/)
        title = (!numbered && (role == "title" || heading))
        if (role == "auto" && !seen && !numbered) title = 1
        if ($0 !~ /^[[:space:]]*[=━─-]+[[:space:]]*$/) seen = 1
        printf "%s%s%s\n", esc (title ? "[1;31m" : "[0;34m"), $0, esc "[0m"
      }
    '
  }
  # 打印脚本内置自述，并等待用户明确确认后再继续。
  show_script_intro_and_wait() {
    clear
    highlight_echo "============================== 脚本自述 ==============================" | jobs_intro_style title
    note_echo "当前脚本：${SCRIPT_PATH}" | jobs_intro_style body
    note_echo "核心用途：这里用一两句话说明脚本解决什么问题。" | jobs_intro_style body
    warn_echo "影响范围：这里说明可能修改的文件、环境或 Git 状态。" | jobs_intro_style body
    gray_echo "取消方式：按 Ctrl+C 终止，不会继续执行后续业务。" | jobs_intro_style body
    highlight_echo "=======================================================================" | jobs_intro_style title
    echo "" | jobs_intro_style body
    read -r "?👉 已了解脚本用途与影响，按回车继续；按 Ctrl+C 取消：" _
  }
  ```

- 普通安装 / 更新 / 升级 / 自检入口的执行确认采用键盘菜单，默认选中“跳过／取消”，用方向键或 Tab 选择后回车确认；不再默认要求“输入任意字符执行”。只读发现与检查可在已有授权内自动完成；真实安装、修复或升级继续展示对象与影响，不能把直接回车设计成默认执行。已进入流程所需 SDK 的自动获取与持续重试按[SDK 环境先决条件](#sdk-acquisition-retry)执行，不重复询问。用户对某个独立入口明确约定的其它交互单独保留。
- <span id="script-dangerous-confirmation">危险操作门禁</span>必须展示风险和作用范围、取得明确授权，并默认取消。用户明确要求免文字输入的入口，提供明确命名的危险选项，选中后再以空格复核授权；普通回车不能默认执行危险操作，取消、空选、输入结束和选择器失败均不得执行。其它独立业务中用户明确要求的精确大写 `YES` 门禁继续保留，不为统一交互批量移除；下例仅用于这类入口。

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

#### 1.3.1、<span id="script-fzf-selection">选择器优先使用 fzf，子层可返回</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- <span id="script-keyboard-only">自动识别与键盘选择优先</span>：尽可能减少或避免文字输入，让用户仅用空格、回车、方向键和 Tab 完成正常选择、返回、取消及确认；文本搜索和其它快捷键只作可选补充。先尊重并校验用户显式参数，再从当前工程、所选目标／配置、已连接设备及现有环境发现所需信息；唯一有效候选自动复用，多个候选用菜单展示名称、来源和适用范围供选择，不要求用户抄写已能取得的 Team ID、UDID 或路径。不能用其它工程、无关 Target 或配置中的参数填补当前目标，自动复用也不替代写操作授权。
- 确需用户提供且无法从现有来源推导的新信息，先说明缺什么、为何无法自动取得，以及对应的原生设置／选择入口；不把自由文本输入当作识别失败的默认回退。已有路径优先发现或用原生选择器取得，确需外部输入时仅收集必要内容，不编造默认值。
- Jobs 自维护脚本中凡是单选、多选、菜单，以及目标、版本、文件等列表选择，都优先使用 [**fzf**](https://formulae.brew.sh/formula/fzf)，不默认设计成手输数字的 `read` 菜单。用户明确指定其它选择方式时按要求执行；无交互终端及 Sourcetree 动作进程仍遵守本文件已有边界，不能为使用 fzf 引入阻塞。
- 使用前检查 fzf 路径、`--version` 和实际需要的选项是否可用。缺失或损坏时明确提示；依赖安装仅沿已有授权执行，未获授权或修复失败则停止并给出安装 / 修复入口，不静默退回数字输入。确因目标环境限制需要其它选择方式时，说明原因并遵从用户已有约定。
- 单选使用回车确认；多选面板直接显示“回车勾选／取消，空格确认”，长列表上下都保留提示。提供明确的“取消本轮”操作行；全选、清空等已提供动作也能用方向键或 Tab 定位后操作，Ctrl+A、Ctrl+D、Esc 等快捷键仅作补充。操作行与业务对象分开解析，不能成为业务选择结果。空选、取消、输入结束或选择器失败不能隐式全选、取当前高亮项或启动业务；明确说明跳过或取消，错误保留失败状态。
- 从一个 fzf 进入下一个 fzf 时，无论是目录 / 菜单下钻，还是“目标 → 版本 → 文件”等连续选择，每个非根层都必须提供返回真正上一选择层的入口；默认绑定 `←` 左方向键，并在面板 header 明示“← 返回上一层”。可同时提供返回行，但不能只显示提示而没有绑定，也不能把返回实现为退出整个脚本。根层明确显示取消方式。
- 将“已选择 / 返回上一层 / 取消流程 / 空选 / 选择器失败”分别传递给调用方；使用专用退出码或显式动作标志，不能把 fzf 通用中断码或空输出一律当作返回，也不能让返回标志混入业务结果。使用 `--expect=left` 时，即使当前查询无匹配、退出码为 `1`，仍应先解析明确的返回键，再判断空选。返回与取消均不得触发下载、克隆、写入或依赖业务选择的其它动作。
- 多层选择使用循环或明确的状态编排，不通过递归重跑整段业务实现返回。返回后保留仍有效的上层选择和查询；上层目标改变时清除依赖它的下层结果，避免沿用旧版本 / 文件。全部选择和确认完成后再执行业务，不能先执行一部分再让用户返回修改选择。
- 选择完成只形成待执行计划，不替代脚本初始自述回车、普通更新 / 下载的执行确认或前文危险操作门禁；确认方式遵循前文的免文字输入规则及用户明确保留的独立例外。
- 验证时使用隔离业务命令并在真实 TTY 中覆盖自动发现的唯一／多候选／缺失分支、单选、多选、全选／清空、逐层 `←` 返回、重新进入、修改上层后重新选择、空选、取消及失败传播；实际走完仅用空格、回车、方向键和 Tab 的正常路径，确认业务结果正确，取消／返回／失败没有真实业务副作用。核对 README 中按键、来源、默认值、必要的文字输入例外及依赖与实现一致；静态搜索到按键名称或通过 `zsh -n` 不能代替交互行为验证。

### <span id="jobs-toc-heading-8" data-jobs-toc="v2">1.4、[**Homebrew**](https://brew.sh/) / MacOS 环境 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

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

### 1.5、<span id="script-package-naming">脚本同名包装、平台与宿主命名</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- Jobs 自维护脚本默认全部使用“同名文件夹 + 真正脚本 + 对应 `README.md`”结构，覆盖 `.sh`、`.zsh`、`.command`、`.rb`、`.py` 等脚本；内部 helper、被 `source` / `require` 载入的脚本以及测试脚本不因所在目录或调用方式自动豁免。文件夹名必须与脚本完整文件名逐字一致，包含前缀与扩展名，例如：

  ```text
  【MacOS】⚙️运行授权.command/
  ├── 【MacOS】⚙️运行授权.command
  └── README.md
  ```

- 只有用户明确拒绝该包装方式时，才按其指定范围保留裸脚本；不能由“现有目录已经这样”“内部使用”或“Python 工具”自行推导例外。命中 `OS@Extension` 已明确要求裸露的管理入口时，先读取 [README 规范：OS@Extension 脚本布局](../jobs-markdown-docs/README规范-OS@Extension脚本布局.md)，只对附件列出的路径与入口应用该用户例外，不扩大到其它脚本。
- 按文件职责识别脚本，不把所有同语言源码机械当作独立脚本。语言包布局必需的纯模块源码（如 Python 的 `__init__.py`）保留语言要求的组织方式；这不构成对辅助脚本、可执行模块或测试脚本的普遍豁免。第三方、供应商和生成代码继续遵守所有权排除边界。
- 以 macOS 系统 Shell 为解释器的脚本（如 `.sh` / `.zsh` / `.command`），名称前加 `【MacOS】`；明确挂载到某个应用的入口改用 `【MacOS@应用名】`，例如 `【MacOS@Xcode】`、`【MacOS@SourceTree】`。脚本目录同步使用相同前缀。普通终端启动不等于专用应用挂载，不为通用脚本猜测宿主或机械增加 `@Terminal`。
- Ruby、Python 等依赖对应语言运行时的脚本本体不因在 macOS 执行、或被 Xcode / Sourcetree 调用而添加 `【MacOS】` / `【MacOS@…】` 前缀；其同名目录也不添加该平台前缀。Shell 包装器即使调用 Ruby / Python，仍按 Shell 入口及真实宿主命名；README 必须写明实际解释器与外部依赖，平台前缀不代表零依赖。
- 根 README 负责总览，各脚本的同名目录 README 说明该脚本的能力、依赖和运行方式，上级独立功能与关键目录继续提供导航；三者不能相互替代。脚本内置自述继续独立维护。
- 编写脚本配套 `README.md` 时必须同时加载 `jobs-markdown-docs`，按 Jobs [**Markdown**](https://markdown.cn) 规范及其[功能覆盖规则](../jobs-markdown-docs/SKILL.md#readme-examples-first)说明当前能力；模式、参数、默认值和副作用等按真实入口对账，历史修复 / 升级叙事转为当前功能说明。
- 现有脚本整理时保留有意义的业务名称，只补齐缺失或错误的平台 / 宿主前缀、同名目录与 README。目录、真正脚本及对应说明一起迁移，引用基准仍从脚本自身或明确项目根目录解析，不因多套一层目录而继续沿用失效的固定父级数量。
- 重命名或包装后，同任务更新真实调用方的相对路径、`source` / `require` / import、测试发现规则、Podfile / 构建 / Scheme 挂载、应用自定义动作、工程展示引用、README 链接与文档登记；只改名称或留下指向旧位置的调用不算完成。先留存原文与路径映射，逐项验证文件、目录和引用一致，复用隔离入口确认搬移 / 改名及无关工作目录下仍能定位，不能为目录整理执行真实安装或构建。
- 批量升级 Shell 脚本时，继续统一 `# shell: zsh`、路径变量、彩色日志、自述阻塞、防误触、`main "$@"`、[**Homebrew**](https://brew.sh/) 自检和升级交互；同名包装、命名与 README 按本节默认规则执行，用户明确例外单独保留。
- 输出压缩包前应做静态检查和结构检查；无法执行 MacOS 专属命令时，README 或最终说明里写清楚“未实际执行”。

### <span id="jobs-toc-heading-10" data-jobs-toc="v2">1.6、Shell 验证 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- Shell 脚本优先做静态检查：

  ```shell
  zsh -n '脚本名.command'
  ```

- 修改 `.command` 后确认 shebang、`SCRIPT_DIR` / `LOG_FILE`、内置自述、回车确认、`main "$@"`、路径引号、前文规定的危险操作门禁、普通升级动作不是默认执行，并核对自动识别与键盘选择路径。
- 修改路径定位或 App 启动入口时，把完整交付目录复制到不同位置、改名后，从无关工作目录验证仍能定位自己的脚本与资源；覆盖空格、中文路径及依赖真实缺失分支。跨机分发场景另外用夹具模拟 App 与外置目录分离，核对包内资源、显式目录及选择 / 取消行为；夹具通过、系统真实 AppTranslocation、AirDrop 接收后的另一台电脑启动分别声明验证状态，不以普通复制冒充真实跨机验收，也不以真实安装 / 卸载代替寻址测试。


### <span id="jobs-toc-heading-11" data-jobs-toc="v2">1.7、脚本运行策略与自检定义 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 本节只补充 1.3 中自述 / 交互规则的运行策略：入口脚本必须先进入 `show_script_intro_and_wait()` 或等价函数；确认前不得执行环境安装、文件写入、Git 索引修改或其它真实业务。
- 日志初始化、`setopt`、`trap` 注册、参数解析、路径切换等准备逻辑要排在自述确认之后；确需提前准备的展示变量，只能下沉到无副作用的展示准备函数中。
- Sourcetree 脚本必须支持双运行模式：明确识别为 Sourcetree 自定义动作时，打印自述后无交互连续执行，需交互的业务按 1.8 转交独立终端；同一脚本在系统终端独立运行时，打印自述并等待回车确认。
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
- 自检、安装、升级都必须先检查再执行，并遵守交互确认：普通写操作不能默认执行，危险动作遵循前文门禁及用户明确约定的例外；新写或升级脚本继续统一使用 `# shell: zsh`，除非目标环境明确不是 MacOS / zsh。

#### <span id="jobs-toc-heading-12" data-jobs-toc="v2">1.7.1、依赖链完整性与条件式自愈 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 当目标命令依赖运行时、包管理器或系统引导工具时，编码前先画出当前执行路径的完整依赖链或依赖图，区分必须同时满足的依赖和可以互相替代的安装来源。不能只检查最末端命令，例如通过 npm 安装或升级 [**CodeGraph**](https://github.com/colbymchenry/codegraph) 时，应识别 `CodeGraph → npm → Node.js → Homebrew → bash / curl / Command Line Tools` 这条可恢复链。
- “已安装”不等于“可用”。`command -v` 只负责发现候选路径；每一层还必须通过 `--version`、只读状态命令或等价的最小健康检查验证真实可执行性。PATH 中存在残缺 shim、损坏安装或不可执行文件时，统一按该层不可用处理。
- 每一层统一采用“发现候选 → 验证可用 → 缺失或损坏时安装 / 修复 → 刷新当前进程环境 → 再次验证”的闭环；只有当前依赖返回成功，才允许进入下一层或最终业务。安装后必须重新解析 PATH、Homebrew `shellenv`、npm 全局 bin 等当前会话环境，不能假设重新打开终端后才生效。
- 即使最终目标命令已经可用，只要本次操作实际包含依赖特定通道的升级、同步或修复，也必须检查该执行路径所需的上游依赖；例如 CodeGraph 升级依赖 npm 时，不能因为 `codegraph --version` 成功就跳过 npm / Node.js 健康检查。
- 只沿缺失或损坏的分支向上溯源。已有健康依赖或等价可用来源必须复用，不重复安装，不为了形式完整强制引入当前路径不需要的包管理器；修复动作必须幂等，健康环境重复运行时不产生写入。
- 普通本地安装或修复每层最多执行一次并立即复检，禁止无限递归；SDK 获取属于[持续自动重试的明确例外](#sdk-acquisition-retry)。确定的本地配置、权限或执行错误仍须停止下游动作，明确输出失败层级、候选路径、失败命令或退出码以及处理方向，不能带病继续执行最终业务。
- 完整依赖链自检不扩张执行权限。只读发现和健康检查可以自动完成；安装、修复、升级等写操作必须属于用户明确请求或当前入口已经清楚声明的行为，并继续遵守普通动作确认和前文危险操作门禁。
- 验证此类脚本时，除 `zsh -n` 外，还要覆盖“全链健康、末端缺失但上游健康、多层连续缺失、安装失败、安装后复检失败”五类分支。优先使用隔离 PATH 或假命令验证分支；用户未要求真实安装时，不得把实际包管理器安装 / 升级当成测试。

- 批量整改后必须同时扫描四类结构问题：一是函数外是否仍有散落执行语句，二是 `main()` 是否严格只含“单行函数调用 + 行尾职责注释”，三是每个调用是否都有同行业务职责注释，四是 `main()` 的第一条函数调用是否为运行时内置自述；不能只做 `zsh -n` 就视为完成。


#### 1.7.2、<span id="sdk-acquisition-retry">SDK 环境先决条件与持续自动获取</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 环境是执行业务的先决条件。Jobs 自维护脚本及系统右键菜单中，当前流程所需的 SDK 缺失或组件不完整时必须先补齐并验证可用，再进入构建、运行、打包等业务；不能以路径存在冒充就绪。覆盖直接下载、版本管理器安装、仓库克隆、平台组件及模拟器系统镜像，以及首次调用隐式补齐的组件，如 Flutter 首次启动下载 Dart SDK。
- 入口已声明并获准的必需 SDK 获取默认自动执行；下载失败、断流、网络超时或获取阶段失败后持续重试，不设默认次数或总时长上限，不要求用户确认下载、确认重试或重新启动脚本。正常结束条件是获取并验证成功，或用户主动取消、停止进程；取消信号与取消退出码不得被重试循环吞掉。
- 每次尝试可设置合理的连接／停滞超时，超时只结束本次尝试，随后自动重试。不要沿用短时健康探测的总超时反复掐断仍在传输的大文件；提供有上限的等待退避，避免空转与刷屏，等待期间同样可中断。
- 保留已下载且可安全续传的内容，复用缓存；残缺克隆、压缩包与安装分别验证，不能见目录就当成功，也不能为重试清空共享缓存或用户已有 SDK。普通流程切换来源、版本或代理不能隐式发生；Flutter SDK 在已声明的自动选路策略下按[下载前网络检测](#flutter-sdk-network-routing)选择并显示实际路线，仍遵守显式配置与网络作用域规则。
- 重试边界只包围可重入的 SDK 获取／补齐步骤，不能反复执行整个构建、安装 App 或其它业务副作用。确定的参数错误、版本不存在、磁盘不足、权限与许可证／认证问题须如实标明，等待用户处理或明确失败；不得伪称网络重试或自动绕过授权。系统异步安装器接管后持续复检并在就绪后自动续行，不反复弹出安装窗口，不把“已启动安装器”当作就绪；安装器内部网络由官方界面管理时明确该边界。
- 真实进度同步显示并追加日志，保留各次尝试的对象、来源、版本、目标、退出码、重试次数与下次间隔；机器可读输出单独保存。界面提示持续重试及主动结束方式，不伪造进度，不用成功状态掩盖尚未就绪的环境。
- 修改右键 SDK 行为时核对双端、独立入口、聚合同包副本与首次启动的隐式下载路径；同步脚本自述和 README。隔离验证至少覆盖连续失败后成功、超过旧次数仍重试、单次超时后恢复、下载中及等待中取消、缓存保留、确定的本地错误，以及业务仅在环境成功后执行一次。源码、已安装菜单和真实网络获取分别声明验证范围。

#### 1.7.3、<span id="flutter-sdk-network-routing">Flutter SDK 下载前网络检测与自动选路</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 所有自维护 Flutter SDK 获取入口都必须在实际下载前检测当前网络，再决定本任务使用的下载路线；覆盖 FVM、直接安装、首次调用补齐 Dart／引擎、平台预缓存及鸿蒙 Flutter 等间接入口，不能只修一个右键菜单。健康本地 SDK 可直接复用，不为没有下载需求的流程强制增加联网前提。独立包、聚合包和同类副本同步，保留用户 fork 与原有业务差异。
- 下载前先显示 SDK 名称、项目声明版本、实际 SDK 版本／路径、系统架构及已知 engine／提交。目标 Dart 版本必须来自与目标 engine 对应的可信元数据；尚未取得时明确说明，不能把 `.old` 或过期缓存当作本次目标。来源、路线、选择原因与实际进度一起进入脱敏日志。
- 显式 SDK 源、包源、代理及其空值优先保留；不能因测速慢而静默覆盖它们。未受显式配置约束的自动模式，可比较官方源、官方文档列出的可信镜像及当前已配置的本机代理路线；不固定代理端口，不引入未知公共代理，不改写私有仓库／鸿蒙 fork 地址。只能对可确认等价的版本、架构、制品路径和元数据切换镜像，不能把 SDK 二进制与 Git 仓库获取当成同一种来源。
- 使用有界、小流量的真实请求检测连接、TLS、首字节和传输情况；只做 HEAD、只测端口或收到错误页面不能算下载路线可用。制品 Range 探测核对状态、范围、字节数与可得的可信摘要／标识，不把忽略范围的整包响应用于测速；探测写入独立临时位置，不接触正在续传的 SDK 文件。
- 将探测结果和所选环境限定于本任务及子进程，短时复用，避免每个文件重复测速；路线失效或缓存过期时重新检测。全部候选因网络不可用时退避重测，沿用 SDK 持续获取规则，不带病进入构建，也不能只报一次失败就退出。环境注入不能写入系统代理、Shell 启动文件、全局 Git 或其它持久配置，结束后自然恢复原环境。
- SDK 共享缓存只能由一个有效获取任务写入；已有写者时明确显示并等待，可主动取消，不能为抢锁杀掉其它有效任务。超时与取消清理本轮完整子进程树，防止父进程退出后遗留下载；确认损坏的本次缓存保留可核对副本后再重新获取，不用不同来源的字节盲目拼接。
- 隔离验证覆盖显式源／代理及空值、不同网络下的最优可用路线、错误页／范围不符、全部断网后恢复、探测取消、路线缓存失效、进程环境恢复、SDK 写者等待及失败后重取。测试必须拦截新增探测入口，不能因旧 mock 失效而触发真实安装；源码覆盖、真实网络测速、已安装菜单分别验收。

### <span id="jobs-toc-heading-15" data-jobs-toc="v2">1.8、Sourcetree 自定义动作脚本兼容 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 新增、修改或重命名 Jobs 的 Sourcetree 自定义动作脚本、动作登记或安装配置时，必须先读取同级附件 [Sourcetree 脚本路径与挂载规则](./Sourcetree脚本路径与挂载规则.md)，执行固定双位置同步、菜单挂载、寻址和验证要求。
- `Sourcetree` 自定义动作运行 `.command` 时，环境可能和系统终端双击运行不同：`TERM` 可能为空、`$0` 可能只是脚本名而不是绝对路径、标准输入可能不可交互、输出窗口可能不解析 ANSI 彩色码。
- 编写 Sourcetree 自定义动作脚本时，必须显式探测运行环境；只有明确确认由 Sourcetree 发起时，才进入无交互连续执行模式，不要影响用户双击脚本后在系统终端里的正常交互体验。
- Sourcetree 动作进程必须从一而终：禁止调用 `read`、`select`、`fzf` 选择、`YES` 确认或任何需要外界输入的交互；所需目标应来自自定义动作参数、当前工作目录、环境变量或安全默认值。必要参数缺失时直接打印错误并退出，不能停在输入等待状态。
- 需要用户选择或危险确认的动作，由 Sourcetree 入口校验参数后打开独立 `Terminal.app`，在真正可交互的终端中重新展示内置自述、回车确认与后续选择；使用明确的终端运行标志避免再次转发，安全引用脚本与仓库路径，并保留最终退出码。打开终端失败或终端仍无 TTY 时停止，不能回退到无交互执行危险动作。终端承接后按终端模式显示红色风险提醒；只有用户精确输入大写 `YES` 才允许舍弃改动，回车、其它输入、输入流结束和任何无交互模式均不能绕过门禁。
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
    highlight_echo "============================== 脚本内置自述 ==============================" | jobs_intro_style title
    note_echo "脚本名称：${SCRIPT_BASENAME}" | jobs_intro_style title
    note_echo "核心用途：这里简要说明 Sourcetree 动作将执行的业务。" | jobs_intro_style body
    note_echo "运行策略：Sourcetree 内无交互连续执行；终端独立运行需回车确认。" | jobs_intro_style body
    gray_echo "日志文件：${LOG_FILE}" | jobs_intro_style body
    highlight_echo "============================================================================" | jobs_intro_style title

    if [[ "${IS_SOURCETREE_RUNTIME:-0}" == "1" ]]; then
      gray_echo "已识别为 Sourcetree 自定义动作，将跳过交互并连续执行。" | jobs_intro_style body
      return 0
    fi
    if [[ ! -t 0 ]]; then
      error_echo "当前不是 Sourcetree，且没有可交互输入；请在终端中重新运行。"
      return 1
    fi
    read -r "?👉 已了解脚本用途与影响，按回车继续；按 Ctrl+C 取消：" _
  }
  ```

- `SCRIPT_DIR` 不能只依赖 `dirname "$0"`；`$0` 不是绝对路径时，必须按 [Sourcetree 脚本路径与挂载规则](./Sourcetree脚本路径与挂载规则.md#script-location) 找回真实脚本目录；运行时自述仍以内置文本为准，不能在运行时 `cat`、拼接或依赖外部 `README.md`。
- 调用 `clear` 前必须确认是完整终端，例如同时满足 `-t 1`、`TERM` 非空且不是 `dumb`，并且不是 `Sourcetree` 瘦身环境；否则跳过 `clear`，避免出现 `TERM environment variable not set.`。
- 彩色日志必须支持纯文本降级：如果检测到 `Sourcetree`、非 TTY、`TERM=dumb` 或用户设置 `NO_COLOR`，不要输出 `\033` 这类 ANSI 转义码，避免日志和 SourceTree 窗口里出现 `[0m` 乱码；此规则对所有 SourceTree 脚本强制生效。
- `Sourcetree` 脚本如果会递归处理工程目录，默认跳过 `.git`、`Pods`、`.dart_tool`、`build`、`DerivedData`，并在最后输出总数、失败数和日志路径；只要有子任务失败，脚本最终也要返回失败状态，方便 `Sourcetree` 判断执行结果。

### 1.9、<span id="network-proxy-recovery">网络代理选择、回溯与恢复</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 启用、停用或切换网络代理前，运行时自述必须醒目说明：这是侵入性网络环境变更，为什么需要、影响哪些进程或配置、流量将经过哪里、可能中断哪些连接，以及如何切回原状态；同时给出日志和恢复入口。已有授权可以覆盖本次选择，不额外堆叠重复确认，但不能省略警示。
- 有交互的入口应明确提供“使用代理 / 不使用本次显式代理”选择，显示默认值、取消方式和各模式真实含义。默认值按用户对当前脚本的要求设置，不能把某个启动器的“直接回车使用代理”推广为其它脚本的默认行为；没有授权时保留原环境或取消。已获明确授权的 [Flutter SDK 自动选路](#flutter-sdk-network-routing)按探测结果决定本任务路线，不逐次追加代理确认，仍须说明作用范围、恢复方式并保留显式配置。无交互入口只能使用已授权的明确参数，缺少必要选择时停止。
- 优先通过单条命令、子 Shell 或新启动进程传入环境，仅影响目标应用及其子进程。不得为一次启动顺手修改系统网络服务、全局 `launchctl` 环境、Shell 启动文件、全局路由或持久化配置；确需扩大作用域时，先说明具体范围并取得对应授权。
- 原地修改或持久化写入前，精确保存将要改动的每项状态及本次写入值：环境变量须区分原本未设置、已设置为空字符串、已设置为非空值；配置还须保留原启用状态、地址、端口、绕过规则及归属作用域。只采集本次需要的键，不转储整个进程环境或无关配置。含敏感值的恢复快照按最小权限保存，与脱敏审计日志分开。仅向子命令或新应用注入环境、父 Shell 和持久状态均未改变时，无需采集未修改的父环境敏感值或建立全量快照；记录注入范围，并提供退出目标应用后按原生方式重新启动的撤回入口。
- “恢复原状态”必须按快照还原，原本未设置的键用 `unset`，原本为空的键还原为空；不能用清空全部代理代替恢复。仅恢复本次实际修改的项，写回前核对当前值仍等于本次写入值；发现其它进程或用户已改动时，保留新状态并报告冲突，禁止用旧快照覆盖并发修改。
- 提供可随时调用、可重复执行的恢复入口，并说明异常退出时的恢复办法；需要恢复的持久状态在受控失败或中断时执行清理。进程内代理随目标进程退出结束；后台应用继续运行时仍保有启动环境，恢复父 Shell 或关闭终端不代表该应用已恢复。切换已有应用的模式须完整退出并按所选模式重启，先提示重启对在途任务的影响，不能复用旧进程后声称新环境已生效。
- “不使用本次显式代理”只表示清除或不注入本脚本负责的代理项；系统代理、自动代理规则、透明隧道和应用自有代理仍可能生效。未核实实际路由时不得称为“全系统直连”；恢复原状态也不等于强制直连。
- 审计记录使用独立运行编号或追加日志，保留时间、所选模式、作用域、修改项名称、原状态类别、执行与验证结果、恢复尝试及结果；后次运行不能抹掉前次恢复依据。不记录代理密码、凭据、完整环境或含认证信息的代理 URL，日志中只保留必要的脱敏摘要。
- 配置读回、进程是否重新启动、目标连接是否成功分别验证；端口可连接或配置已写入不能替代应用真实连接结果。恢复失败、状态冲突或验证不通过必须显式报错并返回失败状态，保留快照和人工恢复路径，不能输出“已恢复”或静默继续。

### 1.10、<span id="paired-deployment-rollback">部署与反部署脚本成对</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 每个目标系统的部署脚本必须配套可执行的反部署脚本；菜单可转调该脚本，不能用占位 README、手工停止指令或仅结束进程代替。反部署是部署实际变更的逆操作，目标是恢复部署前环境；完整交付范围见[升级、回滚与反部署](../jobs-software-project/软件项目开发与交付规范.md#deployment-recovery)。
- 部署前记录本次将改动对象的原状态与归属，部署后保留实际创建／替换的程序、配置、服务、依赖、SDK及缓存清单和必要恢复副本；已存在与新安装分开登记，日志脱敏。反部署仅停止经身份核验属于本次部署的进程，恢复本次覆盖的原配置，删除本次新建且确认未被其它项目使用的对象；原有或共享环境不能按目录整片清空。归属不明、状态已被后续修改或缺失恢复依据时保留对象并明确报告未完成项，不能声称已回到原点。
- 数据处理使用 [**fzf**](https://formulae.brew.sh/formula/fzf) 选择“数据库数据备份”（默认）或“数据库数据清零”，同时覆盖对应文件存储、附件及匹配密钥；选择与危险确认分别处理，取消、空选或失败不执行清理。备份先保存至清理范围外并核对完整性、匹配密钥与恢复所需配置，验证后清理所选本项目源数据；验证失败或源内容已偏离确认快照时保留源与原备份并停止，不静默改备份后继续清零；清零须展示本项目准确范围并经既有危险操作门禁明确确认，不删除其它项目或共用数据库。
- 支持中断后的可核对重试；按部署前清单逐项验证恢复、数据去向及遗留对象。用隔离夹具覆盖原有／新建／共享资源、进程身份、备份失败、清零、取消、并发变更及重复反部署，目标系统实机结果另行声明；不为验证卸载用户真实环境。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
