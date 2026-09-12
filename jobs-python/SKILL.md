---
name: jobs-python
description: 当任务涉及 Python 脚本、命令行入口、日志、异常、依赖、格式化、lint 或测试规则时使用。
---

# Jobs Python 写作规范

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[toc]

---

## 🔥 <font id=前言>前言</font>

> 本技能由 `💻JobsCodexConfigs/AGENTS.md` 拆分而来，保留原有 Jobs 工作规范。只有当前任务命中本技能描述时才加载本文件，避免把所有细则长期塞进全局上下文。

## 一、[**Python**](https://www.python.org/) 写作规范 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 1.1、Python 工具目录结构

- Python 工具如果需要同时面向 Windows / macOS 独立打包，外层交付目录优先采用“外层入口 + 内层 Python 工程”的结构：

  ```text
  ToolName.py/
  ├── README.md
  ├── 【MacOS】📦生成dmg.command
  ├── 【Windows】📦生成exe.bat
  └── ToolName/
      ├── pyproject.toml
      ├── src/
      ├── tests/
      ├── assets/
      └── scripts/
  ```

- `ToolName/` 内层目录保存 Python 源码、依赖声明、测试、资源、构建辅助脚本和项目配置；外层目录只保留用户双击入口、交付产物和总说明。
- 外层入口按工具真实分发方式取舍，不强制提供源码运行脚本；如果工具应通过打包产物运行，外层只保留 macOS / Windows 打包入口即可。
- 根据 Python 源文件在 macOS 平台生成 `*.dmg` 的外层脚本固定命名为 `【MacOS】📦生成dmg.command`；根据 Python 源文件在 Windows 平台生成 `*.exe` 的外层脚本固定命名为 `【Windows】📦生成exe.bat`，大小写按这里保持。
- 外层 `.bat` / `.command` 不使用“同名文件夹 + 脚本 + README.md”的包裹结构；除非用户另有要求，也不为每个入口脚本单独写 `README.md`。
- Python 工具系列的说明收口到外层 `README.md`：分别解释每个 `.bat` / `.command` 的平台、用途、环境检查、输出目录、日志位置、风险边界和是否会安装依赖。
- 通用 Shell / Git 仓库里“一脚本一目录、一脚本一 README”的标准不直接套用到 Python 工具系列；Python 工具以“外层总 README + 内层 Python 工程”为准。
- 外层脚本只负责环境检查、进入内层 Python 工程、启动源码或触发构建；业务逻辑应留在 Python 包内，避免把核心逻辑写进 `.bat` / `.command`。
- 移动目录后必须同步修正脚本中的项目根路径、`PYTHONPATH`、`pyproject.toml` 路径、构建输出路径、日志说明和 README 里的目录树。

### 1.2、跨平台打包边界

- macOS 安装包在 macOS 本机生成，Windows EXE 在 Windows 本机生成；不要默认从 macOS 交叉生成 Windows EXE。
- 打包脚本生成的 `.app` / `.dmg` / `.exe` 应包含 Python 运行时和项目依赖；普通用户运行成品时不应再要求手动安装 Python 包。
- 源码运行脚本可以按需准备开发 / 构建环境，但必须先打印内置自述并等待确认；缺少依赖时才安装，不主动升级已有环境。

### 1.3、代码与验证

- Python 代码优先使用 `pathlib`、`argparse` 或项目既有 CLI 框架处理路径和参数；不要用脆弱字符串拼接处理文件路径。
- 修改 Python 包结构后，至少执行 `python -m compileall` 或项目测试；依赖缺失导致无法跑完整测试时，说明未执行原因。
- 修改 `.command` 后执行 `zsh -n`；修改 `.bat` 后至少做路径和变量静态审查，能在 Windows 环境验证时再实际运行。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
