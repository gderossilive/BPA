param VMName string
param dataCollectionEndpointId string
param dataCollectionRuleId string
param Seed string


resource VM 'Microsoft.HybridCompute/machines@2023-10-03-preview' existing = {
  name: VMName
}

resource DCRA_VM 'Microsoft.Insights/dataCollectionRuleAssociations@2023-03-11' = {
  name: 'DCRA-VM-${Seed}'
  scope: VM
  properties: {
    dataCollectionEndpointId: dataCollectionEndpointId
    dataCollectionRuleId: dataCollectionRuleId
  }
}
