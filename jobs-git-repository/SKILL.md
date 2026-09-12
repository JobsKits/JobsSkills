---
name: jobs-git-repository
description: 当任务涉及 JobsMacEnvVarConfigs、Git 仓库结构、脚本安装/升级入口、仓库级配置同步规则时使用。
---

# Jobs Git 仓库规则

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[toc]

---

## 🔥 <font id=前言>前言</font>

> 本技能由 `💻JobsCodexConfigs/AGENTS.md` 拆分而来，保留原有 Jobs 工作规范。只有当前任务命中本技能描述时才加载本文件，避免把所有细则长期塞进全局上下文。

## 一、Git 仓库规则 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 1.1、🌍JobsMacEnvVarConfigs 仓库

- 处理 `🌍JobsMacEnvVarConfigs` 仓库时，先分清根目录入口脚本和 `scripts/` 下的解耦脚本，不要把二者混成一类。
- `scripts/` 是存放解耦脚本代码的目录；这里面的脚本主文件名对应终端里的命令名，脚本文件统一以 `.command` 作为后缀。
- `scripts/` 下每一个具体的 `*.command` 脚本，都必须由同名文件夹包裹，并且每个脚本文件夹内都必须放置这个脚本对应的 `README.md`。

  ```text
  scripts/
  ├── install.command/
  │   ├── install.command
  │   └── README.md
  └── update.command/
      ├── update.command
      └── README.md
  ```

- `scripts/install.command/install.command` 和仓库根目录下的 `install.command/install.command` 不是同一个职责：

  | 入口位置 | 核心职责 | 处理原则 |
  | -------- | -------- | -------- |
  | `scripts/install.command/install.command` | 利用 `zsh` 配置安装 MacOS 系统的各种自定义依赖。 | 面向依赖安装和本机环境构建。 |
  | `install.command/install.command` | 将 `JobsMacEnvVarConfigs` 内容同步到系统。 | 主要瞄准终端 `zsh` 配置同步。 |

- `scripts/update.command/update.command` 是全员升级入口；凡是 `scripts/install.command/install.command` 新增、删除或调整安装能力，都必须同步更新升级入口，保持安装与升级能力平行，不允许只改安装不改升级。
- 写或改这个仓库的脚本时，要随时对照安装与升级两个入口：安装负责“从无到有”，升级负责“已有环境持续更新”，两者覆盖的工具链和交互顺序应尽量一致。

### 1.2、仓库级 Shell 脚本统一整改

- 批量扫描多个仓库或目录前，先识别嵌套关系并对真实路径去重，避免同一脚本被重复改写。
- 开始修改前必须检查各 Git 工作区和子模块状态；已有改动一律保留，在其基础上继续工作，不得通过回滚或覆盖换取批量处理便利。
- 扫描时默认跳过 `.git`、`node_modules`、`Pods`、`.dart_tool`、`build` 和 `DerivedData`，同时识别扩展名与真实文件类型不一致的替身、书签或二进制文件。
- 区分可独立执行的入口脚本与仅供 `source` 的函数库；入口脚本的 `main()` 必须服从 `jobs-macos-shell` 的“高层步骤集中编排、每个函数调用带职责注释、禁止单次转调包装”规范，函数库不得为了形式统一而强加入口。
- 批量改写前后都要按脚本真实解释器执行静态语法检查，并单独审计 `main()` 结构；出现既有失败时记录基线，整改不得引入新增失败。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
