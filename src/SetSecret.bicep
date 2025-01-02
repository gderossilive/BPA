targetScope = 'resourceGroup'

param SecretName string
param KVname string
@secure()
param Secret string

resource KV 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: KVname
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' =  {
  dependsOn: [
    KV
  ] 
  name: '${KVname}/${SecretName}'
  properties: {
    value: Secret
  }
}
