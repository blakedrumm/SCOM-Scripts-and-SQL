#Original Author: Rogério Barros
#Edited by: Blake Drumm (blakedrumm@microsoft.com)
$MSWatcherClass = get-scomclass -name "Microsoft.SystemCenter.ManagementServerWatcher"
$MSClass = get-scomclass -name "Microsoft.SystemCenter.ManagementServer"


$watchers = ($MSWatcherClass | Get-SCOMClassInstance).DisplayName
$MS = ($MSClass | Get-SCOMClassInstance).DisplayName

$OrphanedObjects = @()
$OrphanedWatchers = (Compare-Object $watchers $ms | ? { $_.SideIndicator -eq "<=" }).inputobject

foreach ($ow in $OrphanedWatchers)
{
	$OrphanedObjects += get-scomclassinstance -Class $MSWatcherClass | ? { $_.DisplayName -eq $ow }
}

$MG = Get-SCOMManagementGroup
$discdata = New-Object Microsoft.EnterpriseManagement.ConnectorFramework.IncrementalDiscoveryData
if ($OrphanedObjects)
{
	foreach ($obj in $OrphanedObjects)
	{
		Write-Host "Removing: $($obj.DiplayName)" -ForegroundColor Red
		$discdata.Remove($obj)
	}
	Write-Host "Committing Removal: $($obj.FullName)" -ForegroundColor Green
	$discdata.commit($mg)
}
else
{
	Write-Host "Did not find any orphaned Management Server objects" -ForegroundColor Magenta
}
