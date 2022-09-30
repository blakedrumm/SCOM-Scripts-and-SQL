# ===============================
# Author: Blake Drumm (blakedrumm@microsoft.com)
# Created: September 30th, 2022
# Modified: September 30th, 2022
# Script location: https://github.com/blakedrumm/SCOM-Scripts-and-SQL/blob/master/Powershell/Agents%20Failover/Check-AgentFailover.ps1
# ===============================

# ===============================
#region Script Start
Import-Module OperationsManager;
$agents = Get-SCOMAgent
# ===============================

# ===============================
#region Initiate Variables
$primaryOutput = @()
$i = 0
#endregion Initiate Variables
#endregion ScriptStart
# ===============================

# ===============================
#region Main Script
ForEach ($agent in $agents)
{
	$i++
	$i = $i
	Write-Progress -Activity 'Running' -Status 'Script is executing' -PercentComplete $($i/$agents.count * 100)
	Write-Output "($i / $($agents.count)) $($agent.DisplayName)"
	$output = [pscustomobject]@{ }
	$output | Add-Member -MemberType NoteProperty -Name 'Server Agent' -Value $agent.DisplayName -ErrorAction SilentlyContinue
	
	If (($agent.GetPrimaryManagementServer()).IsGateway -eq $true)
	{
		$output | Add-Member -MemberType NoteProperty -Name 'Primary Management Server [Gateway]' -Value ($agent.GetPrimaryManagementServer()).DisplayName -ErrorAction SilentlyContinue
		$output | Add-Member -MemberType NoteProperty -Name 'Primary Management Server [Management Server]' -Value $null -ErrorAction SilentlyContinue
	}
	else
	{
		$output | Add-Member -MemberType NoteProperty -Name 'Primary Management Server [Management Server]' -Value ($agent.GetPrimaryManagementServer()).DisplayName -ErrorAction SilentlyContinue
		$output | Add-Member -MemberType NoteProperty -Name 'Primary Management Server [Gateway]' -Value $null -ErrorAction SilentlyContinue
	};
	
	$output | Add-Member -MemberType NoteProperty -Name 'Failover Management Server' -Value $(($agent.GetFailoverManagementServers()).DisplayName -join ", ") -ErrorAction SilentlyContinue
	$primaryOutput += $output
	sleep 2
};
#endregion Main Script
# ===============================

# ===============================
#region Output
# Output to a table
$primaryOutput | ft *
# Output to a csv file in C:\Temp\
$primaryOutput | Export-Csv -Path C:\Temp\AgentList_of_Primary_and_Failover.csv -NoTypeInformation
#endregion Output
# ===============================
