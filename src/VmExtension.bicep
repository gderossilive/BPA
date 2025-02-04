param vmName string
param VmExtensionName string = 'VmExtension' 
param publisher string 
param type string 
param location string = resourceGroup().location
param Settings object = {}

resource VmExtension 'Microsoft.HybridCompute/machines/extensions@2024-07-10' = {
  name:  '${vmName}/${VmExtensionName}'
  location: location
  properties: {
    publisher: publisher
    type: type
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: Settings
  }
}
  