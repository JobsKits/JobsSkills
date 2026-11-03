# Jobs [**Sourcetree**](https://www.sourcetreeapp.com/) 逐层推送路径约定

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#%E5%89%8D%E8%A8%80)
- [一、单本地工作分支与双平台同步](#jobs-toc-heading-2)
- [二、隔离验证](#jobs-toc-heading-3)

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

> 本文件是[仓库 Skill](./SKILL.md) 的同级路径附件，只在维护、排障或运行 `【MacOS@SourceTree】🚀逐层空白提交并Push.command` 时加载；不单独注册为 Skill。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、单本地工作分支与双平台同步 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- `【MacOS@SourceTree】🚀逐层空白提交并Push.command` 的常用场景是“大 [**Git**](https://git-scm.com/) 套小 Git”：每个父仓、子仓各自维护一份代码和一个已有本地工作分支，同步到 [**GitHub**](https://github.com) 与 [**Gitee**](https://gitee.com) 各自的主分支。维护、排障和运行此脚本都必须遵守本节。
- 保持原有本地工作分支，不因托管平台不同而额外创建本地 `gitee`、镜像、同步、备份、救援或临时分支；不能通过 `branch`、`checkout -b`、`switch -c/-C`、`update-ref refs/heads/...` 等路径绕过。游离 HEAD 只允许恢复到明确的已有本地分支；分支不存在或目标不明确时，在清理和提交前停止。
- 两个平台的远端主分支名称可以不同，按各仓已确认的配置分别映射；例如同一个本地 `main` 可同步 GitHub 的 `main` 与 Gitee 的 `gitee`。远端别名、远端跟踪引用和本地分支是不同概念；配置 `gitee` remote 或获取 `refs/remotes/gitee/...` 不要求建立本地 `gitee` 分支。
- 先获取并整合全部已配置目标线路的历史，再用同一最终 `HEAD` 分别显式推送到 `refs/heads/<该平台主分支>`，逐条核验提交号一致；只有单条已配置线路的子仓继续按单线处理，不自动创建远端仓库。禁止将额外本地分支带到远端，禁止 `push --all`、`push --mirror` 或通配推送 `refs/heads/*`。无法确定映射、整合冲突或推送失败时停止，不创建替代分支、不强推。
- 已存在的额外本地或远端分支不属于本规则的自动清理授权；保留并报告，不擅自删除或改名。[**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) 新旧工程的固定映射及现有独立快照按[专用例外](./路径约定-OC双工程与Gitee快照.md#oc-main-bypods-snapshot)处理，不借通用逐层脚本建立辅助分支或合并两套历史。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、隔离验证 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 修改分支相关逻辑后，用隔离仓库核对运行前后本地分支名称集合不增加、正常分支不切换、两端只更新指定主分支且最终提交号一致；同时覆盖远端主分支异名、游离态已有 / 缺失本地分支、失败停止的路径。不用真实业务仓库的提交或推送验证规则。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
