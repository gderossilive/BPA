param WorkspaceName string
param location string
param VMName string
param DceName string = ''
param DcrName string = 'sql-bpa-dcr'

resource LAW 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: WorkspaceName
}

resource DCE 'Microsoft.Insights/dataCollectionEndpoints@2023-03-11' = if (DceName != '') {
  name: DceName
  location: location
  properties: {
    networkAcls:{
      publicNetworkAccess: 'Enabled'
    }
  }
}

resource DCR_DC 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: DcrName
  location: location
  properties: {
    dataCollectionEndpointId: DCE.id
    dataSources: {
      windowsEventLogs: [
        {
            streams: [
                'Microsoft-Event'
            ]
            xPathQueries: [
                'Application!*[System[(Level=1 or Level=2)]]'
                'Security!*[System[(band(Keywords,4503599627370496))]]'
                'System!*[System[(Level=1 or Level=2)]]'
            ]
            name: 'eventLogsDataSource'
        }
    ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: LAW.id
          name: WorkspaceName
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-Event'
        ]
        destinations: [
          'la--1123508881'
        ]
        transformKql: 'source'
        outputStream: 'Microsoft-Event'
      }
    ]
  }
}

resource VM 'Microsoft.HybridCompute/machines@2023-10-03-preview' existing = {
  name: VMName
}

resource DCRA_VM 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = {
  name: 'configurationAccessEndpoint'
  scope: VM
  properties: {
    //dataCollectionEndpointId: DCE.id
    dataCollectionRuleId: DCR_DC.id
  }
}
