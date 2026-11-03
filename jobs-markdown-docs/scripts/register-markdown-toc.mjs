// Created by Jobs on 2026年10月21日，星期三.
// Exact remote conditions load an immutable, reviewed converter before clone checkout.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';

const SELF = fileURLToPath(import.meta.url);
const ASSET = path.resolve(path.dirname(SELF), '../assets/markdown-toc/MarkdownToc.mjs');
const DRIVER = 'jobs-markdown-toc';
const hash = value => crypto.createHash('sha256').update(value).digest('hex');
const quote = value => "'" + value.replaceAll("'", "'\\''") + "'";

function git(args, options = {}, allowed = [0]) {
  const result = spawnSync('git', args, { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024, ...options });
  if (result.error) throw result.error;
  if (!allowed.includes(result.status)) throw new Error(result.stderr.trim() || `git 退出码 ${result.status}`);
  return result;
}

function within(root, target) {
  const relative = path.relative(root, target);
  return relative === '' || (!relative.startsWith('../') && !path.isAbsolute(relative));
}

export function exactRemotePatterns(remote) {
  if (!remote || /[\n\r\0*?\[\]]/.test(remote)) throw new Error('来源含空值或通配字符，未扩大注册范围。');
  const scp = remote.match(/^([^@/:]+)@([^/:]+):(.+)$/);
  let url;
  try { url = scp ? new URL(`ssh://${scp[1]}@${scp[2]}/${scp[3]}`) : new URL(remote); }
  catch { return [remote]; }
  if (url.password || (['https:', 'http:'].includes(url.protocol) && url.username) || url.search || url.hash) {
    throw new Error('来源包含凭据或 URL 参数，未记录敏感地址；请先提供可公开的仓库来源。');
  }
  if (!['https:', 'ssh:'].includes(url.protocol) || url.port || (url.username && url.username !== 'git') || !['github.com', 'gitee.com'].includes(url.hostname)) return [remote];
  const repository = url.pathname.replace(/^\//, '').replace(/\.git$/, '');
  if (!repository || repository.split('/').some(part => !part || part === '..' || part === '.')) throw new Error('仓库来源路径无效。');
  return ['', '.git'].flatMap(suffix => [`https://${url.hostname}/${repository}${suffix}`,
    `git@${url.hostname}:${repository}${suffix}`, `ssh://git@${url.hostname}/${repository}${suffix}`]);
}

function configArgs(target) {
  return target ? ['--file', target] : ['--global'];
}

function values(target, key) {
  return git(['config', ...configArgs(target), '--no-includes', '--null', '--get-all', key], {}, [0, 1]).stdout.split('\0').slice(0, -1);
}

function remove(target, key, value) {
  git(['config', ...configArgs(target), '--fixed-value', '--unset-all', key, value], {}, [0, 5]);
}

function atomicWrite(file, data, mode = 0o600) {
  const temporary = `${file}.tmp-${crypto.randomUUID()}`;
  fs.writeFileSync(temporary, data, { flag: 'wx', mode });
  fs.renameSync(temporary, file);
}

function checkExistingDriver(root, converter, target, base) {
  const options = target ? { cwd: root, env: { ...process.env, GIT_CONFIG_GLOBAL: target, GIT_CONFIG_NOSYSTEM: '1' } } : { cwd: root };
  if (git(['config', '--get', `filter.${DRIVER}.process`], options, [0, 1]).status === 0) throw new Error(`存在优先 process 驱动，保留现场：${root}`);
  const stateFile = path.resolve(root, git(['rev-parse', '--git-path', 'jobs-markdown-toc.json'], { cwd: root }).stdout.trim());
  const state = fs.existsSync(stateFile) ? JSON.parse(fs.readFileSync(stateFile, 'utf8')) : null;
  for (const mode of ['clean', 'smudge']) {
    const key = `filter.${DRIVER}.${mode}`;
    const commands = git(['config', '--null', '--get-all', key], options, [0, 1]).stdout.split('\0').slice(0, -1);
    for (const command of commands) {
      if (state?.version === 1 && state.installed?.[key]?.includes(command)) continue;
      const prefix = `${quote(process.execPath)} `;
      const suffix = ` ${mode}`;
      let trusted = false;
      if (command.startsWith(prefix) && command.endsWith(suffix)) {
        const quoted = command.slice(prefix.length, -suffix.length);
        const file = quoted.slice(1, -1).replaceAll("'\\''", "'");
        if (quoted === quote(file) && [base, path.join(os.homedir(), '.local/share/jobs-markdown-toc')].some(directory => within(directory, file)) && fs.existsSync(file)) {
          trusted = hash(fs.readFileSync(file)) === hash(converter);
        }
      }
      if (!trusted) throw new Error(`发现同名外部 ${mode} 驱动，未接管：${root}`);
    }
  }
}

function plan(inventories, converter, target, base) {
  const roots = new Set();
  for (const file of inventories) {
    const inventory = JSON.parse(fs.readFileSync(file, 'utf8'));
    const scope = fs.realpathSync(inventory.root);
    for (const candidate of inventory.candidates ?? []) {
      if (candidate.approved !== true) continue;
      const root = fs.realpathSync(candidate.repoRoot);
      const document = fs.realpathSync(candidate.path);
      if (!within(scope, root) || !within(root, document)) throw new Error('审核清单越过授权 Git 边界。');
      roots.add(root);
    }
  }
  if (!roots.size) throw new Error('审核清单没有获准仓库。');
  const patterns = new Set();
  const repositories = [];
  for (const root of [...roots].sort()) {
    if (fs.realpathSync(git(['rev-parse', '--show-toplevel'], { cwd: root }).stdout.trim()) !== root) throw new Error('清单 Git 根不匹配。');
    if (hash(fs.readFileSync(path.join(root, '.jobs-markdown-toc/MarkdownToc.mjs'))) !== hash(converter)) throw new Error(`仓库尚未部署标准转换器：${root}`);
    checkExistingDriver(root, converter, target, base);
    const raw = git(['config', '--local', '--null', '--get-regexp', '^remote\\..*\\.url$'], { cwd: root }, [0, 1]).stdout;
    const urls = raw.split('\0').filter(Boolean).map(record => record.slice(record.indexOf('\n') + 1));
    const remotePatterns = [...new Set(urls.flatMap(exactRemotePatterns))].sort();
    remotePatterns.forEach(pattern => patterns.add(pattern));
    repositories.push({ root, patterns: remotePatterns, status: remotePatterns.length ? 'ready' : 'no-remote' });
  }
  const sorted = [...patterns].sort();
  if (!sorted.length) throw new Error('没有可登记的精确远端。');
  const id = hash(JSON.stringify({ patterns: sorted, converter: hash(converter), node: process.execPath, target })).slice(0, 20);
  const runtime = path.join(base, id);
  const config = path.join(runtime, 'driver.gitconfig');
  return { version: 1, id, runtime, config, statePath: path.join(runtime, 'state.json'), target,
    converterHash: hash(converter), node: process.execPath, patterns: sorted,
    keys: sorted.map(pattern => `includeIf.hasconfig:remote.*.url:${pattern}.path`), repositories };
}

function install(record, converter) {
  const stateFile = record.statePath;
  if (fs.existsSync(record.runtime)) {
    if (!fs.existsSync(stateFile)) throw new Error('运行目录无自身记录，保留现场。');
    const state = JSON.parse(fs.readFileSync(stateFile, 'utf8'));
    if (state.id !== record.id || state.converterHash !== record.converterHash) throw new Error('现行注册记录不匹配。');
    for (const [file, digest] of Object.entries(state.files)) {
      if (hash(fs.readFileSync(path.join(record.runtime, file))) !== digest) throw new Error('可信机器副本已被外部修改。');
    }
    if (state.active && state.keys.every(key => values(record.target, key).includes(record.config))) return state;
  }
  fs.mkdirSync(record.runtime, { recursive: true, mode: 0o700 });
  const previous = Object.fromEntries(record.keys.map(key => [key, values(record.target, key)]));
  const converterPath = path.join(record.runtime, 'MarkdownToc.mjs');
  atomicWrite(converterPath, converter);
  atomicWrite(path.join(record.runtime, 'register-markdown-toc.mjs'), fs.readFileSync(SELF));
  const command = `${quote(process.execPath)} ${quote(fs.realpathSync(converterPath))}`;
  const temporary = `${record.config}.new`;
  fs.writeFileSync(temporary, '');
  for (const [key, value] of Object.entries({ clean: `${command} clean`, smudge: `${command} smudge`, required: 'true' })) {
    git(['config', '--file', temporary, `filter.${DRIVER}.${key}`, value]);
  }
  fs.renameSync(temporary, record.config);
  const files = Object.fromEntries(['MarkdownToc.mjs', 'register-markdown-toc.mjs', 'driver.gitconfig'].map(file => [file, hash(fs.readFileSync(path.join(record.runtime, file)))]));
  const oldState = fs.existsSync(stateFile) ? JSON.parse(fs.readFileSync(stateFile, 'utf8')) : null;
  const ownedKeys = [...new Set([...(oldState?.ownedKeys ?? []), ...record.keys.filter(key => !previous[key].includes(record.config))])];
  const state = { ...record, previous, ownedKeys, files, active: false };
  atomicWrite(stateFile, JSON.stringify(state, null, 2) + '\n');
  const added = [];
  try {
    for (const key of record.keys) {
      if (values(record.target, key).includes(record.config)) continue;
      git(['config', ...configArgs(record.target), '--add', key, record.config]);
      added.push(key);
    }
    state.active = true;
    atomicWrite(stateFile, JSON.stringify(state, null, 2) + '\n');
  } catch (error) {
    for (const key of added.reverse()) remove(record.target, key, record.config);
    throw error;
  }
  const withdraw = `node ${quote(path.join(record.runtime, 'register-markdown-toc.mjs'))} uninstall --state ${quote(stateFile)}`;
  atomicWrite(path.join(record.runtime, 'README.md'), `# Markdown 目录可信驱动\n\n此副本由获准仓库清单部署；精确来源及备份见 state.json。仅处理 Git 标准输入，不执行被克隆仓库的脚本。依赖 Git 与 Node.js。\n\n撤回：\n\n\`\`\`shell\n${withdraw}\n\`\`\`\n\n仅移除本工具拥有的精确 include 值，保留其它配置、各仓 local 驱动及此审计目录。\n`);
  return state;
}

function main(args) {
  const mode = args.shift() ?? 'help';
  if (mode === 'help') {
    console.log('用法：register-markdown-toc.mjs plan|install --inventory 清单.json [--inventory 另一清单.json] --report 报告.json\nstatus|uninstall --state 注册记录.json\n--config 隔离配置文件 与 --runtime-dir 隔离目录用于离线实验；默认操作本机用户级 Git。');
    return;
  }
  if (['GIT_DIR', 'GIT_WORK_TREE', 'GIT_COMMON_DIR', 'GIT_CONFIG_GLOBAL', 'GIT_CONFIG_COUNT', 'GIT_CONFIG_PARAMETERS'].some(key => process.env[key])) throw new Error('注册不接受 Git 定位 / 配置环境覆盖。');
  const options = {};
  for (let i = 0; i < args.length; i += 2) {
    if (!['--inventory', '--report', '--config', '--runtime-dir', '--state'].includes(args[i]) || !args[i + 1]) throw new Error('参数缺失或未知。');
    (options[args[i]] ??= []).push(args[i + 1]);
  }
  const one = key => options[key]?.at(-1);
  if (!['plan', 'install', 'status', 'uninstall'].includes(mode)) throw new Error('未知模式。');
  const target = one('--config') ? path.resolve(one('--config')) : null;
  let record;
  let converter;
  if (mode === 'plan' || mode === 'install') {
    if (!options['--inventory']?.length || !one('--report')) throw new Error('需要审核清单与报告路径。');
    converter = fs.readFileSync(ASSET);
    record = plan(options['--inventory'], converter, target, path.resolve(one('--runtime-dir') ?? path.join(os.homedir(), '.local/share/jobs-markdown-toc/registrations')));
  } else {
    if (!one('--state')) throw new Error('需要本工具注册记录。');
    record = JSON.parse(fs.readFileSync(one('--state'), 'utf8'));
    if (record.version !== 1 || path.resolve(one('--state')) !== path.join(record.runtime, 'state.json') || record.config !== path.join(record.runtime, 'driver.gitconfig')) throw new Error('注册记录不匹配。');
  }
  if (mode === 'status') {
    console.log(JSON.stringify({ active: record.active, registered: record.keys.filter(key => values(record.target, key).includes(record.config)).length, total: record.keys.length, runtime: record.runtime }));
    return;
  }
  if (mode !== 'plan') {
    const parent = path.dirname(record.runtime);
    fs.mkdirSync(parent, { recursive: true, mode: 0o700 });
    const lock = path.join(parent, '.registration.lock');
    const descriptor = fs.openSync(lock, 'wx', 0o600);
    try {
      if (mode === 'install') record = install(record, converter);
      else {
        for (const key of record.ownedKeys) remove(record.target, key, record.config);
        record.active = false;
        atomicWrite(record.statePath, JSON.stringify(record, null, 2) + '\n');
      }
    } finally { fs.closeSync(descriptor); fs.unlinkSync(lock); }
  }
  if (one('--report')) {
    fs.mkdirSync(path.dirname(path.resolve(one('--report'))), { recursive: true, mode: 0o700 });
    fs.writeFileSync(one('--report'), JSON.stringify(record, null, 2) + '\n', { mode: 0o600 });
  }
  console.log(JSON.stringify({ mode, repositories: record.repositories.length, exactRemotes: record.patterns.length, state: record.statePath }));
}

if (process.argv[1] && pathToFileURL(path.resolve(process.argv[1])).href === import.meta.url) {
  try { main(process.argv.slice(2)); }
  catch (error) { console.error(`MarkdownTocRegistration：${error.message}`); process.exitCode = 1; }
}
