# <span id="前言">Azure AI Search Tool</span>

Ground agent responses with data from an Azure AI Search vector index. Requires a project connection and proper RBAC setup.

## Prerequisites <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- Azure AI Search index with vector search configured:
  - One or more `Edm.String` fields (searchable + retrievable)
  - One or more `Collection(Edm.Single)` vector fields (searchable)
  - At least one retrievable text field with content for citations
  - A retrievable field with source URL for citation links
- A [project connection](../../../project/connections.md) between your Foundry project and search service
- `azure-ai-projects` package (`pip install azure-ai-projects --pre`)

## Required RBAC Roles <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

For **keyless authentication** (recommended), assign these roles to the **Foundry project's managed identity** on the Azure AI Search resource:

| Role | Scope | Purpose |
|------|-------|---------|
| **Search Index Data Contributor** | AI Search resource | Read/write index data |
| **Search Service Contributor** | AI Search resource | Manage search service config |

> **If RBAC assignment fails:** Ask the user to manually assign roles in Azure portal → AI Search resource → Access control (IAM). They need Owner or User Access Administrator on the search resource.

## Connection Setup <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

A project connection between your Foundry project and the Azure AI Search resource is required. See [Project Connections](../../../project/connections.md) for connection management via Foundry MCP tools.

## Query Types <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Value | Description |
|-------|-------------|
| `SIMPLE` | Keyword search |
| `VECTOR` | Vector similarity only |
| `SEMANTIC` | Semantic ranking |
| `VECTOR_SIMPLE_HYBRID` | Vector + keyword |
| `VECTOR_SEMANTIC_HYBRID` | Vector + keyword + semantic (default, recommended) |

## Tool Parameters <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Parameter | Required | Description |
|-----------|----------|-------------|
| `project_connection_id` | Yes | Connection ID (resolve via `project_connection_get`, typically after discovering the connection with `project_connection_list`) |
| `index_name` | Yes | Search index name |
| `top_k` | No | Number of results (default: 5) |
| `query_type` | No | Search type (default: `vector_semantic_hybrid`) |
| `filter` | No | OData filter applied to all queries |

## Limitations <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- Only **one index per tool** instance. For multiple indexes, use connected agents each with their own index.
- Search resource and Foundry agent must be in the **same tenant**.
- Private AI Search resources require **standard agent deployment** with vNET injection.

## Troubleshooting <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Error | Cause | Fix |
|-------|-------|-----|
| 401/403 accessing index | Missing RBAC roles | Assign `Search Index Data Contributor` + `Search Service Contributor` to project managed identity |
| Index not found | Name mismatch | Verify `AI_SEARCH_INDEX_NAME` matches exactly (case-sensitive) |
| No citations in response | Instructions don't request them | Add citation instructions to agent prompt |
| Wrong connection endpoint | Connection points to different search resource | Re-create connection with correct endpoint |

## References <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- [Azure AI Search tool documentation](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/tools/azure-ai-search?view=foundry)
- [Tool Catalog](https://learn.microsoft.com/azure/ai-foundry/agents/concepts/tool-catalog?view=foundry)
- [Project Connections](../../../project/connections.md)

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
