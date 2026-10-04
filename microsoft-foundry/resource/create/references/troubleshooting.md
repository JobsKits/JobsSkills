# <span id="前言">Troubleshooting: Create Foundry Resource</span>

## Resource Creation Failures <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### ResourceProviderNotRegistered <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

**Solution:**
1. If you have Owner/Contributor role, register the provider:
   ```bash
   az provider register --namespace Microsoft.CognitiveServices
   ```
2. If you lack permissions, ask a subscription Owner or Contributor to register it
3. Alternatively, ask them to grant you the `/register/action` privilege

### InsufficientPermissions <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

**Solution:**
```bash
# Check your role assignments
az role assignment list --assignee <your-user-id> --subscription <subscription-id>

# You need: Contributor, Owner, or custom role with Microsoft.CognitiveServices/accounts/write
```

Use `microsoft-foundry:rbac` skill to manage permissions.

### LocationNotAvailableForResourceType <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

**Solution:**
```bash
# List available regions for Cognitive Services
az provider show --namespace Microsoft.CognitiveServices \
  --query "resourceTypes[?resourceType=='accounts'].locations" --out table

# Choose different region from the list
```

### ResourceNameNotAvailable <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

Resource name must be globally unique. Try adding a unique suffix:

```bash
UNIQUE_SUFFIX=$(date +%s)
az cognitiveservices account create \
  --name "foundry-${UNIQUE_SUFFIX}" \
  --resource-group <rg> \
  --kind AIServices \
  --sku S0 \
  --location <location> \
  --yes
```

## Resource Shows as Failed <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

**Check provisioning state:**
```bash
az cognitiveservices account show \
  --name <resource-name> \
  --resource-group <rg> \
  --query "properties.provisioningState"
```

If `Failed`, delete and recreate:
```bash
# Delete failed resource
az cognitiveservices account delete \
  --name <resource-name> \
  --resource-group <rg>

# Recreate
az cognitiveservices account create \
  --name <resource-name> \
  --resource-group <rg> \
  --kind AIServices \
  --sku S0 \
  --location <location> \
  --yes
```

## Cannot Access Keys <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

**Error:** `AuthorizationFailed` when listing keys

**Solution:** You need `Cognitive Services User` or higher role on the resource.

Use `microsoft-foundry:rbac` skill to grant appropriate permissions.

## External Resources <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- [Create multi-service resource](https://learn.microsoft.com/en-us/azure/ai-services/multi-service-resource?pivots=azcli)
- [Azure AI Services documentation](https://learn.microsoft.com/en-us/azure/ai-services/)
- [Azure regions with AI Services](https://azure.microsoft.com/global-infrastructure/services/?products=cognitive-services)

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
