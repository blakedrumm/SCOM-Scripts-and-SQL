	<#
	.SYNOPSIS
		Test the ports SCOM Uses with Test-NetConnection Automatically.
	
	.DESCRIPTION
		This script tests the ports for SCOM.
	
	.PARAMETER Servers
		An array of Servers, or alternatively you can pipe in objects from Get-SCOMAgent or Get-SCOMManagementServer.
	
	.EXAMPLE
				PS C:\> Get-SCOMAgent | Where {$_.Name -match "IIS-server"} | .\Test-SCOMPorts
				PS C:\> Get-SCOMManagementServer | .\Test-SCOMPorts
				PS C:\> .\Test-SCOMPorts -Servers Agent1.contoso.com, SQL-Server.contoso.com
	
	.NOTES
		.AUTHOR
			Blake Drumm (v-bldrum@microsoft.com)
		.LAST MODIFIED
			06/10/2021
#>
param
(
	[Parameter(Mandatory = $false,
			   ValueFromPipeline = $true,
			   Position = 1)]
	[array]$Servers
)
$ports = @{
	"Management Server / Agent Port" = 5723;
	"Console Port" = 5724;
	"Connector Framework Source Port" = 51905;
	"ACS Forwarder Port" = 51909;
	"AEM Port" = 51906;
	"SQL Server (Default) Port" = 1433;
	"SSH Port" = 22;
	"WS-MAN Port" = 1270;
	"Web Console (HTTP) Port" = 80;
	"Web Console (HTTPS) Port" = 443;
	"SNMP (Get) Port" = 161;
	"SNMP (Trap) Port" = 162
}
if (!$Servers)
{
	$servers = $env:COMPUTERNAME
}
elseif ($Servers -match 'Microsoft.EnterpriseManagement.Administration.ManagementServer')
{
	$Servers = $Servers.DisplayName
}
elseif ($Servers -match 'Microsoft.EnterpriseManagement.Administration.AgentManagedComputer')
{
	$Servers = $Servers.DisplayName
}
foreach ($server in $Servers)
{
	if ($server -match $env:COMPUTERNAME)
	{
		Write-Host -ForegroundColor Yellow "Checking SCOM ports on computer: $env:COMPUTERNAME"
		
		
		ForEach ($port in $ports.GetEnumerator())
		{
			
			
			$nettest = Test-NetConnection -Computername $server -Port $port.Value -WarningAction SilentlyContinue
			
			Switch ($($nettest.TcpTestSucceeded))
			{
				
				True { Write-Host -Foregroundcolor Green "AVAILABLE - $($port.Name): $($port.Value)" }
				
				False { Write-Host -ForegroundColor Red "FAILED - $($port.Name): $($port.Value)" }
			}
			
		}
	}
	else
	{
		Invoke-Command -ComputerName $server -ScriptBlock {
			Write-Host -ForegroundColor Yellow "Checking SCOM ports on computer: $env:COMPUTERNAME"
			
			$ports = $using:ports
			
			
			ForEach ($port in $ports.GetEnumerator())
			{
				
				
				$nettest = Test-NetConnection -Computername $server -Port $port.Value -WarningAction SilentlyContinue
				
				Switch ($($nettest.TcpTestSucceeded))
				{
					
					True { Write-Host -Foregroundcolor Green "AVAILABLE - $($port.Name): $($port.Value)" }
					
					False { Write-Host -ForegroundColor Red "FAILED - $($port.Name): $($port.Value)" }
				}
				
			}
		}
	}
}
