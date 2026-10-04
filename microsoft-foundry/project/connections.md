# <span id="前言">Foundry Project Connections</span>

Connections authenticate and link external resources to a Foundry project. Many agent tools (Azure AI Search, Bing Grounding, MCP) require a project connection before use.

## Managing Connections via MCP <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

Use the Foundry MCP server for all connection operations. The MCP tools handle authentication, validation, and project scoping automatically.

| Operation | MCP Tool | Description |
|-----------|----------|-------------|
| List all connections | `project_connection_list` | Lists project connections and can filter by category or target |
| Get connection details | `project_connection_get` | Retrieves a specific connection by `connectionName` |
| Create a connection | `project_connection_create` | Creates or replaces a project connection to an external resource |
| Update a connection | `project_connection_update` | Updates auth, category, target, or expiry on an existing connection |
| Delete a connection | `project_connection_delete` | Removes a connection from the project by name |
| List supported categories/auth types | `project_connection_list_metadata` | Lists valid connection categories and auth types before create/update |

> 💡 **Tip:** Use `project_connection_get` or `project_connection_list` to resolve the connection name and full connection resource ID before configuring agent tools that require `project_connection_id`.

## Create Connection via Portal <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

1. Open [Microsoft Foundry portal](https://ai.azure.com)
2. Navigate to **Operate** → **Admin** → select your project
3. Select **Add connection** → choose service type
4. Browse for resource, select auth method, click **Add connection**

## Connection ID Format <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

For REST and TypeScript samples, the full connection ID format is:

```
/subscriptions/{subId}/resourceGroups/{rg}/providers/Microsoft.CognitiveServices/accounts/{account}/projects/{project}/connections/{connectionName}
```

Python and C# SDKs resolve this automatically from the connection name.

## Common Connection Types <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Type | Resource | Used By |
|------|----------|---------|
| `azure_ai_search` | Azure AI Search | AI Search tool |
| `bing` | Grounding with Bing Search | Bing grounding tool |
| `bing_custom_search` | Grounding with Bing Custom Search | Bing Custom Search tool |
| `api_key` | Any API-key resource | MCP servers, custom tools |
| `azure_openai` | Azure OpenAI | Model access |
| `AzureStorageAccount` | Azure Blob Storage | Dataset upload via `evaluation_dataset_create` |

## RBAC for Connection Management <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Role | Scope | Permission |
|------|-------|------------|
| **Foundry Project Manager** | Project | Create/manage project connections |
| **Contributor** or **Owner** | Subscription/RG | Create Bing/Search resources, get keys |

## Troubleshooting <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Error | Cause | Fix |
|-------|-------|-----|
| `Connection not found` | Name mismatch or wrong project | Use `project_connection_list` to find the correct `connectionName` |
| `Unauthorized` creating connection | Missing Foundry Project Manager role | Assign role on the Foundry project |
| `Invalid connection ID format` | Using name instead of full resource ID | Use `project_connection_get` to resolve the full ID |

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
