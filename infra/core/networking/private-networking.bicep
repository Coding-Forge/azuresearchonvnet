param location string = resourceGroup().location
param virtualNetworkName string
param storageAccountName string
param virtualNetworkIntegrationSubnetName string
param virtualNetworkPrivateEndpointSubnetName string
param openaiName string
param docIntelligenceName string
param cogSearchName string

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
//   }
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
    groupIds: [
      svc
    ]
  }
}]

module docIntelligencePrivateEnpoint 'private-endpoint.bicep' = {
  name: 'docIntelligenceEnpoint'
  params: {
    dnsZoneName: 'privatelink.cognitiveservices.azure.com'
    location: location
    privateEndpointName: 'pe-${docIntelligence.name}'
    privateLinkServiceId: docIntelligence.id
    subnetId: vnet::privateEndpointSubnet.id
    virtualNetworkName: vnet.name
    groupIds: [ 'documentintelligence' ]
  }
}

module cogSearchPrivateEndpoint 'private-endpoint.bicep' = {
  name: 'cogSearchPrivateEndpoint'
  params: {
    dnsZoneName: 'privatelink.cognitiveservices.azure.com'
    location: location
    privateEndpointName: 'pe-${cogSearch.name}'
    privateLinkServiceId: cogSearch.id
    subnetId: vnet::privateEndpointSubnet.id
    virtualNetworkName: vnet.name
    groupIds: [ 'cognitiveservices' ]
  }
}

/*
module functionPrivateEndpoint 'private-endpoint.bicep' = {
  name: 'functionPrivateEndpoint'
  params: {
    dnsZoneName: 'privatelink.azurewebsites.net'
    location: location
    privateEndpointName: 'pe-${function.name}'
    privateLinkServiceId: function.id
    subnetId: vnet::privateEndpointSubnet.id
    virtualNetworkName: vnet.name
    groupIds: [ 'sites' ]
  }
}
*/

module openaiPrivateEndpoint 'private-endpoint.bicep' = {
  name: 'openaiPrivateEndpoint'
  params: {
    dnsZoneName: 'privatelink.openai.azure.com'
    location: location
    privateEndpointName: 'pe-${openAi.name}'
    privateLinkServiceId: openAi.id
    subnetId: vnet::privateEndpointSubnet.id
    virtualNetworkName: vnet.name
    groupIds: [ 'openai' ]
  }
}
