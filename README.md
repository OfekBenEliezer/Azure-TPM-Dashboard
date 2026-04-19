# Microsoft Foundry - TPM Dashboard

**TeraSky Custom Workbook** - Real-time visibility into Microsoft Foundry model token consumption and operational metrics

---

## Overview

This Azure Monitor Workbook provides visibility into Microsoft Foundry AI deployments, helping you:

- **Track Token Usage**: Monitor Input and Output tokens per deployment
- **Monitor Requests**: Track API call volume by deployment
- **Cost Attribution**: Break down usage by model deployment for chargeback

## Supported Resources

| Resource Type | Description |
|---------------|-------------|
| **Microsoft Foundry AIServices** | `microsoft.cognitiveservices/accounts` with kind `AIServices` |

## Metrics Displayed

| Chart | Metric | Description |
|-------|--------|-------------|
| **Input Tokens by Deployment** | `InputTokens` | Prompt tokens consumed |
| **Output Tokens by Deployment** | `OutputTokens` | Completion tokens generated |
| **Requests by Deployment** | `ModelRequests` | API call volume |
| **Rate Limited (429) by Deployment** | `ModelRequests` (filtered) | Throttled requests |

---

## Deployment

### Prerequisites
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) installed
- Bicep CLI included with Azure CLI

### Deploy

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "<your-subscription-id>"

# Create a resource group (if needed)
az group create --name rg-azure-ai-dashboards --location eastus

# Deploy the workbook
az deployment group create \
  --resource-group rg-azure-ai-dashboards \
  --template-file main.bicep \
  --parameters workbookId=$(uuidgen | tr '[:upper:]' '[:lower:]')
```

### Update Existing Dashboard

To update an existing deployment, delete the old workbook first:

```bash
# Delete existing workbook and redeploy
az resource list --resource-group rg-azure-ai-dashboards \
  --resource-type "Microsoft.Insights/workbooks" \
  --query "[].name" -o tsv | \
  xargs -I {} az resource delete \
    --resource-group rg-azure-ai-dashboards \
    --resource-type "Microsoft.Insights/workbooks" \
    --name {}

# Deploy new version
az deployment group create \
  --resource-group rg-azure-ai-dashboards \
  --template-file main.bicep \
  --parameters workbookId=$(uuidgen | tr '[:upper:]' '[:lower:]')
```

---

## Using the Dashboard

### Accessing the Workbook

1. In Azure Portal, search for "Azure Workbooks" or "Monitor"
2. Navigate to the Workbooks section
3. Find "Microsoft Foundry - TPM Dashboard"
4. Click "Open Workbook"

### Configuring Filters

| Filter | Description |
|--------|-------------|
| Subscription | Select subscriptions containing Foundry resources |
| Foundry Resource | Select specific AIServices accounts to monitor |
| Time Range | Choose from preset ranges (5 min to 30 days) or custom |
| Aggregation | Sum, Average, Maximum, or Minimum |

---

## Metrics Reference

### Microsoft Foundry Models Metrics

From [Azure Monitor Metrics Reference](https://learn.microsoft.com/en-us/azure/azure-monitor/reference/supported-metrics/microsoft-cognitiveservices-accounts-metrics):

| Metric | REST API Name | Unit | Dimensions |
|--------|---------------|------|------------|
| Input Tokens | `InputTokens` | Count | ModelDeploymentName, ModelName, ModelVersion |
| Output Tokens | `OutputTokens` | Count | ModelDeploymentName, ModelName, ModelVersion |
| Model Requests | `ModelRequests` | Count | ModelDeploymentName, ModelName, StatusCode |

---

## Contributing

This workbook was developed by TeraSky to address real customer needs around Azure AI observability.

For feedback or contributions, contact:
- Ofekb@terasky.com

---

## License

MIT License - Feel free to use, modify, and distribute.

---

**TeraSky** - Empowering Cloud Excellence  
[www.terasky.com](https://www.terasky.com)
