param vmName string
param publisher string 
param type string 

resource VmExtension 'Microsoft.HybridCompute/machines/extensions@2024-09-10-preview' = {
  name:  '${vmName}/VmExtension'
  properties: {
    publisher: publisher
    type: type
    autoUpgradeMinorVersion: true
    settings: {
    }
    protectedSettings: {
    }
  }
}
  