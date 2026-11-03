# `README.md` 项目统计规范

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#%E5%89%8D%E8%A8%80)
- [一、统计口径总纲](#jobs-toc-heading-2)
  - [1.1、必须注明的三要素](#jobs-toc-heading-3)
  - [1.2、失效判定](#jobs-toc-heading-4)
- [二、项目统计](#jobs-toc-heading-5)
  - [2.1、外层 SDK 与工具链版本](#jobs-toc-heading-6)
  - [2.2、建库与提交历史](#jobs-toc-heading-7)
  - [2.3、前端页面数](#jobs-toc-heading-8)
  - [2.4、后端规模统计](#jobs-toc-heading-9)
  - [2.5、业务逻辑与路由流程图](#jobs-toc-heading-10)
  - [2.6、功能清单](#jobs-toc-heading-11)
  - [2.7、业务文件占比](#jobs-toc-heading-12)
- [三、第三方依赖统计](#jobs-toc-heading-13)
  - [3.1、依赖清单](#jobs-toc-heading-14)
  - [3.2、依赖风险标注](#jobs-toc-heading-15)
- [四、项目定位](#jobs-toc-heading-16)
- [五、如何运行](#jobs-toc-heading-17)
- [六、维护要求](#jobs-toc-heading-18)

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

本规范规定软件工程项目顶层 `README.md` 的编写要求。

> 对软件工程项目，不仅仅要有代码地图（`.codegraph`），顶层目录下也要有 `README.md`（和 `.codegraph` 目录平级）。

编写时的两条总原则：

- 统计类条款如果没有口径，等于没有条款。同一个项目两个人能数出三倍的差距，横向比较全部失效。
- 本规范既是填写要求，也是复核清单。评审时逐条对照，缺项视为未完成。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、统计口径总纲 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-3" data-jobs-toc="v2">1.1、必须注明的三要素 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

凡涉及"数量"的统计项，必须在数字旁注明以下三项：

1、统计口径：什么算一个、什么不算

2、统计依据：从哪个文件、文档、命令或平台得出

3、统计时间：数字会变，必须标注日期

### <span id="jobs-toc-heading-4" data-jobs-toc="v2">1.2、失效判定 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 缺少上述三要素中任意一项的数字，视为无效统计。
- 口径不一致的数字，不得跨项目横向比较。
- 超过一个迭代周期未更新的统计，视为已失效。

## <span id="jobs-toc-heading-5" data-jobs-toc="v2">二、项目统计 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-6" data-jobs-toc="v2">2.1、外层 SDK 与工具链版本 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

需要写清的版本分四类，按项目实际情况取舍：

- 语言与框架：[**Java**](https://openjdk.org)（或项目实际 JDK 发行版）、[**Kotlin**](https://kotlinlang.org)、<u>[**Swift**](https://www.swift.org/)</u>、[**Dart**](https://dart.dev) 与 [**Flutter**](https://flutter.dev/)、[**Node.js**](https://nodejs.org)、[**Python**](https://www.python.org)、[**Go**](https://go.dev/)
- 包管理器与构建工具：[**CocoaPods**](https://cocoapods.org/)、[**Gradle**](https://gradle.org)（含 AGP）、[**pnpm**](https://pnpm.io/)、[**FVM**](https://fvm.app)、[**Bundler**](https://bundler.io)
- 最低支持版本：`minSdk`、iOS 部署目标、浏览器基线
- 锁文件：`pubspec.lock`、`Podfile.lock`、`pnpm-lock.yaml`，并注明是否提交入库

  填写表格：

  | 类别 | 名称 | 版本 | 锁文件是否提交 |
  | --- | --- | --- | --- |
  | 语言 / 框架 | | | — |
  | 包管理器 / 构建工具 | | | — |
  | 最低支持版本 | | | — |

### <span id="jobs-toc-heading-7" data-jobs-toc="v2">2.2、建库与提交历史 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

需要记录：首次建库时间、首次提交时间与 commit hash、最近一次提交时间、总提交数、贡献者数。

  取数命令：

  ```shell
  git log --reverse --format="%ad  %h  %an" --date=iso | head -1   # 首次提交
  git log -1 --format="%ad" --date=iso                             # 最近提交
  git rev-list --count HEAD                                        # 总提交数
  git shortlog -sn --all | wc -l                                   # 贡献者数
  ```

  这五个数字合起来才能判断项目是活跃维护还是已停摆，只写建库时间信息量不够。

### <span id="jobs-toc-heading-8" data-jobs-toc="v2">2.3、前端页面数 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

对于前端项目（[**iOS**](https://developer.apple.com/ios/)、[**Android**](https://developer.android.com)（含 [**HarmonyOS**](https://developer.huawei.com/consumer/cn/harmonyos/)）、Web），要写清楚具体有多少个页面（含子页面）。

  计数口径必须写明，否则数字不可比：

  - 计数单位：路由条目 / `ViewController` / `Activity` / 页面组件，四选一并注明
  - 弹层、半屏、浮层是否计入，需明确
  - H5 容器、跨端容器是否单独计数，需明确
  - 建议同时给出路由数，便于与页面数交叉核对

  填写表格：

  | 端 | 页面数 | 子页面数 | 路由数 | 计数口径 |
  | --- | --- | --- | --- | --- |
  | iOS | | | | |
  | Android（含鸿蒙） | | | | |
  | Web | | | | |

### <span id="jobs-toc-heading-9" data-jobs-toc="v2">2.4、后端规模统计 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

前端交付的最小单元是"页面"，后端交付的最小单元是"接口"。所以后端主指标为**对外接口数**，对标前端页面数。

  需要统计的八项：

  1、对外接口数（主指标），按 HTTP / RPC / MQ 分类

  2、服务（模块）数与部署单元数

  3、核心数据表数，只数业务主表，日志表与中间表不计

  4、业务状态机数，即有状态流转的对象，如订单、审批、结算

  5、外部系统集成数，如支付、短信、实名、地图、ERP

  6、定时任务数，含定时 Job、批处理、异步消费者

  7、中间件依赖，如 [**Redis**](https://redis.io)、MQ、[**Elasticsearch**](https://www.elastic.co/elasticsearch/)、对象存储

  8、运行时规模，含峰值 QPS、日增数据量、存储量

  接口统计表：

  | 协议类型 | 数量 | 统计依据 | 备注 |
  | --- | --- | --- | --- |
  | HTTP | | [**Swagger**](https://swagger.io/) / [**OpenAPI**](https://www.openapis.org/) 文档地址 | |
  | RPC | | 注册中心服务清单 | |
  | MQ | | 消费者配置清单 | |

  口径要求：

  - 只统计**对外暴露**的接口，内部方法、`health check`、管理端点不计入
  - 必须给出统计依据来源，便于复核
  - 交叉校验：正常情况下页面数与接口数比例在 1:2 ~ 1:5 之间，偏离过大需在备注中说明原因，如中台型、平台型后端

### <span id="jobs-toc-heading-10" data-jobs-toc="v2">2.5、业务逻辑与路由流程图 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

依据代码地图（`.codegraph`）里面的资料，梳理业务逻辑与路由情况，形成流程图。

  绘制要求：

  - 使用 [**Mermaid**](https://mermaid.js.org) 内嵌，不要粘贴图片，图片会过期
  - 至少两张：模块依赖图、核心业务流程图
  - 关键节点与模块必须标注**入口文件**，如 `main.dart`、`AppDelegate`、`Application`
  - 标注跨模块调用边界与外部系统边界

  示例：

  ```mermaid
  flowchart TD
      A[入口 main.dart] --> B[路由注册]
      B --> C[业务模块 A]
      B --> D[业务模块 B]
      C --> E[(本地数据库)]
      D --> F[[外部系统]]
  ```

### <span id="jobs-toc-heading-11" data-jobs-toc="v2">2.6、功能清单 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

写清楚涉及到了哪些功能，按类目列出，每项注明"是否涉及 + 实现方式"。

- 网络与安全：接口加解密、证书绑定 / SSL Pinning、鉴权方式（[**OAuth**](https://oauth.net) / [**JWT**](https://jwt.io) / Session）、密钥存储
- 数据：本地数据持久化、数据库（什么牌子、哪个版本）、缓存策略、数据迁移与升级
- 端能力：蓝牙、推送、定位、相机相册、生物识别、扫码、NFC、分享、支付
- 工程：多语言国际化、埋点与监控、崩溃收集、热更新、CI/CD、多环境配置
- 后端：幂等设计、限流降级熔断、分布式锁、事务边界、链路追踪、灰度开关、对账机制
- 合规：隐私清单、权限申请说明、数据脱敏、日志脱敏

### <span id="jobs-toc-heading-12" data-jobs-toc="v2">2.7、业务文件占比 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

除开第三方支援（依赖库），属于业务上的文件有多少，做个统计并给出占比。

  口径要求：

  - 优先按**代码行数**统计占比，按文件数统计必须注明
  - 明确排除项：第三方依赖目录、生成代码、资源文件、锁文件、构建产物
  - 测试代码单独列出，不混入业务代码
  - 用 [**Mermaid**](https://mermaid.js.org) 的 `pie` 画饼状图

  填写表格：

  | 类别 | 文件数 | 行数 | 占比 |
  | --- | --- | --- | --- |
  | 业务代码 | | | |
  | 测试代码 | | | |
  | 配置与脚本 | | | |
  | 第三方依赖（排除） | | | |

  饼图示例：

  ```mermaid
  pie showData
      title 业务代码占比
      "业务代码" : 65
      "测试代码" : 20
      "配置与脚本" : 15
  ```

  占比按行数不按文件数：一个 3000 行的核心类和三个 100 行的配置文件，按文件数算会被严重稀释。

## <span id="jobs-toc-heading-13" data-jobs-toc="v2">三、第三方依赖统计 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

### <span id="jobs-toc-heading-14" data-jobs-toc="v2">3.1、依赖清单 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

写清楚第三方依赖的来源与版本，注明谁是私库、谁是公有库。

  填写表格：

  | 依赖名 | 版本 | 来源（公库 / 私库） | 私库地址 | 许可证 | 直接 / 传递 | 用途模块 | 是否仍在使用 |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | | | | | | | | |

  填写要求：

  - 只统计**直接依赖**，传递依赖不计入总数
  - 许可证必填，这是合规硬需求，混进一个传染性协议的依赖会直接影响商业发布
  - 私库必须写完整地址，否则新人无法拉取
  - "用途模块"与"是否仍在使用"是后续清理僵尸依赖的唯一依据

### <span id="jobs-toc-heading-15" data-jobs-toc="v2">3.2、依赖风险标注 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

以下情况必须单独列出并说明处置方式：

1、许可证风险：[**GPL**](https://www.gnu.org/licenses/gpl-3.0.html) / [**AGPL**](https://www.gnu.org/licenses/agpl-3.0.html) 等传染性协议需显式标注

2、已停止维护或已归档的依赖

3、存在已知安全漏洞的依赖

4、未锁定版本、使用浮动版本号的依赖

## <span id="jobs-toc-heading-16" data-jobs-toc="v2">四、项目定位 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

这是 `README.md` 第一屏内容，统计写得再细也不能替代它：

1、项目名称与一句话简介

2、解决什么问题、给谁用

3、当前状态：在研 / 维护中 / 仅修 Bug / 已归档

4、负责人与维护团队

## <span id="jobs-toc-heading-17" data-jobs-toc="v2">五、如何运行 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

接手的人第一件事永远是把它跑起来，所以这一章不能省。

1、环境准备与依赖安装

2、启动、构建、测试命令

3、多环境配置说明（dev / test / prod）及配置文件位置

4、常见启动问题

## <span id="jobs-toc-heading-18" data-jobs-toc="v2">六、维护要求 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

1、当代码变更影响到第二章、第三章任一统计项时，必须同步更新 `README.md`

2、所有统计数字须标注统计日期，超过一个迭代周期未更新视为失效

3、流程图须与代码地图（`.codegraph`）同步更新

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
