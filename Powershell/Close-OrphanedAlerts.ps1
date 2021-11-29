Import-Module OperationsManager
#Author: Brook Hudson (brook.hudson@microsoft.com) / Udish Mudiar (udishman.mudiar@microsoft.com)

#Getting list of all the Open alerts raised from monitors.
$openalertsfrommonitors=Get-SCOMAlert -Criteria "ResolutionState = 0 AND IsMonitorAlert = 1"

$alertname=@()
foreach($alert in $openalertsfrommonitors)
    {
    $objectID=$alert.MonitoringObjectId.Guid
    $classID=$alert.MonitoringClassId.Guid

    #Get the instance for which the alert is generated
    $instance=Get-SCOMClassInstance -Id $objectID

    #Get the monitor for which alert is generated
    $monitor=Get-SCOMMonitor -id $alert.MonitoringRuleId

    #Set the monitor collection to empty and create the collection to contain monitors
    $MonitorColl = @()
    $MonitorColl = New-Object "System.Collections.Generic.List[Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitor]"
 
    #Add this monitor to a collection
    $MonitorColl.Add($Monitor)

    #Get the state associated with this specific monitor
    $State=$instance.getmonitoringstates($MonitorColl)

    #$state

    if($state.healthstate -eq "Success" )
        {
        $alertname+=$alert
        }
    }

Write-host "Below alerts count and details which are open for which the monitor is healthy `n" -ForegroundColor Cyan
"Count:" + $alertname.count
$alertname

Write-Host " "
Write-Host "Output file to $env:USERPROFILE\Desktop\falsepostivealerts.txt" -ForegroundColor Gray
$alertname | Out-File $env:USERPROFILE\Desktop\falsepostivealerts.txt

$input=Read-Host "`nDo you want to close all the alerts in the above list? (Y/N)"

if($input -eq "Y")
    {
    Write-host "`nClosing the alerts from the above list" -ForegroundColor Cyan
    foreach($alert in $alertname)
        {
        Get-SCOMAlert -id $alert.Id | Set-SCOMAlert -ResolutionState 255 -Comment "Closing the alert via a script because the object state is already healthy"
        }
    }
else
    {
    Write-host "`nNot closing the alerts" -ForegroundColor Cyan
    }
