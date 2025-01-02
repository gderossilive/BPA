param (
    # Domain admin credential (the local admin credential will be set to this one!)
    #! user user@domain.com for the user
    [Parameter(Mandatory )] [string]
    $username
    ,
    [Parameter(Mandatory )] [string]
    $password
    ,
    [Parameter(Mandatory )] [string]
    $serverName
)

$domainCred = new-object -typename System.Management.Automation.PSCredential `
         -argumentlist $username, $password

Install-Module -Name ActiveDirectoryDsc -Force

# note: These steps need to be performed in an Administrator PowerShell session
$cert = New-SelfSignedCertificate -Type DocumentEncryptionCertLegacyCsp -DnsName 'DscEncryptionCert' -HashAlgorithm SHA256
# export the private key certificate
$mypwd = ConvertTo-SecureString -String "!P@ssword1" -Force -AsPlainText
$cert | Export-PfxCertificate -FilePath "$env:temp\DscPrivateKey.pfx" -Password $mypwd -Force
# remove the private key certificate from the node but keep the public key certificate
$cert | Export-Certificate -FilePath "$env:temp\DscPublicKey.cer" -Force
$cert | Remove-Item -Force
Import-Certificate -FilePath "$env:temp\DscPublicKey.cer" -CertStoreLocation Cert:\LocalMachine\My

$ConfigData = @{
    AllNodes = @(
        @{
            # The name of the node we are describing
            NodeName        = $serverName

            # The path to the .cer file containing the
            # public key of the Encryption Certificate
            # used to encrypt credentials for this node
            CertificateFile = "$env:temp\DscPublicKey.cer"

            # The thumbprint of the Encryption Certificate
            # used to decrypt the credentials on target node
            Thumbprint      = $cert.Thumbprint
        }
    )
}

Configuration ADDomain_NewForest_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ActiveDirectoryDsc

    node $serverName
    {
        File exampleFile
        {
            SourcePath = "$env:temp\DscPublicKey.cer"
            DestinationPath = "$env:temp"
            Credential = $credential
        }
        LocalConfigurationManager
        {
             CertificateId = $node.Thumbprint
        }
        WindowsFeature 'ADDS'
        {
            Name   = 'AD-Domain-Services'
            Ensure = 'Present'
        }

        WindowsFeature 'RSAT'
        {
            Name   = 'RSAT-AD-PowerShell'
            Ensure = 'Present'
        }

        ADDomain 'contoso.com'
        {
            DomainName                    = 'contoso.com'
            Credential                    = $Credential
            SafemodeAdministratorPassword = $Credential
            ForestMode                    = 'WinThreshold'
        }
    }
}

Write-Host "Generate DSC Configuration..."
ADDomain_NewForest_Config -ConfigurationData $ConfigData .\ADDomain_NewForest_Config

Write-Host "Setting up LCM to decrypt credentials..."
Set-DscLocalConfigurationManager .\ADDomain_NewForest_Config -Verbose

Write-Host "Starting Configuration..."
Start-DscConfiguration -Path .\ADDomain_NewForest_Config -Wait -Verbose -Force

Restart-Computer -Force