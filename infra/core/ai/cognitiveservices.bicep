metadata description = 'Creates an Azure Cognitive Services instance.'
param name string
param location string = resourceGroup().location
param tags object = {}
@description('The custom subdomain name used to access the API. Defaults to the value of the name parameter.')
param customSubDomainName string = name
param deployments array = []
param kind string = 'OpenAI'
param vnetName string
param privateEndpointsSubnetname string

@allowed([ 'Enabled', 'Disabled' ])
param publicNetworkAccess string = 'Enabled'
param sku object = {
  name: 'S0'
}

//var baseName = 'placeholdername'


// @allowed([ 'AzureDnsZone', 'Standard' ])
// param dnsEndpointType string = 'Standard'
// param minimumTlsVersion string = 'TLS1_2'


param allowedIpRules array = []
param networkAcls object = empty(allowedIpRules) ? {
  defaultAction: 'Allow'
} : {
  ipRules: allowedIpRules
  defaultAction: 'Deny'
}


// can I use these here?
// dnsEndpointType: dnsEndpointType
// minimumTlsVersion: minimumTlsVersion


//var openaiName = 'oai-${baseName}'
//var openaiPrivateEndpointName = 'pep-${openaiName}'
//var openaiDnsGroupName = '${openaiPrivateEndpointName}/default'
//var openaiDnsZoneName = 'privatelink.openai.azure.com'

resource vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: vnetName
  resource privateEndpointsSubnet 'subnets' existing = {
    name: privateEndpointsSubnetname
  }
}

resource account 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  properties: {
    customSubDomainName: customSubDomainName
    publicNetworkAccess: publicNetworkAccess
    networkAcls: networkAcls
  }
  sku: sku
}

@batchSize(1)
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = [for deployment in deployments: {
  parent: account
  name: deployment.name
  properties: {
    model: deployment.model
    raiPolicyName: contains(deployment, 'raiPolicyName') ? deployment.raiPolicyName : null
  }
  sku: contains(deployment, 'sku') ? deployment.sku : {
    name: 'Standard'
    capacity: 20
  }
}]

output endpoint string = account.properties.endpoint
output id string = account.id
output name string = account.name
