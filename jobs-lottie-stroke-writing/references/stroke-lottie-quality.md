# <span id="前言">Stroke [**Lottie**](https://airbnb.io/lottie/) Quality Checks</span>

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [一、JSON 扫描](#json-scan)
- [二、人眼验收](#visual-review)
- [三、常见错误](#common-errors)

</details>
<!-- jobs-toc:end -->

---

## 一、<span id="json-scan">[**JSON**](https://www.json.org/json-en.html) 扫描</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

检查每个 Lottie 是否只有笔尖 fill，汉字本体没有 fill，并且每个主笔画都有 trim path：

```bash
node - <<'NODE'
const fs = require('fs');
for (const file of process.argv.slice(1)) {
  const json = JSON.parse(fs.readFileSync(file, 'utf8'));
  let nonTipFills = 0;
  let tipFills = 0;
  let inkStrokes = 0;
  let inkTrims = 0;
  const walk = (node, layerName) => {
    if (!node || typeof node !== 'object') return;
    if (node.ty === 'fl') {
      if (/^Brush tip/.test(layerName)) tipFills++;
      else nonTipFills++;
    }
    if (node.ty === 'st' && /^Ink stroke/.test(layerName)) inkStrokes++;
    if (node.ty === 'tm' && /^Ink stroke/.test(layerName)) inkTrims++;
    for (const value of Object.values(node)) {
      if (Array.isArray(value)) value.forEach(item => walk(item, layerName));
      else if (value && typeof value === 'object') walk(value, layerName);
    }
  };
  for (const layer of json.layers || []) walk(layer, layer.nm || layer.n || '');
  console.log(`${file}: inkStrokes=${inkStrokes}, inkTrims=${inkTrims}, tipFills=${tipFills}, nonTipFills=${nonTipFills}, op=${json.op}`);
  if (nonTipFills !== 0 || inkStrokes === 0 || inkStrokes !== inkTrims) process.exitCode = 1;
}
NODE
```

## 二、<span id="visual-review">人眼验收</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 开头帧不能出现完整文字轮廓。
- 中间帧不能提前出现后续笔画。
- 最后一帧是由已写笔画自然累计出来的字，不是额外叠加的文字层。
- 如果 Lottie 预览正确，但 App 里又出现第二份文案，检查 Controller 是否保留 UILabel、CATextLayer、图片字或结束回调补文案。

## 三、<span id="common-errors">常见错误</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- `hanzi-writer-data` 的 y 坐标没有反转，字会倒置或结构异常。
- 使用 AI 生成 path，汉字会像“假中文”，尤其复杂字的部件位置容易错。
- 先放完整字形再用透明度淡入，即使叠了笔画线，也不符合“没有划过的地方不出来”。
- 使用 Lottie text layer 作为最终字形，会让动画变成“写线条 + 显示文字”，不是真手写。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
