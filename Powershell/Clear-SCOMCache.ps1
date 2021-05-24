<#
	.SYNOPSIS
	Clear-SCOMCache

	.DESCRIPTION
	The script clears the SCOM cache, Flushing DNS, Purging Kerberos Tickets, Resetting NetBIOS over TCPIP Statistics, and Resetting Winsock catalog. And reboots the server(s) if -Reboot switch is present.

	.PARAMETER Servers
	Each Server you want to Clear SCOM Cache on.

	.PARAMETER Reboot
	Optionally reboot the server after stopping the SCOM Services and clearing SCOM Cache. 

	.EXAMPLE
	Clear SCOM cache and reboot the 2 Servers specified.
		PS C:\> .\Clear-SCOMCache.ps1 -Servers MS1.contoso.com, MS2.contoso.com -Reboot

	Clear SCOM cache on every Management Server in Management Group.
		PS C:\> Get-SCOMManagementServer | %{.\Clear-SCOMCache.ps1 -Servers $_}

	Clear SCOM cache on every Agent in the in Management Group.
		PS C:\> Get-SCOMAgent | %{.\Clear-SCOMCache.ps1 -Servers $_}

	.AUTHOR
	Blake Drumm (v-bldrum@microsoft.com)

	.MODIFIED
	May 24th, 2021
#>
param
(
	[Parameter(Mandatory = $false,
			   Position = 1,
			   ValueFromPipeline)]
	[Array]$Servers,
	[Parameter(Mandatory = $false,
			   Position = 2)]
	[Switch]$Reboot
)

if ($Servers -match 'Microsoft.EnterpriseManagement.Administration.ManagementServer')
{
	$Servers = $Servers.DisplayName
}
elseif ($Servers -match 'Microsoft.EnterpriseManagement.Administration.AgentManagedComputer')
{
    $Servers = $Servers.DisplayName
}


Write-Host '===================================================================' -ForegroundColor DarkYellow
Write-Host '==========================  Start of Script =======================' -ForegroundColor DarkYellow
Write-Host '===================================================================' -ForegroundColor DarkYellow

