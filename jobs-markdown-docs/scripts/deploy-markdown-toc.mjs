// Created by Jobs on 2026年10月18日，星期日.
// Deploy only a reviewed inventory; this program never stages or commits files.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { execFileSync, spawnSync } from 'node:child_process';
import { cleanMarkdown, smudgeMarkdown, inspectMarkdown } from '../assets/markdown-toc/MarkdownToc.mjs';

const ASSETS = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../assets/markdown-toc');
const DIRECTORY = '.jobs-markdown-toc';
const START = '# jobs-markdown-toc:start';
const END = '# jobs-markdown-toc:end';
const DRIVER = 'jobs-markdown-toc';
const KEYS = ['clean', 'smudge', 'required'].map(key => `filter.${DRIVER}.${key}`);
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const decode = bytes => new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes);

function git(root, args, options = {}) {
  return execFileSync('git', args, { cwd: root, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' },
    encoding: 'utf8', maxBuffer: 64 * 1024 * 1024, stdio: ['pipe', 'pipe', 'pipe'], ...options });
}

export function attributePattern(relative) {
  const pattern = '/' + relative.replace(/[\\*?\[\]]/g, value => '\\' + value);
  let quoted = '"';
  for (const byte of Buffer.from(pattern)) {
    if (byte === 34 || byte === 92) quoted += '\\' + String.fromCharCode(byte);
    else if (byte >= 32 && byte <= 126) quoted += String.fromCharCode(byte);
    else quoted += '\\' + byte.toString(8).padStart(3, '0');
  }
  return quoted + '"';
}

