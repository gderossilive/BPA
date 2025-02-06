param(
    [string] $serverInstance,
    [string] $proxy
)

# Define variables
$backupFile = "C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\AdventureWorksLT2022.bak"
$databaseName = "AdventureWorks2022"


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

