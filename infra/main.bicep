targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

param useVirtualNetworkIntegration bool = false
param useVirtualNetworkPrivateEndpoint bool = false
param virtualNetworkAddressSpacePrefix string = '10.1.0.0/16'
param virtualNetworkIntegrationSubnetAddressSpacePrefix string = '10.1.1.0/24'
param virtualNetworkPrivateEndpointSubnetAddressSpacePrefix string = '10.1.2.0/24'

// AZD will set AZURE_PRINCIPAL_ID to the principal ID of the user executing the deployment (identity of the logged in user of AZD).
@description('The principal ID of the user to assign application roles.')
param principalId string = ''

// TODO: Remove this if confirmed that it is extra
// Locally, the AZURE_PRINCIPAL_ID may be a user. If running in a GitHub pipeline, AZURE_PRINCIPAL_ID is a service principal.
//@allowed([
//  'User'
//  'ServicePrincipal'
//])

// declared in the user section
//param principalType string = 'User'

// Tags that should be applied to all resources.
// 
// Note that 'azd-service-name' tags should be applied separately to service host resources.
// Example usage:
//   tags: union(tags, { 'azd-service-name': <service name in azure.yaml> })

var useVirtualNetwork = useVirtualNetworkIntegration || useVirtualNetworkPrivateEndpoint
var virtualNetworkName = 'bbbbbbv${abbrs.networkVirtualNetworks}${resourceToken}-vn5'
var virtualNetworkIntegrationSubnetName = 'bbbbbbv${abbrs.networkVirtualNetworksSubnets}${resourceToken}-int5'
var virtualNetworkPrivateEndpointSubnetName = 'bbbbbbv${abbrs.networkVirtualNetworksSubnets}${resourceToken}-pe5'

//var virtualNetworkName = ''
//var virtualNetworkIntegrationSubnetName = ''
//var virtualNetworkPrivateEndpointSubnetName = ''



var functionAppName = '${abbrs.webSitesFunctions}${resourceToken}'

param appServicePlanName string = ''
param backendServiceName string = ''
param resourceGroupName string = ''

param applicationInsightsDashboardName string = ''
param applicationInsightsName string = ''
param logAnalyticsName string = ''

param searchServiceName string = ''
param searchServiceResourceGroupName string = ''
param searchServiceLocation string = ''
// The free tier does not support managed identity (required) or semantic search (optional)
@allowed([ 'free', 'basic', 'standard', 'standard2', 'standard3', 'storage_optimized_l1', 'storage_optimized_l2' ])
param searchServiceSkuName string // Set in main.parameters.json
param searchIndexName string // Set in main.parameters.json
param searchQueryLanguage string // Set in main.parameters.json
param searchQuerySpeller string // Set in main.parameters.json
param searchServiceSemanticRankerLevel string // Set in main.parameters.json
var actualSearchServiceSemanticRankerLevel = (searchServiceSkuName == 'free') ? 'disabled' : searchServiceSemanticRankerLevel
param useSearchServiceKey bool = searchServiceSkuName == 'free'

param storageAccountName string = ''
param storageResourceGroupName string = ''
//param storageResourceGroupLocation string = location
param storageContainerName string = 'content'
param storageSkuName string // Set in main.parameters.json

@allowed([ 'F1', 'S1', 'S2', 'S3' ])
param appServiceSkuName string // Set in main.parameters.json

@allowed([ 'azure', 'openai', 'azure_custom' ])
param openAiHost string // Set in main.parameters.json
param isAzureOpenAiHost bool = startsWith(openAiHost, 'azure')
param azureOpenAiCustomUrl string = ''
param azureOpenAiApiVersion string = ''

param openAiServiceName string = ''
param openAiResourceGroupName string = ''
param useGPT4V bool = false

param searchServiceSecretName string = 'searchServiceSecret'