function attributesFor(original, files) {
  const startMatches = [...original.matchAll(/^# jobs-markdown-toc:start\r?$/gm)];
  const endMatches = [...original.matchAll(/^# jobs-markdown-toc:end\r?$/gm)];
  const starts = startMatches.length;
  const ends = endMatches.length;
  if (original.split(START).length - 1 !== starts || original.split(END).length - 1 !== ends) throw new Error('Git 属性标记不是独占行，保留原文。');
  if (starts !== ends || starts > 1 || (starts && original.indexOf(START) > original.indexOf(END))) throw new Error('Git 属性受控块不完整或重复。');
  const block = [START, ...files.map(file => `${attributePattern(file)} filter=${DRIVER}`), END].join('\n');
  if (starts) return original.slice(0, original.indexOf(START)) + block + original.slice(original.indexOf(END) + END.length);
  return original + (original && !original.endsWith('\n') ? '\n' : '') + '\n' + block + '\n';
}

function values(root, key) {
  const result = spawnSync('git', ['config', '--local', '--null', '--get-all', key], { cwd: root, encoding: 'utf8' });
  if (result.status === 1) return [];
  if (result.status !== 0) throw new Error('不能读取本仓过滤器配置。');
  return result.stdout.split('\0').slice(0, -1);
}

function restoreValues(root, key, list) {
  const result = spawnSync('git', ['config', '--local', '--unset-all', key], { cwd: root, encoding: 'utf8' });
  if (result.status !== 0 && result.status !== 5) throw new Error('不能恢复本仓过滤器配置。');
  for (const value of list) git(root, ['config', '--local', '--add', key, value]);
}

function inside(root, file) {
  const relative = path.relative(root, file);
  return relative && !relative.startsWith('../') && !path.isAbsolute(relative);
}

function main(args) {
  if (['GIT_DIR', 'GIT_WORK_TREE', 'GIT_COMMON_DIR', 'GIT_INDEX_FILE'].some(key => process.env[key])) {
    throw new Error('批量部署不接受外部 Git 仓库或索引定位覆盖，未修改任何仓库。');
  }
  const apply = args.includes('--apply');
  const option = name => { const index = args.indexOf(name); return index < 0 ? null : args[index + 1]; };
  const inventoryPath = option('--inventory');
  const reportPath = option('--report');
  if (!inventoryPath || !reportPath) throw new Error('用法：node deploy-markdown-toc.mjs --inventory 已审核清单.json --report 报告.json [--apply]');
  const inventory = JSON.parse(decode(fs.readFileSync(inventoryPath)));
  const scope = fs.realpathSync(inventory.root);
  const grouped = new Map();
  for (const candidate of inventory.candidates) {
    if (candidate.approved !== true) continue;
    if (fs.lstatSync(candidate.path).isSymbolicLink()) throw new Error('候选文件是符号链接。');
    const file = fs.realpathSync(candidate.path);
    const root = fs.realpathSync(candidate.repoRoot);
    if (path.relative(path.resolve(candidate.repoRoot), path.resolve(candidate.path)) !== path.relative(root, file)) throw new Error('候选经过了仓内符号链接目录。');
    if (!inside(scope, file) || (root !== scope && !inside(scope, root)) || !inside(root, file)) throw new Error('候选路径越过授权根目录。');
    const relative = path.relative(root, file).split(path.sep).join('/');
    if (!/\.md$/i.test(relative)) throw new Error('候选不是 .md 文档。');
    if (!grouped.has(root)) grouped.set(root, []);
    grouped.get(root).push({ ...candidate, path: file, relative });
  }
  const report = { version: 1, scope, applied: apply, started: new Date().toISOString(), repositories: [], excluded: inventory.excluded ?? [] };
  const backupRoot = path.resolve(path.dirname(reportPath), 'backups');
  fs.mkdirSync(path.dirname(reportPath), { recursive: true, mode: 0o700 });
  if (apply) fs.mkdirSync(backupRoot, { recursive: true, mode: 0o700 });
  const template = fs.readFileSync(path.join(ASSETS, 'MarkdownToc.mjs'));
  const readme = fs.readFileSync(path.join(ASSETS, 'README.md'));
  const flush = () => fs.writeFileSync(reportPath, JSON.stringify(report, null, 2) + '\n', { mode: 0o600 });
  for (const [root, candidates] of [...grouped].sort(([a], [b]) => a.localeCompare(b))) {
    const result = { root, candidateCount: candidates.length, status: 'planning' };
    report.repositories.push(result);
    let backups = [];
    let previousConfig;
    let installedConfig;
    const written = new Map();
    try {
      if (fs.realpathSync(git(root, ['rev-parse', '--show-toplevel']).trim()) !== root) throw new Error('Git 根不匹配。');
      const directory = path.join(root, DIRECTORY);
      if (fs.existsSync(directory) && (fs.lstatSync(directory).isSymbolicLink() || !fs.existsSync(path.join(directory, 'manifest.json')))) {
        throw new Error('工具目录已存在但没有本工具清单，保留现场。');
      }
      if (fs.existsSync(directory) && fs.realpathSync(git(directory, ['rev-parse', '--show-toplevel']).trim()) !== root) throw new Error('工具目录属于嵌套独立 Git，保留原状。');
      const stateFile = path.resolve(root, git(root, ['rev-parse', '--git-path', 'jobs-markdown-toc.json']).trim());
      const targets = [path.join(root, '.gitattributes'), path.join(directory, 'MarkdownToc.mjs'), path.join(directory, 'manifest.json'), path.join(directory, 'README.md'), stateFile];
      for (const file of targets) {
        try { if (fs.lstatSync(file).isSymbolicLink()) throw new Error(`不覆盖符号链接：${path.basename(file)}`); }
        catch (error) { if (error.code !== 'ENOENT') throw error; }
      }
      for (const candidate of candidates) {
        const bytes = fs.readFileSync(candidate.path);
        if (candidate.sha256 && hash(bytes) !== candidate.sha256) throw new Error(`盘点后文档已变化：${candidate.relative}`);
        const source = decode(bytes);
        if (!inspectMarkdown(source).tocCount) throw new Error(`没有有效目录标签：${candidate.relative}`);
        if (smudgeMarkdown(source) !== source) throw new Error(`批量部署只接收本地标签形态；请先单仓安装还原：${candidate.relative}`);
        const generated = cleanMarkdown(source);
        if (smudgeMarkdown(generated) !== smudgeMarkdown(source) || cleanMarkdown(generated) !== generated) throw new Error(`文档往返失败：${candidate.relative}`);
      }
      let previousFiles = [];
      if (fs.existsSync(path.join(directory, 'manifest.json'))) {
        const previous = JSON.parse(decode(fs.readFileSync(path.join(directory, 'manifest.json'))));
        if (previous.version !== 1 || !Array.isArray(previous.files)) throw new Error('已有清单不是本工具格式。');
        previousFiles = previous.files;
        for (const file of previousFiles) {
          if (typeof file !== 'string' || path.posix.isAbsolute(file) || file.split('/').some(part => !part || part === '.' || part === '..') || !/\.md$/i.test(file)) throw new Error('已有清单路径无效。');
          if (file !== `${DIRECTORY}/README.md` && !inspectMarkdown(decode(fs.readFileSync(path.join(root, file)))).tocCount) throw new Error(`旧清单文档需要单独核对，未移除：${file}`);
        }
      }
      const files = [...new Set([...previousFiles, ...candidates.map(candidate => candidate.relative), `${DIRECTORY}/README.md`])].sort();
      const attributesFile = path.join(root, '.gitattributes');
      if (fs.existsSync(attributesFile) && fs.lstatSync(attributesFile).isSymbolicLink()) throw new Error('.gitattributes 是符号链接。');
      const originalAttributes = fs.existsSync(attributesFile) ? decode(fs.readFileSync(attributesFile)) : '';
      const nextAttributes = attributesFor(originalAttributes, files);
      const deliverables = [`.gitattributes`, ...['MarkdownToc.mjs', 'manifest.json', 'README.md'].map(file => `${DIRECTORY}/${file}`)];
      const ignored = spawnSync('git', ['check-ignore', '-z', '--stdin'], { cwd: root, input: deliverables.join('\0') + '\0', encoding: 'utf8' });
      if (ignored.status === 0) throw new Error('仓库忽略规则会排除工具目录，未擅自改写忽略规则。');
      if (ignored.status !== 1) throw new Error('不能检查工具目录忽略规则。');
      const effective = git(root, ['check-attr', '-z', '--stdin', 'filter'], { input: candidates.map(file => file.relative).join('\0') + '\0' }).split('\0');
      for (let index = 0; index < candidates.length; index++) {
        if (!['unspecified', 'unset', DRIVER].includes(effective[index * 3 + 2])) throw new Error(`已有其他过滤器：${candidates[index].relative}`);
      }
      result.fileCount = files.length;
      result.sourceCount = candidates.length;
      result.headBefore = git(root, ['rev-parse', 'HEAD']).trim();
      const indexFile = path.resolve(root, git(root, ['rev-parse', '--git-path', 'index']).trim());
      result.indexBefore = fs.existsSync(indexFile) ? hash(fs.readFileSync(indexFile)) : null;
      if (!apply) { result.status = 'ready'; flush(); continue; }
      backups = targets.map(file => ({ file, bytes: fs.existsSync(file) ? fs.readFileSync(file) : null }));
      previousConfig = Object.fromEntries(KEYS.map(key => [key, values(root, key)]));
      const backupFile = path.join(backupRoot, hash(Buffer.from(root)).slice(0, 20) + '.json');
      const documentTimes = candidates.map(candidate => { const stat = fs.statSync(candidate.path); return { file: candidate.path, sha256: hash(fs.readFileSync(candidate.path)), atime: stat.atimeMs, mtime: stat.mtimeMs }; });
      fs.writeFileSync(backupFile, JSON.stringify({ root, previousConfig, documents: documentTimes,
        files: backups.map(record => ({ file: record.file, base64: record.bytes?.toString('base64') ?? null })) }, null, 2) + '\n', { mode: 0o600 });
      fs.mkdirSync(directory, { recursive: true });
      const write = (file, content) => { const bytes = Buffer.from(content); fs.writeFileSync(file, bytes); written.set(file, bytes); };
      write(path.join(directory, 'MarkdownToc.mjs'), template);
      write(path.join(directory, 'manifest.json'), JSON.stringify({ version: 1, files }, null, 2) + '\n');
      write(path.join(directory, 'README.md'), readme);
      write(attributesFile, nextAttributes);
      git(root, ['check-attr', 'filter', '--', ...files]);
      execFileSync(process.execPath, [path.join(directory, 'MarkdownToc.mjs'), 'install'], { cwd: root, stdio: 'pipe' });
      written.set(stateFile, fs.readFileSync(stateFile));
      installedConfig = Object.fromEntries(KEYS.map(key => [key, values(root, key)]));
      execFileSync(process.execPath, [path.join(directory, 'MarkdownToc.mjs'), 'verify'], { cwd: root, stdio: 'pipe' });
      for (const document of documentTimes) {
        if (hash(fs.readFileSync(document.file)) !== document.sha256) throw new Error('源文档内容发生变化，停止并保留报告。');
      }
      result.indexAfter = fs.existsSync(indexFile) ? hash(fs.readFileSync(indexFile)) : null;
      if (result.indexBefore !== result.indexAfter) throw new Error('真实 Git 索引被并发修改，停止此仓验证。');
      result.headAfter = git(root, ['rev-parse', 'HEAD']).trim();
      if (result.headAfter !== result.headBefore) throw new Error('HEAD 被并发修改。');
      result.backup = backupFile;
      result.status = 'installed';
    } catch (error) {
      result.status = 'failed';
      result.error = error.stderr?.toString().trim() || error.message;
      if (apply && backups.length) {
        try {
          for (const record of backups) {
            const current = fs.existsSync(record.file) ? fs.readFileSync(record.file) : null;
            if (current === null && record.bytes === null || current && record.bytes && current.equals(record.bytes)) continue;
            if (!current || !written.has(record.file) || !current.equals(written.get(record.file))) {
              result.rollbackConflicts ??= [];
              result.rollbackConflicts.push(record.file);
              continue;
            }
            if (record.bytes === null) fs.unlinkSync(record.file);
            else fs.writeFileSync(record.file, record.bytes);
          }
          for (const key of KEYS) {
            const current = values(root, key);
            if (JSON.stringify(current) === JSON.stringify(previousConfig[key])) continue;
            if (!installedConfig || JSON.stringify(current) !== JSON.stringify(installedConfig[key])) {
              result.rollbackConflicts ??= [];
              result.rollbackConflicts.push(key);
              continue;
            }
            restoreValues(root, key, previousConfig[key]);
          }
          result.rolledBack = !result.rollbackConflicts?.length;
        } catch (rollbackError) { result.rollbackError = rollbackError.message; }
      }
    }
    flush();
  }
  report.completed = new Date().toISOString();
  report.summary = { repositories: report.repositories.length,
    installed: report.repositories.filter(repo => repo.status === 'installed').length,
    ready: report.repositories.filter(repo => repo.status === 'ready').length,
    failed: report.repositories.filter(repo => repo.status === 'failed').length,
    documents: report.repositories.filter(repo => ['installed', 'ready'].includes(repo.status)).reduce((sum, repo) => sum + repo.fileCount, 0) };
  flush();
  console.log(JSON.stringify({ report: path.resolve(reportPath), ...report.summary }));
  if (report.summary.failed) process.exitCode = 1;
}

if (process.argv[1] && pathToFileURL(path.resolve(process.argv[1])).href === import.meta.url) {
  try { main(process.argv.slice(2)); }
  catch (error) { console.error(error.message); process.exitCode = 1; }
}
