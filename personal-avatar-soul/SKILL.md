---
name: personal-avatar-soul
description: 生成数字分身的人格设定（SOUL.md）。接收人格问卷答案，生成完整的人格设定文档。
---

# personal-avatar-soul

本技能负责生成数字分身的人格设定文档 `boot/SOUL.md`。

## 输入

调用方（Main 的 SoulStage）通过 turn 输入提供人格问卷的答案，格式如下：

```text
请使用 personal-avatar-soul 生成人格设定。

【人格问卷】
- 职业/角色：{identityTags}
- 语言习惯：{languageHabit}
- 情绪基调：{emotionTone}
- 反馈方式：{feedbackStyle}
- 偏好语言：{language}
```

## 执行步骤

1. **解析输入**：从 turn 输入中提取人格问卷的 5 个答案
2. **读取模板**：读取本 skill 的 `template/SOUL.md` 作为输出骨架。若运行环境给出 `<SKILL_DIR>` 提示，则从 `<SKILL_DIR>/template/SOUL.md` 读取；否则从 `~/.agents/skills/personal-avatar-soul/template/SOUL.md` 读取
3. **填充占位**：按「占位规则」填充模板占位，生成完整的人格设定文档；不得自行增删章节
4. **写入文件**：将生成的内容写入 `boot/SOUL.md`（使用相对路径）

## 占位规则

- `{name}` **保留**占位符（由 Main 在结算确认时全局替换）
- `{description}` → 分身简介（LLM 据人格 5 问 + 用户画像自动生成）
- `{identityTags}`/`{languageHabit}`/`{emotionTone}`/`{feedbackStyle}`/`{language}` → turn 输入的人格 5 问
- turn 输入未提供者保留占位字面量，不臆造

## 约束

- 使用相对路径写文件（`boot/SOUL.md`），不要用绝对路径
- 不创建/不修改 `avatar.json`
- 不生成工作风格（BEHAVIOR.md 由 Main 的 BehaviorStage 负责）
- 内容使用简体中文
- 写文件时行首不要加前导空格；标题必须恰好是 `# SOUL`
- SOUL.md 中不写占位符机制说明：只保留占位符本身，不要写入"由 Main patch""由 skill 填充"等元说明注释