@description('Location for the OpenAI resource group')
@allowed([ 'canadaeast', 'eastus', 'eastus2', 'francecentral', 'switzerlandnorth', 'uksouth', 'japaneast', 'northcentralus', 'australiaeast', 'swedencentral' ])
@metadata({
  azd: {
    type: 'location'
  }
})
param openAiResourceGroupLocation string

param openAiSkuName string = 'S0'

param openAiApiKey string = ''
param openAiApiOrganization string = ''

param documentIntelligenceServiceName string = ''
param documentIntelligenceResourceGroupName string = ''
// Limited regions for new version:
// https://learn.microsoft.com/azure/ai-services/document-intelligence/concept-layout
@description('Location for the Document Intelligence resource group')
@allowed([ 'eastus', 'westus2', 'westeurope' ])
@metadata({
  azd: {
    type: 'location'
  }
})
param documentIntelligenceResourceGroupLocation string

param documentIntelligenceSkuName string = 'S0'

//param computerVisionServiceName string = ''
//param computerVisionResourceGroupName string = ''
//param computerVisionResourceGroupLocation string = 'eastus' // Vision vectorize API is yet to be deployed globally
//param computerVisionSkuName string = 'S1'

param chatGptDeploymentName string // Set in main.parameters.json
//param chatGptDeploymentCapacity int = 30
//param chatGpt4vDeploymentCapacity int = 10
param chatGptModelName string = startsWith(openAiHost, 'azure') ? 'gpt-35-turbo' : 'gpt-3.5-turbo'
//param chatGptModelVersion string = '0613'
param embeddingDeploymentName string // Set in main.parameters.json
//param embeddingDeploymentCapacity int = 30
param embeddingModelName string = 'text-embedding-ada-002'
param gpt4vModelName string = 'gpt-4'
param gpt4vDeploymentName string = 'gpt-4v'
//param gpt4vModelVersion string = 'vision-preview'

param tenantId string = tenant().tenantId
param authTenantId string = ''

// Used for the optional login and document level access control system
param useAuthentication bool = false
param enforceAccessControl bool = false
param serverAppId string = ''
@secure()
param serverAppSecret string = ''
param clientAppId string = ''
@secure()
param clientAppSecret string = ''

// Used for optional CORS support for alternate frontends
param allowedOrigin string = '' // should start with https://, shouldn't end with a /

@description('Use Application Insights for monitoring and performance tracing')
param useApplicationInsights bool = false

@description('Show options to use vector embeddings for searching in the app UI')
param useVectors bool = false
@description('Use Built-in integrated Vectorization feature of AI Search to vectorize and ingest documents')
param useIntegratedVectorization bool = false

