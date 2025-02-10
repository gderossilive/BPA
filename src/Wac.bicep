param VMName string
param wacPort string = '6516'


// Deploy WAC extension
module WAC 'VmExtension.bicep' = {
  name: '${VMName}-WindowsAdminCenter'
  params: {
    vmName: VMName
    VmExtensionName: 'AdminCenter'
    publisher: 'Microsoft.AdminCenter'
    type: 'AdminCenter'
    Settings: {
      port: wacPort
      proxy: {
        mode: 'none'
      }
    }
  }
}
