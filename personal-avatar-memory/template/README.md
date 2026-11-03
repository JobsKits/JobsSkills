# memory/ — L1 临时记忆与收割日志

> 本目录存放 L1 临时记忆与经验收割日志，按日期分文件（`YYYY-MM-DD.md`）。
> 与 `../MEMORY.md`（L2 长期记忆）的区别：L1 是原始/未确认候选的暂存区，L2 是已确认提升的长期记忆。

## 检索规则

1. **按日期倒序**：最新日志在最前。需要追溯近期会话时从最新文件读起。
2. **不自动提升**：本目录内容未经用户确认，不得直接写入 `USER.md`/`MEMORY.md` 正式文件。
3. **待确认标注**：未确认候选标"待确认"，确认后由用户或经 skill 融合提升至 L2。
4. **来源必带**：每条候选记忆带 `source(file)` + `confidence`，便于核验。

## 文件命名

- `YYYY-MM-DD.md`：当日收割日志，含来源清单 + 原始候选摘要。
- 同一天多次收割追加到同一文件，不覆盖。

## 冲突优先级

用户显式事实 > 行为观察；当前任务指令 > 历史偏好；未经确认的推断不得覆盖正式文件（对齐参考文档 §1.2）。

## 示例条目格式

```markdown
## 2026-07-25 收割日志

### 来源
- `~/.claude/CLAUDE.md`（confidence: high）
- `~/.codex/config.toml`（confidence: medium）

### 候选

- [待确认] 用户偏好中文输出 — source: ~/.claude/CLAUDE.md
- [待确认] 提交格式 `<commit>:<taskId>_<name>：<desc>` — source: ~/.claude/CLAUDE.md
```
