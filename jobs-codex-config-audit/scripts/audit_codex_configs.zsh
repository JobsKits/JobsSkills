#!/bin/zsh
# ==============================================================================
# audit_codex_configs.zsh
# 用途：只读审计 Jobs Codex 全局指导、JobsSkills 现行工作树和父仓子模块关系。
# 边界：不修改、不部署、不删除任何文件；所有候选项交给人工判断。
# ==============================================================================

set -u
setopt NO_NOMATCH

SCRIPT_PATH="${0:A}"
SCRIPT_DIR="${SCRIPT_PATH:h}"
DEFAULT_CONFIG_ROOT="/Users/jobs/Documents/Github/JobsGenesis/JobsConfigOS/💻JobsCodexConfigs"
CONFIG_ROOT="${1:-${DEFAULT_CONFIG_ROOT}}"
SKILLS_SOURCE="${2:-${HOME}/.agents/skills}"
AGENTS_SOURCE="${CONFIG_ROOT}/AGENTS.md"
SKILLS_SUBMODULE="${CONFIG_ROOT}/skills"
RUNTIME_AGENTS="${HOME}/.codex/AGENTS.md"
JOBS_SKILLS_REPOSITORY="https://github.com/JobsKits/JobsSkills.git"

typeset -i WARNING_COUNT=0
typeset -i ERROR_COUNT=0

# 输出统一章节标题，便于自动任务摘要和人工扫读。
section() {
  print
  print -r -- "## $*"
}

# 记录不阻断审计的规范问题。
warn() {
  print -r -- "⚠️  $*"
  (( WARNING_COUNT += 1 ))
}

# 记录无法继续完整审计的结构错误。
error() {
  print -r -- "❌ $*"
  (( ERROR_COUNT += 1 ))
}

# 判断 Git 远端是否指向 JobsSkills，兼容 SSH 和 HTTPS 写法。
is_jobs_skills_remote() {
  local remote_url="$1"
  case "$remote_url" in
    "https://github.com/JobsKits/JobsSkills"|\
    "https://github.com/JobsKits/JobsSkills.git"|\
    "git@github.com:JobsKits/JobsSkills.git")
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# 只输出 Jobs 本人维护或已明确接管的 Skill，第三方实体目录和软链接仅做清单核对。
print_managed_skill_files() {
  find "$SKILLS_SOURCE" -mindepth 2 -maxdepth 2 -type f -name SKILL.md \
    \( -path "${SKILLS_SOURCE}/jobs-*/SKILL.md" -o -path "${SKILLS_SOURCE}/hacker/SKILL.md" \) -print0
}

# 验证两个标准源，避免把父仓中的子模块挂载误当成 Skills 最大集。
validate_source_layout() {
  section "标准源"
  print -r -- "全局指导源：${AGENTS_SOURCE}"
  print -r -- "Skills 现行基准：${SKILLS_SOURCE}"
  print -r -- "JobsSkills 远端：${JOBS_SKILLS_REPOSITORY}"
  [[ -f "$AGENTS_SOURCE" ]] || error "缺少 AGENTS.md"
  [[ -d "$SKILLS_SOURCE" ]] || error "缺少 Skills 现行工作树"
  if [[ -d "$SKILLS_SOURCE" ]]; then
    git -C "$SKILLS_SOURCE" rev-parse --is-inside-work-tree >/dev/null 2>&1 || error "Skills 现行工作树不是 Git 仓库"
    local remote_url="$(git -C "$SKILLS_SOURCE" remote get-url origin 2>/dev/null || true)"
    is_jobs_skills_remote "$remote_url" || error "Skills 现行工作树 origin 不是 JobsSkills：${remote_url:-未配置}"
    find -L "$SKILLS_SOURCE" -mindepth 2 -maxdepth 2 -name SKILL.md -print -quit | rg -q . || error "Skills 现行工作树中没有可审计的 SKILL.md"
  fi
  if (( ERROR_COUNT > 0 )); then
    print -r -- "审计无法继续。"
    exit 2
  fi
}

