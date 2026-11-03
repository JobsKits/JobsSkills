---
name: jobs-obsidian-memory
description: 当 Codex 需要在任何任务开始前读取跨项目永久记忆，或在任务中新增、更新、去重、归档长期规划、稳定偏好、工作流决策、项目约束和每日复盘时使用；也用于维护 Obsidian Vault、处理记忆冲突或执行每日凌晨记忆同步。
---

# Jobs Obsidian 永久记忆规范

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#jobs-toc-heading-1)
- [一、固定路径](#jobs-toc-heading-2)
- [二、任务前读取](#jobs-toc-heading-3)
- [三、写入边界](#jobs-toc-heading-4)
- [四、写入方法](#jobs-toc-heading-5)
- [五、每日复盘](#jobs-toc-heading-6)
- [六、验证](#jobs-toc-heading-7)

</details>
<!-- jobs-toc:end -->

---

## <span id="jobs-toc-heading-1" data-jobs-toc="v2">🔥 <font id=前言>前言</font></span><!-- jobs-toc:heading-end -->

> 把 [**Obsidian**](https://obsidian.md) Vault 作为 Codex 跨项目永久记忆的人类可读源。任务前按索引读取，任务中只沉淀经用户确认且能复用的长期信息。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、固定路径 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 记忆仓库根目录：`/Users/jobs/Documents/Github/JobsGenesis/JobsConfigOS/📒CodexByObsidian`。
- Vault 根目录：`/Users/jobs/Documents/Github/JobsGenesis/JobsConfigOS/📒CodexByObsidian/JobsCodexMemory`。
- 任务前必读入口：`00-记忆入口.md`。
- 稳定偏好：`10-用户画像/长期偏好.md`。
- 长期规划：`20-长期规划/长期规划.md`。
- 工作流决策：`30-工作流决策/工作流决策.md`。
- 项目约束：`40-项目记忆/`。
- 待分类记忆：`60-收集箱/记忆收集箱.md`。
- 协议与同步游标：`90-系统/记忆协议.md`、`90-系统/同步状态.md`。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、任务前读取 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

1、先用 `rg --files` 或等价方式扫描 Vault 目录结构，确认入口和项目笔记仍存在。

2、完整读取 `00-记忆入口.md`、`长期偏好.md`和 `工作流决策.md`中与当前任务相关的段落。

3、根据当前仓库路径、项目名、模块名和任务关键词，只继续读取 `40-项目记忆/`下命中的笔记。

4、读取失败时不得静默忽略；先检查路径，再向用户简要说明未能应用哪部分永久记忆。

5、不要每次全量读取整个 Vault；目录扫描是全量的，正文读取必须按索引和任务命中，避免无关记忆污染上下文。

## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、写入边界 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 只写入这些可复用信息：

  - 用户明确的长期目标或跨任务规划。
  - 用户稳定的沟通、代码、文档、验证或交付偏好。
  - 已确认的工作流决策、目录边界、同步方向和风险约束。
  - 可能影响后续任务的项目架构事实、模块映射或验证基线。

- 不写入临时闲聊、一次性输出、可随时重新检索的普通事实、未验证推断、密码、Token、私钥、Cookie 或其它敏感数据。
- 只有当用户明确要求“记住”或信息显然具有跨任务价值时才落库；不得把猜测写成用户偏好。
- 任务结束前检查是否产生新的持久记忆；有则去重后写入，无则不制造空记录。

## <span id="jobs-toc-heading-5" data-jobs-toc="v2">四、写入方法 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

1、先搜索同类项，优先更新原记忆，不要叠加语义相同的条目。

2、按“用户偏好 / 长期规划 / 工作流决策 / 项目记忆”路由；尚不能安全归类时写入收集箱，等复盘后再移动。

3、保留来源、确认状态、适用范围、创建时间和更新时间；项目记忆记录仓库绝对路径。

4、新决策与旧决策冲突时，不要无声覆盖；把旧项标为 `superseded`，并链接到新项。

5、写入后更新 `00-记忆入口.md`的导航或摘要，再检查 [**Obsidian**](https://obsidian.md) Wiki 链接目标存在。

## <span id="jobs-toc-heading-6" data-jobs-toc="v2">五、每日复盘 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 每天凌晨 1 点运行时，完整读取 `90-系统/记忆协议.md`和 `90-系统/同步状态.md`。
- 从上次游标开始检查最近 Codex 任务和 `~/.codex/memories`中的新增线索，仅提取经确认的持久信息。
- 去重、分类、更新索引，然后追加 `50-每日复盘/YYYY/YYYY-MM-DD.md`。
- 即使无新增记忆，也记录“无新增”和检查范围，再更新同步游标。
- 自动化失败时保留原游标，不得把未完成的复盘标成成功。

## <span id="jobs-toc-heading-7" data-jobs-toc="v2">六、验证 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 检查 Markdown 头部、属性、路径和 Wiki 链接。
- 检查新写入内容没有敏感信息、未证实推断和重复项。
- 最终回复只说明读取了哪类记忆、新增或更新了什么、是否验证；不回显敏感正文。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➔点我回到首页</a>
