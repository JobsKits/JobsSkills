---
name: personal-avatar-summary
description: 生成数字分身的摘要（SUMMARY.md）。读取所有已生成的文档，生成综合摘要。
---

# personal-avatar-summary

本技能负责生成数字分身的摘要文档 `boot/SUMMARY.md`。

## 输入

调用方（Main 的 SummaryStage）会确保以下文件已生成：
- `boot/SOUL.md` - 人格设定
- `boot/USER.md` - 用户画像
- `boot/BEHAVIOR.md` - 工作风格
- `boot/memory/MEMORY.md` - 长期记忆（如果用户选择了记忆应用）

## 执行步骤

1. **读取文档**：读取所有已生成的文档内容
2. **生成摘要**：综合所有文档内容，生成简洁的摘要
3. **写入文件**：将生成的内容写入 `boot/SUMMARY.md`（使用相对路径）

## 输出格式

生成的 `boot/SUMMARY.md` 应包含以下章节。**标题行与正文章节行首不得有缩进空格**。

```markdown
# SUMMARY

## 人格设定
{从 SOUL.md 提取的核心人格特征，1～2 句}

## 用户画像
{从 USER.md 提取的用户关键信息，1～2 句}

## 工作风格
{从 BEHAVIOR.md 提取的工作风格说明，1～2 句}

## 长期记忆
{从 MEMORY.md 提取的记忆概要，如果没有则说明"未配置记忆"}

## 整体描述
{一段约 80～100 字的纯中文，无标题、无列表、无 markdown 符号；供结算页与 TwinInfo 展示}
```

## 约束

- 使用相对路径写文件（`boot/SUMMARY.md`），不要用绝对路径
- 不创建/不修改 `avatar.json`
- 内容使用简体中文
- 前面各章节要简洁，每个章节不超过 2 句话
- 如果某个文档不存在，在对应章节说明"未生成"
- 写文件时行首不要加前导空格；标题必须恰好是 `# SUMMARY`
- **必须**包含 `## 整体描述` 章节（Main 会提取该段写入 `avatar.json.summary`）
- **整体描述必须是一段纯文本**：约 80～100 字；禁止再写 `##`/`#`、禁止分点列表；不要写分身名字或 `{name}`（名字在摘要之后由用户填写）
