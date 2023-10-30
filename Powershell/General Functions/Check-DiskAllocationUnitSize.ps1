# Author: Blake Drumm (blakedrumm@microsoft.com)

# Query the Win32_Volume class to get disk information
$disks = Get-WmiObject -Query "SELECT * FROM Win32_Volume"

# Loop through each disk and display its allocation unit size in KB
foreach ($disk in $disks) {
    $driveLetter = $disk.Name
    $diskLabel = $disk.Label
    $allocationUnitSizeBytes = $disk.BlockSize
    $allocationUnitSizeKB = $allocationUnitSizeBytes / 1024
    Write-Host "Drive $driveLetter $(if($diskLabel){"($diskLabel) "}else{Out-Null})- Allocation Unit Size: $allocationUnitSizeKB KB"
}
