# <span id="前言">Invocations Protocol Guide</span>

The `invocations` protocol is **bytes in, bytes out**. The platform is pure pass-through — the raw HTTP request body is forwarded to the container and the raw response is returned. The agent developer defines what the container accepts and returns. Unlike `responses` (OpenAI-compatible with platform-managed history), `invocations` gives full control to the container code.

## Input/Output Contract <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Aspect | `responses` | `invocations` |
|--------|------------|---------------|
| **Input** | `inputText` is a natural language message (e.g., `"What is the weather?"`) | `inputText` is forwarded as the **raw HTTP request body** — bytes in. Format as whatever the container's invoke handler expects (typically JSON) |
| **Output** | Structured OpenAI response with `output_text` | **Raw response bytes** from the container — JSON, text, or SSE events. Format is defined by the agent developer |
| **Conversation history** | Platform-managed via `conversationId` | Agent-managed via session filesystem; `conversationId` does **not** apply |
| **Streaming** | Platform-managed via `stream: true` | Agent-controlled; `stream` parameter does **not** apply |

## Discovering the Expected Input Schema <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

> ⚠️ **Do not guess the invocations request body.** The developer defines the schema in the container's invoke handler. The platform does not validate or transform the payload.

### 1. Fetch the OpenAPI Spec (Preferred) <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

Agents can register an OpenAPI spec that describes the expected request/response format. Fetch it from:

```text
GET {projectEndpoint}/agents/{agentName}/endpoint/protocols/invocations/docs/openapi.json
```

If the developer registered an `openapi_spec` when creating the server, this returns the full API contract. If not registered, it returns 404.

### 2. Inspect Agent Source Code <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

Look at the agent's invoke handler — the function registered with `@app.invoke_handler` (Python) or equivalent. The handler reads the raw request (e.g., `request.json()` for JSON, `request.body()` for raw bytes) and returns a `Response`.

### 3. Ask the User <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

If neither the OpenAPI spec nor source code is available, ask the user for the expected request body format before invoking.

## Examples <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

**Responses protocol** (default):

```text
agent_invoke(projectEndpoint, agentName, inputText: "What is the weather in Seattle?")
→ Structured response with output_text
```

**Invocations protocol** — agent expects `{"message": "<text>"}`:

```text
agent_invoke(projectEndpoint, agentName, inputText: "{\"message\":\"hello\"}", protocol: "invocations", sessionId: "<session-id>")
→ Raw bytes from container, e.g.: {"response": "Hi there!", "session_id": "abc123"}
```

## Common Use Cases <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Scenario | Why Invocations |
|----------|----------------|
| Webhook receiver (GitHub, Stripe, Jira) | External system sends its own payload format |
| Non-conversational processing (classification, extraction) | Input is structured data, not a chat message |
| Custom streaming protocol (AG-UI) | Needs raw SSE control, not OpenAI-compatible streaming |
| Protocol bridge (proprietary systems) | Caller has its own protocol that doesn't map to `/responses` |

## Error Handling <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Error | Cause | Resolution |
|-------|-------|------------|
| 400/422 or invocation failed | Request body does not match what the container expects | Fetch OpenAPI spec or inspect handler code for the correct schema |
| 404 on OpenAPI spec | Developer did not register an `openapi_spec` | Inspect handler source code or ask the user for the API contract |
| Empty response | Agent returned no content | Check agent logs via `session_logstream`; verify the handler processes the request body correctly |

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
