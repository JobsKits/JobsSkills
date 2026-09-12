# Stroke Lottie Quality Checks

## JSON 扫描

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

## 人眼验收

- 开头帧不能出现完整文字轮廓。
- 中间帧不能提前出现后续笔画。
- 最后一帧是由已写笔画自然累计出来的字，不是额外叠加的文字层。
- 如果 Lottie 预览正确，但 App 里又出现第二份文案，检查 Controller 是否保留 UILabel、CATextLayer、图片字或结束回调补文案。

## 常见错误

- `hanzi-writer-data` 的 y 坐标没有反转，字会倒置或结构异常。
- 使用 AI 生成 path，汉字会像“假中文”，尤其复杂字的部件位置容易错。
- 先放完整字形再用透明度淡入，即使叠了笔画线，也不符合“没有划过的地方不出来”。
- 使用 Lottie text layer 作为最终字形，会让动画变成“写线条 + 显示文字”，不是真手写。
