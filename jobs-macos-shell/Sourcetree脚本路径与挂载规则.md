# Jobs [**Sourcetree**](https://www.sourcetreeapp.com/) 脚本路径与挂载规则

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#%E5%89%8D%E8%A8%80)
- [一、固定双位置与同步验证](#dual-locations)
- [二、菜单挂载与安装入口同步](#action-installation)
- [三、异常启动路径的寻址](#script-location)

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

> 本附件承载 Jobs 的 Sourcetree 自定义动作脚本固定双位置、菜单安装和寻址规则。新增、修改或重命名相关脚本、动作登记或安装配置时必须读取；通用运行环境、交互与日志兼容规则继续执行 [Shell 主 Skill](./SKILL.md)。

## 一、<span id="dual-locations">固定双位置与同步验证</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 所有 Sourcetree 自定义动作脚本固定采用双位置维护：运行目录为 `/Users/jobs/SourceTree.command`，备灾目录为 `/Users/jobs/Documents/Github/JobsGenesis/SourceTree.command`。新增、修改或重命名脚本包时，必须按相同相对路径同步两边的 `.command`、同名 `README.md` 和脚本行为文档，不能只改其中一处。
- 双位置同步后必须使用 `cmp` 或内容哈希确认对应文件完全一致；修改 `.command` 时，还必须对运行副本与备灾副本分别执行 `zsh -n`。任一位置缺失、内容不一致或语法校验失败，都不能视为任务完成。

## 二、<span id="action-installation">菜单挂载与安装入口同步</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 新增或修改 Sourcetree 脚本的默认完成定义必须包含“已经实际挂载到当前用户 Sourcetree 自定义操作”：同时更新脚本包内和 `~/Library/Application Support/SourceTree/actions.plist` 中的动作配置，确保动作目标指向运行副本、仓库动作参数为 `$REPO`，并在 Sourcetree 运行时完成重载验证。只交付脚本、README 或待用户手工配置步骤，一律不能标记完成。
- 新增、修改或重命名动作时，必须同步关联 `【MacOS】安装SourceTree自定义菜单.command/` 内安装脚本的动作登记、`actions.plist` 模板及 `README.md`，再对齐运行库、仓库备灾库与当前用户菜单；不能只修改当前用户菜单而让新电脑安装遗漏动作。动作登记按稳定脚本路径补齐默认项，更新已有项保留用户标题；重命名时同步旧路径迁移，不遗留重复动作。
- [**Codex**](https://openai.com/codex) 负责动作目标路径、参数、仓库 / 文件动作类型、输出窗口策略、执行权限、双位置脚本副本和配置安装；用户最多只需要在 Sourcetree 中按个人偏好修改菜单显示标题。更新已存在动作时，应按稳定目标路径识别并保留用户当前显示标题；只有用户明确要求时才改名，避免用脚本默认标题覆盖用户定制。
- 修改任何现行 `actions.plist` 前必须创建带时间戳的可恢复备份；修改后校验 plist 可解档、动作唯一、目标脚本存在且可执行。Sourcetree 正在运行时按安全方式重启或重新加载，再从当前用户配置中反查动作名称、`$REPO` 参数和目标路径，证明菜单已经挂载。

## 三、<span id="script-location">异常启动路径的寻址</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- `SCRIPT_DIR` 不能只依赖 `dirname "$0"`；当 `$0` 不是绝对路径时，要按脚本名从 `~/SourceTree.command/脚本名/脚本名` 和 `../../../../JobsGenesis/SourceTree.command/脚本名/脚本名` 兜底找回真实脚本目录，确保脚本能定位自身目录和配套静态文档路径，不能退化成根目录路径；运行时自述仍以内置文本为准，不能在运行时 `cat`、拼接或依赖外部 `README.md`。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
