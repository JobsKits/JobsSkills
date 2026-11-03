# Jobs [**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) 双工程与 [**Gitee**](https://gitee.com) 快照路径约定

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#%E5%89%8D%E8%A8%80)
- [一、双工作目录与独立快照例外](#oc-main-bypods-snapshot)
- [二、只读核验与规则维护边界](#jobs-toc-heading-3)

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

> 本文件是[仓库 Skill](./SKILL.md) 的同级路径附件，只在处理 OC 新旧工程的本地目录、分支映射、快照同步及相关规则时加载；不单独注册为 Skill。

## 一、<span id="oc-main-bypods-snapshot">双工作目录与独立快照例外</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- OC 新旧工程由两个磁盘目录中的独立本地 [**Git**](https://git-scm.com/) 仓库管理，两处各自拥有独立 Git 元数据，同一托管平台上共用远端仓库地址，以分支区分工程形态。用户于 2026-10-16 再次确认下列职责映射，不能套用通用的 Gitee 远端目标统一为 `gitee` 的命名规则。

  | 本地工作目录 | 日常工作分支 | [**GitHub**](https://github.com) 远端分支 | Gitee 远端分支 |
  | --- | --- | --- | --- |
  | `/Users/jobs/Documents/Github/JobsBaseConfig/JobsBaseConfig@JobsOCBaseConfigDemo`，功能集成主工程 | `main` | `main` | `main` |
  | `/Users/jobs/Documents/Github/JobsOCBaseConfigDemo@ByPods`，功能下沉本地 Pod | `byPods` | `byPods` | `byPods`，发布源为现有本地 `Gitee@snapshot` |

- `Gitee@snapshot` 的原因是当时 Gitee 旧历史与仓库容量问题，已有报告记录服务端 `Repo size ... exceeds quota` 拒绝。用户选择 GitHub 保留完整历史，Gitee 从当前已提交文件树建立独立零点，该分支专门承载已授权的独立发布链。证据位于新工程 `ScriptsByDevTools/gitee_snapshot.command/README.md` 的容量问题及零点快照说明，不把历史故障扩写为未经核验的当前平台限额。
- 专用同步复用 `byPods` 已提交文件树：首次快照没有父提交，后续只延续快照父链，树未变化时复用现有快照提交。两边追求文件树一致，提交号和历史可以不同；禁止将完整 `byPods` 历史、其它分支或标签混入 Gitee 的快照发布链，也不为追求相同 HEAD 而合并两条历史。
- 开发、提交和拉取 GitHub 始终使用 `byPods`；推送映射固定为 `byPods → origin/byPods`、`Gitee@snapshot → gitee/byPods`。快照只供专用同步及发布，不用切换到该分支开发，不发布到 GitHub，也不在远端创建同名 `Gitee@snapshot`。现有专用 hook 和推送映射必须保留，不运行通用逐层双远端整合去绕过它们。
- 本地分支职责限定为：旧工程工作分支 `main`，新工程工作分支 `byPods` 加已有发布分支 `Gitee@snapshot`。后者是仅属于新工程的明确例外，不推广到其它仓库；不得自动为两处补建对方的工作分支或再建立 `gitee`、同步、备份、救援分支。远端跟踪引用不计为本地工作分支。
- 保留 `Gitee@snapshot` 的大小写和 `@`；它由既有快照链改名而来。旧名称 `codex/gitee-snapshot`、`gitee-snapshot` 已淘汰，安装或同步时先识别并复用现有分支标记、有效配置和快照根标记，多候选或映射不明确时停止，不能因旧配置重建旧名称或生成第二条快照链。
- 对其它已有本地分支先核验用途和独有提交并报告；新增、删除、改名或重写历史须有用户明确授权。远端地址由两处共用，清空仓库或删除远端 `main` / `byPods` 会影响另一工程，不能从本地分支整理推导远端清理授权。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、只读核验与规则维护边界 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 上表定义分支职责，不证明两平台当前都已同步。先只读核对两处 Git 身份、当前分支、upstream、push refspec、快照开关及目标；只读梳理时按需使用 `ls-remote` 确认服务端，不运行安装器、同步脚本、hook、fetch 或 push，也不自动补建缺失远端分支。仅要求提炼原因或写入规则时，只修改规则文档。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
