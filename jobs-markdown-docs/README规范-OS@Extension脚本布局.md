# `README.md` 路径专项：`OS@Extension` 脚本布局

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#%E5%89%8D%E8%A8%80)
- [一、适用路径与裸露定义](#scope)
- [二、必须直接放置的管理入口](#bare-entrypoints)
- [三、README 与验证](#readme-and-validation)

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

> 本附件承载 `OS@Extension` 的管理入口布局例外。命中系统右键功能时，先读取主规则 [系统右键菜单双端与独立安装规范](../jobs-macos-shell/系统右键菜单双端与独立安装规范.md)，再按本文维护入口与就近说明，并遵循 [Markdown 主规范](./SKILL.md#readme-examples-first)。

## 一、<span id="scope">适用路径与裸露定义</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 项目范围为 `JobsGenesis/OS@Extension/`；两端总入口分别位于其下的 `MacOS@Extension/`、`WindowsOS@Extension/`，各子功能使用独立物理文件夹管理。
- “裸露”指脚本直接放在所属仓库或功能目录内，与该目录的 `README.md` 平级；不再额外创建与脚本完整文件名相同的文件夹。
- 本规则覆盖下文列出的本端总管理入口，以及 `OS@Extension` 下各独立功能目录中的 `.command` / `.cmd` 管理入口；不将该例外扩大到其它脚本、独立交付包或其它仓库。

## 二、<span id="bare-entrypoints">必须直接放置的管理入口</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 两端各保留一个总管理入口，与各自根 `README.md` 平级；每个面板同时提供安装 / 更新与卸载，只管理本端功能集合：

  - `MacOS@Extension/【MacOS】🧩管理Finder扩展.command`
  - `WindowsOS@Extension/【Windows】🧩管理资源管理器扩展.cmd`

- 各子功能继续通过独立物理文件夹解耦；一个管理入口统一提供本功能的安装 / 更新与卸载，直接放在对应功能文件夹内，与其 `README.md` 平级。例如：

  - macOS `JobsFileCreator/【MacOS】管理新建文件Finder扩展.command`
  - Windows `JobsHiddenFilesToggler/Manage.cmd`

- 上述入口不能因“一脚本一目录”或整理 README 再套同名文件夹，也不能把不同功能的入口移到一个公共目录。公开入口可唤起同名 `.app` / `.vbs`，内部 worker 收于本功能 `Scripts/`；保留原 `.command` / `.cmd` 入口及完整独立包能力，不再恢复成对的公开安装、卸载脚本。

  ```text
  OS@Extension/
  ├── MacOS@Extension/
  │   ├── README.md
  │   ├── 【MacOS】🧩管理Finder扩展.command
  │   └── JobsFileCreator/
  │       ├── README.md
  │       ├── 【MacOS】管理新建文件Finder扩展.command
  │       └── Scripts/
  │           └── README.md
  └── WindowsOS@Extension/
      ├── README.md
      ├── 【Windows】🧩管理资源管理器扩展.cmd
      └── JobsHiddenFilesToggler/
          ├── README.md
          ├── Manage.cmd
          └── Scripts/
              └── README.md
  ```

## 三、<span id="readme-and-validation">README 与验证</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 总 README 说明本端总管理面板、功能集合及目录；功能 README 说明本项管理入口的用途、依赖、两种操作、确认与取消、安装 / 卸载影响范围、日志与产物。根说明不能替代功能目录内的 README；实际维护 `Scripts/` 时补齐其就近说明。
- 文件链接与命令以当前 README 所在目录为基准，例如功能 README 使用 `./【MacOS】管理新建文件Finder扩展.command` 或 `./Manage.cmd`，不写多余的同名中间文件夹。
- 交付前核对脚本与就近 README 均为真实文件、功能目录独立存在、入口未被同名文件夹包裹，并检查目录树、相对链接及调用路径相符。
- 仅维护规则或文档时不移动业务脚本，不执行安装 / 卸载、不注册扩展或重启 [**Finder**](https://support.apple.com/guide/mac-help/welcome/mac)；文档结构验证与真实安装验收分别报告。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
