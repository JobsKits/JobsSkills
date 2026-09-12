---
name: jobs-auth-switch-motion
description: >
  蒸馏 JobsAppDoor-1 和 JobsAppDoor-2 的注册/登录切换动画。Use when Codex needs to create,
  rebuild, port, or describe an auth screen where login and register switch with the same motion
  language: side-rail morphing panel, separate-card slide transition, entrance pop, keyboard lift,
  iOS UIKit/SwiftUI/web animation equivalents, or Jobs 登录注册切换动效复刻。
---

# Jobs Auth Switch Motion

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[toc]

---

## 🔥 <font id=前言>前言</font>

> 本技能用于蒸馏 JobsAppDoor 登录 / 注册切换动效。重点保留运动骨架、状态关系、节奏和层级，不复刻旧界面的视觉包袱。

## 一、核心目标 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

新建一套登录/注册 UI 时，不要复刻旧界面外观；只复刻动画骨架、状态关系、节奏和层级运动。先做干净的新 UI，再把下面两种动效配方之一套上去。

## 二、模式选择 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- `JobsAppDoor-1 / morphing-panel`: 登录和注册共用同一个内容面板。切换时面板尺寸变高、竖向切换按钮从右边换到左边，登录输入框横向让位，注册额外输入框出现。
- `JobsAppDoor-2 / sliding-cards`: 登录卡片和注册卡片是两个独立视图。切换时旧卡片滑出屏幕左侧，新卡片从屏幕外滑到中心，客服按钮跟随当前卡片底部落点移动。
- 如果用户只说“像 JobsAppDoor 登录注册切换”，默认优先用 `morphing-panel`；如果用户明确要两个页面/两张卡片/横向切换，用 `sliding-cards`。

## 三、共同动效基因 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 入口动效：主卡片、Logo、客服按钮在首次出现时做 `scale 0.01 -> 1.1 -> 1.0` 的 keyframe pop，持续 `1s`，`easeInEaseOut`。这是“先吸出来，再轻微过冲回落”的入场感。
- 状态不靠纯透明度表达。切换时必须至少同时改变 `position/frame`，必要时叠加 `alpha`、按钮标题、颜色和输入框边框。
- 所有登录/注册切换先收键盘，再切状态。输入框编辑中的键盘顶起不属于主切换动画，但要一起兼容。
- 需要真实几何位置时，优先动画 `frame/center/transform`，或改约束后在动画块里 `layoutIfNeeded`。不要只改 Masonry/SnapKit 约束却不触发布局。

## 四、方案一：Morphing Panel <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 4.1、静态结构

- 一个 `contentPanel` 同时承载登录与注册。
- 一个竖向 `switchRail`，宽度约 `64pt`，登录态贴右边，注册态贴左边。
- 登录输入框只有账号、密码两项；注册态复用这两个输入框，再追加确认密码、手机号、验证码等输入框。
- 标题、提交按钮、返回首页按钮都在同一个面板里根据状态改文案和位置。

### 4.2、登录态

- `contentPanel.frame = loginFrame`，高度较短。
- `switchRail.frame = right edge`，文案是“新用户注册”一类竖排入口。
- 标题居中于 `contentPanel.width - railWidth` 的左侧内容区。
- 账号/密码输入框 `x = horizontalPadding`。
- 记住密码、忘记密码等登录辅助项 `alpha = 1`。
- 提交按钮文案为登录，底部位置按登录面板高度计算。

### 4.3、注册态

- `contentPanel.frame = registerFrame`，高度明显变高。
- `switchRail.frame = left edge`，文案改成“返回登录”一类竖排入口。
- 标题居中于 `contentPanel.width + railWidth` 的右侧内容区。
- 账号/密码输入框整体向右平移 `railWidth`，形成“给左侧竖栏让位”的效果。
- 注册额外输入框首次创建在账号/密码下方，以 `inputHeight + verticalGap` 逐项堆叠；后续切换只恢复 `alpha = 1`。
- 登录辅助项 `alpha = 0`；提交按钮文案为注册，底部位置按注册面板高度计算。

### 4.4、动画事务

