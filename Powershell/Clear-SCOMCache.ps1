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
		For advanced users: Edit line 663 to modify the default command run when this script is executed.

		Originally hosted on my github:
		https://github.com/blakedrumm/SCOM-Scripts-and-SQL/blob/master/Powershell/Clear-SCOMCache.ps1
		
		Blog Post: https://blakedrumm.com/blog/clear-scomcache/

		.AUTHOR
		Blake Drumm (blakedrumm@microsoft.com)
		
		.MODIFIED
		November 21st, 2022
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
				if (-NOT ($omsdk -or $cshost -or $healthservice))
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
	<# Edit line 663 to modify the default command run when this script is executed without any arguments. This is helpful when running from Powershell ISE.

	   Example 1: 
	   Clear-SCOMCache -Servers Agent1.contoso.com, Agent2.contoso.com, ManagementServer1.contoso.com, ManagementServer2.contoso.com

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

# SIG # Begin signature block
# MIInpAYJKoZIhvcNAQcCoIInlTCCJ5ECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDIZnJKV9LEPh7A
# Hagyeqfv4kZdnWeWnhXd53BxafqEwqCCDXYwggX0MIID3KADAgECAhMzAAACy7d1
# OfsCcUI2AAAAAALLMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjIwNTEyMjA0NTU5WhcNMjMwNTExMjA0NTU5WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQC3sN0WcdGpGXPZIb5iNfFB0xZ8rnJvYnxD6Uf2BHXglpbTEfoe+mO//oLWkRxA
# wppditsSVOD0oglKbtnh9Wp2DARLcxbGaW4YanOWSB1LyLRpHnnQ5POlh2U5trg4
# 3gQjvlNZlQB3lL+zrPtbNvMA7E0Wkmo+Z6YFnsf7aek+KGzaGboAeFO4uKZjQXY5
# RmMzE70Bwaz7hvA05jDURdRKH0i/1yK96TDuP7JyRFLOvA3UXNWz00R9w7ppMDcN
# lXtrmbPigv3xE9FfpfmJRtiOZQKd73K72Wujmj6/Su3+DBTpOq7NgdntW2lJfX3X
# a6oe4F9Pk9xRhkwHsk7Ju9E/AgMBAAGjggFzMIIBbzAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUrg/nt/gj+BBLd1jZWYhok7v5/w4w
# RQYDVR0RBD4wPKQ6MDgxHjAcBgNVBAsTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEW
# MBQGA1UEBRMNMjMwMDEyKzQ3MDUyODAfBgNVHSMEGDAWgBRIbmTlUAXTgqoXNzci
# tW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3JsMGEG
# CCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3J0
# MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIBAJL5t6pVjIRlQ8j4dAFJ
# ZnMke3rRHeQDOPFxswM47HRvgQa2E1jea2aYiMk1WmdqWnYw1bal4IzRlSVf4czf
# zx2vjOIOiaGllW2ByHkfKApngOzJmAQ8F15xSHPRvNMmvpC3PFLvKMf3y5SyPJxh
# 922TTq0q5epJv1SgZDWlUlHL/Ex1nX8kzBRhHvc6D6F5la+oAO4A3o/ZC05OOgm4
# EJxZP9MqUi5iid2dw4Jg/HvtDpCcLj1GLIhCDaebKegajCJlMhhxnDXrGFLJfX8j
# 7k7LUvrZDsQniJZ3D66K+3SZTLhvwK7dMGVFuUUJUfDifrlCTjKG9mxsPDllfyck
# 4zGnRZv8Jw9RgE1zAghnU14L0vVUNOzi/4bE7wIsiRyIcCcVoXRneBA3n/frLXvd
# jDsbb2lpGu78+s1zbO5N0bhHWq4j5WMutrspBxEhqG2PSBjC5Ypi+jhtfu3+x76N
# mBvsyKuxx9+Hm/ALnlzKxr4KyMR3/z4IRMzA1QyppNk65Ui+jB14g+w4vole33M1
# pVqVckrmSebUkmjnCshCiH12IFgHZF7gRwE4YZrJ7QjxZeoZqHaKsQLRMp653beB
# fHfeva9zJPhBSdVcCW7x9q0c2HVPLJHX9YCUU714I+qtLpDGrdbZxD9mikPqL/To
# /1lDZ0ch8FtePhME7houuoPcMIIHejCCBWKgAwIBAgIKYQ6Q0gAAAAAAAzANBgkq
# hkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEwOTA5WjB+MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQg
# Q29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+laUKq4BjgaBEm6f8MMHt03
# a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc6Whe0t+bU7IKLMOv2akr
# rnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4Ddato88tt8zpcoRb0Rrrg
# OGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+lD3v++MrWhAfTVYoonpy
# 4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nkkDstrjNYxbc+/jLTswM9
# sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6A4aN91/w0FK/jJSHvMAh
# dCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmdX4jiJV3TIUs+UsS1Vz8k
# A/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL5zmhD+kjSbwYuER8ReTB
# w3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zdsGbiwZeBe+3W7UvnSSmn
# Eyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3T8HhhUSJxAlMxdSlQy90
# lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS4NaIjAsCAwEAAaOCAe0w
# ggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRIbmTlUAXTgqoXNzcitW2o
# ynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYD
# VR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBDuRQFTuHqp8cx0SOJNDBa
# BgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2Ny
# bC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3JsMF4GCCsG
# AQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3J0MIGfBgNV
# HSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEFBQcCARYzaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1hcnljcHMuaHRtMEAGCCsG
# AQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkAYwB5AF8AcwB0AGEAdABl
# AG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn8oalmOBUeRou09h0ZyKb
# C5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7v0epo/Np22O/IjWll11l
# hJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0bpdS1HXeUOeLpZMlEPXh6
# I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/KmtYSWMfCWluWpiW5IP0
# wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvyCInWH8MyGOLwxS3OW560
# STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBpmLJZiWhub6e3dMNABQam
# ASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJihsMdYzaXht/a8/jyFqGa
# J+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYbBL7fQccOKO7eZS/sl/ah
# XJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbSoqKfenoi+kiVH6v7RyOA
# 9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sLgOppO6/8MO0ETI7f33Vt
# Y5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtXcVZOSEXAQsmbdlsKgEhr
# /Xmfwb1tbWrJUnMTDXpQzTGCGYQwghmAAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAALLt3U5+wJxQjYAAAAAAsswDQYJYIZIAWUDBAIB
# BQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBf9KVFGsKhYR4nSz5dRC4G1
# c5YYKG9O7OkLhk+A9VBIMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQCrgV24Wn4oPWVcAwPTAg4+7R7jKhTIGq6JoFZWcMnjIlswdIJgKbPE
# jJZNKYwCJ1TdBPKb3ZVCfnuXVlzIS/7n7/HeTgTLrxy5S8PzfGp+3G9J7k7g2AUg
# aJ+M33eLO+tdN2x2Z94uUKeWo1Ew1hbXAVelGBEu0LIQ8QJIFOPhGOBVw7Audcxs
# jLndBJYAETQk/4bQnve6c8L9UCBR8uzr6Z5Y55OOf08kTlRqct1KGU8AXY8JROVF
# fHTFinCrc+b6nZaDXGn0952Jpvww5wdecjPugy58XVvqyUEtoD1gSCFzT8bmP+bL
# DUmHcRx8GCzDVahXj5s9qRIHkZ7T6LLgoYIXDDCCFwgGCisGAQQBgjcDAwExghb4
# MIIW9AYJKoZIhvcNAQcCoIIW5TCCFuECAQMxDzANBglghkgBZQMEAgEFADCCAVUG
# CyqGSIb3DQEJEAEEoIIBRASCAUAwggE8AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEIN0aRyRdz8uXDNKNfAjq8tK/CPHBuSp7W2GXYE2KVsHsAgZjc8e5
# um4YEzIwMjIxMTI5MjAzMDA3LjI3MlowBIACAfSggdSkgdEwgc4xCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAsTIE1pY3Jvc29mdCBP
# cGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjo0
# RDJGLUUzREQtQkVFRjElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vy
# dmljZaCCEV8wggcQMIIE+KADAgECAhMzAAABsKHjgzLojTvAAAEAAAGwMA0GCSqG
# SIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# JjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4XDTIyMDMw
# MjE4NTE0MloXDTIzMDUxMTE4NTE0Mlowgc4xCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1
# ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjo0RDJGLUUzREQtQkVF
# RjElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCAiIwDQYJ
# KoZIhvcNAQEBBQADggIPADCCAgoCggIBAJzGbTsM19KCnQc5RC7VoglySXMKLut/
# yWWPQWD6VAlJgBexVKx2n1zgX3o/xA2ZgZ/NFGcgNDRCJ7mJiOeW7xeHnoNXPlg7
# EjYWulfk3oOAj6a7O15GvckpYsvLcx+o8Se8CrfIb40EJ8W0Qx4TIXf0yDwAJ4/q
# O94dJ/hGabeJYg4Gp0G0uQmhwFovAWTHlD1ci+sp36AxT9wIhHqw/70tzMvrnDF7
# jmQjaVUPnjOgPOyFWZiVr7e6rkSl4anT1tLv23SWhXqMs14wolv4ZeQcWP84rV2F
# rr1KbwkIa0vlHjlv4xG9a6nlTRfo0CYUQDfrZOMXCI5KcAN2BZ6fVb09qtCdsWdN
# NxB0y4lwMjnuNmx85FNfzPcMZjmwAF9aRUUMLHv626I67t1+dZoVPpKqfSNmGtVt
# 9DETWkmDipnGg4+BdTplvgGVq9F3KZPDFHabxbLpSWfXW90MZXOuFH8yCMzDJNUz
# eyAqytFFyLZir3j4T1Gx7lReCOUPw1puVzbWKspV7ModZjtN/IUWdVIdk3HPp4QN
# 1wwdVvdXOsYdhG8kgjGyAZID5or7C/75hyKQb5F0Z+Ee04uY9K+sDZ3l3z8TQZWA
# fYurbZCMWWnmJVsu5V4PR5PO+U6D7tAtMvMULNYibT9+sxVZK/WQer2JJ9q3Z7lj
# Fs4lgpmfc6AVAgMBAAGjggE2MIIBMjAdBgNVHQ4EFgQUOt8BJDcBJm4dy6ASZHrX
# IEfWNj8wHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYDVR0fBFgw
# VjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWlj
# cm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwGCCsGAQUF
# BwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3Br
# aW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgx
# KS5jcnQwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcDCDANBgkqhkiG
# 9w0BAQsFAAOCAgEA3XPih5sNtUfAyLnlXq6MZSpCh0TF+uG+nhIJ44//cMcQGEVi
# Z2N263NwvrQjCFOni/+oxf76jcmUhcKWLXk9hhd7vfFBhZZzcF5aNs07Uligs24p
# veasFuhmJ4y82OYm1G1ORYsFndZdvF//NrYGxaXqUNlRHQlskV/pmccqO3Oi6wLH
# cPB1/WRTLJtYbIiiwE/uTFEFEL45wWD/1mTCPEkFX3hliXEypxXzdZ1k6XqGTysG
# AtLXUB7IC6CH26YygKQuXG8QjcJBAUG/9F3yNZOdbFvn7FinZyNcIVLxld7h0bEL
# fQzhIjelj+5sBKhLcaFU0vbjbmf0WENgFmnyJNiMrL7/2FYOLsgiQDbJx6Dpy1Ef
# vuRGsdL5f+jVVds5oMaKrhxgV7oEobrA6Z56nnWYN47swwouucHf0ym1DQWHy2DH
# OFRRN7yv++zes0GSCOjRRYPK7rr1Qc+O3nsd604Ogm5nR9QqhOOc2OQTrvtSgXBS
# tu5vF6W8DPcsns53cQ4gdcR1Y9Ng5IYEwxCZzzYsq9oalxlH+ZH/A6J7ZMeSNKNk
# rXPx6ppFXUxHuC3k4mzVyZNGWP/ZgcUOi2qV03m6Imytvi1kfGe6YdCh32POgWeN
# H9lfKt+d1M+q4IhJLmX0E2ZZICYEb9Q0romeMX8GZ+cbhuNsFimJga/fjjswggdx
# MIIFWaADAgECAhMzAAAAFcXna54Cm0mZAAAAAAAVMA0GCSqGSIb3DQEBCwUAMIGI
# MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
# bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylN
# aWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAxMDAeFw0yMTA5
# MzAxODIyMjVaFw0zMDA5MzAxODMyMjVaMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBD
# QSAyMDEwMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA5OGmTOe0ciEL
# eaLL1yR5vQ7VgtP97pwHB9KpbE51yMo1V/YBf2xK4OK9uT4XYDP/XE/HZveVU3Fa
# 4n5KWv64NmeFRiMMtY0Tz3cywBAY6GB9alKDRLemjkZrBxTzxXb1hlDcwUTIcVxR
# MTegCjhuje3XD9gmU3w5YQJ6xKr9cmmvHaus9ja+NSZk2pg7uhp7M62AW36MEByd
# Uv626GIl3GoPz130/o5Tz9bshVZN7928jaTjkY+yOSxRnOlwaQ3KNi1wjjHINSi9
# 47SHJMPgyY9+tVSP3PoFVZhtaDuaRr3tpK56KTesy+uDRedGbsoy1cCGMFxPLOJi
# ss254o2I5JasAUq7vnGpF1tnYN74kpEeHT39IM9zfUGaRnXNxF803RKJ1v2lIH1+
# /NmeRd+2ci/bfV+AutuqfjbsNkz2K26oElHovwUDo9Fzpk03dJQcNIIP8BDyt0cY
# 7afomXw/TNuvXsLz1dhzPUNOwTM5TI4CvEJoLhDqhFFG4tG9ahhaYQFzymeiXtco
# dgLiMxhy16cg8ML6EgrXY28MyTZki1ugpoMhXV8wdJGUlNi5UPkLiWHzNgY1GIRH
# 29wb0f2y1BzFa/ZcUlFdEtsluq9QBXpsxREdcu+N+VLEhReTwDwV2xo3xwgVGD94
# q0W29R6HXtqPnhZyacaue7e3PmriLq0CAwEAAaOCAd0wggHZMBIGCSsGAQQBgjcV
# AQQFAgMBAAEwIwYJKwYBBAGCNxUCBBYEFCqnUv5kxJq+gpE8RjUpzxD/LwTuMB0G
# A1UdDgQWBBSfpxVdAF5iXYP05dJlpxtTNRnpcjBcBgNVHSAEVTBTMFEGDCsGAQQB
# gjdMg30BATBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20v
# cGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wEwYDVR0lBAwwCgYIKwYBBQUHAwgw
# GQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB
# /wQFMAMBAf8wHwYDVR0jBBgwFoAU1fZWy4/oolxiaNE9lJBb186aGMQwVgYDVR0f
# BE8wTTBLoEmgR4ZFaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJv
# ZHVjdHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3JsMFoGCCsGAQUFBwEBBE4w
# TDBKBggrBgEFBQcwAoY+aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0
# cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5jcnQwDQYJKoZIhvcNAQELBQADggIB
# AJ1VffwqreEsH2cBMSRb4Z5yS/ypb+pcFLY+TkdkeLEGk5c9MTO1OdfCcTY/2mRs
# fNB1OW27DzHkwo/7bNGhlBgi7ulmZzpTTd2YurYeeNg2LpypglYAA7AFvonoaeC6
# Ce5732pvvinLbtg/SHUB2RjebYIM9W0jVOR4U3UkV7ndn/OOPcbzaN9l9qRWqveV
# tihVJ9AkvUCgvxm2EhIRXT0n4ECWOKz3+SmJw7wXsFSFQrP8DJ6LGYnn8AtqgcKB
# GUIZUnWKNsIdw2FzLixre24/LAl4FOmRsqlb30mjdAy87JGA0j3mSj5mO0+7hvoy
# GtmW9I/2kQH2zsZ0/fZMcm8Qq3UwxTSwethQ/gpY3UA8x1RtnWN0SCyxTkctwRQE
# cb9k+SS+c23Kjgm9swFXSVRk2XPXfx5bRAGOWhmRaw2fpCjcZxkoJLo4S5pu+yFU
# a2pFEUep8beuyOiJXk+d0tBMdrVXVAmxaQFEfnyhYWxz/gq77EFmPWn9y8FBSX5+
# k77L+DvktxW/tM4+pTFRhLy/AsGConsXHRWJjXD+57XQKBqJC4822rpM+Zv/Cuk0
# +CQ1ZyvgDbjmjJnW4SLq8CdCPSWU5nR0W2rRnj7tfqAxM328y+l7vzhwRNGQ8cir
# Ooo6CGJ/2XBjU02N7oJtpQUQwXEGahC0HVUzWLOhcGbyoYIC0jCCAjsCAQEwgfyh
# gdSkgdEwgc4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAn
# BgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQL
# Ex1UaGFsZXMgVFNTIEVTTjo0RDJGLUUzREQtQkVFRjElMCMGA1UEAxMcTWljcm9z
# b2Z0IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUAAp4vkN3fD5FN
# BVYZklZeS/JFPBiggYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAx
# MDANBgkqhkiG9w0BAQUFAAIFAOcwuqEwIhgPMjAyMjExMjkyMTA2NDFaGA8yMDIy
# MTEzMDIxMDY0MVowdzA9BgorBgEEAYRZCgQBMS8wLTAKAgUA5zC6oQIBADAKAgEA
# AgIJWwIB/zAHAgEAAgIRQTAKAgUA5zIMIQIBADA2BgorBgEEAYRZCgQCMSgwJjAM
# BgorBgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEB
# BQUAA4GBAEu7A1xM4qMsa46QUr5Yqcnx/1raNffDLKMwpQ6x8BCss8WVw6Stsi3/
# lQ04eOhBdIOHeZANAbetzW2eHOZ22bQtQmM2UGvJS/LXyPNRsqEyCDi9zWhlXPMJ
# 5VhqLRaObNpVUIY3uHOZXLBqf6OuE1cD4+EBEzAax36aKydFH0cvMYIEDTCCBAkC
# AQEwgZMwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQG
# A1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGwoeODMuiN
# O8AAAQAAAbAwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG
# 9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQg0hH+jq2rT0+FsNP7k+DpSatSe+FBmEmC
# zOeniGrrH+IwgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCDNBgtDd8uf9KTj
# Gf1G67IfKmcNFJmeWTd6ilAy5xWEoDCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0
# YW1wIFBDQSAyMDEwAhMzAAABsKHjgzLojTvAAAEAAAGwMCIEIFQLa22bykToAJsv
# jYUVHm71pr1F2086d5dK4pCd9x/DMA0GCSqGSIb3DQEBCwUABIICADtH53G9/ytx
# KYhfctw/C7tFMxcRuMItz/ibfh5C5RwxX+r5oEktr7dDpkN9D3y8WOOVuNaB0jd+
# IGNeDzMmPlHdEFr0C2HKY37mx36FTU2ro24Ue7EG4niI6SUmV6zrzGpU2E5BPfEi
# 5qradQ31WGj3/xVD2HjCLe2JS4UQUApEqEnk3a3VUEW9CiG6nx0Y7BrJS7oYiQX8
# Ji9XZpDf+YI1sY8mvzoWYcT312Linusk/wQjrj5ztBYecZ+LW0NIofFVEfehkb4g
# fzTaPrmydZiCu08GFuyNxuXmWn2faJR4INTvSWtNw92jV9TbhNmvGhfonWbphb1D
# iL4zmObjgdoh/MN62clxtwXIOaoenUdEakJR0wPuMW2kTDq3W0wjRgbPBTi2JLr8
# gThO9/2TmKsMW8Zb4IxajdJ3euokwd3kjLiKCIemRaCQwAt9QrmC0HgPc8GorVcQ
# Wjul8NFq6B3GjPEPU5maMK5z8QYgU7r0tCBYI9vsgzPaqIZ/pFdCmyIiidErNuej
# aAMgy728HW10XzlPEc5EQxW36vIRsWohu7PVD+NFzIXX/FVHfat9tpYG7NU6pEpM
# ITVE9q1yS4Tuu2uGmA4FfL0+0Ka674iCNZvECQKS2p0SfQHgqzMUt+0TQvor/m0f
# G8DuaXngSOfgQYMPna3q7mEoz4ymQPYP
# SIG # End signature block
