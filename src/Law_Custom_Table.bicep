param LAW_Name string
param TableName string
param columns array 

resource LAW 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: LAW_Name
}

resource LAW_Table 'Microsoft.OperationalInsights/workspaces/tables@2023-09-01' = {
  parent: LAW
  name: TableName
  properties: {
    retentionInDays: 30
    plan: 'Analytics'
    schema: {
      name: TableName
      columns: columns
    }
  }
}
