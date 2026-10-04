# <span id="前言">Tool — Agent-to-Agent (A2A, preview)</span>

Call another Foundry agent as if it were a tool. Useful for composing specialist agents into an orchestrator.

## Toolbox shape <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

```json
{
  "type": "a2a_preview",
  "name": "<AGENT_NAME>",
  "description": "<what this agent does>",
  "base_url": "<AGENT_BASE_URL>",
  "project_connection_id": "<connection_to_target_project>"
}
```

Auth is either anonymous (for the same project) or via a project connection that holds credentials for the remote agent's host.

## References <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- [A2A tool documentation](https://learn.microsoft.com/azure/foundry/agents/how-to/tools/agent-to-agent)
- [agent-tools.md](agent-tools.md) — tool index

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
