# <span id="前言">SDK Operations for Foundry Agent Service</span>

Use the Foundry MCP tools for agent CRUD operations. When MCP tools are unavailable, use the `azure-ai-projects` Python SDK or REST API.

## Agent Operations via MCP <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Operation | MCP Tool | Description |
|-----------|----------|-------------|
| Create/Update agent | `agent_update` | Create a new agent or update an existing one (creates new version) |
| List/Get agents | `agent_get` | List all agents, or get a specific agent by name |
| Delete agent | `agent_delete` | Delete an agent |
| Invoke agent | `agent_invoke` | Send a message to an agent and get a response |
| Get schema | `agent_definition_schema_get` | Get the full JSON schema for agent definitions |

## SDK Agent Operations <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

When MCP tools are unavailable, use the `azure-ai-projects` Python SDK (`pip install azure-ai-projects --pre`):

```python
from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential

endpoint = "https://<resource>.services.ai.azure.com/api/projects/<project>"
client = AIProjectClient(endpoint=endpoint, credential=DefaultAzureCredential())
```

| Operation | SDK Method |
|-----------|------------|
| Create | `client.agents.create_version(agent_name, definition)` |
| List | `client.agents.list()` |
| Get | `client.agents.get(agent_name)` |
| Update | `client.agents.create_version(agent_name, definition)` (creates new version) |
| Delete | `client.agents.delete(agent_name)` |
| Chat | `client.get_openai_client().responses.create(model=<deployment>, input=<text>, extra_body={"agent": {"name": agent_name, "type": "agent_reference"}})` |

## Environment Variables <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Variable | Description |
|----------|-------------|
| `PROJECT_ENDPOINT` | Foundry project endpoint (`https://<resource>.services.ai.azure.com/api/projects/<project>`) |
| `MODEL_DEPLOYMENT_NAME` | Deployed model name (e.g., `gpt-4.1-mini`) |

## References <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- [Agent quickstart](https://learn.microsoft.com/azure/ai-foundry/agents/quickstart?view=foundry)
- [Create agents](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/create-agent?view=foundry)
- [Tool Catalog](https://learn.microsoft.com/azure/ai-foundry/agents/concepts/tool-catalog?view=foundry)

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
