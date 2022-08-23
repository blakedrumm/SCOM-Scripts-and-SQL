#Author: Blake Drumm (blakedrumm@microsoft.com)

#We will look for all Agents Managed by this Management Server.
$movefromManagementServer = Get-SCOMManagementServer -Name "MS01-2019.contoso.com"
#Primary Management Server
$movetoPrimaryMgmtServer = Get-SCOMManagementServer -Name "MS03-2019.contoso.com"
#Secondary Management Server
$movetoFailoverMgmtServer = Get-SCOMManagementServer -Name "MS02-2019.contoso.com"
#get the SystemCenter Agent Class
$scomAgent = Get-SCOMClass | Where-Object{ $_.name -eq "Microsoft.SystemCenter.Agent" } | Get-SCOMClassInstance | where { $_.IsAvailable -eq $false }
#Set Primary Management Server
foreach ($agent in $scomAgent)
{
	$scomAgentDetails = Get-SCOMAgent -ManagementServer $movefromManagementServer | Where { $_.DisplayName -match $agent.DisplayName }
	if ($scomAgentDetails)
	{
		Write-Output "$($agent.DisplayName) Primary: $($movefromManagementServer.DisplayName) -> $($movetoPrimaryMgmtServer.DisplayName)"
		$scomAgentDetails | Set-SCOMParentManagementServer -PrimaryServer $movetoPrimaryMgmtServer | Out-Null
		Write-Output "$($agent.DisplayName) Failover: $($movetoFailoverMgmtServer.DisplayName)`n`n"
		#Set Secondary Management Server
		$scomAgentDetails | Set-SCOMParentManagementServer -FailoverServer $movetoFailoverMgmtServer | Out-Null
	}
	else
	{
		Write-Output "Unable to locate any data."
	}
}
