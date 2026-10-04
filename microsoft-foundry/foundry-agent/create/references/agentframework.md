# <span id="前言">Microsoft Agent Framework — Best Practices for Hosted Agents</span>

Best practices when building hosted agents with Microsoft Agent Framework for deployment to Foundry Agent Service.

## Official Resources <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Resource | URL |
|----------|-----|
| **GitHub Repo** | https://github.com/microsoft/agent-framework |
| **MS Learn Overview** | https://learn.microsoft.com/agent-framework/overview/agent-framework-overview |
| **Quick Start** | https://learn.microsoft.com/agent-framework/tutorials/quick-start |
| **User Guide** | https://learn.microsoft.com/agent-framework/user-guide/overview |
| **Hosted Agents Concepts** | https://learn.microsoft.com/azure/ai-foundry/agents/concepts/hosted-agents |
| **Python Samples (MAF repo)** | https://github.com/microsoft/agent-framework/tree/main/python/samples |
| **.NET Samples (MAF repo)** | https://github.com/microsoft/agent-framework/tree/main/dotnet/samples |
| **PyPI** | https://pypi.org/project/agent-framework/ |
| **NuGet** | https://www.nuget.org/profiles/MicrosoftAgentFramework/ |

## Installation <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

**Python:** `pip install agent-framework agent-framework-foundry-hosting` (installs all sub-packages)

**.NET:** `dotnet add package Microsoft.Agents.AI`

## Hosting Adapter <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

Hosted agents must expose an HTTP server using the hosting adapter. This enables local testing and Foundry deployment with the same code.

**Python adapter packages:** `agent_framework_foundry_hosting`

**.NET adapter packages:** `Azure.AI.AgentServer.Core`, `Microsoft.Agents.AI.Foundry.Hosting`

The adapter handles protocol translation between Foundry request/response formats and your framework's native data structures, including conversation management, message serialization, and streaming.

> 💡 **Tip:** Make HTTP server mode the default entrypoint (no flags needed). This simplifies both local debugging and containerized deployment.

## Key Patterns <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### Python: Credentials <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

For **local development**, use `DefaultAzureCredential` from `azure.identity`. In production, use `ManagedIdentityCredential`. See [auth-best-practices.md](../../../references/auth-best-practices.md).

### Python: Environment Variables <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

Always use `load_dotenv(override=False)` so environment variables set by Foundry at runtime take precedence over local `.env` values.

Required `.env` variables:
- `FOUNDRY_PROJECT_ENDPOINT` — project endpoint URL
- `FOUNDRY_MODEL_DEPLOYMENT_NAME` — model deployment name

### Authentication <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

If explicitly asked to use API key instead of managed identity, then use AzureOpenAIResponsesClient and pass in api_key parameter to it.

### Agent Naming Rules <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

Agent names must: start/end with alphanumeric characters, may contain hyphens in the middle, max 63 characters. Examples: `MyAgent`, `agent-1`. Invalid: `-agent`, `agent-`, `sample_agent`.

### Python: Virtual Environment <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

Always use a virtual environment. Never use bare `python` or `pip` — use venv-activated versions or full paths (e.g., `.venv/bin/pip`).

## Workflow Patterns <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

Agent Framework supports single-agent and multi-agent workflow patterns using graph-based orchestration:

- **Single Agent** — Basic agent with tools, RAG, or MCP integration
- **Multi-Agent Workflow** — Graph-based orchestration connecting multiple agents and deterministic functions
- **Advanced Patterns** — Reflection, switch-case, fan-out/fan-in, loop, human-in-the-loop

For workflow samples and advanced patterns, search the [Agent Framework GitHub repo](https://github.com/microsoft/agent-framework).

## Debugging <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

Use [Foundry Toolkit for VS Code (Formerly AI Toolkit)](https://marketplace.visualstudio.com/items?itemName=ms-windows-ai-studio.windows-ai-studio) with the `agentdev` CLI tool for interactive debugging:

1. Install `debugpy` for VS Code Python Debugger support
2. Install `agent-dev-cli` (pre-release) for the `agentdev` command
3. Key debug tasks: `agentdev run <entrypoint>.py --port 8087` starts the agent HTTP server, `debugpy --listen 127.0.0.1:5679` attaches the debugger, and the `ai-mlstudio.openTestTool` VS Code command opens the Agent Inspector UI

For VS Code `launch.json` and `tasks.json` configuration templates, see [Foundry Toolkit Agent Inspector — Configure debugging manually](https://github.com/microsoft/vscode-ai-toolkit/blob/main/doc/agent-test-tool.md#configure-debugging-manually).

## Common Errors <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Error | Cause | Fix |
|-------|-------|-----|
| `ModuleNotFoundError` | Missing SDK | `pip install agent-framework agent-framework-foundry-hosting` in venv |
| Credential error | Wrong import | Use `azure.identity.DefaultAzureCredential` (local dev) or `ManagedIdentityCredential` (production) |
| Agent name validation error | Invalid characters | Use alphanumeric + hyphens, start/end alphanumeric, max 63 chars |
| Hosting adapter not found | Missing package | Install `agent-framework-foundry-hosting` |

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
