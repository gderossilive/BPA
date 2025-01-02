param location string = resourceGroup().location
param Seed string
param customTableName string
param filePattern string
param WorkspaceName string
param DceName string

resource DCE 'Microsoft.Insights/dataCollectionEndpoints@2023-03-11' existing = {
  name: DceName
 }

 resource LAW 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: WorkspaceName
}

resource DCR_SqlBPA 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: 'sql-bpa-dcr-${Seed}'
  location: location
  properties: {
    dataCollectionEndpointId: DCE.id
    streamDeclarations: {
      SqlAssessment_CL: {
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
            customTableName
          ]
          filePatterns: [
            filePattern
          ]
          format: 'text'
          settings: {
            text: {
              recordStartTimestampFormat: 'ISO 8601'
            }
          }
          name: customTableName
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
          customTableName
        ]
        destinations: [
          WorkspaceName
        ]
        transformKql: 'source'
        outputStream: customTableName
      }
    ]
  }
}

output DCR_SqlBPA_id string = DCR_SqlBPA.id
