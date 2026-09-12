# Hacker 参考仓库

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[toc]

---

## 🔥 <font id=前言>前言</font>

> 本文件记录 `$hacker` 技能内置关注的公开仓库。它们只能作为授权安全研究、防御分析、代码审阅和风险识别的资料入口，不作为直接执行攻击或部署恶意能力的操作手册。

## 一、仓库清单 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| 仓库 | 公开定位 | 使用边界 |
| ---- | -------- | -------- |
| [**NYAN-x-CAT/AsyncRAT-C-Sharp**](https://github.com/NYAN-x-CAT/AsyncRAT-C-Sharp) | Windows 平台 C# 远程访问工具 / RAT 项目。 | 仅做恶意能力识别、静态代码审阅、IOC 和检测思路整理；不提供部署、上线、控制端配置或规避检测步骤。 |
| [**Z4nzu/hackingtool**](https://github.com/Z4nzu/hackingtool) | all-in-one 安全/渗透工具集合。 | 仅做工具分类、依赖风险、授权测试边界和防御建议；不引导攻击第三方目标或批量执行工具链。 |
| [**dstotijn/hetty**](https://github.com/dstotijn/hetty) | 面向安全研究的 HTTP toolkit / 代理类工具。 | 可用于授权 Web / API 流量观察和安全测试辅助；避免对未授权目标抓包、重放、绕过或攻击。 |

## 二、审阅重点 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 2.1、AsyncRAT-C-Sharp

- 重点看网络通信、客户端配置、持久化逻辑、文件操作、进程操作、键鼠/屏幕相关能力、插件加载和反分析迹象。
- 输出时优先给防守侧信息：可疑路径、进程行为、网络特征、配置字段、日志关注点、EDR/SIEM 检测思路。
- 不给出控制端搭建、客户端生成、上线联动、插件投放、免杀和逃逸路径。

### 2.2、hackingtool

- 重点看工具分类、依赖安装、外部脚本调用、目标输入方式、默认扫描/爆破/枚举能力和潜在破坏性动作。
- 输出时优先给授权边界、风险提示、实验室隔离建议和蓝队监控点。
- 不把工具菜单改写成可执行攻击步骤，不为未授权目标选择模块或参数。

### 2.3、hetty

- 重点看代理监听、证书处理、请求/响应存储、重放能力、项目数据落盘、Web UI 暴露面和访问控制。
- 输出时优先给合法代理测试流程的风险边界、敏感数据保护、日志留存、测试环境隔离和清理建议。
- 不帮助绕过第三方访问控制，不指导对未授权服务做重放、撞库、枚举或漏洞利用。

## 三、安全输出模板 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

```markdown
## 项目定位

## 高风险能力

## 可观察行为

## 可能 IOC

## 检测与日志建议

## 加固与处置建议

## 未验证项
```

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
