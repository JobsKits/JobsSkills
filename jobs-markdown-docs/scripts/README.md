# Markdown 目录部署与机器注册脚本

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#%E5%89%8D%E8%A8%80)
- [一、文件与职责](#files)
- [二、先计划再部署](#deploy)
- [三、首次克隆前的机器注册](#registration)
- [四、验证与发布边界](#validation)

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

本目录把已审核的文档清单部署到各自 [**Git**](https://git-scm.com/) 根，并注册当前机器新克隆前所需的可信驱动。统一标准为本地 `[toc]`、整文件暂存生成有层级缩进的折叠目录、已注册机器首次克隆自动恢复标签。依赖 Git、[**Node.js**](https://nodejs.org/) 20 或更新版本，无 npm 依赖。

## 一、<span id="files">文件与职责</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| 文件 | 职责 |
| --- | --- |
| [deploy-markdown-toc.mjs](./deploy-markdown-toc.mjs) | 读取精确审核清单，默认只计划；显式 apply 后接入或升级自包含工具，保留现有文档、配置和暂存内容 |
| [register-markdown-toc.mjs](./register-markdown-toc.mjs) | 从已获准仓库的实际远端构建精确条件，部署可信机器副本，提供状态与精确撤回 |
| [markdown-toc.Tests.mjs](./markdown-toc.Tests.mjs) | 转换、安装、属性与索引保护回归 |
| [deploy-markdown-toc.Tests.mjs](./deploy-markdown-toc.Tests.mjs) | 隔离仓库的部署、升级和失败保护回归 |
| [register-markdown-toc.Tests.mjs](./register-markdown-toc.Tests.mjs) | 隔离配置下实跑注册、首次克隆、来源隔离与撤回，不改真实全局配置 |

## 二、<span id="deploy">先计划再部署</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

从本目录执行，清单和报告路径替换为当前任务的实际文件。审核清单包含授权 `root`、`candidates` 和 `excluded`；每份获准文档给出绝对 `path`、实际 `repoRoot`、当前 `sha256` 和 `approved: true`。父子 Git 分开登记，无有效目录的文档不加入，第三方与所有权不明文档排除。

```shell
node ./deploy-markdown-toc.mjs \
  --inventory ./已审核目录清单.json \
  --report ./部署计划.json

node ./deploy-markdown-toc.mjs \
  --inventory ./已审核目录清单.json \
  --report ./部署结果.json \
  --apply
```

写入前保存备份；已有工具 README 只恢复本地目录标签，完整保留当前正文，不自动追加阶段性说明或历史记录。仅在工具 README 缺失时使用当前模板；既有文档的功能补充由明确的文档维护任务处理。错误报告与回滚冲突逐仓保留，不能把失败仓报告为已完成。报告和备份写到报告文件所在目录，不混入业务提交。

## 三、<span id="registration">首次克隆前的机器注册</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

先部署标准转换器，再使用同一份审核清单注册。多份授权根可重复传入 `--inventory`；不从某个目录名推定其中全部仓库都获准。

```shell
node ./register-markdown-toc.mjs plan \
  --inventory ./已审核目录清单.json \
  --report ./机器注册计划.json

node ./register-markdown-toc.mjs install \
  --inventory ./已审核目录清单.json \
  --report ./机器注册结果.json
```

注册只向当前用户 Git 配置添加精确远端的 `includeIf hasconfig:remote.*.url` 引用，不设全局文档通配，不增加 hooks，不执行被克隆仓库的脚本。可信副本与记录保存在用户数据目录的 `jobs-markdown-toc/registrations/`，运行时不依赖本 Skills 工作树。带端口的来源仅保留实际协议与端口，不猜测其它服务端口；含凭据、通配字符等不可靠来源停止并报告，不写入敏感地址。

计划和结果报告给出实际 `statePath`，将其传给状态与撤回入口：

```shell
node ./register-markdown-toc.mjs status \
  --state ./实际机器注册记录.json

node ./register-markdown-toc.mjs uninstall \
  --state ./实际机器注册记录.json
```

撤回只移除本工具拥有的精确 include 值，保留其它配置、同条件下已有引用、各仓 local 驱动和审计副本。报告记录原有值及本次写入的归属。换机需要注册一次；未注册机器仍可审阅并运行仓内工具的 local 安装。

## 四、<span id="validation">验证与发布边界</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

```shell
node --test ./markdown-toc.Tests.mjs
node --test ./deploy-markdown-toc.Tests.mjs
node ./register-markdown-toc.Tests.mjs
```

部署后逐份检查磁盘标签态与完整字节往返，用独立临时索引验证发布态，保留真实 HEAD、暂存对象、模式、阶段和用户标记。首次克隆验收使用全新目录，不能先运行 install / restore 再声称下载即标签态。只更新当前源码不等于远端已发布；部署和验证均不提交、不推送、不改已有分支。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