$checkingpermission = "Checking for elevated permissions..."
$scriptout += $checkingpermission
Write-Host $checkingpermission -ForegroundColor Gray
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator"))
{
	$currentPath = $myinvocation.mycommand.definition
	$nopermission = "Insufficient permissions to run this script. Attempting to open the PowerShell script ($currentPath) as administrator."
	$scriptout += $nopermission
	Write-Warning $nopermission
	# We are not running "as Administrator" - so relaunch as administrator
	# ($MyInvocation.Line -split '\.ps1[\s\''\"]\s*', 2)[-1]
	Start-Process powershell.exe "-File", ('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
	break
}
else
{
	$permissiongranted = " Currently running as administrator - proceeding with script execution..."
	Write-Host $permissiongranted -ForegroundColor Green
}

Function Clear-SCOMCache
{
	param
	(
		[Parameter(Mandatory = $false,
				   Position = 1)]
		[Array]$Servers,
		[Parameter(Mandatory = $false,
				   Position = 2)]
		[Switch]$Reboot
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
			if ($Reboot)
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
					sleep 10
					$omsdk = (Get-WmiObject win32_service | ?{ $_.Name -eq 'omsdk' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
					$cshost = (Get-WmiObject win32_service | ?{ $_.Name -eq 'cshost' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
					$healthservice = (Get-WmiObject win32_service | ?{ $_.Name -eq 'healthservice' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
					$apm = (Get-WmiObject win32_service | ?{ $_.Name -eq 'System Center Management APM' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
					$auditforwarding = (Get-WmiObject win32_service -ErrorAction SilentlyContinue | ?{ $_.Name -eq 'AdtAgent' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path -ErrorAction SilentlyContinue
					if ($omsdk)
					{
						$omsdkStatus = (Get-Service -Name omsdk).Status
						if ($omsdkStatus -eq "Running")
						{
							Time-Stamp
							Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'omsdk').DisplayName)
							Stop-Service omsdk
						}
						else
						{
							Time-Stamp
							Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'omsdk').DisplayName) -NoNewline
							Write-Host "$omsdkStatus" -ForegroundColor Yellow
						}
						
					}
					if ($cshost)
					{
						$cshostStatus = (Get-Service -Name cshost).Status
						if ($cshostStatus -eq "Running")
						{
							Time-Stamp
							Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'cshost').DisplayName)
							Stop-Service cshost
						}
						else
						{
							Time-Stamp
							Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'cshost').DisplayName) -NoNewline
							Write-Host "$cshostStatus" -ForegroundColor Yellow
						}
					}
					if ($apm)
					{
						$apmStatus = (Get-Service -Name 'System Center Management APM').Status
						$apmStartType = (Get-Service -Name 'System Center Management APM').StartType
						if ($apmStatus -eq "Running")
						{
							Time-Stamp
							Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'System Center Management APM').DisplayName)
							Stop-Service 'System Center Management APM'
						}
						elseif ($apmStartType -eq 'Disabled')
						{
							$apm = $null
						}
						else
						{
							Time-Stamp
							Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'System Center Management APM').DisplayName) -NoNewline
							Write-Host "$apmStatus" -ForegroundColor Yellow
						}
					}
					if ($auditforwarding)
					{
						$auditforwardingstatus = (Get-Service -Name 'AdtAgent').Status
						$auditforwardingStartType = (Get-Service -Name 'System Center Management APM').StartType
						if ($auditforwardingstatus -eq "Running")
						{
							Time-Stamp
							Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'AdtAgent').DisplayName)
							Stop-Service AdtAgent
						}
						elseif ($auditforwardingStartType -eq 'Disabled')
						{
							$auditforwarding = $null
						}
						else
						{
							Time-Stamp
							Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'AdtAgent').DisplayName) -NoNewline
							Write-Host "$auditforwardingstatus" -ForegroundColor Yellow
						}
					}
					if ($healthservice)
					{
						$healthserviceStatus = (Get-Service -Name healthservice).Status
						if ($healthserviceStatus -eq "Running")
						{
							Time-Stamp
							Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'healthservice').DisplayName)
							Stop-Service healthservice
						}
						else
						{
							Time-Stamp
							Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'healthservice').DisplayName) -NoNewline
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
			        # Clear Console Cache
                    $consoleKey = Get-Item 'HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Console\' -ErrorAction SilentlyContinue
                    if($consoleKey)
                    {
			        try { Time-Stamp; Write-Host "Clearing Operations Manager Console Cache."; Get-ChildItem "$env:SystemDrive\Users\*\AppData\Local\Microsoft\Microsoft.EnterpriseManagement.Monitoring.Console\momcache.mdb" | % { Remove-Item $_ -Force -ErrorAction Stop }
                    }
			        catch { Write-Warning $_ }
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
			else
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
					sleep 10
					$omsdk = (Get-WmiObject win32_service | ?{ $_.Name -eq 'omsdk' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
					$cshost = (Get-WmiObject win32_service | ?{ $_.Name -eq 'cshost' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
					$healthservice = (Get-WmiObject win32_service | ?{ $_.Name -eq 'healthservice' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
					$apm = (Get-WmiObject win32_service | ?{ $_.Name -eq 'System Center Management APM' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
					$auditforwarding = (Get-WmiObject win32_service -ErrorAction SilentlyContinue | ?{ $_.Name -eq 'AdtAgent' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path -ErrorAction SilentlyContinue
					if ($omsdk)
					{
						$omsdkStatus = (Get-Service -Name omsdk).Status
						if ($omsdkStatus -eq "Running")
						{
							Time-Stamp
							Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'omsdk').DisplayName)
							Stop-Service omsdk
						}
						else
						{
							Time-Stamp
							Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'omsdk').DisplayName) -NoNewline
							Write-Host "$omsdkStatus" -ForegroundColor Yellow
						}
						
					}
					if ($cshost)
					{
						$cshostStatus = (Get-Service -Name cshost).Status
						if ($cshostStatus -eq "Running")
						{
							Time-Stamp
							Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'cshost').DisplayName)
							Stop-Service cshost
						}
						else
						{
							Time-Stamp
							Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'cshost').DisplayName) -NoNewline
							Write-Host "$cshostStatus" -ForegroundColor Yellow
						}
					}
					if ($apm)
					{
						$apmStatus = (Get-Service -Name 'System Center Management APM').Status
						$apmStartType = (Get-Service -Name 'System Center Management APM').StartType
						if ($apmStatus -eq "Running")
						{
							Time-Stamp
							Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'System Center Management APM').DisplayName)
							Stop-Service 'System Center Management APM'
						}
						elseif ($apmStartType -eq 'Disabled')
						{
							$apm = $null
						}
						else
						{
							Time-Stamp
							Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'System Center Management APM').DisplayName) -NoNewline
							Write-Host "$apmStatus" -ForegroundColor Yellow
						}
					}
					if ($auditforwarding)
					{
						$auditforwardingstatus = (Get-Service -Name 'AdtAgent').Status
						$auditforwardingStartType = (Get-Service -Name 'System Center Management APM').StartType
						if ($auditforwardingstatus -eq "Running")
						{
							Time-Stamp
							Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'AdtAgent').DisplayName)
							Stop-Service AdtAgent
						}
						elseif ($auditforwardingStartType -eq 'Disabled')
						{
							$auditforwarding = $null
						}
						else
						{
							Time-Stamp
							Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'AdtAgent').DisplayName) -NoNewline
							Write-Host "$auditforwardingstatus" -ForegroundColor Yellow
						}
					}
					if ($healthservice)
					{
						$healthserviceStatus = (Get-Service -Name healthservice).Status
						if ($healthserviceStatus -eq "Running")
						{
							Time-Stamp
							Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'healthservice').DisplayName)
							Stop-Service healthservice
						}
						else
						{
							Time-Stamp
							Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'healthservice').DisplayName) -NoNewline
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
			        # Clear Console Cache
                    $consoleKey = Get-Item 'HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Console\' -ErrorAction SilentlyContinue
                    if($consoleKey)
                    {
			        try { Time-Stamp; Write-Host "Clearing Operations Manager Console Cache."; Get-ChildItem "$env:SystemDrive\Users\*\AppData\Local\Microsoft\Microsoft.EnterpriseManagement.Monitoring.Console\momcache.mdb" | % { Remove-Item $_ -Force -ErrorAction Stop }
                    }
			        catch { Write-Warning $_ }
                    }
				
					
					Time-Stamp
					Write-Host "Flushing DNS: " -NoNewline
					Write-Host "IPConfig /FlushDNS" -ForegroundColor Cyan
					Start-Process "IPConfig" "/FlushDNS"
					Time-Stamp
					Write-Host "Resetting NetBIOS over TCPIP Statistics: " -NoNewline
					Write-Host 'NBTStat -R' -ForegroundColor Cyan
					Start-Process "NBTStat" "-R"
					if ($healthservice)
					{
						Time-Stamp
						Write-Host ("Starting `'{0}`' Service" -f (Get-Service -Name 'healthservice').DisplayName)
						Start-Service 'healthservice'
					}
					if ($omsdk)
					{
						Time-Stamp
						Write-Host ("Starting `'{0}`' Service" -f (Get-Service -Name 'omsdk').DisplayName)
						Start-Service 'omsdk'
					}
					if ($cshost)
					{
						Time-Stamp
						Write-Host ("Starting `'{0}`' Service" -f (Get-Service -Name 'cshost').DisplayName)
						Start-Service 'cshost'
					}
					if ($apm)
					{
						Time-Stamp
						Write-Host ("Starting `'{0}`' Service" -f (Get-Service -Name 'System Center Management APM').DisplayName)
						Start-Service 'System Center Management APM'
					}
					if ($auditforwarding)
					{
						Time-Stamp
						Write-Host ("Starting `'{0}`' Service" -f (Get-Service -Name 'AdtAgent').DisplayName)
						Start-Service 'AdtAgent'
					}
				}
			}
			
		}
		if ($containslocal -eq $true)
		{
			if ($Reboot)
			{
				Function Time-Stamp
				{
					$TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
					write-host "$TimeStamp - " -NoNewline
				}
				Time-Stamp
				Write-Host "Starting Script Execution on: " -NoNewline
				Write-Host "$env:ComputerName (Local Computer)" -ForegroundColor Cyan
				sleep 10
				$omsdk = (Get-WmiObject win32_service | ?{ $_.Name -eq 'omsdk' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
				$cshost = (Get-WmiObject win32_service | ?{ $_.Name -eq 'cshost' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
				$healthservice = (Get-WmiObject win32_service | ?{ $_.Name -eq 'healthservice' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
				$apm = (Get-WmiObject win32_service | ?{ $_.Name -eq 'System Center Management APM' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
				$auditforwarding = (Get-WmiObject win32_service -ErrorAction SilentlyContinue | ?{ $_.Name -eq 'AdtAgent' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path -ErrorAction SilentlyContinue
				if ($omsdk)
				{
					$omsdkStatus = (Get-Service -Name omsdk).Status
					if ($omsdkStatus -eq "Running")
					{
						Time-Stamp
						Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'omsdk').DisplayName)
						Stop-Service omsdk
					}
					else
					{
						Time-Stamp
						Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'omsdk').DisplayName) -NoNewline
						Write-Host "$omsdkStatus" -ForegroundColor Yellow
					}
					
				}
				if ($cshost)
				{
					$cshostStatus = (Get-Service -Name cshost).Status
					if ($cshostStatus -eq "Running")
					{
						Time-Stamp
						Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'cshost').DisplayName)
						Stop-Service cshost
					}
					else
					{
						Time-Stamp
						Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'cshost').DisplayName) -NoNewline
						Write-Host "$cshostStatus" -ForegroundColor Yellow
					}
				}
				if ($apm)
				{
					$apmStatus = (Get-Service -Name 'System Center Management APM').Status
					$apmStartType = (Get-Service -Name 'System Center Management APM').StartType
					if ($apmStatus -eq "Running")
					{
						Time-Stamp
						Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'System Center Management APM').DisplayName)
						Stop-Service 'System Center Management APM'
					}
					elseif ($apmStartType -eq 'Disabled')
					{
						$apm = $null
					}
					else
					{
						Time-Stamp
						Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'System Center Management APM').DisplayName) -NoNewline
						Write-Host "$apmStatus" -ForegroundColor Yellow
					}
				}
				if ($auditforwarding)
				{
					$auditforwardingstatus = (Get-Service -Name 'AdtAgent').Status
					$auditforwardingStartType = (Get-Service -Name 'System Center Management APM').StartType
					if ($auditforwardingstatus -eq "Running")
					{
						Time-Stamp
						Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'AdtAgent').DisplayName)
						Stop-Service AdtAgent
					}
					elseif ($auditforwardingStartType -eq 'Disabled')
					{
						$auditforwarding = $null
					}
					else
					{
						Time-Stamp
						Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'AdtAgent').DisplayName) -NoNewline
						Write-Host "$auditforwardingstatus" -ForegroundColor Yellow
					}
				}
				if ($healthservice)
				{
					$healthserviceStatus = (Get-Service -Name healthservice).Status
					if ($healthserviceStatus -eq "Running")
					{
						Time-Stamp
						Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'healthservice').DisplayName)
						Stop-Service healthservice
					}
					else
					{
						Time-Stamp
						Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'healthservice').DisplayName) -NoNewline
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
				sleep 10
				$omsdk = (Get-WmiObject win32_service | ?{ $_.Name -eq 'omsdk' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
				$cshost = (Get-WmiObject win32_service | ?{ $_.Name -eq 'cshost' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
				$healthservice = (Get-WmiObject win32_service | ?{ $_.Name -eq 'healthservice' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
				$apm = (Get-WmiObject win32_service | ?{ $_.Name -eq 'System Center Management APM' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
				$auditforwarding = (Get-WmiObject win32_service -ErrorAction SilentlyContinue | ?{ $_.Name -eq 'AdtAgent' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path -ErrorAction SilentlyContinue
				if ($omsdk)
				{
					$omsdkStatus = (Get-Service -Name omsdk).Status
					if ($omsdkStatus -eq "Running")
					{
						Time-Stamp
						Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'omsdk').DisplayName)
						Stop-Service omsdk
					}
					else
					{
						Time-Stamp
						Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'omsdk').DisplayName) -NoNewline
						Write-Host "$omsdkStatus" -ForegroundColor Yellow
					}
					
				}
				if ($cshost)
				{
					$cshostStatus = (Get-Service -Name cshost).Status
					if ($cshostStatus -eq "Running")
					{
						Time-Stamp
						Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'cshost').DisplayName)
						Stop-Service cshost
					}
					else
					{
						Time-Stamp
						Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'cshost').DisplayName) -NoNewline
						Write-Host "$cshostStatus" -ForegroundColor Yellow
					}
				}
				if ($apm)
				{
					$apmStatus = (Get-Service -Name 'System Center Management APM').Status
					$apmStartType = (Get-Service -Name 'System Center Management APM').StartType
					if ($apmStatus -eq "Running")
					{
						Time-Stamp
						Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'System Center Management APM').DisplayName)
						Stop-Service 'System Center Management APM'
					}
					elseif ($apmStartType -eq 'Disabled')
					{
						$apm = $null
					}
					else
					{
						Time-Stamp
						Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'System Center Management APM').DisplayName) -NoNewline
						Write-Host "$apmStatus" -ForegroundColor Yellow
					}
				}
				if ($auditforwarding)
				{
					$auditforwardingstatus = (Get-Service -Name 'AdtAgent').Status
					$auditforwardingStartType = (Get-Service -Name 'System Center Management APM').StartType
					if ($auditforwardingstatus -eq "Running")
					{
						Time-Stamp
						Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'AdtAgent').DisplayName)
						Stop-Service AdtAgent
					}
					elseif ($auditforwardingStartType -eq 'Disabled')
					{
						$auditforwarding = $null
					}
					else
					{
						Time-Stamp
						Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'AdtAgent').DisplayName) -NoNewline
						Write-Host "$auditforwardingstatus" -ForegroundColor Yellow
					}
				}
				if ($healthservice)
				{
					$healthserviceStatus = (Get-Service -Name healthservice).Status
					if ($healthserviceStatus -eq "Running")
					{
						Time-Stamp
						Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'healthservice').DisplayName)
						Stop-Service healthservice
					}
					else
					{
						Time-Stamp
						Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'healthservice').DisplayName) -NoNewline
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
			    # Clear Console Cache
                $consoleKey = Get-Item 'HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Console\' -ErrorAction SilentlyContinue
                if($consoleKey)
                {
			    try { Time-Stamp; Write-Host "Clearing Operations Manager Console Cache."; Get-ChildItem "$env:SystemDrive\Users\*\AppData\Local\Microsoft\Microsoft.EnterpriseManagement.Monitoring.Console\momcache.mdb" | % { Remove-Item $_ -Force -ErrorAction Stop }
                }
			    catch { Write-Warning $_ }
                }
				
				Time-Stamp
				Write-Host "Flushing DNS: " -NoNewline
				Write-Host "IPConfig /FlushDNS" -ForegroundColor Cyan
				Start-Process "IPConfig" "/FlushDNS"
				Time-Stamp
				Write-Host "Resetting NetBIOS over TCPIP Statistics: " -NoNewline
				Write-Host 'NBTStat -R' -ForegroundColor Cyan
				Start-Process "NBTStat" "-R"
				if ($healthservice)
				{
					Time-Stamp
					Write-Host ("Starting `'{0}`' Service" -f (Get-Service -Name 'healthservice').DisplayName)
					Start-Service 'healthservice'
				}
				if ($omsdk)
				{
					Time-Stamp
					Write-Host ("Starting `'{0}`' Service" -f (Get-Service -Name 'omsdk').DisplayName)
					Start-Service 'omsdk'
				}
				if ($cshost)
				{
					Time-Stamp
					Write-Host ("Starting `'{0}`' Service" -f (Get-Service -Name 'cshost').DisplayName)
					Start-Service 'cshost'
				}
				if ($apm)
				{
					Time-Stamp
					Write-Host ("Starting `'{0}`' Service" -f (Get-Service -Name 'System Center Management APM').DisplayName)
					Start-Service 'System Center Management APM'
				}
				if ($auditforwarding)
				{
					Time-Stamp
					Write-Host ("Starting `'{0}`' Service" -f (Get-Service -Name 'AdtAgent').DisplayName)
					Start-Service 'AdtAgent'
				}
			}
		}
		
	}
	else
	{
		Function Time-Stamp
		{
			$TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
			write-host "$TimeStamp - " -NoNewline
		}
		if ($Reboot)
		{
			Function Time-Stamp
			{
				$TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
				write-host "$TimeStamp - " -NoNewline
			}
			Time-Stamp
			Write-Host "Starting Script Execution on: " -NoNewline
			Write-Host "$env:ComputerName (Local Computer)" -ForegroundColor Cyan
			sleep 10
			$omsdk = (Get-WmiObject win32_service | ?{ $_.Name -eq 'omsdk' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
			$cshost = (Get-WmiObject win32_service | ?{ $_.Name -eq 'cshost' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
			$healthservice = (Get-WmiObject win32_service | ?{ $_.Name -eq 'healthservice' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
			$apm = (Get-WmiObject win32_service | ?{ $_.Name -eq 'System Center Management APM' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
			$auditforwarding = (Get-WmiObject win32_service -ErrorAction SilentlyContinue | ?{ $_.Name -eq 'AdtAgent' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path -ErrorAction SilentlyContinue
			if ($omsdk)
			{
				$omsdkStatus = (Get-Service -Name omsdk).Status
				if ($omsdkStatus -eq "Running")
				{
					Time-Stamp
					Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'omsdk').DisplayName)
					Stop-Service omsdk
				}
				else
				{
					Time-Stamp
					Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'omsdk').DisplayName) -NoNewline
					Write-Host "$omsdkStatus" -ForegroundColor Yellow
				}
				
			}
			if ($cshost)
			{
				$cshostStatus = (Get-Service -Name cshost).Status
				if ($cshostStatus -eq "Running")
				{
					Time-Stamp
					Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'cshost').DisplayName)
					Stop-Service cshost
				}
				else
				{
					Time-Stamp
					Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'cshost').DisplayName) -NoNewline
					Write-Host "$cshostStatus" -ForegroundColor Yellow
				}
			}
			if ($apm)
			{
				$apmStatus = (Get-Service -Name 'System Center Management APM').Status
				$apmStartType = (Get-Service -Name 'System Center Management APM').StartType
				if ($apmStatus -eq "Running")
				{
					Time-Stamp
					Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'System Center Management APM').DisplayName)
					Stop-Service 'System Center Management APM'
				}
				elseif ($apmStartType -eq 'Disabled')
				{
					$apm = $null
				}
				else
				{
					Time-Stamp
					Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'System Center Management APM').DisplayName) -NoNewline
					Write-Host "$apmStatus" -ForegroundColor Yellow
				}
			}
			if ($auditforwarding)
			{
				$auditforwardingstatus = (Get-Service -Name 'AdtAgent').Status
				$auditforwardingStartType = (Get-Service -Name 'System Center Management APM').StartType
				if ($auditforwardingstatus -eq "Running")
				{
					Time-Stamp
					Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'AdtAgent').DisplayName)
					Stop-Service AdtAgent
				}
				elseif ($auditforwardingStartType -eq 'Disabled')
				{
					$auditforwarding = $null
				}
				else
				{
					Time-Stamp
					Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'AdtAgent').DisplayName) -NoNewline
					Write-Host "$auditforwardingstatus" -ForegroundColor Yellow
				}
			}
			if ($healthservice)
			{
				$healthserviceStatus = (Get-Service -Name healthservice).Status
				if ($healthserviceStatus -eq "Running")
				{
					Time-Stamp
					Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'healthservice').DisplayName)
					Stop-Service healthservice
				}
				else
				{
					Time-Stamp
					Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'healthservice').DisplayName) -NoNewline
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
			sleep 10
			$omsdk = (Get-WmiObject win32_service | ?{ $_.Name -eq 'omsdk' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
			$cshost = (Get-WmiObject win32_service | ?{ $_.Name -eq 'cshost' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
			$healthservice = (Get-WmiObject win32_service | ?{ $_.Name -eq 'healthservice' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
			$apm = (Get-WmiObject win32_service | ?{ $_.Name -eq 'System Center Management APM' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path
			$auditforwarding = (Get-WmiObject win32_service -ErrorAction SilentlyContinue | ?{ $_.Name -eq 'AdtAgent' } | select PathName -ExpandProperty PathName | % { $_.Split('"')[1] }) | Split-Path -ErrorAction SilentlyContinue
			if ($omsdk)
			{
				$omsdkStatus = (Get-Service -Name omsdk).Status
				if ($omsdkStatus -eq "Running")
				{
					Time-Stamp
					Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'omsdk').DisplayName)
					Stop-Service omsdk
				}
				else
				{
					Time-Stamp
					Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'omsdk').DisplayName) -NoNewline
					Write-Host "$omsdkStatus" -ForegroundColor Yellow
				}
				
			}
			if ($cshost)
			{
				$cshostStatus = (Get-Service -Name cshost).Status
				if ($cshostStatus -eq "Running")
				{
					Time-Stamp
					Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'cshost').DisplayName)
					Stop-Service cshost
				}
				else
				{
					Time-Stamp
					Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'cshost').DisplayName) -NoNewline
					Write-Host "$cshostStatus" -ForegroundColor Yellow
				}
			}
			if ($apm)
			{
				$apmStatus = (Get-Service -Name 'System Center Management APM').Status
				$apmStartType = (Get-Service -Name 'System Center Management APM').StartType
				if ($apmStatus -eq "Running")
				{
					Time-Stamp
					Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'System Center Management APM').DisplayName)
					Stop-Service 'System Center Management APM'
				}
				elseif ($apmStartType -eq 'Disabled')
				{
					$apm = $null
				}
				else
				{
					Time-Stamp
					Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'System Center Management APM').DisplayName) -NoNewline
					Write-Host "$apmStatus" -ForegroundColor Yellow
				}
			}
			if ($auditforwarding)
			{
				$auditforwardingstatus = (Get-Service -Name 'AdtAgent').Status
				$auditforwardingStartType = (Get-Service -Name 'System Center Management APM').StartType
				if ($auditforwardingstatus -eq "Running")
				{
					Time-Stamp
					Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'AdtAgent').DisplayName)
					Stop-Service AdtAgent
				}
				elseif ($auditforwardingStartType -eq 'Disabled')
				{
					$auditforwarding = $null
				}
				else
				{
					Time-Stamp
					Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'AdtAgent').DisplayName) -NoNewline
					Write-Host "$auditforwardingstatus" -ForegroundColor Yellow
				}
			}
			if ($healthservice)
			{
				$healthserviceStatus = (Get-Service -Name healthservice).Status
				if ($healthserviceStatus -eq "Running")
				{
					Time-Stamp
					Write-Host ("Stopping `'{0}`' Service" -f (Get-Service -Name 'healthservice').DisplayName)
					Stop-Service healthservice
				}
				else
				{
					Time-Stamp
					Write-Host ("[Warning] :: Status of `'{0}`' Service - " -f (Get-Service -Name 'healthservice').DisplayName) -NoNewline
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
			# Clear Console Cache
            $consoleKey = Get-Item 'HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Console\' -ErrorAction SilentlyContinue
            if($consoleKey)
            {
			try { Time-Stamp; Write-Host "Clearing Operations Manager Console Cache."; Get-ChildItem "$env:SystemDrive\Users\*\AppData\Local\Microsoft\Microsoft.EnterpriseManagement.Monitoring.Console\momcache.mdb" | % { Remove-Item $_ -Force -ErrorAction Stop }
            }
			catch { Write-Warning $_ }
            }
			Time-Stamp
			Write-Host "Flushing DNS: " -NoNewline
			Write-Host "IPConfig /FlushDNS" -ForegroundColor Cyan
			Start-Process "IPConfig" "/FlushDNS"
			Time-Stamp
			Write-Host "Resetting NetBIOS over TCPIP Statistics: " -NoNewline
			Write-Host 'NBTStat -R' -ForegroundColor Cyan
			Start-Process "NBTStat" "-R"
			if ($healthservice)
			{
				Time-Stamp
				Write-Host ("Starting `'{0}`' Service" -f (Get-Service -Name 'healthservice').DisplayName)
				Start-Service 'healthservice'
			}
			if ($omsdk)
			{
				Time-Stamp
				Write-Host ("Starting `'{0}`' Service" -f (Get-Service -Name 'omsdk').DisplayName)
				Start-Service 'omsdk'
			}
			if ($cshost)
			{
				Time-Stamp
				Write-Host ("Starting `'{0}`' Service" -f (Get-Service -Name 'cshost').DisplayName)
				Start-Service 'cshost'
			}
			if ($apm)
			{
				Time-Stamp
				Write-Host ("Starting `'{0}`' Service" -f (Get-Service -Name 'System Center Management APM').DisplayName)
				Start-Service 'System Center Management APM'
			}
			if ($auditforwarding)
			{
				Time-Stamp
				Write-Host ("Starting `'{0}`' Service" -f (Get-Service -Name 'AdtAgent').DisplayName)
				Start-Service 'AdtAgent'
			}
		}
		
	}
}
if ($Servers -or $Reboot)
{
	Clear-SCOMCache -Servers $Servers -Reboot:$Reboot
}
else
{
<# Edit line 1388 to modify the default command run when this script is executed.

   Example: 
   Clear-SCOMCache -Servers Agent1.contoso.com, Agent2.contoso.com, MS1.contoso.com, MS2.contoso.com
   #>
	Clear-SCOMCache
}
