<#
	.SYNOPSIS
		Clear-SCOMCache
	
	.DESCRIPTION
		The script without any modifications clears the SCOM cache only on the local server, nothing else.

	.PARAMETER All
		Optionally clear all caches that SCOM could potentially use that doesn't require a reboot. Flushing DNS, Purging Kerberos Tickets, Resetting NetBIOS over TCPIP Statistics. (Combine with -Reboot for a full clear cache)
	
	.PARAMETER Reboot
		Optionally reset winsock catalog, stop the SCOM Services, clear SCOM Cache, then reboot the server. This will always perform on the local server last.

	.PARAMETER Servers
		Each Server you want to clear SCOM Cache on. Can be an Agent, Management Server, or SCOM Gateway. This will always perform on the local server last.

	.PARAMETER Shutdown
		Optionally shutdown the server after clearing the SCOM cache. This will always perform on the local server last.

	.PARAMETER Sleep
		Time in seconds to sleep between each server.	

	
	.EXAMPLE
		Clear all Gray SCOM Agents
		PS C:\> #Get the SystemCenter Agent Class
		PS C:\>	$agent = Get-SCOMClass | where-object{$_.name -eq "microsoft.systemcenter.agent"}
		PS C:\>	#Get the grey agents
		PS C:\>	$objects = Get-SCOMMonitoringObject -class:$agent | where {$_.IsAvailable -eq $false}
		PS C:\>	.\Clear-SCOMCache.ps1 -Servers $objects
		
		Clear SCOM cache on every Management Server in Management Group.
		PS C:\> Get-SCOMManagementServer | .\Clear-SCOMCache.ps1
		
		Clear SCOM cache on every Agent in the in Management Group.
		PS C:\> Get-SCOMAgent | .\Clear-SCOMCache.ps1
		
		Clear SCOM cache and reboot the Servers specified.
		PS C:\> .\Clear-SCOMCache.ps1 -Servers AgentServer.contoso.com, ManagementServer.contoso.com -Reboot

		Clear SCOM cache and shutdown the Servers specified.
		PS C:\> .\Clear-SCOMCache.ps1 -Servers AgentServer.contoso.com, ManagementServer.contoso.com -Shutdown
	
	.NOTES
		For advanced users: Edit line 723 to modify the default command run when this script is executed.

		Originally hosted on my github:
		https://github.com/blakedrumm/SCOM-Scripts-and-SQL/blob/master/Powershell/Clear-SCOMCache.ps1
		
		Blog Post: https://blakedrumm.com/blog/clear-scomcache/

		.AUTHOR
		Blake Drumm (blakedrumm@microsoft.com)
		
		.MODIFIED
		April 26th, 2022
