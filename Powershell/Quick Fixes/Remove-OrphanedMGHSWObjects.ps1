#Original Author: Rogério Barros
$MSWatcherClass = get-scomclass -name "Microsoft.SystemCenter.ManagementServerWatcher"
$MSClass =  get-scomclass -name "Microsoft.SystemCenter.ManagementServer"


$watchers = ($MSWatcherClass | Get-SCOMClassInstance).DisplayName
$MS = ($MSClass | Get-SCOMClassInstance).DisplayName

$OrphanedObjects = @()
$OrphanedWatchers = (Compare-Object $watchers $ms | ? {$_.SideIndicator -eq "<="}).inputobject

foreach ($ow in $OrphanedWatchers)
{
    $OrphanedObjects += get-scomclassinstance -Class $MSWatcherClass | ? {$_.DisplayName -eq $ow}
}

$MG = Get-SCOMManagementGroup
$discdata = New-Object Microsoft.EnterpriseManagement.ConnectorFramework.IncrementalDiscoveryData

foreach ($obj in $OrphanedObjects)
{
        Write-Host $obj.Name -ForegroundColor Red
	$discdata.Remove($obj)
}

$discdata.commit($mg)
