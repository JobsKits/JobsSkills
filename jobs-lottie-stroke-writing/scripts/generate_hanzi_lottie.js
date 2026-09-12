#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const defaults = {
  width: 420,
  height: 130,
  fps: 30,
  bgPause: 4,
  gap: null,
};

function usage() {
  console.log(`Usage:
  node scripts/generate_hanzi_lottie.js --text "蒸肉" --out ./title.json --data-dir /path/to/hanzi-writer-data/package [options]

Options:
  --text TEXT        Chinese text to write.
  --out FILE         Output Lottie JSON file.
  --name NAME        Lottie composition name. Defaults to output basename.
  --data-dir DIR     Directory containing hanzi-writer-data JSON files.
  --width N          Canvas width. Default: 420.
  --height N         Canvas height. Default: 130.
  --fps N            Frame rate. Default: 30.
  --gap N            Gap between characters. Default: 8 for 3+ chars, else 10.
`);
}

function parseArgs(argv) {
  const args = { ...defaults };
  for (let i = 2; i < argv.length; i++) {
    const key = argv[i];
    const next = argv[i + 1];
    if (key === '--help' || key === '-h') {
      args.help = true;
    } else if (key === '--text') {
      args.text = next;
      i++;
    } else if (key === '--out') {
      args.out = next;
      i++;
    } else if (key === '--name') {
      args.name = next;
      i++;
    } else if (key === '--data-dir') {
      args.dataDir = next;
      i++;
    } else if (key === '--width') {
      args.width = Number(next);
      i++;
    } else if (key === '--height') {
      args.height = Number(next);
      i++;
    } else if (key === '--fps') {
      args.fps = Number(next);
      i++;
    } else if (key === '--gap') {
      args.gap = Number(next);
      i++;
    } else {
      throw new Error(`Unknown argument: ${key}`);
    }
  }
  if (args.help) return args;
  if (!args.text) throw new Error('Missing --text');
  if (!args.out) throw new Error('Missing --out');
  if (!args.dataDir) throw new Error('Missing --data-dir');
  if (!Number.isFinite(args.width) || args.width <= 0) throw new Error('Invalid --width');
  if (!Number.isFinite(args.height) || args.height <= 0) throw new Error('Invalid --height');
  if (!Number.isFinite(args.fps) || args.fps <= 0) throw new Error('Invalid --fps');
  args.name = args.name || path.basename(args.out, path.extname(args.out));
  return args;
}

function round(n) {
  return Math.round(n * 100) / 100;
}

function pt2(p) {
  return [round(p[0]), round(p[1])];
}

function pt3(p) {
  return [round(p[0]), round(p[1]), 0];
}

function easeOut() {
  return { x: [0.25], y: [0] };
}

function easeIn() {
  return { x: [0.55], y: [1] };
}

function dist(a, b) {
  return Math.hypot(a[0] - b[0], a[1] - b[1]);
}

function pathLength(points) {
  let length = 0;
  for (let i = 1; i < points.length; i++) length += dist(points[i - 1], points[i]);
  return length;
}

function readCharData(dataDir, ch) {
  const file = path.join(dataDir, `${ch}.json`);
  if (!fs.existsSync(file)) {
    throw new Error(`Missing hanzi-writer-data file for "${ch}": ${file}`);
  }
  const data = JSON.parse(fs.readFileSync(file, 'utf8'));
  if (!Array.isArray(data.medians)) {
    throw new Error(`Invalid hanzi-writer-data for "${ch}": missing medians`);
  }
  return data;
}

function mapPoint(rawPoint, charIndex, charSize, gap, startX, startY) {
  const [x, y] = rawPoint;
  return [
    startX + charIndex * (charSize + gap) + (x / 1024) * charSize,
    startY + ((1024 - y) / 1024) * charSize,
  ];
}

function titleStrokeData(args) {
  const chars = Array.from(args.text);
  const gap = args.gap == null ? (chars.length >= 3 ? 8 : 10) : args.gap;
  const maxCharSize = chars.length >= 3 ? 106 : 112;
  const charSize = Math.min(maxCharSize, (args.width - 44 - gap * (chars.length - 1)) / chars.length, args.height - 18);
  const totalWidth = chars.length * charSize + (chars.length - 1) * gap;
  const startX = (args.width - totalWidth) / 2;
  const startY = (args.height - charSize) / 2;
  const strokes = [];

  chars.forEach((ch, charIndex) => {
    const data = readCharData(args.dataDir, ch);
    data.medians.forEach((median, strokeIndex) => {
      const points = median.map(point => mapPoint(point, charIndex, charSize, gap, startX, startY));
      if (points.length > 1) strokes.push({ ch, charIndex, strokeIndex, points });
    });
  });

  return { strokes, charSize };
}

function transform() {
  return {
    ty: 'tr',
    p: { a: 0, k: [0, 0], ix: 2 },
    a: { a: 0, k: [0, 0], ix: 1 },
    s: { a: 0, k: [100, 100], ix: 3 },
    r: { a: 0, k: 0, ix: 6 },
    o: { a: 0, k: 100, ix: 7 },
    sk: { a: 0, k: 0, ix: 4 },
    sa: { a: 0, k: 0, ix: 5 },
    nm: 'Transform',
  };
}

function layerKs(extra = {}) {
  return Object.assign({
    a: { a: 0, k: [0, 0, 0], ix: 1 },
    p: { a: 0, k: [0, 0, 0], ix: 2 },
    s: { a: 0, k: [100, 100, 100], ix: 6 },
    r: { a: 0, k: 0, ix: 10 },
    o: { a: 0, k: 100, ix: 11 },
  }, extra);
}

