param WorkspaceName string
param location string
param VMName string
param DceName string = 'sql-bpa-dcr-dce'
param DcrName string = 'sql-bpa-dcr'

resource LAW 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: WorkspaceName
}

/* Create a custom table in Log Analytics Workspace
resource SqlTable 'Microsoft.OperationalInsights/workspaces/tables@2023-09-01' = {
  parent: LAW
  name: 'SqlAssessment_CL'
  properties: {
    schema: {
      name: 'SqlAssessment_CL'
      columns: [
        {
          name: 'TimeGenerated'
          type: 'datetime'
        }
        {
          name: 'RawData'
          type: 'string'
        }
      ]
    }
  }
}*/

module SqlExtension 'VmExtension.bicep' = {
  name: '${VMName}-WindowsAgent.SqlServer'
  params: {
    vmName: VMName
    VmExtensionName: 'WindowsAgent.SqlServer'
    publisher: 'Microsoft.AzureData'
    type: 'WindowsAgent.SqlServer'
    Settings: {
      SqlManagement: {
        IsEnabled: true
      }
      LicenseType: 'PAYG'
      ExcludedSqlInstances: [
        ''
      ]
      AssessmentSettings: {
        IsEnabled: true
        RunImmediately: true
        WorkspaceResourceId: LAW.id
        WorkspaceLocation: location
      }
    }
  }
}

resource DCE 'Microsoft.Insights/dataCollectionEndpoints@2023-03-11' = {
  name: DceName
  location: location
  properties: {
    networkAcls:{
      publicNetworkAccess: 'Enabled'
    }
  }
}

resource DCR_SqlBPA 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: DcrName
  location: location
  properties: {
    dataCollectionEndpointId: DCE.id
    streamDeclarations: {
      'Custom-SqlAssessment_CL': {
        columns: [
          {
            name: 'TimeGenerated'
            type: 'datetime'
          }
          {
            name: 'RawData'
            type: 'string'
          }
        ]
      }
    }
    dataSources: {
      logFiles: [
        {
          streams: [
            'Custom-SqlAssessment_CL'
          ]
          filePatterns: [
            'C:\\Windows\\System32\\config\\systemprofile\\AppData\\Local\\Microsoft SQL Server Extension Agent\\Assessment\\*.csv'
          ]
          format: 'text'
          settings: {
            text: {
              recordStartTimestampFormat: 'ISO 8601'
            }
          }
          name: 'SqlAssessment_CL'
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
          'Custom-SqlAssessment_CL'
        ]
        destinations: [
          WorkspaceName
        ]
        transformKql: 'source'
        outputStream: 'Custom-SqlAssessment_CL'
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
    dataCollectionRuleId: DCR_SqlBPA.id
  }
}
