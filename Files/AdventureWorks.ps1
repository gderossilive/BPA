param(
    [string] $serverInstance,
    [string] $proxy
)

# Define variables
$backupFile = "C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\AdventureWorksLT2022.bak"
$databaseName = "AdventureWorks2022"

# Load the SQL Server module
Import-Module SQLPS -DisableNameChecking

# Create a new SMO Server object
$server = New-Object Microsoft.SqlServer.Management.Smo.Server $serverInstance

# Add NT AUTHORITY\SYSTEM to the sysadmin role
$login = $server.Logins["NT AUTHORITY\SYSTEM"]
if ($login -eq $null) {
    Write-Host "Login 'NT AUTHORITY\SYSTEM' does not exist."
} else {
    $login.AddToRole("sysadmin")
    Write-Host "Login 'NT AUTHORITY\SYSTEM' has been added to the sysadmin role."
}


try {
    if ($proxy) {
		Invoke-WebRequest -Proxy $proxy -Uri https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorksLT2022.bak -OutFile 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\AdventureWorksLT2022.bak'
	} else {
		Invoke-WebRequest -Uri https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorksLT2022.bak -OutFile 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\AdventureWorksLT2022.bak'
	}
}
catch {
    throw "Invoke-WebRequest failed: $_"
}


# Restore the database
Invoke-SqlCmd -ServerInstance $serverInstance -Query "RESTORE DATABASE [$databaseName] FROM DISK = N'$backupFile' WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 5" -Encrypt Optional

