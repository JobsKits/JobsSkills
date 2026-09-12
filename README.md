# `Codex` 用户级 `Skills`

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[toc]

---

## 🔥 <font id=前言>前言</font>

> 本目录是 [**Codex**](https://openai.com/codex) 用户级 `Skills` 的运行态集合。Jobs 自有 `Skill`、外部安装的 `Skill` 和外援软链接可以同时出现，但必须分清所有权、标准源和 Git 跟踪边界。

## 一、目录责职 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- Jobs 自有 `Skill` 的唯一标准源位于 `~/Documents/Github/JobsGenesis/JobsConfigOS/💻JobsCodexConfigs/skills`。
- `~/.agents/skills` 只是运行态目录，Jobs 自有内容只允许从标准源单向部署到这里，不反向回写。
- 外援 `Skill` 依旧由其上游仓库管理源码和版本；本仓库只记录来源和运行态链接映射。

## 二、Git 管理边界

| 类型 | Git 处理 | 信息来源 |
| --- | --- | --- |
| Jobs 自有 `Skill` | 在标准源仓库中跟踪完整内容 | `💻JobsCodexConfigs/skills` |
| 外部安装的实体目录 | 按各自安装器、锁定文件或上游仓库溯源 | 例如 `~/.agents/.skill-lock.json` |
| 外援软链接 | 不进入 Git 索引，在 `.gitignore` 中按精确名称忽略 | 本文档的来源和映射表 |

Git 对软链接只保存“目标路径字符串”，不保存链接目标的内容。当软链接指向仓库外的本机绝对路径时，直接提交会使克隆结果依赖特定机器目录。因此本目录使用“`.gitignore` 排除运行态链接 + `README.md` 保留溯源信息”的组合方式。

`.gitignore` 中使用完整链接名称，不使用 `/understand*` 之类的宽泛规则，避免误伤以后新增的同前缀自有 `Skill`。

## 三、外援软链接溯源

- 上游项目：[**Understand Anything**](https://github.com/Lum1104/Understand-Anything)
- 上游 Git 地址：`https://github.com/Lum1104/Understand-Anything.git`
- 本地检出目录：`~/.understand-anything/repo`
- 链接源目录：`~/.understand-anything/repo/understand-anything-plugin/skills`
- 已核验基线：`5c1e35f90be029efb012a41e1122b08abef5cbb2`

| 运行态链接 | 上游子目录 |
| --- | --- |
| `understand` | `understand-anything-plugin/skills/understand` |
| `understand-chat` | `understand-anything-plugin/skills/understand-chat` |
| `understand-dashboard` | `understand-anything-plugin/skills/understand-dashboard` |
| `understand-diff` | `understand-anything-plugin/skills/understand-diff` |
| `understand-domain` | `understand-anything-plugin/skills/understand-domain` |
| `understand-explain` | `understand-anything-plugin/skills/understand-explain` |
| `understand-knowledge` | `understand-anything-plugin/skills/understand-knowledge` |
| `understand-onboard` | `understand-anything-plugin/skills/understand-onboard` |

## 四、溯源与恢复检查

1、检查上游地址和当前版本：

```shell
git -C "$HOME/.understand-anything/repo" remote -v
git -C "$HOME/.understand-anything/repo" rev-parse HEAD
```

2、检查运行态链接：

```shell
for skill_name in understand understand-chat understand-dashboard understand-diff understand-domain understand-explain understand-knowledge understand-onboard; do
  printf '%s -> %s\n' "$skill_name" "$(readlink "$skill_name")"
done
```

3、链接失效时，先恢复上游仓库，再按本文档映射表重建链接；不把外援源码复制进 Jobs 自有 `Skill` 标准源。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➔点我回到首页</a>
