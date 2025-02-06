param WorkspaceName string
param location string
param VMName string

resource LAW 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: WorkspaceName
}

// Deploy AMA extension
module AMA 'VmExtension.bicep' = {
  name: '${VMName}-AzureMonitorWindowsAgent'
  params: {
    vmName: VMName
    VmExtensionName: 'AzureMonitorWindowsAgent'
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
  }
}

// Deploy DependencyAgent extension
module DA 'VmExtension.bicep' = {
  name: '${VMName}-DependencyAgentWindows'
  params: {
    vmName: VMName
    VmExtensionName: 'DependencyAgentWindows'
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentWindows'
    Settings: {
      enableAMA: 'true'
    }
  }
}

resource DCE 'Microsoft.Insights/dataCollectionEndpoints@2023-03-11' = {
  name: 'DCE-${WorkspaceName}'
  location: location
  properties: {
    networkAcls:{
      publicNetworkAccess: 'Enabled'
    }
  }
}

resource DCR_VMInsights 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: 'DCR-VM-${WorkspaceName}'
  location: location
  properties: {
//    dataCollectionEndpointId: DCE.id
    dataSources: {
      performanceCounters: [
        {
          name: 'VMInsightsPerfCounters'
          streams: [
            'Microsoft-InsightsMetrics'
          ]
          samplingFrequencyInSeconds: 60
          counterSpecifiers:[
            '\\VmInsights\\DetailedMetrics'
          ]
        }
      ]
      extensions: [
        {
          name: 'DependencyAgentDataSource'
          streams: [
            'Microsoft-ServiceMap'
          ]
          extensionName: 'DependencyAgent'
          extensionSettings: {}

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
          'Microsoft-InsightsMetrics'
        ]
        destinations: [
          WorkspaceName
        ]
      }
      {
        streams: [
          'Microsoft-ServiceMap'
        ]
        destinations: [
          WorkspaceName
        ]
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
    dataCollectionRuleId: DCR_VMInsights.id
  }
}
