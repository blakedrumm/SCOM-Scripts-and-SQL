# ===============================
# Author: Blake Drumm (blakedrumm@microsoft.com)
# Created: September 30th, 2022
# Modified: September 30th, 2022
# Script location: https://github.com/blakedrumm/SCOM-Scripts-and-SQL/blob/master/Powershell/Agents%20Failover/Set-AgentFailover.ps1
# ===============================

Import-Module OperationsManager

#===================================================================
#region Script Variables

#We will look for all Agents Managed by this Management Server.
$movefromManagementServer = Get-SCOMManagementServer -Name "<MoveFrom_MS>"

#Primary Management Server
$movetoPrimaryMgmtServer = Get-SCOMManagementServer -Name "<MoveToPrimary_MS>"

#Secondary Management Server
$movetoFailoverMgmtServer = Get-SCOMManagementServer -Name '<MoveToSecondary_MS>'

#Gather the System Center Agent Class so we can get the gray Agents:
$scomAgent = Get-SCOMClass | Where-Object{ $_.name -eq "Microsoft.SystemCenter.Agent" } | Get-SCOMClassInstance

#endregion Variables
#===================================================================

#===================================================================
#region MainScript
$i = 0
foreach ($agent in $scomAgent)
{
	$i++
	$i = $i
	
	$scomAgentDetails = Get-SCOMAgent -ManagementServer $movefromManagementServer | Where { $_.DisplayName -match $agent.DisplayName }
	if ($scomAgentDetails)
	{
		#Remove Failover Management Server
		Write-Output "($i/$($scomAgent.count)) $($agent.DisplayName) Removing Failover: $($movetoFailoverMgmtServer.DisplayName)`n`n"
		$scomAgentDetails | Set-SCOMParentManagementServer -FailoverServer $null | Out-Null
		#Set Primary Management Server
		Write-Output "             $($agent.DisplayName) Primary: $($movefromManagementServer.DisplayName) -> $($movetoPrimaryMgmtServer.DisplayName)"
		$scomAgentDetails | Set-SCOMParentManagementServer -PrimaryServer $movetoPrimaryMgmtServer | Out-Null
		#Set Secondary Management Server
		Write-Output "               $($agent.DisplayName) Failover: $($movetoFailoverMgmtServer.DisplayName)`n`n"
		$scomAgentDetails | Set-SCOMParentManagementServer -FailoverServer $movetoFailoverMgmtServer | Out-Null
	}
	else
	{
		Write-Verbose "Unable to locate any data."
	}
}
Write-Output "Script completed!"
#endregion MainScript
#===================================================================
