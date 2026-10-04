# <span id="前言">Agentic RFT — Tool Calling</span>

Train reasoning models (o4-mini) for agentic scenarios where the model invokes external tools during chain-of-thought reasoning.

> ⚠️ **Access required**: Agentic RFT with tool calling and GPT-5 RFT are behind feature flags. You must request access through the Azure AI Foundry portal or your Microsoft account team. o4-mini RFT without tools is generally available.

## Tool Definition Format <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

```python
tools = [
    {
        "name": "search",
        "server_url": "https://your-function-app.azurewebsites.net/api/tools",
        "headers": {
            "Authorization": "Bearer <your-key>"
        }
    },
    {
        "name": "get_by_id",
        "server_url": "https://your-function-app.azurewebsites.net/api/tools",
        "headers": {
            "Authorization": "Bearer <your-key>"
        }
    }
]
```

## Submitting an Agentic RFT Job <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

```python
job = client.fine_tuning.jobs.create(
    model="o4-mini-2025-04-16",
    training_file=train.id,
    validation_file=valid.id,
    method={
        "type": "reinforcement",
        "reinforcement": {
            "grader": grader,
            "tools": tools,
            "max_episode_steps": 10,
            "hyperparameters": {
                "eval_interval": 5,
                "eval_samples": 10,
                "compute_multiplier": 1.5,
                "reasoning_effort": "medium"
            }
        }
    }
)
```

## Tool Response Format <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

Your tool endpoint must return:

```json
{
    "type": "function_call_output",
    "call_id": "call_12345xyz",
    "output": "The result of the tool call...",
    "id": "fc_12345xyz"
}
```

## Tool Endpoint Requirements <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Constraint | Limit |
|-----------|-------|
| Recommended throughput | 50 QPS |
| Max input payload | 1 MB |
| Max return payload | 1 MB (413 error if exceeded) |
| Timeout | 10 minutes |
| Parallel calls | Supported — handle race conditions |
| Retry on 5xx | 3 attempts, then rollout discarded |
| On 4xx | Error serialized and shown to model |

**Infrastructure**: Use Always On, sufficient compute (S2+), multiple instances. Under-provisioned endpoints can cause jobs to hang during post-training eval.

## RFT Hyperparameters <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Parameter | Description | Recommended Start |
|-----------|-------------|-------------------|
| `reasoning_effort` | `"low"`, `"medium"`, `"high"` | `"medium"` |
| `compute_multiplier` | Scales rollouts per step | `1.5` |
| `learning_rate_multiplier` | Scales the learning rate | `1.0` |
| `n_epochs` | Data passes | `2–3` |
| `eval_interval` | Eval every N steps | `5` |
| `eval_samples` | Validation examples per eval | `10` |
| `max_episode_steps` | Max tool calls + reasoning steps per rollout | `5–10` |

**Notes:** Higher LR increases output verbosity without improving accuracy. Compute multiplier 1.5 balances rollout quality and training time. Platform may early-stop before all epochs.

## When to Use Agentic RFT <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- Model needs to **decide when to call tools** (not just follow instructions)
- Task involves **multi-step reasoning** with external data lookups
- Model needs to learn **tool selection** — choosing the right tool for the job
- Standard RFT (without tools) can't capture the agentic behavior

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
