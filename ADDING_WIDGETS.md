# Adding Widgets to the Microsoft Foundry TPM Dashboard

This guide explains how to add new metric widgets to the Azure Monitor Workbook defined in `main.bicep`.

---

## Understanding the Structure

The workbook is defined in `main.bicep` inside the `workbookContent` variable. Each widget is an item in the `items` array.

### Widget Types

| Type | Description | Use Case |
|------|-------------|----------|
| `type: 1` | Markdown text | Headers, descriptions |
| `type: 9` | Parameters | Filters (subscription, resource, time) |
| `type: 10` | Metrics chart | Line charts, tiles, grids |

---

## Metric Name Format (CRITICAL)

Azure Monitor Workbooks require a specific metric string format:

```
{namespace}-{category}-{metricName}
```

**Example:**
```
microsoft.cognitiveservices/accounts-Models  Usage-InputTokens
```

### Important Notes:
- The category name has **double spaces** where the original has ` - ` (dash with spaces)
- Original: `Models - Usage` → Workbook format: `Models  Usage`
- Original: `Models - HTTP Requests` → Workbook format: `Models HTTP Requests`

### Finding Metric Names

1. Check `docs/metrics.txt` for available metrics
2. Look for the "Name in REST API" column
3. Apply the format transformation above

---

## Adding a Line Chart

```bicep
{
  type: 10
  content: {
    chartId: 'unique-chart-id'           // Must be unique
    version: 'MetricsItem/2.0'
    size: 0                               // 0=normal, 1=small
    chartType: 2                          // 2=line chart
    resourceType: 'microsoft.cognitiveservices/accounts'
    metricScope: 0
    resourceIds: ['{Resource}']           // Uses the Resource parameter
    timeContextFromParameter: 'TimeRange'
    timeContext: {
      durationMs: 0
    }
    metrics: [
      {
        namespace: 'microsoft.cognitiveservices/accounts'
        metric: 'microsoft.cognitiveservices/accounts-Models  Usage-InputTokens'
        aggregation: 1                    // 1=Sum, 4=Average
        splitBy: 'ModelDeploymentName'    // Dimension to split by
      }
    ]
    title: 'Chart Title'
    showOpenInMe: true
    gridSettings: {
      rowLimit: 10000
    }
  }
  name: 'unique-element-name'             // Must be unique
}
```

---

## Adding a Filtered Chart (e.g., 429 errors)

To filter by a dimension value (like StatusCode=429):

```bicep
{
  type: 10
  content: {
    chartId: 'foundry-metric-429'
    version: 'MetricsItem/2.0'
    size: 0
    chartType: 2
    resourceType: 'microsoft.cognitiveservices/accounts'
    metricScope: 0
    resourceIds: ['{Resource}']
    timeContextFromParameter: 'TimeRange'
    timeContext: {
      durationMs: 0
    }
    metrics: [
      {
        namespace: 'microsoft.cognitiveservices/accounts'
        metric: 'microsoft.cognitiveservices/accounts-Models HTTP Requests-ModelRequests'
        aggregation: 1
        splitBy: 'ModelDeploymentName'
      }
    ]
    filters: [
      {
        key: 'StatusCode'                 // Dimension to filter
        operator: 0                       // 0 = equals
        values: ['429']                   // Value(s) to match
      }
    ]
    title: 'Rate Limited Requests (HTTP 429)'
    showOpenInMe: true
    gridSettings: {
      rowLimit: 10000
    }
  }
  name: 'foundry-metric-429'
}
```

---

## Adding KPI Tiles

For summary tiles showing aggregated values:

```bicep
{
  type: 10
  content: {
    chartId: 'kpi-tiles'
    version: 'MetricsItem/2.0'
    size: 4                               // 4=tile size
    chartType: 0                          // 0=tiles/grid (not line chart)
    resourceType: 'microsoft.cognitiveservices/accounts'
    metricScope: 0
    resourceIds: ['{Resource}']
    timeContextFromParameter: 'TimeRange'
    timeContext: {
      durationMs: 0
    }
    metrics: [
      {
        namespace: 'microsoft.cognitiveservices/accounts'
        metric: 'microsoft.cognitiveservices/accounts-Models  Usage-InputTokens'
        aggregation: 1
        columnName: 'Input Tokens'        // Display name in tile
      }
      {
        namespace: 'microsoft.cognitiveservices/accounts'
        metric: 'microsoft.cognitiveservices/accounts-Models  Usage-OutputTokens'
        aggregation: 1
        columnName: 'Output Tokens'
      }
    ]
    gridFormatType: 1
    tileSettings: {
      titleContent: {
        columnMatch: 'Metric'
        formatter: 1
      }
      leftContent: {
        columnMatch: 'Value'
        formatter: 12
        formatOptions: {
          palette: 'auto'
        }
        numberFormat: {
          unit: 17
          options: {
            style: 'decimal'
            maximumFractionDigits: 0
          }
        }
      }
      showBorder: true
    }
    gridSettings: {
      rowLimit: 10000
    }
  }
  name: 'kpi-tiles'
}
```

---

## Adding a Section Header

```bicep
{
  type: 1
  content: {
    json: '''
---
## Section Title
Optional description text.
'''
  }
  name: 'section-header-name'
}
```

---

## Available Foundry Metrics

From `docs/metrics.txt`, key metrics for Foundry (`kind=AIServices`):

### Models - Usage
| Metric | REST API Name | Description |
|--------|---------------|-------------|
| Input Tokens | `InputTokens` | Prompt tokens processed |
| Output Tokens | `OutputTokens` | Tokens generated |
| Total Tokens | `TotalTokens` | Input + Output |

### Models - HTTP Requests
| Metric | REST API Name | Description |
|--------|---------------|-------------|
| Model Requests | `ModelRequests` | API calls (has StatusCode dimension) |
| Model Availability | `ModelAvailabilityRate` | Availability percentage |

### Models - Latency
| Metric | REST API Name | Description |
|--------|---------------|-------------|
| Time to Response | `TimeToResponse` | First response latency |
| Time to Last Byte | `TimeToLastByte` | Full response latency |
| Tokens Per Second | `TokensPerSecond` | Generation speed |

---

## Common Dimensions for Splitting/Filtering

| Dimension | Description |
|-----------|-------------|
| `ModelDeploymentName` | Name of the model deployment |
| `ModelName` | Model type (e.g., gpt-4, llama) |
| `ModelVersion` | Model version |
| `StatusCode` | HTTP status (200, 429, 500, etc.) |
| `Region` | Azure region |

---

## Aggregation Types

| Value | Type |
|-------|------|
| 1 | Sum |
| 2 | Minimum |
| 3 | Maximum |
| 4 | Average |

---

## Deployment After Changes

```bash
# Delete existing and redeploy
az resource list --resource-group <rg-name> \
  --resource-type "Microsoft.Insights/workbooks" \
  --query "[].name" -o tsv | \
  xargs -I {} az resource delete \
    --resource-group <rg-name> \
    --resource-type "Microsoft.Insights/workbooks" \
    --name {}

az deployment group create \
  --resource-group <rg-name> \
  --template-file main.bicep \
  --parameters workbookId=$(uuidgen | tr '[:upper:]' '[:lower:]')
```

---

## Troubleshooting

### "Failed to find metric configuration"
- Check the metric name format (namespace-category-metricName)
- Verify double spaces in category names
- Confirm the metric exists in `docs/metrics.txt`

### Chart shows "null" or no data
- Verify the resource has `kind=AIServices`
- Check if the metric is being emitted (resource must have activity)
- Try removing the `splitBy` to see if aggregated data appears

### Dimension not available
- Not all metrics support all dimensions
- Check `docs/metrics.txt` for the "Dimensions" column