#>
[OutputType([string])]
param
(
	[Parameter(Mandatory = $false,
			   Position = 1,
			   HelpMessage = 'Optionally clear all caches that SCOM could potentially use that doesnt require a reboot. Flushing DNS, Purging Kerberos Tickets, Resetting NetBIOS over TCPIP Statistics. (Combine with -Reboot for a full clear cache)')]
	[Switch]$All,
	[Parameter(Mandatory = $false,
			   Position = 2,
			   HelpMessage = 'Optionally reset winsock catalog, stop the SCOM Services, clear SCOM Cache, then reboot the server. This will always perform on the local server last.')]
	[Switch]$Reboot,
	[Parameter(Mandatory = $false,
			   ValueFromPipeline = $true,
			   Position = 3,
			   HelpMessage = 'Each Server you want to clear SCOM Cache on. Can be an Agent, Management Server, or SCOM Gateway. This will always perform on the local server last.')]
	[String[]]$Servers,
	[Parameter(Mandatory = $false,
			   Position = 4,
			   HelpMessage = 'Optionally shutdown the server after clearing the SCOM cache. This will always perform on the local server last.')]
	[Switch]$Shutdown,
	[Parameter(Position = 5,
			   HelpMessage = 'Time in seconds to sleep between each server.')]
	[int64]$Sleep
)
BEGIN
{
	Write-Output '
===================================================================
==========================  Start of Script =======================
==================================================================='

	Function Get-TimeStamp
	{
		$TimeStamp = (Get-Date).DateTime
		return "$TimeStamp - "
	}
}
PROCESS
{
	$setdefault = $false
	foreach ($Server in $input)
	{
		if ($Server)
		{
			if ($Server.GetType().Name -eq 'ManagementServer')
			{
				if (!$setdefault)
				{
					$Servers = @()
					$setdefault = $true
				}
				$Servers += $Server.DisplayName
			}
			elseif ($Server.GetType().Name -eq 'AgentManagedComputer')
			{
				if (!$setdefault)
				{
					$Servers = @()
					$setdefault = $true
				}
				$Servers += $Server.DisplayName
			}
			elseif ($Server.GetType().Name -eq 'MonitoringObject')
			{
				if (!$setdefault)
				{
					$Servers = @()
					$setdefault = $true
				}
				$Servers += $Server.DisplayName
			}
		}
	}
	Function Clear-SCOMCache
	{
		[OutputType([string])]
		param
		(
			[Parameter(Mandatory = $false,
					   Position = 1,
					   HelpMessage = 'Optionally clear all caches that SCOM could potentially use that doesnt require a reboot. Flushing DNS, Purging Kerberos Tickets, Resetting NetBIOS over TCPIP Statistics. (Combine with -Reboot for a full clear cache)')]
			[Switch]$All,
			[Parameter(Mandatory = $false,
					   Position = 2,
					   HelpMessage = 'Optionally reset winsock catalog, stop the SCOM Services, clear SCOM Cache, then reboot the server. This will always perform on the local server last.')]
			[Switch]$Reboot,
			[Parameter(Mandatory = $false,
					   ValueFromPipeline = $true,
					   Position = 3,
					   HelpMessage = 'Each Server you want to clear SCOM Cache on. Can be an Agent, Management Server, or SCOM Gateway. This will always perform on the local server last.')]
			[String[]]$Servers,
			[Parameter(Mandatory = $false,
					   Position = 4,
					   HelpMessage = 'Optionally shutdown the server after clearing the SCOM cache. This will always perform on the local server last.')]
			[Switch]$Shutdown,
			[Parameter(Position = 5,
					   HelpMessage = 'Time in seconds to sleep between each server.')]
			[int64]$Sleep
		)
		$setdefault = $false
		foreach ($Server in $input)
		{
			if ($Server)
			{
				if ($Server.GetType().Name -eq 'ManagementServer')
				{
					if (!$setdefault)
					{
						$Servers = @()
						$setdefault = $true
					}
					$Servers += $Server.DisplayName
				}
				elseif ($Server.GetType().Name -eq 'AgentManagedComputer')
				{
					if (!$setdefault)
					{
						$Servers = @()
						$setdefault = $true
					}
					$Servers += $Server.DisplayName
				}
				elseif ($Server.GetType().Name -eq 'MonitoringObject')
				{
					if (!$setdefault)
					{
						$Servers = @()
						$setdefault = $true
					}
					$Servers += $Server.DisplayName
				}
				else
				{
					if (!$setdefault)
					{
						$Servers = @()
						$setdefault = $true
					}
					$Servers += $Server
				}
				
			}
			
		}
		if (!$Servers)
		{
			$Servers = $env:COMPUTERNAME
		}
		function Inner-ClearSCOMCache
		{
			param
			(
				[Parameter(Mandatory = $false,
						   Position = 1)]
				[Switch]$All,
				[Parameter(Mandatory = $false,
						   Position = 2)]
				[Switch]$Reboot,
				[Parameter(Mandatory = $false,
						   Position = 3)]
				[Switch]$Shutdown
			)
			BEGIN
			{
				trap
				{
					Write-Output $_
				}
				
				$currentserv = $env:COMPUTERNAME
				Function Get-TimeStamp
				{
					$TimeStamp = (Get-Date).DateTime
					return "$TimeStamp - "
				}
				Write-Output "`n==================================================================="
				Write-Output "$(Get-TimeStamp)Starting Script Execution on: $currentserv"
			}
			PROCESS
			{
				$omsdk = (Get-WmiObject win32_service | Where-Object{ $_.Name -eq 'omsdk' } | Select-Object PathName -ExpandProperty PathName | ForEach-Object { $_.Split('"')[1] }) | Split-Path
				$cshost = (Get-WmiObject win32_service | Where-Object{ $_.Name -eq 'cshost' } | Select-Object PathName -ExpandProperty PathName | ForEach-Object { $_.Split('"')[1] }) | Split-Path
				$healthservice = (Get-WmiObject win32_service | Where-Object{ $_.Name -eq 'healthservice' } | Select-Object PathName -ExpandProperty PathName | ForEach-Object { $_.Split('"')[1] }) | Split-Path
				$apm = (Get-WmiObject win32_service | Where-Object{ $_.Name -eq 'System Center Management APM' } | Select-Object PathName -ExpandProperty PathName | ForEach-Object { $_.Split('"')[1] }) | Split-Path
				$auditforwarding = (Get-WmiObject win32_service -ErrorAction SilentlyContinue | Where-Object{ $_.Name -eq 'AdtAgent' } | Select-Object PathName -ExpandProperty PathName | ForEach-Object { $_.Split('"')[1] }) | Split-Path -ErrorAction SilentlyContinue
				$veeamcollector = (Get-WmiObject win32_service | Where-Object{ $_.Name -eq 'veeamcollector' } | Select-Object PathName -ExpandProperty PathName | ForEach-Object { $_.Split('"')[1] }) | Split-Path
				if ($omsdk)
				{
					$omsdkStatus = (Get-Service -Name omsdk).Status
					if ($omsdkStatus -eq "Running")
					{
						Write-Output ("$(Get-TimeStamp)Stopping `'{0}`' Service" -f (Get-Service -Name 'omsdk').DisplayName)
						Stop-Service omsdk
					}
					else
					{
						Write-Output ("$(Get-TimeStamp)[Warning] :: Status of `'{0}`' Service - $omsdkStatus" -f (Get-Service -Name 'omsdk').DisplayName)
					}
					
				}
				if ($cshost)
				{
					$cshostStatus = (Get-Service -Name cshost).Status
					if ($cshostStatus -eq "Running")
					{
						Write-Output ("$(Get-TimeStamp)Stopping `'{0}`' Service" -f (Get-Service -Name 'cshost').DisplayName)
						Stop-Service cshost
					}
					else
					{
						Write-Output ("$(Get-TimeStamp)[Warning] :: Status of `'{0}`' Service - $cshostStatus" -f (Get-Service -Name 'cshost').DisplayName)
					}
				}
				if ($apm)
				{
					$apmStatus = (Get-Service -Name 'System Center Management APM').Status
					$apmStartType = (Get-Service -Name 'System Center Management APM').StartType
					if ($apmStatus -eq "Running")
					{
						Write-Output ("$(Get-TimeStamp)Stopping `'{0}`' Service" -f (Get-Service -Name 'System Center Management APM').DisplayName)
						Stop-Service 'System Center Management APM'
					}
					elseif ($apmStartType -eq 'Disabled')
					{
						Write-Output ("$(Get-TimeStamp)Status of `'{0}`' Service - $apmStartType" -f (Get-Service -Name 'System Center Management APM').DisplayName)
						$apm = $null
					}
					elseif ($apmStatus -eq 'Stopped')
					{
						Write-Output ("$(Get-TimeStamp)Status of `'{0}`' Service - $apmStatus" -f (Get-Service -Name 'System Center Management APM').DisplayName)
						$apm = $null
					}
					else
					{
						Write-Output ("$(Get-TimeStamp)[Warning] :: Status of `'{0}`' Service - $apmStatus" -f (Get-Service -Name 'System Center Management APM').DisplayName)
					}
				}
				if ($auditforwarding)
				{
					$auditforwardingstatus = (Get-Service -Name 'AdtAgent').Status
					$auditforwardingStartType = (Get-Service -Name 'System Center Management APM').StartType
					if ($auditforwardingstatus -eq "Running")
					{
						Write-Output ("$(Get-TimeStamp)Stopping `'{0}`' Service" -f (Get-Service -Name 'AdtAgent').DisplayName)
						Stop-Service AdtAgent
					}
					elseif ($auditforwardingStartType -eq 'Disabled')
					{
						$auditforwarding = $null
					}
					else
					{
						Write-Output ("$(Get-TimeStamp)[Warning] :: Status of `'{0}`' Service - $auditforwardingstatus" -f (Get-Service -Name 'AdtAgent').DisplayName)
					}
				}
				if ($veeamcollector)
				{
					$veeamcollectorStatus = (Get-Service -Name 'veeamcollector').Status
					$veeamcollectorStartType = (Get-Service -Name 'veeamcollector').StartType
					if ($veeamcollectorStatus -eq "Running")
					{
						Write-Output ("$(Get-TimeStamp)Stopping `'{0}`' Service" -f (Get-Service -Name 'System Center Management APM').DisplayName)
						Stop-Service 'System Center Management APM'
					}
					elseif ($veeamcollectorStartType -eq 'Disabled')
					{
						$veeamcollector = $null
					}
					else
					{
						Write-Output ("$(Get-TimeStamp)[Warning] :: Status of `'{0}`' Service - $veeamcollectorStatus" -f (Get-Service -Name 'System Center Management APM').DisplayName)
					}
				}
				if ($healthservice)
				{
					$healthserviceStatus = (Get-Service -Name healthservice).Status
					if ($healthserviceStatus -eq "Running")
					{
						Write-Output ("$(Get-TimeStamp)Stopping `'{0}`' Service" -f (Get-Service -Name 'healthservice').DisplayName)
						Stop-Service healthservice
					}
					else
					{
						Write-Output ("$(Get-TimeStamp)[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'healthservice').DisplayName)
						Write-Output "$healthserviceStatus"
					}
					try
					{
						Write-Output "$(Get-TimeStamp)Attempting to Move Folder from: `"$healthservice`\Health Service State`" to `"$healthservice\Health Service State.old`" "
						Move-Item "$healthservice\Health Service State" "$healthservice\Health Service State.old" -ErrorAction Stop
						Write-Output "$(Get-TimeStamp)Moved Folder Successfully"
					}
					catch
					{
						Write-Output "$(Get-TimeStamp)[Info] :: $_"
						Write-Output "$(Get-TimeStamp)Attempting to Delete Folder: `"$healthservice`\Health Service State`" "
						try
						{
							Remove-Item "$healthservice\Health Service State" -Recurse -ErrorAction Stop
							Write-Output "$(Get-TimeStamp)Deleted Folder Successfully"
						}
						catch
						{
							Write-Output "$(Get-TimeStamp)Issue removing the 'Health Service State' folder. Maybe attempt to clear the cache again, or a process is using the Health Service State Folder."
							#$healthservice = $null
						}
					}
					
				}
				if ($null -eq $omsdk -and $cshost -and $healthservice)
				{
					try
					{
						$installdir = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup" -ErrorAction Stop | Select-Object -Property "InstallDirectory" -ExpandProperty "InstallDirectory"
						try
						{
							Write-Output "$(Get-TimeStamp)Attempting to Move Folder from: `"$installdir`\Health Service State`" to `"$installdir\Health Service State.old`" "
							Move-Item "$installdir\Health Service State" "$installdir\Health Service State.old" -ErrorAction Stop
							Write-Output "$(Get-TimeStamp)Moved Folder Successfully"
						}
						catch
						{
							Write-Output "$(Get-TimeStamp)[Warning] :: $_"
							Write-Output "$(Get-TimeStamp)Attempting to Delete Folder: `"$installdir`\Health Service State`" "
							try
							{
								Remove-Item "$installdir\Health Service State" -Recurse -ErrorAction Stop
								Write-Output "$(Get-TimeStamp)Deleted Folder Successfully"
							}
							catch
							{
								Write-Warning $_
							}
						}
					}
					catch
					{
						Write-Warning "$(Get-TimeStamp)Unable to locate the Install Directory`nHKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup"
						break
					}
				}
				# Clear Console Cache
				$consoleKey = Get-Item 'HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Console\' -ErrorAction SilentlyContinue
				if ($consoleKey)
				{
					try
					{
						if ($Shutdown -or $Reboot)
						{
							Write-Output "$(Get-TimeStamp) Attempting to force closure of open Operations Manager Console(s) due to Reboot or Shutdown switch present."
							Stop-Process -Name "Microsoft.EnterpriseManagement.Monitoring.Console" -Confirm:$false -ErrorAction SilentlyContinue
						}
						$cachePath = Get-ChildItem "$env:SystemDrive\Users\*\AppData\Local\Microsoft\Microsoft.EnterpriseManagement.Monitoring.Console\momcache.mdb"
						if ($cachePath)
						{
							Write-Output "$(Get-TimeStamp)Clearing Operations Manager Console Cache for the following users:";
							foreach ($consolecachefolder in $cachePath)
							{
								Write-Output "$(Get-TimeStamp)  $($consolecachefolder.FullName.Split("\")[2])"
								Remove-Item $consolecachefolder -Force -ErrorAction Stop
							}
						}
						
					}
					catch { Write-Warning $_ }
				}
				
				if ($All -or $Reboot -or $Shutdown)
				{
					Write-Output "$(Get-TimeStamp)Purging Kerberos Tickets: KList -li 0x3e7 purge"
					Start-Process "KList" "-li 0x3e7 purge"
					Write-Output "$(Get-TimeStamp)Flushing DNS: IPConfig /FlushDNS"
					Start-Process "IPConfig" "/FlushDNS"
					Write-Output "$(Get-TimeStamp)Resetting NetBIOS over TCPIP Statistics: NBTStat -R"
					Start-Process "NBTStat" "-R"
				}
				if ($Shutdown)
				{
					Write-Output "$(Get-TimeStamp)Shutting down: $env:COMPUTERNAME"
					Shutdown /s /t 10
					continue
				}
				elseif ($Reboot)
				{
					Write-Output "$(Get-TimeStamp)Resetting Winsock catalog: netsh winsock reset"
					Start-Process "netsh" "winsock reset"
					Start-Sleep 1
					Write-Output "$(Get-TimeStamp)Restarting: $env:COMPUTERNAME"
					Shutdown /r /t 10
				}
				else
				{
					if ($veeamcollector)
					{
						Write-Output ("$(Get-TimeStamp)Starting `'{0}`' Service" -f (Get-Service -Name 'veeamcollector').DisplayName)
						Start-Service 'veeamcollector'
					}
					if ($healthservice)
					{
						Write-Output ("$(Get-TimeStamp)Starting `'{0}`' Service" -f (Get-Service -Name 'healthservice').DisplayName)
						Start-Service 'healthservice'
					}
					if ($omsdk)
					{
						Write-Output ("$(Get-TimeStamp)Starting `'{0}`' Service" -f (Get-Service -Name 'omsdk').DisplayName)
						Start-Service 'omsdk'
					}
					if ($cshost)
					{
						Write-Output ("$(Get-TimeStamp)Starting `'{0}`' Service" -f (Get-Service -Name 'cshost').DisplayName)
						Start-Service 'cshost'
					}
					if ($apm)
					{
						Write-Output ("$(Get-TimeStamp)Starting `'{0}`' Service" -f (Get-Service -Name 'System Center Management APM').DisplayName)
						Start-Service 'System Center Management APM'
					}
					if ($auditforwarding)
					{
						Write-Output ("$(Get-TimeStamp)Starting `'{0}`' Service" -f (Get-Service -Name 'AdtAgent').DisplayName)
						Start-Service 'AdtAgent'
					}
				}
			}
			END
			{
				Write-Output "$(Get-TimeStamp)Completed Script Execution on: $currentserv"
			}
			
		}
		$containslocal = $false
		if ($Servers)
		{
			$InnerClearSCOMCacheFunctionScript = "function Inner-ClearSCOMCache { ${function:Inner-ClearSCOMCache} }"
			if ($Servers.Count -le 1)
			{
				Write-Verbose "$(Get-TimeStamp)Server list ($Servers) 1 or below, setting -Sleep to `$false."
				$Sleep = $false
			}
			foreach ($server in $Servers)
			{
				if ($server -match "$env:COMPUTERNAME")
				{
					Write-Verbose "$(Get-TimeStamp)Contains Local Server Name."
					$containslocal = $true
					continue
				}
				if ($Shutdown)
				{
					try
					{
						Invoke-Command -ErrorAction Stop -ComputerName $server -ArgumentList $InnerClearSCOMCacheFunctionScript -ScriptBlock {
							Param ($script,
								$VerbosePreference)
							. ([ScriptBlock]::Create($script))
							if ($VerbosePreference.value__ -ne 0)
							{
								return Inner-ClearSCOMCache -Verbose -Shutdown
							}
							else
							{
								return Inner-ClearSCOMCache -Shutdown
							}
						}
					}
					catch { Write-Output $Error[0] }
					if ($Sleep)
					{
						Write-Output "$(Get-TimeStamp)Sleeping for $Sleep seconds."
						Start-Sleep -Seconds $Sleep
					}
					continue
				}
				elseif ($Reboot)
				{
					if ($All)
					{
						try
						{
							Invoke-Command -ErrorAction Stop -ComputerName $server -ArgumentList $InnerClearSCOMCacheFunctionScript -ScriptBlock {
								Param ($script,
									$VerbosePreference)
								. ([ScriptBlock]::Create($script))
								if ($VerbosePreference.value__ -ne 0)
								{
									return Inner-ClearSCOMCache -Verbose -All -Reboot
								}
								else
								{
									return Inner-ClearSCOMCache -All -Reboot
								}
							}
						}
						catch { Write-Output $Error[0] }
					}
					else
					{
						try
						{
							Invoke-Command -ErrorAction Stop -ComputerName $server -ArgumentList $InnerClearSCOMCacheFunctionScript -ScriptBlock {
								Param ($script,
									$VerbosePreference)
								. ([ScriptBlock]::Create($script))
								if ($VerbosePreference.value__ -ne 0)
								{
									return Inner-ClearSCOMCache -Verbose -Reboot
								}
								else
								{
									return Inner-ClearSCOMCache -Reboot
								}
							}
						}
						catch { Write-Output $Error[0] }
					}
				}
				elseif ($All)
				{
					try
					{
						Invoke-Command -ErrorAction Stop -ComputerName $server -ArgumentList $InnerClearSCOMCacheFunctionScript -ScriptBlock {
							Param ($script,
								$VerbosePreference)
							. ([ScriptBlock]::Create($script))
							if ($VerbosePreference.value__ -ne 0)
							{
								return Inner-ClearSCOMCache -Verbose -All
							}
							else
							{
								return Inner-ClearSCOMCache -All
							}
						}
					}
					catch { Write-Output $Error[0] }
				}
				else
				{
					try
					{
						Invoke-Command -ErrorAction Stop -ComputerName $server -ArgumentList $InnerClearSCOMCacheFunctionScript, $VerbosePreference -ScriptBlock {
							Param ($script,
								$VerbosePreference)
							. ([ScriptBlock]::Create($script))
							if ($VerbosePreference.value__ -ne 0)
							{
								Write-Verbose "Verbose Preference Defined"
								return Inner-ClearSCOMCache -Verbose
							}
							else
							{
								Write-Verbose "Verbose Preference Not Defined"
								return Inner-ClearSCOMCache
							}
						}
					}
					catch { Write-Output $Error[0] }
				}
				if ($Sleep)
				{
					Write-Output "$(Get-TimeStamp)Sleeping for $Sleep seconds."
					Start-Sleep -Seconds $Sleep
				}
				continue
			}
			# If the list contains local server, run the below if-elseif-else section
			if ($containslocal)
			{
				if ($Reboot -and $All)
				{
					Inner-ClearSCOMCache -Reboot -All
				}
				elseif ($Reboot)
				{
					Inner-ClearSCOMCache -Reboot
				}
				elseif ($Shutdown)
				{
					Inner-ClearSCOMCache -Shutdown
				}
				elseif ($All)
				{
					Inner-ClearSCOMCache -All
				}
				else
				{
					Inner-ClearSCOMCache
				}
			}
		}
	}
	if ($All -or $Reboot -or $Servers -or $Shutdown -or $Sleep)
	{
		Clear-SCOMCache -All:$All -Reboot:$Reboot -Servers $Servers -Shutdown:$Shutdown -Sleep $Sleep
	}
	else
	{
	<# Edit line 680 to modify the default command run when this script is executed without any arguments. This is helpful when running from Powershell ISE.

	   Example 1: 
	   Clear-SCOMCache -Servers Agent1.contoso.com, Agent2.contoso.com, MangementServer1.contoso.com, MangementServer2.contoso.com

	   Example 2:
	   Get-SCOMManagementServer | Clear-SCOMCache
	   #>
		Clear-SCOMCache
	}
}
end
{
	Write-Output "$(Get-TimeStamp)Script has Completed!"
	Write-Output "==================================================================="
}
