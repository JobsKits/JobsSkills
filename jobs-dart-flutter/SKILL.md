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

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

> 本技能由 `💻JobsCodexConfigs/AGENTS.md` 拆分而来，保留原有 Jobs 工作规范。只有当前任务命中本技能描述时才加载本文件，避免把所有细则长期塞进全局上下文。

## 一、<span id="dart-flutter-conventions">[**Dart**](https://dart.dev) / [**Flutter**](https://flutter.dev/) 写作规范</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 1.1、<span id="icon-assets">图标资源规则</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- Flutter 项目中需要用到 UI 图标时，先去 [**iconfont**](https://www.iconfont.cn/) 找合适图标；优先复用项目已有图标库、命名和视觉风格。iconfont 无合适素材时，按全局公约主动搜索官方站点、[**Wikipedia**](https://www.wikipedia.org/) / [**Wikimedia**](https://www.wikimedia.org/) 等可追溯来源，无须再次确认；用户指定素材优先。下载到本地并保留来源与许可，默认通过打包资源加载，不使用运行时外链。
- 新图标落地时，按当前项目资源体系放入 `assets/`、字体图标目录或既有资源目录，并同步 `pubspec.yaml`、资源常量、README 资源说明和必要的平台端配置。
- 如果采用字体图标方式集成，要记录并统一维护图标名称、unicode / class 信息；业务代码里不要散落硬编码 codepoint，优先通过统一常量、枚举、模型或封装入口引用。

### 1.2、<span id="ios-theme-contrast">[**iOS**](https://www.apple.com/ios/) 页面主题对比</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 制作或修改运行于 iOS 的 Flutter 页面、主题色及文字样式时，必须读取并执行 [iOS 主题对比共同规范](../jobs-swift/references/ios-theme-contrast.md)。白天浅底深字、副标题比主标题浅；黑夜深底浅字、副标题比主标题深；两种模式都必须保证副标题可读。
- 使用项目既有主题的主文字、次文字、页面 / 卡片背景角色成对配置并随有效主题更新；按真实局部背景验收白天、黑夜和跟随系统，不把固定浅灰或低透明度当作通用副标题颜色。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
