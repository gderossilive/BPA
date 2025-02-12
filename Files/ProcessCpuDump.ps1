$dump = Get-Process | Select-Object Name, Id, CPU, StartTime 
$Now=Get-Date
$cpuUsage = @()
foreach ($process in $dump) {
    $Interval=$Now-$process.StartTime
    $cpuUsage += [PSCustomObject]@{
        Name = $process.Name
        CPUUsagePercent = $process.CPU/$Interval.TotalSeconds*100
    }
}
$cpuUsage | Sort-Object CPUUsagePercent -Descending | Select -First 5 | ConvertTo-Json