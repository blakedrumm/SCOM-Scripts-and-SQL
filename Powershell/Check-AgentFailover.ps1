Param ([string]$parameter)

# Author: Blake Drumm (blakedrumm@microsoft.com)

Import-Module OperationsManager;

$ErrorActionPreference = "silentlycontinue";
$output = [pscustomobject]@{ }

If (!($parameter -eq "")) { $agents = Get-SCOMAgent $parameter }
else { $agents = Get-SCOMAgent };

$i = 0
ForEach ($agent in $agents)
{
	$i++
	$i = $i
	Write-Output "($i / $($agents.count)) $($agent.DisplayName)"
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
	
	$failover = $agent.GetFailoverManagementServers();
	
	$output | Add-Member -MemberType NoteProperty -Name 'Failover Management Server' -Value $failover -ErrorAction SilentlyContinue
	
};
$output | ft *
$output | Export-Csv -Path C:\Temp\AgentList_of_Primary_and_Failover.csv -NoTypeInformation
