param
(
	[Parameter(Mandatory = $false,
			   Position = 1)]
	[String]$ManagementServer,
	[Parameter(Mandatory = $false,
			   Position = 2)]
	[String]$Discovery
)
try
{
	if (!$ManagementServer)
	{
		$ManagementServer = $env:COMPUTERNAME
	}
	if (!$Discovery)
	{
		return Write-Host "Missing the Display Name of the Discovery. (ex. Azure SQL*). Run this script like this:`n.\Start-SCOMDiscovery.ps1 -Discovery 'Azure SQL*'" -ForegroundColor Red
	}
	Import-Module OperationsManager
	$Task = Get-SCOMTask -Name Microsoft.SystemCenter.TriggerOnDemandDiscovery
	$Discoveries = Get-SCOMDiscovery -DisplayName $Discovery
	'Starting Discoveries (Count: ' + $Discoveries.Count + ')' | Write-Host
	$i = 0
	foreach ($Discov in $Discoveries)
	{
		$i = $i
		$i++
		'(' + $i + '/' + $Discoveries.Count + ') ---------------------------------------' | Write-Host
		$output = @()
		$Override = @{ DiscoveryId = $Discov.Id.ToString(); TargetInstanceId = $Discov.Target.Id.ToString() }
		$Instance = Get-SCOMClass -Name Microsoft.SystemCenter.ManagementServer | Get-SCOMClassInstance | where { $_.Displayname -like "$ManagementServer`*" }
		$output += (Start-SCOMTask -Task $Task -Instance $Instance -Override $Override | Select-Object Status, @{ Name = "Discovery"; Expression = { $Discov } }, TimeStarted, TimeScheduled, TimeFinished, Output) | Out-String -Width 4096
		$output
		$randomnumber = Get-Random -Minimum 3 -Maximum 10
		Start-Sleep -Seconds $randomnumber
	}
}
catch
{
	Write-Warning $_
	Write-Host "Unable to trigger the discovery" -ForegroundColor Red
}
break