var abbrs = loadJsonContent('abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }
//var computerVisionName = !empty(computerVisionServiceName) ? computerVisionServiceName : '${abbrs.cognitiveServicesComputerVision}${resourceToken}'

var tenantIdForAuth = !empty(authTenantId) ? authTenantId : tenantId
var authenticationIssuerUri = '${environment().authentication.loginEndpoint}${tenantIdForAuth}/v2.0'

@description('Whether the deployment is running on GitHub Actions')
param runningOnGh string = ''

@description('Whether the deployment is running on Azure DevOps Pipeline')
param runningOnAdo string = ''


resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

/*
@description('This is the built-in role definition for the Key Vault Secret User role. See https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#key-vault-secrets-user for more information.')
resource keyVaultSecretUserRoleDefintion 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '4633458b-17de-408a-b874-0445c86b69e6'
}

@description('This is the built-in role definition for the Azure Event Hubs Data Receiver role. See https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#azure-event-hubs-data-receiver for more information.')
resource eventHubDataReceiverUserRoleDefintion 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'a638d3c7-ab3a-418d-83e6-5f17a39d4fde'
}

@description('This is the built-in role definition for the Azure Storage Blob Data Owner role. See https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#storage-blob-data-owner for more information.')
resource storageBlobDataOwnerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
}
*/

resource openAiResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = if (!empty(openAiResourceGroupName)) {
  name: !empty(openAiResourceGroupName) ? openAiResourceGroupName : rg.name
}

resource documentIntelligenceResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = if (!empty(documentIntelligenceResourceGroupName)) {
  name: !empty(documentIntelligenceResourceGroupName) ? documentIntelligenceResourceGroupName : rg.name
}

/*
resource computerVisionResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = if (!empty(computerVisionResourceGroupName)) {
  name: !empty(computerVisionResourceGroupName) ? computerVisionResourceGroupName : rg.name
}
*/

resource searchServiceResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = if (!empty(searchServiceResourceGroupName)) {
  name: !empty(searchServiceResourceGroupName) ? searchServiceResourceGroupName : rg.name
}

resource storageResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = if (!empty(storageResourceGroupName)) {
  name: !empty(storageResourceGroupName) ? storageResourceGroupName : rg.name
}


// TODO: Scope to the specific resource (Event Hub, Storage, Key Vault) instead of the resource group.
//       See https://github.com/Azure/bicep/discussions/5926

/*
module storageRoleAssignment 'core/security/role.bicep' = {
  name: 'storageRoleAssignment'
  scope: rg
  params: {
    principalId: functionApp.outputs.identityPrincipalId
    roleDefinitionId: storageBlobDataOwnerRoleDefinition.name
    principalType: 'ServicePrincipal'
  }
}
*/
/*
module keyVaultRoleAssignment 'core/security/role.bicep' = {
  name: 'keyVaultRoleAssignment'
  scope: rg
  params: {
    principalId: functionApp.outputs.identityPrincipalId
    roleDefinitionId: keyVaultSecretUserRoleDefintion.name
    principalType: 'ServicePrincipal'
  }
}
*/

module logAnalytics './core/monitor/loganalytics.bicep' = {
  name: 'logAnalytics'
  scope: rg
  params: {
    name: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    location: location
    tags: tags
  }
}

module appInsights './core/monitor/applicationinsights.bicep' = {
  name: 'applicationInsights'
  scope: rg
  params: {
    name: '${abbrs.insightsComponents}${resourceToken}'
    tags: tags

    includeDashboard: false
    dashboardName: ''
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
    location: location
  }
}

module storage './core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}${resourceToken}'
    location: location
    tags: tags

    fileShares: [
      {
        name: functionAppName
      }
    ]
    allowBlobPublicAccess: false
    // publicNetworkAccess: 'Enabled'
    sku: {
      name: storageSkuName
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 2
    }
    containers: [
      {
        name: storageContainerName
        publicAccess: 'None'
      }
    ]

    // Set the key vault name to set the connection string as a secret in the key vault.
    useVirtualNetworkPrivateEndpoint: useVirtualNetworkPrivateEndpoint
  }
}

// Monitor application with Azure Monitor
module monitoring 'core/monitor/monitoring.bicep' = if (useApplicationInsights) {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsDashboardName: applicationInsightsDashboardName
  }
}

module applicationInsightsDashboard 'backend-dashboard.bicep' = if (useApplicationInsights) {
  name: 'application-insights-dashboard'
  scope: rg
  params: {
    name: !empty(applicationInsightsDashboardName) ? applicationInsightsDashboardName : '${abbrs.portalDashboards}${resourceToken}'
    location: location
    applicationInsightsName: useApplicationInsights ? monitoring.outputs.applicationInsightsName : ''
  }
}

// Create an App Service Plan to group applications under the same payment plan and SKU
module appServicePlan 'core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: appServiceSkuName
      capacity: 1
    }
    kind: 'linux'
  }
}


