---
name: jobs-podspec
description: 当任务涉及 CocoaPods、Podspec、source_files、public_header_files、resource_bundles、xcconfig、JobsPodspecKit.rb、本地 Pod 发布配置，或 iOS 的 pod install / Xcode 挂载脚本及 README 同步时使用。
---

# Jobs CocoaPods Podspec 规范

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[toc]

---

## 🔥 <font id=前言>前言</font>

> 本技能由 `💻JobsCodexConfigs/AGENTS.md` 拆分而来，保留原有 Jobs 工作规范。只有当前任务命中本技能描述时才加载本文件，避免把所有细则长期塞进全局上下文。

## 一、[**CocoaPods**](https://cocoapods.org/) Podspec 文件（`*.podspec`） <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 1.1、适用范围

- 本规范来自 `~/Documents/JobsOCBaseConfigDemo/JobsByPods` 下 69 个 `*.podspec` 的现有写法。
- 适用于 Jobs 本地管理的 [**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) Pods、`Extra` 扩展 Pods、聚合 Pods，以及 `ManualByOCPods@Pods` 下手动托管的第三方 Pods。
- 新增或升级 podspec 时，先看同类 Pod 的现有写法，再按本规范收口。不要凭空换一套 [**CocoaPods**](https://cocoapods.org/) 风格。

### 1.2、整体结构

- 自研 Pod / Extra Pod 优先使用同目录 `JobsPodspecKit.rb`：

  ```ruby
  require_relative 'JobsPodspecKit'

  Pod::Spec.new do |spec|
    support_context = JobsPodspecKitForPodName.build_support_context(
      podspec_dir: File.expand_path(File.dirname(__FILE__)),
      support_dir: 'Support',
      support_dependencies: []
    )

    # spec 元信息
    # source / platform / Core / Support / dependencies / xcconfig
  end
  ```

- 字段顺序优先保持稳定：`require_relative`、`support_context`、`name`、`version`、`summary`、`description`、`homepage`、`license`、`author`、`platform`、`requires_arc`、`source`、根入口文件、真实 `Core` / `Support`、`default_subspecs`（仅确实对外提供 subspec API 时）、`exclude_files`、`frameworks`、`dependency`、`xcconfig`。
- 字段对齐按现有风格即可：

  ```ruby
  spec.name             = 'JobsBaseUI'
  spec.version          = '1.0.0'
  spec.summary          = 'Base UI component library for Jobs projects.'
  spec.platform         = :ios, '12.0'
  spec.requires_arc     = true
  spec.source           = { :path => '.' }
  ```

### 1.3、基础信息与 source

- 自研 Pod 的 `homepage` 可以使用 `https://example.local/PodName`；已经有真实 Git 地址的 Pod 保留真实地址。
- 自研 Pod 作者默认：`spec.author = { 'Jobs' => 'lg295060456@gmail.com' }`。
- 第三方 Manual Pod 保留原作者、原 homepage、原 license；只做本地托管适配，不抹掉来源信息。
- iOS 最低版本默认：`spec.platform = :ios, '12.0'`。
- Objective-C Pod 默认：`spec.requires_arc = true`。
- 本地管理的 Pod 默认：`spec.source = { :path => '.' }`。
- 需要模拟远程 tag 或聚合仓库时，才使用：`spec.source = { :git => "file://#{__dir__}", :tag => spec.version.to_s }`。
- 第三方 Manual Pod 如果保留上游源码声明，可以继续使用：`spec.source = { :git => 'https://github.com/owner/repo.git', :tag => spec.version.to_s }`。

### 1.4、入口头文件 / Core / Support

- 有根入口头文件时，根层暴露入口头，并让真实 `Core/` 目录在根级直接参与源码 / 公开头声明：

  ```ruby
  spec.source_files        = [
    'PodName.h',
    'Core/**/*.{h,m,mm}'
  ]
  spec.public_header_files = [
    'PodName.h',
    'Core/**/*.h'
  ]
  ```

- 没有根入口头时，也优先在根级直接映射真实 `Core/`：

  ```ruby
  spec.source_files        = 'Core/**/*.{h,m,mm}'
  spec.public_header_files = 'Core/**/*.h'
  ```

- `Core` 是磁盘真实目录，不要再用 `spec.subspec 'Core'` 包住 `Core/**/*`，否则 Xcode 的 `Development Pods` 容易展示成 `Core/Core`。出现双层 `Core` 时，先确认磁盘上是否误套 `Core/Core`；磁盘正常则修正 podspec 的 `source_files` / `public_header_files` / `resources`，让 Pod 根级直接映射真实 `Core/`。
- 只有确实需要对外暴露 `PodName/Core` 这种 subspec API 时，才允许创建 `spec.subspec 'Core'`；创建后必须执行 `pod install` 并确认 `Development Pods > PodName` 下不会出现 `Core/Core`。
- 有 `Support` 目录时，自研 Pod 优先用 `JobsPodspecKitForPodName.add_support_subspec(spec, support_context)` 镜像真实目录。
- `Core` 依赖 `Support` 时，如果使用 subspec，优先使用 `JobsPodspecKitForPodName.add_dynamic_support_dependencies(ss, spec, support_context)`；如果根级直接映射 `Core/`，则把需要的 `Support` 依赖加在 `spec` 根级。
- 如果某个 Support 子路径必须显式依赖，可以只补最小必要项，例如 `ss.dependency 'JobsOCDefs/Support/UIKit'`。

### 1.5、资源、排除与依赖

- 源码扩展默认覆盖 `h,m,mm`。
- 资源扩展默认覆盖 `png,jpg,jpeg,gif,webp,svg,pdf,json,plist,bundle,xib,nib,storyboard,xcassets,strings,stringsdict,ttf,otf,mp4,aiff`。
- `source_files` 只匹配源码和头文件；图片、xib、bundle、json、plist 等进入 `resources`，不要混在源码 glob 里。
- 自建 Pod 的非代码资源统一放在与 `Core` 平级的真实 `Resource` 文件夹里；`Resource` 按需创建，没有资源的 Pod 不创建空目录。不要继续使用 Pod 根目录、`Core`、`Support`、`Resources` 或 `resources` 承载图片、`*.bundle`、声音、`*.json`、`*.xcprivacy` 等资源。
- 自研 Pod 优先调用 `JobsPodspecKitForPodName.apply_standard_exclude_files(spec)`。
- Manual Pod 没有 `JobsPodspecKit` 时，要手写完整排除清单，至少覆盖 macOS 垃圾文件、Git / SVN、[**CocoaPods**](https://cocoapods.org/)、[**Xcode**](https://developer.apple.com/xcode/)、Demo / Example / Test、文档截图、CI / 临时 / 压缩包。
- `frameworks` 使用数组，按现有 Jobs 风格多行写。
- 依赖优先一行一个，放在 `frameworks` 后或对应 subspec 内。有版本约束时使用 [**CocoaPods**](https://cocoapods.org/) 原生写法，例如 `spec.dependency 'lottie-ios', '~> 2.5.3'`。
- 聚合 Pod 依赖很多时，可以先定义 `common_dependencies`，再用 lambda 统一添加。

### 1.6、xcconfig 与校验

- 自研 Pod 默认使用 `JobsPodspecKitForPodName.apply_standard_xcconfig(spec)`。
- 标准配置应包含 `DEFINES_MODULE`、`HEADER_SEARCH_PATHS`、`CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES`。
- 只有确实需要链接 Objective-C Category 时，才补 `'OTHER_LDFLAGS' => '$(inherited) -ObjC'`。
- 如果某个 Pod 头文件搜索路径必须收窄，可以像 `JobsAPIs` 一样显式指定 `Core` / `Support`，不要无脑扩大。
- podspec 注释同样精简扼要，只解释目录策略、动态 Support、风险依赖、特殊 xcconfig。
- 需要校验时优先使用：

  ```shell
  pod lib lint PodName.podspec --allow-warnings --verbose
  ```

- 本地集成排查优先：

  ```shell
  pod install --no-repo-update
  ```

- 如果当前机器环境不适合实际执行 `pod`，至少做 [**Ruby**](https://www.ruby-lang.org) 语法检查：

  ```shell
  ruby -c PodName.podspec
  ```

- 修改 podspec 后要重点检查：`spec.name` 是否和文件名一致、入口头是否真实存在、`Core` / `Support` glob 是否命中、依赖是否形成循环、资源是否被错误放进 `source_files`。
- 但凡修改 podspec 或本地 Pod 的依赖 / 入口 / 公开文件，都必须回到整个归属工程做使用面扫描并同步更新调用方。扫描范围至少包括主工程源码、Demo 入口、`import` / `#import`、其它 podspec 的 `dependency`、`Podfile` / `Podfile.deps`、README / 技术文档和脚本中的 Pod 名；不能只通过 `ruby -c`、`pod ipc spec` 或 `pod install` 判断完成。生成物如 `Podfile.lock`、`PodspecDependencyReport` 若本轮未重新生成，最终回复必须说明它们仍可能保留旧引用。
- 本地 Pod 修改后，`pod install` 成功只代表 CocoaPods 主流程没有中断，不代表 Pods 工程在 Xcode 里可用。必须继续验证 `Pods/Pods.xcodeproj` 能被 `xcodeproj` 打开、根对象仍是 `PBXProject`、目标 Pod target / scheme 存在、`Development Pods > Pod名` 能展开出 `Core` / `Support` / `Pod` / `Support Files`。如果 Xcode 左侧 Pod 名能看到但没有子项，优先排查 Podfile 脚本或 `JobsPodspecKit.rb` 是否写坏 group / file reference / UUID。
- 建议把本地 Pod 可见性检查写成固定命令：`ruby -rxcodeproj -e 'p = Xcodeproj::Project.open("Pods/Pods.xcodeproj"); puts [p.root_object.isa, p.targets.find { |t| t.name == "Pod名" }&.name].join(" | ")'`，再用 `xcodebuild -workspace 工程.xcworkspace -list | rg "Pod名"` 验证 scheme。只有这两步都正常，才算解决“pod install 不报错但 Xcode 左侧不可展开”的问题。

#### 1.6.1、`Podfile` / `Podfile.deps` 解耦、展示与脚本边界

- `Podfile.deps` 只维护 `pod` 依赖定义，不直接执行外部脚本；需要挂载脚本时统一放在 `Podfile` 的 `pre_install`、`post_install` 或 `post_integrate` 中处理。
- 依赖清单以直观为先：每个依赖单独写一行 `pod '名称', :path => '实际路径'`；远端依赖直接写名称与版本。可保留 `byJobs` 等分组方法，但不使用 `%w` + `each`、字符串插值或路径推导来压缩声明，方便逐条阅读、注释和调整。
- `Podfile` 里凡是调用外部脚本、`load` 外部 Ruby 文件、`.command`、`.sh`、`.rb` 或 `ScriptsByPods` 下的工具，都必须先判断文件是否存在。脚本不存在、`chmod +x` 失败或脚本执行失败时，默认只打印告警并 `return` / 跳过，不中断 `pod install` 主流程。
- 只有用户明确要求某个脚本是强制门禁时，才允许用 `raise` 阻塞；否则依赖报告、CodeGraph、资源清理、Flutter/Unity 辅助脚本都按“可选增强，失败不阻塞”处理。
- 新增脚本入口时优先封装统一 helper，例如 `jobs_run_external_script(...)` 或 `run_xxx_script`，不要在 Podfile 里散落裸 `system(script_path)`。
- Swift / OC 项目采用 `Podfile` + `Podfile.deps` 解耦时，验收必须同时满足：`Podfile.deps` 在 Xcode 的 Pods 工程根组中与 `Podfile` 相邻正常显示，呈现红色 Ruby 钻石图标及文件引用标识，并能打开编辑真实依赖文件。设置 `explicitFileType = text.script.ruby`，不要使用 Xcode 无法识别的 `sourcecode.ruby`；仅添加文件引用，不加入任何 Build Phase。通过 `Podfile` 的安装 hook 自动维护，重复 `pod install` 后仍保持红钻引用态且无重复引用。必须在 Xcode 实际查看图标与引用态，不能只以文件存在、Ruby 语法通过或安装成功代替验收。
- 上述展示挂载及其它 `Pods.xcodeproj` 展示增强都必须先查重，通过 `xcodeproj` API 生成唯一 UUID，禁止手写固定 UUID 或复用已有对象 UUID；只修改必要引用，不加入无关报告等文件。保存后立刻重新打开工程，确认 `p.root_object.isa == "PBXProject"`、根 UUID 未变且文件引用唯一。失败时恢复修改前工程、告警并跳过展示，不阻断依赖安装。历史上不安全的引用写入曾覆盖 `PBXProject` 根 UUID，表现为 `pod install` 正常但 Xcode 左侧 Pods 无法展开；可见性与工程完整性必须一起验收。
- 需要把 `Podfile.deps` 挂进 Xcode Pods 根组时，优先直接复制下面已验证的 hook；不要重新推导 `lastKnownFileType` 或改用手写 PBX UUID。`dependency_path` 固定按 `Pods/Pods.xcodeproj` 相对于 `Podfile.deps` 所在目录设置；已有 `post_install` 时合并到同一个块，保留项目原有逻辑与 Build Settings。本 hook 只添加根组文件引用，不修改 target Build Settings。

  ```ruby
  require 'fileutils'
  require 'securerandom'

  post_install do |installer|
    project_path = installer.pods_project.path
    backup_path = "#{project_path}.repair-backup-#{SecureRandom.hex(8)}"

    begin
      FileUtils.cp(project_path, backup_path) if File.file?(project_path)
      project = installer.pods_project
      root_uuid = project.root_object.uuid
      dependency_path = '../Podfile.deps'
      dependency_refs = project.main_group.files.select do |file|
        file.path == dependency_path
      end
      raise 'Podfile.deps 根组中存在重复引用' if dependency_refs.length > 1

      file_ref = dependency_refs.first
      file_ref ||= project.main_group.new_file(dependency_path)
      file_ref.explicit_file_type = 'text.script.ruby'
      project.save

      reopened = Xcodeproj::Project.open(project_path)
      dependency_refs = reopened.main_group.files.select do |file|
        file.path == dependency_path
      end
      dependency_ref_found = dependency_refs.length == 1 &&
        dependency_refs.first.explicit_file_type == 'text.script.ruby'
      build_phase_refs = reopened.targets.flat_map(&:build_phases).flat_map do |phase|
        phase.respond_to?(:files_references) ? phase.files_references : []
      end
      dependency_ref_in_build_phase = build_phase_refs.any? do |file|
        file.path == dependency_path && file.explicit_file_type == 'text.script.ruby'
      end
      unless reopened.root_object.isa == 'PBXProject' &&
          reopened.root_object.uuid == root_uuid &&
          dependency_ref_found &&
          !dependency_ref_in_build_phase
        raise 'Podfile.deps 引用写入后核验失败'
      end
    rescue StandardError => error
      begin
        FileUtils.cp(backup_path, project_path) if File.file?(backup_path)
      rescue StandardError => restore_error
        warn "[Podfile.deps] Pods 工程恢复失败：#{restore_error.message}"
      end
      warn "[Podfile.deps] Xcode 展示引用维护失败，已跳过：#{error.message}"
    ensure
      FileUtils.rm_f(backup_path)
    end
  end
  ```

#### 1.6.2、iOS 安装与构建挂载脚本的 README 强制同步

- 凡新增或修改挂载到 `pod install` 的外援脚本，或 Xcode 编译 / 编译后的挂载脚本，必须在同一任务更新受影响项目根目录的 `README.md`。触发范围包括脚本本体、调用参数、环境变量、开关、执行条件、顺序和挂载配置；不能只改脚本或只更新脚本目录的说明。移除挂载时同步删除或修正文档中的自动执行声明。
- 固定栏目：Swift 项目写入“项目配置支持”，OC 新、老项目写入“特色一览”，优先合并现有“安装与构建自动挂载脚本”小节。记录当前完整行为，不堆叠变更日志。
- 每项记录脚本入口与相对路径、实际挂载位置、触发时机、执行行为、产物及覆盖规则、日志位置、依赖与迁移要求、执行 / 跳过条件、同步或异步方式，以及失败是否阻断安装或构建；不存在的能力不得推断补写。
- 对照 `Podfile`、podspec 的 `script_phase`、`project.pbxproj` 的 Build Phases、共享 Scheme 的 Pre-actions / Post-actions 与脚本实现核实，只检查实际受影响入口。区分安装前置、`post_install`、`post_integrate`、目标构建阶段和整个 Scheme 构建后动作；不能把最后一个 Build Phase 写成“整个项目编译成功后的回调”，也不能把仅存放在目录内的脚本写成已挂载。
- 共用脚本或跨仓挂载变化必须逐一核对受影响的 Swift、OC 新、OC 老工程，并同步各自 README；保留实际挂载差异，不为文档一致而新增未授权挂载。文档同步不扩大第三方源码修改权限。
- 交付前完成脚本行为与 README 对账、相对链接存在性及 `git diff --check` 检查，说明更新了哪些 README、做了何种验证。未执行 `pod install` 或构建时如实注明；不得仅为验证文档触发安装、构建或外援脚本副作用。

### 1.7、`JobsPodspecKit.rb` / 样例 `*.podspec` 蒸馏规则

- `JobsPodspecKit.rb` 不是普通工具脚本，而是本地 Pod 的 podspec 基座。新增 Pod 时优先复制同类 Pod 的 `JobsPodspecKit.rb`，并把模块名改成当前 Pod 对应的 `JobsPodspecKitForPodName`，不要把多个 Pod 的模块名混用。
- `build_support_context` 负责扫描 `Support` 真实磁盘目录，把每一级有效文件夹收集成 `Support` subspec 路径，并跳过隐藏目录、`Pods`、Demo / Example / Test、文档截图、构建产物、`__MACOSX`、`.bundle`、`.xcassets` 等不该成为 subspec 的目录。
- `add_support_subspec(spec, support_context)` 负责把 `Support` 目录镜像成真实 subspec 树：每个子目录设置 `header_mappings_dir`，直接源码进入 `source_files`，直接头文件进入 `private_header_files`，资源进入 `resources`；没有直接命中文件时用 `preserve_paths` 保留目录。
- `add_dynamic_support_dependencies(ss, spec, support_context)` 只用于真实存在的 subspec，负责让该 subspec 自动依赖所有扫描到的 `Support` subspec。新增、删除、移动 `Support` 子目录后，`pod install` 应能动态反映真实目录结构，不要手写一长串易过期的固定路径。
- `build_file_support_context` / `add_file_support_dependencies` 适合更细的文件级 Support 依赖：只收集真正有源码或资源的路径；如果没有收集到子路径，则回退依赖根 `Support`。
- `apply_standard_exclude_files(spec)` 用统一排除清单兜底，至少覆盖 macOS 垃圾文件、Git / SVN、[**CocoaPods**](https://cocoapods.org/)、[**Xcode**](https://developer.apple.com/xcode) 工程、Demo / Example / Test、文档截图、CI、临时缓存、日志、备份和压缩包。
- `apply_standard_xcconfig(spec)` 是默认收口点。标准 `pod_target_xcconfig` 包含 `DEFINES_MODULE`、`HEADER_SEARCH_PATHS`、`CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES`；标准 `user_target_xcconfig` 指向 `$(PODS_ROOT)/Headers/Public/PodName/**`。确需覆盖时只覆盖最小项，不要无意识扩大或删掉头文件搜索路径。
- 新 Pod 模板先 `require_relative 'JobsPodspecKit'`，再构造 `support_context`，再写基础信息、`spec.source = { :path => '.' }`、入口头文件存在性判断、`spec.header_dir`、`frameworks`、逐行 `dependency`、`add_support_subspec`、根级 `Core` 文件声明、真实 `Resource` 资源声明、标准排除和标准 `xcconfig`；`Core` / `Resource` 的 glob 直接沿用 1.4 / 1.5，不再重复包一层 `spec.subspec 'Core'`。
- 新增资源扩展时，优先同步 `JobsPodspecKit.rb` 的扩展白名单和 podspec 的 `resources` / `resource_bundles`，避免资源被误塞进源码 glob。
- `spec.header_dir = 'PodName'` 要和 Pod 名保持一致。根入口头文件只在真实存在时暴露，避免新建 Pod 初期因为入口头缺失直接 lint 失败。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
