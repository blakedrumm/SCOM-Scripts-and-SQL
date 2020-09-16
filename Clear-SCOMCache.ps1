Function Clear-SCOMCache
{
<#
	.SYNOPSIS
		Clear-SCOMCache
	
	.DESCRIPTION
		The script reboots the server(s) after clearing the SCOM cache, Flushing DNS, Purging Kerberos Tickets, Resetting NetBIOS over TCPIP Statistics, and Resetting Winsock catalog
	
	.PARAMETER Servers
		A description of the Servers parameter.
	
	.EXAMPLE
		PS C:\> .\Clear-SCOMCache.ps1 -Servers MS1.contoso.com, MS2.contoso.com
	
	.NOTES
		Additional information about the file.
#>
	param
	(
		[Parameter(Mandatory = $false,
				   Position = 1)]
		[Array]$Servers
	)
	if ($Servers)
	{
		if ($Servers -match $env:COMPUTERNAME)
		{
			$Servers = $Servers -notmatch $env:COMPUTERNAME
			$containslocal = $true
		}
		foreach ($server in $Servers)
		{
			
			Invoke-Command -ComputerName $server -ScriptBlock {
				$currentserv = $using:server
				Function Time-Stamp
				{
					$TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
					write-host "$TimeStamp - " -NoNewline
				}
				Time-Stamp
				Write-Host "Starting Script Execution on $currentserv"
				$omsdk = (Get-WmiObject win32_service | ?{ $_.Name -like 'omsdk' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
				$cshost = (Get-WmiObject win32_service | ?{ $_.Name -like 'cshost' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
				$healthservice = (Get-WmiObject win32_service | ?{ $_.Name -like 'healthservice' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
				if ($omsdk)
				{
					Time-Stamp
					Write-Host "Stopping `'omsdk`' Service"
					net stop omsdk
				}
				elseif ($cshost)
				{
					Time-Stamp
					Write-Host "Stopping `'cshost`' Service"
					net stop cshost
				}
				elseif ($healthservice)
				{
					Time-Stamp
					Write-Host "Stopping `'healthservice`' Service"
					net stop healthservice
					try
					{
						Time-Stamp
						Write-Host "Attempting to Move Folder from: `"$healthservice`\Health Service State`" to `"$healthservice\Health Service State.old`""
						Move-Item "$healthservice\Health Service State" "$healthservice\Health Service State.old" -ErrorAction Stop
						Time-Stamp
						Write-Host "Moved Folder Successfully"
					}
					catch
					{
						$time = Time-Stamp
						Write-Warning "$time$_"
						Time-Stamp
						Write-Host "Attempting to Delete Folder: `"$healthservice`\Health Service State`""
						try
						{
							rd "$healthservice\Health Service State" /s /q
							Time-Stamp
							Write-Host "Deleted Folder Successfully"
						}
						catch
						{
							$healthservice = $null
						}
					}
					
				}
				elseif ($null -eq $omsdk -and $cshost -and $healthservice)
				{
					Time-Stamp
					try
					{
						$installdir = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup" -ErrorAction Stop | Select-Object -Property "InstallDirectory" -ExpandProperty "InstallDirectory"
						try
						{
							Time-Stamp
							Write-Host "Attempting to Move Folder from: `"$installdir`\Health Service State`" to `"$installdir\Health Service State.old`""
							Move-Item "$installdir\Health Service State" "$installdir\Health Service State.old" -ErrorAction Stop
							Time-Stamp
							Write-Host "Moved Folder Successfully"
						}
						catch
						{
							$time = Time-Stamp
							Write-Warning "$time$_"
							Time-Stamp
							Write-Host "Attempting to Delete Folder: `"$installdir`\Health Service State`""
							try
							{
								rd "$installdir\Health Service State" /s /q
								Time-Stamp
								Write-Host "Deleted Folder Successfully"
							}
							catch
							{
								$time = Time-Stamp
								Write-Warning $time$_
							}
						}
					}
					catch
					{
						Write-Warning "Unable to locate the Install Directory`nHKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup"
						exit 1
					}
				}
				Time-Stamp
				Write-Host "Flushing DNS: IPConfig /FlushDNS"
				Start-Process "IPConfig" "/FlushDNS"
				Time-Stamp
				Write-Host "Purging Kerberos Tickets: KList purge"
				Start-Process "KList" "purge"
				Time-Stamp
				Write-Host "Resetting NetBIOS over TCPIP Statistics: NBTStat -R"
				Start-Process "NBTStat" "-R"
				Time-Stamp
				Write-Host "Resetting Winsock catalog: ​netsh winsock reset"
				Start-Process "netsh" "winsock reset"
				sleep 2
				Write-Host "Restarting: $currentserv"
				Shutdown /r /t 15
			}
			Write-Host "----------------------------------------------------------`n"
		}
		if ($containslocal -eq $true)
		{
			Function Time-Stamp
			{
				$TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
				write-host "$TimeStamp - " -NoNewline
			}
			Time-Stamp
			Write-Host "Starting Script Execution on Local Computer"
			sleep 2
			$omsdk = (Get-WmiObject win32_service | ?{ $_.Name -like 'omsdk' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
			$cshost = (Get-WmiObject win32_service | ?{ $_.Name -like 'cshost' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
			$healthservice = (Get-WmiObject win32_service | ?{ $_.Name -like 'healthservice' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
			if ($omsdk)
			{
				Time-Stamp
				Write-Host "Stopping `'omsdk`' Service"
				net stop omsdk
			}
			elseif ($cshost)
			{
				Time-Stamp
				Write-Host "Stopping `'cshost`' Service"
				net stop cshost
			}
			elseif ($healthservice)
			{
				Time-Stamp
				Write-Host "Stopping `'healthservice`' Service"
				net stop healthservice
				try
				{
					Time-Stamp
					Write-Host "Attempting to Move Folder from: `"$healthservice`\Health Service State`" to `"$healthservice\Health Service State.old`""
					Move-Item "$healthservice\Health Service State" "$healthservice\Health Service State.old" -ErrorAction Stop
					Time-Stamp
					Write-Host "Moved Folder Successfully"
				}
				catch
				{
					$time = Time-Stamp
					Write-Warning "$time$_"
					Time-Stamp
					Write-Host "Attempting to Delete Folder: `"$healthservice`\Health Service State`""
					try
					{
						rd "$healthservice\Health Service State" /s /q
						Write-Host "Deleted Folder Successfully"
					}
					catch
					{
						$healthservice = $null
					}
				}
				
			}
			elseif ($null -eq $omsdk -and $cshost -and $healthservice)
			{
				Time-Stamp
				try
				{
					$installdir = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup" -ErrorAction Stop | Select-Object -Property "InstallDirectory" -ExpandProperty "InstallDirectory"
					try
					{
						Time-Stamp
						Write-Host "Attempting to Move Folder from: `"$installdir`\Health Service State`" to `"$installdir\Health Service State.old`""
						Move-Item "$installdir\Health Service State" "$installdir\Health Service State.old" -ErrorAction Stop
						Time-Stamp
						Write-Host "Moved Folder Successfully"
					}
					catch
					{
						$time = Time-Stamp
						Write-Warning "$time$_"
						Time-Stamp
						Write-Host "Attempting to Delete Folder: `"$installdir`\Health Service State`""
						try
						{
							rd "$installdir\Health Service State" /s /q
							Time-Stamp
							Write-Host "Deleted Folder Successfully"
						}
						catch
						{
							Write-Warning $_
						}
					}
				}
				catch
				{
					Write-Warning "Unable to locate the Install Directory`nHKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup"
					exit 1
				}
			}
			Time-Stamp
			Write-Host "Flushing DNS: IPConfig /FlushDNS"
			Start-Process "IPConfig" "/FlushDNS"
			Time-Stamp
			Write-Host "Purging Kerberos Tickets: KList purge"
			Start-Process "KList" "purge"
			Time-Stamp
			Write-Host "Resetting NetBIOS over TCPIP Statistics: NBTStat -R"
			Start-Process "NBTStat" "-R"
			Time-Stamp
			Write-Host "Resetting Winsock catalog: ​netsh winsock reset"
			Start-Process "netsh" "winsock reset"
			sleep 2
			Write-Host "Restarting: $env:COMPUTERNAME"
			Shutdown /r /t 15
		}
	}
	else
	{
		Function Time-Stamp
		{
			$TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
			write-host "$TimeStamp - " -NoNewline
		}
		Time-Stamp
		Write-Host "Starting Script Execution on Local Computer`nPausing for 20 seconds to give you time to verify this is what you want to do."
		sleep 20
		$omsdk = (Get-WmiObject win32_service | ?{ $_.Name -like 'omsdk' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
		$cshost = (Get-WmiObject win32_service | ?{ $_.Name -like 'cshost' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
		$healthservice = (Get-WmiObject win32_service | ?{ $_.Name -like 'healthservice' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
		if ($omsdk)
		{
			Time-Stamp
			Write-Host "Stopping `'omsdk`' Service"
			net stop omsdk
		}
		elseif ($cshost)
		{
			Time-Stamp
			Write-Host "Stopping `'cshost`' Service"
			net stop cshost
		}
		elseif ($healthservice)
		{
			Time-Stamp
			Write-Host "Stopping `'healthservice`' Service"
			net stop healthservice
			try
			{
				Time-Stamp
				Write-Host "Attempting to Move Folder from: `"$healthservice`\Health Service State`" to `"$healthservice\Health Service State.old`""
				Move-Item "$healthservice\Health Service State" "$healthservice\Health Service State.old" -ErrorAction Stop
				Time-Stamp
				Write-Host "Moved Folder Successfully"
			}
			catch
			{
				$time = Time-Stamp
				Write-Warning "$time$_"
				Time-Stamp
				Write-Host "Attempting to Delete Folder: `"$healthservice`\Health Service State`""
				try
				{
					rd "$healthservice\Health Service State" /s /q
					Write-Host "Deleted Folder Successfully"
				}
				catch
				{
					$healthservice = $null
				}
			}
			
		}
		elseif ($null -eq $omsdk -and $cshost -and $healthservice)
		{
			Time-Stamp
			try
			{
				$installdir = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup" -ErrorAction Stop | Select-Object -Property "InstallDirectory" -ExpandProperty "InstallDirectory"
				try
				{
					Time-Stamp
					Write-Host "Attempting to Move Folder from: `"$installdir`\Health Service State`" to `"$installdir\Health Service State.old`""
					Move-Item "$installdir\Health Service State" "$installdir\Health Service State.old" -ErrorAction Stop
					Time-Stamp
					Write-Host "Moved Folder Successfully"
				}
				catch
				{
					$time = Time-Stamp
					Write-Warning "$time$_"
					Time-Stamp
					Write-Host "Attempting to Delete Folder: `"$installdir`\Health Service State`""
					try
					{
						rd "$installdir\Health Service State" /s /q
						Time-Stamp
						Write-Host "Deleted Folder Successfully"
					}
					catch
					{
						Write-Warning $_
					}
				}
			}
			catch
			{
				Write-Warning "Unable to locate the Install Directory`nHKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup"
				exit 1
			}
		}
		Time-Stamp
		Write-Host "Flushing DNS: IPConfig /FlushDNS"
		Start-Process "IPConfig" "/FlushDNS"
		Time-Stamp
		Write-Host "Purging Kerberos Tickets: KList purge"
		Start-Process "KList" "purge"
		Time-Stamp
		Write-Host "Resetting NetBIOS over TCPIP Statistics: NBTStat -R"
		Start-Process "NBTStat" "-R"
		Time-Stamp
		Write-Host "Resetting Winsock catalog: ​netsh winsock reset"
		Start-Process "netsh" "winsock reset"
		sleep 2
		Write-Host "Restarting: $env:COMPUTERNAME"
		Shutdown /r /t 15
	}
}
Clear-SCOMCache -Servers MS1.contoso.com, MS2.contoso.com, Agent1.contoso.com, Agent2.contoso.com