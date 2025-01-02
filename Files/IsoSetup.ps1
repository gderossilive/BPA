param(
    [string] $servicePrincipalClientId,
    [string] $servicePrincipalSecret,
    [string] $TenantId,
    [string] $StorageAccountName,
    [string] $ContainerName,
    [string] $BlobName
)

Write-Host "Installing necessary packages..." -ForegroundColor Green
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name SqlServerDsc -Force
Install-Module sqlserver -Force
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri "https://aka.ms/downloadazcopy-v10-windows" -OutFile "D:\azcopy.zip"
Expand-Archive -Path "D:\azcopy.zip" -DestinationPath "D:\"
Copy-Item -Path "D:\azcopy_windows_amd64_10.27.1\azcopy.exe" -Destination "C:\Windows\System32\"



Write-Host "Getting access token..." -ForegroundColor Green
$Resource="https://$StorageAccountName.blob.core.windows.net"
# Get the access token
$Body = @{
    grant_type    = "client_credentials"
    client_id     = $servicePrincipalClientId
    client_secret = $servicePrincipalSecret
    resource      = $Resource
}
$TokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/token" -ContentType "application/x-www-form-urlencoded" -Body $Body
$AccessToken = $TokenResponse.access_token

# Set up headers
$Headers = @{
    "Authorization" = "Bearer $AccessToken"
    "x-ms-version"  = "2020-08-04"
}

Write-Host "Downloading SQL Server ISO..." -ForegroundColor Green
# Download the SQL Server ISO via azcopy
azcopy login --identity 
azcopy copy "https://$StorageAccountName.blob.core.windows.net/$ContainerName/$BlobName" "D:\SQLServer2022-x64-ENU.iso"

Write-Host "Copying SQL Server ISO content to C:\SQL2022..." -ForegroundColor Green
# Copy the ISO content to C:\SQL2022
New-Item -Path C:\SQL2022 -ItemType Directory
$mountResult = Mount-DiskImage -ImagePath 'D:\SQLServer2022-x64-ENU.iso' -PassThru
$volumeInfo = $mountResult | Get-Volume
$driveInfo = Get-PSDrive -Name $volumeInfo.DriveLetter
Copy-Item -Path ( Join-Path -Path $driveInfo.Root -ChildPath '*' ) -Destination 'C:\SQL2022\' -Recurse -Force
Write-Host "unmounting the ISO..." -ForegroundColor Green
Dismount-DiskImage -ImagePath 'D:\SQLServer2022-x64-ENU.iso'
Write-Host "Done." -ForegroundColor Green