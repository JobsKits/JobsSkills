---
name: personal-avatar-user
description: 生成数字分身的用户画像（USER.md）。接收用户画像问卷答案和可选简历，生成完整的用户画像文档。
---

# personal-avatar-user

本技能负责生成数字分身的用户画像文档 `boot/USER.md`。

## 输入

调用方（Main 的 UserStage）通过 turn 输入提供用户画像问卷的答案和可选简历，格式如下：

```text
请使用 personal-avatar-user 生成用户画像。

【用户画像问卷】
- 希望我如何称呼你：{callName}
- 工作领域/专业方向：{profession}
- 你处理问题有什么偏好？：{problemPreference}
- 核心兴趣与长期关注的领域：{interests}

【简历】（可选）
{resumeContent}
```

## 执行步骤

1. **解析输入**：从 turn 输入中提取用户画像问卷的 4 个答案和可选简历内容
2. **读取模板**：读取本 skill 的 `template/USER.md` 作为输出骨架。若运行环境给出 `<SKILL_DIR>` 提示，则从 `<SKILL_DIR>/template/USER.md` 读取；否则从 `~/.agents/skills/personal-avatar-user/template/USER.md` 读取
3. **填充占位**：按「占位规则」填充模板占位，生成完整的用户画像文档；不得新增章节，未提供简历时必须删除「简历」节（含 `{resumeFileName}`/`{resume}` 占位）
4. **写入文件**：将生成的内容写入 `boot/USER.md`（使用相对路径）

## 占位规则

- `{name}` **保留**占位符（由 Main 在结算确认时全局替换）
- `{callName}` → turn 输入的希望称呼
- `{profession}` → turn 输入的职业/技术栈/专业方向
- `{problemPreference}` → turn 输入的处理问题偏好
- `{interests}` → turn 输入的兴趣领域
- `{resumeFileName}`/`{resume}` → 简历：提供时提取关键信息总结并记录来源文件名；未提供时删除「简历」节，禁止保留 `{resumeFileName}`/`{resume}` 占位、不臆造内容，不阻断
- 除 `{name}` 外，turn 未提供的可选信息（如简历）不得写入占位符：删除对应小节或写显式空状态，不臆造内容

## 约束

- 使用相对路径写文件（`boot/USER.md`），不要用绝对路径
- 不创建/不修改 `avatar.json`
- 内容使用简体中文
- 写文件时行首不要加前导空格；标题必须恰好是 `# USER`
- USER.md 中不写占位符机制说明：只保留占位符本身，不要写入"由 Main patch""由 skill 填充"等元说明注释
