// ============================================================================
// Microsoft Foundry - TPM Dashboard
// Bicep deployment for Azure dMonitor Workbook + Alert Rules
// 
// Created by TeraSky - Provides comprehensive visibility into Microsoft Foundry
// model token usage, request metrics, and operational insights.
//= ============================================================================

@description('The friensdly name for the workbook that will be displayed in Azure Portal')
param workbookDisplayName string = 'Microsoft Foundry - TPM Dashboard'

@description('The id of resource instance to which the workbook will be associated')
param workbookSourceId string = 'Azure Monitor'

@description('The unique guid for this workbook instance. Provide a stable GUID for reproducible deployments.')
param workbookId string

@description('Location for the workbook resource')
param location string = resourceGroup().location

@description('Tags to apply to resources')
param tags object = {
  createdBy: 'TeraSky'
  purpose: 'Azure AI TPM Monitoring'
  version: '5.2'
}

// ============================================================================
// Alert Configuration Parameters
// ============================================================================

@description('Deploy metric alert rules for Azure OpenAI resources')
param deployAlerts bool = false

@description('Resource ID of the Azure OpenAI resource to monitor (required if deployAlerts is true)')
param openAiResourceId string = ''

@description('Action Group resource ID for alert notifications (required if deployAlerts is true)')
param actionGroupId string = ''

@description('Threshold for rate limited requests (429) per 5 minutes')
param rateLimitAlertThreshold int = 10

@description('Threshold for average latency in milliseconds')
param latencyAlertThreshold int = 30000

@description('Threshold for total tokens per minute (TPM) - useful for quota monitoring')
param tpmAlertThreshold int = 100000

@description('Severity level for alerts (0=Critical, 1=Error, 2=Warning, 3=Informational, 4=Verbose)')
@allowed([0, 1, 2, 3, 4])
param alertSeverity int = 2

// ============================================================================
// Workbook Content Definition
// ============================================================================

