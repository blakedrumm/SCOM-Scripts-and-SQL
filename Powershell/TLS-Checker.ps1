Function Start-TLSChecker
{
	[CmdletBinding()]
	Param
	(
		[string[]]$Servers
	)
    $OutputPath = $OutputPath
	foreach ($server in $servers)
	{
	    Write-Host "  Checking TLS on $server`:`n" -NoNewline -ForegroundColor Gray
		if (($Comp -ne $server) -and ($global:OpsDB_SQLServer -ne $server) -and ($global:DW_SQLServer -ne $server))
		{
			Invoke-Command -ComputerName $server {
				#=================================================================================
				# 
				# Install SCOM TLS 1.2 Configuration Support Script
				#
				# This script supports SCOM 2012R2, 2016, 1801, 1807, and 2019
				#                      SQL 2008R2 through 2017
				#                      .NET 4.5 through 4.8
				#
				# Author:  Kevin Holman
				# v 1.6
				#
				# https://kevinholman.com/2018/05/06/implementing-tls-1-2-enforcement-with-scom/
				#=================================================================================
				
				
				Write-Host "   Starting SCOM TLS 1.2 Configuration Checker on $using:server" -ForegroundColor Green
			
				Write-Host "    Creating log file...." -ForegroundColor Magenta
				Start-Sleep -s 2
				$Error.Clear()
				[string]$LogPath = "C:\Windows\Temp"
				[string]$LogName = "SCOM_TLS_Config_" + $using:server + ".log"
				[string]$LogFile = $LogPath + "\" + $LogName
				IF (!(Test-Path $LogPath))
				{
					Write-Host "    ERROR: Cannot access logging directory ($LogPath).  Terminating.`n" -ForegroundColor Red
					
					
				}
				IF (!(Test-Path $LogFile))
				{
					New-Item -Path $LogPath -Name $LogName -ItemType File | Out-Null
				}
				Function LogWrite
				{
					Param ([string]$LogString)
					$LogTime = Get-Date -Format 'dd/MM/yy hh:mm:ss'
					Add-content $LogFile -value "$LogTime : $LogString"
				}
				LogWrite "*****"
				LogWrite "*****"
				LogWrite "*****"
				LogWrite "Starting SCOM TLS 1.2 Configuration script"
				IF ($Error)
				{
					LogWrite "Error occurred.  Error is: ($Error)"
				}
				
				
				###################################################
				# Find out if SCOM of any kind is installed Section
				
				Write-Host "    Checking to see if SCOM is installed and gather the SCOM Role...." -ForegroundColor Magenta
				LogWrite "Checking to see if SCOM is installed and gather the SCOM Role."
				Start-Sleep -s 2
				$Error.Clear()
				$SCOMRegPath = "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup"
				$SCOMInstalled = Test-Path $SCOMRegPath
				
				#On SCOM 2019 StandAlone Web Console Servers the above reg path is missing.  Check alternate path
				IF (!($SCOMInstalled))
				{
					$SCOMRegPath = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\WebConsole"
					$SCOMInstalled = Test-Path $SCOMRegPath
				}
				
				IF ($SCOMInstalled)
				{
					#Find out if this is a SCOM Management server or GW
					$SCOMSvrRegPath = "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Server Management Groups"
					$SCOMServer = Test-Path $SCOMSvrRegPath
					IF ($SCOMServer)
					{
						[string]$Product = (Get-ItemProperty $SCOMRegPath).Product
						IF ($Product -match "Gateway")
						{
							$Gateway = $true
							Write-Host "    SCOM Roles:  Gateway Role was detected." -ForegroundColor Green
							LogWrite "SCOM Roles:  Gateway Role was detected."
							
						}
						ELSE
						{
							$ManagementServer = $true
							Write-Host "    SCOM Roles:  Management Server Role was detected." -ForegroundColor Green
							LogWrite "SCOM Roles:  Management Server Role was detected."
							
						}
					}
					ELSE
					{
						Write-Host "    SCOM Roles:  No Management Server nor Gateway roles detected." -ForegroundColor Green
						LogWrite "SCOM Roles:  No Management Server nor Gateway roles detected."
						
					}
					#Find out if this is a SCOM Web Console Server
					$SCOMInstallPath = (Get-ItemProperty $SCOMRegPath).InstallDirectory
					$WebConsolePath = $SCOMInstallPath -replace "\\Server\\", "\WebConsole\"
					[string]$WebConsoleMVPath = $WebConsolePath + "MonitoringView"
					$WebConsoleServer = Test-Path $WebConsoleMVPath
					IF ($WebConsoleServer)
					{
						Write-Host "    SCOM Roles:  Web Console Role was detected." -ForegroundColor Green
						LogWrite "SCOM Roles:  Web Console Role was detected."
						
					}
					ELSE
					{
						Write-Host "    SCOM Roles:  No Web Console Role was detected." -ForegroundColor Green
						LogWrite "SCOM Roles: No Web Console Role was detected."
						
					}
					
					#Find out of this is a Management Server and has ACS Colector installed
					
					IF ($ManagementServer)
					{
						$ACSReg = "HKLM:\SYSTEM\CurrentControlSet\Services\AdtServer"
						IF (Test-Path $ACSReg)
						{
							#This is an ACS Collector server
							Write-Host "    SCOM Roles:  ACS Collector Role was detected." -ForegroundColor Green
							LogWrite "SCOM Roles:  ACS Collector Role was detected."
							$ACS = $true
							
						}
						ELSE
						{
							#This is NOT an ACS Collector server
							Write-Host "    SCOM Roles:  No ACS Collector Role was detected." -ForegroundColor Green
							LogWrite "SCOM Roles:  No ACS Collector Role was detected."
							
						}
					}
				}
				
				
				###################################################
				# Ensure SCOM 1801, 1807, 2019, SCOM 2016 UR4 (or later) or SCOM 2012 UR14 (or later) is installed
				
				IF ($ManagementServer -or $WebConsoleServer -or $Gateway)
				{
					
					Write-Host "    Checking to ensure the your version of SCOM supports TLS 1.2 enforcement (2012R2 UR14, 2016 UR4, or later)...." -ForegroundColor Magenta
					LogWrite "Checking to ensure the your version of SCOM supports TLS 1.2 enforcement (2012R2 UR14, 2016 UR4, or later)"
					Start-Sleep -s 2
					$Error.Clear()
					# Check to see if this is a Gateway
					IF ($Gateway)
					{
						$GWURFilePath = $SCOMInstallPath + "HealthService.dll"
						$GWURFile = Get-Item $GWURFilePath
						$GWURFileVersion = $GWURFile.VersionInfo.FileVersion
						$GWURFileVersionSplit = $GWURFileVersion.Split(".")
						[double]$MajorSCOMGWVersion = $GWURFileVersionSplit[0] + "." + $GWURFileVersionSplit[1]
						
						IF ($MajorSCOMGWVersion -gt "8.0")
						{
							# This is a SCOM 1801, 1807, 2019 or later Gateway
							Write-Host "    PASSED:  Gateway Server role version 1801/1807/2019 or later detected which supports TLS 1.2" -ForegroundColor Green
							LogWrite "PASSED:  Gateway Server role 1801/1807/2019 or later detected which supports TLS 1.2"
							
						}
						ELSEIF ($MajorSCOMGWVersion -eq "8.0")
						{
							# This is a SCOM 2016 Gateway
							[int]$URVersion = $GWURFileVersionSplit[2]
							IF ($URVersion -ge 10977)
							{
								#This is UR4 or later
								Write-Host "    PASSED:  UR4 or later detected on this SCOM 2016 Gateway" -ForegroundColor Green
								LogWrite "PASSED:  UR4 or later detected on this SCOM 2016 Gateway"
								
							}
							ELSE
							{
								Write-Host "    FAILED:  UR4 was not found on this SCOM 2016 Gateway.  Please ensure UR4 is applied before continuing." -ForegroundColor Red
								Write-Host "    Version found for Healthservice.dll ($GWURFileVersion)" -ForegroundColor Red
								LogWrite "FAILED:  UR4 was not found on this SCOM 2016 Gateway.  Please ensure UR4 is applied before continuing."
								LogWrite "Version found for Healthservice.dll ($GWURFileVersion)"
								
								
							}
						}
						ELSEIF ($MajorSCOMGWVersion -eq "7.1")
						{
							# This is a SCOM 2012R2 Gateway
							[int]$URVersion = $GWURFileVersionSplit[2]
							IF ($URVersion -ge 10305)
							{
								#This is UR4 or later
								Write-Host "    PASSED:  UR14 or later detected on this SCOM 2012 R2 Gateway" -ForegroundColor Green
								LogWrite "PASSED:  UR14 or later detected on this SCOM 2012 R2 Gateway"
								
							}
							ELSE
							{
								Write-Host "    FAILED:  UR14 was not found on this Gateway.  Please ensure UR14 is applied before continuing." -ForegroundColor Red
								Write-Host "    Version found for Healthservice.dll ($GWURFileVersion)" -ForegroundColor Red
								LogWrite "FAILED:  UR14 was not found on this Gateway.  Please ensure UR14 is applied before continuing."
								LogWrite "Version found for Healthservice.dll ($GWURFileVersion)"
								
								
							}
						}
						ELSE
						{
							Write-Host "    FAILED:  A SCOM Gateway Server Role was detected however it is not a known version supported by this script" -ForegroundColor Red
							Write-Host "      Version found for Healthservice.dll ($GWURFileVersion)" -ForegroundColor Red
							LogWrite "FAILED:  A SCOM Gateway Server Role was detected however it is not a known version."
							LogWrite "  Version found for Healthservice.dll ($GWURFileVersion)"
							
							
						}
					}
					IF ($ManagementServer)
					{
						$ServerURFilePath = $SCOMInstallPath + "Microsoft.EnterpriseManagement.RuntimeService.dll"
						$ServerURFile = Get-Item $ServerURFilePath
						$ServerURFileVersion = $ServerURFile.VersionInfo.FileVersion
						$ServerURFileVersionSplit = $ServerURFileVersion.Split(".")
						[double]$MajorSCOMVersion = $ServerURFileVersionSplit[0] + "." + $ServerURFileVersionSplit[1]
						
						IF ($MajorSCOMVersion -gt "7.2")
						{
							# This is a SCOM 1801, 1807, 2019 or later ManagementServer
							Write-Host "    PASSED:  Management Server role version 1801/1807/2019 or later detected which supports TLS 1.2" -ForegroundColor Green
							LogWrite "PASSED:  Management Server role 1801/1807/2019 or later detected which supports TLS 1.2"
							
						}
						ELSEIF ($MajorSCOMVersion -eq "7.2")
						{
							# This is a SCOM 2016 ManagementServer
							[int]$URVersion = $ServerURFileVersionSplit[2]
							IF ($URVersion -ge 11938)
							{
								#This is UR4 or later
								Write-Host "    PASSED:  Management Server role version 2016 UR4 or later detected which supports TLS 1.2" -ForegroundColor Green
								LogWrite "PASSED:  Management Server role version 2016 UR4 or later detected which supports TLS 1.2"
								
							}
							ELSE
							{
								Write-Host "    FAILED:  UR4 or later was not found on this SCOM 2016 ManagementServer.  Please ensure UR4 or later is applied before continuing." -ForegroundColor Red
								Write-Host "    Version found for Microsoft.EnterpriseManagement.RuntimeService.dll ($ServerURFileVersion)" -ForegroundColor Red
								LogWrite "FAILED:  UR4 or later was not found on this SCOM 2016 ManagementServer.  Please ensure UR4 or later is applied before continuing."
								LogWrite "Version found for Microsoft.EnterpriseManagement.RuntimeService.dll ($ServerURFileVersion)"
								
								
							}
						}
						ELSEIF ($MajorSCOMVersion -eq "7.1")
						{
							# This is a SCOM 2012R2 ManagementServer
							[int]$URVersion = $ServerURFileVersionSplit[3]
							IF ($URVersion -ge 1387)
							{
								#This is UR14 or later
								Write-Host "    PASSED:  Management Server role version 2012R2 UR14 or later detected which supports TLS 1.2" -ForegroundColor Green
								LogWrite "PASSED:  Management Server role version 2012R2 UR14 or later detected which supports TLS 1.2"
								
							}
							ELSE
							{
								Write-Host "    FAILED:  UR14 or later was not found on this SCOM 2012R2 ManagementServer.  Please ensure UR14 or later is applied before continuing." -ForegroundColor Red
								Write-Host "    Version found for Microsoft.EnterpriseManagement.RuntimeService.dll ($ServerURFileVersion)" -ForegroundColor Red
								LogWrite "FAILED:  UR14 or later was not found on this SCOM 2012R2 ManagementServer.  Please ensure UR14 or later is applied before continuing."
								LogWrite "Version found for Microsoft.EnterpriseManagement.RuntimeService.dll ($ServerURFileVersion)"
								
								
							}
						}
						ELSE
						{
							Write-Host "    FAILED:  A SCOM Management Server Role was detected however it is not a known version supported by this script" -ForegroundColor Red
							Write-Host "    Version found for Microsoft.EnterpriseManagement.RuntimeService.dll ($ServerURFileVersion)" -ForegroundColor Red
							LogWrite "FAILED:  A SCOM Management Server Role was detected however it is not a known version."
							LogWrite "Version found for Microsoft.EnterpriseManagement.RuntimeService.dll ($ServerURFileVersion)"
							
							
						}
					}
					IF ($WebConsoleServer)
					{
						$WebConsoleFilePath = $WebConsolePath + "Microsoft.Mom.Common.dll"
						$WebConsoleFile = Get-Item $WebConsoleFilePath
						$WebConsoleFileVersion = $WebConsoleFile.VersionInfo.FileVersion
						$WebConsoleFileVersionSplit = $WebConsoleFileVersion.Split(".")
						[double]$MajorWebConsoleVersion = $WebConsoleFileVersionSplit[0] + "." + $WebConsoleFileVersionSplit[1]
						
						IF ($MajorWebConsoleVersion -gt "7.2")
						{
							# This is a SCOM 1801, 1807, 2019 or later Web Console Server
							Write-Host "    PASSED:  Web Console Server role version 1801/1807/2019 or later detected which supports TLS 1.2" -ForegroundColor Green
							LogWrite "PASSED:  Web Console Server role 1801/1807/2019 or later detected which supports TLS 1.2"
							
						}
						ELSEIF ($MajorWebConsoleVersion -eq "7.2")
						{
							# This is a SCOM 2016 WebConsole
							# Get a file that is included in UR4 and later for version checking
							$WebConsole2016URFilePath = $WebConsolePath + "WebHost\bin\Microsoft.EnterpriseManagement.Management.DataProviders.dll"
							$WebConsole2016URFile = Get-Item $WebConsole2016URFilePath
							$WebConsole2016URFileVersion = $WebConsole2016URFile.VersionInfo.FileVersion
							$WebConsole2016URFileVersionSplit = $WebConsole2016URFileVersion.Split(".")
							[int]$2016URVersion = $WebConsole2016URFileVersionSplit[2]
							IF ($2016URVersion -ge 11938)
							{
								#This is UR4 or later
								Write-Host "    PASSED:  Web Console Server role version 2016 UR4 or later detected which supports TLS 1.2" -ForegroundColor Green
								LogWrite "PASSED:  Web Console Server role version 2016 UR4 or later detected which supports TLS 1.2"
								
							}
							ELSE
							{
								Write-Host "    FAILED:  UR4 was not found on this SCOM 2016 WebConsole.  Please ensure UR4 is applied before continuing." -ForegroundColor Red
								Write-Host "    Version found for Microsoft.EnterpriseManagement.Management.DataProviders.dll ($WebConsole2016URFileVersion)" -ForegroundColor Red
								LogWrite "FAILED:  UR4 was not found on this SCOM 2016 WebConsole.  Please ensure UR4 is applied before continuing."
								LogWrite "Version found for Microsoft.EnterpriseManagement.Management.DataProviders.dll ($WebConsole2016URFileVersion)"
								
								
							}
						}
						ELSEIF ($MajorWebConsoleVersion -eq "7.1")
						{
							# This is a SCOM 2012R2 WebConsole
							$WebConsole2012URFilePath = $WebConsolePath + "WebHost\bin\Microsoft.EnterpriseManagement.Management.DataProviders.dll"
							$WebConsole2012URFile = Get-Item $WebConsole2012URFilePath
							$WebConsole2012URFileVersion = $WebConsole2012URFile.VersionInfo.FileVersion
							$WebConsole2012URFileVersionSplit = $WebConsole2012URFileVersion.Split(".")
							[int]$2012URVersion = $WebConsole2012URFileVersionSplit[3]
							
							IF ($2012URVersion -ge 1387)
							{
								#This is UR14 or later
								Write-Host "    PASSED:  Web Console Server role version 2012R2 UR14 or later detected which supports TLS 1.2" -ForegroundColor Green
								LogWrite "PASSED:  Web Console Server role version 2012R2 UR14 or later detected which supports TLS 1.2"
								
							}
							ELSE
							{
								Write-Host "    FAILED:  UR14 was not found on this SCOM 2012R2 WebConsole.  Please ensure UR14 is applied before continuing." -ForegroundColor Red
								Write-Host "    Version found for Microsoft.EnterpriseManagement.Management.DataProviders.dll ($WebConsole2012URFileVersion)" -ForegroundColor Red
								LogWrite "FAILED:  UR14 was not found on this SCOM 2012R2 WebConsole.  Please ensure UR14 is applied before continuing."
								LogWrite "Version found for Microsoft.EnterpriseManagement.Management.DataProviders.dll ($WebConsole2012URFileVersion)"
								
								
							}
						}
						ELSE
						{
							Write-Host "    FAILED:  A SCOM Web Console Server Role was detected however it is not a known version supported by this script" -ForegroundColor Red
							Write-Host "    Version found for ($WebConsoleFilePath) is ($WebConsoleFileVersion)" -ForegroundColor Red
							LogWrite "FAILED:  A SCOM Management Server Role was detected however it is not a known version."
							LogWrite "Version found for ($WebConsoleFilePath) is ($WebConsoleFileVersion)"
							
							
						}
					}
				}
				
				
				
				###################################################
				# Test .NET Framework version on ALL servers
				
				Write-Host "    Checking .NET Framework Version is 4.6 or later...." -ForegroundColor Magenta
				LogWrite "Checking .NET Framework Version is 4.6 or later"
				Start-Sleep -s 2
				$Error.Clear()
				
				# Get version from registry
				$RegPath = "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\"
				[int]$ReleaseRegValue = (Get-ItemProperty $RegPath).Release
				# Interpret .NET version
				[string]$VersionString = switch ($ReleaseRegValue)
				{
					"378389" { ".NET Framework 4.5" }
					"378675" { ".NET Framework 4.5.1" }
					"378758" { ".NET Framework 4.5.1" }
					"379893" { ".NET Framework 4.5.2" }
					"393295" { ".NET Framework 4.6" }
					"393297" { ".NET Framework 4.6" }
					"394254" { ".NET Framework 4.6.1" }
					"394271" { ".NET Framework 4.6.1" }
					"394802" { ".NET Framework 4.6.2" }
					"394806" { ".NET Framework 4.6.2" }
					"460798" { ".NET Framework 4.7" }
					"460805" { ".NET Framework 4.7" }
					"461308" { ".NET Framework 4.7.1" }
					"461310" { ".NET Framework 4.7.1" }
					"461808" { ".NET Framework 4.7.2" }
					"461814" { ".NET Framework 4.7.2" }
					"528040" { ".NET Framework 4.8" }
					"528049" { ".NET Framework 4.8" }
					default { "Unknown version of .NET version: $ReleaseRegValue" }
				}
				# Check if version is 4.6 or higher
				IF ($ReleaseRegValue -ge 393295)
				{
					Write-Host "    PASSED:  .NET version is 4.6 or later" -ForegroundColor Green
					Write-Host "      Detected version is: ($VersionString)" -ForegroundColor Green
					LogWrite "PASSED:  .NET version is 4.6 or later"
					LogWrite "  Detected version is: ($VersionString)"
					
				}
				ELSE
				{
					Write-Host "    FAILED:  .NET Version is NOT 4.6 or later" -ForegroundColor Red
					Write-Host "      Detected version is: ($VersionString)" -ForegroundColor Red
					LogWrite "FAILED:  .NET Version is NOT 4.6 or later"
					LogWrite "  Detected version is: ($VersionString)"
					
					
				}
								
				
				
				###################################################
				# Software Prerequisites for Management Servers and Web Console servers
				IF ($ManagementServer -or $WebConsoleServer)
				{
					
					Write-Host "    Checking SQL Client version and ODBC Driver version for TLS 1.2 support...." -ForegroundColor Magenta
					LogWrite "Checking SQL Client version and ODBC Driver version for TLS 1.2 support"
					Start-Sleep -s 2
					$Error.Clear()
					
					### Check if SQL Client is installed 
					$RegPath = "HKLM:SOFTWARE\Microsoft\SQLNCLI11"
					IF (Test-Path $RegPath)
					{
						[string]$SQLClient11VersionString = (Get-ItemProperty $RegPath)."InstalledVersion"
						[version]$SQLClient11Version = [version]$SQLClient11VersionString
					}
					[version]$MinSQLClient11Version = [version]"11.4.7001.0"
					
					IF ($SQLClient11Version -ge $MinSQLClient11Version)
					{
						Write-Host "    PASSED:  SQL Client - is installed and version: ($SQLClient11VersionString) and greater or equal to the minimum version required: (11.4.7001.0)" -ForegroundColor Green
						LogWrite "PASSED:  SQL Client - is installed and version: ($SQLClient11VersionString) and greater or equal to the minimum version required: (11.4.7001.0)"
					}
					ELSEIF ($SQLClient11VersionString)
					{
						Write-Host "    SQL Client - is installed and version: ($SQLClient11VersionString) but below the minimum version of (11.4.7001.0).  We will attempt upgrade now." -ForegroundColor Yellow
						LogWrite "SQL Client - is installed and version: ($SQLClient11VersionString) but below the minimum version of (11.4.7001.0).  We will attempt upgrade now."
						$SQLClientInstallFlag = $true
						
					}
					ELSE
					{
						Write-Host "    SQL Client - is NOT installed." -ForegroundColor Yellow
						LogWrite "SQL Client - is NOT installed."
					}
					
					
					### Check if ODBC 13 driver is installed
					$RegPath = "HKLM:SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers"
					[string]$ODBCDriver13 = (Get-ItemProperty $RegPath)."ODBC Driver 13 for SQL Server"
					
					
					IF ($ODBCDriver13 -eq "Installed")
					{
						Write-Host "    PASSED:  ODBC Driver - Version 13 is already installed." -ForegroundColor Green
						LogWrite "PASSED:  ODBC Driver - Version 13 is already installed."
					}
					ELSE
					{
						Write-Host "    ODBC Driver - Version 13 is not installed." -ForegroundColor Yellow
						LogWrite "ODBC Driver - Version 13 is not installed."
					}
				}
				
				Write-Host "    Completed TLS 1.2 checks`n" -ForegroundColor Yellow
				LogWrite "Completed TLS 1.2 checks."
				
				#End of Script
			}
            Move-Item "\\$server\C`$\Windows\Temp\SCOM_TLS_Config_$Server.log" "$OutputPath"
		}
        elseif($Comp -eq $server)
		{
			#=================================================================================
			# 
			# Install SCOM TLS 1.2 Configuration Support Script
			#
			# This script supports SCOM 2012R2, 2016, 1801, 1807, and 2019
			#                      SQL 2008R2 through 2017
			#                      .NET 4.5 through 4.8
			#
			# Author:  Kevin Holman
			# v 1.6
			#
			#=================================================================================
			
			
			Write-Host "   Starting SCOM TLS 1.2 Configuration Checker on $Comp (Local)" -ForegroundColor Green			
			
			Write-Host "    Creating log file...." -ForegroundColor Magenta
			Start-Sleep -s 2
			$Error.Clear()
			[string]$LogPath = "C:\Windows\Temp"
			[string]$LogName = "SCOM_TLS_Config_$Server.log"
			[string]$LogFile = $LogPath + "\" + $LogName
			IF (!(Test-Path $LogPath))
			{
				Write-Host "    ERROR: Cannot access logging directory ($LogPath).  Terminating.`n" -ForegroundColor Red
				
				
			}
			IF (!(Test-Path $LogFile))
			{
				New-Item -Path $LogPath -Name $LogName -ItemType File | Out-Null
			}
			Function LogWrite
			{
				Param ([string]$LogString)
				$LogTime = Get-Date -Format 'dd/MM/yy hh:mm:ss'
				Add-content $LogFile -value "$LogTime : $LogString"
			}
			LogWrite "*****"
			LogWrite "*****"
			LogWrite "*****"
			LogWrite "Starting SCOM TLS 1.2 Configuration script"
			IF ($Error)
			{
				LogWrite "Error occurred.  Error is: ($Error)"
			}
			
			
			###################################################
			# Find out if SCOM of any kind is installed Section
			
			Write-Host "    Checking to see if SCOM is installed and gather the SCOM Role...." -ForegroundColor Magenta
			LogWrite "Checking to see if SCOM is installed and gather the SCOM Role."
			Start-Sleep -s 2
			$Error.Clear()
			$SCOMRegPath = "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup"
			$SCOMInstalled = Test-Path $SCOMRegPath
			
			#On SCOM 2019 StandAlone Web Console Servers the above reg path is missing.  Check alternate path
			IF (!($SCOMInstalled))
			{
				$SCOMRegPath = "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\WebConsole"
				$SCOMInstalled = Test-Path $SCOMRegPath
			}
			
			IF ($SCOMInstalled)
			{
				#Find out if this is a SCOM Management server or GW
				$SCOMSvrRegPath = "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Server Management Groups"
				$SCOMServer = Test-Path $SCOMSvrRegPath
				IF ($SCOMServer)
				{
					[string]$Product = (Get-ItemProperty $SCOMRegPath).Product
					IF ($Product -match "Gateway")
					{
						$Gateway = $true
						Write-Host "    SCOM Roles:  Gateway Role was detected." -ForegroundColor Green
						LogWrite "SCOM Roles:  Gateway Role was detected."
						
					}
					ELSE
					{
						$ManagementServer = $true
						Write-Host "    SCOM Roles:  Management Server Role was detected." -ForegroundColor Green
						LogWrite "SCOM Roles:  Management Server Role was detected."
						
					}
				}
				ELSE
				{
					Write-Host "    SCOM Roles:  No Management Server nor Gateway roles detected." -ForegroundColor Green
					LogWrite "SCOM Roles:  No Management Server nor Gateway roles detected."
					
				}
				#Find out if this is a SCOM Web Console Server
				$SCOMInstallPath = (Get-ItemProperty $SCOMRegPath).InstallDirectory
				$WebConsolePath = $SCOMInstallPath -replace "\\Server\\", "\WebConsole\"
				[string]$WebConsoleMVPath = $WebConsolePath + "MonitoringView"
				$WebConsoleServer = Test-Path $WebConsoleMVPath
				IF ($WebConsoleServer)
				{
					Write-Host "    SCOM Roles:  Web Console Role was detected." -ForegroundColor Green
					LogWrite "SCOM Roles:  Web Console Role was detected."
					
				}
				ELSE
				{
					Write-Host "    SCOM Roles:  No Web Console Role was detected." -ForegroundColor Green
					LogWrite "SCOM Roles: No Web Console Role was detected."
					
				}
				
				#Find out of this is a Management Server and has ACS Colector installed
				
				IF ($ManagementServer)
				{
					$ACSReg = "HKLM:\SYSTEM\CurrentControlSet\Services\AdtServer"
					IF (Test-Path $ACSReg)
					{
						#This is an ACS Collector server
						Write-Host "    SCOM Roles:  ACS Collector Role was detected." -ForegroundColor Green
						LogWrite "SCOM Roles:  ACS Collector Role was detected."
						$ACS = $true
						
					}
					ELSE
					{
						#This is NOT an ACS Collector server
						Write-Host "    SCOM Roles:  No ACS Collector Role was detected." -ForegroundColor Green
						LogWrite "SCOM Roles:  No ACS Collector Role was detected."
						
					}
				}
			}
			
			
			###################################################
			# Ensure SCOM 1801, 1807, 2019, SCOM 2016 UR4 (or later) or SCOM 2012 UR14 (or later) is installed
			
			IF ($ManagementServer -or $WebConsoleServer -or $Gateway)
			{
				
				Write-Host "    Checking to ensure the your version of SCOM supports TLS 1.2 enforcement (2012R2 UR14, 2016 UR4, or later)...." -ForegroundColor Magenta
				LogWrite "Checking to ensure the your version of SCOM supports TLS 1.2 enforcement (2012R2 UR14, 2016 UR4, or later)"
				Start-Sleep -s 2
				$Error.Clear()
				# Check to see if this is a Gateway
				IF ($Gateway)
				{
					$GWURFilePath = $SCOMInstallPath + "HealthService.dll"
					$GWURFile = Get-Item $GWURFilePath
					$GWURFileVersion = $GWURFile.VersionInfo.FileVersion
					$GWURFileVersionSplit = $GWURFileVersion.Split(".")
					[double]$MajorSCOMGWVersion = $GWURFileVersionSplit[0] + "." + $GWURFileVersionSplit[1]
					
					IF ($MajorSCOMGWVersion -gt "8.0")
					{
						# This is a SCOM 1801, 1807, 2019 or later Gateway
						Write-Host "    PASSED:  Gateway Server role version 1801/1807/2019 or later detected which supports TLS 1.2" -ForegroundColor Green
						LogWrite "PASSED:  Gateway Server role 1801/1807/2019 or later detected which supports TLS 1.2"
						
					}
					ELSEIF ($MajorSCOMGWVersion -eq "8.0")
					{
						# This is a SCOM 2016 Gateway
						[int]$URVersion = $GWURFileVersionSplit[2]
						IF ($URVersion -ge 10977)
						{
							#This is UR4 or later
							Write-Host "    PASSED:  UR4 or later detected on this SCOM 2016 Gateway" -ForegroundColor Green
							LogWrite "PASSED:  UR4 or later detected on this SCOM 2016 Gateway"
							
						}
						ELSE
						{
							Write-Host "    FAILED:  UR4 was not found on this SCOM 2016 Gateway.  Please ensure UR4 is applied before continuing." -ForegroundColor Red
							Write-Host "    Version found for Healthservice.dll ($GWURFileVersion)" -ForegroundColor Red
							LogWrite "FAILED:  UR4 was not found on this SCOM 2016 Gateway.  Please ensure UR4 is applied before continuing."
							LogWrite "Version found for Healthservice.dll ($GWURFileVersion)"
							
							
						}
					}
					ELSEIF ($MajorSCOMGWVersion -eq "7.1")
					{
						# This is a SCOM 2012R2 Gateway
						[int]$URVersion = $GWURFileVersionSplit[2]
						IF ($URVersion -ge 10305)
						{
							#This is UR4 or later
							Write-Host "    PASSED:  UR14 or later detected on this SCOM 2012 R2 Gateway" -ForegroundColor Green
							LogWrite "PASSED:  UR14 or later detected on this SCOM 2012 R2 Gateway"
							
						}
						ELSE
						{
							Write-Host "    FAILED:  UR14 was not found on this Gateway.  Please ensure UR14 is applied before continuing." -ForegroundColor Red
							Write-Host "    Version found for Healthservice.dll ($GWURFileVersion)" -ForegroundColor Red
							LogWrite "FAILED:  UR14 was not found on this Gateway.  Please ensure UR14 is applied before continuing."
							LogWrite "Version found for Healthservice.dll ($GWURFileVersion)"
							
							
						}
					}
					ELSE
					{
						Write-Host "    FAILED:  A SCOM Gateway Server Role was detected however it is not a known version supported by this script" -ForegroundColor Red
						Write-Host "      Version found for Healthservice.dll ($GWURFileVersion)" -ForegroundColor Red
						LogWrite "FAILED:  A SCOM Gateway Server Role was detected however it is not a known version."
						LogWrite "  Version found for Healthservice.dll ($GWURFileVersion)"
						
						
					}
				}
				IF ($ManagementServer)
				{
					$ServerURFilePath = $SCOMInstallPath + "Microsoft.EnterpriseManagement.RuntimeService.dll"
					$ServerURFile = Get-Item $ServerURFilePath
					$ServerURFileVersion = $ServerURFile.VersionInfo.FileVersion
					$ServerURFileVersionSplit = $ServerURFileVersion.Split(".")
					[double]$MajorSCOMVersion = $ServerURFileVersionSplit[0] + "." + $ServerURFileVersionSplit[1]
					
					IF ($MajorSCOMVersion -gt "7.2")
					{
						# This is a SCOM 1801, 1807, 2019 or later ManagementServer
						Write-Host "    PASSED:  Management Server role version 1801/1807/2019 or later detected which supports TLS 1.2" -ForegroundColor Green
						LogWrite "PASSED:  Management Server role 1801/1807/2019 or later detected which supports TLS 1.2"
						
					}
					ELSEIF ($MajorSCOMVersion -eq "7.2")
					{
						# This is a SCOM 2016 ManagementServer
						[int]$URVersion = $ServerURFileVersionSplit[2]
						IF ($URVersion -ge 11938)
						{
							#This is UR4 or later
							Write-Host "    PASSED:  Management Server role version 2016 UR4 or later detected which supports TLS 1.2" -ForegroundColor Green
							LogWrite "PASSED:  Management Server role version 2016 UR4 or later detected which supports TLS 1.2"
							
						}
						ELSE
						{
							Write-Host "    FAILED:  UR4 or later was not found on this SCOM 2016 ManagementServer.  Please ensure UR4 or later is applied before continuing." -ForegroundColor Red
							Write-Host "    Version found for Microsoft.EnterpriseManagement.RuntimeService.dll ($ServerURFileVersion)" -ForegroundColor Red
							LogWrite "FAILED:  UR4 or later was not found on this SCOM 2016 ManagementServer.  Please ensure UR4 or later is applied before continuing."
							LogWrite "Version found for Microsoft.EnterpriseManagement.RuntimeService.dll ($ServerURFileVersion)"
							
							
						}
					}
					ELSEIF ($MajorSCOMVersion -eq "7.1")
					{
						# This is a SCOM 2012R2 ManagementServer
						[int]$URVersion = $ServerURFileVersionSplit[3]
						IF ($URVersion -ge 1387)
						{
							#This is UR14 or later
							Write-Host "    PASSED:  Management Server role version 2012R2 UR14 or later detected which supports TLS 1.2" -ForegroundColor Green
							LogWrite "PASSED:  Management Server role version 2012R2 UR14 or later detected which supports TLS 1.2"
							
						}
						ELSE
						{
							Write-Host "    FAILED:  UR14 or later was not found on this SCOM 2012R2 ManagementServer.  Please ensure UR14 or later is applied before continuing." -ForegroundColor Red
							Write-Host "    Version found for Microsoft.EnterpriseManagement.RuntimeService.dll ($ServerURFileVersion)" -ForegroundColor Red
							LogWrite "FAILED:  UR14 or later was not found on this SCOM 2012R2 ManagementServer.  Please ensure UR14 or later is applied before continuing."
							LogWrite "Version found for Microsoft.EnterpriseManagement.RuntimeService.dll ($ServerURFileVersion)"
							
							
						}
					}
					ELSE
					{
						Write-Host "    FAILED:  A SCOM Management Server Role was detected however it is not a known version supported by this script" -ForegroundColor Red
						Write-Host "    Version found for Microsoft.EnterpriseManagement.RuntimeService.dll ($ServerURFileVersion)" -ForegroundColor Red
						LogWrite "FAILED:  A SCOM Management Server Role was detected however it is not a known version."
						LogWrite "Version found for Microsoft.EnterpriseManagement.RuntimeService.dll ($ServerURFileVersion)"
						
						
					}
				}
				IF ($WebConsoleServer)
				{
					$WebConsoleFilePath = $WebConsolePath + "Microsoft.Mom.Common.dll"
					$WebConsoleFile = Get-Item $WebConsoleFilePath
					$WebConsoleFileVersion = $WebConsoleFile.VersionInfo.FileVersion
					$WebConsoleFileVersionSplit = $WebConsoleFileVersion.Split(".")
					[double]$MajorWebConsoleVersion = $WebConsoleFileVersionSplit[0] + "." + $WebConsoleFileVersionSplit[1]
					
					IF ($MajorWebConsoleVersion -gt "7.2")
					{
						# This is a SCOM 1801, 1807, 2019 or later Web Console Server
						Write-Host "    PASSED:  Web Console Server role version 1801/1807/2019 or later detected which supports TLS 1.2" -ForegroundColor Green
						LogWrite "PASSED:  Web Console Server role 1801/1807/2019 or later detected which supports TLS 1.2"
						
					}
					ELSEIF ($MajorWebConsoleVersion -eq "7.2")
					{
						# This is a SCOM 2016 WebConsole
						# Get a file that is included in UR4 and later for version checking
						$WebConsole2016URFilePath = $WebConsolePath + "WebHost\bin\Microsoft.EnterpriseManagement.Management.DataProviders.dll"
						$WebConsole2016URFile = Get-Item $WebConsole2016URFilePath
						$WebConsole2016URFileVersion = $WebConsole2016URFile.VersionInfo.FileVersion
						$WebConsole2016URFileVersionSplit = $WebConsole2016URFileVersion.Split(".")
						[int]$2016URVersion = $WebConsole2016URFileVersionSplit[2]
						IF ($2016URVersion -ge 11938)
						{
							#This is UR4 or later
							Write-Host "    PASSED:  Web Console Server role version 2016 UR4 or later detected which supports TLS 1.2" -ForegroundColor Green
							LogWrite "PASSED:  Web Console Server role version 2016 UR4 or later detected which supports TLS 1.2"
							
						}
						ELSE
						{
							Write-Host "    FAILED:  UR4 was not found on this SCOM 2016 WebConsole.  Please ensure UR4 is applied before continuing." -ForegroundColor Red
							Write-Host "    Version found for Microsoft.EnterpriseManagement.Management.DataProviders.dll ($WebConsole2016URFileVersion)" -ForegroundColor Red
							LogWrite "FAILED:  UR4 was not found on this SCOM 2016 WebConsole.  Please ensure UR4 is applied before continuing."
							LogWrite "Version found for Microsoft.EnterpriseManagement.Management.DataProviders.dll ($WebConsole2016URFileVersion)"
							
							
						}
					}
					ELSEIF ($MajorWebConsoleVersion -eq "7.1")
					{
						# This is a SCOM 2012R2 WebConsole
						$WebConsole2012URFilePath = $WebConsolePath + "WebHost\bin\Microsoft.EnterpriseManagement.Management.DataProviders.dll"
						$WebConsole2012URFile = Get-Item $WebConsole2012URFilePath
						$WebConsole2012URFileVersion = $WebConsole2012URFile.VersionInfo.FileVersion
						$WebConsole2012URFileVersionSplit = $WebConsole2012URFileVersion.Split(".")
						[int]$2012URVersion = $WebConsole2012URFileVersionSplit[3]
						
						IF ($2012URVersion -ge 1387)
						{
							#This is UR14 or later
							Write-Host "    PASSED:  Web Console Server role version 2012R2 UR14 or later detected which supports TLS 1.2" -ForegroundColor Green
							LogWrite "PASSED:  Web Console Server role version 2012R2 UR14 or later detected which supports TLS 1.2"
							
						}
						ELSE
						{
							Write-Host "    FAILED:  UR14 was not found on this SCOM 2012R2 WebConsole.  Please ensure UR14 is applied before continuing." -ForegroundColor Red
							Write-Host "    Version found for Microsoft.EnterpriseManagement.Management.DataProviders.dll ($WebConsole2012URFileVersion)" -ForegroundColor Red
							LogWrite "FAILED:  UR14 was not found on this SCOM 2012R2 WebConsole.  Please ensure UR14 is applied before continuing."
							LogWrite "Version found for Microsoft.EnterpriseManagement.Management.DataProviders.dll ($WebConsole2012URFileVersion)"
							
							
						}
					}
					ELSE
					{
						Write-Host "    FAILED:  A SCOM Web Console Server Role was detected however it is not a known version supported by this script" -ForegroundColor Red
						Write-Host "    Version found for ($WebConsoleFilePath) is ($WebConsoleFileVersion)" -ForegroundColor Red
						LogWrite "FAILED:  A SCOM Management Server Role was detected however it is not a known version."
						LogWrite "Version found for ($WebConsoleFilePath) is ($WebConsoleFileVersion)"
						
						
					}
				}
			}
			
			
			
			###################################################
			# Test .NET Framework version on ALL servers
			
			Write-Host "    Checking .NET Framework Version is 4.6 or later...." -ForegroundColor Magenta
			LogWrite "Checking .NET Framework Version is 4.6 or later"
			Start-Sleep -s 2
			$Error.Clear()
			
			# Get version from registry
			$RegPath = "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\"
			[int]$ReleaseRegValue = (Get-ItemProperty $RegPath).Release
			# Interpret .NET version
			[string]$VersionString = switch ($ReleaseRegValue)
			{
				"378389" { ".NET Framework 4.5" }
				"378675" { ".NET Framework 4.5.1" }
				"378758" { ".NET Framework 4.5.1" }
				"379893" { ".NET Framework 4.5.2" }
				"393295" { ".NET Framework 4.6" }
				"393297" { ".NET Framework 4.6" }
				"394254" { ".NET Framework 4.6.1" }
				"394271" { ".NET Framework 4.6.1" }
				"394802" { ".NET Framework 4.6.2" }
				"394806" { ".NET Framework 4.6.2" }
				"460798" { ".NET Framework 4.7" }
				"460805" { ".NET Framework 4.7" }
				"461308" { ".NET Framework 4.7.1" }
				"461310" { ".NET Framework 4.7.1" }
				"461808" { ".NET Framework 4.7.2" }
				"461814" { ".NET Framework 4.7.2" }
				"528040" { ".NET Framework 4.8" }
				"528049" { ".NET Framework 4.8" }
				default { "Unknown version of .NET version: $ReleaseRegValue" }
			}
			# Check if version is 4.6 or higher
			IF ($ReleaseRegValue -ge 393295)
			{
				Write-Host "    PASSED:  .NET version is 4.6 or later" -ForegroundColor Green
				Write-Host "      Detected version is: ($VersionString)" -ForegroundColor Green
				LogWrite "PASSED:  .NET version is 4.6 or later"
				LogWrite "  Detected version is: ($VersionString)"
				
			}
			ELSE
			{
				Write-Host "    FAILED:  .NET Version is NOT 4.6 or later" -ForegroundColor Red
				Write-Host "      Detected version is: ($VersionString)" -ForegroundColor Red
				LogWrite "FAILED:  .NET Version is NOT 4.6 or later"
				LogWrite "  Detected version is: ($VersionString)"
				
				
			}
			
			
			###################################################
			# Get SQL Server Version to check for TLS Support
			
			IF ($ManagementServer)
			{
				
				Write-Host "    Checking SQL Server Versions to ensure they support TLS 1.2 ...." -ForegroundColor Magenta
				LogWrite "Checking SQL Server Versions to ensure they support TLS 1.2"
				Start-Sleep -s 2
				$Error.Clear()
				
				# This is a management server.  Try to get the database values.
				$OpsSQLServer = (Get-ItemProperty $SCOMRegPath).DatabaseServerName
				$DWSQLServer = (Get-ItemProperty $SCOMRegPath).DataWarehouseDBServerName
				# Connect to and query SQL for OpsDB
				$SqlQuery = "SELECT SERVERPROPERTY('ProductVersion') AS 'Version'"
				$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
				$SqlConnection.ConnectionString = "Server=$OpsSQLServer;Database=master;Integrated Security=True"
				$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
				$SqlCmd.Connection = $SqlConnection
				$SqlCmd.CommandText = $SqlQuery
				$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
				$SqlAdapter.SelectCommand = $SqlCmd
				$ds = New-Object System.Data.DataSet
				$SqlAdapter.Fill($ds) | Out-Null
				$SQLOutput = $ds.Tables[0]
				$SQLVersion = $SQLOutput.Version
				$SQLVersionSplit = $SQLVersion.split(".")
				[int]$SQLMajorVersion = $SQLVersionSplit[0]
				
				IF ($SQLMajorVersion -ge 13)
				{
					Write-Host "    PASSED:  Operations DB Server: This is SQL 2016 or later.  All versions of SQL 2016 and later support TLS 1.2 so no update is required on server ($OpsSQLServer)" -ForegroundColor Green
					LogWrite "PASSED:  Operations DB Server: This is SQL 2016 or later.  All versions of SQL 2016 and later support TLS 1.2 so no update is required on server ($OpsSQLServer)"
					
				}
				ELSEIF ($SQLMajorVersion -eq 12)
				{
					[int]$SQLMinorVersion = $SQLVersionSplit[2]
					IF ($SQLMinorVersion -ge 4439)
					{
						Write-Host "    PASSED:  Operations DB Server: This is SQL 2014.  We detected a version that is greater than SQL 2014 SP1 CU5, so no update is required on server ($OpsSQLServer)." -ForegroundColor Green
						Write-Host "      Minimum version: (12.0.4439.1)" -ForegroundColor Green
						Write-Host "      Detected version: ($SQLVersion)" -ForegroundColor Green
						LogWrite "PASSED:  Operations DB Server: This is SQL 2014.  We detected a version that is greater than SQL 2014 SP1 CU5, so no update is required on server ($OpsSQLServer)."
						LogWrite "  Minimum version: (12.0.4439.1)"
						LogWrite "  Detected version: ($SQLVersion)"
						
					}
					ELSE
					{
						Write-Host "    FAILED.  Operations DB Server: This is SQL 2014, and we detected a version that does not support TLS 1.2 on server ($OpsSQLServer)" -ForegroundColor Red
						Write-Host "      Minimum version: (12.0.4439.1)" -ForegroundColor Red
						Write-Host "      Detected version: ($SQLVersion)" -ForegroundColor Red
						LogWrite "FAILED.  Operations DB Server: This is SQL 2014, and we detected a version that does not support TLS 1.2 on server ($OpsSQLServer)"
						LogWrite "  Minimum version: (12.0.4439.1)"
						LogWrite "  Detected version: ($SQLVersion)"
						
						
					}
				}
				ELSEIF ($SQLMajorVersion -eq 11)
				{
					[int]$SQLMinorVersion = $SQLVersionSplit[2]
					IF ($SQLMinorVersion -ge 6216)
					{
						Write-Host "    PASSED:  Operations DB Server: This is SQL 2012.  We detected a version that is greater than SQL 2012 SP3 with TLS Update, so no update is required on server ($OpsSQLServer)." -ForegroundColor Green
						Write-Host "      Minimum version: (11.0.6216.0)" -ForegroundColor Green
						Write-Host "      Detected version: ($SQLVersion)" -ForegroundColor Green
						LogWrite "PASSED:  Operations DB Server: This is SQL 2012.  We detected a version that is greater than SQL 2012 SP3 with TLS Update, so no update is required on server ($OpsSQLServer)."
						LogWrite "  Minimum version: (11.0.6216.0)"
						LogWrite "  Detected version: ($SQLVersion)"
						
					}
					ELSE
					{
						Write-Host "    FAILED.  Operations DB Server: This is SQL 2012, and we detected a version that does not support TLS 1.2 on server ($OpsSQLServer)" -ForegroundColor Red
						Write-Host "      Minimum version: (11.0.6216.0)" -ForegroundColor Red
						Write-Host "      Detected version: ($SQLVersion)" -ForegroundColor Red
						LogWrite "FAILED.  Operations DB Server: This is SQL 2012, and we detected a version that does not support TLS 1.2 on server ($OpsSQLServer)"
						LogWrite "  Minimum version: (11.0.6216.0)"
						LogWrite "  Detected version: ($SQLVersion)"
						
						
					}
				}
				ELSEIF ($SQLMajorVersion -eq 10 -and $SQLVersionSplit[1] -eq 50)
				{
					[int]$SQLMinorVersion = $SQLVersionSplit[2]
					IF ($SQLMinorVersion -ge 6542)
					{
						Write-Host "    PASSED:  Operations DB Server: This is SQL 2008R2.  We detected a version that is greater than SQL 2008R2 SP3 with TLS update, so no update is required on server ($OpsSQLServer)." -ForegroundColor Green
						Write-Host "      Minimum version: (10.50.6542.0)" -ForegroundColor Green
						Write-Host "      Detected version: ($SQLVersion)" -ForegroundColor Green
						LogWrite "PASSED:  Operations DB Server: This is SQL 2008R2.  We detected a version that is greater than SQL 2008R2 SP3 with TLS update, so no update is required on server ($OpsSQLServer)."
						LogWrite "  Minimum version: (10.50.6542.0)"
						LogWrite "  Detected version: ($SQLVersion)"
						
					}
					ELSE
					{
						Write-Host "    FAILED.  Operations DB Server: This is SQL 2008R2, and we detected a version that does not support TLS 1.2 on server ($OpsSQLServer)" -ForegroundColor Red
						Write-Host "      Minimum version: (10.50.6542.0)" -ForegroundColor Red
						Write-Host "      Detected version: ($SQLVersion)" -ForegroundColor Red
						LogWrite "FAILED.  Operations DB Server: This is SQL 2008R2, and we detected a version that does not support TLS 1.2 on server ($OpsSQLServer)"
						LogWrite "  Minimum version: (10.50.6542.0)"
						LogWrite "  Detected version: ($SQLVersion)"
						
						
					}
				}
				ELSE
				{
					Write-Host "    FAILED.  Operations DB Server: We did not detect a supported version of SQL for SCOM and TLS 1.2 on server ($OpsSQLServer)" -ForegroundColor Red
					LogWrite "FAILED.  Operations DB Server: We did not detect a supported version of SQL for SCOM and TLS 1.2 on server ($OpsSQLServer)"
					
					
				}
				
				# Connect to and query SQL for Data Warehouse SQL Server
				$SqlQuery = "SELECT SERVERPROPERTY('ProductVersion') AS 'Version'"
				$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
				$SqlConnection.ConnectionString = "Server=$DWSQLServer;Database=master;Integrated Security=True"
				$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
				$SqlCmd.Connection = $SqlConnection
				$SqlCmd.CommandText = $SqlQuery
				$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
				$SqlAdapter.SelectCommand = $SqlCmd
				$ds = New-Object System.Data.DataSet
				$SqlAdapter.Fill($ds) | Out-Null
				$SQLOutput = $ds.Tables[0]
				$SQLVersion = $SQLOutput.Version
				$SQLVersionSplit = $SQLVersion.split(".")
				[int]$SQLMajorVersion = $SQLVersionSplit[0]
				
				IF ($SQLMajorVersion -ge 13)
				{
					Write-Host "    PASSED:  DataWarehouse Server: This is SQL 2016 or later.  All versions of SQL 2016 or later support TLS 1.2 so no update is required on server ($DWSQLServer)" -ForegroundColor Green
					LogWrite "PASSED:  DataWarehouse Server: This is SQL 2016 or later.  All versions of SQL 2016 or later support TLS 1.2 so no update is required on server ($DWSQLServer)"
					
				}
				ELSEIF ($SQLMajorVersion -eq 12)
				{
					[int]$SQLMinorVersion = $SQLVersionSplit[2]
					IF ($SQLMinorVersion -ge 4439)
					{
						Write-Host "    PASSED:  DataWarehouse Server: This is SQL 2014.  We detected a version that is greater than SQL 2014 SP1 CU5, so no update is required on server ($DWSQLServer)." -ForegroundColor Green
						Write-Host "      Minimum version: (12.0.4439.1)" -ForegroundColor Green
						Write-Host "      Detected version: ($SQLVersion)" -ForegroundColor Green
						LogWrite "PASSED:  DataWarehouse Server: This is SQL 2014.  We detected a version that is greater than SQL 2014 SP1 CU5, so no update is required on server ($DWSQLServer)."
						LogWrite "  Minimum version: (12.0.4439.1)"
						LogWrite "  Detected version: ($SQLVersion)"
						
					}
					ELSE
					{
						Write-Host "    FAILED.  DataWarehouse Server: This is SQL 2014, and we detected a version that does not support TLS 1.2 on server ($DWSQLServer)" -ForegroundColor Red
						Write-Host "      Minimum version: (12.0.4439.1)" -ForegroundColor Red
						Write-Host "      Detected version: ($SQLVersion)" -ForegroundColor Red
						LogWrite "FAILED.  DataWarehouse Server: This is SQL 2014, and we detected a version that does not support TLS 1.2 on server ($DWSQLServer)"
						LogWrite "  Minimum version: (12.0.4439.1)"
						LogWrite "  Detected version: ($SQLVersion)"
						
						
					}
				}
				ELSEIF ($SQLMajorVersion -eq 11)
				{
					[int]$SQLMinorVersion = $SQLVersionSplit[2]
					IF ($SQLMinorVersion -ge 6216)
					{
						Write-Host "    PASSED:  DataWarehouse Server: This is SQL 2012.  We detected a version that is greater than SQL 2012 SP3 with TLS update, so no update is required on server ($DWSQLServer)." -ForegroundColor Green
						Write-Host "      Minimum version: (11.0.6216.0)" -ForegroundColor Green
						Write-Host "      Detected version: ($SQLVersion)" -ForegroundColor Green
						LogWrite "PASSED:  DataWarehouse Server: This is SQL 2012.  We detected a version that is greater than SQL 2012 SP3 with TLS update, so no update is required on server ($DWSQLServer)."
						LogWrite "  Minimum version: (11.0.6216.0)"
						LogWrite "  Detected version: ($SQLVersion)"
						
					}
					ELSE
					{
						Write-Host "    FAILED.  DataWarehouse Server: This is SQL 2012, and we detected a version that does not support TLS 1.2 on server ($DWSQLServer)" -ForegroundColor Red
						Write-Host "      Minimum version: (11.0.6216.0)" -ForegroundColor Red
						Write-Host "      Detected version: ($SQLVersion)" -ForegroundColor Red
						LogWrite "FAILED.  DataWarehouse Server: This is SQL 2012, and we detected a version that does not support TLS 1.2 on server ($DWSQLServer)"
						LogWrite "  Minimum version: (11.0.6216.0)"
						LogWrite "  Detected version: ($SQLVersion)"
						
						
					}
				}
				ELSEIF ($SQLMajorVersion -eq 10 -and $SQLVersionSplit[1] -eq 50)
				{
					[int]$SQLMinorVersion = $SQLVersionSplit[2]
					IF ($SQLMinorVersion -ge 6542)
					{
						Write-Host "    PASSED:  This is SQL 2008R2.  DataWarehouse Server: We detected a version that is greater than SQL 2008R2 SP3 with TLS update, so no update is required on server ($DWSQLServer)." -ForegroundColor Green
						Write-Host "      Minimum version: (10.50.6542.0)" -ForegroundColor Green
						Write-Host "      Detected version: ($SQLVersion)" -ForegroundColor Green
						LogWrite "PASSED:  This is SQL 2008R2.  DataWarehouse Server: We detected a version that is greater than SQL 2008R2 SP3 with TLS update, so no update is required on server ($DWSQLServer)."
						LogWrite "  Minimum version: (10.50.6542.0)"
						LogWrite "  Detected version: ($SQLVersion)"
						
					}
					ELSE
					{
						Write-Host "    FAILED.  DataWarehouse Server: This is SQL 2008R2, and we detected a version that does not support TLS 1.2 on server ($DWSQLServer)" -ForegroundColor Red
						Write-Host "      Minimum version: (10.50.6542.0)" -ForegroundColor Red
						Write-Host "      Detected version: ($SQLVersion)" -ForegroundColor Red
						LogWrite "FAILED.  DataWarehouse Server: This is SQL 2008R2, and we detected a version that does not support TLS 1.2 on server ($DWSQLServer)"
						LogWrite "  Minimum version: (10.50.6542.0)"
						LogWrite "  Detected version: ($SQLVersion)"
						
						
					}
				}
				ELSE
				{
					Write-Host "    FAILED.  DataWarehouse Server: We did not detect a supported version of SQL for SCOM and TLS 1.2 on server ($DWSQLServer)" -ForegroundColor Red
					LogWrite "FAILED.  DataWarehouse Server: We did not detect a supported version of SQL for SCOM and TLS 1.2 on server ($DWSQLServer)"
					
					
				}
			}
			
			
			
			###################################################
			# Software Prerequisites for Management Servers and Web Console servers
			IF ($ManagementServer -or $WebConsoleServer)
			{
				
				Write-Host "    Checking SQL Client version and ODBC Driver version for TLS 1.2 support...." -ForegroundColor Magenta
				LogWrite "Checking SQL Client version and ODBC Driver version for TLS 1.2 support"
				Start-Sleep -s 2
				$Error.Clear()
				
				### Check if SQL Client is installed 
				$RegPath = "HKLM:SOFTWARE\Microsoft\SQLNCLI11"
				IF (Test-Path $RegPath)
				{
					[string]$SQLClient11VersionString = (Get-ItemProperty $RegPath)."InstalledVersion"
					[version]$SQLClient11Version = [version]$SQLClient11VersionString
				}
				[version]$MinSQLClient11Version = [version]"11.4.7001.0"
				
				IF ($SQLClient11Version -ge $MinSQLClient11Version)
				{
					Write-Host "    PASSED:  SQL Client - is installed and version: ($SQLClient11VersionString) and greater or equal to the minimum version required: (11.4.7001.0)" -ForegroundColor Green
					LogWrite "PASSED:  SQL Client - is installed and version: ($SQLClient11VersionString) and greater or equal to the minimum version required: (11.4.7001.0)"
				}
				ELSEIF ($SQLClient11VersionString)
				{
					Write-Host "    SQL Client - is installed and version: ($SQLClient11VersionString) but below the minimum version of (11.4.7001.0).  We will attempt upgrade now." -ForegroundColor Yellow
					LogWrite "SQL Client - is installed and version: ($SQLClient11VersionString) but below the minimum version of (11.4.7001.0).  We will attempt upgrade now."
					$SQLClientInstallFlag = $true
					
				}
				ELSE
				{
					Write-Host "    SQL Client - is NOT installed." -ForegroundColor Yellow
					LogWrite "SQL Client - is NOT installed."
				}
				
				
				### Check if ODBC 13 driver is installed
				$RegPath = "HKLM:SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers"
				[string]$ODBCDriver13 = (Get-ItemProperty $RegPath)."ODBC Driver 13 for SQL Server"
				
				
				IF ($ODBCDriver13 -eq "Installed")
				{
					Write-Host "    PASSED:  ODBC Driver - Version 13 is already installed." -ForegroundColor Green
					LogWrite "PASSED:  ODBC Driver - Version 13 is already installed."
				}
				ELSE
				{
					Write-Host "    ODBC Driver - Version 13 is not installed." -ForegroundColor Yellow
					LogWrite "ODBC Driver - Version 13 is not installed."
				}
			}
			
			Write-Host "    Completed TLS 1.2 checks`n" -ForegroundColor Yellow
			LogWrite "Completed TLS 1.2 checks."
			
			#End of Script
			Move-Item $LogFile $OutputPath
		}
	}
}
Start-TLSChecker