把以下变化放进同一个动画事务，父容器和子面板都要参与同一帧提交：

- `duration = 0.7s`
- `delay = 0.1s`
- `spring damping = 1.0`
- `initial velocity = 0.1`
- `curve = easeInOut`

这组参数几乎不弹跳，重点是“稳、顺、同屏变形”。切注册时执行：切按钮选中态 -> 改面板 frame -> 改 rail frame/颜色/文案 -> 平移共享输入框 -> 创建或显示注册额外输入框 -> 淡出登录辅助项 -> 更新提交按钮。切登录时按反方向恢复，注册额外输入框淡出到 `alpha = 0`，不要销毁。

## 五、方案二：Sliding Cards <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 5.1、静态结构

- `loginCard` 和 `registerCard` 是两个独立内容视图，尺寸可以不同。
- 初始：`loginCard.x = 20` 左右边距内居中；`registerCard.x = screenWidth + 20`，放在屏幕右侧外。
- 两张卡片 `y` 一致，约在屏幕高度 `1/4`；注册卡片高度大于登录卡片。
- `customerServiceButton` 不属于卡片内部，放在当前卡片下方 `8pt` 左右，并在切换时跟随当前卡片底部。

### 5.2、切到注册

- 先设置当前页为注册。
- `loginCard` 退出：滑到屏幕左侧外，目标 `x = -(card.width + card.x)`，`y` 回到初始 y。
- `registerCard` 进入：`centerX = screenWidth / 2`，`centerY` 可按传入 offset 微调，默认 offset 为 `0`。
- `customerServiceButton.y = registerCard.top + registerCard.height + 8`。

### 5.3、切回登录

- 先设置当前页为登录。
- `registerCard` 按同样方式退出到屏幕左侧外。
- `loginCard` 从当前屏幕外位置回到中心。
- `customerServiceButton.y = loginCard.top + loginCard.height + 8`。

### 5.4、动画事务

卡片进出和客服按钮跟随都使用同一组弹簧参数：

- `duration = 2s`
- `delay = 0.1s`
- `spring damping = 0.3`
- `initial velocity = 10`
- `curve = easeInOut`

这组参数故意很“弹”：耗时长、速度大、阻尼低，带明显弹簧回拉。要让旧卡和新卡同时动，不要先等退出完成再进入。

## 六、键盘顶起 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

如果登录/注册表单里输入框较多，记录当前激活输入框 index 和上次激活 index：

- 有输入框编辑时：`delta = currentIndex - lastIndex`，把 Logo、当前卡片/面板、备用卡片和客服按钮一起 `y -= 40 * delta`。
- 没有输入框编辑时：把这些视图恢复到初始化缓存的 y。
- 每次键盘通知处理结束后重置 `isEditingAnyInput = false`，避免下一轮残留。

## 七、跨端落地 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- UIKit：`UIView animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:` 可直接表达两套参数；入口 pop 用 `CAKeyframeAnimation` 的 `transform`。
- SwiftUI：Pattern 1 用状态驱动 `frame/offset/opacity`，动画用 `.spring(response: 0.7, dampingFraction: 1)` 近似；Pattern 2 用低阻尼 spring 和较长 response 近似。
- Web/React：Pattern 1 用高阻尼 spring 或 cubic ease-in-out；Pattern 2 用低阻尼 spring。不要用只改 display/opacity 的切换。
- 新 UI 可以改色、排版、圆角、字体和素材，但必须保留：切换触发点、面板/卡片运动方向、时长层级、按钮/辅助项跟随逻辑。

## 八、质量检查 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- Pattern 1 验收：同一面板在屏幕上变形；竖向按钮左右换边；账号/密码不是重建，而是横向让位；注册额外项出现；登录辅助项淡出。
- Pattern 2 验收：登录和注册是两张独立卡片；旧卡滑出左侧；新卡滑到中心；客服按钮跟着目标卡片底部移动；整体有明显弹簧感。
- 入口验收：页面初现有 `0.01 -> 1.1 -> 1.0` 的 pop，不是简单 fade in。
- 视觉验收：不要复刻旧 UI 的脏色和拥挤排版；动效像，界面可以更现代。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
