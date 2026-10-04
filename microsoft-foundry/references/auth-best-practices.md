# <span id="前言">Azure Authentication Best Practices</span>

> Source: [Microsoft — Passwordless connections for Azure services](https://learn.microsoft.com/azure/developer/intro/passwordless-overview) and [Azure Identity client libraries](https://learn.microsoft.com/dotnet/azure/sdk/authentication/).

**Table of Contents:** [Golden Rule](#golden-rule) · [Authentication by Environment](#authentication-by-environment) · [Why Not DefaultAzureCredential in Production?](#why-not-defaultazurecredential-in-production) · [Production Patterns](#production-patterns) · [Local Development Setup](#local-development-setup) · [Environment-Aware Pattern](#environment-aware-pattern) · [Security Checklist](#security-checklist) · [Further Reading](#further-reading)

## Golden Rule <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

Use **managed identities** and **Azure RBAC** in production. Reserve `DefaultAzureCredential` for **local development only**.

## Authentication by Environment <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| Environment | Recommended Credential | Why |
|---|---|---|
| **Production (Azure-hosted)** | `ManagedIdentityCredential` (system- or user-assigned) | No secrets to manage; auto-rotated by Azure |
| **Production (on-premises)** | `ClientCertificateCredential` or `WorkloadIdentityCredential` | Deterministic; no fallback chain overhead |
| **CI/CD pipelines** | `AzurePipelinesCredential` / `WorkloadIdentityCredential` | Scoped to pipeline identity |
| **Local development** | `DefaultAzureCredential` | Chains CLI, PowerShell, and VS Code credentials for convenience |

## Why Not `DefaultAzureCredential` in Production? <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

1. **Unpredictable fallback chain** — walks through multiple credential types, adding latency and making failures harder to diagnose.
2. **Broad surface area** — checks environment variables, CLI tokens, and other sources that should not exist in production.
3. **Non-deterministic** — which credential actually authenticates depends on the environment, making behavior inconsistent across deployments.
4. **Performance** — each failed credential attempt adds network round-trips before falling back to the next.

## Production Patterns <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### .NET <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

```csharp
using Azure.Identity;

var credential = Environment.GetEnvironmentVariable("AZURE_FUNCTIONS_ENVIRONMENT") == "Development"
    ? new DefaultAzureCredential()                          // local dev — uses CLI/VS credentials
    : new ManagedIdentityCredential();                      // production — deterministic, no fallback chain
// For user-assigned identity: new ManagedIdentityCredential("<client-id>")
```

### TypeScript / JavaScript <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

```typescript
import { DefaultAzureCredential, ManagedIdentityCredential } from "@azure/identity";

const credential = process.env.NODE_ENV === "development"
  ? new DefaultAzureCredential()                          // local dev — uses CLI/VS credentials
  : new ManagedIdentityCredential();                      // production — deterministic, no fallback chain
// For user-assigned identity: new ManagedIdentityCredential("<client-id>")
```

### Python <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

```python
import os
from azure.identity import DefaultAzureCredential, ManagedIdentityCredential

credential = (
    DefaultAzureCredential()                              # local dev — uses CLI/VS credentials
    if os.getenv("AZURE_FUNCTIONS_ENVIRONMENT") == "Development"
    else ManagedIdentityCredential()                      # production — deterministic, no fallback chain
)
# For user-assigned identity: ManagedIdentityCredential(client_id="<client-id>")
```

### Java <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

```java
import com.azure.identity.DefaultAzureCredentialBuilder;
import com.azure.identity.ManagedIdentityCredentialBuilder;

var credential = "Development".equals(System.getenv("AZURE_FUNCTIONS_ENVIRONMENT"))
    ? new DefaultAzureCredentialBuilder().build()          // local dev — uses CLI/VS credentials
    : new ManagedIdentityCredentialBuilder().build();      // production — deterministic, no fallback chain
// For user-assigned identity: new ManagedIdentityCredentialBuilder().clientId("<client-id>").build()
```

## Local Development Setup <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

`DefaultAzureCredential` is ideal for local dev because it automatically picks up credentials from developer tools:

1. **Azure CLI** — `az login`
2. **Azure Developer CLI** — `azd auth login`
3. **Azure PowerShell** — `Connect-AzAccount`
4. **Visual Studio / VS Code** — sign in via Azure extension

```typescript
import { DefaultAzureCredential } from "@azure/identity";

// Local development only — uses CLI/PowerShell/VS Code credentials
const credential = new DefaultAzureCredential();
```

## Environment-Aware Pattern <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

Detect the runtime environment and select the appropriate credential. The key principle: use `DefaultAzureCredential` only when running locally, and a specific credential in production.

> **Tip:** Azure Functions sets `AZURE_FUNCTIONS_ENVIRONMENT` to `"Development"` when running locally. For App Service or containers, use any environment variable you control (e.g. `NODE_ENV`, `ASPNETCORE_ENVIRONMENT`).

```typescript
import { DefaultAzureCredential, ManagedIdentityCredential } from "@azure/identity";

function getCredential() {
  if (process.env.NODE_ENV === "development") {
    return new DefaultAzureCredential();          // picks up az login / VS Code creds
  }
  return process.env.AZURE_CLIENT_ID
    ? new ManagedIdentityCredential(process.env.AZURE_CLIENT_ID)  // user-assigned
    : new ManagedIdentityCredential();                            // system-assigned
}
```

## Security Checklist <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- [ ] Use managed identity for all Azure-hosted apps
- [ ] Never hardcode credentials, connection strings, or keys
- [ ] Apply least-privilege RBAC roles at the narrowest scope
- [ ] Use `ManagedIdentityCredential` (not `DefaultAzureCredential`) in production
- [ ] Store any required secrets in Azure Key Vault
- [ ] Rotate secrets and certificates on a schedule
- [ ] Enable Microsoft Defender for Cloud on production resources

## Further Reading <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- [Passwordless connections overview](https://learn.microsoft.com/azure/developer/intro/passwordless-overview)
- [Managed identities overview](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview)
- [Azure RBAC overview](https://learn.microsoft.com/azure/role-based-access-control/overview)
- [.NET authentication guide](https://learn.microsoft.com/dotnet/azure/sdk/authentication/)
- [Python identity library](https://learn.microsoft.com/python/api/overview/azure/identity-readme)
- [JavaScript identity library](https://learn.microsoft.com/javascript/api/overview/azure/identity-readme)
- [Java identity library](https://learn.microsoft.com/java/api/overview/azure/identity-readme)

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
