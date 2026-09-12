---
name: jobs-objective-c-pods
description: 当任务涉及 Objective-C、系统类创建工厂、系统 API 的 JobsMake/JobsOCDSL 封装、Xcode CodeSnippets 对齐、本地 Pods、Core/Support/Resource、头文件引用、Pod 拆分、JobsDefineProperty、JobsModelDSL、JobsBlock、import 排序或 Xcode Markdown 引用时使用。
---

# Jobs Objective-C 与本地 Pods 工程规范

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[toc]

---

## 🔥 <font id=前言>前言</font>

> 本技能由 `💻JobsCodexConfigs/AGENTS.md` 拆分而来，保留原有 Jobs 工作规范。只有当前任务命中本技能描述时才加载本文件，避免把所有细则长期塞进全局上下文。

## 一、[**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) / 本地 Pods 工程规范 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 1.1、工程背景与目录边界

- 本规范默认服务 Jobs 的 OC 工程，尤其是把原工程里的本地代码逐步提取为本地管理 Pods 的场景。
- Swift 侧的 iOS 项目固定指 `../../../../JobsBaseConfig/JobsBaseConfig@JobsSwiftBaseConfigDemo`。
- OC 侧的新项目固定指 `../../../../JobsOCBaseConfigDemo@ByPods`。
- OC 侧的老项目固定指 `../../../../JobsBaseConfig/JobsBaseConfig@JobsOCBaseConfigDemo`。
- OC 新项目由 OC 老项目升级改造而来：新项目把老项目中集成于主工程的一部分能力拆解成本地 Pods 管理，拆解过程中只做极小调整，绝大多数新项目本地 Pod 都能在老项目主工程里找到对应来源或对应功能。
- OC 新工程与 OC 老工程的唯一架构差异是能力承载形态：新工程把 Jobs 自维护能力下沉到本地 Pod 集中管理，老工程把同一能力集成在主工程；这不是两套产品或两套功能标准。除本地 Pod 形态层之外，对应业务目录中的 Jobs 自维护源码、Demo、资源、行为和文档必须保持一致。
- 用户只点名任一 OC 工程时，默认授权并要求在同一任务中定位另一工程的对应能力并同步；不能因为用户忘记补充“另一个工程也要改”就只改单侧。开始修改前先建立新工程本地 Pod路径 ↔ 老工程主工程路径的对应关系，结束前复核两侧差异。
- 允许保留的差异仅限集成形态：新工程的 `JobsByPods/Pod名@Pods`、podspec、Podfile 依赖、聚合头和 Development Pods 装配，对应老工程的主工程源码目录、资源目录、Xcode 文件引用、Build Phases 与 target membership。不能把这些形态差异误判为功能差异，也不能把新工程的 Pod 目录或 podspec 原样复制进老工程。
- 对应文件没有集成形态差异时应逐字同步；确有形态差异时，归一化 Pod 路径、模块化 import、聚合入口和工程引用后，公开 API、实现语义、Demo 交互、资源内容和文档说明必须一致。若一侧没有对应文件，必须在本轮补齐对应实现，或明确报告因第三方所有权、语言边界或目标能力不适用而“无需修改”，不得静默遗漏。
- 从 OC 新项目向 OC 老项目平移能力时，要按老项目的主工程集成方式落地：不要把新项目的 `Pod名@Pods` 目录、podspec 或 Podfile 依赖照搬成老项目的新 Pod；应把源码放回老项目主工程的对应功能目录，把资源加入老项目资源目录，把 Demo 入口、聚合头、Build Phases 和 target 引用同步到老项目现有结构。
- OC 新项目里“Jobs 自己写的代码”定义为主工程 + `JobsByPods/` 下 Jobs 自建本地 Pods；排除根目录 `Pods/`、`JobsByPods/ManualByOCPods@Pods/` 和确认的外援第三方源码。扫描、批改、回归和编译都按这个边界执行。
- OC 修改前必须确认文件所有权：标准 Jobs 文件头、仓库历史或用户明确指定可以作为 Jobs 自有 / 已接管维护的依据，仅有 `Jobs*` 目录名或位于本地 Pod 内不能单独证明所有权。批处理脚本统一检查源码前 100 行：必须存在 `Created by Jobs`，同时出现其它 `Created by` 或非 Jobs `Copyright` 就排除；`.m` / `.mm` 存在同名头时还要联查头文件所有权，防止只改到被换过文件头的外援实现。文件头、版权、路径或上游来源显示为他人编写的 Pod 源码、供应商源码、生成代码一律不改；所有权不明确时先排除并报告，只有用户明确点名授权后才处理。该边界同时覆盖 OC 新工程和 OC 老工程，脚本复用 `scripts/jobs_oc_ownership.rb`，不得各写一套宽松判定。
- 当文件头与路径 / 仓库历史冲突时，按更严格的外援边界处理：不能因批量统一过 `Created by Jobs` 文件头，就把 `Pods`、`ManualByOCPods@Pods`、`PodsManual`、`Manual_Add_ThirdParty`、应用内 `App工具类/3rd`或已确认的上游 Demo（如 `Demo@Excel/Excel-SpreadsheetView`、`Demo@CoreTextLearning`）误认为 Jobs 自有源码。这些路径是 `jobs_oc_ownership.rb` 的硬排除项；若用户确实要接管某一份外援源码，必须单独点名并手工审核，不通过全局脚本放宽。
- 所有本地管理的 Pod 默认位于项目根目录 `JobsByPods` 文件夹下，每个 Pod 文件夹命名统一为 `Pod名@Pods`。
- 外源性 Pod 本地化后，统一放入 `JobsByPods/ManualByOCPods@Pods` 管辖。第三方来源信息要保留，只做本地托管适配，不抹掉上游痕迹。
- `JobsByPods/ManualByOCPods@Pods/Texture` 是明确的重型第三方 Pod 豁免项，不套用 Jobs 自建 Pod 的 `Core` / `Support` / `Resource`、根聚合头、`JobsPodspecKit.rb` 和 podspec 扁平化规范，也不因全量本地 Pod 整理而移动或改写其上游目录、源码、资源与 subspec。只有用户明确点名修改 `Texture` 本身时才进入该目录，并继续以保留上游结构为优先。
- `JobsByOCPods` 是最初提取出来的本地 Pod，也是后续本地 Pods 分离时的源头参照。遇到缺文件、缺宏、缺分类、缺辅助类时，优先回到 `JobsByOCPods` 找源头，再迁移到目标 Pod 的合适位置。
- 工程最初能完整编译通过的前提，是尚未把部分本地写法提取成多个本地 Pod。拆分后，每个 Pod 实际上成为独立工程，只是通过同一个 `xcworkspace` 协同管理，因此编译器会提高跨域访问门槛，暴露头文件、模块化、依赖边界和循环引用问题。
- 处理编译错误时，不要只追求“先编过”。要判断错误是不是由本地 Pod 化后的边界变化引起：头文件暴露层级、`Core` / `Support` 归属、podspec 依赖、聚合头、`HEADER_SEARCH_PATHS`、循环依赖，都要一起看。
- Jobs 自己维护的 [**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) 文件（`*.h` / `*.m` / `*.mm`）顶部注释必须使用完整 Jobs 模板：第一行文件名，第二行模块名，第三行空注释行，第四行 `Created by Jobs on yyyy年M月d日，星期X.`。新建文件、迁移文件、整理旧文件或用户点名头注释不规范时，都要补齐；不要保留只有文件名和模块名的简化头。文件头注释区域和 `#import` 导入区域之间必须保留一个空行，不能让注释块的最后一行 `//` 紧贴 `#import`。

  ```objc
  //
  //  JobsClass.h
  //  JobsClass
  //
  //  Created by Jobs on 2026年5月13日，星期三.
  //

  #import "JobsClass.h"
  ```

- 模板中的文件名必须匹配当前文件真实名称，例如 `PDFView+DSL.m`；模块名优先写当前类、分类或所属 Pod / 模块的稳定名称，不确定时先参考同目录同类文件，不要机械写成占位的 `JobsClass`。

### 1.2、文件组织与类边界

- 默认坚持“一个文件一个类”。除非是 `NS_INLINE`、小型 `typedef`、私有枚举、协议声明、极短生命周期的匿名 category，或者确实必须和主类共生的编译期兼容声明，否则不要把多个 `@interface` / `@implementation` 写进同一个 `.h` / `.m` 文件。
- 控制器文件尤其不能顺手塞 model、cell、view、helper class。发现 `ViewController*.m`、`*VC.m`、`*Cell.m` 里混入独立类时，优先拆成独立的 `类名.h/.m`，并按真实职责放到同目录或 `Model` / `View` / `Cell` 子目录，再由调用方 `#import` 引用。
- 拆出来的类必须使用真实类名文件名、完整 Jobs 文件头、独立 `@interface` / `@implementation`，公开 API 放 `.h`，实现细节留 `.m`。不要为了省事写在调用方 `.m` 顶部形成“局部类”。
- 如果新增文件属于 Xcode 主工程源码，必须同步检查并更新 `*.xcodeproj/project.pbxproj` 的文件引用和 target membership；如果属于本地 Pod，则按 Pod 目录、podspec、README 和 `pod install` 规则处理。不能只在磁盘上新建文件就结束。
- Jobs 自建 Pod 的磁盘根目录统一为 `Pod名@Pods`：`Core` 必须存在，`Support` / `Resource` 按需创建，不强制空目录；入口头、podspec、README、LICENSE 放在根目录，不放进 `Core` / `Resource`。CocoaPods 的 `Development Pods > Pod名` 只是展示分组，不能当成真实资源目录。
- `Core` 只放代码。Jobs 自建 Pod 的 `Core` 目录下，所有 `*.h` / `*.m` / `*.mm` 源码都必须用完整基名建同名文件夹包裹；同一组 `.h` / `.m` / `.mm` 放进同一个同名文件夹，分类保留 `+Category` 全名，不允许因为同层只有一组就平铺。例如 `Core/JobsFuseAnimation/JobsFuseOuterRingConfig/JobsFuseOuterRingConfig.h` 和 `Core/JobsFuseAnimation/UIView+JobsFuseAnimation/UIView+JobsFuseAnimation.h`。
- 聚合头 / 模块入口头必须放在 `Pod名@Pods/` 根目录，和 `Core` / `Resource` / `Support` 齐平。入口头一般使用 `Pod名.h`；若 `Core/Pod名/Pod名.h` 带同名 `.m` 或真实 `@interface`，它是源码头，不按聚合头硬搬，必须先解决命名冲突和公开头设计，避免同名 public header 互相覆盖。
- `Core` 只能有一层真实目录，禁止磁盘上出现 `Pod名@Pods/Core/Core/...`，也不要用 podspec 虚拟 subspec 再包一层 `Core/**/*`。移动目录后同步检查 podspec 递归通配、公开头边界、README 目录结构和 `pod install` 后的 Development Pods 展示。

#### 1.2.1、`switch` / `case` 分支注释

- OC 新项目和 OC 老项目中 Jobs 自己维护的新增、修改和存量回归代码，只要使用 `switch`，每个 `case` 的分支说明都必须使用独立一行的 `///`，放在该标签紧邻上方并与 `case` 保持同缩进；禁止写成 `case ...: // ...` 或把分支说明接在单行执行语句末尾。枚举定义处已有注释不能替代 `switch` 使用处的独立分支注释。
- 已有的行尾分支说明应保留原语义并上移为 `///`；编译器、lint 或格式化工具控制注释不当作分支说明，必要时保留原位并另补 `///`。多个枚举值合并在同一个 `case` 时写一条覆盖全部值的独立注释；连续的多个 `case` 标签每个分别写。`default` 同样使用独立 `///` 说明兜底或未知值处理语义。

  ```objc
  switch (displayMode) {
      /// 处理多行尾部截断模式
      case JobsLabelTextDisplayModeMultiLineTailTruncation:
          break;
      /// 未匹配已知分支时执行兜底处理
      default:
          break;
  }
  ```

### 1.3、`Core` / `Support` 文件夹职责

