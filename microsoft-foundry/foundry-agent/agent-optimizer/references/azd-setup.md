# <span id="前言">azd Setup</span>

Use this before running Agent Optimizer operations. This skill targets agent code repos that use azd and hosted agents.

## Verify prerequisites <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

Run from the selected agent repo:

```bash
azd version
az login
azd ai agent --help
azd ai agent optimize --help
```

If `azd ai agent` is unavailable, install or update the `azure.ai.agents` azd extension using the official extension source. If the needed version is private preview only, ask the user for their approved extension source; do not embed private registry commands.

## Resolve hosted-agent context <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

Use [Common Project Context Resolution](../../../SKILL.md#agent-common-project-context-resolution). Prefer azd context from `azure.yaml` and `azd env get-values`.

Confirm:

- selected service uses `host: azure.ai.agent`
- selected root contains Python agent code
- agent kind is `hosted`
- project endpoint/project ID and deployed agent name/version are known

If `agent.yaml` is missing, ask before initializing:

```bash
azd ai agent init --project-id <project-id>
```

Use the project ID from azd context when available; otherwise ask the user. After init, stop for review of generated `agent.yaml`.

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
