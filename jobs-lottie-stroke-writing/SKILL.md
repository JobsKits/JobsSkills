---
name: jobs-lottie-stroke-writing
description: 当任务涉及汉字一笔一画手写 Lottie、中文标题笔顺动画、hanzi-writer-data、Lottie trim path、未写不显、禁止整字淡入或修正 AI 生成的伪汉字手写动画时使用。
---

# Jobs Lottie Stroke Writing

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[toc]

---

## 🔥 <font id=前言>前言</font>

> 本技能用于复刻 Jobs 认可的汉字手写 Lottie 动画：汉字必须按真实笔顺一笔一画写出来，没有被笔划过的地方不能提前出现。

## 一、核心标准 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 必须使用真实汉字笔顺数据，优先用 `hanzi-writer-data` 的 `medians`；不要凭感觉手写 SVG path，也不要让 AI 画近似字形。
- 每一笔用 Lottie shape path + stroke + trim path 表达，`trim path` 的 end 从 `0 -> 100`，上一笔完成后下一笔再开始。
- 未写到的位置必须不可见。禁止用整字、局部字形、图片、文本层、opacity fade-in 或最终叠加 UILabel/文字层来补字。
- 允许保留笔尖、阴影、高光和已完成笔画，但它们都必须跟随同一笔画路径的 trim 进度出现。
- 最终效果应是“人手按笔顺写出来”，不是“完整汉字先淡出淡入，再顺便画几条线”。

## 二、生成流程 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

1、明确要写的文字，例如 `蒸肉`、`主标题`、`豆花`。

2、准备 `hanzi-writer-data` 数据目录。可以用 npm 包解包后的 `package` 目录，也可以使用项目中已存在的同结构数据目录。

3、使用 `scripts/generate_hanzi_lottie.js` 生成 Lottie JSON：

   ```bash
   node scripts/generate_hanzi_lottie.js \
     --text "蒸肉" \
     --name "JobsCategoryTitleWriting_ZhengRou" \
     --out ./JobsCategoryTitleWriting_ZhengRou.json \
     --data-dir /tmp/hanzi-writer-data-pack/package
   ```

4、在 App 里只播放生成的 Lottie。不要在动画结束后再出现另一个 UILabel、CATextLayer、图片字或完整文案。

5、修改或新增多个标题时，为每个入口生成独立 JSON，名称要稳定，便于 Controller 按标题映射资源。

## 三、Lottie 结构约束 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- `layers` 里每一笔至少有一层 `Ink stroke N`，并且该层必须同时包含：
  - `ty: "sh"`：来自当前笔画 median points 的路径。
  - `ty: "st"`：可见笔画线条，`lc` 和 `lj` 用 round。
  - `ty: "tm"`：写字进度，`e` 从 `0` 动到 `100`。
- 可以追加 `Ink shadow N`、`Ink highlight N`、`Brush tip`，但都必须和当前笔画同一段时间、同一条路径或同一支笔尖轨迹。
- 不要生成非笔尖用途的 `ty: "fl"`。如果 JSON 里出现 fill，必须确认它只属于 `Brush tip`，不能属于汉字本体。
- 多字标题按字符顺序写；同一字内部按 `hanzi-writer-data` 的 stroke 顺序写；字符之间可以留短暂停顿。
- 中文坐标需要从 Hanzi Writer 的 `1024 x 1024` 字框映射到 Lottie 画布，并反转 y 轴：`mappedY = startY + ((1024 - y) / 1024) * charSize`。

## 四、视觉参数 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 默认画布可用 `420 x 130`，用于标题区横向文字；多字标题按总宽度居中。
- 主笔画宽度建议约为 `charSize * 0.08`，阴影略宽，高光约主笔画三分之一。
- 笔画颜色可以按业务 UI 调整，但不要用纯色块或大面积填充替代手写路径。
- 每笔持续时间按路径长度估算，短笔不小于约 `4.2` 帧，长笔不大于约 `10.5` 帧；笔画之间留约 `1.8` 帧呼吸。
- 笔尖可以是小椭圆，跟随当前笔画路径移动，结束后消失。

## 五、质量检查 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 逐帧看动画开头：第一笔未开始前，不能看到任何完整字形或浅色底字。
- 暂停在中间帧：只能看到已经写过的笔画和正在写的当前笔画，不能看到未来笔画。
- 查 JSON：`Ink stroke` 数量必须等于总笔画数；每个 `Ink stroke` 必须有对应 `tm`；汉字本体 `nonTipFills` 必须为 `0`。
- 查 App UI：不要有动画结束后叠加的新文案，也不要用 UILabel 在 Lottie 上面补“正确汉字”。
- 如果用户指出“写出来不是中国字”，优先怀疑手写 path 数据来源错误、坐标 y 轴没翻转、字符文件缺失或用了 AI 自造路径。

更细的验收命令见 [references/stroke-lottie-quality.md](references/stroke-lottie-quality.md)。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