module backend 'core/host/appservice.bicep' = {
  name: 'web'
  scope: rg
  params: {
    name: !empty(backendServiceName) ? backendServiceName : '${abbrs.webSitesAppService}backend-${resourceToken}'
    location: location
    tags: union(tags, { 'azd-service-name': 'backend' })
    appServicePlanId: appServicePlan.outputs.id
    runtimeName: 'python'
    runtimeVersion: '3.10'
    appCommandLine: 'python3 -m gunicorn main:app'
    scmDoBuildDuringDeployment: true
    managedIdentity: true
    appSettings: {
      AZURE_STORAGE_ACCOUNT: storage.outputs.name
      AZURE_STORAGE_CONTAINER: storageContainerName
      AZURE_OPENAI_RESOURCE_GROUP: 'coding-forge'
      AZURE_OPENAI_SERVICE: isAzureOpenAiHost ? openAi.outputs.name : ''
      AZURE_SEARCH_INDEX: searchIndexName
      AZURE_SEARCH_SERVICE: searchService.outputs.name
      AZURE_OPENAI_CHATGPT_DEPLOYMENT: chatGptDeploymentName
      AZURE_OPENAI_CHATGPT_MODEL: chatGptModelName
      AZURE_OPENAI_EMB_DEPLOYMENT: embeddingDeploymentName
      APPLICATIONINSIGHTS_CONNECTION_STRING: useApplicationInsights ? monitoring.outputs.applicationInsightsConnectionString : ''
    }
  }
}


// The application frontend
// module backend 'core/host/appservice.bicep' = {
//   name: 'web'
//   scope: rg
//   params: {
//     name: !empty(backendServiceName) ? backendServiceName : '${abbrs.webSitesAppService}backend-${resourceToken}'
//     location: location
//     tags: union(tags, { 'azd-service-name': 'backend' })
//     appServicePlanId: appServicePlan.outputs.id
//     runtimeName: 'python'
//     runtimeVersion: '3.11'
//     appCommandLine: 'python3 -m gunicorn main:app'
//     scmDoBuildDuringDeployment: true
//     managedIdentity: true
//     allowedOrigins: [ allowedOrigin ]
//     clientAppId: clientAppId
//     serverAppId: serverAppId
//     clientSecretSettingName: !empty(clientAppSecret) ? 'AZURE_CLIENT_APP_SECRET' : ''
//     authenticationIssuerUri: authenticationIssuerUri
//     use32BitWorkerProcess: appServiceSkuName == 'S1'
//     alwaysOn: appServiceSkuName != 'F1'
//     appSettings: {
//       AZURE_STORAGE_ACCOUNT: storage.outputs.name
//       AZURE_STORAGE_CONTAINER: storageContainerName
//       AZURE_SEARCH_INDEX: searchIndexName
//       AZURE_SEARCH_SERVICE: searchService.outputs.name
//       AZURE_SEARCH_SEMANTIC_RANKER: actualSearchServiceSemanticRankerLevel
//       SEARCH_SECRET_NAME: useSearchServiceKey ? searchServiceSecretName : ''
//       AZURE_SEARCH_QUERY_LANGUAGE: searchQueryLanguage
//       AZURE_SEARCH_QUERY_SPELLER: searchQuerySpeller
//       APPLICATIONINSIGHTS_CONNECTION_STRING: useApplicationInsights ? monitoring.outputs.applicationInsightsConnectionString : ''
//       // Shared by all OpenAI deployments
//       OPENAI_HOST: openAiHost
//       AZURE_OPENAI_CUSTOM_URL: azureOpenAiCustomUrl
//       AZURE_OPENAI_API_VERSION: azureOpenAiApiVersion
//       AZURE_OPENAI_EMB_MODEL_NAME: embeddingModelName
//       AZURE_OPENAI_CHATGPT_MODEL: chatGptModelName
//       AZURE_OPENAI_GPT4V_MODEL: gpt4vModelName
//       // Specific to Azure OpenAI
//       AZURE_OPENAI_SERVICE: isAzureOpenAiHost ? openAi.outputs.name : ''
//       AZURE_OPENAI_CHATGPT_DEPLOYMENT: chatGptDeploymentName
//       AZURE_OPENAI_EMB_DEPLOYMENT: embeddingDeploymentName
//       AZURE_OPENAI_GPT4V_DEPLOYMENT: useGPT4V ? gpt4vDeploymentName : ''
//       // Used only with non-Azure OpenAI deployments
//       OPENAI_API_KEY: openAiApiKey
//       OPENAI_ORGANIZATION: openAiApiOrganization
//       // Optional login and document level access control system
//       AZURE_USE_AUTHENTICATION: useAuthentication
//       AZURE_ENFORCE_ACCESS_CONTROL: enforceAccessControl
//       AZURE_SERVER_APP_ID: serverAppId
//       AZURE_SERVER_APP_SECRET: serverAppSecret
//       AZURE_CLIENT_APP_ID: clientAppId
//       AZURE_CLIENT_APP_SECRET: clientAppSecret
//       AZURE_TENANT_ID: tenantId
//       AZURE_AUTH_TENANT_ID: tenantIdForAuth
//       AZURE_AUTHENTICATION_ISSUER_URI: authenticationIssuerUri
//       // CORS support, for frontends on other hosts
//       ALLOWED_ORIGIN: allowedOrigin
//       USE_VECTORS: useVectors
//       USE_GPT4V: useGPT4V
//     }
//   }
// }

