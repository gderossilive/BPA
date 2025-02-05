param WorkspaceName string
param location string
param Seed string
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

// Deploy assessmentplatform extension
module assessmentplatform 'VmExtension.bicep' = {
  name: '${VMName}-assessmentplatform'
  params: {
    vmName: VMName
    VmExtensionName: 'Aassessmentplatform'
    publisher: 'microsoft.serviceshub'
    type: 'assessmentplatform'
  }
}

// Deploy windowsserverassessment extension
module windowsserverassessment 'VmExtension.bicep' = {
  name: '${VMName}-windowsserverassessment'
  params: {
    vmName: VMName
    VmExtensionName: 'windowsserverassessment'
    publisher: 'microsoft.serviceshub'
    type: 'windowsserverassessment'
    Settings: {
      addTaskOnInstallRequested: true
      autoUpgradeMinorVersion: false
      isEnabled: true
      triggerServerName: VMName
      triggerLogAnalyticsWorkspaceFullId: LAW.id
      triggerLogAnalyticsWorkspaceId: LAW.properties.customerId
      triggerLogAnalyticsWorkspaceName: LAW.name
    }
  }
}

resource vm 'Microsoft.HybridCompute/machines@2024-11-10-preview' existing = {
  name: VMName
}

// Deploy DCR association
resource DCRA 'Microsoft.Insights/dataCollectionRuleAssociations@2023-03-11' = {
  dependsOn:[windowsserverassessment]
  name: 'windowsserver-dcr-assoc'
  properties: {
    dataCollectionRuleId: DCR_WinBPA.id
  }
  scope: vm
}

// Create a custom table in Log Analytics Workspace
resource WSAR 'Microsoft.OperationalInsights/workspaces/tables@2023-09-01' = {
  parent: LAW
  name: 'WindowsServerAssessmentRecommendation'
  properties: {
    schema: {
      name: 'WindowsServerAssessmentRecommendation'
    }
  }
}

// Deploy Data Collection Endpoint
resource DCE 'Microsoft.Insights/dataCollectionEndpoints@2023-03-11' = {
  name: 'oda-dcr-endpoint'
  location: location
  properties: {
    networkAcls: {
      publicNetworkAccess: 'Enabled'
    }
  }
}

// Deploy Data Collection Rule
resource DCR_WinBPA 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: 'windowsserver-dcr-rule'
  location: location
  kind: 'Windows'
  properties: {
    dataCollectionEndpointId: DCE.id
    streamDeclarations: {
      'Custom-ODAStream': {
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
                'Custom-ODAStream'
            ]
            filePatterns: [
                'C:\\ODA\\WindowsServerAssessment\\*.assessmentwindowsserverrecs'
            ]
            format: 'text'
            settings: {
                text: {
                    recordStartTimestampFormat: 'ISO 8601'
                }
            }
            name: 'myLogFileFormat-Windows'
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: LAW.id
          name: 'law-destination'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Custom-ODAStream'
        ]
        destinations: [
          'law-destination'
        ]
        transformKql: 'source | extend rowData = split(parse_json(RawData), "\t") | project SourceSystem = tostring(rowData[2]) , AssessmentId = toguid(rowData[3]), AssessmentName =\'WindowsServer\', RecommendationId = toguid(rowData[4]), Recommendation = tostring(rowData[5]), Description = tostring(rowData[6]), RecommendationResult = tostring(rowData[7]), TimeGenerated = todatetime(rowData[8]), FocusAreaId = toguid(rowData[9]), FocusArea = tostring(rowData[10]), ActionAreaId = toguid(rowData[11]), ActionArea = tostring(rowData[12]), RecommendationScore = toreal(rowData[13]), RecommendationWeight = toreal(rowData[14]), Computer = tostring(rowData[18]) , AffectedObjectType = tostring(rowData[20]), AffectedObjectName = tostring(rowData[22]), AffectedObjectUniqueName = tostring(rowData[23]), AffectedObjectDetails = tostring(rowData[25]) , Domain = tostring(rowData[28]) , Server = tostring(rowData[29]) , Ipv4Address = tostring(rowData[31]) , OSVersion = tostring(rowData[30]) , WebServer = tostring(rowData[32]) , WebSite = tostring(rowData[33]) , IISApplication = tostring(rowData[34]) , IISApplicationPool = tostring(rowData[35]) , Technology = tostring(rowData[42]) , CustomData = tostring(rowData[26])'
        outputStream: 'Microsoft-WindowsServerAssessmentRecommendation'
      }
    ]
  }
}
