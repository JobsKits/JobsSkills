// Created by Jobs on 2026年10月21日，星期三.
// Exercise the real registration CLI using isolated config files and local remotes.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { cleanMarkdown } from '../assets/markdown-toc/MarkdownToc.mjs';
import { exactRemotePatterns } from './register-markdown-toc.mjs';

const root = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), 'jobs-toc-registration-test-')));
const producer = path.join(root, 'producer');
const bare = path.join(root, 'remote.git');
const otherBare = path.join(root, 'other.git');
const config = path.join(root, 'global.config');
const runtime = path.join(root, 'runtime');
const inventory = path.join(root, 'inventory.json');
const report = path.join(root, 'report.json');
const asset = fileURLToPath(new URL('../assets/markdown-toc/MarkdownToc.mjs', import.meta.url));
const registrar = fileURLToPath(new URL('./register-markdown-toc.mjs', import.meta.url));
const cleanEnv = Object.fromEntries(Object.entries(process.env).filter(([key]) => !key.startsWith('GIT_')));
const env = { ...cleanEnv, GIT_CONFIG_NOSYSTEM: '1', GIT_CONFIG_GLOBAL: config,
  GIT_AUTHOR_NAME: 'Jobs TOC fixture', GIT_AUTHOR_EMAIL: 'fixture@example.invalid',
  GIT_COMMITTER_NAME: 'Jobs TOC fixture', GIT_COMMITTER_EMAIL: 'fixture@example.invalid' };
fs.mkdirSync(producer);
fs.writeFileSync(config, '[user]\n\tname = retained identity\n');

function run(command, args, cwd = root, environment = env) {
  const result = spawnSync(command, args, { cwd, env: environment, encoding: 'utf8' });
  assert.equal(result.status, 0, `${args.join(' ')}\n${result.stderr}`);
  return result.stdout;
}
const git = (cwd, args) => run('git', ['-c', 'core.hooksPath=/dev/null', '-c', 'commit.gpgsign=false', ...args], cwd);
const cli = args => run(process.execPath, [registrar, ...args], root, cleanEnv);
const passed = [];
function check(name, action) { action(); passed.push(name); console.log(`PASS ${name}`); }

check('remote conditions stay exact; credentials and globs are rejected', () => {
  assert.equal(exactRemotePatterns('git@github.com:JobsKits/JobsSkills.git').length, 6);
  assert.deepEqual(exactRemotePatterns('ssh://git@example.test:2222/group/repo.git'), ['ssh://git@example.test:2222/group/repo.git']);
  assert.deepEqual(exactRemotePatterns('ssh://git@private.example/group/repo.git'), ['ssh://git@private.example/group/repo.git']);
  assert.throws(() => exactRemotePatterns('https://token:secret@example.test/repo.git'));
  assert.throws(() => exactRemotePatterns('https://example.test/*'));
});

git(root, ['init', '--bare', '--initial-branch=main', bare]);
git(producer, ['init', '--initial-branch=main']);
fs.mkdirSync(path.join(producer, '.jobs-markdown-toc'));
fs.copyFileSync(asset, path.join(producer, '.jobs-markdown-toc/MarkdownToc.mjs'));
const source = '# Fixture\n\n[toc]\n\n## Parent\n\n### Child\n';
fs.writeFileSync(path.join(producer, 'README.md'), cleanMarkdown(source));
fs.writeFileSync(path.join(producer, '.gitattributes'), '/README.md filter=jobs-markdown-toc\n');
git(producer, ['add', '.']);
git(producer, ['commit', '-m', 'fixture']);
git(producer, ['remote', 'add', 'origin', bare]);
git(producer, ['push', '--set-upstream', 'origin', 'main']);
git(root, ['clone', '--bare', bare, otherBare]);
fs.writeFileSync(inventory, JSON.stringify({ root, candidates: [{ path: path.join(producer, 'README.md'), repoRoot: producer, approved: true }] }));
const args = ['--inventory', inventory, '--config', config, '--runtime-dir', runtime, '--report', report];
check('priority process filter is rejected before adding any registration', () => {
  git(root, ['config', '--file', config, 'filter.jobs-markdown-toc.process', 'foreign-process']);
  const before = fs.readFileSync(config);
  const failed = spawnSync(process.execPath, [registrar, 'install', ...args], { env: cleanEnv, encoding: 'utf8' });
  assert.equal(failed.status, 1);
  assert.match(failed.stderr, /process/);
  assert.deepEqual(fs.readFileSync(config), before);
  assert.equal(fs.existsSync(runtime), false);
  git(root, ['config', '--file', config, '--unset-all', 'filter.jobs-markdown-toc.process']);
});
cli(['plan', ...args]);
const planned = JSON.parse(fs.readFileSync(report));
const unrelated = path.join(root, 'identity.config');
fs.writeFileSync(unrelated, '[user]\n\temail = retained@example.invalid\n');
git(root, ['config', '--file', config, '--add', planned.keys[0], unrelated]);

check('real CLI registration supports fresh clone without local install', () => {
  cli(['install', ...args]);
  const consumer = path.join(root, 'consumer');
  git(root, ['clone', bare, consumer]);
  assert.equal(fs.readFileSync(path.join(consumer, 'README.md'), 'utf8'), source);
  assert.equal(git(consumer, ['show', 'HEAD:README.md']), cleanMarkdown(source));
  assert.equal(git(consumer, ['status', '--porcelain']), '');
  assert.ok(git(consumer, ['config', '--show-origin', '--get', 'filter.jobs-markdown-toc.smudge']).includes(planned.runtime));
  const before = fs.readFileSync(config);
  cli(['install', ...args]);
  assert.deepEqual(fs.readFileSync(config), before);
});

check('unmatched repository does not receive this driver', () => {
  const consumer = path.join(root, 'unmatched');
  git(root, ['clone', otherBare, consumer]);
  assert.equal(fs.readFileSync(path.join(consumer, 'README.md'), 'utf8'), cleanMarkdown(source));
});

check('uninstall keeps existing condition values and unrelated identity', () => {
  cli(['uninstall', '--state', planned.statePath]);
  assert.equal(git(root, ['config', '--file', config, '--get', planned.keys[0]]).trim(), unrelated);
  assert.equal(git(root, ['config', '--file', config, '--get', 'user.name']).trim(), 'retained identity');
  const consumer = path.join(root, 'after-uninstall');
  git(root, ['clone', bare, consumer]);
  assert.equal(fs.readFileSync(path.join(consumer, 'README.md'), 'utf8'), cleanMarkdown(source));
});

console.log(JSON.stringify({ groups: passed.length, root, realGlobalConfigChanged: false }));
