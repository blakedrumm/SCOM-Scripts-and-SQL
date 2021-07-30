<#
	.SYNOPSIS
		Test the ports SCOM Uses with Test-NetConnection Automatically.
	
	.DESCRIPTION
		This script tests the ports for SCOM.
	
	.PARAMETER SourceServer
		A description of the SourceServer parameter.
	
	.PARAMETER DestinationServer
		A description of the DestinationServer parameter.
	
	.PARAMETER OutputFile
		A description of the OutputFile parameter.
	
	.PARAMETER OutputType
		A description of the OutputType parameter.
	
	.PARAMETER Servers
		An array of Servers, or alternatively you can pipe in objects from Get-SCOMAgent or Get-SCOMManagementServer.
	
	.EXAMPLE
		PS C:\> Get-SCOMAgent | Where {$_.Name -match "IIS-server"} | .\Test-SCOMPorts
		PS C:\> Get-SCOMManagementServer | .\Test-SCOMPorts
		PS C:\> .\Test-SCOMPorts -Servers Agent1.contoso.com, SQL-Server.contoso.com
	
	.NOTES
		.AUTHOR
		Blake Drumm (blakedrumm@microsoft.com)
		.LAST MODIFIED
		07/29/2021
		
		https://www.stefanroth.net/2013/10/08/powershell-4-0-checking-scom-required-ports/
#>
function Test-SCOMPorts
{
	param
	(
		[Parameter(Mandatory = $false,
				   Position = 1)]
		[array]$SourceServer,
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 2)]
		[array]$DestinationServer,
		[Parameter(Position = 3)]
		[string]$OutputFile,
		[Parameter(Position = 4)]
		[ValidateSet("Text", "CSV", "Table")]
		[string[]]$OutputType = 'Table'
	)
	if ($OutputFile)
	{
		if (!$OutputType)
		{
			$OutputType = 'Text'
		}
	}
	else
	{
		if ($OutputType -eq 'Text')
		{
			$OutputFile = "$PSScriptRoot`\SCOM-Port-Checker.txt"
		}
		elseif ($OutputType -eq 'CSV')
		{
			$OutputFile = "$PSScriptRoot`\SCOM-Port-Checker.csv"
		}
	}
	if (!$SourceServer)
	{
		$SourceServer = $env:COMPUTERNAME
	}
	elseif ($SourceServer -match 'Microsoft.EnterpriseManagement.Administration.ManagementServer')
	{
		$SourceServer = $SourceServer.DisplayName
	}
	elseif ($SourceServer -match 'Microsoft.EnterpriseManagement.Administration.AgentManagedComputer')
	{
		$SourceServer = $SourceServer.DisplayName
	}
	else
	{
		$SourceServer = $SourceServer
	}
	Write-Output " "
	Write-Output @"
================================
Starting SCOM Port Checker
"@
	function Check-SCOMPorts
	{
		param
		(
			[Parameter(Mandatory = $true,
					   Position = 0)]
			[array]$DestinationServer,
			[Parameter(Mandatory = $false,
					   Position = 1)]
			[array]$SourceServer
		)
		$payload = $null
		$payload = @()
		Write-Host "  Running from: " -NoNewLine
		Write-Host $env:COMPUTERNAME -ForegroundColor Cyan -NoNewLine
		$ports = @{
			"Management Server / Agent Port"   = 5723;
			"Web Console / Console Port"	   = 5724;
			"Connector Framework Source Port"  = 51905;
			"ACS Forwarder Port"			   = 51909;
			"AEM Port"						   = 51906;
			"SQL Server (Default) Port"	       = 1433;
			"SSH Port"						   = 22;
			"WS-MAN Port"					   = 1270;
			"Web Console (HTTP) Port"		   = 80;
			"Web Console (HTTPS) Port"		   = 443;
			"SNMP (Get) Port"				   = 161;
			"SNMP (Trap) Port"				   = 162
			
			"Remote Procedure Call (DCOM/RPC)" = 135;
			#"NetBIOS (Name Services UDP)"  = 137;
			#"NetBIOS (Datagram Services UDP)"  = 138;
			"NetBIOS (Session Services)"	   = 139;
			"SMB Over IP (Direct TCP/IP)"	   = 445;
			#"Private/Dynamic Range (Beginning)" = 49152;
			#"Private/Dynamic Range (Middle)" = 57343;
			#"Private/Dynamic Range (End)" = 65535;
		}
		foreach ($server in $DestinationServer)
		{
			ForEach ($port in $ports.GetEnumerator())
			{
				$tcp = $null
				$tcp = Test-NetConnection -Computername $server -Port $port.Value -WarningAction SilentlyContinue
				Write-Host '-' -ForegroundColor Green -NoNewline
				Switch ($($tcp.TcpTestSucceeded))
				{
					True { $payload += new-object psobject -property @{ Availability = 'Up'; 'Service Name' = $($port.Name); Port = $($port.Value); SourceServer = $env:COMPUTERNAME; DestinationServer = $server } }
					
					False { $payload += new-object psobject -property @{ Availability = 'Down'; 'Service Name' = $($port.Name); Port = $($port.Value); SourceServer = $env:COMPUTERNAME; DestinationServer = $server } }
				}
			}
			
		}
		Write-Host '> Complete!' -ForegroundColor Green
		return $payload
	}
	$sb = (get-item Function:Check-SCOMPorts).ScriptBlock
	foreach ($source in $SourceServer)
	{
		if ($source -match $env:COMPUTERNAME)
		{
			$scriptout += Check-SCOMPorts -SourceServer $source -DestinationServer $DestinationServer
		}
		else
		{
			$scriptout += Invoke-Command -ComputerName $source -ScriptBlock $sb -ArgumentList ( ,$DestinationServer)
		}
		
	}
	
	$finalout = $scriptout | select 'Service Name', SourceServer, Port, Availability, DestinationServer | Sort-Object -Property @{
		expression = 'SourceServer'
		descending = $false
	}, @{
		expression = 'DestinationServer'
		descending = $false
	}, @{
		expression = 'Port'
		descending = $false
	}
	if ($OutputType -eq 'CSV')
	{
		Write-Host "Output to " -NoNewline -ForegroundColor Gray
		Write-Host $OutputFile -NoNewline -ForegroundColor Cyan
		$finalout | Export-Csv -Path $OutputFile -NoTypeInformation
	}
	elseif ($OutputType -eq 'Text')
	{
		Write-Host "Output to " -NoNewline -ForegroundColor Gray
		Write-Host $OutputFile -NoNewline -ForegroundColor Cyan
		$finalout | ft * | Out-File $OutputFile
	}
	elseif ($OutputType -eq 'Table')
	{
		$finalout | ft *
	}
}
if ($SourceServer -or $DestinationServer -or $OutputFile -or $OutputType)
{
	Test-SCOMPorts -SourceServer $SourceServer -DestinationServer $DestinationServer -OutputFile $OutputFile -OutputType $OutputType
}
else
{
	#Enter the Server you want to check ports against here.
	# ex. Test-SCOMPorts -DestinationServer 'Agent1.contoso.com'
	Test-SCOMPorts
}
