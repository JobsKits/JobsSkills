// Created by Jobs on 2026年10月18日，星期日.
// Every deployment, Git index, and commit used here belongs to a disposable fixture.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';
import { attributePattern } from './deploy-markdown-toc.mjs';

const deployScript = fileURLToPath(new URL('./deploy-markdown-toc.mjs', import.meta.url));
const assets = fileURLToPath(new URL('../assets/markdown-toc/', import.meta.url));
const directory = '.jobs-markdown-toc';
const driver = 'jobs-markdown-toc';
const sha256 = bytes => crypto.createHash('sha256').update(bytes).digest('hex');

function fixture(t, names = ['README.md'], attributes = '*.txt text\n') {
  const scope = fs.mkdtempSync(path.join(os.tmpdir(), "TOC deployment '实验 "));
  t.after(() => fs.rmSync(scope, { recursive: true, force: true }));
  const root = path.join(scope, 'repository');
  fs.mkdirSync(root);
  const globalConfig = path.join(scope, 'global.gitconfig');
  fs.writeFileSync(globalConfig, '# isolated global configuration\n');
  const env = Object.fromEntries(Object.entries(process.env).filter(([key]) => !key.startsWith('GIT_')));
  Object.assign(env, { GIT_CONFIG_NOSYSTEM: '1', GIT_CONFIG_GLOBAL: globalConfig,
    GIT_OPTIONAL_LOCKS: '0', GIT_TERMINAL_PROMPT: '0' });
  const run = (command, args, options = {}) => {
    const result = spawnSync(command, args, { cwd: root, env, encoding: 'utf8', ...options });
    if (result.error) throw result.error;
    return result;
  };
  const git = (...args) => {
    const result = run('git', args);
    assert.equal(result.status, 0, `git ${args.join(' ')}\n${result.stderr}`);
    return result.stdout;
  };
  git('init', '--quiet');
  git('config', '--local', 'user.name', 'TOC fixture');
  git('config', '--local', 'user.email', 'toc-fixture@example.invalid');
  git('config', '--local', 'core.autocrlf', 'false');
  const hooks = path.join(scope, 'empty-hooks');
  fs.mkdirSync(hooks);
  git('config', '--local', 'core.hooksPath', hooks);
  const sources = new Map();
  const oldTime = new Date('2020-01-01T00:00:00Z');
  for (const [index, name] of names.entries()) {
    const source = Buffer.from(`# Fixture ${index + 1}\n\n[toc]\n\n## Section ${index + 1}\n`);
    const file = path.join(root, name);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, source);
    fs.utimesSync(file, oldTime, oldTime);
    sources.set(name, source);
  }
  const unmanaged = path.join(root, 'unmanaged.md');
  fs.writeFileSync(unmanaged, '[toc]\n\n## Leave this file alone\n');
  fs.utimesSync(unmanaged, oldTime, oldTime);
  fs.writeFileSync(path.join(root, '.gitattributes'), attributes);
  git('add', '--all');
  git('-c', 'commit.gpgSign=false', 'commit', '--quiet', '-m', 'Disposable deployment fixture');
  let sequence = 0;
  const deploy = (selected = names, apply = false, environment = env) => {
    const number = ++sequence;
    const inventoryFile = path.join(scope, `inventory-${number}.json`);
    const reportFile = path.join(scope, `report-${number}.json`);
    const candidates = selected.map(name => ({ path: path.join(root, name), repoRoot: root,
      sha256: sha256(fs.readFileSync(path.join(root, name))), approved: true }));
    fs.writeFileSync(inventoryFile, JSON.stringify({ root: scope, candidates }));
    const args = [deployScript, '--inventory', inventoryFile, '--report', reportFile];
    if (apply) args.push('--apply');
    const result = run(process.execPath, args, { env: environment });
    const report = fs.existsSync(reportFile) ? JSON.parse(fs.readFileSync(reportFile, 'utf8')) : null;
    return { ...result, report, reportFile };
  };
  const indexBytes = () => fs.readFileSync(path.join(root, '.git/index'));
  const configBytes = () => fs.readFileSync(path.join(root, '.git/config'));
  const runtime = mode => run(process.execPath, [path.join(root, directory, 'MarkdownToc.mjs'), mode]);
  return { scope, root, env, globalConfig, names, sources, unmanaged, run, git, deploy,
    indexBytes, configBytes, runtime };
}

function assertSourceBytes(repo) {
  for (const [name, source] of repo.sources) assert.deepEqual(fs.readFileSync(path.join(repo.root, name)), source, name);
}

function checkAttributes(repo, names) {
  const fields = repo.git('check-attr', '-z', 'filter', '--', ...names).split('\0');
  return new Map(names.map((name, index) => [name, fields[index * 3 + 2]]));
}

