param (
    # Domain admin credential (the local admin credential will be set to this one!)
    #! user user@domain.com for the user
    [Parameter(Mandatory )] [ValidateNotNullOrEmpty()][int]
    $interval
)
#$interval=30
$initial = Get-Process | Sort-Object CPU -Descending | Select-Object Name, CPU -First 5 
Start-Sleep -Seconds $interval
$final = Get-Process | Sort-Object CPU -Descending | Select-Object Name, CPU -First 5
$cpuUsage = @()
foreach ($process in $initial) {
    $finalProcess = $final | Where-Object { $_.Name -eq $process.Name }
    if ($finalProcess) {
        $cpuDiff = $finalProcess.CPU - $process.CPU
        $cpuUsage += [PSCustomObject]@{
            Name = $process.Name
            CPUUsagePercent = ($cpuDiff / $interval) * 100
        }
    }
}
$cpuUsage | Sort-Object CPUUsagePercent -Descending | ConvertTo-Json