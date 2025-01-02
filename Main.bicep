targetScope='subscription'
// General
param location string 
param Seed string
param MyObjectId string
@secure()
param adminPassword string
param adminUsername string = 'gdradmin'

// Resource Group
param HubRgName string = '${Seed}-Demo'

// Virtual Network
param HubVnetName string = 'VNet-${Seed}'
param HubVnetAddressPrefix string 
param PEsubnetName string = 'PE-Subnet'
param PEsubnetAddressPrefix string
param DMZsubnetName string = 'DMZ-Subnet'
param DMZsubnetAddressPrefix string
param BastionSubnetAddressPrefix string
param FirewallSubnetAddressPrefix string
param FirewallManagementSubnetAddressPrefix string
param GatewaySubnetAddressPrefix string
param BastionHostName string = 'Bastion-${Seed}'
param BastionPublicIpName string = 'BastionPublicIp-${Seed}'

// Virtual Machines
param WinNum int = 0
param SQLNum int = 0
param rnd string = substring(uniqueString(utcNow()),0,5)
param vmsize string = 'Standard_D2s_v3'

param WorskspaceName string = 'LA-${Seed}'
param publicNetworkAccess string = 'Enabled'

param KVname string = 'KV-${Seed}'
param customTableName string = 'GcAgent_CL'
param DCEname string = 'DCE-${Seed}'
//param SSHPublickey string


// Hub Resource Group Deploy
resource HubRG 'Microsoft.Resources/resourceGroups@2021-01-01' existing = {
  name: HubRgName
}

// Hub Virtual Network Deploy
module HubDeploy './src/HubDeploy.bicep' = {
  name: 'HubVnet'
  scope: HubRG
  params: {
    location: location
    Seed: Seed
    MyObjectId: MyObjectId
    adminPassword: adminPassword
    HubVnetName: HubVnetName
    BastionSubnetAddressPrefix: BastionSubnetAddressPrefix
    FirewallSubnetAddressPrefix: FirewallSubnetAddressPrefix
    FirewallManagementSubnetAddressPrefix: FirewallManagementSubnetAddressPrefix
    GatewaySubnetAddressPrefix: GatewaySubnetAddressPrefix
    HubVnetAddressPrefix: HubVnetAddressPrefix
    PEsubnetAddressPrefix: PEsubnetAddressPrefix
    PEsubnetName: PEsubnetName
    DMZsubnetAddressPrefix: DMZsubnetAddressPrefix
    DMZsubnetName: DMZsubnetName
    BastionHostName: BastionHostName
    BastionPublicIpName: BastionPublicIpName
  }
 }

 module LAW './src/LAworkspace.bicep' ={
  dependsOn: [HubDeploy]
  name: WorskspaceName
  scope: HubRG
  params: {
    WorkspaceName: WorskspaceName
    publicNetworkAccess : publicNetworkAccess
  }
}
 
module SqlVM 'src/WindowsVM.bicep' = [for i in range(1, SQLNum): {
  dependsOn: [HubDeploy]
  name: 'SQL-${Seed}-${rnd}-${i}'
  scope: HubRG
  params: {
    vmName: 'SQL-${i}'
    adminUsername: adminUsername
    adminPassword: adminPassword   
    virtualNetworkName: HubVnetName
    subnetName: DMZsubnetName
    location: location
    vmSize: vmsize
    OSVersion: '2022-Datacenter'
  }
}]

module SrvVM 'src/WindowsVM.bicep' = [for i in range(1, WinNum): {
  dependsOn: [HubDeploy]
  name: 'SRV-${Seed}-${rnd}-${i}'
  scope: HubRG
  params: {
    vmName: 'Srv-${i}'
    adminUsername: adminUsername
    adminPassword: adminPassword   
    virtualNetworkName: HubVnetName
    subnetName: DMZsubnetName
    location: location
    vmSize: vmsize
    OSVersion: '2025-Datacenter'
  }
}]

/*
// Workspace Custom Table
module LAW_Table './src/Law_Custom_Table.bicep' = {
  dependsOn: [
    LAW
  ]
  scope: HubRG
  name: 'LAW_Table-${Seed}'
  params: {
    LAW_Name: WorskspaceName
    TableName: customTableName
    columns: [
      {
        name: 'TimeGenerated'
        type: 'DateTime'
      }
      {
        name: 'RawData'
        type: 'String'
      }
    ]
  }
}

// Data Collection Endpoint
module DCE './src/DCE.bicep' = {
  name: DCEname
  scope: HubRG
  params: {
    Seed: Seed
    location: location
  }
}

// Data Collection Rule
module DCR_SqlBPA './src/DCR.bicep' = {
  dependsOn: [DCE]
  name: 'DCR-${Seed}'
  scope: HubRG
  params: {
    Seed: Seed
    customTableName: 'SqlAssessment_CL'
    filePattern: 'C:\\Windows\\System32\\config\\systemprofile\\AppData\\Local\\Microsoft SQL Server Extension Agent\\Assessment\\*.csv'
    WorkspaceName: WorskspaceName
    DceName: DCEname
  }
}*/


output SqlVMsName array = [for i in range(0,SQLNum):{
  name: SqlVM[i].outputs.hostname
}]

output SrvVMsName array = [for i in range(0,WinNum):{
  name: SrvVM[i].outputs.hostname
}]
output HubVnetName string = HubVnetName
output PEsubnetName string = PEsubnetName
output KvName string =  KVname
output laWname string = WorskspaceName
