param WorkspaceName string
param location string
param Seed string
param VMName string
param customTableName string = 'SqlAssessment_CL'
param filePattern string
param DceName string


resource DCE 'Microsoft.Insights/dataCollectionEndpoints@2023-03-11' = {
  name: DceName
  location: location
}

module DCR_SqlBPA 'DCR.bicep' = {
  name: 'DCR-${Seed}'
  params: {
    Seed: Seed
    customTableName: customTableName
    filePattern: filePattern
    WorkspaceName: WorkspaceName
    DceName: DceName
  }
}


module DCR_VM_Association 'DCR-VM-Association.bicep' = {
  name: 'DCR-${VMName}-${Seed}'
  params: {
    VMName: VMName
    dataCollectionEndpointId: DCE.id
    dataCollectionRuleId: DCR_SqlBPA.outputs.DCR_SqlBPA_id
    Seed: Seed
  }
}
