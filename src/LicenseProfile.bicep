param vmName string
param location string = resourceGroup().location

resource vm 'Microsoft.HybridCompute/machines@2024-11-10-preview' existing = {
  name: vmName
}

resource LP 'Microsoft.HybridCompute/machines/licenseProfiles@2024-07-10' = {
  name: 'default'
  parent: vm
  location: location
  properties: {
    softwareAssurance: {
      softwareAssuranceCustomer: true
    }
  }
}
