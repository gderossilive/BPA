$dump = Get-Process | Select-Object Name, Id, CPU, StartTime, SI 
$Now=Get-Date
$numCores = (Get-WmiObject -Class Win32_ComputerSystem).NumberOfLogicalProcessors
$cpuUsage = @()
foreach ($process in $dump) {
    if ($process.Name -ne 'Idle') {
        $Interval=$Now-$process.StartTime
        $cpuUsage += [PSCustomObject]@{
            Name = $process.Name
            CPUUsagePercent = $process.CPU/$Interval.TotalSeconds/$numCores*100
        }
    }
}
$cpuUsage | Sort-Object CPUUsagePercent -Descending | Select -First 5 | ConvertTo-Json