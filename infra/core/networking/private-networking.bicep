param location string = resourceGroup().location
param virtualNetworkName string
param storageAccountName string
param virtualNetworkIntegrationSubnetName string
param virtualNetworkPrivateEndpointSubnetName string
param openaiName string
param docIntelligenceName string
param cogSearchName string
param appServiceName string

// var storageServices = [ 'table', 'blob', 'queue', 'file' ]
var storageServices = [ 'blob' ]

resource vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: virtualNetworkName

  resource integrationSubnet 'subnets' existing = {
    name: virtualNetworkIntegrationSubnetName
  }

  resource privateEndpointSubnet 'subnets' existing = {
    name: virtualNetworkPrivateEndpointSubnetName
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: storageAccountName
}

resource openAi 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: openaiName
}

resource docIntelligence 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: docIntelligenceName
}

resource cogSearch 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: cogSearchName
}

resource appService 'Microsoft.Web/sites@2023-01-01' existing = {
  name: appServiceName
}


// module keyVaultPrivateEndpoint 'private-endpoint.bicep' = {
//   name: 'keyVaultPrivateEndpoint'
//   params: {
//     dnsZoneName: 'privatelink.vaultcore.azure.net'
//     privateEndpointName: 'pe-${keyVault.name}'
//     location: location
//     privateLinkServiceId: keyVault.id
//     subnetId: vnet::privateEndpointSubnet.id
//     virtualNetworkName: vnet.name
//     groupIds: [ 'vault' ]
//  cc }
// }

module storagePrivateEndpoint 'private-endpoint.bicep' = [for (svc, i) in storageServices: {
  name: '${svc}-storagePrivateEndpoint'
  params: {
    dnsZoneName: 'privatelink.${svc}.${environment().suffixes.storage}'
    location: location
    privateEndpointName: 'pe-${storage.name}-${svc}'
    privateLinkServiceId: storage.id
    subnetId: vnet::privateEndpointSubnet.id
    virtualNetworkName: vnet.name
    groupIds: [svc]
  }
}]

module docIntelligencePrivateEnpoint 'private-endpoint.bicep' = {
  name: 'docIntelligenceEndpoint'
  params: {
    dnsZoneName: 'privatelink.cognitiveservices.azure.com'
    location: location
    privateEndpointName: 'pe-${docIntelligence.name}'
    privateLinkServiceId: resourceId('Microsoft.CognitiveServices/accounts', docIntelligence.name)
    subnetId: vnet::privateEndpointSubnet.id
    virtualNetworkName: vnet.name
    groupIds: [ 'account' ]
  }
}

module cogSearchPrivateEndpoint 'private-endpoint.bicep' = {
  name: 'cogSearchPrivateEndpoint'
  params: {
    dnsZoneName: 'privatelink.search.windows.net'
    location: location
    privateEndpointName: 'pe-${cogSearch.name}'
    privateLinkServiceId: resourceId('Microsoft.Search/searchServices', cogSearch.name)
    subnetId: vnet::privateEndpointSubnet.id
    virtualNetworkName: vnet.name
    groupIds: [ 'searchService' ] // 'search'
  }
}

module openaiPrivateEndpoint 'private-endpoint.bicep' = {
  name: 'openaiPrivateEndpoint'
  params: {
    dnsZoneName: 'privatelink.openai.azure.com'
    location: location
    privateEndpointName: 'pe-${openAi.name}'
    privateLinkServiceId: resourceId('Microsoft.CognitiveServices/accounts',openAi.name) //openAi.id
    subnetId: vnet::privateEndpointSubnet.id
    virtualNetworkName: vnet.name
    groupIds: [ 'account' ]
  }
}

module appServicePrivateEndpoint 'private-endpoint.bicep' = {
  name: 'appServicePrivateEndpoint'
  params: {
    dnsZoneName: 'privatelink.azurewebsites.net'
    location: location
    privateEndpointName: 'pe-${appService.name}'
    privateLinkServiceId: resourceId('Microsoft.Web/sites', appService.name)
    subnetId: vnet::privateEndpointSubnet.id
    virtualNetworkName: vnet.name
    groupIds: [ 'sites' ]
  }
}

