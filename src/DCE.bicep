param Seed string
param location string = resourceGroup().location

var DceName = 'DCE-${Seed}'

resource DCE 'Microsoft.Insights/dataCollectionEndpoints@2023-03-11' = {
  name: DceName
  location: location
  properties: {
    networkAcls: {
      publicNetworkAccess: 'Enabled'
    }
  }
}

output DCEResourceId string = DCE.id