var workbookContent = {
  version: 'Notebook/1.0'
  items: [
    // ========== HEADER SECTION ==========
    {
      type: 1
      content: {
        json: '''
# Microsoft Foundry - TPM Dashboard

**TeraSky Custom Workbook** - Real-time visibility into Microsoft Foundry model token consumption and operational metrics

---

### Supported Models
- **Microsoft Foundry**: Llama, Mistral, DeepSeek, Phi, and other AI Foundry models

### What This Dashboard Provides
- **Input Tokens per Deployment** - Prompt tokens consumed
- **Output Tokens per Deployment** - Completion tokens generated
- **Requests per Deployment** - API call volume

---
'''
      }
      name: 'header-section'
    }
    // ========== GLOBAL PARAMETERS ==========
    {
      type: 9
      content: {
        version: 'KqlParameterItem/1.0'
        parameters: [
          {
            id: 'subscription-param'
            version: 'KqlParameterItem/1.0'
            name: 'Subscription'
            label: 'Subscription'
            type: 6
            isRequired: true
            multiSelect: true
            quote: '\''
            delimiter: ','
            typeSettings: {
              additionalResourceOptions: ['value::all']
              includeAll: true
              showDefault: false
            }
            defaultValue: 'value::all'
          }
          {
            id: 'resource-param'
            version: 'KqlParameterItem/1.0'
            name: 'Resource'
            label: 'Foundry Resource'
            type: 5
            isRequired: true
            multiSelect: true
            quote: '\''
            delimiter: ','
            query: '''
Resources
| where type =~ 'microsoft.cognitiveservices/accounts'
| where kind =~ 'AIServices'
| project value = id, label = name, selected = true, group = resourceGroup
'''
            crossComponentResources: ['{Subscription}']
            typeSettings: {
              additionalResourceOptions: ['value::all']
              includeAll: true
              showDefault: false
              resourceTypeFilter: {
                'microsoft.cognitiveservices/accounts': true
              }
            }
            defaultValue: 'value::all'
            queryType: 1
            resourceType: 'microsoft.resourcegraph/resources'
          }
          {
            id: 'timerange-param'
            version: 'KqlParameterItem/1.0'
            name: 'TimeRange'
            label: 'Time Range'
            type: 4
            isRequired: true
            typeSettings: {
              selectableValues: [
                { durationMs: 300000, displayText: 'Last 5 minutes' }
                { durationMs: 900000, displayText: 'Last 15 minutes' }
                { durationMs: 1800000, displayText: 'Last 30 minutes' }
                { durationMs: 3600000, displayText: 'Last 1 hour' }
                { durationMs: 14400000, displayText: 'Last 4 hours' }
                { durationMs: 43200000, displayText: 'Last 12 hours' }
                { durationMs: 86400000, displayText: 'Last 24 hours' }
                { durationMs: 172800000, displayText: 'Last 2 days' }
                { durationMs: 604800000, displayText: 'Last 7 days' }
                { durationMs: 2592000000, displayText: 'Last 30 days' }
              ]
              allowCustom: true
            }
            value: {
              durationMs: 3600000
            }
          }
          {
            id: 'aggregation-param'
            version: 'KqlParameterItem/1.0'
            name: 'Aggregation'
            label: 'Aggregation'
            type: 2
            isRequired: true
            typeSettings: {
              additionalResourceOptions: []
            }
            jsonData: '[{"value":"1","label":"Sum","selected":true},{"value":"4","label":"Average"},{"value":"3","label":"Maximum"},{"value":"2","label":"Minimum"}]'
            value: '1'
          }
        ]
        style: 'pills'
        queryType: 1
        resourceType: 'microsoft.resourcegraph/resources'
      }
      name: 'parameters-global'
    }
    // ========== TOKEN USAGE SECTION ==========
    {
      type: 1
      content: {
        json: '''
---
## Token Usage by Deployment
'''
      }
      name: 'foundry-tokens-section-header'
    }
    {
      type: 10
      content: {
        chartId: 'foundry-metric-input'
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
            metric: 'microsoft.cognitiveservices/accounts-Models  Usage-InputTokens'
            aggregation: 1
            splitBy: 'ModelDeploymentName'
          }
        ]
        title: 'Input Tokens by Deployment'
        showOpenInMe: true
        gridSettings: {
          rowLimit: 10000
        }
      }
      name: 'foundry-metric-input-tokens'
    }
    {
      type: 10
      content: {
        chartId: 'foundry-metric-output'
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
            metric: 'microsoft.cognitiveservices/accounts-Models  Usage-OutputTokens'
            aggregation: 1
            splitBy: 'ModelDeploymentName'
          }
        ]
        title: 'Output Tokens by Deployment'
        showOpenInMe: true
        gridSettings: {
          rowLimit: 10000
        }
      }
      name: 'foundry-metric-output-tokens'
    }
    // ========== REQUEST METRICS SECTION ==========
    {
      type: 1
      content: {
        json: '''
---
## Requests by Deployment
'''
      }
      name: 'requests-section-header'
    }
    {
      type: 10
      content: {
        chartId: 'foundry-metric-requests'
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
        title: 'Requests by Deployment'
        showOpenInMe: true
        gridSettings: {
          rowLimit: 10000
        }
      }
      name: 'foundry-metric-requests'
    }
    // 429 Rate Limited Requests
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
            key: 'StatusCode'
            operator: 0
            values: ['429']
          }
        ]
        title: 'Rate Limited Requests (HTTP 429) by Deployment'
        showOpenInMe: true
        gridSettings: {
          rowLimit: 10000
        }
      }
      name: 'foundry-metric-429'
    }
    // ========== FOOTER ==========
    {
      type: 1
      content: {
        json: '''
---
*TeraSky | Version 5.1 - Microsoft Foundry Models*
'''
      }
      name: 'footer-section'
    }
  ]
  isLocked: false
  fallbackResourceIds: ['Azure Monitor']
}

// ============================================================================
// Workbook Resource
// ============================================================================