- `Core` 承载准备对外暴露的核心能力；`Core` 代码头文件通常进入 `public_header_files`，代表使用方能看到的 API 边界。
- `Resource` 和 `Core` 平级，专门承载非代码资源；图片、`*.bundle`、声音文件、`*.json`、`*.plist`、`*.xcprivacy`、`.xcassets`、字体、音视频等都放入真实 `Resource` 目录，不塞进 `Core`，也不只在 podspec 中虚拟分组。
- `Support` 辅助 `Core`，放实现细节、兼容代码、内部分类、桥接文件、局部宏和非公开工具。`Core` 如果必须引用 `Support`，只允许写在 `*.m` / `*.mm` 内，并使用 `<Pod名/Support头文件.h>` 这类尖括号形式。
- 某个 Pod 缺文件时，最合理路径不是立刻新增跨 Pod 引用，而是去源头 `JobsByOCPods` 寻找，迁移到当前 Pod 的 `Support` 文件夹下，并按既定目录格式放入。
- 能放进当前 Pod `Support` 解决的，不要轻易加新的 Pod 依赖。只有该能力确实属于独立公共能力、多个 Pod 都应该复用时，才考虑拆成独立 Pod 或依赖已有 Pod。
- `Core` / `Support` 的真实磁盘目录结构必须能在 [**Xcode**](https://developer.apple.com/xcode) / Pods 工程里显示出来。新增、删除、移动目录后，通过 `JobsPodspecKit.rb` 动态映射，`pod install` 后应反映真实目录结构。

### 1.4、头文件引用边界

- `Core` 引用 `Core`、`Support` 引用 `Support` 时，依赖可写在 `*.h`；`Core` 引用 `Support` 时写在 `*.m` / `*.mm`，避免把内部实现细节泄露到公开头文件。
- 系统头、第三方 Pod、内源 Pod 的公开依赖默认写入当前模块同名 `*.h`；Jobs 自己维护的 `*.m` / `*.mm` 顶部只保留自身同名头文件，以及当前 Pod 内部确需下沉到实现层的 `Support` 私有头。
- 用到其他 Pod 时，一律优先 `__has_include` 双通道保护性写法 + 聚合头，先尝试 `<Pod名/聚合头.h>`，再 fallback 到 `"聚合头.h"`；不要裸写第三方 / 其他 Pod 的内部子头，也不要把保护性 import 留在实现文件。
- 对 `JobsOCDSL`、`JobsMakes`、`JobsModelDSL`、`JobsBlock`、`JobsOCDefs` 这类聚合头，按“必须上提到同名 `*.h`”执行；如果上提后暴露循环依赖，要通过前向声明、依赖下沉、拆 Support 或修 podspec 边界解决，不退回实现文件。
- 头文件只引入当前 `*.h` 真实暴露类型、协议、宏或声明所需要的最小模块；普通实现细节头可留在 `*.m`，但 `__has_include` 保护性 import 和上述 Jobs 聚合头不适用该例外。
- 如果某个 Pod 已经提供聚合头，外部引用必须引入聚合头，不要因为当前只用到其中一个协议、宏、分类或类，就绕开聚合头单独引入内部子头。聚合头是这个 Pod 对外承诺的头文件边界，子头只是聚合头内部组织细节。
- 禁止用“补一个更具体的子头 import”来掩盖 podspec 依赖、公开头暴露、modulemap、`HEADER_SEARCH_PATHS` 或循环依赖问题。例如已经引入 `JobsOCProtocols/JobsBaseProtocolHeader.h` 时，不要再为了 `BaseProtocol` 单独引入 `JobsOCProtocols/BaseProtocol.h`；如果 `BaseProtocol` 仍未声明，应排查 `JobsOCProtocols` 的直接依赖、聚合头导出、Pod 生成物和模块边界。
- 只要某个文件用了 `MacroDef_Cor.h` 里提供的颜色相关能力，例如 `JobsWhiteColor`、`JobsClearColor`、`HEXCOLOR(...)`、`UIColor.xy_*` 等，则该文件的 `*.h` 头文件必须显式补上 `XYColorOC` 的双通道保护性导入；不要只依赖 `*.m`、PCH、别的聚合头或间接包含。

  ```objc
  #if __has_include(<XYColorOC/XYColorOC.h>)
  #import <XYColorOC/XYColorOC.h>
  #else
  #import "XYColorOC.h"
  #endif
  ```

- 这条规则优先作用在公开头文件边界：如果 `MacroDef_Cor.h` 的颜色宏或 `XYColorOC` 能力是在 `*.h` 里被声明、默认值、宏定义、内联函数或点语法签名直接用到，就必须把上面的导入写进对应 `*.h`；只有确定相关能力纯属 `*.m` 内部实现细节时，才允许只在 `*.m` 导入。

  ```objc
  #if __has_include(<JobsOCDefs/JobsDefines.h>)
  #import <JobsOCDefs/JobsDefines.h>
  #else
  #import "JobsDefines.h"
  #endif
  ```

- 不要在公开头里写脆弱的相对路径，例如 `../../xxx.h`。如果必须靠搜索路径才能找到，要回到 podspec / `JobsPodspecKit.rb` / `header_mappings_dir` / 聚合头设计上修正。

### 1.5、本地 Pod 拆分策略

- 拆 Pod 前先确认职责边界：这个能力是公共基础能力、业务 UI、工具分类、模型、宏定义、资源包，还是某个 Pod 的内部辅助实现。职责没分清，不要急着建新 Pod。
- 从 `JobsByOCPods` 分离能力时，优先保持原始文件命名、注释风格和调用方式，先完成边界收口，再考虑小范围整理。
- 新 Pod 目录必须使用 `Pod名@Pods`，内部至少包含 `Core`、`Pod名.podspec`、必要时包含 `Support`、`JobsPodspecKit.rb`、`README.md`、入口头 `Pod名.h`。
- 能用 `Support` 消化的跨域访问问题，优先迁移到当前 Pod `Support`；确实属于可复用公共能力时，才新增 Pod 依赖。
- 对第三方库做 Jobs 风格补充时，优先独立成本地管理的 `Extra` Pod，并以 `Extra` 结尾，例如 `BRPickerViewExtra`、`GKCustomNavigationBarExtra`、`HTMLDocumentExtra`。这些补充不直接改外援源码，优先放入对应 `Extra@Pods/Core`。
- `Extra` Pod 里如果发现继承自 `NSObject`、实质承担配置 / model 职责的第三方类或本地适配类，默认做成 `类名+DSL.h/.m` 的形式并入对应 `Extra` Pod 的 `Core`。每组文件都必须用各自名字命名的文件夹包裹管理，例如 `Core/BRPickerStyle/BRPickerStyle+DSL/BRPickerStyle+DSL.h`；即使该目录下只有 `BRPickerStyle+DSL.h/.m` 这一组，也不允许直接平铺在 `Core/BRPickerStyle/` 下。
- 一个文件只办一件事。遇到历史代码在 `类名+Category.h/.m` 里顺手定义主类、兼容空类、记录类、配置类等独立类型时，必须拆到独立的 `类名.h/.m` 文件；category 文件只保留 category 职责。为防止旧代码或外部库重复定义，兼容类声明和空实现默认用 `#ifndef` 宏保护。
- 批量修改后，如果用户指出一个具体文件的问题，默认按同一套批量规则做全局回归扫描。只要该问题可能由统一脚本、统一替换、统一 import 规则造成，就不能只修被点名文件，要在同一覆盖范围内找同类问题并同步修正。
- 但凡修改本地 Pod，不管是新增、删除、重命名、调整 `Core` / `Support`、公开 API、入口头、资源、podspec、`Podfile.deps` 还是依赖关系，都必须扫描整个归属工程里使用到这个 Pod 的代码并同步更新。扫描范围至少包括主工程源码、Demo 入口、`#import` / 聚合头引用、其它 Pod 的 podspec 依赖、`Podfile` / `Podfile.deps`、README / 技术文档和脚本中的 Pod 名；不能只改 `Pod名@Pods` 目录。`Pods/`、`Podfile.lock`、`PodspecDependencyReport` 等生成物如果本轮没有执行生成流程，不手工硬改，但最终必须明确标出仍需刷新。
- 每次新增、删除或调整 Pod 依赖，都要同步检查直接依赖和第二层以下间接依赖。不要只看当前 podspec 里写了什么，还要看它依赖的 Pod 又依赖了谁。
- 严禁用“互相依赖”解决编译问题。出现循环依赖时，要把公共部分下沉到更底层 Pod，或把内部实现移动到 `Support`，而不是继续堆 `dependency`。
- 调整本地管理的子 Pod、`Podfile`、`Podfile.deps`、`JobsPodspecKit.rb` 或 `post_install` / `post_integrate` 逻辑后，不能只以 `pod install` 不报错作为完成标准。必须额外确认 `Pods/Pods.xcodeproj` 能被 `xcodeproj` 正常打开、`PBXProject` 根对象没有被新文件引用覆盖、`xcodebuild -workspace ... -list` 能列出目标 Pod scheme，并且 Xcode 左侧 `Development Pods > Pod名` 能展开到 `Core` / `Support` / `Pod` / `Support Files` 等真实子项。
- 如果 Xcode 左侧能看到 Pod 名但点击后没有子项，优先怀疑 Pods 工程文件被脚本写坏或 UUID 冲突，而不是怀疑 CocoaPods 没装成功。重点检查 `Podfile` 里手动给 `Pods.xcodeproj` 增加文件引用、移动 group、固定 UUID、补 `Podfile.deps` / 报告文件引用等逻辑；这类增强只能做展示辅助，失败或冲突时应跳过，不能破坏 CocoaPods 生成的 `PBXProject`、root group 和 Development Pods 树。
- 本地子 Pod 的可用性回归至少覆盖三步：`pod install --no-repo-update`、`ruby -rxcodeproj -e 'p = Xcodeproj::Project.open("Pods/Pods.xcodeproj"); puts [p.root_object.isa, p.targets.map(&:name).grep(/Pod名/)].inspect'`、`xcodebuild -workspace 工程.xcworkspace -scheme Pod名 -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build`。如果改动会影响主 App Demo，还要编译主 App scheme。
- Demo 分类或主工程分类不要把试验能力全局污染到所有基础控件。尤其是 `UITableView` / `UICollectionView` 的 `reloadData` swizzle，禁止在分类 `+initialize` 里用 `self` 做交换；要么显式 opt-in，要么在 `+load` 中固定基类并 `dispatch_once` 交换一次，且默认状态必须 no-op。否则新 Pod 的普通 table 也会被 Demo 分类截获，出现点击进入二级页后崩溃、野指针或空数据视图误插入。
- `reloadData` swizzle 必须考虑重入保护。`UITableView` / `UICollectionView` 原始 `reloadData` 可能在 `layoutSubviews`、索引刷新、约束更新或第三方刷新回调里再次触发 `reloadData`；如果 swizzle 方法里直接 `[self jobsReloadData]` 而没有 associated flag 防重入，容易形成 `reloadData -> jobsReloadData -> layoutSubviews -> reloadData` 的递归，最终 `EXC_BAD_ACCESS` 或栈溢出。
- `UITableViewDataSource` / `UITableViewDelegate` 回调里不要为了比较来源而调用 `self.tableView` 这类懒加载 getter。尤其是在懒加载闭包中刚创建 table、尚未赋值给 ivar 时，系统可能立即回调 `sectionIndexTitlesForTableView:`、`heightForHeaderInSection:` 等方法；这时再进 getter 会重复创建 table。应使用 `_tableView` 这类 ivar 做身份比较，避免懒加载重入。

#### 1.5.1、`JobsDefineProperty.h` 属性宏覆盖

- `JobsOCDefs` 是最底层定义 Pod，`JobsDefineProperty.h` 里对系统冗长的 `@property` 做了 `Prop()` / `Prop_strong()` / `Prop_weak()` / `Prop_assign()` / `Prop_copy()` / `Prop_retain()` 简短定义。Jobs 自己维护的代码默认使用这些宏，不再新增系统冗长写法。
- 全局覆盖范围：项目主工程、非 `Pods` 文件夹及其下辖文件、`JobsByPods` 中除 `ManualByOCPods@Pods` 之外的本地管理 Pod。外援 Pod、`Pods/` 生成物、`JobsByPods/ManualByOCPods@Pods/` 下手动托管的第三方源码不做覆盖。用户明确指定旧工程“除了 `Pods` 文件夹下”时，按该工程实际外援边界执行。
- 限定范围内只要出现真实 `@property` 声明，就要替换为属性宏；不只处理 `strong` / `weak` / `assign` / `copy` / `retain`，`readonly`、`readwrite`、`class`、`getter=`、`nullable`、`nonnull` 等属性参数也要并入对应宏参数。属性之间如果没有注释，不保留空行。
- 执行覆盖后要确认使用 `Prop_*()` 的目标头文件直接导入属性宏头，不依赖 `.m`、PCH 或间接包含。新本地 Pod 优先按真实模块导入 `JobsDefineProperty.h` / `JobsOCDefs` 聚合入口；旧主工程如果实际宏头叫 `DefineProperty.h`，就必须写 `#import "DefineProperty.h"`，不要误写成 `JobsDefineProperty.h`。
- 如果某个独立 Pod 因宏不可见编译失败，优先补该 Pod 对 `JobsOCDefs` 的直接依赖和保护性 import，而不是退回系统 `@property` 写法。

### 1.6、Pod README 同步规则

- 每个本地 Pod 都应有自己的 `README.md`，因为每个 Pod 本质上都是相对独立的工程。
- 只要更新 Pod 的 `Core`、`Support`、podspec、依赖、资源、入口头、公开 API，就要同步更新该 Pod 的 `README.md`。
- Pod README 至少说明：用途、适用场景、目录结构、`Core` / `Support` / `Resource` 边界、公开能力、内部辅助能力、依赖关系、引用方式、资源说明、验证方式、风险说明。
- README 不要只写口号。它要能帮助后续排查：这个 Pod 为什么存在、哪些文件是公开的、哪些文件只是内部支撑、缺文件时应该回哪里找、修改依赖后要看哪个报告。

#### 1.6.1、OC 双工程文档与公共 CodeSnippets 强制同步

- OC 新工程根文档固定为 `/Users/jobs/Documents/Github/JobsOCBaseConfigDemo@ByPods/README.md`，框架文档固定为 `/Users/jobs/Documents/Github/JobsOCBaseConfigDemo@ByPods/OC工程项目框架配置方案@Jobs.md/OC工程项目框架配置方案@Jobs.md`；OC 老工程根文档固定为 `/Users/jobs/Documents/Github/JobsBaseConfig/JobsBaseConfig@JobsOCBaseConfigDemo/README.md`，框架文档固定为 `/Users/jobs/Documents/Github/JobsBaseConfig/JobsBaseConfig@JobsOCBaseConfigDemo/OC工程项目框架配置方案@Jobs.md/OC工程项目框架配置方案@Jobs.md`。
- Xcode 代码块目录固定为 `/Users/jobs/Library/Developer/Xcode/UserData/CodeSnippets`，是 OC / Swift 共用的 Xcode 资产，不属于任一单独工程。
- 每次调整任一 OC 工程中的 Jobs 自维护能力，不论改动位于主工程还是本地 Pod，也不论是新增、删除、重命名、公开 API、固定写法、Demo、资源、依赖或行为变化，都必须同步检查并更新两份根 `README.md` 和相关 `.codesnippet`；不能只更新实际落码的一侧。
- 但凡新增、删除、重命名或改变 `JobsOCDefs`、`JobsBlock`、`JobsMakes`、`JobsOCDSL`、`JobsModelDSL`、公共协议、宏、基础组件公开入口等底层自建 API，同一任务必须同步核对 OC 新老工程对应实现、公开头、相关 Pod / 根 README、宿主 Demo、两份框架文档和公共 CodeSnippets；某项没有对应内容时也必须完成检索，并在交付中明确说明无需修改。
- 两份根 README 的特色说明、能力矩阵、Demo 代码和使用边界必须保持同步。唯一允许的固定差异是工程形态：本地 Pod 工程只说明“相关功能由本地 Pod 管理”，主工程集成工程只说明“相关功能集成于主工程管理”。
- 每份 README 只陈述当前工程自身的管理形态，不提及、比较或引导读者查看另一份工程。同步校验时先把工程形态说明归一化，再比较对应章节，归一化后的内容必须一致。
- README 和 CodeSnippets 都不是 API 权威源。更新前必须以 Jobs 自维护源码、公开头和可运行 Demo 核对真实签名；若能力尚未在某一工程落地，不得先写成已支持，应先完成对齐或明确记录当前缺口。
- 代码块至少使用 `plutil -lint` 校验；涉及固定 API 或完整用法时，优先采用“全暴露写法”，让 README 的精炼 Demo 与代码块的可直接复用版本相互对应。

### 1.7、依赖报告与循环引用校正

- Pod 之间的上下依赖关系，会在每次 `pod install` 时通过脚本挂载加载：

  ```text
  ScriptsByPods/【MacOS】🔍查询Xcode工程依赖关系.command/【MacOS】🔍查询Xcode工程依赖关系.command
  ```

- 依赖报告生成物位于：

  ```text
  PodspecDependencyReport
  ```

- 修改或增删本地管理的子 Pod 依赖后，必须查看 `PodspecDependencyReport`，校正上下依赖关系，重点排查循环引用。
- 不能只看第一层依赖。有些风险藏在第二层、第三层或聚合 Pod 之后，需要沿报告仔细甄别。
- 能生成 `PodspecDependencyReport`，说明对应时间点 `pod install` 已执行成功，依赖关系至少在当时是正常的。后续排查“什么时候还正常”时，可以把报告生成时间作为关键节点。
- 如果依赖报告显示链路过长或边界混乱，优先通过下沉公共能力、迁移内部文件到 `Support`、减少公开头引用来修正，而不是继续扩大 `HEADER_SEARCH_PATHS`。

### 1.8、`ScriptsByPods` 脚本约定

- `ScriptsByPods` 存放适用于整个当前工程的脚本，其中一部分会挂载到 `pod install` 后自动运行。
- 因为 [**CocoaPods**](https://cocoapods.org/) 本身使用 [**Ruby**](https://www.ruby-lang.org) 生态，Pod 相关脚本优先使用原生 Shell + Ruby。除非确实没法低成本实现，不要引入 [**Python**](https://www.python.org)、Node.js 或其他额外运行环境。
- 能在 Shell 里稳定完成的路径处理、文件扫描、日志输出、交互确认，不要强行换语言。能在 Ruby 里直接读 podspec / Podfile / CocoaPods 上下文的，不要绕远路。
- 脚本仍然遵守本文 `二、MacOS Shell 脚本` 的基座规则：`# shell: zsh`、路径变量、彩色日志、README 阻塞、防误触、`main "$@"`、危险操作 `YES` 确认、静态检查。
- OC 项目的 `Podfile.deps` 只维护 `pod` 依赖定义，不直接执行外部脚本；外部脚本统一由 `Podfile` 调用，并且必须具备“脚本不存在就跳过、不影响 `pod install` 主流程”的保护。
- `Podfile` 中所有 `ScriptsByPods`、`.command`、`.sh`、`.rb` 脚本调用，以及 `load` 外部 Ruby 文件，都按可选增强处理：脚本缺失、`chmod +x` 失败、脚本执行失败时只打印告警并返回，不用 `raise` 中断。除非用户明确指定强制门禁，否则依赖报告、CodeGraph 等 post-install 脚本都不能阻塞主流程。

### 1.9、`return` 收口格式

- [**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) 代码里，只要 `return ...;` 紧跟在控制块、循环块、枚举块或其它内部代码块的右花括号 `}` 后面，就不单独成行，必须紧跟在上一行右括号后面写成 `};return ...;`。`}` 和 `return` 中间的分号不能省略，`}return ...;` 是错误写法。这条规则覆盖所有返回值，不只限于 `return self;`。
- 如果后花括号 `}` 所在行出现 `//` 或 `///` 注释，则不应用本节 `};return` 紧凑规则；因为在 [**Xcode**](https://developer.apple.com/xcode) 里 `//` 和 `///` 都是注释，下一行 `return ...;` 必须保持单独成行，不能提到注释行后面。
- 这条规则只作用于方法或 Block 内部的代码块收口；不要把方法实现本身的结束花括号、`@implementation` / `@end`、类或结构声明收口误改成 `};return`。
- 这条规则只应用 Jobs 自己写的代码；外援 Pod 不处理，包括 `Pods/` 目录和 `JobsByPods/ManualByOCPods@Pods/` 目录。
- 每次写 OC 代码或批量改 OC 文件后，如果触碰了 Jobs 自己维护的 `.m` / `.mm` 文件，必须在目标范围内扫描 `}\nreturn` 和 `}return` 残留；优先使用 `rg -n -U "\\}\\n\\s*return\\b|\\}return\\b" <目标路径>`，命中后按本节规则修正。用户点名某些模块时，必须覆盖用户点名的全部模块。

  ```objc
  -(JobsRetMutableParagraphStyleByCGFloatBlock _Nonnull)byDefaultTabInterval {
      @jobs_weakify(self)
      return ^__kindof NSMutableParagraphStyle * (CGFloat v) {
          @jobs_strongify(self)
          if (@available(iOS 7.0, tvOS 9.0, watchOS 2.0, visionOS 1.0, *)) {
              self.defaultTabInterval = v;
          };return self;
      };
  }
  ```

  ```objc
  -(NSString *)stableHash:(NSString *)value {
      uint64_t hash = 14695981039346656037ULL;
      const char *string = value.UTF8String;
      while (*string) {
          hash ^= (uint64_t)(unsigned char)(*string++);
          hash *= 1099511628211ULL;
      };return [NSString stringWithFormat:@"%llx", hash];
  }
  ```

- [**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) `*.m` 文件里，`@end` 必须和上方主内容区域之间空一行；不能把 `@end` 紧贴在上一个方法、实现块或右括号下面。

  ```objc
  -(JobsRetJobsBaseModelByJobsByBtnBlockBlock _Nonnull)byCloseBtnClickAction{
      @jobs_weakify(self)
      return ^__kindof JobsBaseModel *_Nullable(jobsByBtnBlock _Nullable data) {
          @jobs_strongify(self)
          self.closeBtnClickAction = data;
          return self;
      };
  }

  @end
  ```

### 1.10、Jobs DSL 总体思想

- Jobs 的 OC / Swift DSL 本质是一套命名和调用思想：用点语法 + 链式语法让对象从创建、配置、事件、装配到布局尽量一路设置下去，减少散落赋值和割裂的中间变量。
- `JobsMakes`、`JobsOCDSL`、`JobsModelDSL` 及相关自建 Pod 里的当前实现是 OC Jobs API 的唯一权威源；`~/Library/Developer/Xcode/UserData/CodeSnippets` 只是辅助使用记录，不能反过来定义 API。写代码前先核对封装实现，再参考代码块；两者冲突时以最新封装为准，并反哺修正代码块。
- Jobs 自维护的上层 OC 代码不直接调用已纳入 Jobs 封装体系的系统 API：创建走 `JobsMake`，属性/方法走 `JobsOCDSL` / `JobsModelDSL`，Block 走 `JobsBlock`，事件、装配、布局走已有 Jobs 入口。发现系统 API 还没有对应封装时，先在正确的自建 Pod / 类型层补齐封装，再回到调用方落地，不把裸调用当成长期兼容方案。
- Jobs 自维护调用方创建任何 Apple 系统类时都必须先进入 Jobs 创建 DSL，不以“这个类型还没有封装”为由保留 `Type.new`、`[Type new]`、`Type.alloc.init` 或 `[[Type alloc] init...]`。无入参构造复用或补齐 `jobsMakeType(^(Type *object) { ... })` 一类“创建对象 + 配置 Block”入口；裸 `new` / `alloc-init` 只允许存在于该入口的底层实现。
- 带初始化参数的系统类不把构造参数硬塞进通用 `jobsMakeType`。必须在真实系统类型的 Jobs 分类上提供类级 Block 初始化 DSL，按既有 `initByXxx` 语义命名，例如 `+(JobsRetNSUserActivityByNSStringBlock)initByActivityType`，调用方写 `NSUserActivity.initByActivityType(activityType)`；`[NSUserActivity.alloc initWithActivityType:activityType]` 只允许留在该类级 DSL 的实现内部。初始化完成后直接继续实例 `byXxx(...)` 链，不能再以局部变量重复起链。
- 系统类实例创建后，当前类型自己声明的属性、0 入参实例方法和 1 入参实例方法全部使用 `JobsOCDSL`：属性写入使用 `byProperty(value)`，无入参方法使用 `byAction()`，单入参方法使用 `byAction(value)`。除查询或明确终止动作外，Block 必须返回当前具体类型以维持一镜到底；缺入口时先补真实所有者 DSL 和 `JobsBlock` typedef，再改调用方。
- 构造审计覆盖 OC 新工程 Jobs 自建 Pods 与应用层、OC 老工程 Jobs 自维护主工程和全部 Demo；排除 `Pods/`、`ManualByOCPods@Pods/`、`PodsManual/`、生成代码、第三方和所有权不明源码。`[super init...]` / `[self init...]`、初始化方法实现本身、系统固定生命周期、系统回调已经交付的实例，以及 Jobs 创建 DSL / 工厂的底层实现属于明确边界，不得机械替换。
- 全量构造审计运行 `scripts/audit_oc_system_class_construction.rb --sdk-root "$(xcrun --sdk iphonesimulator --show-sdk-path)" <OC 新 Pods 与应用根...> <OC 老工程根...>`；输出的 `zero-argument` 必须进入 `jobsMakeType(config Block)`，`parameterized` 必须进入真实类型 `initByXxx(arguments)`。`factory_hits` 只统计工厂底层允许保留的原生构造，不能拿它抵消调用方 `issues`；最终要求调用方 `issues=0`。
- 对已经能看到 `JobsMakes` 且已有明确类型工厂的无参构造，可先运行 `scripts/migrate_oc_zero_argument_system_construction.rb <源码根...>` 干跑，再加 `--apply`；脚本只迁移白名单类型，不猜测带参初始化器，也不跨 Pod 自动补依赖。应用后必须二次干跑到 `replacements=0`，再由编译器核对 Block 参数类型和公开头可见性；能把后续配置并入创建 Block 时，继续人工收成同一 Block 内的一条 `byXxx` 链。
- 当前真实归属要分清：`jobsMakeView`、`jobsMakeLabel`、`jobsMakeImageView`、`jobsMakeTextField`、`jobsMakeCollectionView`、`jobsMakeScrollView` 等通用工厂位于 `JobsMakes`；`jobsMakeButton`、`UIButton.jobsInit()` 与 `jobsResetBtn*` 跨新旧按钮管线入口当前由 `JobsByOCPods` 的 `UIButton+SimplyMake` / `UIButton+UI` 承接，不得误写成 `JobsMakes` 已经导出按钮工厂。
- 值类型、路径、动画和静态构造同样受封装规则约束：字体走 `JobsOCDefs` 的 `UIFontSystemFontOfSize`、`UIFontSystemFontOfSizeAndWeight`、`UIFontWeight*Size`、`UIFontMonospaced*Size`；颜色走 `RGB_COLOR` / `RGBA_COLOR` / `jobsMakeCor2` 等当前封装；贝塞尔路径走 `jobsMakeBezierPath` 或 `UIBezierPath.byBezierPathWithRect/OvalInRect/CGPath/RoundedRect/RoundedCorners/ArcCenter`；视图动画与转场走 `UIView.jobsAnimate/jobsAnimateWithCompletion/jobsAnimateWithOptions/jobsAnimateWithSpring/jobsTransition/jobsTransitionFromViewToView`。调用方不得因这些 API 是类方法或值工厂就继续直调 UIKit。
- `JobsMakes` 当前还负责 `jobsMakeAction`、`jobsMakeMenu`、`jobsMakeMenuByConfiguration`、`jobsMakeContextMenuConfiguration`、`jobsMakeNib`、`jobsMakeBarButtonItemByTitle/ByImage/BySystemItem`、`jobsMakeImage` 等静态构造入口；空贝塞尔路径使用 `jobsMakeBezierPath(nil)`。新增或升级工厂时，以公开头真实签名为准，同时更新直接依赖、README 和 CodeSnippets。
- `UIButton+SimplyMake` / `UIButton+UI` / `UIButton+UIControlState` 在部分 Pod 的 `Support` 中仍有历史副本时，以 `JobsByOCPods/Core/UIKit/UIButton` 当前实现核对 API；canonical 新增、修正按钮 API 时，所有仍参与编译的 Support 副本必须同步并做接口 / 行为对齐，但调用方不得绕过聚合头直接引用私有 `Support`。轻量 Pod 若因循环依赖不能直接依赖 canonical、但已安全依赖 `JobsBaseUI`，可通过其公开聚合头使用 `jobsMakeBaseButton` 并继续用 `JobsOCDSL` 配置；若必须保留 `jobsResetBtn*` 的跨管线语义，则先下沉 / 统一导出封装再调用。不允许退回 `[UIButton new]`、`buttonWithType:`、`setTitle:`、`setImage:` 等系统 API。
- 上述限制作用于调用方；`JobsMakes` / `JobsOCDSL` / `JobsModelDSL` 等封装的底层实现为了承接系统管线可以调用系统 API，但不得从实现层反向复制裸调用到业务层。每次新写或修改 OC 代码后，都要按同一映射反扫整个 OC 自维护范围，不只修被点名文件。
- Jobs 二次封装 API 不得因底层 Apple API 过期就机械复制 `API_DEPRECATED` / `API_DEPRECATED_WITH_REPLACEMENT` 到自己的公开声明，不得让上层调用 Jobs API 仍出现系统 deprecated 警告。在封装实现内用 `@available` 选择新 API 与旧系统回退；确实无法避免的旧 API 警告只能在最小实现语句上用 `SuppressWdeprecatedDeclarationsWarning(...)` 收口，不向调用方外溢。
- 调用方不得围绕同一个 Jobs 封装再补 `@available` 分支、重复调新旧 API 或自行压警告；发现这类补丁时，先修正 Pod / 旧工程对应封装，再删掉上层兼容分支，并在 OC 新工程、OC 老工程与 Swift 对应封装中做同语义回归。
- 只有 Jobs 公开 API 自身已无法维持语义、决定废弃，且已提供可用的 Jobs 替代入口时，才能对外标记 deprecated；message 必须指向 Jobs 替代 API，不能只复制 Apple 的底层提示。
- Jobs DSL 的第一性是对系统 API 的二次封装。OC / Swift 两侧允许因语言、Block / closure、范型、可选值、返回类型等差异采用不同实现形态，但判断是否应该补 DSL 时，永远先看对应系统 API 是否属于当前类型的覆盖范围，而不是先看另一侧代码是否已经存在同形态实现。
- DSL 命名统一使用 `by` + 首字母大写的属性名、单参数方法名或一个参数语义名。例如 `text` 对应 `byText(...)`，`font` 对应 `byFont(...)`，`addSubview:` 这类动作可按既有封装写成 `addOn(...)` / `byAddTo(...)` 等项目内统一语义。
- 遇到 `BOOL` 属性且系统名以 `is` 开头时，DSL 名省略 `is`，例如 `isSelected` 写成 `bySelected(...)`，`isEnabled` 写成 `byEnabled(...)`，保持 Swift / OC 两侧命名平行。
- UIKit 状态和可见性也按属性所属层收口：`UIControl` / `UIButton` 使用 `bySelected(...)`、`byEnabled(...)`、`byHighlighted(...)`，选中态切换使用 `byToggleSelected()`，状态读取使用 `jobs_isSelected` / `jobs_isEnabled` / `jobs_isHighlighted` / `jobs_effectiveState`；`UIView` / `CALayer` 使用各自的 `byHidden(...)`。系统代理已存在 Jobs DSL 时统一走 `byDelegate(...)`，例如 `UINavigationController` 与 `UNUserNotificationCenter`。`UINavigationBarAppearance`、`UITabBarAppearance` 的公共底色能力统一复用父类 `UIBarAppearance.byBackgroundColor(...)`，不在子类或调用方重复裸赋值。
- DSL 覆盖范围不只限于 Apple 原生 API。Jobs 自建 Model、配置对象、业务基础对象也要按同一套思路封装；OC 侧重点体现在 `JobsModel` 的 `JobsModelDSL`，例如 `UIViewModel`、`UITextModel`、`UIButtonModel` 等大 Model / 子 Model 都应支持链式配置。
- 对系统 API 进行二次封装成 JobsOCDSL 时，覆盖标准是当前类型自己声明的全部属性、0 个入参数方法、1 个入参数方法。父类已有能力放在父类 DSL，不在子类重复铺开；有返回值的方法默认也要收口为可继续链下去的主对象，除非该能力天然是查询或明确的终止动作。
- OC 因为 Block 类型繁多，所有可复用 Block typedef 必须集中放入 `JobsBlock` 管理；新增 DSL 前先查 `JobsBlock` 是否已有可复用类型，缺失再补到合适的 `JobsBlock.h`、`ReturnByCertainParametersBlock.h` 或其它既有分类头里，不在 DSL 头文件里私自散落 typedef。
- OC 项目里系统 API DSL 产生的相关 Block 定义全部收进 `JobsBlock`：按返回值和入参签名复用或补齐 typedef，DSL 头文件只引用既有 Block 类型，不本地声明临时 Block。
- `JobsBlock` 是全局 Block 服务，不只服务 DSL。整理 `JobsBlock` / `ReturnByCertainParametersBlock.h` 时，优先按返回值相同归为一组，同组第一行用 `/// 返回类型` 标注；`#pragma mark ——` 只写大类名，不写 `DSL` 字样。遇到外源 Pod 的 Block 定义，大类名写 Pod 名，例如 `#pragma mark —— ReactiveObjC`，再用 `/// RACSignal`、`/// RACDisposable` 这类返回值标注细分。
- 判断 Block 是否重复时，只看返回类型和入参类型；如果两个 typedef 的返回类型和入参类型完全一致，只是 Block 名不同，它们就是同一个 Block。新增调用优先复用现有 typedef；历史兼容名需要保留时，用 `typedef 已有Block名 兼容Block名;` 做别名，不再重复写一遍 `(^BlockName)(...)` 签名。
- `JobsBlock` 里的 Block 类型命名一律把 `Return` 缩写成 `Ret`，例如 `JobsReturnIDByAppLanguageBlock` 必须改成 `JobsRetIDByAppLanguageBlock`。修改 typedef 名后必须全局搜索并同步替换所有调用、属性、方法签名和文档引用；不要只改 `JobsBlock.h`。
- 默认不要新定义 Block。确实缺失时，先全局查 `JobsBlock` 现有类型和别名，确认没有同签名可复用项后，再补到对应返回值分组下，并同步检查公开头 import、podspec 依赖和 README。
- 新增 OC DSL 时要同时考虑公开头、podspec 依赖、README 和调用方 import 边界；`JobsOCDSL` / `JobsModelDSL` 负责链式分类，`JobsBlock` 负责 Block 类型，`JobsMake` 负责创建入口，职责不能混写。
- OC 链式 DSL 的 Block 必须返回可继续链下去的对象；除明确的终止动作外，不写只执行副作用却返回 `void` 的 DSL。Block typedef 优先返回 `__kindof 当前类 * _Nullable` 或主对象类型，方法实现里设置完属性后必须 `return self;`，否则点语法链会在这一节断掉。
- OC / Swift 两侧面对同一个 Apple API 或同一个 Jobs 自建模型语义时，应尽量保持 DSL 名称、参数语义、调用顺序平行；发现一侧缺失时，优先补齐缺失侧，而不是在业务代码里回退到裸赋值。
- “一镜到底”（亦称“一链到底”）覆盖 OC 应用侧所有支持 Jobs 点语法 / 链式语法的对象，包括但不限于 View、Control、Layer、Cell、Model、配置对象、请求对象和业务基础对象，不能只在 `UIButton` 上执行。在同一个 `jobsMakeXxx`、懒加载 getter、配置闭包或连续配置语义中，主对象变量名只能作为整条链的起点出现一次；后续必须继续 `.byXxx(...)`、`.jobsXxx(...)` 或其它返回当前对象的点语法，不得再出现第二段 `object.byXxx(...)`、`object.method(...)`、`object.property = ...`。
- 子对象配置不能用 `object.child.xxx` 另起一条链。优先提供并使用 `byXxxBlock(...)` 这类回调 DSL：主链进入子对象配置 Block，子对象在 Block 内同样只出现一次，Block 结束后返回主对象继续原链。若现有 DSL 返回 `void`、降级为父类或无法从子对象回到主链，先在属性真实归属层补齐“返回当前具体对象”的 DSL 或父子对象 Block DSL，再改应用侧；不得以“API 暂时不够”为由保留多段接收者。
- 真正的查询取值、控制流分支、系统 / 第三方回调中无法形成同一主对象链的参数，以及明确的终止动作可以独立表达；终止动作必须放在链尾。连续存在多个返回 `void` 的终止动作时，每个动作分别以真实接收者起句，例如两个 `JobsNotificationCenter.Remove(...)`，不得因视觉上想“一链到底”而把第二个动作接到第一个 `void` 返回值上。Masonry 的 `MASConstraintMaker` 等外部构建器按其原生语义逐条约束，不为追求表面单链强行拼接。除此之外，不以视觉分组、空行、注释或对象类型不同为由拆成第二个接收者。
- 全量回归时运行 `scripts/audit_oc_application_chains.rb <应用层源码目录...>`，先定位同一配置 Block 中重复起链的参数。同一 Block 参数在同一层级连续出现的、无嵌套代码块的 DSL，可先用 `scripts/collapse_oc_block_parameter_chains.rb --apply <源码目录...>` 收成一条链；但脚本只能证明语句相邻和括号平衡，不能证明 Objective-C 静态返回类型。应用前必须核对链上每个 selector 的真实返回值：子类专属 DSL 在前，会降级到父类的通用 DSL 在后；`byAdd`、`actionRetIDByGestureRecognizerBlock`、`actionObjBlock` 等返回 `void` / 固定宽类型的终止点以精确 selector 豁免，不得继续接链。禁止跨分支、嵌套 Block、异步回调或 `@jobs_weakify` / `@jobs_strongify` 生命周期边界拼链；应用后必须立即编译对应 target，以编译器暴露类型降级。收口后重跑审计并结合上述豁免逐项判断。扫描必须覆盖 OC 新工程和 OC 老工程的 Jobs 自维护应用层，排除 `Pods/`、`ManualByOCPods@Pods/`、`PodsManual/`、生成代码和他人源码；命中一种对象后继续反扫其它对象类型，不能只修用户举例的控件。

  ```objc
  button
      .jobsResetBtnImage(normalMenuImage)
      .selectedStateImageBy(activeMenuImage)
      .imageForStateBy(activeMenuImage, UIControlStateSelected | UIControlStateHighlighted)
      .byLayer(^(__kindof CALayer *layer) {
          layer
              .byShadowOpacity(0)
              .byShadowRadius(0)
              .byShadowOffset(CGSizeZero);
      })
      .bySize(CGSizeMake(32, 32));
  ```
- 父子类 DSL 调用顺序按 `1.10.2` 执行；这是编译硬约束，不是排版偏好。链条必须按静态类型从具体到通用排序：`UIButton` / `UILabel` / `UITextField` / `UITableViewCell` 等子类专属 DSL 在前，`UIControl` / `UIView` / `NSObject` 等父类通用 DSL 在后；任何返回父类的 DSL 只能放在链尾，或其后只继续调用该父类仍可见的 DSL。如果父类 DSL 会导致返回类型降级，应补充能返回主对象的 block DSL 或当前层 DSL，而不是拆成第二个接收者调用。
- 编译出现 `Property 'xxx' not found on object of type '__kindof UIView *'`、`'__kindof UIControl *'` 或类似“子类属性在父类返回值上不可见”的错误时，第一检查项就是链式调用顺序：把报错的子类 DSL 前移到第一个返回父类的 DSL 之前，再检查中间是否混入返回其它对象、`void` 或查询值的终止动作。不得通过强转、重复起链或退回裸系统 API绕过。
- 返回 `CGRect` / `CGPoint` / `CGSize`、标量、查询对象、其它非主接收者或 `void` 的 Block DSL 都是终止动作，必须放在链尾，不能把后续对象 DSL 接在其返回值上。需要连续修改同一对象的 frame 时，优先改用返回主对象的一次性入口，例如把 `view.resetOrigin(...).resetSize(...)` 收成 `view.byFrame(CGRectMake(...))`；确实没有等价组合语义时，分别执行终止动作，不能为了表面单链制造错误类型。
- `CAKeyframeAnimation`、`CAShapeLayer`、手势子类等多层继承对象同样执行“最具体类型在前”：先调用 `byValues/byCalculationMode`、`byPath`、`byDirection/byRotation` 等子类 DSL，再调用 `byKeyPath/byFrame` 等中间父类 DSL，最后调用 `byDuration/byDelegate/byTarget` 等更通用 DSL。自动合链脚本不得改变这一静态类型拓扑；编译命中类型降级后，要反扫所有同类链，不只修首个文件。
- 在本地 Pod 里写 `UITableView`、`UIButton`、`UITextField`、`UILabel` 等 JobsOCDSL 链时，编译通过不是唯一目标，还要检查链条类型是否中途被父类 DSL 降级。例如 `UITableView` 先调 `bySeparatorStyle`、`byDelegate`、`byDataSource`、`byShowsVerticalScrollIndicator` 等本层 / `UIScrollView` 层能力，再调 `byBgColor`、`addOn`、`byAdd` 等 `UIView` 层能力；不要把父类 DSL 插在中间导致后续子类 DSL 失效。
- 写 DSL 示例、Xcode 代码片段和工程配置文档时，点语法以行为最小单位提行书写，方便按行删除或注释。跟在某一行 DSL 后面的解释统一用两根双斜杠 `//`；单独成行的段落说明统一用三根双斜杠 `///`。
- 写 Objective-C 代码、DSL 示例、懒加载 getter 或常见 UI 配置前，先核对实际封装 API，再查看 `~/Library/Developer/Xcode/UserData/CodeSnippets` 下是否已有可复用的 Xcode 代码块；代码块未过时时，优先沿用其命名、占位符和链式组织方式。
- 如果本轮更新了 OC 侧封装、DSL、JobsMake、Block typedef 或固定写法，必须同步检查并反哺 `~/Library/Developer/Xcode/UserData/CodeSnippets` 里的相关 `.codesnippet`，让代码块示例跟真实 API 保持一致；不要让片段继续传播旧封装、旧命名或散落赋值写法。
- `~/Library/Developer/Xcode/UserData/CodeSnippets` 里的 OC 代码片段默认采用“全暴露写法”：常用配置、事件、装配、约束和兼容分支尽量完整列出，让使用者按需求删除或注释，不让使用者临场补 API。片段必须优先传播 Jobs 封装、JobsMake、JobsOCDSL、JobsModelDSL 和聚合头边界，不能为了示例短而退回裸系统 API。
- 每次完善或纠错 OC 代码片段后，必须按同一写法反扫 OC 新工程和老工程应用层，重点查 `rowHeight =`、`contentInset =`、`contentInsetAdjustmentBehavior =`、`backgroundColor =`、`delegate =`、`dataSource =` 等已有 DSL 覆盖的裸赋值。命中 Jobs 自己维护的主工程或本地 Pod 代码时改成链式；外援 `Pods/`、`ManualByOCPods@Pods/` 和确认为第三方源码的目录不处理。
- DSL 示例颗粒度必须细：一个属性、一个状态、一个事件、一个装配动作分别独立成行，不把标题、颜色、字体、图片、内边距等多个意图合并到一行。若同一能力同时存在单参数和二参数写法，默认首选单参数写法；二参数写法只在确实需要表达 `UIControlStateSelected`、`UIControlStateDisabled`、`UIControlStateHighlighted` 等非默认状态差异时使用。

#### 1.10.1、0 / 1 入参功能方法统一 Block 化

- 把 OC 新工程 `JobsByPods/` 下 Jobs 自建 Pod 作为功能权威源，并同时覆盖 OC 新工程应用层 / 所有 Demo 页面、OC 老工程的主工程集成代码及其 Demo。范围包含公开与私有的 Jobs 功能方法，不能只改 Pod 或只改底层；继续排除 `Pods/`、`ManualByOCPods@Pods/`、`PodsManual/`、生成代码、第三方和所有权不明源码。
- Jobs 自定义功能方法只要原签名为 0 个或 1 个入参，就改为“无入参方法返回 Block”的形态：原 0 入参方法调用由 `[object action]` 改为 `object.action()`，原 1 入参方法调用由 `[object action:value]` 改为 `object.action(value)`。方法名保留原第一段 selector 名，声明、实现、协议、调用点、Demo、README、工程文档和 CodeSnippets 必须一次同步，不保留半套旧调用。普通 1 入参方法必须直接替换原声明和原实现，不得自动保留 `-(void)action:(id)value` + Runtime 转发薄包装；只有能用协议、SDK 头、Target-Action、selector 字符串或不可修改消费方证明的真实 ABI 契约才保留 trampoline。
- 任何“方法返回 Block”的声明与实现都必须在返回类型后显式标注 `_Nonnull`，不得只依赖 `NS_ASSUME_NONNULL_BEGIN`。真实可空的 Block 属性 getter 是例外：属性必须同步声明为 `nullable`，getter 保持 `_Nullable`，不得为过编译把可空属性伪装成非空功能方法。
- 这类改造只改变 API 表述，不改变功能内核：把原方法体完整迁入返回的 Block，Block 入参类型等于原方法入参类型，Block 返回类型等于原方法返回类型；原方法返回 `void` 时使用对应 `jobsByXxxBlock` 并视为终止动作，原方法返回当前对象时才继续返回当前对象，不得为了表面链式擅自改变查询值、错误值或业务返回值。
- 实例方法返回的 Block 默认在外层 `@jobs_weakify(self)`、Block 内 `@jobs_strongify(self)` 后执行原逻辑；原有提前 `return`、可用性分支、副作用顺序、默认值和异常边界保持不变。Block 内 `self == nil` 时的返回值必须与原来给 `nil` 接收者发消息的结果等价：对象返回 `nil`，标量 / 结构体返回零值，`void` 直接结束。类方法按真实捕获需求处理，不机械制造无意义的弱引用。
- 出现 `__weak typeof(self) weakSelf = self;` 和 `__strong typeof(weakSelf) self = weakSelf;` 时，统一改为 `@jobs_weakify(self)` / `@jobs_strongify(self)`。使用者必须通过下面的完整双通道引入 `JobsDefines.h`，不得只写单路 import。该引入只能放在对应 `.h` 的 import 区，`.m` / `.mm` 不得出现这段；无同名头时先定位真实对外头或为 Jobs 自建源补齐合法头，不得因为方便把宏头留在实现文件：

  ```objc
  #if __has_include(<JobsOCDefs/JobsDefines.h>)
  #import <JobsOCDefs/JobsDefines.h>
  #else
  #import "JobsDefines.h"
  #endif
  ```

- `JobsBlock` 自身是 `JobsOCDefs -> JobsBlock` 的底层依赖端，不得为使用宏反向 import `JobsOCDefs` 形成循环依赖；因此 `JobsBlock` 内部实现是唯一固定例外，可保留显式 `__weak` / `__strong`。其它 Jobs 自维护 Pod、应用层和 Demo 不得借用这个例外。
- 系统 / 框架 / 不可修改消费者必须按原 selector 调用的契约入口不得直接改签名，包括生命周期、父类覆写、协议 / delegate / dataSource 必选方法、属性 getter / setter、Target-Action、通知 selector、KVC / KVO、归档复制、Runtime / swizzle 入口以及仍在编译的第三方调用。语义安全时保留最小契约 trampoline，把原功能内核完整迁入不与属性 / 系统 selector 冲突的 Jobs Block 门面；0 参契约因无法同名重载，统一使用 `jobsXxx` 新名，1 参契约存在属性、协议或外部同名风险时也使用 `jobsXxx`。属性 getter、协议 getter 与跨模块公开 getter 必须在声明、实现和所有协议侧共同保留原返回类型，另设 `jobsXxx` Block 门面；严禁协议声明返回 Block、实现却仍返回对象或标量，否则编译可能成功但运行会把对象 / 标量当 Block 执行。`sharedManager` / `destroySingleton` 是跨协议、宏和第三方消费者的固定 ABI，原入口固定保留，Jobs 调用统一走 `jobsSharedManager()` / `jobsDestroySingleton()`；`AppToolsProtocol` 的 `getViewModel` / `getButtonModel` 存在不可修改实现，原 getter 固定保留，Jobs 自有实现另设 `jobsGetViewModel()` / `jobsGetButtonModel()` 门面，而按协议持有的通用接收者继续调用原 getter；已经以 `jobs` 开头却与旧分类冲突的入口使用可检索后缀（如 `jobsGetCurrentViewControllerBlock()`）承载 Block 门面。普通 Jobs 自有方法不得以“兼容”为由永久保留旧实现；迁移期薄包装必须在无外部契约后删除。
- 属性 setter 尤其不能把 `setFrame:`、`setSelected:`、`setState:`、`setViewModel:` 直接改成无冒号 Block 方法；否则 UIKit、KVC/KVO、点赋值和协议消费者仍发送原 selector，却绕过 Jobs 自定义内核。正确结构固定为原 `setXxx:` trampoline + `jobsSetXxx` Block 门面，Block 内调用父类 setter 时继续写 `[super setXxx:value]`，不得写 `super.setXxx(value)`。存量误迁移统一用 `scripts/restore_oc_fixed_property_setter_facades.rb` 按审核后的计划表恢复，并反扫重复的 `setXxx:` 实现与错误的 `@selector(setXxx)` 自转发。
- 固定 ABI trampoline 获取 Block 门面时必须非虚调用地绑定当前 `@implementation` 的具体实现：实例方法通过 `JobsBlockInstanceMethodIMP(ClassName.class, @selector(jobsXxx))` 取 IMP，类方法通过 `JobsBlockClassMethodIMP(ClassName.class, @selector(jobsXxx))` 取 IMP，再传入当前 `self` 同步获取 Block。两个 Runtime helper 统一定义在 `JobsBlockDef.h`，同时兼容 `NSObject` 与 `NSProxy` 根类体系；不得直接依赖 `instanceMethodForSelector:` / `methodForSelector:`。禁止在 trampoline 里写 `self.jobsXxx`；否则子类 Block 内的 `[super lifecycleMethod]` 进入父类 trampoline 后，会因动态派发重新回到子类 `jobsXxx`，形成生命周期递归、Block 重复 copy 和栈溢出。存量与新生成代码统一用 `scripts/ensure_oc_fixed_block_trampoline_dispatch.rb` 审计收口。
- 一参数方法 `foo:` 收成无冒号 Block getter `foo` 后，Block 内核如果仍需调用系统、框架或保留的固定 selector，必须写 `[self foo:value]`；严禁写 `self.foo(value)`，后者会重新取得当前 Block 并调用自身，形成无限递归和栈溢出。迁移后必须运行 `scripts/restore_oc_recursive_block_kernel_dispatch.rb --apply`，只按脚本中已核对的 Foundation / UIKit / 框架固定 selector 白名单收口；普通 Jobs 方法在 Block 内可能存在有终止条件的同步递归或切到主线程后的异步自调用，不能仅凭“当前 Block 方法名与点调用同名”改回冒号消息。零参数、顶层多参数和白名单外命中必须人工确认固定契约。
- Jobs 自建 Block getter 严禁按名字猜测为固定 selector 并收入消息发送还原白名单；例如 `jobsSelectorBlock`、`onImageLoaded` 的调用必须分别保持 `receiver.jobsSelectorBlock(block)`、`receiver.onImageLoaded(image)`，不能生成不存在的 `jobsSelectorBlock:` / `onImageLoaded:`。若历史脚本已生成 `[receiver getter:argument]`，必须按配对括号完整恢复为点语法 Block 调用，并以真实声明、编译和冷启动共同验证，避免“头文件未声明消息但警告被 `-w` 隐藏”继续演变为运行期 `unrecognized selector`。
- Block Getter 之间不得形成无终止条件的跨 Getter 互调或别名环，例如 `byA` 的 Block 内执行 `self.byB(value)`，而 `byB` 又 `return self.byA`；这种表达会依赖分类加载顺序，最终以双节点递归栈溢出。主入口的 Block 内核必须直接读写底层系统属性或调用真实契约 selector，别名 Getter 才可以单向 `return self.byMain`。迁移后必须运行 `scripts/audit_oc_block_getter_cycles.rb`，新工程 Pods、新工程应用 / Demo 和老工程均必须 `cycles=0`；已确认有状态终止条件的合法状态机环只能以 selector 集合精确收入脚本白名单，不得按文件或目录整体跳过。
- 同一进程镜像内，同一类的同一种类（`+` 或 `-`）不得由两个 Category / 实现重复提供同名 Block Getter。重复实现即使编译通过，也会让最终 IMP 取决于链接与 Category 加载顺序，不能以“当前两个内核相同”豁免；应把声明和实现收回唯一的真实类型 DSL，AutoSupplement 只保留具体 DSL 尚未覆盖的 selector。迁移后运行 `scripts/audit_oc_duplicate_category_block_getters.rb <Jobs 自维护源码根...>`，新工程和老工程都必须 `duplicate_getters=0`。已确认完全同内核的存量重复，可先用 `scripts/deduplicate_identical_oc_block_getters.rb` 干跑；默认只在同一宿主 / 同一本地 Pod 内消重。跨 Pod 使用 `--cross-module` 前必须先把公开头、podspec 依赖和调用方 import 收到真实所有者，禁止只删实现、依赖宿主 App 偶然链入另一份副本。
- `dealloc` / `.cxx_destruct`、`+load`、`+initialize` 以及 `init` / `new` / `alloc` / `copy` / `mutableCopy` 方法族是固定安全例外：它们涉及 ARC 所有权、对象尚未初始化或已经析构、Runtime 装载顺序，不能为了形式统一创建捕获 `self` 的 Block 或搬移内核。审计中必须以 `runtime-contract` / `objc-family` 明确列出，不能伪装成已 Block 化；只有存在经过编译和生命周期验证的专用方案时才单独处理。
- `dealloc` 内也不得调用会在 getter 外层执行 `@jobs_weakify(self)` 的 Block 门面；对象进入析构后再注册弱引用会触发 Objective-C Runtime fatal。析构清理保留不捕获 `self` 的传统入口，普通路径另设 `jobsXxx` Block 门面；`dealloc` 直接调用传统入口，不能写成 `self.jobsXxx()`。
- Block 调用不继承 Objective-C “向 `nil` 发消息安全返回零值”的语义：`nullableReceiver.jobsAction()` 会先从 `nil` 取得空 Block，再调用空函数指针而 `EXC_BAD_ACCESS`。凡接收者可能为空，必须先以局部变量或条件判断守卫，再调用 Block；守卫后的行为要与迁移前 `[nullableReceiver action]` 等价。
- `UIAppearance` 返回的是消息转发代理，不是实际 UIKit 实例；禁止对 `UIButton.appearance`、`UITabBar.appearance` 等代理调用返回 Block 的 Category getter，例如 `UITabBar.appearance.byStandardAppearance(value)` 会在 `NSMethodSignature` / `forwardInvocation:` 链路把返回值解释错并崩溃。公开调用仍通过 `jobsApplyXxx(...)` 这类 Jobs Block 门面表达，门面内核必须向 appearance 代理发送真实系统 setter（如 `[UITabBar.appearance setStandardAppearance:value]`）；该内核属于系统代理固定 ABI 例外，不继续 Block 化。
- 契约门面的 Block 返回类型必须保持原方法返回类型，Block 入参必须保持原方法唯一入参类型；trampoline 只获取并同步执行 Block，不插入异步、缓存、重排、副作用或业务兜底。Block 内继续保留原来的 `super` 调用、提前返回、可用性判断与异常路径；原实现依赖 `_cmd` 时要固定为原 selector，避免迁入 `jobsXxx` 后语义漂移。
- 所有 Block typedef 继续集中在 `JobsBlock`：先按“返回类型 + 入参类型”复用现有定义，确实缺失再补；不在业务 Pod、`JobsOCDefs` 或分类头里散落同签名 typedef。底层依赖必须保持单向，先拆除 `JobsBlock` 对使用方的反向类型依赖，再让需要 Block API 的 Pod 直接依赖 `JobsBlock`，禁止用循环 Pod 依赖换取头文件可见。
- 上层功能代码的单行对象属性写入不得出现 `receiver.property = value`，必须改为 `receiver.byProperty(value)` 或实际所有者上的 `jobsSetXxx(value)` Block 门面；缺 DSL 时先在属性真实归属类型补齐，再改调用点。只豁免 DSL / 属性 setter 自身的底层实现、结构体字段写入、系统要求的固定 ABI 和经核对无对象 DSL 语义的纯局部计算；不得把 `center.y = ...` 这类 C 结构体字段误改成对象 Block。
- `audit_oc_property_assignment_dsl.rb` 的命中只是候选：只有同时解析出接收者真实静态类型、该类型或其父类 / Category 真实声明了目标 Block，且调用 target 的头文件依赖能看到该声明时，才能改写。禁止仅凭“全工程存在同名 `byXxx`”运行全局 `--apply`；无法证明接收者类型或声明可见性时必须标成 `unverified-receiver`，留给编译器或人工确认，不得自动改写。`JobsOCDSL`、`*+DSL.m` 和属性 setter 的底层实现必须保留一次真实 setter / 赋值，防止 `byBackgroundColor` 误套到 `UIView`、`UILabel.byValue` 被误当成任意 Model 的 `byValue`，或 DSL 内核自调用递归。
- 点语法链中间步的 Block 返回类型必须保持当前真实接收者类型；例如 `SZTextView` 调用返回 `UITextView *` 的父类 DSL 后，会丢失 `byPlaceholderColor` 等子类 API。出现此类链条降级时，应在真实子类拥有者的 DSL 中补同名、返回子类 `Self` 的入口，并保持一镜到底；不得通过拆链、重复书写主接收者或把子类专属 DSL 塞进无关 Category 来绕过类型错误。
- 把 `nullableReceiver.property = value` 改成 `nullableReceiver.byProperty(value)` 会改变 Objective-C 的 nil 语义：给 nil 发 setter 消息安全，但先从 nil 取得 Block 再执行会触发 `EXC_BAD_ACCESS`。任何可能为空的中间接收者（尤其 `mj_header`、`mj_footer`、可选 delegate / view / layer）都必须先保存为静态类型局部变量并判空，再调用 Block DSL；不得仅因声明未标 `_Nullable` 就假定运行期一定存在。冷启动若出现地址接近 `0x10` 的 Block 调用崩溃，优先用 LLDB 核对这类 nil Block 执行，并把修复同步到 OC 新、老对应实现。
- 调用点改成 `receiver.byXxx(value)` 前，必须先把 typedef、所有者声明和实现纳入接收者所在的真实 Pod / App target，再以该 target 的编译结果验证。“方法在另一个类、另一个 Pod 或 PCH 间接可见”都不是当前接收者可调的证据；编译出现 `property 'byXxx' not found`、`called object type ... is not a function` 时，优先追溯静态类型和当前 target 的公开头，不用 `id` / 强转或无关 Category 掩盖。
- 一个 Block API 只有同时满足“`JobsBlock` 中的 typedef + 消费 target 真实可见的所有者声明 + 已加入链接 target 的唯一实现 + 调用点”才算闭环。任一段缺失都不能用 PCH、`-w`、偶然链入的其它 Pod 或 Runtime 动态派发掩盖；必须至少经过头文件可见性编译、链接和冷启动三层验证。私有辅助类也要保持全局唯一类名；OC 老工程把两套功能同时编入一个 target 时，不得因批处理将 `_FooEntry` / `_BarEntry` 合并成同名实体，否则会产生 Objective-C class / ivar 重复符号。
- 类属性必须保持类级语义：`Prop_* (class)` / `@property(class, ...)` 的写入门面固定生成为 `+byXxx`，对应 setter 声明也是 `+setXxx:`，Block 返回 `Class _Nullable` 并 `return self`；禁止生成 `-byXxx` 或返回实例对象。扫描器必须同时记录属性的 `class` 标记和方法的 `+` / `-`，不能只按 selector 名判断“已经存在”。
- 生成 DSL 前先展开接收者宏和别名，例如 `JobsAppTool` 实际是 `JobsAppTools` 单例表达式时，必须把能力落到 `JobsAppTools`；禁止据宏名生成 `@interface JobsAppTool`、`@class JobsAppTool` 或对应 typedef。宏接收者、类接收者和实例接收者必须在计划表中分栏确认。
- DSL 的声明和实现必须落在真实所有者：UIKit / Foundation 公共属性进入 `JobsOCDSL` 对应具体类型或 `JobsSystemAPIDSLSupplement`，FDF、ZFPlayer、JXPager、TFPopup 等扩展属性进入各自 Jobs 自建 Extra / 分类，应用私有属性进入该应用类型；禁止把“扫描到的第一个同类型 Category”当落点，也禁止把 FDF / JXPager / 通用 `UIViewController` 属性塞进 `JobsSuspend` 这类无关 Pod。
- 属性审计必须带当前 SDK、`Pods/` 公开头和工程公开头作为 `--type-root`，最终 `missing-dsl=0`、`missing-import=0`、`unverified-receiver=0`。`missing-import` 要通过正确的公开头与 podspec 依赖解决，不能依赖 PCH、另一个 Pod 的偶然 Category 或编译顺序；`unverified-receiver` 必须补静态类型解析、真实所有者 DSL 或人工确认，不得直接批量改写。
- 懒加载 getter、工厂或配置方法必须“一镜到底”：`_object = Type.jobsInit()` 后直接继续整条链，不得先分号再以 `_object` 起第二条链；同一配置块中主接收者只允许出现一次。子对象、Layer、手势或条件配置使用 `byTitleLabel(...)`、`byLayer(...)`、`byButtonBlock(...)` 等父子 Block DSL 进入，不得回到 `_object.child.property = ...`。
- 模型装配也必须落在属性的真实所有者：给自建 Model 补返回该 Model 的 `byXxx` Block，子模型通过 `byTextModelBlock(...)` / `bySubTextModelBlock(...)` 等父级入口继续主链；不在 Demo 里临时包一层 setter，也不重启 `viewModel.textModel...` 子链。
- DSL 调用内嵌 `jobsMakeXxx(...)` 时必须核对括号层级：`receiver.byXxx(jobsMakeXxx(^{ ... }))` 只有“工厂 + DSL”两层右括号，继续链写成 `})).byNext(...)`，结束写成 `}));`；不得产生 `})))` / `})));`。批量替换左右导航按钮、数组工厂等调用后，必须编译覆盖真实语法层级。
- 全量迁移前后先运行 `scripts/audit_oc_functional_block_apis.rb`，再用 `scripts/audit_oc_block_typedef_coverage.rb` 对齐 `JobsBlock` 类型覆盖；普通功能方法按确认计划运行 `scripts/migrate_oc_functional_block_plan.rb`，然后必须运行 `scripts/remove_oc_redundant_block_wrappers.rb` 删除无契约证据的传统薄包装，不得把“已有 Block 门面”统称为 `compatibility-wrapper` 后跳过。系统回调、协议、selector、Target-Action、外部 ABI 等固定契约使用 `scripts/migrate_oc_fixed_block_facades.rb` 生成原 selector trampoline + `jobsXxx` Block 门面，属性 setter 误迁移再按审核计划运行 `scripts/restore_oc_fixed_property_setter_facades.rb`，既有 `sharedManager`、旧分类同名 selector 等遗留冲突再用 `scripts/ensure_oc_legacy_selector_block_facades.rb` 收口，然后必须运行 `scripts/ensure_oc_fixed_block_trampoline_dispatch.rb` 将所有 trampoline 绑定到定义类 IMP，并运行 `scripts/restore_oc_recursive_block_kernel_dispatch.rb --apply` 恢复同名一参数固定 selector 的消息派发。最后用 `scripts/rewrite_oc_same_file_block_message_calls.rb --apply`、`scripts/audit_oc_block_call_sites.rb`、`scripts/ensure_oc_zero_argument_block_calls.rb --same-file-self-only --selectors-file <selectors.txt>`、`scripts/audit_oc_nullable_block_invocations.rb`、`scripts/ensure_oc_block_return_nonnull.rb --apply`、`scripts/audit_oc_duplicate_category_block_getters.rb`、`scripts/audit_oc_property_assignment_dsl.rb`、`scripts/ensure_jobsblock_imports.rb`、`scripts/ensure_jobsdefines_imports.rb --apply` 和 `scripts/ensure_oc_protective_imports.rb --apply` 收口点语法、`self.selector()`、`[self selector]()`、nullable 接收者、Block 空性、Category 重复 IMP、属性写入、调用与 import；`rewrite_oc_same_file_block_message_calls.rb` 默认只改 `self`，其它接收者必须用 `--selector` 显式放行且先核对静态类型，禁止因当前文件恰好存在同名 Block 就把 `UIApplication.openURL`、`JSContext.evaluateScript` 等系统调用改成 Block；`ensure_jobsdefines_imports.rb` 的定义是“把完整双通道移到 `.h` 并从 `.m` 删除”，`ensure_oc_protective_imports.rb` 则把其它顶层 `__has_include` import 块同样上提；二者都不是向 `.m` 插入 import。`--same-file-self-only` 只能修复语义明确的独立调用语句，必须排除存在 setter 的 Block 属性、Block 变量赋值、返回 Block 以及门面转发，不得把 `self.onTick = block` 或 `return self.byXxx` 误改为执行 Block。nullable 审计命中只表示需要结合初始化与控制流复核，确认可空时补守卫，不能机械忽略或盲目批量改写。每次必须分别传入 OC 新工程 `JobsByPods/`、OC 新工程应用 / Demo 源码、OC 老工程 Jobs 源码三类根目录，并在功能 API 和调用点两个审计中都通过 `--contract-root` 纳入当前 SDK 的 `System/Library/Frameworks`、真实 `Pods/` 源头、`*.framework/Headers`、手工第三方头和工程内仍在编译的外援公开头；不能只传 UIKit / Foundation，也不能只传一个未确认会递归跟进 symlink 的 `Pods/Headers/Public`，否则 AVFoundation、CoreBluetooth、ZFPlayer、Flutter 等同名 selector / 属性会被误判为漏写 `()` 或漏收 Block。契约豁免必须有可检索依据；最终同时反扫旧 selector 消息调用、漏写 `()` 的 0 参 Block 调用、显式 `weakSelf` / `strongSelf` 模式、`dealloc` 内弱引用 Block 门面、nullable 接收者直接执行 Block 和错误的 `#endif#import`。硬验收除 OC 新、老两个 App workspace 的 Debug 模拟器构建通过外，还必须把两个 App 安装到模拟器并冷启动到根页面，检查生命周期无重入、无 `EXC_BAD_ACCESS` / 栈溢出；只有 `BUILD SUCCEEDED` 不足以验收此类改造。
- 生成 typedef 时必须把本轮所有 `unmatched` 覆盖报告一次性合并传给 `scripts/ensure_oc_functional_block_typedefs.rb`；该脚本维护的是完整自动生成区，不能只拿最后一小批报告覆盖前面已经生成且被现有方法签名引用的类型。生成后重新跑 typedef coverage，必须达到 `unmatched=0` 才能迁移方法。
- Block 方法参与点语法链时，typedef 和方法声明必须返回当前具体主对象或业务声明的精确类型；禁止为省事统一返回裸 `id`，否则下一个子类 DSL 会静态降级或误判成普通属性。编译出现“called object type is not a function”时，先检查同名属性 / 外部 category / 系统 selector 冲突；保留固定入口并把 Block 改名为 `jobsXxx`，不要通过强转掩盖冲突。

  ```objc
  -(jobsByCorBlock _Nonnull)jobsTheme_setTextColor{
      @jobs_weakify(self)
      return ^(UIColor *_Nullable cor) {
          @jobs_strongify(self)
          /// 原 jobsTheme_setTextColor: 方法体保持原顺序迁入这里
      };
  }
  ```

#### 1.10.2、`JobsOCDSL` 链式调用顺序

- [**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) 侧新增或迁移 `JobsOCDSL` 链式方法时，公共属性只放在父类 DSL，子类特有属性只放在子类 DSL，不要为了调用方便在子类重复定义父类能力。
- 调用链必须优先调用本层类型 DSL，再逐层调用父类 DSL。例如 `UIButton` 先完成 `jobsResetBtn*`、状态图片、事件等按钮能力，再调用 `UIControl.bySelected/byEnabled`，最后调用 `UIView` 层装配能力；`UITextField` 先完成 `byPlaceholder`、`byReturnKeyType` 等输入框能力，再调用 `UIControl` / `UIView` 能力；`UITableViewCell` 先完成 `byTextLabel`、`byContentView` 等 cell 能力，再调用 `UIView.byBgColor`。`UILabel` 同理，先调用 `byText`、`byFont`、`byTextAlignment`、`byNumberOfLines`，最后再调用 `UIView` 层的 `byBgColor`、`byCornerRadius` 或 [**Masonry**](https://github.com/SnapKit/Masonry) 层的 `byAddTo`、`byMakeConstraints`、`byUpdateConstraints`、`byRemakeConstraints`。
- 原因是父类 DSL 返回值通常会收口成 `UIView` / 父类类型；如果先调父类 DSL，后面就可能丢失 `UILabel`、`UIButton`、`UITextField` 等子类本层的点语法能力。
- 对齐 [**Swift**](https://www.swift.org/) 项目里的 [**SnapKit**](https://github.com/SnapKit/SnapKit) DSL 时，OC 侧使用 [**Masonry**](https://github.com/SnapKit/Masonry) 在 `JobsOCDSL/Core/ThirdParty/Masonry` 下补公共链式入口。旧 Pod 私有的 `byAdd`、`setMasonryBy`、网格算法、动画算法不要直接搬进公共 DSL，除非先拆掉业务和历史耦合。

  ```objc
  UILabel *label = jobsMakeLabel(^(__kindof UILabel * _Nullable label) {
      label
          .byText(@"Demo")
          .byFont(UIFontSystemFontOfSize(16))
          .byTextAlignment(NSTextAlignmentCenter)
          .byNumberOfLines(1)
          .byAddTo(self.view, ^(MASConstraintMaker *make) {
              make.center.equalTo(self.view);
              make.size.mas_equalTo(CGSizeMake(JobsWidth(200), JobsWidth(20)));
          });
  });
  ```

#### 1.10.3、`JobsMake` + `JobsOCDSL` UI 创建公约

- UI 创建统一优先使用真实归属下的 `jobsMakeXXX` 形成创建 Block：`JobsMakes@Pods/JobsMakes.h` 提供 `jobsMakeView`、`jobsMakeLabel`、`jobsMakeImageView`、`jobsMakeTextView`、`jobsMakeTextField`、`jobsMakeCollectionView`、`jobsMakeScrollView`、`jobsMakeStackView`、`jobsMakeSwitch`、`jobsMakeSlider`、`jobsMakeProgressView`、`jobsMakeSegmentedControl`、`jobsMakeContextualAction`、`jobsMakeSwipeActionsConfiguration` 等；按钮的 `jobsMakeButton` 与表格的 `jobsMakeTableViewByPlain/Grouped/InsetGrouped` 当前由 `JobsByOCPods` 对应分类提供。不要因为名字都以 `jobsMake` 开头就误判所属 Pod。创建入口只负责创建对象和提供闭包，不在里面扩展业务配置。
- 业务配置对象的工厂留在业务能力自己的 Pod：`jobsMakeOCKeyboardConfig` 归 `JobsOCKeyboardMgr` 的 `JobsOCKeyboardConfig` 公共头导出，`JobsMakes` 不得为它反向依赖 `JobsOCKeyboardMgr`。发现 `基础 DSL -> JobsMakes -> 业务 Pod -> 基础 DSL` 这类环时，优先把工厂迁回模型 / 业务 Pod 的真实归属并更新调用方直接依赖，不以搜索路径或暂留裸 API 掩盖循环。
- UIButton 常态标题、标题色、字体、图片、背景图、背景色、圆角和图文间距优先使用 `jobsResetBtnTitle`、`jobsResetBtnTitleCor`、`jobsResetBtnTitleFont`、`jobsResetBtnImage`、`jobsResetBtnBgImage`、`jobsResetBtnBgCor`、`jobsResetBtnCornerRadiusValue`、`jobsResetImagePlacement_Padding`，让新旧管线在封装内部收口。高亮、选中、禁用状态确实需要不同资源时，使用当前实现已提供的 `highlightedStateImageBy(...)`、`selectedStateImageBy(...)`、`disabledStateImageBy(...)` 等 state-specific Jobs API。任意状态及 `UIControlStateSelected | UIControlStateHighlighted` 这类组合态，按资源类型使用 `titleForStateBy`、`attributedTitleForStateBy`、`titleColorForStateBy`、`titleShadowColorForStateBy`、`imageForStateBy`、`backgroundImageForStateBy`、`preferredSymbolConfigurationForStateBy`；复制 / 查询状态资源时使用对应 `titleByState`、`attributedTitleByState`、`titleColorByState`、`titleShadowColorByState`、`imageByState`、`backgroundImageByState`、`preferredSymbolConfigurationByState`，不用常态 API 抹平状态语义，也不退回系统 setter / getter。
- 按钮向外透露的主标题、副标题、前景图和无障碍文案必须与“此刻再次点击会执行的动作”一一对应，不能只描述当前状态或长期挂一个模糊图标。按钮行为因选中态、展开 / 收起、开始 / 停止、明 / 暗主题等状态发生切换时，必须在同一状态变更链路同步刷新全部对外表述；例如当前为明亮主题且下一次点击会切到黑夜，应显示“切换为黑夜”和对应图标，菜单展开后则应改为“收起操作”而不是继续显示“展开操作”。
- OC 新、老工程中每个具体 Demo 页的导航栏右上角最多只显示一个触发入口。没有页面业务动作时，该入口直接执行主题切换并按下一次点击行为展示文案 / 图标；存在其它页面动作时，该入口只负责展开 / 收起与 Demo 总入口一致的下拉列表，把主题与全部页面动作统一收纳，入口表述也必须随展开状态同步切换。
- `UIButton` 虽继承自 `UIView`，但按钮可见背景和圆角必须按独立管线处理：调用方不使用 `UIView.byBgColor`、`UIView.byCornerRadius` 或直接操作 `button.layer` 作为按钮背景 / 圆角的最终实现，统一调用 `jobsResetBtnBgCor`、`jobsResetBtnCornerRadiusValue` 等 `UIButton` 专用 Jobs API。封装内部在 iOS 16+ 写入 `UIButtonConfiguration.background.backgroundColor` / `cornerRadius`，旧系统再回退传统按钮 / Layer 管线；依赖动态高度的胶囊按钮先按设计默认高度设置初始圆角，再在真实布局完成后校准，不能等定时器或后续事件才首次圆角化。
- `UISegmentedControl` 创建走 `jobsMakeSegmentedControl(items, block)`，写入选中项走 `bySelectedSegmentIndex(...)`，读取走 `jobs_selectedSegmentIndex`；`UISwitch` 写入 / 读取状态使用 `byOn(...)` / `jobs_isOn`；Auto Layout 开关使用 `UIView.byTranslatesAutoresizingMaskIntoConstraints(...)`。`UIStackView`、`UISwitch`、`UIContextualAction`、`UISwipeActionsConfiguration` 分别使用当前类型 DSL，不再在上层散落系统属性赋值。
- UI 子视图默认使用懒加载 getter 创建和配置。不要在 `setupSubviews`、`viewDidLoad`、`init` 或某个大方法里连续 `UIView.new` / `UILabel.new` / `UIImageView.new` / `UITableView alloc init...` 再散落赋值、添加和约束。`setupSubviews` 只负责触发懒加载、添加层级、部署约束或做极少量编排。
- 凡是创建后会进入页面视图层级、绑定约束 / 事件 / 代理、参与页面生命周期，或未来可能被刷新、显隐、换肤、重配的 UI / 交互对象，都必须在类扩展中用 `Prop_strong()` 等属性保留引用，并由对应懒加载 getter 负责创建。禁止仅因为当前方法最后 `return` 了对象，就把 `UIScrollView *scrollView`、`UIStackView *stackView`、`UIButton *button` 等长期 UI 留成方法局部变量；页面装配方法只消费 `self.xxx` / `_xxx`。
- 固定唯一对象使用语义明确的单一属性；按数据重复生成的行、按钮、StackView、ScrollView 等使用带元素类型的 `NSMutableArray` / `NSArray` / `NSMutableDictionary` 属性统一持有。动态重建时先移除旧视图并清理集合，再创建并立即写入持有集合，保证每个已展示对象都能从所属类取回引用，不能用“数量不固定”作为不留引用的理由。
- 属性化改造必须覆盖 OC 新工程和 OC 老工程中 Jobs 自维护代码的同类写法；重点反扫 `viewDidLoad`、`loadView`、`setup*`、`build*`、`make*`、`configure*` 以及返回 UI 对象的辅助方法。只排除系统 / 框架回调已经传入且生命周期由复用机制管理的对象、Jobs 工厂 / DSL 底层为完成封装而创建的临时对象，以及不会进入视图层级也不存在后续修改语义的纯计算临时值。
- 懒加载 getter 内部必须用 `JobsMake` + `JobsOCDSL` / `JobsModelDSL` 收口：创建、基础属性、事件、进入父视图、Masonry 约束通过链式写法完成。当前类型缺 DSL 时先补封装，不回退到 `_view = UIView.new; _view.xxx = ...; [parent addSubview:_view];` 这种散落写法。
- 需要保存约束对象时，可以在懒加载 getter 的 `byAdd` / `byOn` / `mas_makeConstraints` block 中赋值给 ivar，例如保存高度约束；但对象本身仍应由 getter 负责创建，不把整棵 UI 树塞进一个方法。
- `JobsMake` 的 Block 内部，属性赋值使用 `JobsOCDSL` / `JobsModelDSL` 点语法链式配置；不要回退成散落的 `label.text = ...`、`view.backgroundColor = ...`。目标属性没有 DSL 时先在属性所属类型补齐，不在调用方留“临时裸写法”。
- UI 装配顺序固定为：先当前类本层 DSL，再父类 DSL，再进入 `UIView+DSL` / `Masonry+DSL` 的装配入口。当前 `UIView+MasonryDSL` 的 `byAddTo(superview, makeBlock)` 是“加父视图 + 首次约束”的组合入口；如果后续拆成独立 `UIView+DSL` 加父视图入口，也必须保证加载到父视图早于 [**Masonry**](https://github.com/SnapKit/Masonry) 约束。
- 能拆开的动作就拆开表达：优先写 `addOn(...).byAdd(...)`，把“进父视图”和“布约束”作为两个明确步骤；`byAddTo(...)` 只保留兼容，不作为默认新增写法。
- 如果某些效果依赖真实 `frame`，例如渐变层、圆角路径、局部切角、阴影路径、动画初始位置等，可以放在 `byAddTo` + [**Masonry**](https://github.com/SnapKit/Masonry) + `layoutIfNeeded` 之后执行；因此“加父视图和约束”通常靠后，但不一定是整个链条的最后一步。
- 只要当前类型已经有 DSL，就不要回退成裸赋值写法；例如 `layer.path = ...`、`borderLayer.strokeColor = ...`、`label.font = ...` 这类语句，在对应层已经有 `byPath(...)`、`byStrokeColor(...)`、`byFont(...)` 时，必须改成链式调用。缺 DSL 就补到属性所属层，不把子类属性错误地下沉到父类 DSL。
- 链式 Block 内部不要夹无意义空行；同一段配置连续写完，除非有明确语义分组，否则不要靠空行制造视觉停顿。
- `UIView+DSL` 负责“进入父视图”这类视图动作，`Masonry+DSL` 负责“部署约束”这类布局动作。二者职责不要混写：不要在普通属性 DSL 里偷偷添加父视图，也不要在 [**Masonry**](https://github.com/SnapKit/Masonry) DSL 里写业务属性。
- `UITableView` / `UICollectionView` 后续免协议 Block 化封装要对照 [**Swift**](https://www.swift.org/) 侧 `JobsSwiftDSL`：优先支持 `byTarget`、`numberOfRowsInSection` / `numberOfItemsInSection`、`cellForRowAt` / `cellForItemAt`、`didSelect...` 等常用入口；协议代理仍可保留，Block 配置作为常用页面的轻量写法。
- 写文档和示例时，必须体现这个统一模型：`JobsMake` 创建对象，`JobsOCDSL` / `JobsModelDSL` 配属性，`UIView+DSL` 添加父视图，[**Masonry**](https://github.com/SnapKit/Masonry) DSL 部署约束，frame 依赖效果在约束刷新之后处理。

#### 1.10.4、Masonry 强制布局、无警告约束与临时布局阶段

- OC 新项目、OC 老项目中 Jobs 自己维护的 UI 布局统一使用 [**Masonry**](https://github.com/SnapKit/Masonry)，覆盖主工程和 Jobs 自建本地 Pods；继续排除 `Pods/`、`JobsByPods/ManualByOCPods@Pods/`、生成代码和确认的外援第三方源码。
- Jobs 自维护代码禁止直接使用系统 `NSLayoutConstraint` 体系，包括但不限于创建 `NSLayoutConstraint` 对象、`activateConstraints:` / `deactivateConstraints:`、`constraintsWithVisualFormat:`、`constraintWithItem:`，以及 `NSLayoutAnchor` / `NSLayoutXAxisAnchor` / `NSLayoutYAxisAnchor` / `NSLayoutDimension` 等 Anchor API。不得把系统约束封装进 Jobs DSL 后继续使用；底层和调用方都必须收口到 Masonry。
- 新增、迁移或修改布局时，首次约束使用 `mas_makeConstraints` / `byAdd` / `byMakeConstraints`，常量更新使用保存的 `MASConstraint` 或 `mas_updateConstraints` / `byUpdateConstraints`，结构变化才使用 `mas_remakeConstraints` / `byRemakeConstraints`。需要真实 `frame` 的绘制、动画或路径计算只能在 Masonry 布局完成后读取，不能用 `frame` 计算代替约束。
- 每次触碰 OC UI / 布局代码后，必须在 OC 新、老项目的 Jobs 自维护范围反扫 `NSLayoutConstraint`、`NSLayoutAnchor`、`constraintWithItem:`、`constraintsWithVisualFormat:`、`activateConstraints:` 和 `deactivateConstraints:`；命中项目代码就改为 Masonry，不能只修本轮文件。若命中外援 / 生成代码，只记录排除原因，不修改上游源码。

- 新写或修改 UI 后，必须检查控制台 `Unable to simultaneously satisfy constraints`、`UIView-Encapsulated-Layout-*` 和 `UITableViewAlertForLayoutOutsideViewHierarchy`。按日志里的视图类型、约束地址和创建代码定位来源；禁止删除已成立的业务约束、吞日志或用异常捕获伪装无警告。
- `UITableViewCell` / `UICollectionViewCell` 测量时可能临时获得 `44` 或 `0` 的系统封装高度。固定头部、上下边距、折叠内容等只在真实行高下成立时，保留原数值，把其中可压缩的一条写成 `.priority(999)`；真实高度阶段视觉不变，临时阶段不与系统 `UIView-Encapsulated-Layout-Height` 硬冲突。
- 折叠容器禁止同时以必选优先级声明“高度为 `0`”和“上下均有正间距”。保存高度约束并把零高度或非关键底边设为 `999`，展开时只 `setOffset:` / `mas_updateConstraints`，不要重复 `mas_makeConstraints`。
- 视图或 TableView 尚未挂到 `window` 时，不调用 `layoutIfNeeded`、`beginUpdates/endUpdates` 或仅为刷新主题执行 `reloadData`。初始化只准备数据；强制布局用 `self.window` / `view.window` 守卫，或延后到 `viewDidAppear:` / `didMoveToWindow`。
- 首次创建用 `mas_makeConstraints` / `byAdd`，仅常量变化用保存约束或 `mas_updateConstraints`，结构变化才用 `mas_remakeConstraints`。禁止在 cell 复用、配置和 `layoutSubviews` 中重复叠加同义约束。
- 导航控制器、TabBar 子控制器和 titleView 在根窗口仍为 `0×0` 时，不主动触发布局。先完成 `window.rootViewController` 与 `makeKeyAndVisible`，再刷新依赖真实宽高、安全区或导航栏边距的 UI。

  ```objc
  _titleLab = jobsMakeLabel(^(__kindof UILabel * _Nullable label) {
      label
          .byText(@"标题")
          .byFont(UIFontWeightBoldSize(16))
          .byTextAlignment(NSTextAlignmentCenter)
          .byNumberOfLines(1)
          .byBgColor(JobsClearColor)
          .byAddTo(self.contentView, ^(MASConstraintMaker *make) {
              make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(8, 12, 8, 12));
          });
  });
  ```

#### 1.10.5、图标资源规则

- 用户明确指定图标、图标名称或现有视觉样式时，严格按指定资源落地；用户没有特别指定时，必须先到[**阿里巴巴矢量图标库 iconfont**](https://www.iconfont.cn/)按按钮实际触发行为查找语义匹配的图标。只有 [**iconfont**](https://www.iconfont.cn/) 确实没有合适素材时，才向用户说明并征求其它来源，不能自行改用 SF Symbols、来源不明图片、临时纯色块或无意义占位图。
- OC 新、老项目的 Demo 入口页面中，每个 cell 前的图标必须与当前入口内容及功能语义贴合，并保证同一页面内不重复；来自 [**iconfont**](https://www.iconfont.cn/) 的图标必须下载到本地并放入当前工程实际使用的 `*.xcassets`，禁止通过 URL 或其它方式远程引用。
- 新图标落地时，按当前项目资源体系放入 `Assets.xcassets`、自建 Pod 的 `Resource` / resource bundle 或既有图标目录，并同步 Xcode 文件引用、podspec 资源声明和 README 资源说明。
- 如果采用字体图标方式集成，要记录并统一维护图标名称、unicode / class 信息；业务代码里不要散落硬编码 codepoint，优先通过统一常量、枚举、模型或封装入口引用。

### 1.11、`*.h` 头文件 `#import` 排序

- 每次新写、修改或批量整理 OC 头文件导入区，都必须同时全文扫描 OC 新项目和老项目中 Jobs 自己维护的 `*.h`；不只修用户点名文件，也不只扫当前子 Pod。继续排除 `Pods/`、`JobsByPods/ManualByOCPods@Pods/`、生成目录和确认的外援第三方源码。
- [**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) 头文件顶部先写一般性 `#import`，再写双通道保护性 `#if __has_include(...)`。一般性写法和双通道保护性写法之间保留一个空行。
- 一般性 `#import` 优先写系统 / Apple / Darwin / 底层头文件，再写本文件直接依赖的普通头文件；越靠近底层越靠上，例如 ObjC runtime / message、C 系统库、`CoreFoundation`、`Foundation`、`UIKit`、`WebKit`、`AVFoundation` 等系统头按底层到上层排列。
- Jobs 自己写的代码里，系统 / Apple / Darwin / ObjC runtime 头文件必须写在对应同名 `*.h` 文件的一般性 import 区域，`*.m` / `*.mm` 不单独导入。不限于 `#import <objc/runtime.h>`：例如 `<objc/message.h>`、`<Foundation/Foundation.h>`、`<UIKit/UIKit.h>`、`<WebKit/WebKit.h>`、`<AVFoundation/AVFoundation.h>`、`<AudioToolbox/AudioToolbox.h>`、`<Photos/Photos.h>`、`<Security/Security.h>`、`<CommonCrypto/CommonCrypto.h>`、`<os/lock.h>`、`<pthread.h>`、`<sys/sysctl.h>`、`<stdint.h>`、`<ctype.h>` 等都按这条执行。即使只有实现文件里调用相关 API，也要由同名头文件统一承接。
- 如果已经写了 `#import <UIKit/UIKit.h>`，则同一个 import 区域不再重复写 `#import <Foundation/Foundation.h>`，因为 `UIKit` 已经包含 `Foundation`。
- 把导入区按“普通单个 `#import` ”和“完整双通道保护块”视为相邻导入单元：普通↔普通之间不留空行；只要相邻两个单元中任意一个是双通道保护块，两者之间必须且只能保留一行空行。这覆盖普通↔双通道、双通道↔普通、双通道↔双通道三种组合；双通道块内部四段结构仍紧凑连写，不插入空行。
- OC 新项目中 Jobs 自己维护的 `*.m` 文件，每条 `#import "xxx.h"` 必须独占一行，行尾说明移到独立注释行；相邻的双引号 `#import` 之间不得保留空行，必须紧挨排列。文件头注释与第一条 import 之间、最后一条 import 与正文之间仍各保留一个空行，不把导入区粘到文件头或正文。
- 上述 `*.m` 双引号 import 排版使用 `scripts/normalize_oc_m_quoted_import_layout.rb <OC 新项目根目录...>` 先干跑，确认范围后加 `--apply`；应用后必须二次干跑到 `changed_files=0 invalid_lines=0 blank_gaps=0`。脚本必须复用 `jobs_oc_ownership.rb` 过滤所有权，继续排除 `Pods/`、`ManualByOCPods@Pods/`、生成目录和他人源码。
- `#import` 导入区和下面的正文内容区之间必须保留一行空行。正文内容区包括 `NS_ASSUME_NONNULL_BEGIN`、`@interface`、`@implementation`、`@protocol`、`@class`、`typedef`、`NS_INLINE`、`static`、`#pragma` 等；例如 `#import "DefineProperty.h"` 后面不能紧贴 `NS_ASSUME_NONNULL_BEGIN`，必须空一行。
- 双通道保护性区域先写外源性 Pod，再写内源性 Pod。外源性 Pod 指 OC 项目 `Pods/` 目录下的模块；内源性 Pod 指 OC 项目 `JobsByPods/` 下除 `ManualByOCPods@Pods/` 以外的模块。
- 内源性 Pod 的双通道保护性写法排序：`JobsOCProtocols` 靠前，中间写其他内源 Pod，`JobsBlock` 和 `JobsOCDefs` 靠后；其中 `JobsOCDefs` 通常作为宏定义兜底放在最后。
- 跨模块保护性 import 承接 `1.4` 的边界规则：公开依赖写同名 `*.h`，外部 Pod 固定导入聚合头，例如 `#import <ZFPlayer/ZFPlayer.h>`；不要在双通道块里拆成多个内部子头。
- OC 新旧工程的应用层 / Demo 只要使用 Pod，不区分 Jobs 自建 Pod 还是外源 Pod，都必须由调用文件的同名 `*.h` 承接“尖括号模块入口 + 双引号 fallback”的双通道聚合头；`*.m` / `*.mm` 禁止裸写 Pod 聚合头或内部子头。比如实现层的 `JobsBaseUI/UIViewController+BaseNavigationBar.h` 必须上提并收成 `JobsBaseUI/JobsBaseUI.h`，`JobsViewPush/JobsViewPush.h` 也必须整体上提。
- “聚合头”以自建 Pod 根入口头、上游公开入口头、modulemap 或 CocoaPods umbrella 实际导出的入口为准；不能把当前恰好需要的分类 / 协议 / 类子头冒充聚合头。若上游确实没有总入口，只能登记明确的上游主入口例外，不能静默漏扫。
- 应用层 Pod import 全量整理使用 `scripts/ensure_oc_application_pod_imports.rb --project-root <工程根目录> --apply <应用层源码目录...>`：脚本必须排除 `Pods/`、`JobsByPods/`、`ManualByOCPods@Pods/`、生成代码和非 Jobs 源码，先一次性处理完整范围，再以不带 `--apply` 的二次干跑确认 `headers=0 implementations=0 unresolved=0`。
- 带 `HAS_*` / `JOBS_*_HAS_*` 能力宏的可选 Pod 保护块是完整语义单元；必须保留 `#elif`、成功 / 失败分支宏值和无 Pod 回退路径，批量脚本不得为收成四段导入而丢掉宏或改变可选能力语义。
- 新旧工程都纳入同一轮时，先完成两边迁移与静态审计，再统一编译各自 target；不要每修改一个文件就触发一次编译。编译报错按模块边界集中修复，修复后重新跑迁移器和编译验证。
- Jobs 自己写的 `*.m` / `*.mm` 不允许出现 `#if __has_include(...)` / `#elif __has_include(...)` 包住 `#import`、`#define HAS_*` 或 fallback import 的保护性块；这些块必须整体移到同名 `*.h`。实现文件如果还需要可选能力判断，只能使用同名头文件定义好的 `HAS_*` 宏。
- Jobs 自己写的普通业务 `*.m` / `*.mm` 顶部默认只保留自身同名头文件；除当前 Pod 内部确需引用自身 `Support` 私有支援文件外，其它类、Cell、Model、聚合头、DSL 头和跨模块头都应上提到同名 `*.h`。
- 批量改完 OC import 后，必须全文扫描 Jobs 自维护范围内的 `.m` / `.mm`：`rg -n --glob '*.m' --glob '*.mm' --glob '!Pods/**' --glob '!JobsByPods/ManualByOCPods@Pods/**' "__has_include" .`。只要实现文件命中，就继续上提到同名头文件：保护性 import 整体迁移；可选能力判断改成同名头文件定义 `HAS_*` 宏后由 `.m` 使用宏判断。目标是 Jobs 自维护 `.m` / `.mm` 不直接出现 `__has_include`。
- 历史老工程可能存在多个同名头、同名类或功能副本；不得把 `rg` 命中的第一份当成编译器实际看到的版本。必须结合 `.m` 的真实 `#import`、target membership、build log 里的 include stack（必要时使用 `-H`）或预处理结果确认解析路径；只修未参与当前 target 的副本等于没修。若多份 Jobs 副本都在不同受支持 target 中生效，必须同步修改或先安全收敛唯一来源，不能依赖 Header Search Paths 偶然选中。
- 批量改完 OC 系统头 import 后，必须全文扫描 Jobs 自维护范围内的 `.m` / `.mm`：`rg -n --glob '*.m' --glob '*.mm' --glob '!Pods/**' --glob '!JobsByPods/ManualByOCPods@Pods/**' '^#import <(objc/|Foundation/|UIKit/|WebKit/|AVFoundation/|AudioToolbox/|Photos/|Security/|CommonCrypto/|Core[A-Za-z]+/|QuartzCore/|ImageIO/|MobileCoreServices/|UniformTypeIdentifiers/|os/|sys/|libkern/|XCTest/|pthread\\.h|stdint\\.h|stdio\\.h|stdlib\\.h|string\\.h|ctype\\.h)' .`。只要命中 Jobs 自己写的实现文件，就把系统头上提到同名 `*.h`；如果没有同名头或该文件是明确第三方源码，必须在最终说明中标出原因。
- 双通道保护性写法固定保持四段结构，不要拆散：

  ```objc
  #if __has_include(<MJRefresh/MJRefresh.h>)
  #import <MJRefresh/MJRefresh.h>
  #else
  #import "MJRefresh.h"
  #endif
  ```

- 例如 `JobsModel` 和 `JobsBlock` 这两个模块之间，必须写成下面这样：

  ```objc
  #if __has_include(<JobsModel/JobsModel.h>)
  #import <JobsModel/JobsModel.h>
  #else
  #import "JobsModel.h"
  #endif

  #if __has_include(<JobsBlock/JobsBlock.h>)
  #import <JobsBlock/JobsBlock.h>
  #else
  #import "JobsBlock.h"
  #endif
  ```

### 1.12、Xcode 工程里的 Markdown 文档引用

- [**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) 工程范围内的 Markdown 文档统一命名为 `README.md`。遇到历史遗留的 `xxx.md` 文件时，改为 `xxx.md/README.md` 这种“同名目录包裹 README”的结构，避免同一目录下多个说明文件互相抢名。
- `README.md` 只作为文档引用存在，可以在 [**Xcode**](https://developer.apple.com/xcode) 左侧导航中展示，但不得加入 `Sources`、`Resources`、`Copy Files`、`Headers` 等任何 Build Phase，不进入编译、打包或资源拷贝环节。
- 批量整理 Markdown 后必须同步检查 `*.xcodeproj/project.pbxproj`：`PBXFileReference` 应指向新的 `README.md` 路径；如果发现 `*.md in Sources`、`*.md in Resources`、`*.md in Copy Files` 或 `*.md in Headers`，必须移除对应 `PBXBuildFile` 和 Build Phase 条目，只保留文件引用。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
