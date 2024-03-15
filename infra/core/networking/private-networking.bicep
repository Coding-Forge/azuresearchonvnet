param location string = resourceGroup().location
param virtualNetworkName string
param keyVaultName string
param storageAccountName string
param virtualNetworkIntegrationSubnetName string
param virtualNetworkPrivateEndpointSubnetName string
param openaiName string

var storageServices = [ 'table', 'blob', 'queue', 'file' ]


resource vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: virtualNetworkName

  resource integrationSubnet 'subnets' existing = {
    name: virtualNetworkIntegrationSubnetName
  }

  resource privateEndpointSubnet 'subnets' existing = {
    name: virtualNetworkPrivateEndpointSubnetName
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: storageAccountName
}

resource openAi 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: openaiName
}

module keyVaultPrivateEndpoint 'private-endpoint.bicep' = {
  name: 'keyVaultPrivateEndpoint'
  params: {
    dnsZoneName: 'privatelink.vaultcore.azure.net'
    privateEndpointName: 'pe-${keyVault.name}'
    location: location
    privateLinkServiceId: keyVault.id
    subnetId: vnet::privateEndpointSubnet.id
    virtualNetworkName: vnet.name
    groupIds: [ 'vault' ]
  }
}

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
    dnsZoneName: 'privatelink.cognitiveservices.azure.com'
    location: location
    privateEndpointName: 'pe-${openAi.name}'
    privateLinkServiceId: openAi.id
    subnetId: vnet::privateEndpointSubnet.id
    virtualNetworkName: vnet.name
    groupIds: [ 'cognitiveservices' ]
  }
}
