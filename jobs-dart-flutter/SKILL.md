---
name: jobs-dart-flutter
description: 当任务涉及 Dart、Flutter、Widget 拆分、状态管理、路由、资源、iOS/Android 打包、Gradle、Flutter SDK 或代码生成时使用。
---

# Jobs Dart Flutter 写作规范

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[toc]

---

## 🔥 <font id=前言>前言</font>

> 本技能由 `💻JobsCodexConfigs/AGENTS.md` 拆分而来，保留原有 Jobs 工作规范。只有当前任务命中本技能描述时才加载本文件，避免把所有细则长期塞进全局上下文。

## 一、[**Dart**](https://dart.dev) / [**Flutter**](https://flutter.dev/) 写作规范 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 1.1、图标资源规则

- Flutter 项目中需要用到 UI 图标时，先去 [**iconfont**](https://www.iconfont.cn/) 找合适图标；优先复用项目已有图标库、命名和视觉风格，不随手使用来源不明的图片素材。
- 新图标落地时，按当前项目资源体系放入 `assets/`、字体图标目录或既有资源目录，并同步 `pubspec.yaml`、资源常量、README 资源说明和必要的平台端配置。
- 如果采用字体图标方式集成，要记录并统一维护图标名称、unicode / class 信息；业务代码里不要散落硬编码 codepoint，优先通过统一常量、枚举、模型或封装入口引用。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