/*
var defaultOpenAiDeployments = [
  {
    name: chatGptDeploymentName
    model: {
      format: 'OpenAI'
      name: chatGptModelName
      version: chatGptModelVersion
    }
    sku: {
      name: 'Standard'
      capacity: chatGptDeploymentCapacity
    }
  }
  {
    name: embeddingDeploymentName
    model: {
      format: 'OpenAI'
      name: embeddingModelName
      version: '2'
    }
    sku: {
      name: 'Standard'
      capacity: embeddingDeploymentCapacity
    }
  }
]

var openAiDeployments = concat(defaultOpenAiDeployments, useGPT4V ? [
  {
      name: gpt4vDeploymentName
      model: {
        format: 'OpenAI'
        name: gpt4vModelName
        version: gpt4vModelVersion
      }
      sku: {
        name: 'Standard'
        capacity: chatGpt4vDeploymentCapacity
      }
    }
  ] : [])
*/

module openAi 'core/ai/cognitiveservices.bicep' = if (isAzureOpenAiHost) {
  name: 'openai'
  scope: openAiResourceGroup
  params: {
    name: !empty(openAiServiceName) ? openAiServiceName : '${abbrs.cognitiveServicesAccounts}${resourceToken}'
    location: openAiResourceGroupLocation
    tags: tags
    sku: {
      name: openAiSkuName
    }
    vnetName: vnet.outputs.virtualNetworkName
    //deployments: openAiDeployments
    publicNetworkAccess: 'Disabled'
    customSubDomainName: virtualNetworkIntegrationSubnetName
    privateEndpointsSubnetname: virtualNetworkPrivateEndpointSubnetName
  }
}

// module openAI  'core/ai/cognitiveservices.bicep' = if (isAzureOpenAiHost) {
//   name: 'openai'
//   scope: openAiResourceGroup
//   params: {
//     sku: {
//       name: openAiSkuName
//     }
//     kind: 'OpenAI'
//     name: 'openAi'
//     location: location
//     vnetName: vnet.outputs.virtualNetworkName
//     privateEndpointsSubnetname: virtualNetworkPrivateEndpointSubnetName
//     // privateEndpoints: [
//     //   {
//     //     name: virtualNetworkPrivateEndpointSubnetName
//     //     privateLinkServiceConnectionState: {
//     //       status: 'Approved'
//     //       description: 'Approved'
//     //     }
//     //   }
//     // ]
//     deployments: [
//       {
//         name: 'model-deployment-gpt'
//         sku: {
//           name: 'Standard'
//           capacity: 120
//         }
//         properties: {
//           model: {
//             format: 'OpenAI'
//             name: 'text-davinci-002'
//             version: 1
//           }
//           raiPolicyName: 'Microsoft.Default'
//         }
//       }
//     ]
//   }
// }



