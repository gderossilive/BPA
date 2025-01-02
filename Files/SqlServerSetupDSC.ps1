Install-Module -Name SqlServerDsc -Force
Install-Module sqlserver -Force

Configuration SQLServerSetup {
    param (
        [string]$SourcePath = "C:\SQL2022"
    )

    Import-DscResource -ModuleName SqlServerDsc
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    Node localhost {
        SqlSetup 'InstallDefaultInstance' {
            InstanceName = "MSSQLSERVER"
            SourcePath = $SourcePath
            Features = 'SQLENGINE'
            SQLSysAdminAccounts = 'gdradmin'
            InstallSharedDir = 'C:\\Program Files\\Microsoft SQL Server'
            InstallSharedWOWDir = 'C:\\Program Files (x86)\\Microsoft SQL Server'
            InstanceDir = 'C:\\Program Files\\Microsoft SQL Server'
        }

        SqlProtocol 'EnableTcpIp' {
            InstanceName = "MSSQLSERVER"
            ProtocolName = 'TcpIp'
            Enabled = $true
            DependsOn = "[SqlSetup]InstallDefaultInstance"
        }

        Service 'SQLServerService' {
            Name = "MSSQLSERVER"
            Ensure = "Present"
            State = "Running"
            DependsOn = "[SqlProtocol]EnableTcpIp"
        }

        Service 'EnsureSQLBrowserRunning' {
            Name = "SQLBrowser"
            Ensure = 'Present'
            State = 'Running'
            StartupType = 'Automatic'
            DependsOn = "[SqlSetup]InstallDefaultInstance"
        }
    }
}

SQLServerSetup
Start-DscConfiguration -Path .\SQLServerSetup -Wait -Verbose -Force