function stageAndCheck(repo, expectedFiles) {
  const manifest = JSON.parse(fs.readFileSync(path.join(repo.root, directory, 'manifest.json'), 'utf8'));
  assert.equal(manifest.version, 1);
  assert.deepEqual(manifest.files, [...expectedFiles, `${directory}/README.md`].sort());
  repo.git('add', '--', ...manifest.files, '.gitattributes', `${directory}/MarkdownToc.mjs`, `${directory}/manifest.json`);
  const checked = repo.runtime('check');
  assert.equal(checked.status, 0, checked.stderr);
  for (const name of manifest.files) {
    const blob = repo.git('show', `:${name}`);
    assert.ok(blob.includes('<!-- jobs-toc:source {"v":2'), `${name} needs a generated TOC`);
    assert.ok(!/^ {0,3}\[toc\][ \t]*$/im.test(blob), `${name} contains an unconverted token`);
  }
  assertSourceBytes(repo);
}

test('plan leaves the repository untouched; apply installs exact attributes and supports ordinary staging', t => {
  const names = ['README.md', 'Docs/中文 空格.md'];
  if (process.platform !== 'win32') names.push('Docs/guide[1]*?.md', 'Docs/quote" and \'note.md');
  const repo = fixture(t, names);
  const originalIndex = repo.indexBytes();
  const originalConfig = repo.configBytes();
  const originalAttributes = fs.readFileSync(path.join(repo.root, '.gitattributes'));
  const originalGlobal = fs.readFileSync(repo.globalConfig);
  const untouchedBytes = fs.readFileSync(repo.unmanaged);
  const untouchedMtime = fs.statSync(repo.unmanaged, { bigint: true }).mtimeNs;
  const sourceMtimes = new Map(names.map(name => [name, fs.statSync(path.join(repo.root, name), { bigint: true }).mtimeNs]));
  const head = repo.git('rev-parse', 'HEAD');

  const planned = repo.deploy();
  assert.equal(planned.status, 0, planned.stderr);
  assert.equal(planned.report.applied, false);
  assert.equal(planned.report.summary.ready, 1);
  assert.equal(planned.report.summary.installed, 0);
  assert.equal(fs.existsSync(path.join(repo.root, directory)), false);
  assert.equal(fs.existsSync(path.join(repo.scope, 'backups')), false);
  assert.deepEqual(repo.indexBytes(), originalIndex);
  assert.deepEqual(repo.configBytes(), originalConfig);
  assert.deepEqual(fs.readFileSync(path.join(repo.root, '.gitattributes')), originalAttributes);
  for (const name of names) assert.equal(fs.statSync(path.join(repo.root, name), { bigint: true }).mtimeNs, sourceMtimes.get(name));
  assertSourceBytes(repo);

  const applied = repo.deploy(names, true);
  assert.equal(applied.status, 0, applied.stderr || JSON.stringify(applied.report));
  assert.equal(applied.report.summary.installed, 1);
  assert.deepEqual(fs.readdirSync(path.join(repo.root, directory)).sort(), ['MarkdownToc.mjs', 'README.md', 'manifest.json']);
  for (const asset of ['MarkdownToc.mjs', 'README.md']) {
    assert.deepEqual(fs.readFileSync(path.join(repo.root, directory, asset)), fs.readFileSync(path.join(assets, asset)));
  }
  assert.deepEqual(repo.indexBytes(), originalIndex, 'deployment must not stage anything');
  assert.equal(repo.git('rev-parse', 'HEAD'), head);
  assert.deepEqual(fs.readFileSync(repo.globalConfig), originalGlobal);
  assert.deepEqual(fs.readFileSync(repo.unmanaged), untouchedBytes);
  assert.equal(fs.statSync(repo.unmanaged, { bigint: true }).mtimeNs, untouchedMtime);
  assertSourceBytes(repo);

  const registered = [...names, `${directory}/README.md`];
  const decoys = ['Docs/guide1-other.md', 'Docs/guide1x.md', 'Docs/中文 空格.md.extra', 'unmanaged.md'];
  const attributes = checkAttributes(repo, [...registered, ...decoys]);
  for (const name of registered) assert.equal(attributes.get(name), driver, name);
  for (const name of decoys) assert.equal(attributes.get(name), 'unspecified', name);
  const text = fs.readFileSync(path.join(repo.root, '.gitattributes'), 'utf8');
  assert.ok(text.startsWith(originalAttributes.toString()));
  for (const name of registered) assert.ok(text.includes(`${attributePattern(name)} filter=${driver}`));
  assert.equal((text.match(/^# jobs-markdown-toc:start$/gm) ?? []).length, 1);
  stageAndCheck(repo, names);
});

test('two partial inventories merge their manifests instead of dropping earlier documents', t => {
  const names = ['README.md', 'Docs/another.md'];
  const repo = fixture(t, names);
  const originalIndex = repo.indexBytes();
  const first = repo.deploy([names[0]], true);
  assert.equal(first.status, 0, first.stderr || JSON.stringify(first.report));
  const firstManifest = JSON.parse(fs.readFileSync(path.join(repo.root, directory, 'manifest.json'), 'utf8'));
  assert.deepEqual(firstManifest.files, [`${directory}/README.md`, names[0]].sort());
  const second = repo.deploy([names[1]], true);
  assert.equal(second.status, 0, second.stderr || JSON.stringify(second.report));
  assert.deepEqual(repo.indexBytes(), originalIndex);
  assertSourceBytes(repo);
  const attributes = checkAttributes(repo, names);
  for (const name of names) assert.equal(attributes.get(name), driver);
  stageAndCheck(repo, names);
});

test('symlinked targets and nested Git tool directories are rejected without overwriting their contents', async t => {
  for (const kind of ['attribute symlink', 'candidate symlink', 'nested Git']) {
    await t.test(kind, { skip: kind.includes('symlink') && process.platform === 'win32' }, sub => {
      const repo = fixture(sub);
      const external = path.join(repo.scope, 'external.md');
      const externalBytes = Buffer.from('[toc]\n\n## Protected external file\n');
      fs.writeFileSync(external, externalBytes);
      const externalMtime = fs.statSync(external, { bigint: true }).mtimeNs;
      if (kind === 'attribute symlink') {
        fs.unlinkSync(path.join(repo.root, '.gitattributes'));
        fs.symlinkSync(external, path.join(repo.root, '.gitattributes'));
      } else if (kind === 'candidate symlink') {
        fs.unlinkSync(path.join(repo.root, 'README.md'));
        fs.symlinkSync(external, path.join(repo.root, 'README.md'));
      } else {
        fs.mkdirSync(path.join(repo.root, directory));
        repo.git('init', '--quiet', directory);
        fs.writeFileSync(path.join(repo.root, directory, 'manifest.json'), '{"version":1,"files":[]}\n');
        fs.writeFileSync(path.join(repo.root, directory, 'sentinel.md'), externalBytes);
      }
      const originalIndex = repo.indexBytes();
      const originalConfig = repo.configBytes();
      const result = repo.deploy(['README.md'], true);
      assert.notEqual(result.status, 0);
      assert.deepEqual(repo.indexBytes(), originalIndex);
      assert.deepEqual(repo.configBytes(), originalConfig);
      assert.deepEqual(fs.readFileSync(external), externalBytes);
      assert.equal(fs.statSync(external, { bigint: true }).mtimeNs, externalMtime);
      if (kind === 'nested Git') {
        assert.deepEqual(fs.readFileSync(path.join(repo.root, directory, 'sentinel.md')), externalBytes);
        assert.equal(fs.existsSync(path.join(repo.root, directory, 'MarkdownToc.mjs')), false);
      }
    });
  }
});

test('GIT_DIR overrides are rejected before the repository or report is written', t => {
  const repo = fixture(t);
  const originalIndex = repo.indexBytes();
  const originalConfig = repo.configBytes();
  const result = repo.deploy(['README.md'], true, { ...repo.env, GIT_DIR: path.join(repo.root, '.git') });
  assert.notEqual(result.status, 0);
  assert.equal(result.report, null);
  assert.equal(fs.existsSync(path.join(repo.root, directory)), false);
  assert.deepEqual(repo.indexBytes(), originalIndex);
  assert.deepEqual(repo.configBytes(), originalConfig);
  assertSourceBytes(repo);
});

test('marker text inside unrelated attribute comments is preserved and prevents destructive block replacement', t => {
  const attributes = '# Notes mention # jobs-markdown-toc:start inline.\n*.txt text\n# Notes mention # jobs-markdown-toc:end inline.\n';
  const repo = fixture(t, ['README.md'], attributes);
  const originalIndex = repo.indexBytes();
  const originalConfig = repo.configBytes();
  const result = repo.deploy(['README.md'], true);
  assert.notEqual(result.status, 0);
  assert.equal(result.report.summary.failed, 1);
  assert.equal(fs.readFileSync(path.join(repo.root, '.gitattributes'), 'utf8'), attributes);
  assert.deepEqual(repo.indexBytes(), originalIndex);
  assert.deepEqual(repo.configBytes(), originalConfig);
  assert.equal(fs.existsSync(path.join(repo.root, directory)), false);
  assertSourceBytes(repo);
});