// Formerly known as Form Recognizer
module documentIntelligence 'core/ai/cognitiveservices.bicep' = {
  name: 'documentintelligence'
  scope: documentIntelligenceResourceGroup
  params: {
    name: !empty(documentIntelligenceServiceName) ? documentIntelligenceServiceName : '${abbrs.cognitiveServicesDocumentIntelligence}${resourceToken}'
    kind: 'FormRecognizer'
    location: documentIntelligenceResourceGroupLocation
    tags: tags
    sku: {
      name: documentIntelligenceSkuName
    }
    publicNetworkAccess: 'Disabled'
    vnetName: vnet.outputs.virtualNetworkName
    customSubDomainName: virtualNetworkIntegrationSubnetName
    privateEndpointsSubnetname: virtualNetworkPrivateEndpointSubnetName
  }
}

// Currently, we only need Key Vault for storing Search service key,
// which is only used for free tier

module searchService 'core/search/search-services.bicep' = {
  name: 'search-service'
  scope: searchServiceResourceGroup
  params: {
    name: !empty(searchServiceName) ? searchServiceName : 'gptkb-${resourceToken}'
    location: !empty(searchServiceLocation) ? searchServiceLocation : location
    tags: tags
    authOptions: {
      aadOrApiKey: {
        aadAuthFailureMode: 'http401WithBearerChallenge'
      }
    }
    sku: {
      name: searchServiceSkuName
    }
    semanticSearch: actualSearchServiceSemanticRankerLevel
    
  }
}

module integrationSubnetNsg 'core/networking/network-security-group.bicep' = if (useVirtualNetwork) {
  name: 'integrationSubnetNsg'
  scope: rg
  params: {
    name: '${abbrs.networkNetworkSecurityGroups}${resourceToken}-integration-subnet'
    location: location
  }
}

module privateEndpointSubnetNsg 'core/networking/network-security-group.bicep' = if (useVirtualNetwork) {
  name: 'privateEndpointSubnetNsg'
  scope: rg
  params: {
    name: '${abbrs.networkNetworkSecurityGroups}${resourceToken}-private-endpoint-subnet'
    location: location
  }
}

module vnet './core/networking/virtual-network.bicep' = if (useVirtualNetwork) {
  name: 'vnet'
  scope: rg
  params: {
    name: virtualNetworkName
    location: location
    tags: tags

    virtualNetworkAddressSpacePrefix: virtualNetworkAddressSpacePrefix

    // TODO: Find a better way to handle subnets. I'm not a fan of this array of object approach (losing Intellisense).
    subnets: [
      {
        name: virtualNetworkIntegrationSubnetName
        addressPrefix: virtualNetworkIntegrationSubnetAddressSpacePrefix
        networkSecurityGroupId: useVirtualNetwork ? integrationSubnetNsg.outputs.id : null

        delegations: [
          {
            name: 'delegation'
            properties: {
              serviceName: 'Microsoft.Web/serverFarms'
            }
          }
        ]
      }
      {
        name: virtualNetworkPrivateEndpointSubnetName
        addressPrefix: virtualNetworkPrivateEndpointSubnetAddressSpacePrefix
        networkSecurityGroupId: useVirtualNetwork ? privateEndpointSubnetNsg.outputs.id : null
        privateEndpointNetworkPolicies: 'Disabled'
      }
    ]
  }
}

