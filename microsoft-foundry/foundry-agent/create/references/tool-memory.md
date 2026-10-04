# <span id="前言">Agent Memory</span>

Managed long-term memory for Foundry agents. Enables agent continuity across sessions, devices, and workflows. Agents retain user preferences, conversation history, and deliver personalized experiences. Memory is stored in your project's owned storage.

## Prerequisites <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- A [Foundry project](https://learn.microsoft.com/azure/ai-foundry/how-to/create-projects) with authorization configured
- A **chat model deployment** (e.g., `gpt-5.2`)
- An **embedding model deployment** (e.g., `text-embedding-3-small`) — see [Check Embedding Model](#check-embedding-model) below
- Python packages: `pip install azure-ai-projects azure-identity`

### Check Embedding Model <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

An embedding model is **required** before enabling memory. Check if one is already deployed:

Use `foundry_models_list` MCP tool to list all deployments and look for an embedding model (e.g., `text-embedding-3-small`, `text-embedding-3-large`, `text-embedding-ada-002`).

| Result | Action |
|--------|--------|
| ✅ Embedding model found | Note the deployment name and proceed |
| ❌ No embedding model | Deploy one before enabling memory — see below |

### Deploy Embedding Model <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

If no embedding model exists, use `foundry_models_deploy` MCP tool with:
- `deploymentName`: `text-embedding-3-small` (or preferred name)
- `modelName`: `text-embedding-3-small`
- `modelFormat`: `OpenAI`

## Authorization and Permissions <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Role | Scope | Purpose |
|------|-------|---------|
| **Foundry User** | AI Services resource | Assigned to project managed identity |
| **System-assigned managed identity** | Project | Must be enabled on the project |

**Setup steps:**
1. In Azure portal → project → **Resource Management** → **Identity** → enable system-assigned managed identity
2. On the AI Services resource → **Access control (IAM)** → assign **Foundry User** to the project managed identity

## Workflow <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

```
User wants agent memory
    │
    ▼
Step 1: Check for embedding model deployment
    │  ├─ ✅ Found → Continue
    │  └─ ❌ Not found → Deploy one (ask user)
    │
    ▼
Step 2: Create memory store
    │
    ▼
Step 3: Attach memory tool to agent
    │
    ▼
Step 4: Test with conversation
```

## Key Concepts <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### Memory Store Options <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Option | Description |
|--------|-------------|
| `chat_summary_enabled` | Summarize conversations for memory |
| `user_profile_enabled` | Build and maintain user profile |
| `user_profile_details` | Control what data gets stored (e.g., `"Avoid sensitive data such as age, financials, location, credentials"`) |

> 💡 **Tip:** Use `user_profile_details` to control what the agent stores — e.g., `"flight carrier preference and dietary restrictions"` for a travel agent, or exclude sensitive data.

### Scope <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

The `scope` parameter partitions memory per user:

| Scope Value | Behavior |
|-------------|----------|
| `{{$userId}}` | Auto-extracts TID+OID from auth token (recommended) |
| `"user_123"` | Static identifier — you manage user mapping |

### Memory Store Operations <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Operation | Description |
|-----------|-------------|
| Create | Initialize a memory store with chat/embedding models and options |
| List | List all memory stores in the project |
| Update | Update memory store description or configuration |
| Delete scope | Delete memories for a specific user scope |
| Delete store | Delete entire memory store (irreversible — all scopes lost) |

> ⚠️ **Warning:** Deleting a memory store removes all memories across all scopes. Agents with attached memory stores lose access to historical context.

## Troubleshooting <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Issue | Cause | Resolution |
|-------|-------|------------|
| Auth/authorization error | Identity or managed identity lacks required roles | Verify roles in Authorization section; refresh access token for REST |
| Memories don't appear after conversation | Updates are debounced or still processing | Increase wait time or call update API with `update_delay=0` |
| Memory search returns no results | Scope mismatch between update and search | Use same scope value for storing and retrieving memories |
| Agent response ignores stored memory | Agent not configured with memory search tool | Confirm agent definition includes `MemorySearchTool` with correct store name |
| No embedding model available | Embedding deployment missing | Deploy an embedding model — see Check Embedding Model section |

## References <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- [Memory tool documentation](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/memory-usage?view=foundry)
- [Memory Concepts](https://learn.microsoft.com/azure/ai-foundry/agents/concepts/what-is-memory)
- [Tool Catalog](https://learn.microsoft.com/azure/ai-foundry/agents/concepts/tool-catalog?view=foundry)
- [Python Samples](https://github.com/Azure/azure-sdk-for-python/tree/main/sdk/ai/azure-ai-projects/samples/memories)

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
