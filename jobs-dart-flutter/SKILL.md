---
name: jobs-dart-flutter
description: 当任务涉及 Dart、Flutter、Widget 拆分、状态管理、路由、资源、iOS/Android 打包、Gradle、Flutter SDK 或代码生成时使用。
---

# Jobs [**Dart**](https://dart.dev) [**Flutter**](https://flutter.dev/) 写作规范

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#%E5%89%8D%E8%A8%80)
- [一、Dart / Flutter 写作规范](#dart-flutter-conventions)
  - [1.1、图标资源规则](#icon-assets)
  - [1.2、iOS 页面主题对比](#ios-theme-contrast)
  - [1.3、工程路径与源码导入可迁移](#portable-project-paths)

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

> 本技能由 `💻JobsCodexConfigs/AGENTS.md` 拆分而来，保留原有 Jobs 工作规范。只有当前任务命中本技能描述时才加载本文件，避免把所有细则长期塞进全局上下文。

涉及 Flutter 完整项目规划、跨端选型或产品交付方案时，必须按任务读取共用[《软件项目开发与交付规范》的前端技术栈](../jobs-software-project/软件项目开发与交付规范.md#frontend-stack)、[分级验收](../jobs-software-project/软件项目开发与交付规范.md#acceptance)与[发布交接](../jobs-software-project/软件项目开发与交付规范.md#release-delivery)中的命中章节，不无条件加载全文。普通页面或局部修复不因此扩大为全量交付任务；保留既有项目确认的方案，框架、插件及平台版本按实际目标重新核验。

完整 0 到 1 项目先按[主 Skill](../jobs-software-project/SKILL.md)生成需求与评审文档；前端路线未明确时询问“标准型／通用型／混合型”。缺失项留白、不确定项用红字标记，不把规范默认路线视为已确认方案。

## 一、<span id="dart-flutter-conventions">[**Dart**](https://dart.dev) / [**Flutter**](https://flutter.dev/) 写作规范</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 1.1、<span id="icon-assets">图标资源规则</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- Flutter 项目中需要用到 UI 图标时，先去 [**iconfont**](https://www.iconfont.cn/) 找合适图标；优先复用项目已有图标库、命名和视觉风格。iconfont 无合适素材时，按全局公约主动搜索官方站点、[**Wikipedia**](https://www.wikipedia.org/) / [**Wikimedia**](https://www.wikimedia.org/) 等可追溯来源，无须再次确认；用户指定素材优先。下载到本地并保留来源与许可，默认通过打包资源加载，不使用运行时外链。
- 新图标落地时，按当前项目资源体系放入 `assets/`、字体图标目录或既有资源目录，并同步 `pubspec.yaml`、资源常量、README 资源说明和必要的平台端配置。
- 如果采用字体图标方式集成，要记录并统一维护图标名称、unicode / class 信息；业务代码里不要散落硬编码 codepoint，优先通过统一常量、枚举、模型或封装入口引用。

### 1.2、<span id="ios-theme-contrast">[**iOS**](https://www.apple.com/ios/) 页面主题对比</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 制作或修改运行于 iOS 的 Flutter 页面、主题色及文字样式时，必须读取并执行 [iOS 主题对比共同规范](../jobs-swift/references/ios-theme-contrast.md)。白天浅底深字、副标题比主标题浅；黑夜深底浅字、副标题比主标题深；两种模式都必须保证副标题可读。
- 使用项目既有主题的主文字、次文字、页面 / 卡片背景角色成对配置并随有效主题更新；按真实局部背景验收白天、黑夜和跟随系统，不把固定浅灰或低透明度当作通用副标题颜色。

### 1.3、<span id="portable-project-paths">工程路径与源码导入可迁移</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- `import`、`export`、`part` 使用项目既有的相对 URI 或合法 `package:` URI；包内引用保持既有风格，跨包通过已声明依赖的公开入口引用，不越过包边界拼接开发机目录。禁止使用指向本机文件的 `file:///Users/...`、`/home/...`、盘符或绝对磁盘路径作为源码导入。
- 资源声明、本地 `path` 依赖及工程脚本以相应配置文件、脚本或明确的项目根目录为基准定位，不依赖启动工作目录，不把 SDK / 仓库在开发机上的安装路径写成共享配置。SDK 位置由当前环境或项目既有管理工具解析；运行时文件 API 需要的绝对路径可以动态取得，用户显式选择的文件路径按其输入处理。
- 改动导入、资源或依赖寻址时，核对目标文件与包依赖有效，并在完整工程复制 / 改名后检查解析；工程脚本另外从无关工作目录验证。按变更执行必要的分析或构建检查；可复用缓存与既有依赖，不为验证主动清理或安装，未完成跨机验证时明确说明。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