// Sets up private endpoints and private dns zones for the resources.
module networking 'core/networking/private-networking.bicep' = if (useVirtualNetworkPrivateEndpoint) {
  name: 'networking'
  scope: rg
  params: {
    location: location
    virtualNetworkIntegrationSubnetName: virtualNetworkIntegrationSubnetName
    virtualNetworkName: virtualNetworkName
    virtualNetworkPrivateEndpointSubnetName: virtualNetworkPrivateEndpointSubnetName
    openaiName: openAi.outputs.name
    docIntelligenceName: documentIntelligence.outputs.name
    cogSearchName: searchService.outputs.name
    storageAccountName: storage.outputs.name
  }
}

module functionPlan 'core/host/functionplan.bicep' = {
  name: 'functionPlan'
  scope: rg
  params: {
    location: location
    tags: tags
    OperatingSystem: 'Linux'
    name: '${abbrs.webServerFarms}${resourceToken}'
    planSku: 'EP1'
  }
}


// USER ROLES
var principalType = empty(runningOnGh) && empty(runningOnAdo) ? 'User' : 'ServicePrincipal'

module openAiRoleUser 'core/security/role.bicep' = if (isAzureOpenAiHost) {
  scope: openAiResourceGroup
  name: 'openai-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalType: principalType
  }
}

// For both document intelligence and computer vision
module cognitiveServicesRoleUser 'core/security/role.bicep' = {
  scope: rg
  name: 'cognitiveservices-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: 'a97b65f3-24c7-4388-baec-2e87135dc908'
    principalType: principalType
  }
}

module storageRoleUser 'core/security/role.bicep' = {
  scope: storageResourceGroup
  name: 'storage-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
    principalType: principalType
  }
}

module storageContribRoleUser 'core/security/role.bicep' = {
  scope: storageResourceGroup
  name: 'storage-contribrole-user'
  params: {
    principalId: principalId
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    principalType: principalType
  }
}

// Only create if using managed identity (non-free tier)
module searchRoleUser 'core/security/role.bicep' = if (!useSearchServiceKey) {
  scope: searchServiceResourceGroup
  name: 'search-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '1407120a-92aa-4202-b7e9-c0e197c71c8f'
    principalType: principalType
  }
}

module searchContribRoleUser 'core/security/role.bicep' = if (!useSearchServiceKey) {
  scope: searchServiceResourceGroup
  name: 'search-contrib-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
    principalType: principalType
  }
}

module searchSvcContribRoleUser 'core/security/role.bicep' = if (!useSearchServiceKey) {
  scope: searchServiceResourceGroup
  name: 'search-svccontrib-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
    principalType: principalType
  }
}

// SYSTEM IDENTITIES
module openAiRoleBackend 'core/security/role.bicep' = if (isAzureOpenAiHost) {
  scope: openAiResourceGroup
  name: 'openai-role-backend'
  params: {
    principalId: backend.outputs.identityPrincipalId
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalType: 'ServicePrincipal'
  }
}

module openAiRoleSearchService 'core/security/role.bicep' = if (isAzureOpenAiHost && useIntegratedVectorization) {
  scope: openAiResourceGroup
  name: 'openai-role-searchservice'
  params: {
    principalId: searchService.outputs.principalId
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalType: 'ServicePrincipal'
  }
}

module storageRoleBackend 'core/security/role.bicep' = {
  scope: storageResourceGroup
  name: 'storage-role-backend'
  params: {
    principalId: backend.outputs.identityPrincipalId
    roleDefinitionId: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
    principalType: 'ServicePrincipal'
  }
}

module storageRoleSearchService 'core/security/role.bicep' = if (useIntegratedVectorization) {
  scope: storageResourceGroup
  name: 'storage-role-searchservice'
  params: {
    principalId: searchService.outputs.principalId
    roleDefinitionId: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
    principalType: 'ServicePrincipal'
  }
}

// Used to issue search queries
// https://learn.microsoft.com/azure/search/search-security-rbac
module searchRoleBackend 'core/security/role.bicep' = if (!useSearchServiceKey) {
  scope: searchServiceResourceGroup
  name: 'search-role-backend'
  params: {
    principalId: backend.outputs.identityPrincipalId
    roleDefinitionId: '1407120a-92aa-4202-b7e9-c0e197c71c8f'
    principalType: 'ServicePrincipal'
  }
}

