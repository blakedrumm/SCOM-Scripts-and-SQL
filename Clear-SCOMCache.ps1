param
(
	[Parameter(Position = 1)]
	[Array]$Servers
)

Write-Host '===================================================================' -ForegroundColor DarkYellow
Write-Host '==========================  Start of Script =======================' -ForegroundColor DarkYellow
Write-Host '===================================================================' -ForegroundColor DarkYellow


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
				Write-Host "Starting Script Execution on: " -NoNewline
				Write-Host "$currentserv" -ForegroundColor Cyan
				$omsdk = (Get-WmiObject win32_service | ?{ $_.Name -like 'omsdk' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
				$cshost = (Get-WmiObject win32_service | ?{ $_.Name -like 'cshost' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
				$healthservice = (Get-WmiObject win32_service | ?{ $_.Name -like 'healthservice' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
				if ($omsdk)
				{
					$omsdkStatus = (Get-Service -Name omsdk).Status
					if ($omsdkStatus -eq "Running")
					{
						Time-Stamp
						Write-Host "Stopping `'omsdk`' Service"
						Stop-Service omsdk
					}
					else
					{
						Time-Stamp
						Write-Host "[Warning] :: Status of `'omsdk`' Service - " -NoNewline
						Write-Host "$omsdkStatus" -ForegroundColor Yellow
					}
					
				}
				if ($cshost)
				{
					$cshostStatus = (Get-Service -Name cshost).Status
					if ($cshostStatus -eq "Running")
					{
						Time-Stamp
						Write-Host "Stopping `'cshost`' Service"
						Stop-Service cshost
					}
					else
					{
						Time-Stamp
						Write-Host "[Warning] :: Status of `'cshost`' Service - " -NoNewline
						Write-Host "$cshostStatus" -ForegroundColor Yellow
					}
				}
				if ($healthservice)
				{
					$healthserviceStatus = (Get-Service -Name healthservice).Status
					if ($healthserviceStatus -eq "Running")
					{
						Time-Stamp
						Write-Host "Stopping `'healthservice`' Service"
						Stop-Service healthservice
					}
					else
					{
						Time-Stamp
						Write-Host "[Warning] :: Status of `'healthservice`' Service - " -NoNewline
						Write-Host "$healthserviceStatus" -ForegroundColor Yellow
					}
					try
					{
						Time-Stamp
						Write-Host "Attempting to Move Folder from: `"$healthservice`\Health Service State`" to `"$healthservice\Health Service State.old`" "
						Move-Item "$healthservice\Health Service State" "$healthservice\Health Service State.old" -ErrorAction Stop
						Time-Stamp
						Write-Host "Moved Folder Successfully" -ForegroundColor Green
					}
					catch
					{
						Time-Stamp
						Write-Host "[Warning] :: " -NoNewline
						Write-Host "$_" -ForegroundColor Yellow
						Time-Stamp
						Write-Host "Attempting to Delete Folder: `"$healthservice`\Health Service State`" "
						try
						{
							rd "$healthservice\Health Service State" -Recurse -ErrorAction Stop
							Time-Stamp
							Write-Host "Deleted Folder Successfully" -ForegroundColor Green
						}
						catch
						{
							$healthservice = $null
						}
					}
					
				}
				if ($null -eq $omsdk -and $cshost -and $healthservice)
				{
					Time-Stamp
					try
					{
						$installdir = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup" -ErrorAction Stop | Select-Object -Property "InstallDirectory" -ExpandProperty "InstallDirectory"
						try
						{
							Time-Stamp
							Write-Host "Attempting to Move Folder from: `"$installdir`\Health Service State`" to `"$installdir\Health Service State.old`" "
							Move-Item "$installdir\Health Service State" "$installdir\Health Service State.old" -ErrorAction Stop
							Time-Stamp
							Write-Host "Moved Folder Successfully" -ForegroundColor Green
						}
						catch
						{
							Time-Stamp
							Write-Host "[Warning] :: " -NoNewline
							Write-Host "$_" -ForegroundColor Yellow
							Time-Stamp
							Write-Host "Attempting to Delete Folder: `"$installdir`\Health Service State`" "
							try
							{
								rd "$installdir\Health Service State" -Recurse -ErrorAction Stop
								Time-Stamp
								Write-Host "Deleted Folder Successfully" -ForegroundColor Green
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
						break
					}
				}
				Time-Stamp
				Write-Host "Flushing DNS: " -NoNewline
				Write-Host "IPConfig /FlushDNS" -ForegroundColor Cyan
				Start-Process "IPConfig" "/FlushDNS"
				Time-Stamp
				Write-Host "Purging Kerberos Tickets: " -NoNewline
				Write-Host 'KList -li 0x3e7 purge' -ForegroundColor Cyan
				Start-Process "KList" "-li 0x3e7 purge"
				Time-Stamp
				Write-Host "Resetting NetBIOS over TCPIP Statistics: " -NoNewline
				Write-Host 'NBTStat -R' -ForegroundColor Cyan
				Start-Process "NBTStat" "-R"
				Time-Stamp
				Write-Host "Resetting Winsock catalog: " -NoNewline
				Write-Host '​netsh winsock reset' -ForegroundColor Cyan
				Start-Process "netsh" "winsock reset"
				sleep 2
				Time-Stamp
				Write-Host "Restarting: " -NoNewLine
				Write-Host "$env:COMPUTERNAME" -ForegroundColor Green
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
			$omsdk = (Get-WmiObject win32_service | ?{ $_.Name -like 'omsdk' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
			$cshost = (Get-WmiObject win32_service | ?{ $_.Name -like 'cshost' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
			$healthservice = (Get-WmiObject win32_service | ?{ $_.Name -like 'healthservice' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
			if ($omsdk)
			{
				$omsdkStatus = (Get-Service -Name omsdk).Status
				if ($omsdkStatus -eq "Running")
				{
					Time-Stamp
					Write-Host "Stopping `'omsdk`' Service"
					Stop-Service omsdk
				}
				else
				{
					Time-Stamp
					Write-Host "[Warning] :: Status of `'omsdk`' Service - " -NoNewline
					Write-Host "$omsdkStatus" -ForegroundColor Yellow
				}
				
			}
			if ($cshost)
			{
				$cshostStatus = (Get-Service -Name cshost).Status
				if ($cshostStatus -eq "Running")
				{
					Time-Stamp
					Write-Host "Stopping `'cshost`' Service"
					Stop-Service cshost
				}
				else
				{
					Time-Stamp
					Write-Host "[Warning] :: Status of `'cshost`' Service - " -NoNewline
					Write-Host "$cshostStatus" -ForegroundColor Yellow
				}
			}
			if ($healthservice)
			{
				$healthserviceStatus = (Get-Service -Name healthservice).Status
				if ($healthserviceStatus -eq "Running")
				{
					Time-Stamp
					Write-Host "Stopping `'healthservice`' Service"
					Stop-Service healthservice
				}
				else
				{
					Time-Stamp
					Write-Host "[Warning] :: Status of `'healthservice`' Service - " -NoNewline
					Write-Host "$healthserviceStatus" -ForegroundColor Yellow
				}
				try
				{
					Time-Stamp
					Write-Host "Attempting to Move Folder from: `"$healthservice`\Health Service State`" to `"$healthservice\Health Service State.old`" "
					Move-Item "$healthservice\Health Service State" "$healthservice\Health Service State.old" -ErrorAction Stop
					Time-Stamp
					Write-Host "Moved Folder Successfully" -ForegroundColor Green
				}
				catch
				{
					Time-Stamp
					Write-Host "[Warning] :: " -NoNewline
					Write-Host "$_" -ForegroundColor Yellow
					Time-Stamp
					Write-Host "Attempting to Delete Folder: `"$healthservice`\Health Service State`" "
					try
					{
						rd "$healthservice\Health Service State" -Recurse -ErrorAction Stop
						Time-Stamp
						Write-Host "Deleted Folder Successfully" -ForegroundColor Green
					}
					catch
					{
						$healthservice = $null
					}
				}
				
			}
			if ($null -eq $omsdk -and $cshost -and $healthservice)
			{
				Time-Stamp
				try
				{
					$installdir = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup" -ErrorAction Stop | Select-Object -Property "InstallDirectory" -ExpandProperty "InstallDirectory"
					try
					{
						Time-Stamp
						Write-Host "Attempting to Move Folder from: `"$installdir`\Health Service State`" to `"$installdir\Health Service State.old`" "
						Move-Item "$installdir\Health Service State" "$installdir\Health Service State.old" -ErrorAction Stop
						Time-Stamp
						Write-Host "Moved Folder Successfully" -ForegroundColor Green
					}
					catch
					{
						Time-Stamp
						Write-Host "[Warning] :: " -NoNewline
						Write-Host "$_" -ForegroundColor Yellow
						Time-Stamp
						Write-Host "Attempting to Delete Folder: `"$installdir`\Health Service State`" "
						try
						{
							rd "$installdir\Health Service State" -Recurse -ErrorAction Stop
							Time-Stamp
							Write-Host "Deleted Folder Successfully" -ForegroundColor Green
						}
						catch
						{
							Time-Stamp
							Write-Warning $_
						}
					}
				}
				catch
				{
					Time-Stamp
					Write-Warning "Unable to locate the Install Directory`nHKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup"
					break
				}
			}
			Time-Stamp
			Write-Host "Flushing DNS: " -NoNewline
			Write-Host "IPConfig /FlushDNS" -ForegroundColor Cyan
			Start-Process "IPConfig" "/FlushDNS"
			Time-Stamp
			Write-Host "Purging Kerberos Tickets: " -NoNewline
			Write-Host 'KList -li 0x3e7 purge' -ForegroundColor Cyan
			Start-Process "KList" "-li 0x3e7 purge"
			Time-Stamp
			Write-Host "Resetting NetBIOS over TCPIP Statistics: " -NoNewline
			Write-Host 'NBTStat -R' -ForegroundColor Cyan
			Start-Process "NBTStat" "-R"
			Time-Stamp
			Write-Host "Resetting Winsock catalog: " -NoNewline
			Write-Host '​netsh winsock reset' -ForegroundColor Cyan
			Start-Process "netsh" "winsock reset"
			sleep 2
			Time-Stamp
			Write-Host "Restarting: " -NoNewLine
			Write-Host "$env:COMPUTERNAME" -ForegroundColor Green
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
		Write-Host "Starting Script Execution on: " -NoNewline
		Write-Host "$env:ComputerName (Local Computer)" -ForegroundColor Cyan
		sleep 20
		$omsdk = (Get-WmiObject win32_service | ?{ $_.Name -like 'omsdk' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
		$cshost = (Get-WmiObject win32_service | ?{ $_.Name -like 'cshost' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
		$healthservice = (Get-WmiObject win32_service | ?{ $_.Name -like 'healthservice' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
		if ($omsdk)
		{
			$omsdkStatus = (Get-Service -Name omsdk).Status
			if ($omsdkStatus -eq "Running")
			{
				Time-Stamp
				Write-Host "Stopping `'omsdk`' Service"
				Stop-Service omsdk
			}
			else
			{
				Time-Stamp
				Write-Host "[Warning] :: Status of `'omsdk`' Service - " -NoNewline
				Write-Host "$omsdkStatus" -ForegroundColor Yellow
			}
			
		}
		if ($cshost)
		{
			$cshostStatus = (Get-Service -Name cshost).Status
			if ($cshostStatus -eq "Running")
			{
				Time-Stamp
				Write-Host "Stopping `'cshost`' Service"
				Stop-Service cshost
			}
			else
			{
				Time-Stamp
				Write-Host "[Warning] :: Status of `'cshost`' Service - " -NoNewline
				Write-Host "$cshostStatus" -ForegroundColor Yellow
			}
		}
		if ($healthservice)
		{
			$healthserviceStatus = (Get-Service -Name healthservice).Status
			if ($healthserviceStatus -eq "Running")
			{
				Time-Stamp
				Write-Host "Stopping `'healthservice`' Service"
				Stop-Service healthservice
			}
			else
			{
				Time-Stamp
				Write-Host "[Warning] :: Status of `'healthservice`' Service - " -NoNewline
				Write-Host "$healthserviceStatus" -ForegroundColor Yellow
			}
			try
			{
				Time-Stamp
				Write-Host "Attempting to Move Folder from: `"$healthservice`\Health Service State`" to `"$healthservice\Health Service State.old`" "
				Move-Item "$healthservice\Health Service State" "$healthservice\Health Service State.old" -ErrorAction Stop
				Time-Stamp
				Write-Host "Moved Folder Successfully" -ForegroundColor Green
			}
			catch
			{
				Time-Stamp
				Write-Host "[Warning] :: " -NoNewline
				Write-Host "$_" -ForegroundColor Yellow
				Time-Stamp
				Write-Host "Attempting to Delete Folder: `"$healthservice`\Health Service State`" "
				try
				{
					rd "$healthservice\Health Service State" -Recurse -ErrorAction Stop
					Time-Stamp
					Write-Host "Deleted Folder Successfully" -ForegroundColor Green
				}
				catch
				{
					$healthservice = $null
				}
			}
			
		}
		if ($null -eq $omsdk -and $cshost -and $healthservice)
		{
			Time-Stamp
			try
			{
				$installdir = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup" -ErrorAction Stop | Select-Object -Property "InstallDirectory" -ExpandProperty "InstallDirectory"
				try
				{
					Time-Stamp
					Write-Host "Attempting to Move Folder from: `"$installdir`\Health Service State`" to `"$installdir\Health Service State.old`" "
					Move-Item "$installdir\Health Service State" "$installdir\Health Service State.old" -ErrorAction Stop
					Time-Stamp
					Write-Host "Moved Folder Successfully" -ForegroundColor Green
				}
				catch
				{
					Time-Stamp
					Write-Host "[Warning] :: " -NoNewline
					Write-Host "$_" -ForegroundColor Yellow
					Time-Stamp
					Write-Host "Attempting to Delete Folder: `"$installdir`\Health Service State`" "
					try
					{
						rd "$installdir\Health Service State" -Recurse -ErrorAction Stop
						Time-Stamp
						Write-Host "Deleted Folder Successfully" -ForegroundColor Green
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
				break
			}
		}
		Time-Stamp
		Write-Host "Flushing DNS: " -NoNewline
		Write-Host "IPConfig /FlushDNS" -ForegroundColor Cyan
		Start-Process "IPConfig" "/FlushDNS"
		Time-Stamp
		Write-Host "Purging Kerberos Tickets: " -NoNewline
		Write-Host 'KList -li 0x3e7 purge' -ForegroundColor Cyan
		Start-Process "KList" "-li 0x3e7 purge"
		Time-Stamp
		Write-Host "Resetting NetBIOS over TCPIP Statistics: " -NoNewline
		Write-Host 'NBTStat -R' -ForegroundColor Cyan
		Start-Process "NBTStat" "-R"
		Time-Stamp
		Write-Host "Resetting Winsock catalog: " -NoNewline
		Write-Host '​netsh winsock reset' -ForegroundColor Cyan
		Start-Process "netsh" "winsock reset"
		sleep 2
		Time-Stamp
		Write-Host "Restarting: " -NoNewLine
		Write-Host "$env:COMPUTERNAME" -ForegroundColor Green
		Shutdown /r /t 15
	}
}
if ($Servers)
{
	Clear-SCOMCache -Servers:$Servers
}
else
{
	Clear-SCOMCache
}
