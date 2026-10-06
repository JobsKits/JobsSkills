#!/bin/zsh
# 脚本自述：
# - 脚本名称：同步Skills.command
# - 核心用途：通过 fzf 选择 Skill 包，在系统 Skills 与本目录之间手动双向同步。
# - 影响范围：覆盖同名源文件、保留目标独有文件；完整备份后把软链接实体化，绝不写穿上游。
# - 运行提示：先回车确认，再选方向、选 Skill、看预览；输入 YES 才真正同步，Ctrl+C 可取消。
# shell: zsh

typeset -g SCRIPT_DIR SCRIPT_PATH SCRIPT_BASENAME LOG_FILE SYSTEM_DIR REPO_DIR STATE_DIR
typeset -g SOURCE_DIR TARGET_DIR DIRECTION_LABEL FZF_BIN RSYNC_BIN BREW_BIN BREW_PREFIX
typeset -g SCAN_FILE CHOICE_FILE PREVIEW_FILE BACKUP_DIR STAGING_DIR ACTIVE_TARGET PREVIOUS_TARGET
typeset -g ALL_OPTION DRY_RUN=0 USE_COLOR=0
typeset -ga AVAILABLE_SKILLS SELECTED_SKILLS

# 为自述提供红色标题、蓝色正文与纯文本降级。
jobs_intro_style() {
  local color=0
  if [[ -t 1 && -n "${TERM:-}" && "${TERM:-}" != dumb && -z "${NO_COLOR+x}" ]]; then
    color=1
  fi
  /usr/bin/awk -v color="$color" -v role="${1:-body}" '
    BEGIN { esc = sprintf("%c", 27) }
    { if (!color || $0 == "") { print; next }
      printf "%s%s%s\n", esc (role == "title" ? "[1;31m" : "[0;34m"), $0, esc "[0m" }
  '
}
# 显示使用说明；帮助模式不创建日志或其它文件。
show_help() {
  printf '%s\n' \
    '同步Skills.command：手动双向同步 Codex 用户级 Skill 包。' \
    '用法：./同步Skills.command [--dry-run] [--help]' \
    '流程：回车确认 → 方向（默认系统到当前）→ fzf 选择（默认全部）→ 变更预览 → YES。' \
    'Tab / Shift+Tab 多选，直接 Enter 接受当前项；Esc / Ctrl+C 取消。' \
    '只同步含有效 SKILL.md 的根层包，包内嵌套 Skill 随包同步。' \
    '同名源文件覆盖，目标独有文件保留；源端链接解引用复制，目标链接经备份后替换为实体。' \
    '.git、.system、插件与构建缓存不从源复制；根层 README、.gitignore、脚本不参与同步。' \
    '目标包内存在 .git 时拒绝同步，以保护独立仓库元数据。' \
    '--dry-run：仍交互选择和预览，但不安装依赖、不备份、不复制、不修改目标；会写运行日志。' \
    '默认系统目录：${HOME}/.agents/skills；默认仓库目录：脚本自身目录。' \
    '默认备份：${XDG_STATE_HOME:-${HOME}/.local/state}/jobs-skills-sync/backups/唯一时间戳目录。' \
    '日志：${TMPDIR:-/tmp}/同步Skills.log（每次运行重新写入）。' \
    '隔离测试可覆盖：JOBS_SKILLS_SYNC_SYSTEM_DIR、JOBS_SKILLS_SYNC_REPO_DIR、JOBS_SKILLS_SYNC_STATE_DIR。' \
    '覆盖路径必须是绝对路径；两端根目录须已存在，状态目录不得放在 Skills 树或本脚本父 Git 工作树内。'
}
# 第一屏打印写在源码内的用途和边界，确认前不初始化日志。
show_script_intro_and_wait() {
  local arg=""
  for arg in "$@"; do
    if [[ "$arg" == --help || "$arg" == -h ]]; then
      show_help
      exit 0
    fi
  done
  printf '\n同步Skills.command\n' | jobs_intro_style title
  printf '%s\n' \
    '1、用途：手动选择系统 Skills → 当前目录，或当前目录 → 系统 Skills。' \
    '2、范围：按根层 Skill 包同步，默认全部；覆盖同名源文件，保留目标独有文件。' \
    '3、链接：源端与目标端链接都会实体化；先备份原链接结构和实体快照，不改外援上游。' \
    '4、保护：不触碰根层 Git、.system、插件目录、README、.gitignore和本脚本。' \
    '5、执行：先展示变更，输入 YES 才备份与同步；--dry-run 只预览。' \
    '6、依赖：需要可用的 fzf 与 rsync；fzf 缺失时可另行确认通过现有 Homebrew 安装。' \
    '7、备份：用户状态目录 jobs-skills-sync/backups；日志在系统临时目录“同步Skills.log”。' \
    '8、取消：方向菜单输入 q，fzf 按 Esc，或随时按 Ctrl+C。' | jobs_intro_style body
  if [[ ! -t 0 ]]; then
    printf '✖ 请在终端交互运行此脚本；当前没有可交互输入。\n' >&2
    exit 1
  fi
  IFS= read -r '?👉 已了解用途与影响，按回车继续；按 Ctrl+C 取消：' arg || exit 130
}
# 将纯文本同步写入屏幕与日志，保留路径中的反斜杠。
log() {
  print -r -- "$1" | /usr/bin/tee -a "$LOG_FILE"
}
# 按终端能力输出业务日志颜色。
styled_log() {
  local code="$1"
  local message="$2"
  if (( USE_COLOR )); then
    log $'\033['"${code}m${message}"$'\033[0m'
  else
    log "$message"
  fi
}
# 输出正常状态。
color_echo() { styled_log '1;32' "$1"; }
# 输出信息状态。
info_echo() { styled_log '1;34' "ℹ $1"; }
# 输出完成状态。
success_echo() { styled_log '1;32' "✔ $1"; }
# 输出需留意的边界。
warn_echo() { styled_log '1;33' "⚠ $1"; }
# 输出温馨提示。
warm_echo() { styled_log '1;33' "$1"; }
# 输出说明。
note_echo() { styled_log '1;35' "➤ $1"; }
# 输出错误状态。
error_echo() { styled_log '1;31' "✖ $1" >&2; }
# 输出纯文本错误。
err_echo() { log "$1" >&2; }
# 输出调试信息。
debug_echo() { styled_log '1;35' "🐞 $1"; }
# 输出高亮信息。
highlight_echo() { styled_log '1;36' "🔹 $1"; }
# 输出次要说明。
gray_echo() { styled_log '0;90' "$1"; }
# 输出加粗信息。
bold_echo() { styled_log '1' "$1"; }
# 输出下划线信息。
underline_echo() { styled_log '4' "$1"; }
# 停止后续步骤并保留失败现场和日志。
fail() {
  error_echo "$1"
  [[ -n "$BACKUP_DIR" ]] && warn_echo "已完成的备份保留在：$BACKUP_DIR"
  [[ -n "$STAGING_DIR" && -d "$STAGING_DIR" ]] && warn_echo "同步暂存现场保留在：$STAGING_DIR"
  exit 1
}
# 删除本次生成的已知临时选择文件，不递归处理其它目录。
cleanup_scratch() {
  local scratch=""
  for scratch in "$SCAN_FILE" "$CHOICE_FILE" "$PREVIEW_FILE"; do
    [[ -n "$scratch" && -f "$scratch" ]] && /bin/rm -f -- "$scratch"
  done
  return 0
}
# 中断切换时恢复仍未被替换的原包，并留下其它现场供检查。
handle_interrupt() {
  if [[ -n "$ACTIVE_TARGET" && ! -e "$ACTIVE_TARGET" && ! -L "$ACTIVE_TARGET" &&
        -n "$PREVIOUS_TARGET" && ( -e "$PREVIOUS_TARGET" || -L "$PREVIOUS_TARGET" ) ]]; then
    /bin/mv -- "$PREVIOUS_TARGET" "$ACTIVE_TARGET" || error_echo "无法恢复原目标，请检查：$PREVIOUS_TARGET"
  fi
  warn_echo '已取消；已完成的包不会自动回滚，备份和同步现场保留。'
  [[ -n "$BACKUP_DIR" ]] && note_echo "备份：$BACKUP_DIR"
  exit 130
}
# 在自述确认后解析参数、动态路径、临时文件和日志。
initialize_runtime() {
  setopt NO_NOMATCH
  export PATH="${PATH:-}:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  local arg=""
  for arg in "$@"; do
    case "$arg" in
      --dry-run) DRY_RUN=1 ;;
      *) printf '✖ 未知参数：%s；使用 --help 查看说明。\n' "$arg" >&2; exit 1 ;;
    esac
  done
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd -P)" || exit 1
  SCRIPT_PATH="${SCRIPT_DIR}/$(basename -- "${ZSH_ARGZERO:-${(%):-%x}}")"
  SCRIPT_BASENAME="$(basename -- "$SCRIPT_PATH" | /usr/bin/sed 's/\.[^.]*$//')"
  LOG_FILE="${TMPDIR:-/tmp}/${SCRIPT_BASENAME}.log"
  : > "$LOG_FILE" || exit 1
  if [[ -t 1 && -n "${TERM:-}" && "${TERM:-}" != dumb && -z "${NO_COLOR+x}" ]]; then
    USE_COLOR=1
  fi
  SYSTEM_DIR="${JOBS_SKILLS_SYNC_SYSTEM_DIR:-${HOME}/.agents/skills}"
  REPO_DIR="${JOBS_SKILLS_SYNC_REPO_DIR:-${SCRIPT_DIR}}"
  STATE_DIR="${JOBS_SKILLS_SYNC_STATE_DIR:-${XDG_STATE_HOME:-${HOME}/.local/state}/jobs-skills-sync}"
  local root=""
  for root in "$SYSTEM_DIR" "$REPO_DIR" "$STATE_DIR"; do
    [[ "$root" == /* ]] || fail "目录必须是绝对路径：$root"
  done
  [[ -d "$SYSTEM_DIR" ]] || fail "系统 Skills 目录不存在：$SYSTEM_DIR"
  [[ -d "$REPO_DIR" ]] || fail "当前 Skills 目录不存在：$REPO_DIR"
  SYSTEM_DIR="$(cd "$SYSTEM_DIR" && pwd -P)" || fail '无法读取系统目录。'
  REPO_DIR="$(cd "$REPO_DIR" && pwd -P)" || fail '无法读取当前目录。'
  STATE_DIR="${STATE_DIR:A}"
  if [[ "$SYSTEM_DIR" == "$REPO_DIR" || "$SYSTEM_DIR" == "${REPO_DIR}/"* || "$REPO_DIR" == "${SYSTEM_DIR}/"* ]]; then
    fail '两个 Skills 根目录相同或互相嵌套，不能执行同步。'
  fi
  if [[ "$STATE_DIR" == "$SYSTEM_DIR" || "$STATE_DIR" == "${SYSTEM_DIR}/"* ||
        "$STATE_DIR" == "$REPO_DIR" || "$STATE_DIR" == "${REPO_DIR}/"* ]]; then
    fail '持久状态目录不得放在任一 Skills 根目录内。'
  fi
  local parent_repo="${SCRIPT_DIR:h}"
  if [[ -e "${parent_repo}/.git" && ( "$STATE_DIR" == "$parent_repo" || "$STATE_DIR" == "${parent_repo}/"* ) ]]; then
    fail '持久状态目录不得放在本脚本的父 Git 工作树内。'
  fi
  SCAN_FILE="$(/usr/bin/mktemp "${TMPDIR:-/tmp}/jobs-skills-scan.XXXXXX")" || fail '无法创建扫描临时文件。'
  CHOICE_FILE="$(/usr/bin/mktemp "${TMPDIR:-/tmp}/jobs-skills-choice.XXXXXX")" || fail '无法创建选择临时文件。'
  PREVIEW_FILE="$(/usr/bin/mktemp "${TMPDIR:-/tmp}/jobs-skills-preview.XXXXXX")" || fail '无法创建预览临时文件。'
  trap cleanup_scratch EXIT
  trap handle_interrupt INT TERM
  info_echo "运行日志：$LOG_FILE"
  (( DRY_RUN )) && note_echo '当前为 --dry-run；只预览，不安装依赖、不备份、不复制。'
  return 0
}
# 显示两个相反方向，直接回车使用系统到当前目录。
choose_direction() {
  local answer=""
  log "1、系统 Skills → 当前目录（默认）"
  log "   $SYSTEM_DIR → $REPO_DIR"
  log "2、当前目录 → 系统 Skills"
  log "   $REPO_DIR → $SYSTEM_DIR"
  IFS= read -r '?👉 选择方向 [1/2]；回车选 1，q 取消：' answer || exit 130
  case "$answer" in
    ''|1) SOURCE_DIR="$SYSTEM_DIR"; TARGET_DIR="$REPO_DIR"; DIRECTION_LABEL='系统 Skills → 当前目录' ;;
    2) SOURCE_DIR="$REPO_DIR"; TARGET_DIR="$SYSTEM_DIR"; DIRECTION_LABEL='当前目录 → 系统 Skills' ;;
    q|Q) note_echo '已取消，未复制任何 Skill。'; exit 0 ;;
    *) fail "方向无效：$answer" ;;
  esac
}
# 同步记录外部命令输出，返回真实命令失败状态。
run_logged() {
  "$@" 2>&1 | /usr/bin/tee -a "$LOG_FILE"
  local command_code=${pipestatus[1]}
  return "$command_code"
}
# 发现并验证 fzf，优先复用现有健康安装。
discover_healthy_fzf() {
  local candidate=""
  local -a candidates
  candidates=("$(command -v fzf 2>/dev/null)" "${BREW_PREFIX:+${BREW_PREFIX}/bin/fzf}" /opt/homebrew/bin/fzf /usr/local/bin/fzf)
  for candidate in "${candidates[@]}"; do
    if [[ -n "$candidate" && -x "$candidate" ]] && "$candidate" --version >/dev/null 2>&1; then
      FZF_BIN="$candidate"
      return 0
    fi
  done
  return 1
}
# 为 fzf 安装路径验证 Homebrew 与上游 Command Line Tools。
check_brew_install_chain() {
  local candidate=""
  local -a candidates
  candidates=("$(command -v brew 2>/dev/null)" /opt/homebrew/bin/brew /usr/local/bin/brew)
  for candidate in "${candidates[@]}"; do
    if [[ -n "$candidate" && -x "$candidate" ]] && "$candidate" --version >/dev/null 2>&1; then
      BREW_PREFIX="$("$candidate" --prefix 2>>"$LOG_FILE")" || continue
      [[ -d "$BREW_PREFIX" && "$BREW_PREFIX" == /* ]] || continue
      BREW_BIN="$candidate"
      break
    fi
  done
  [[ -n "$BREW_BIN" ]] || fail '没有健康的 Homebrew；请先手动安装或修复 Homebrew，然后重试。'
  /usr/bin/xcode-select -p >/dev/null 2>&1 || fail 'Command Line Tools 未配置；请手动运行 xcode-select --install 后重试。'
  local compiler=""
  compiler="$(/usr/bin/xcrun --find clang 2>>"$LOG_FILE")" || fail 'xcrun 无法找到 clang；请修复 Command Line Tools。'
  [[ -x "$compiler" ]] && "$compiler" --version >/dev/null 2>&1 || fail "clang 不可用：$compiler"
}
# 检查 rsync 和 fzf；缺失分支只经运行时确认安装一次。
check_environment() {
  RSYNC_BIN="$(command -v rsync 2>/dev/null)"
  [[ -n "$RSYNC_BIN" && -x "$RSYNC_BIN" ]] && "$RSYNC_BIN" --version >/dev/null 2>&1 || fail '缺少健康的 rsync，请先修复系统工具。'
  if discover_healthy_fzf; then
    info_echo "fzf：$FZF_BIN"
    return 0
  fi
  (( DRY_RUN )) && fail '--dry-run 不安装依赖；请先安装或修复 fzf 后重试。'
  warn_echo 'fzf 缺失或不可用；可以通过已安装的 Homebrew 安装或修复一次。'
  local answer=""
  IFS= read -r '?👉 安装/修复 fzf（直接回车跳过；输入任意字符后回车执行）：' answer || exit 130
  [[ -n "$answer" ]] || fail '已跳过 fzf 安装，无法继续交互选择。'
  check_brew_install_chain
  if "$BREW_BIN" list --versions fzf >/dev/null 2>&1; then
    run_logged "$BREW_BIN" reinstall fzf || fail 'Homebrew 修复 fzf 失败，请查看日志。'
  else
    run_logged "$BREW_BIN" install fzf || fail 'Homebrew 安装 fzf 失败，请查看日志。'
  fi
  export PATH="${BREW_PREFIX}/bin:${BREW_PREFIX}/sbin:${PATH}"
  rehash
  discover_healthy_fzf || fail '安装后 fzf 复检仍失败，请人工检查安装和 PATH。'
  success_echo "fzf 已复检可用：$FZF_BIN"
}
# 检查 Skill 文件具有闭合的 frontmatter 和非空 name、description。
is_valid_skill_file() {
  [[ -r "$1" && -s "$1" ]] || return 1
  /usr/bin/awk '
    NR == 1 { sub(/\r$/, ""); if ($0 != "---") exit 1; next }
    /^---\r?$/ { closed=1; exit }
    /^name:[[:space:]]*[^[:space:]]/ { named=1 }
    /^description:[[:space:]]*[^[:space:]]/ { described=1 }
    END { exit !(closed && named && described) }
  ' "$1"
}
# 只识别有效根层包，包内嵌套 Skill 整包参与选择。
discover_skill_packages() {
  AVAILABLE_SKILLS=()
  local package=""
  local skill_file=""
  local name=""
  local valid=0
  for package in "${SOURCE_DIR}"/*(DN); do
    name="${package:t}"
    case "$name" in
      .*|plugins|node_modules|Pods|build|DerivedData|ManualBy*Pods@Pods|PodsManual) continue ;;
    esac
    [[ -d "$package" ]] || continue
    /usr/bin/find -L "$package" \( -name .git -o -name .system -o -name plugins -o -name node_modules -o -name Pods -o -name .dart_tool -o -name build -o -name DerivedData \) -prune -o -type f -name SKILL.md -print0 > "$SCAN_FILE" 2>>"$LOG_FILE" || fail "Skill 扫描失败，可能存在循环链接：$package；详情见日志。"
    valid=0
    while IFS= read -r -d '' skill_file; do
      if is_valid_skill_file "$skill_file"; then
        valid=1
        break
      fi
    done < "$SCAN_FILE"
    (( valid )) && AVAILABLE_SKILLS+=("$name")
  done
  (( ${#AVAILABLE_SKILLS} > 0 )) || fail "源目录没有含有效 SKILL.md 的可同步包：$SOURCE_DIR"
  ALL_OPTION="全部同步（默认，共 ${#AVAILABLE_SKILLS} 个 Skill 包）"
}
# 用 NUL 分隔 fzf 输入输出，支持空格、中文及特殊文件名。
choose_skills() {
  printf '%s\0' "$ALL_OPTION" "${AVAILABLE_SKILLS[@]}" |
    FZF_DEFAULT_OPTS='' FZF_DEFAULT_OPTS_FILE='' FZF_DEFAULT_COMMAND='' "$FZF_BIN" \
      --read0 --print0 --multi --no-sort --layout=reverse --height=80% --border \
      --prompt='选择 Skills > ' --bind='esc:abort,ctrl-c:abort' \
      --header='第一项默认全部；Enter 确认，Tab / Shift+Tab 多选，Esc / Ctrl+C 取消' > "$CHOICE_FILE"
  local picker_code=${pipestatus[2]}
  if (( picker_code == 130 || picker_code == 1 )); then
    note_echo '已取消 Skill 选择，未复制任何 Skill。'
    exit 0
  fi
  (( picker_code == 0 )) || fail "fzf 选择失败，退出码：$picker_code"
  SELECTED_SKILLS=()
  local chosen=""
  while IFS= read -r -d '' chosen; do
    if [[ "$chosen" == "$ALL_OPTION" ]]; then
      SELECTED_SKILLS=("${AVAILABLE_SKILLS[@]}")
      break
    fi
    (( ${AVAILABLE_SKILLS[(Ie)$chosen]} > 0 )) || fail "fzf 返回未知 Skill：$chosen"
    (( ${SELECTED_SKILLS[(Ie)$chosen]} > 0 )) || SELECTED_SKILLS+=("$chosen")
  done < "$CHOICE_FILE"
  (( ${#SELECTED_SKILLS} > 0 )) || fail '没有选中 Skill；未执行同步。'
}
# 在预览前拒绝目标包中的 Git 元数据和非目录冲突。
preflight_targets() {
  local name=""
  local target=""
  for name in "${SELECTED_SKILLS[@]}"; do
    target="${TARGET_DIR}/${name}"
    if [[ -e "$target" || -L "$target" ]]; then
      [[ -d "$target" ]] || fail "目标同名项不是有效目录，不能覆盖：$target"
      /usr/bin/find -L "$target" -name .git -print0 -prune > "$SCAN_FILE" 2>>"$LOG_FILE" || fail "目标扫描失败，可能存在循环链接：$target"
      [[ ! -s "$SCAN_FILE" ]] || fail "目标 Skill 包内存在 .git，保护嵌套 Git 仓库并停止：$target"
    fi
  done
}
# 给源端复制和预览使用相同的保护过滤，不用于目标完整备份。
rsync_source_to() {
  "$RSYNC_BIN" --archive --copy-links --checksum \
    --exclude='.git' --exclude='.system' --exclude='plugins' --exclude='node_modules' \
    --exclude='Pods' --exclude='.dart_tool' --exclude='build' --exclude='DerivedData' \
    --exclude='.DS_Store' "$@"
}
# 展示所选包和增量变更，预览时不创建目标包。
preview_changes() {
  highlight_echo "同步方向：$DIRECTION_LABEL"
  log "源目录：$SOURCE_DIR"
  log "目标目录：$TARGET_DIR"
  log "备份根目录：${STATE_DIR}/backups"
  log "所选 Skill 包（${#SELECTED_SKILLS} 个）："
  local name=""
  local target=""
  local preview_target=""
  for name in "${SELECTED_SKILLS[@]}"; do
    target="${TARGET_DIR}/${name}"
    note_echo "${name}"
    [[ -L "${SOURCE_DIR}/${name}" ]] && warn_echo "源包为软链接，将复制解引用实体：${SOURCE_DIR}/${name}"
    if [[ -d "$target" ]]; then
      /usr/bin/find "$target" -type l -print0 > "$SCAN_FILE" 2>>"$LOG_FILE" || fail "无法扫描目标链接：$target"
      if [[ -L "$target" || -s "$SCAN_FILE" ]]; then
        warn_echo '目标含软链接；将备份原链接结构及实体快照，再替换为实体目录。'
      fi
      preview_target="${target}/"
    else
      preview_target="$target"
      info_echo "将新增目标 Skill 包：$target"
    fi
    rsync_source_to --dry-run --itemize-changes "${SOURCE_DIR}/${name}/" "$preview_target" > "$PREVIEW_FILE" 2>&1
    local preview_code=$?
    /bin/cat "$PREVIEW_FILE" | /usr/bin/tee -a "$LOG_FILE"
    (( preview_code == 0 )) || fail "rsync 预览失败，Skill：$name，退出码：$preview_code"
    [[ -s "$PREVIEW_FILE" ]] || gray_echo '同名源文件没有增量变更；已有目标仍会备份并安全切换。'
  done
  note_echo '保留目标独有文件，不使用 --delete；只替换所选包，不同步根目录文件。'
}
# 只在最终 YES 后进入写操作；dry-run 在预览结束即退出。
confirm_sync() {
  if (( DRY_RUN )); then
    success_echo "预览完成；没有备份或复制。日志：$LOG_FILE"
    exit 0
  fi
  warn_echo '即将覆盖所选包中的同名文件，并把其软链接替换为实体；同步前先完整备份全部已有目标包。'
  local answer=""
  IFS= read -r '?👉 输入 YES 开始同步；其它输入取消：' answer || exit 130
  if [[ "$answer" != YES ]]; then
    note_echo '已取消，未备份或复制任何 Skill。'
    exit 0
  fi
}
# 在更新任一包之前，备份所有已有目标的原始链接结构和完整实体快照。
backup_targets() {
  /bin/mkdir -p -- "${STATE_DIR}/backups" || fail "无法创建持久备份目录：$STATE_DIR"
  BACKUP_DIR="$(/usr/bin/mktemp -d "${STATE_DIR}/backups/$(/bin/date '+%Y.%m.%d %H-%M-%S').XXXXXX")" || fail '无法创建唯一时间戳备份。'
  /bin/mkdir -- "${BACKUP_DIR}/original" "${BACKUP_DIR}/resolved" || fail '无法创建备份结构。'
  printf '方向：%s\n源：%s\n目标：%s\n' "$DIRECTION_LABEL" "$SOURCE_DIR" "$TARGET_DIR" > "${BACKUP_DIR}/同步说明.txt" || fail '无法写入备份说明。'
  local name=""
  local target=""
  for name in "${SELECTED_SKILLS[@]}"; do
    target="${TARGET_DIR}/${name}"
    if [[ -e "$target" || -L "$target" ]]; then
      info_echo "完整备份：$name"
      run_logged "$RSYNC_BIN" --archive "$target" "${BACKUP_DIR}/original/" || fail "原始结构备份失败：$target"
      /bin/mkdir -- "${BACKUP_DIR}/resolved/${name}" || fail "无法创建实体备份目录：$name"
      run_logged "$RSYNC_BIN" --archive --copy-links "${target}/" "${BACKUP_DIR}/resolved/${name}/" || fail "实体快照备份失败，目标可能含失效链接：$target"
      printf '已有目标：%s\n' "$name" >> "${BACKUP_DIR}/同步说明.txt" || fail '无法更新备份说明。'
    else
      printf '新增目标：%s\n' "$name" >> "${BACKUP_DIR}/同步说明.txt" || fail '无法更新备份说明。'
    fi
  done
  success_echo "所有已有目标均已备份：$BACKUP_DIR"
}
# 在目标同文件系统合并实体副本，再通过重命名切换，避免写穿任何目标链接。
sync_selected_packages() {
  local name=""
  local staged_package=""
  for name in "${SELECTED_SKILLS[@]}"; do
    STAGING_DIR="$(/usr/bin/mktemp -d "${TARGET_DIR}/.jobs-skills-sync-stage.XXXXXX")" || fail '无法创建目标同文件系统暂存目录。'
    staged_package="${STAGING_DIR}/package"
    /bin/mkdir -- "$staged_package" || fail '无法创建 Skill 实体暂存目录。'
    if [[ -d "${BACKUP_DIR}/resolved/${name}" ]]; then
      run_logged "$RSYNC_BIN" --archive "${BACKUP_DIR}/resolved/${name}/" "${staged_package}/" || fail "目标独有内容复制到暂存目录失败：$name"
    fi
    rsync_source_to "${SOURCE_DIR}/${name}/" "${staged_package}/" 2>&1 | /usr/bin/tee -a "$LOG_FILE"
    local sync_code=${pipestatus[1]}
    (( sync_code == 0 )) || fail "源包合并失败：$name，rsync 退出码：$sync_code"
    ACTIVE_TARGET="${TARGET_DIR}/${name}"
    PREVIOUS_TARGET="${STAGING_DIR}/previous"
    if [[ -e "$ACTIVE_TARGET" || -L "$ACTIVE_TARGET" ]]; then
      /bin/mv -- "$ACTIVE_TARGET" "$PREVIOUS_TARGET" || fail "无法移开原目标：$ACTIVE_TARGET"
    fi
    if ! /bin/mv -- "$staged_package" "$ACTIVE_TARGET"; then
      if [[ -e "$PREVIOUS_TARGET" || -L "$PREVIOUS_TARGET" ]]; then
        /bin/mv -- "$PREVIOUS_TARGET" "$ACTIVE_TARGET" || error_echo "原目标恢复失败，请检查：$PREVIOUS_TARGET"
      fi
      fail "无法切换新 Skill 包：$ACTIVE_TARGET"
    fi
    ACTIVE_TARGET=''
    PREVIOUS_TARGET=''
    if [[ "$STAGING_DIR" == "${TARGET_DIR}/.jobs-skills-sync-stage."* && -d "$STAGING_DIR" && ! -L "$STAGING_DIR" ]]; then
      /bin/rm -r -- "$STAGING_DIR" || fail "同步已完成，但暂存清理失败：$STAGING_DIR"
    else
      fail "暂存目录安全校验失败：$STAGING_DIR"
    fi
    STAGING_DIR=''
    success_echo "已同步：$name"
  done
  success_echo "全部完成，共 ${#SELECTED_SKILLS} 个 Skill 包；日志：$LOG_FILE"
  note_echo "完整备份：$BACKUP_DIR（original 保留原结构，resolved 保留实体快照）"
}
# 编排自述、选择、预览确认和安全同步。
main() {
  show_script_intro_and_wait "$@" # 首先说明用途和影响，回车前不进行写操作。
  initialize_runtime "$@" # 动态解析两端路径并初始化本次日志与取消处理。
  choose_direction # 明确同步方向，默认系统 Skills 同步到当前目录。
  check_environment # 复用健康依赖，仅经明确确认修复缺失的 fzf。
  discover_skill_packages # 按有效 SKILL.md 识别可同步根层 Skill 包。
  choose_skills # 通过 fzf 默认全部同步或用 Tab 多选指定包。
  preflight_targets # 提前拒绝文件冲突和目标内嵌 Git 元数据。
  preview_changes # 展示增量内容、软链接实体化及完整备份位置。
  confirm_sync # dry-run 到此结束，真实同步必须输入 YES。
  backup_targets # 更新之前先完整备份全部已有目标包。
  sync_selected_packages # 在实体暂存目录合并后安全切换所选包。
}

main "$@"