# 汇总 Markdown 数量和行数，只用于发现异常膨胀，不按行数自动删规则。
print_inventory() {
  section "规模"
  local skill_file_count="$(find -L "$SKILLS_SOURCE" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
  local managed_file_count="$(print_managed_skill_files | tr '\0' '\n' | wc -l | tr -d ' ')"
  local skill_line_count="$(find -L "$SKILLS_SOURCE" -mindepth 2 -maxdepth 2 -name SKILL.md -print0 | xargs -0 wc -l | tail -n 1 | awk '{print $1}')"
  local agents_line_count="$(wc -l < "$AGENTS_SOURCE" | tr -d ' ')"
  local file_count="$(( skill_file_count + 1 ))"
  local line_count="$(( skill_line_count + agents_line_count ))"
  print -r -- "指导文件数：${file_count}"
  print -r -- "其中 Jobs 维护的 Skill：${managed_file_count}"
  print -r -- "总行数：${line_count}"
  find -L "$SKILLS_SOURCE" -mindepth 2 -maxdepth 2 -name SKILL.md -print0 | xargs -0 wc -l | sort -nr | head -n 8
}

# 检查 Skill 独立文档结构，避免审计后丢失 YAML、封面、目录或底部锚点。
audit_skill_structure() {
  section "Skill 文档结构"
  local file=""
  while IFS= read -r -d '' file; do
    [[ "$(head -n 1 "$file")" == "---" ]] || warn "front matter 不在第一行：${file}"
    rg -q '^name: ' "$file" || warn "缺少 name：${file}"
    rg -q '^description: ' "$file" || warn "缺少 description：${file}"
    rg -q '^# ' "$file" || warn "缺少一级标题：${file}"
    rg -q 'picsum\.photos/1500/400' "$file" || warn "缺少 2D 封面：${file}"
    rg -q '^\[toc\]$' "$file" || warn "缺少 [toc]：${file}"
    rg -q '我是有底线的' "$file" || warn "缺少底部锚点：${file}"
  done < <(print_managed_skill_files)
  print -r -- "结构扫描完成。"
}

# 忽略 fenced code block，定位中文说明里仍使用英文句点的数字序号。
audit_chinese_numbering() {
  section "中文数字序号"
  local findings=""
  findings="$(
    awk '
      /^```/ { fenced = !fenced; next }
      !fenced && /^[[:space:]]*[0-9]+\.[[:space:]]/ { print FILENAME ":" FNR ":" $0 }
    ' "$AGENTS_SOURCE"
    print_managed_skill_files | while IFS= read -r -d '' file; do
      awk '
        /^```/ { fenced = !fenced; next }
        !fenced && /^[[:space:]]*[0-9]+\.[[:space:]]/ { print FILENAME ":" FNR ":" $0 }
      ' "$file"
    done
  )"
  if [[ -n "$findings" ]]; then
    print -r -- "$findings"
    warn "发现中文说明使用 1. 样式；应改为 1、，代码和英文原文除外。"
  else
    print -r -- "✅ 未发现代码块外的 1. 数字列表。"
  fi
}

# 固定检查关键名词表项，防止整理时删掉 Jobs 的首次出现超链接习惯。
audit_fixed_term_links() {
  section "专有名词固定链接"
  local markdown_skill="${SKILLS_SOURCE}/jobs-markdown-docs/SKILL.md"
  local required=(
    '[**Swift**](https://www.swift.org/)'
    '[**Codex**](https://openai.com/codex)'
    '[**Understand Anything**](https://github.com/Lum1104/Understand-Anything)'
    '[**Markdown**](https://markdown.cn)'
    '[**Xcode**](https://developer.apple.com/xcode)'
  )
  local term=""
  for term in "${required[@]}"; do
    if rg -Fq "$term" "$markdown_skill"; then
      print -r -- "✅ ${term}"
    else
      warn "固定名词表项缺失：${term}"
    fi
  done
}

# 输出跨文件完全相同的较长规则行，作为人工语义审计候选而非自动删除依据。
audit_exact_duplicate_candidates() {
  section "完全重复候选"
  local temp_file="$(mktemp "${TMPDIR%/}/jobs-codex-duplicates.XXXXXX")"
  {
    awk '/^```/ { fenced = !fenced; next } !fenced && length($0) >= 36 && $0 ~ /^-/ { print $0 }' "$AGENTS_SOURCE"
    print_managed_skill_files | while IFS= read -r -d '' file; do
      awk '/^```/ { fenced = !fenced; next } !fenced && length($0) >= 36 && $0 ~ /^-/ { print $0 }' "$file"
    done
  } | sort | uniq -c | awk '$1 > 1' | sort -nr >| "$temp_file"
  if [[ -s "$temp_file" ]]; then
    head -n 30 "$temp_file"
    print -r -- "以上仅为候选；删除前必须检查触发范围、例外和验证是否等价。"
  else
    print -r -- "✅ 未发现跨文件完全相同的长规则行。"
  fi
  rm -f -- "$temp_file"
}

# 核对 AGENTS 部署状态、JobsSkills 工作树与父仓子模块指针，不执行同步。
audit_repository_relationships() {
  section "仓库与运行态关系"
  if [[ -f "$RUNTIME_AGENTS" ]] && cmp -s "$AGENTS_SOURCE" "$RUNTIME_AGENTS"; then
    print -r -- "✅ AGENTS.md 一致。"
  elif [[ -f "$RUNTIME_AGENTS" ]]; then
    local source_agents="$(<"$AGENTS_SOURCE")"
    local normalized_runtime_agents="$(sed '/<!-- CODEGRAPH_START -->/,/<!-- CODEGRAPH_END -->/d' "$RUNTIME_AGENTS")"
    if [[ "$source_agents" == "$normalized_runtime_agents" ]]; then
      print -r -- "✅ AGENTS.md 源内容一致；运行态仅额外保留 CodeGraph 托管块。"
    else
      warn "AGENTS.md 与运行态不一致。"
    fi
  else
    warn "AGENTS.md 运行态缺失。"
  fi

  local current_head="$(git -C "$SKILLS_SOURCE" rev-parse HEAD 2>/dev/null || true)"
  local current_status="$(git -C "$SKILLS_SOURCE" status --short 2>/dev/null || true)"
  print -r -- "JobsSkills 现行 HEAD：${current_head:-无法读取}"
  if [[ -n "$current_status" ]]; then
    warn "JobsSkills 现行工作树存在未提交改动；这些内容属于最大集，不得被子模块反向覆盖。"
    print -r -- "$current_status"
  else
    print -r -- "✅ JobsSkills 现行工作树干净。"
  fi

  local gitlink_entry="$(git -C "$CONFIG_ROOT" ls-files -s -- skills 2>/dev/null || true)"
  if [[ "$gitlink_entry" != 160000\ * ]]; then
    warn "父仓尚未以 gitlink 跟踪 skills。"
  else
    print -r -- "✅ 父仓已以 gitlink 跟踪 skills。"
  fi

  if [[ ! -e "${SKILLS_SUBMODULE}/.git" ]]; then
    warn "JobsSkills 子模块尚未检出：${SKILLS_SUBMODULE}"
    return
  fi

  local submodule_remote="$(git -C "$SKILLS_SUBMODULE" remote get-url origin 2>/dev/null || true)"
  local submodule_head="$(git -C "$SKILLS_SUBMODULE" rev-parse HEAD 2>/dev/null || true)"
  is_jobs_skills_remote "$submodule_remote" || warn "子模块 origin 不是 JobsSkills：${submodule_remote:-未配置}"
  print -r -- "父仓子模块 HEAD：${submodule_head:-无法读取}"
  if [[ -n "$current_head" && -n "$submodule_head" && "$current_head" != "$submodule_head" ]]; then
    warn "父仓子模块指针与 JobsSkills 现行 HEAD 不一致；应由现行工作树提交推送后再更新子模块指针。"
  else
    print -r -- "✅ 父仓子模块与 JobsSkills 现行 HEAD 一致。"
  fi
}

# 统一执行只读检查并用非零退出码只表达结构错误，不让普通候选中断每周任务。
main() {
  validate_source_layout # 校验 AGENTS 源与 JobsSkills 现行最大集
  print_inventory # 汇总现行指导文件规模
  audit_skill_structure # 检查每个现行 Skill 的文档骨架
  audit_chinese_numbering # 检查中文数字序号格式
  audit_fixed_term_links # 检查固定专有名词链接
  audit_exact_duplicate_candidates # 输出重复规则候选
  audit_repository_relationships # 核对运行态和子模块关系
  section "结论"
  print -r -- "警告：${WARNING_COUNT}；错误：${ERROR_COUNT}"
  print -r -- "本脚本未修改、部署或删除任何文件。"
  (( ERROR_COUNT == 0 )) || exit 2
}

main "$@"