function trimPath(start, end) {
  return {
    ty: 'tm',
    s: { a: 0, k: 0, ix: 1 },
    e: {
      a: 1,
      k: [
        { t: round(start), s: [0], i: easeIn(), o: easeOut(), e: [100] },
        { t: round(end), s: [100] },
      ],
      ix: 2,
    },
    o: { a: 0, k: 0, ix: 3 },
    m: 1,
    nm: 'Write on',
    hd: false,
  };
}

function strokeShape(points) {
  return {
    ty: 'sh',
    ks: {
      a: 0,
      k: {
        i: points.map(() => [0, 0]),
        o: points.map(() => [0, 0]),
        v: points.map(pt2),
        c: false,
      },
      ix: 2,
    },
    nm: 'Stroke order median',
    hd: false,
  };
}

function strokeLayer(index, name, stroke, start, end, color, width, opacity = 100) {
  const items = [
    strokeShape(stroke.points),
    {
      ty: 'st',
      c: { a: 0, k: color, ix: 3 },
      o: { a: 0, k: opacity, ix: 4 },
      w: { a: 0, k: width, ix: 5 },
      lc: 2,
      lj: 2,
      ml: 4,
      bm: 0,
      nm: name,
      hd: false,
    },
    trimPath(start, end),
    transform(),
  ];
  return {
    ddd: 0,
    ind: index,
    ty: 4,
    nm: name,
    sr: 1,
    ks: layerKs(),
    ao: 0,
    shapes: [{ ty: 'gr', it: items, nm: `${name} group`, np: items.length, cix: 2, bm: 0, hd: false }],
    ip: 0,
    op: 10000,
    st: 0,
    bm: 0,
  };
}

function positionKeyframes(points, start, end) {
  const total = Math.max(pathLength(points), 1);
  const frames = [];
  let walked = 0;
  for (let i = 0; i < points.length - 1; i++) {
    const segLen = dist(points[i], points[i + 1]);
    const t = start + (walked / total) * (end - start);
    frames.push({ t: round(t), s: pt3(points[i]), i: easeIn(), o: easeOut(), e: pt3(points[i + 1]) });
    walked += segLen;
  }
  frames.push({ t: round(end), s: pt3(points[points.length - 1]) });
  return frames;
}

function brushLayer(index, stroke, start, end) {
  const items = [
    { ty: 'el', p: { a: 0, k: [0, 0], ix: 3 }, s: { a: 0, k: [15, 12], ix: 2 }, nm: 'Brush tip', hd: false },
    { ty: 'fl', c: { a: 0, k: [1.0, 0.94, 0.58, 1], ix: 4 }, o: { a: 0, k: 100, ix: 5 }, r: 1, bm: 0, nm: 'Tip fill', hd: false },
    transform(),
  ];
  return {
    ddd: 0,
    ind: index,
    ty: 4,
    nm: 'Brush tip',
    sr: 1,
    ks: layerKs({ p: { a: 1, k: positionKeyframes(stroke.points, start, end), ix: 2 }, r: { a: 0, k: -10, ix: 10 } }),
    ao: 0,
    shapes: [{ ty: 'gr', it: items, nm: 'Brush tip group', np: items.length, cix: 2, bm: 0, hd: false }],
    ip: round(start),
    op: round(end + 2),
    st: 0,
    bm: 0,
  };
}

function build(args) {
  const { strokes, charSize } = titleStrokeData(args);
  const mainWidth = round(charSize * 0.082);
  const shadowWidth = round(mainWidth + 3.2);
  const highlightWidth = round(mainWidth * 0.36);
  let current = args.bgPause;
  let ind = 1;
  const brushLayers = [];
  const highlightLayers = [];
  const mainLayers = [];
  const shadowLayers = [];

  strokes.forEach((stroke, idx) => {
    const len = pathLength(stroke.points);
    const duration = Math.max(4.2, Math.min(10.5, len / 17));
    const start = current;
    const end = current + duration;
    brushLayers.push(brushLayer(ind++, stroke, start, end));
    highlightLayers.push(strokeLayer(ind++, `Ink highlight ${idx + 1}`, stroke, start, end, [1, 0.97, 0.63, 1], highlightWidth, 75));
    mainLayers.push(strokeLayer(ind++, `Ink stroke ${idx + 1}`, stroke, start, end, [1, 0.86, 0.34, 1], mainWidth, 100));
    shadowLayers.push(strokeLayer(ind++, `Ink shadow ${idx + 1}`, stroke, start, end, [0.34, 0.16, 0.04, 1], shadowWidth, 48));
    current = end + 1.8;
    const next = strokes[idx + 1];
    if (next && next.charIndex !== stroke.charIndex) current += 4;
  });

  return {
    v: '4.8.0',
    fr: args.fps,
    ip: 0,
    op: Math.ceil(current + 8),
    w: args.width,
    h: args.height,
    nm: args.name,
    ddd: 0,
    assets: [],
    layers: [...brushLayers, ...highlightLayers, ...mainLayers, ...shadowLayers],
    markers: [],
  };
}

function main() {
  try {
    const args = parseArgs(process.argv);
    if (args.help) {
      usage();
      return;
    }
    const json = build(args);
    fs.mkdirSync(path.dirname(path.resolve(args.out)), { recursive: true });
    fs.writeFileSync(args.out, JSON.stringify(json));
    const strokeCount = json.layers.filter(layer => /^Ink stroke/.test(layer.nm || '')).length;
    console.log(`${args.out} <- ${args.text}: strokes=${strokeCount}, op=${json.op}, layers=${json.layers.length}`);
  } catch (error) {
    console.error(`[generate_hanzi_lottie] ${error.message}`);
    usage();
    process.exit(1);
  }
}

main();
