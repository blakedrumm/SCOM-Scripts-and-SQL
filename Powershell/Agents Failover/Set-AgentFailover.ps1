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
$movefromManagementServer = Get-SCOMManagementServer -Name "MS01-2019*"

#Primary Management Server
$movetoPrimaryMgmtServer = Get-SCOMManagementServer -Name "MS02-2019*"

#Secondary Management Server
$movetoFailoverMgmtServer = Get-SCOMManagementServer -Name '<MoveToSecondary_MS>'

#Gather the System Center Agent Class so we can get the Agents:
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
	
	#Check the name of the current
	$scomAgentDetails = Get-SCOMAgent -ManagementServer $movefromManagementServer | Where { $_.DisplayName -match $agent.DisplayName }
	if ($scomAgentDetails)
	{
		#Remove Failover Management Server
		Write-Output "($i/$($scomAgent.count)) $($agent.DisplayName)`n`t`tRemoving Failover"
		$scomAgentDetails | Set-SCOMParentManagementServer -FailoverServer $null | Out-Null
		#Set Primary Management Server
		Write-Output "`t`tCurrent Primary: $($movefromManagementServer.DisplayName)`n`t`tUpdating Primary to: $($movetoPrimaryMgmtServer.DisplayName)"
		$scomAgentDetails | Set-SCOMParentManagementServer -PrimaryServer $movetoPrimaryMgmtServer | Out-Null
		if ($movetoFailoverMgmtServer -and $movetoFailoverMgmtServer -ne '<MoveToSecondary_MS>')
		{
			#Set Secondary Management Server
			Write-Output "               $($agent.DisplayName) Failover: $($movetoFailoverMgmtServer.DisplayName)`n`n"
			$scomAgentDetails | Set-SCOMParentManagementServer -FailoverServer $movetoFailoverMgmtServer | Out-Null
		}
	}
	else
	{
		Write-Verbose "Unable to locate any data."
	}
}
Write-Output "Script completed!"
#endregion MainScript
#===================================================================