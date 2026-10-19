# [**iOS**](https://developer.apple.com/ios/) 主题对比共同规范

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#%E5%89%8D%E8%A8%80)
- [一、文字与实际背景必须清楚区分](#readability)
- [二、白天 / 黑夜与主副标题层级](#title-hierarchy)
- [三、成对的语义颜色与有效主题](#theme-binding)
- [四、交付验收](#verification)

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

> 适用于 Jobs 自维护 iOS 页面，包括 [**UIKit**](https://developer.apple.com/documentation/uikit)、[**SwiftUI**](https://developer.apple.com/documentation/swiftui)、[**OC**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) 新旧工程及运行于 iOS 的 [**Flutter**](https://flutter.dev/) 页面。这里只规定共同视觉原则；各语言继续使用自己的主题封装和 API，不把 <u>[**Swift**](https://www.swift.org/)</u> 写法强加给 OC / Flutter。

## 一、<span id="readability">文字与实际背景必须清楚区分</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 任何主题模式下，文字与承载背景必须保持足够明暗对比；“相对立”指亮度差，不要求互补色。禁止浅底浅字、深底深字，以及虽色相不同但亮度相近的组合。优先级固定为可读性 → 主次层级 → 装饰配色。
- 前景与背景作为一对验收，判断文字所在的卡片、按钮、输入框、导航栏、弹窗或选中区域的实际底色，不能只看页面总背景。白天里的深色品牌按钮仍配浅字，黑夜里的浅色卡片仍配深字。
- 工程默认以对比度 `≥ 4.5:1` 验收需要阅读的文字，主标题、正文、副标题、说明、输入文字、占位及按钮状态文字都适用。这是 Jobs 的统一工程基线，参考 [**WCAG 2.2 普通文字对比要求**](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)；不能因“副标题”“禁用态”或“使用系统语义色”就跳过实际对比检查。

## 二、<span id="title-hierarchy">白天 / 黑夜与主副标题层级</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| 模式 | 页面 / 内容背景 | 主标题、正文 | 副标题、补充说明 |
| --- | --- | --- | --- |
| 白天 | 白色或偏浅色 | 黑色或偏深色 | 比主标题更浅、向白色靠近的次要深灰，仍明显深于背景 |
| 黑夜 | 黑色或偏深色 | 白色或偏浅色 | 比主标题更深、向黑色靠近的次要浅灰，仍明显亮于背景 |

- 同一常规内容背景上，白天亮度关系为“背景 > 副标题 > 主标题”，黑夜为“主标题 > 副标题 > 背景”；在这个层级内同时满足[可读性基线](#readability)。特殊局部背景按该区域实际明暗调整，保持主标题对比更强、副标题次之。
- 副标题负责补充主标题内容，重要程度更次；“弱化”只表示相对主标题降低强调程度，不能淡到与背景混在一起。颜色层级之外，可结合字重、字号与间距表达主次，禁止仅把副标题透明度一味调低。

## 三、<span id="theme-binding">成对的语义颜色与有效主题</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 先定义 / 复用页面背景、内容背景、主文字、次文字及按钮前景 / 背景角色，每个角色分别核对白天和黑夜取值；不要把一个固定灰色、白色或黑色跨模式复用为通用文字色。系统语义色同样必须与实际底色配对检查。
- 跟随宿主当前有效主题；App 手动指定的主题可能与系统外观不同，不能只按系统当前明暗解析颜色。跟随系统模式则随系统外观变化更新；主题切换同步更新前景和背景，包括已打开页面、复用控件、富文本及自绘内容。
- 透明背景需追溯实际底层；半透明文字 / 蒙层按合成后的颜色计算，不能只检查原始色值。图片、渐变和动态素材上的文字要保证承载区域中对比最弱的位置也可读，必要时增加稳定底板或调整蒙层后复核。

## 四、<span id="verification">交付验收</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

1、通过真实主题入口检查白天、黑夜、跟随系统；手动主题与系统相反时也要核对。覆盖首屏、详情 / 返回、弹窗、列表复用、空态、输入及按钮常态 / 选中 / 高亮 / 禁用 / 组合态，反复切换后主副标题层级仍正确。

2、逐项记录需要阅读文字的有效前景 / 实际背景颜色及对比度，结合实机或模拟器截图检查可读性。数值以解析并合成后的颜色计算，截图用于检查实际视觉；选了 `secondaryLabel` 或只编译成功均不能代替验收。

3、对比验收针对需要用户阅读的稳定展示态；登录 / 注册入场、退场中的短暂淡入淡出仍遵守原动效，动画完成后必须达标。无法运行界面时明确说明仅完成规则或静态检查，不宣称已通过视觉验收。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