resource workbook 'Microsoft.Insights/workbooks@2022-04-01' = {
  name: workbookId
  location: location
  tags: tags
  kind: 'shared'
  properties: {
    displayName: workbookDisplayName
    version: '1.0'
    sourceId: workbookSourceId
    category: 'workbook'
    serializedData: string(workbookContent)
  }
}

// ============================================================================
// Alert Rules (Optional)
// ============================================================================

// Alert: Rate Limiting (429 errors)
resource rateLimitAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = if (deployAlerts && !empty(openAiResourceId) && !empty(actionGroupId)) {
  name: 'alert-aoai-rate-limiting'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alerts when Azure OpenAI requests are being rate limited (HTTP 429). This indicates quota is being exceeded.'
    severity: alertSeverity
    enabled: true
    scopes: [openAiResourceId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'RateLimitedRequests'
          metricName: 'RatelimitedCalls'
          metricNamespace: 'Microsoft.CognitiveServices/accounts'
          operator: 'GreaterThan'
          threshold: rateLimitAlertThreshold
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroupId
        webHookProperties: {}
      }
    ]
  }
}

// Alert: High Latency
resource latencyAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = if (deployAlerts && !empty(openAiResourceId) && !empty(actionGroupId)) {
  name: 'alert-aoai-high-latency'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alerts when Azure OpenAI average latency exceeds the threshold. This may indicate performance degradation.'
    severity: alertSeverity
    enabled: true
    scopes: [openAiResourceId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighLatency'
          metricName: 'Latency'
          metricNamespace: 'Microsoft.CognitiveServices/accounts'
          operator: 'GreaterThan'
          threshold: latencyAlertThreshold
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroupId
        webHookProperties: {}
      }
    ]
  }
}

// Alert: High TPM (approaching quota)
resource tpmAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = if (deployAlerts && !empty(openAiResourceId) && !empty(actionGroupId)) {
  name: 'alert-aoai-high-tpm'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alerts when token transactions exceed the threshold. Use this to monitor when approaching quota limits.'
    severity: alertSeverity
    enabled: true
    scopes: [openAiResourceId]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighTPM'
          metricName: 'TokenTransaction'
          metricNamespace: 'Microsoft.CognitiveServices/accounts'
          operator: 'GreaterThan'
          threshold: tpmAlertThreshold
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroupId
        webHookProperties: {}
      }
    ]
  }
}

// Alert: Server Errors (5xx)
resource serverErrorAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = if (deployAlerts && !empty(openAiResourceId) && !empty(actionGroupId)) {
  name: 'alert-aoai-server-errors'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alerts when server errors occur on Azure OpenAI. This indicates service-side issues.'
    severity: 1 // Error severity for server errors
    enabled: true
    scopes: [openAiResourceId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'ServerErrors'
          metricName: 'ServerErrors'
          metricNamespace: 'Microsoft.CognitiveServices/accounts'
          operator: 'GreaterThan'
          threshold: 0
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroupId
        webHookProperties: {}
      }
    ]
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The resource ID of the deployed workbook')
output workbookResourceId string = workbook.id

@description('The name of the deployed workbook')
output workbookName string = workbook.name

@description('The display name of the workbook')
output workbookDisplayName string = workbookDisplayName

@description('Rate limit alert resource ID (if deployed)')
output rateLimitAlertId string = deployAlerts && !empty(openAiResourceId) && !empty(actionGroupId) ? rateLimitAlert.id : ''

@description('Latency alert resource ID (if deployed)')
output latencyAlertId string = deployAlerts && !empty(openAiResourceId) && !empty(actionGroupId) ? latencyAlert.id : ''

@description('TPM alert resource ID (if deployed)')
output tpmAlertId string = deployAlerts && !empty(openAiResourceId) && !empty(actionGroupId) ? tpmAlert.id : ''

@description('Server error alert resource ID (if deployed)')
output serverErrorAlertId string = deployAlerts && !empty(openAiResourceId) && !empty(actionGroupId) ? serverErrorAlert.id : ''