// Used to read index definitions (required when using authentication)
// https://learn.microsoft.com/azure/search/search-security-rbac
module searchReaderRoleBackend 'core/security/role.bicep' = if (useAuthentication && !useSearchServiceKey) {
  scope: searchServiceResourceGroup
  name: 'search-reader-role-backend'
  params: {
    principalId: backend.outputs.identityPrincipalId
    roleDefinitionId: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
    principalType: 'ServicePrincipal'
  }
}

// For computer vision access by the backend
module cognitiveServicesRoleBackend 'core/security/role.bicep' = if (useGPT4V) {
  scope: rg
  name: 'cognitiveservices-role-backend'
  params: {
    principalId: backend.outputs.identityPrincipalId
    roleDefinitionId: 'a97b65f3-24c7-4388-baec-2e87135dc908'
    principalType: 'ServicePrincipal'
  }
}

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenantId
output AZURE_AUTH_TENANT_ID string = authTenantId
output AZURE_RESOURCE_GROUP string = rg.name

// Shared by all OpenAI deployments
output OPENAI_HOST string = openAiHost
output AZURE_OPENAI_EMB_MODEL_NAME string = embeddingModelName
output AZURE_OPENAI_CHATGPT_MODEL string = chatGptModelName
output AZURE_OPENAI_GPT4V_MODEL string = gpt4vModelName

// Specific to Azure OpenAI
//output AZURE_OPENAI_SERVICE string = isAzureOpenAiHost ? openAi.outputs.name : ''
output AZURE_OPENAI_API_VERSION string = isAzureOpenAiHost ? azureOpenAiApiVersion : ''
output AZURE_OPENAI_RESOURCE_GROUP string = isAzureOpenAiHost ? openAiResourceGroup.name : ''
output AZURE_OPENAI_CHATGPT_DEPLOYMENT string = isAzureOpenAiHost ? chatGptDeploymentName : ''
output AZURE_OPENAI_EMB_DEPLOYMENT string = isAzureOpenAiHost ? embeddingDeploymentName : ''
output AZURE_OPENAI_GPT4V_DEPLOYMENT string = isAzureOpenAiHost ? gpt4vDeploymentName : ''

// Used only with non-Azure OpenAI deployments
output OPENAI_API_KEY string = (openAiHost == 'openai') ? openAiApiKey : ''
output OPENAI_ORGANIZATION string = (openAiHost == 'openai') ? openAiApiOrganization : ''

output AZURE_DOCUMENTINTELLIGENCE_SERVICE string = documentIntelligence.outputs.name
output AZURE_DOCUMENTINTELLIGENCE_RESOURCE_GROUP string = documentIntelligenceResourceGroup.name

output AZURE_SEARCH_INDEX string = searchIndexName
output AZURE_SEARCH_SERVICE string = searchService.outputs.name
output AZURE_SEARCH_SECRET_NAME string = useSearchServiceKey ? searchServiceSecretName : ''
output AZURE_SEARCH_SERVICE_RESOURCE_GROUP string = searchServiceResourceGroup.name
output AZURE_SEARCH_SEMANTIC_RANKER string = actualSearchServiceSemanticRankerLevel
output AZURE_SEARCH_SERVICE_ASSIGNED_USERID string = searchService.outputs.principalId

output AZURE_STORAGE_ACCOUNT string = storage.outputs.name
output AZURE_STORAGE_CONTAINER string = storageContainerName
output AZURE_STORAGE_RESOURCE_GROUP string = storageResourceGroup.name

output AZURE_USE_AUTHENTICATION bool = useAuthentication

output BACKEND_URI string = backend.outputs.uri

// from previous azd
output APPLICATIONINSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString
