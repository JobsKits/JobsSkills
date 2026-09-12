#!/bin/zsh
# ==============================================================================
# audit_codex_configs.zsh
# 用途：只读审计 Jobs Codex 配置源的结构、序号、固定链接和运行态差异。
# 边界：不修改、不部署、不删除任何文件；所有候选项交给人工判断。
# ==============================================================================

set -u
setopt NO_NOMATCH

SCRIPT_PATH="${0:A}"
SCRIPT_DIR="${SCRIPT_PATH:h}"
DEFAULT_SOURCE_ROOT="/Users/jobs/Documents/Github/JobsGenesis/JobsConfigOS/💻JobsCodexConfigs"
SOURCE_ROOT="${1:-${DEFAULT_SOURCE_ROOT}}"
AGENTS_SOURCE="${SOURCE_ROOT}/AGENTS.md"
SKILLS_SOURCE="${SOURCE_ROOT}/skills"
RUNTIME_AGENTS="${HOME}/.codex/AGENTS.md"
RUNTIME_SKILLS="${HOME}/.agents/skills"

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

# 验证标准源目录，避免误把运行态或其它仓库当作编辑源。
validate_source_layout() {
  section "标准源"
  print -r -- "配置源：${SOURCE_ROOT}"
  [[ -f "$AGENTS_SOURCE" ]] || error "缺少 AGENTS.md"
  [[ -d "$SKILLS_SOURCE" ]] || error "缺少 skills/"
  if (( ERROR_COUNT > 0 )); then
    print -r -- "审计无法继续。"
    exit 2
  fi
}

# 汇总 Markdown 数量和行数，只用于发现异常膨胀，不按行数自动删规则。
print_inventory() {
  section "规模"
  local file_count="$(find "$SOURCE_ROOT" -type f \( -name 'AGENTS.md' -o -name 'SKILL.md' \) | wc -l | tr -d ' ')"
  local line_count="$(find "$SOURCE_ROOT" -type f \( -name 'AGENTS.md' -o -name 'SKILL.md' \) -print0 | xargs -0 wc -l | tail -n 1 | awk '{print $1}')"
  print -r -- "指导文件数：${file_count}"
  print -r -- "总行数：${line_count}"
  find "$SKILLS_SOURCE" -mindepth 2 -maxdepth 2 -name SKILL.md -print0 | xargs -0 wc -l | sort -nr | head -n 8
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
  done < <(find "$SKILLS_SOURCE" -mindepth 2 -maxdepth 2 -name SKILL.md -print0)
  print -r -- "结构扫描完成。"
}

# 忽略 fenced code block，定位中文说明里仍使用英文句点的数字序号。
audit_chinese_numbering() {
  section "中文数字序号"
  local findings=""
  findings="$(find "$SOURCE_ROOT" -type f \( -name 'AGENTS.md' -o -name 'SKILL.md' \) -print0 | xargs -0 awk '
    /^```/ { fenced = !fenced; next }
    !fenced && /^[[:space:]]*[0-9]+\.[[:space:]]/ { print FILENAME ":" FNR ":" $0 }
  ')"
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
  find "$SOURCE_ROOT" -type f \( -name 'AGENTS.md' -o -name 'SKILL.md' \) -print0 | while IFS= read -r -d '' file; do
    awk '/^```/ { fenced = !fenced; next } !fenced && length($0) >= 36 && $0 ~ /^-/ { print $0 }' "$file"
  done | sort | uniq -c | awk '$1 > 1' | sort -nr >| "$temp_file"
  if [[ -s "$temp_file" ]]; then
    head -n 30 "$temp_file"
    print -r -- "以上仅为候选；删除前必须检查触发范围、例外和验证是否等价。"
  else
    print -r -- "✅ 未发现跨文件完全相同的长规则行。"
  fi
  rm -f -- "$temp_file"
}

# 逐个比较 Jobs 自有同名 Skill，既不把第三方 Skill 当冗余，也不执行删除。
audit_runtime_sync() {
  section "标准源到运行态"
  if [[ -f "$RUNTIME_AGENTS" ]] && cmp -s "$AGENTS_SOURCE" "$RUNTIME_AGENTS"; then
    print -r -- "✅ AGENTS.md 一致。"
  else
    warn "AGENTS.md 与运行态不一致或运行态缺失。"
  fi
  local source_skill=""
  local source_dir=""
  local skill_name=""
  local runtime_skill=""
  while IFS= read -r -d '' source_skill; do
    source_dir="${source_skill:h}"
    skill_name="${source_dir:t}"
    runtime_skill="${RUNTIME_SKILLS}/${skill_name}"
    if [[ ! -d "$runtime_skill" ]]; then
      warn "运行态缺少 Skill：${skill_name}"
    elif ! diff -qr "$source_dir" "$runtime_skill" >/dev/null 2>&1; then
      warn "Skill 与运行态不一致：${skill_name}"
    fi
  done < <(find "$SKILLS_SOURCE" -mindepth 2 -maxdepth 2 -name SKILL.md -print0)
}

# 统一执行只读检查并用非零退出码只表达结构错误，不让普通候选中断每周任务。
main() {
  validate_source_layout
  print_inventory
  audit_skill_structure
  audit_chinese_numbering
  audit_fixed_term_links
  audit_exact_duplicate_candidates
  audit_runtime_sync
  section "结论"
  print -r -- "警告：${WARNING_COUNT}；错误：${ERROR_COUNT}"
  print -r -- "本脚本未修改、部署或删除任何文件。"
  (( ERROR_COUNT == 0 )) || exit 2
}

main "$@"
