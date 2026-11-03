---
name: personal-avatar-memory
description: 生成数字分身的长期记忆（MEMORY.md）。根据用户选择的应用收割记忆内容。
---

# personal-avatar-memory

本技能负责生成数字分身的长期记忆文档 `boot/memory/MEMORY.md` 与 L1 索引 `boot/memory/README.md`。

## 输入

调用方（Main 的 MemoryStage）通过 turn 输入提供用户选择的应用列表，格式如下：

```text
请使用 personal-avatar-memory 生成长期记忆。

【记忆应用】
用户选择的应用：{appList}
```

若 turn 输入附带收割探测段（每应用 found/目录），用于填充「勾选记忆应用」节。

## 执行步骤

1. **解析输入**：从 turn 输入中提取用户选择的应用列表与收割探测信息
2. **建目录**：`mkdir -p boot/memory`（相对路径）
3. **拷贝 L1 索引**：将本 skill 的 `template/README.md` 原样拷贝到 `boot/memory/README.md`。若运行环境给出 `<SKILL_DIR>` 提示，则从 `<SKILL_DIR>/template/README.md` 读取；否则从 `~/.agents/skills/personal-avatar-memory/template/README.md` 读取
4. **读取模板**：读取 `template/MEMORY.md` 作为输出骨架
5. **填充占位**：
   - 勾选记忆应用节：替换 HTML 注释占位，每应用一行，格式 `- **{app}**：found={true|false}，目录={dir}`（仅列出用户勾选且在 turn 输入中出现的应用；未提供 found/目录时只列应用名）
   - `{harvestContent}` → 收割内容：有收割内容时每应用总结不超过 5 条长期记忆写入；否则保留空状态声明
6. **写入文件**：将生成的内容写入 `boot/memory/MEMORY.md`（相对路径）

## 约束

- 使用相对路径写文件，不要用绝对路径
- 不创建/不修改 `avatar.json`
- 内容使用简体中文
- 写文件时行首不要加前导空格；标题必须恰好是 `# MEMORY`
- 每个应用的记忆条目不超过 5 条
- 如果某个应用无法读取，在文档中说明原因

## TODO

当前为占位实现，后续需要实现：
- 读取 Claude 的 CLAUDE.md 和 settings.json
- 读取 Codex 的 memories_1.sqlite
- 读取其他应用的记忆数据
