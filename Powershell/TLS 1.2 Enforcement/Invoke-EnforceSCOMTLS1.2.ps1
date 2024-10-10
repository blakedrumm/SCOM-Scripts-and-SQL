<#
	.SYNOPSIS
		This script allows you to enforce TLS 1.2 / 1.3 on System Center Operation Manager environments.
	
	.DESCRIPTION
		Use this script when you need to want to automate the steps listed here:
		https://learn.microsoft.com/system-center/scom/plan-security-tls12-config
	
	.PARAMETER AssumeYes
		The script will not ask any questions. Good for unattended runs.
	
	.PARAMETER DirectoryForPrerequisites
		The directory to save / load the prerequisites from. Default is the current directory.
	
	.PARAMETER ForceDownloadPrerequisites
		Force download the prerequisites to the directory specified in DirectoryForPrerequisites.
	
	.PARAMETER SkipDotNetCheck
		Skip the .NET Check step.
	
	.PARAMETER SkipDownloadPrerequisites
		Skip downloading the prerequisite files to current directory:
		- msoledbsql.msi  (https://learn.microsoft.com/sql/connect/oledb/release-notes-for-oledb-driver-for-sql-server#1874)
		- msodbcsql.msi   (https://learn.microsoft.com/sql/connect/odbc/windows/release-notes-odbc-sql-server-windows?view=sql-server-ver16#17105)
		- sqlncli.msi     (https://www.microsoft.com/download/details.aspx?id=50402)
	
	.PARAMETER SkipModifyRegistry
		Skip any registry modifications.
	
	.PARAMETER SkipRoleCheck
		Skip the SCOM Role Check step.
	
	.PARAMETER SkipSQLQueries
		Skip any check for SQL version compatibility.
	
	.PARAMETER SkipSQLSoftwarePrerequisites
		Skip the ODBC, MSOLEDBSQL, and/or Microsoft SQL Server 2012 Native Client.
	
	.PARAMETER SkipVersionCheck
		Skip SCOM Version Check step.
	
	.EXAMPLE
	    PS C:\> .\Invoke-EnforceSCOMTLS1.2.ps1
     	    Normal run

	.EXAMPLE
     	    PS C:\> .\Invoke-EnforceSCOMTLS1.2.ps1 -DirectoryForPrerequisites "C:\Temp"
     	    Set the prerequisites folder:
	
	.NOTES
		=================================================================================
		
				 SCOM TLS 1.2 / 1.3 Configuration Script
					     v 2.5
	  
		 This script supports: SCOM 2012R2, 2016, 1801, 1807, 2019, and 2022
		                       SQL 2008R2 through 2022
		                       .NET 4.5 through 4.8.1
		
		 Original Author: Kevin Holman (https://kevinholman.com/)
		 Author: Blake Drumm (https://blakedrumm.com/)
		
		 Last Updated: October 9th, 2024
	
	  	 Blog Post: https://blakedrumm.com/blog/enforce-tls-1-2-scom/
		
		=================================================================================
#>
param
(
	[Parameter(HelpMessage = 'The script will not ask any questions. Good for unattended runs.')]
	[Alias('yes')]
	[switch]$AssumeYes,
	[Parameter(HelpMessage = 'The directory to save / load the prerequisites from. Default is the current directory.')]
	[Alias('dfp')]
	[string]$DirectoryForPrerequisites,
	[Parameter(HelpMessage = 'Force download the prerequisites to the directory specified in DirectoryForPrerequisites.')]
	[Alias('fdp')]
	[switch]$ForceDownloadPrerequisites,
	[Parameter(HelpMessage = 'Skip the .NET Check step.')]
	[Alias('sdnc')]
	[switch]$SkipDotNetCheck,
	[Parameter(HelpMessage = 'Skip downloading the prerequisite files to current directory.')]
	[Alias('sdp')]
	[switch]$SkipDownloadPrerequisites,
	[Parameter(HelpMessage = 'Skip any registry modifications.')]
	[Alias('smr')]
	[switch]$SkipModifyRegistry,
	[Parameter(HelpMessage = 'Skip the SCOM Role Check step.')]
	[Alias('src')]
	[switch]$SkipRoleCheck,
	[Parameter(HelpMessage = 'Skip any check for SQL version compatibility.')]
	[Alias('ssq')]
	[switch]$SkipSQLQueries,
	[Parameter(HelpMessage = 'Skip the ODBC, MSOLEDBSQL, and/or Microsoft SQL Server 2012 Native Client.')]
	[Alias('sssp')]
	[switch]$SkipSQLSoftwarePrerequisites,
	[Parameter(HelpMessage = 'Skip SCOM Version Check step.')]
	[Alias('svc')]
	[switch]$SkipVersionCheck
)

function Start-SCOMTLSEnforcement
{
	param
	(
		[Parameter(HelpMessage = 'The script will not ask any questions. Good for unattended runs.')]
		[Alias('yes')]
		[switch]$AssumeYes,
		[Parameter(HelpMessage = 'The directory to save / load the prerequisites from. Default is the current directory.')]
		[Alias('dfp')]
		[string]$DirectoryForPrerequisites,
		[Parameter(HelpMessage = 'Force download the prerequisites to the directory specified in DirectoryForPrerequisites.')]
		[Alias('fdp')]
		[switch]$ForceDownloadPrerequisites,
		[Parameter(HelpMessage = 'Skip the .NET Check step.')]
		[Alias('sdnc')]
		[switch]$SkipDotNetCheck,
		[Parameter(HelpMessage = 'Skip downloading the prerequisite files to current directory.')]
		[Alias('sdp')]
		[switch]$SkipDownloadPrerequisites,
		[Parameter(HelpMessage = 'Skip any registry modifications.')]
		[Alias('smr')]
		[switch]$SkipModifyRegistry,
		[Parameter(HelpMessage = 'Skip the SCOM Role Check step.')]
		[Alias('src')]
		[switch]$SkipRoleCheck,
		[Parameter(HelpMessage = 'Skip any check for SQL version compatibility.')]
		[Alias('ssq')]
		[switch]$SkipSQLQueries,
		[Parameter(HelpMessage = 'Skip the ODBC, MSOLEDBSQL, and/or Microsoft SQL Server 2012 Native Client.')]
		[Alias('sssp')]
		[switch]$SkipSQLSoftwarePrerequisites,
		[Parameter(HelpMessage = 'Skip SCOM Version Check step.')]
		[Alias('svc')]
		[switch]$SkipVersionCheck
	)
	# Set the location for the Logs to be saved.
	# Example: C:\ProgramData\SCOM_Enforce_TLS_1.2_-_03-17-2023.log
	[string]$LogPath = "$env:PROGRAMDATA"
	[string]$LogName = "SCOM_Enforce_TLS_1.2_-_$(Get-Date -Format "MM-dd-yyyy").log"
	[string]$LogFile = "$LogPath`\$LogName"
	IF (!(Test-Path $LogPath))
	{
		Write-Output "Cannot access logging directory ($LogPath). Terminating!"
		break
	}
	else
	{
		Write-Host "Creating log file: $LogFile"
		Add-content $LogFile -value "-----------------------------------------------------------"
	}
	
	function Get-CurrentDate
	{
		$Date = Get-Date
		[string]$LogTime = "$(($Date).ToShortDateString()) $(($Date).ToLongTimeString())"
		[string]$LogTimeFormatted = "$LogTime - "
		return $LogTimeFormatted
	}
	function Write-ScriptLog
	{
		param
		(
			[string]$LogString,
			$ForegroundColor,
			[string]$Step,
			[string]$Status,
			[switch]$NoOutput
		)
		
		Start-Sleep -Milliseconds 90
		
		if ($Status)
		{
			$ModifiedStatus = "[$($Status.ToUpper())] "
			if ($Status -match "Failed|Error")
			{
				$TextColor = 'Red'
			}
			elseif ($Status -eq 'Passed')
			{
				$TextColor = 'Green'
			}
			else
			{
				$TextColor = 'DarkCyan'
			}
		}
		if (-not $NoOutput)
		{
			Write-Host $(Get-CurrentDate) -NoNewline
		}
		
		if ($Step)
		{
			if (-not $NoOutput)
			{
				Write-Host "(" -NoNewline
				Write-Host "$Step" -NoNewline -ForegroundColor Magenta
				Write-Host "): " -NoNewline
			}
			if ($Status)
			{
				if (-not $NoOutput)
				{
					Write-Host "[" -NoNewline
					Write-Host $Status.ToUpper() -NoNewline -ForegroundColor $TextColor
					Write-Host "] " -NoNewline
				}
				$outText = "($Step): $ModifiedStatus$LogString"
			}
			else
			{
				$outText = "($Step): $LogString"
			}
			
		}
		else
		{
			if ($Status)
			{
				if (-not $NoOutput)
				{
					Write-Host "[" -NoNewline
					Write-Host $Status.ToUpper() -NoNewline -ForegroundColor $TextColor
					Write-Host "] " -NoNewline
				}
				$outText = "$ModifiedStatus$LogString"
			}
			else
			{
				$outText = "$LogString"
			}
		}
		
		if ($ForegroundColor)
		{
			if (-not $NoOutput)
			{
				Write-Host "$LogString" -ForegroundColor $ForegroundColor
			}
		}
		else
		{
			if (-not $NoOutput)
			{
				Write-Host "$LogString"
			}
		}
		Add-Content $LogFile -value "$(Get-CurrentDate)$outText"
	}
	function Script-Failed
	{
		param
		(
			$failed,
			$step
		)
		
		if ($failed)
		{
			Write-ScriptLog -Step $Step -Status Failed -LogString "Encountered at least one fatal error. Terminating!" -ForegroundColor Red
			break
		}
		else
		{
			return
		}
	}
	
	if (-NOT $DirectoryForPrerequisites)
	{
		$DirectoryForPrerequisites = (Resolve-Path .\).Path
	}
	else
	{
		$DirectoryForPrerequisites = (Resolve-Path $DirectoryForPrerequisites).Path
	}
	$missingPreq = $false
	if (-not (Test-Path $DirectoryForPrerequisites\msoledbsql*.msi))
	{
		$missingPreq = $true
	}
	elseif (-not (Test-Path $DirectoryForPrerequisites\msodbcsql*.msi))
	{
		$missingPreq = $true
	}
	elseif (-not (Test-Path $DirectoryForPrerequisites\sqlncli*.msi))
	{
		$missingPreq = $true
	}
	if (-not $SkipDownloadPrerequisites -and $missingPreq -or $ForceDownloadPrerequisites)
	{
		if (-NOT $AssumeYes -and $missingPreq)
		{
			do
			{
				$answer = Read-Host "Would you like to download the MSOLEDBSQL, MSODBCSQL, and SQLNCLI MSI files to the local directory? '$DirectoryForPrerequisites' (Y/N)"
			}
			until ($answer -match "^Y|^N")
		}
		else
		{
			$answer = 'Y'
		}
		
		
		function Download-Prerequisites
		{
			Write-ScriptLog -Step Prerequisites -LogString "Downloading required prerequisites to: '$((Resolve-Path $DirectoryForPrerequisites\).Path)'"
			[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
			
			# MSOLEDB
			<# Download Latest (Version 19+)
			$releasePage = ((Invoke-WebRequest -UseBasicParsing -Uri 'https://learn.microsoft.com/sql/connect/oledb/download-oledb-driver-for-sql-server').RawContent).Split("`r`n")
			$releaseDate = ($releasePage | Where {$_ -match "Released: (.*)"}).Replace("<li>Released: ",'').Replace("</li>",'').Replace(",","") | Select-Object -Index 0
			$releaseVersion = ($releasePage| Where {$_ -match "Release number: (.*)"}).Replace("<li>Release number: ",'').Replace("</li>",'') | Select-Object -Index 0
			$releaseDownloadLink = ($releasePage| Where {$_ -match "Download.*x64"}).Split("`"") | Select-Object -Index 1
			#>
			try
			{
				# MSOLEDB 18.7.4
				$releaseDownloadLink = 'https://go.microsoft.com/fwlink/?linkid=2278907'
				$filename = 'msoledbsql_18.7.4'
				Write-ScriptLog -Step Prerequisites -LogString "Downloading MSOLEDB 18.7.4 automatically from: '$releaseDownloadLink'" -ForegroundColor Cyan
				Start-BitsTransfer -Source $releaseDownloadLink -Destination "$DirectoryForPrerequisites\$filename.msi" -ErrorAction Stop
				Out-File -FilePath "$DirectoryForPrerequisites\$filename-Released-July 09 2024"
			}
			catch
			{
				Write-ScriptLog -Step Prerequisites -LogString "Unable to download MSOLEDB 18.7.4 automatically from: 'https://learn.microsoft.com/sql/connect/oledb/download-oledb-driver-for-sql-server'" -ForegroundColor Red -Status Error
			}
			
			#ODBC
			<# Download Latest ODBC (As of writing: 18.3.1.1)
			$releasePage = ((Invoke-WebRequest -UseBasicParsing -Uri 'https://learn.microsoft.com/sql/connect/odbc/download-odbc-driver-for-sql-server').RawContent).Split("`r`n")
			$releaseDate = ($releasePage | Where { $_ -match "Released: (.*)" }).Replace("<li>Released: ", '').Replace("</li>", '').Replace(",", "").Replace("/", "-") | Select-Object -Index 0
			$releaseVersion = ($releasePage | Where { $_ -match "Release number: (.*)" }).Replace("<li>Release number: ", '').Replace("</li>", '') | Select-Object -Index 0
			$releaseDownloadLink = ($releasePage | Where { $_ -match "Download.*x64" }).Split("`"") | Select-Object -Index 1
			Write-ScriptLog -Step Prerequisites -LogString "Downloading latest ODBC automatically from: '$releaseDownloadLink'" -ForegroundColor Cyan
			Start-BitsTransfer -Source $releaseDownloadLink -Destination "$DirectoryForPrerequisites\msodbcsql_$releaseVersion.msi"
			Out-File -FilePath "$DirectoryForPrerequisites\msodbcsql_$releaseVersion-Released-$releaseDate"
			#>
			try
			{
				# ODBC 17.10.5
				$releaseDownloadLink = 'https://go.microsoft.com/fwlink/?linkid=2249004'
				$filename = 'msodbcsql_17.10.5'
				Write-ScriptLog -Step Prerequisites -LogString "Downloading ODBC 17.10.5 automatically from: '$releaseDownloadLink'" -ForegroundColor Cyan
				Start-BitsTransfer -Source $releaseDownloadLink -Destination "$DirectoryForPrerequisites\$filename.msi" -ErrorAction Stop
				Out-File -FilePath "$DirectoryForPrerequisites\$filename-Released-October 10 2023"
			}
			catch
			{
				Write-ScriptLog -Step Prerequisites -LogString "Unable to download ODBC 17.10.5 automatically from: 'https://learn.microsoft.com/sql/connect/odbc/windows/release-notes-odbc-sql-server-windows'" -ForegroundColor Red -Status Error
			}
			
			# SQL Server 2012 Native Client
			try
			{
				# Microsoft SQL Server 2012 Native Client - QFE (As of writing: 11.0.7001.0)
				$releaseDownloadLink = "https://download.microsoft.com/download/B/E/D/BED73AAC-3C8A-43F5-AF4F-EB4FEA6C8F3A/ENU/x64/sqlncli.msi"
				Write-ScriptLog -Step Prerequisites -LogString "Downloading SQL Server 2012 Native Client automatically from: '$releaseDownloadLink'" -ForegroundColor Cyan
				Start-BitsTransfer -Source $releaseDownloadLink -Destination "$DirectoryForPrerequisites\sqlncli_$releaseVersion.msi"
				Out-File -FilePath "$DirectoryForPrerequisites\sqlncli_$releaseVersion-Released-$releaseDate"
			}
			catch
			{
				Write-ScriptLog -Step Prerequisites -LogString "Unable to download Microsoft SQL Server 2012 Native Client automatically from: 'https://www.microsoft.com/download/details.aspx?id=50402&751be11f-ede8-5a0c-058c-2ee190a24fa6'" -ForegroundColor Red -Status Error
			}
		}
		
		if ($answer -match "^Y" -or $ForceDownloadPrerequisites)
		{
			Download-Prerequisites
		}
		else
		{
			do
			{
				$answer = Read-Host "Do you want to download to another directory instead? (Y/N)"
			}
			until ($answer -match "^Y|^N")
			if ($answer -match "^N")
			{
				Write-ScriptLog -Step Prerequisites -LogString "You have decided to skip the downloading of the pre-requisites. Please ensure you have the software(s) in the same folder as the script, or installed already." -ForegroundColor Yellow -Status Warning
			}
			else
			{
				do
				{
					$answer = Read-Host "Please enter the path to save the prerequisite software(s)? (C:\Temp\)"
				}
				until ($answer -match "(\w:\\+\w+)|(\\+\w+)+")
				$resolvedPath = (Resolve-Path -Path $answer).Path
				$DirectoryForPrerequisites = $resolvedPath
				Download-Prerequisites
			}
		}
	}
<#
Write-ScriptLog @"
Starting SCOM TLS 1.2 Configuration.
PowerShell Unrestricted Execution Policy access is required to run this script.
If applicable, please use the (Set-ExecutionPolicy Unrestricted) command to allow the script to run.
Logging will be written to C:\ProgramData
"@ -ForegroundColor Yellow
#>
	$Error.Clear()
	Write-ScriptLog -LogString "Starting SCOM TLS 1.2 Configuration script on: $env:COMPUTERNAME" -Step Startup
	IF ($Error)
	{
		Write-ScriptLog -Step Startup -LogString "Error occurred. Error is: ($Error)" -ForegroundColor Red -Status Error
	}
	###################################################
	# Find out if SCOM of any kind is installed Section
	$MSOLEDBInstallFlag = $false
	$ODBCInstallFlag = $false
	$failed = $false
	if (-not $SkipRoleCheck)
	{
		Write-ScriptLog -Step Startup -LogString "Checking to see if SCOM is installed and gather the SCOM Role."
		$Error.Clear()
		$SCOMRegPath = "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup"
		$SCOMInstalled = Test-Path $SCOMRegPath
		#On SCOM 2019 StandAlone Web Console Servers the above reg path is missing. Check alternate path
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
					Write-ScriptLog -Step 'SCOM Role Check' -LogString "Gateway Role has been detected." -ForegroundColor Green
				}
				ELSE
				{
					$ManagementServer = $true
					Write-ScriptLog -Step 'SCOM Role Check' -LogString "Management Server Role has been detected." -ForegroundColor Green
				}
			}
			ELSE
			{
				Write-ScriptLog -Step 'SCOM Role Check' -LogString "No Management Server or Gateway roles detected." -ForegroundColor Yellow
			}
			#Find out if this is a SCOM Web Console Server
			$SCOMInstallPath = (Get-ItemProperty $SCOMRegPath).InstallDirectory
			$WebConsolePath = $SCOMInstallPath -replace "\\Server\\", "\WebConsole\"
			[string]$WebConsoleMVPath = $WebConsolePath + "MonitoringView"
			$WebConsoleServer = Test-Path $WebConsoleMVPath
			IF ($WebConsoleServer)
			{
				Write-ScriptLog -Step 'SCOM Role Check' -LogString "Web Console Role has been detected." -ForegroundColor Green
			}
			ELSE
			{
				Write-ScriptLog -Step 'SCOM Role Check' -LogString "No Web Console Role has been detected." -ForegroundColor Yellow
			}
			#Find out if this is a Management Server and has ACS Collector installed
			IF ($ManagementServer)
			{
				$ACSReg = "HKLM:\SYSTEM\CurrentControlSet\Services\AdtServer"
				IF (Test-Path $ACSReg)
				{
					#This is an ACS Collector server
					Write-ScriptLog -Step 'SCOM Role Check' -LogString "ACS Collector Role has been detected." -ForegroundColor Green
					$ACS = $true
				}
				ELSE
				{
					#This is NOT an ACS Collector server
					Write-ScriptLog -Step 'SCOM Role Check' -LogString "No ACS Collector Role has been detected." -ForegroundColor Yellow
				}
			}
		}
	}
	
	Script-Failed -step 'SCOM Role Check' -failed $failed
	###################################################
	# Ensure SCOM 2012 UR14 (or later), 1801, 1807, 2019, 2022, or 2016 UR4 (or later) is installed
	
	$SCOM2012 = $false
	$SCOM2016 = $false
	$SCOM1801_1807 = $true
	$SCOM2019 = $false
	$SCOM2022 = $false
	$SCOM2022andUP = $false
	
	IF (-not $SkipVersionCheck -and $ManagementServer -or $WebConsoleServer -or $Gateway)
	{
		Write-ScriptLog -Step 'SCOM Version Check' -LogString "Checking to ensure the your version of SCOM supports TLS 1.2 enforcement (2012R2 UR14 (or later), 2016 UR4 (or later), 2019, 2022)."
		$Error.Clear()
		$failed = $false
		#region CheckGateway
		# Check to see if this is a Gateway
		IF ($Gateway)
		{
			$GWURFilePath = $SCOMInstallPath + "HealthService.dll"
			Write-ScriptLog -Step 'SCOM Version Check' -ForegroundColor Gray -LogString "SCOM Gateway Update Rollup filepath: $GWURFilePath"
			$GWURFile = Get-Item $GWURFilePath
			$GWURFileVersion = $GWURFile.VersionInfo.FileVersion
			Write-ScriptLog -Step 'SCOM Version Check' -ForegroundColor Gray -LogString "SCOM Gateway Update Rollup file version: $GWURFileVersion"
			$GWURFileVersionSplit = $GWURFileVersion.Split(".")
			[double]$MajorSCOMGWVersion = $GWURFileVersionSplit[0] + "." + $GWURFileVersionSplit[1]
			IF ($MajorSCOMGWVersion -gt "10.22")
			{
				# This is a SCOM 2022 or later Gateway
				Write-ScriptLog -Step 'SCOM Version Check' -Status Passed -LogString "Gateway Server role version 2022 (or newer) detected which supports TLS 1.2" -ForegroundColor Green
				$failed = $false
				$SCOM2022andUP = $true
			}
			ELSEIF ($MajorSCOMGWVersion -eq "10.22")
			{
				# This is a SCOM 2022 Gateway
				Write-ScriptLog -Step 'SCOM Version Check' -Status Passed -LogString "Gateway Server role version 2022 detected which supports TLS 1.2" -ForegroundColor Green
				$failed = $false
				$SCOM2022 = $true
			}
			ELSEIF ($MajorSCOMGWVersion -eq "10.19")
			{
				# This is a SCOM 2019 Gateway
				Write-ScriptLog -Step 'SCOM Version Check' -Status Passed -LogString "Gateway Server role version 2019 detected which supports TLS 1.2" -ForegroundColor Green
				$failed = $false
				$SCOM2019 = $true
			}
			ELSEIF ($MajorSCOMGWVersion -gt "8.0")
			{
				# This is a SCOM 1801, 1807 Gateway
				Write-ScriptLog -Step 'SCOM Version Check' -Status Passed -LogString "Gateway Server role version 1801/1807 detected which supports TLS 1.2" -ForegroundColor Green
				$failed = $false
				$SCOM1801_1807 = $true
			}
			ELSEIF ($MajorSCOMGWVersion -eq "8.0")
			{
				# This is a SCOM 2016 Gateway
				[int]$URVersion = $GWURFileVersionSplit[2]
				IF ($URVersion -ge 10977)
				{
					#This is UR4 or later
					Write-ScriptLog -Step 'SCOM Version Check' -Status Passed -LogString "SCOM 2016 UR4 or later detected on this SCOM 2016 Gateway" -ForegroundColor Green
					$failed = $false
					$SCOM2016 = $true
				}
				ELSE
				{
					Write-ScriptLog -Step 'SCOM Version Check' -Status Failed -LogString "SCOM 2016 UR4 was not found on this SCOM 2016 Gateway. Please ensure SCOM 2016 UR4 is applied before continuing." -ForegroundColor Red
					Write-ScriptLog -Step 'SCOM Version Check' -Status Failed -LogString "Version found for Healthservice.dll ($GWURFileVersion)" -ForegroundColor Red
					$failed = $true
				}
			}
			ELSEIF ($MajorSCOMGWVersion -eq "7.1")
			{
				# This is a SCOM 2012R2 Gateway
				[int]$URVersion = $GWURFileVersionSplit[2]
				IF ($URVersion -ge 10305)
				{
					#This is UR4 or later
					Write-ScriptLog -Step 'SCOM Version Check' -Status Failed -LogString "SCOM 2012R2 UR14 or later detected on this SCOM 2012 R2 Gateway" -ForegroundColor Green
					$SCOM2012 = $true
					$failed = $false
				}
				ELSE
				{
					Write-ScriptLog -Step 'SCOM Version Check' -Status Failed -LogString "SCOM 2012R2 UR14 was not found on this Gateway. Please ensure UR14 is applied before continuing." -ForegroundColor Red
					Write-ScriptLog -Step 'SCOM Version Check' -Status Failed -LogString "Version found for Healthservice.dll ($GWURFileVersion)" -ForegroundColor Red
					$failed = $true
				}
			}
			ELSE
			{
				Write-ScriptLog -Step 'SCOM Version Check' -Status Failed -LogString "A SCOM Gateway Server Role has been detected however it is not a known version supported by this script" -ForegroundColor Red
				Write-ScriptLog -Step 'SCOM Version Check' -Status Failed -LogString "Version found for Healthservice.dll ($GWURFileVersion)" -ForegroundColor Red
				$failed = $true
			}
		}
		Script-Failed -Step 'SCOM Version Check' -failed $failed
		#endregion CheckGateway
		#region CheckManagementServer
		IF (-not $SkipVersionCheck -and $ManagementServer)
		{
			$ServerURFilePath = $SCOMInstallPath + "Microsoft.EnterpriseManagement.RuntimeService.dll"
			Write-ScriptLog -Step 'SCOM Version Check' -ForegroundColor Gray -LogString "Management Server Update Rollup filepath: $ServerURFilePath"
			$ServerURFile = Get-Item $ServerURFilePath
			$ServerURFileVersion = $ServerURFile.VersionInfo.FileVersion
			Write-ScriptLog -Step 'SCOM Version Check' -ForegroundColor Gray -LogString "Management Server Update Rollup file version: $ServerURFileVersion"
			$ServerURFileVersionSplit = $ServerURFileVersion.Split(".")
			[double]$MajorSCOMVersion = $ServerURFileVersionSplit[0] + "." + $ServerURFileVersionSplit[1]
			IF ($MajorSCOMVersion -gt "10.22")
			{
				# This is a SCOM 2022 or later Gateway
				Write-ScriptLog -Step 'SCOM Version Check' -Status Passed -LogString "Management Server role version 2022 (or newer) detected which supports TLS 1.2" -ForegroundColor Green
				$failed = $false
				$SCOM2022andUP = $true
			}
			ELSEIF ($MajorSCOMVersion -eq "10.22")
			{
				# This is a SCOM 2022 Gateway
				Write-ScriptLog -Step 'SCOM Version Check' -Status Passed -LogString "Management Server role version 2022 detected which supports TLS 1.2" -ForegroundColor Green
				$failed = $false
				$SCOM2022 = $true
			}
			ELSEIF ($MajorSCOMVersion -eq "10.19")
			{
				# This is a SCOM 2019 Gateway
				Write-ScriptLog -Step 'SCOM Version Check' -Status Passed -LogString "Management Server role version 2019 detected which supports TLS 1.2" -ForegroundColor Green
				$failed = $false
				$SCOM2019 = $true
			}
			ELSEIF ($MajorSCOMVersion -ge "7.3")
			{
				# This is a SCOM 1801, 1807 Gateway
				Write-ScriptLog -Step 'SCOM Version Check' -Status Passed -LogString "Management Server role version 1801/1807 detected which supports TLS 1.2" -ForegroundColor Green
				$failed = $false
				$SCOM1801_1807 = $true
			}
			ELSEIF ($MajorSCOMVersion -eq "7.2")
			{
				# This is a SCOM 2016 ManagementServer
				[int]$URVersion = $ServerURFileVersionSplit[2]
				IF ($URVersion -ge 11938)
				{
					#This is UR4 or later
					Write-ScriptLog -Step 'SCOM Version Check' -Status Passed -LogString "Management Server role version 2016 UR4 or later detected which supports TLS 1.2" -ForegroundColor Green
					$failed = $false
					$SCOM2016 = $true
				}
				ELSE
				{
					Write-ScriptLog -Step 'SCOM Version Check' -Status Failed -LogString "SCOM 2016 UR4 or later was not found on this SCOM 2016 Management Server. Please ensure UR4 or later is applied before continuing." -ForegroundColor Red
					Write-ScriptLog -Step 'SCOM Version Check' -Status Failed -LogString "Version found for Microsoft.EnterpriseManagement.RuntimeService.dll ($ServerURFileVersion)" -ForegroundColor Red
					$failed = $true
				}
			}
			ELSEIF ($MajorSCOMVersion -eq "7.1")
			{
				# This is a SCOM 2012R2 ManagementServer
				[int]$URVersion = $ServerURFileVersionSplit[3]
				IF ($URVersion -ge 1387)
				{
					#This is UR14 or later
					Write-ScriptLog -Step 'SCOM Version Check' -Status Passed -LogString "Management Server role version 2012R2 UR14 or later detected which supports TLS 1.2" -ForegroundColor Green
					$failed = $false
					$SCOM2012 = $true
				}
				ELSE
				{
					Write-ScriptLog -Step 'SCOM Version Check' -Status Failed -LogString "SCOM 2012R2 UR14 or later was not found on this SCOM 2012R2 Management Server. Please ensure UR14 or later is applied before continuing." -ForegroundColor Red
					Write-ScriptLog -Step 'SCOM Version Check' -Status Failed -LogString "Version found for Microsoft.EnterpriseManagement.RuntimeService.dll ($ServerURFileVersion)" -ForegroundColor Red
					$failed = $true
				}
			}
			ELSE
			{
				Write-ScriptLog -Step 'SCOM Version Check' -Status Failed -LogString "A SCOM Management Server Role has been detected however it is not a known version supported by this script" -ForegroundColor Red
				Write-ScriptLog -Step 'SCOM Version Check' -Status Failed -LogString "Version found for Microsoft.EnterpriseManagement.RuntimeService.dll ($ServerURFileVersion)" -ForegroundColor Red
				$failed = $true
			}
		}
		Script-Failed -Step 'SCOM Version Check' -failed $failed
		#endregion CheckManagementServer
		#region CheckWebConsole
		IF (-not $SkipVersionCheck -and $WebConsoleServer)
		{
			$WebConsoleFilePath = $WebConsolePath + "Microsoft.Mom.Common.dll"
			Write-ScriptLog -Step 'SCOM Version Check' -ForegroundColor Gray -LogString "Web Console filepath: $WebConsoleFilePath"
			$WebConsoleFile = Get-Item $WebConsoleFilePath
			$WebConsoleFileVersion = $WebConsoleFile.VersionInfo.FileVersion
			Write-ScriptLog -Step 'SCOM Version Check' -ForegroundColor Gray -LogString "Web Console file version: $WebConsoleFileVersion"
			$WebConsoleFileVersionSplit = $WebConsoleFileVersion.Split(".")
			[double]$MajorWebConsoleVersion = $WebConsoleFileVersionSplit[0] + "." + $WebConsoleFileVersionSplit[1]
			IF ($MajorWebConsoleVersion -ge "10.22")
			{
				# This is a SCOM 2022 (or later) Web Console Server
				Write-ScriptLog -Step 'SCOM Version Check' -Status Passed -LogString "Web Console Server role version 2022 or later detected which supports TLS 1.2" -ForegroundColor Green
				$failed = $false
				$SCOM2022 = $true
			}
			ELSEIF ($MajorWebConsoleVersion -ge "10.19")
			{
				# This is a SCOM 2019 Web Console Server
				Write-ScriptLog -Step 'SCOM Version Check' -Status Passed -LogString "Web Console Server role version 2019 detected which supports TLS 1.2" -ForegroundColor Green
				$failed = $false
				$SCOM2019 = $true
			}
			ELSEIF ($MajorWebConsoleVersion -ge "7.3")
			{
				# This is a SCOM 1801 or 1807 Web Console Server
				Write-ScriptLog -Step 'SCOM Version Check' -Status Passed -LogString "Web Console Server role version 1801/1807 or later detected which supports TLS 1.2" -ForegroundColor Green
				$failed = $false
				$SCOM2016 = $true
			}
			ELSEIF ($MajorWebConsoleVersion -eq "7.2")
			{
				# This is a SCOM 2016 WebConsole
				# Get a file that is included in UR4 and later for version checking
				$WebConsole2016URFilePath = $WebConsolePath + "WebHost\bin\Microsoft.EnterpriseManagement.Management.DataProviders.dll"
				Write-ScriptLog -Step 'SCOM Version Check' -ForegroundColor Gray -LogString "SCOM 2016 Web Console Update Rollup 4 (or later) filepath: $WebConsole2016URFilePath"
				$WebConsole2016URFile = Get-Item $WebConsole2016URFilePath
				$WebConsole2016URFileVersion = $WebConsole2016URFile.VersionInfo.FileVersion
				Write-ScriptLog -Step 'SCOM Version Check' -ForegroundColor Gray -LogString "SCOM 2016 Web Console Update Rollup 4 (or later) file version: $WebConsole2016URFileVersion"
				$WebConsole2016URFileVersionSplit = $WebConsole2016URFileVersion.Split(".")
				[int]$2016URVersion = $WebConsole2016URFileVersionSplit[2]
				IF ($2016URVersion -ge 11938)
				{
					#This is UR4 or later
					Write-ScriptLog -Step 'SCOM Version Check' -Status Passed -LogString "Web Console Server role version 2016 UR4 or later detected which supports TLS 1.2" -ForegroundColor Green
					$failed = $false
					$SCOM2016 = $true
				}
				ELSE
				{
					Write-ScriptLog -Step 'SCOM Version Check' -Status Failed -LogString "SCOM 2016 UR4 was not found on this SCOM 2016 Web Console. Please ensure UR4 is applied before continuing." -ForegroundColor Red
					Write-ScriptLog -Step 'SCOM Version Check' -Status Failed -LogString "Version found for Microsoft.EnterpriseManagement.Management.DataProviders.dll ($WebConsole2016URFileVersion)" -ForegroundColor Red
					$failed = $true
				}
			}
			ELSEIF ($MajorWebConsoleVersion -eq "7.1")
			{
				# This is a SCOM 2012R2 WebConsole
				$WebConsole2012URFilePath = $WebConsolePath + "WebHost\bin\Microsoft.EnterpriseManagement.Management.DataProviders.dll"
				Write-ScriptLog -Step 'SCOM Version Check' -ForegroundColor Gray -LogString "SCOM 2012 R2 Web Console Update Rollup filepath: $WebConsole2012URFilePath"
				$WebConsole2012URFile = Get-Item $WebConsole2012URFilePath
				$WebConsole2012URFileVersion = $WebConsole2012URFile.VersionInfo.FileVersion
				Write-ScriptLog -Step 'SCOM Version Check' -ForegroundColor Gray -LogString "SCOM 2012R2 Web Console Update Rollup file version: $WebConsole2012URFileVersion"
				$WebConsole2012URFileVersionSplit = $WebConsole2012URFileVersion.Split(".")
				[int]$2012URVersion = $WebConsole2012URFileVersionSplit[3]
				IF ($2012URVersion -ge 1387)
				{
					#This is UR14 or later
					Write-ScriptLog -Step 'SCOM Version Check' -Status Passed -LogString "Web Console Server role version 2012R2 UR14 or later detected which supports TLS 1.2" -ForegroundColor Green
					$failed = $false
					$SCOM2012 = $true
				}
				ELSE
				{
					Write-ScriptLog -Step 'SCOM Version Check' -Status Failed -LogString "SCOM 2012R2 UR14 was not found on this SCOM 2012R2 WebConsole. Please ensure UR14 is applied before continuing." -ForegroundColor Red
					Write-ScriptLog -Step 'SCOM Version Check' -Status Failed -LogString "Version found for Microsoft.EnterpriseManagement.Management.DataProviders.dll ($WebConsole2012URFileVersion)" -ForegroundColor Red
					$failed = $true
				}
			}
			ELSE
			{
				Write-ScriptLog -Step 'SCOM Version Check' -Status Failed -LogString "A SCOM Web Console Server Role has been detected however it is not a version supported by this script" -ForegroundColor Red
				Write-ScriptLog -Step 'SCOM Version Check' -Status Failed -LogString "Version found for ($WebConsoleFilePath) is ($WebConsoleFileVersion)" -ForegroundColor Red
				$failed = $true
			}
		}
		Script-Failed -Step 'SCOM Version Check' -failed $failed
		#endregion
	}
	
	#region CheckIfSQLServer
	try
	{
		$IsSQLServer = Get-ItemProperty -Path "HKLM:\Software\Microsoft\MSSQLServer\MSSQLServer\CurrentVersion" -ErrorAction Stop
	}
	catch
	{
		$IsSQLServer = $null
	}
	
	#region TestDotNetFramework
	###################################################
	# Test .NET Framework version on ALL servers
	if (-not $SkipDotNetCheck)
	{
		Write-ScriptLog -Step '.NET Check' -LogString "Checking if .NET Framework Version is 4.6 or later."
		$Error.Clear()
		# Get version from registry
		$RegPath = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\"
		[int]$ReleaseRegValue = (Get-ItemProperty $RegPath).Release
		Write-ScriptLog -Step '.NET Check' -ForegroundColor Gray -LogString ".NET Framework Release Registry Value: $ReleaseRegValue"
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
			"528449" { ".NET Framework 4.8" }
			"533320" { ".NET Framework 4.8.1" }
			'533325' { ".NET Framework 4.8.1" }
			default { "Unknown version of .NET version: $ReleaseRegValue" }
		}
		# Check if version is 4.6 or higher
		IF ($ReleaseRegValue -ge 393295)
		{
			Write-ScriptLog -Step '.NET Check' -Status Passed -LogString ".NET version 4.6 or later is installed" -ForegroundColor Green
			Write-ScriptLog -Step '.NET Check' -Status Passed -LogString "Detected version is: ($VersionString)" -ForegroundColor Green
			$failed = $false
		}
		ELSE
		{
			Write-ScriptLog -Step '.NET Check' -Status Failed -LogString ".NET version 4.6 or later is NOT installed" -ForegroundColor Red
			Write-ScriptLog -Step '.NET Check' -Status Failed -LogString "Detected version is: ($VersionString)" -ForegroundColor Red
			$failed = $true
		}
		Script-Failed -Step '.NET Check' -failed $failed
	}
	
	#endregion
	#region CheckSQLServerVersions
	###################################################
	# Get SQL Server Version to check for TLS Support
	IF (-not $SkipSQLQueries -and $ManagementServer)
	{
		Write-ScriptLog -Step 'SQL Check' -LogString "Checking SQL Server Versions to ensure they support TLS 1.2."
		#region CheckOpsDB
		$Error.Clear()
		# This is a management server. Try to get the database values.
		$OpsSQLServer = (Get-ItemProperty $SCOMRegPath).DatabaseServerName
		$DWSQLServer = (Get-ItemProperty $SCOMRegPath).DataWarehouseDBServerName
		$OpsDBName = (Get-ItemProperty $SCOMRegPath).DatabaseName
		$DWDBName = (Get-ItemProperty $SCOMRegPath).DataWarehouseDBName
		# Connect to and query SQL for OpsDB
		$SqlQuery = "SELECT SERVERPROPERTY('ProductVersion') AS 'Version'"
		$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
		$SqlConnection.ConnectionString = "Server=$OpsSQLServer; Database=master; Integrated Security=True"
		$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
		$SqlCmd.Connection = $SqlConnection
		$SqlCmd.CommandText = $SqlQuery
		$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
		$SqlAdapter.SelectCommand = $SqlCmd
		$ds = New-Object System.Data.DataSet
		$SqlAdapter.Fill($ds) | Out-Null
		$SQLOutput = $ds.Tables[0]
		$SQLVersion = $SQLOutput.Version
		Write-ScriptLog -Step 'SQL Check' -ForegroundColor Gray -LogString "Operations DB ($OpsDBName) SQL Server version: $SQLVersion"
		$SQLVersionSplit = $SQLVersion.split(".")
		[int]$SQLMajorVersion = $SQLVersionSplit[0]
		IF ($SQLMajorVersion -ge 13)
		{
			Write-ScriptLog -Step 'SQL Check' -Status Passed -LogString "Operations DB Server: This is SQL 2016 or later. All versions of SQL 2016 and later support TLS 1.2 so no patch/update is required on server ($OpsSQLServer)" -ForegroundColor Green
		}
		ELSEIF ($SQLMajorVersion -eq 12)
		{
			[int]$SQLMinorVersion = $SQLVersionSplit[2]
			IF ($SQLMinorVersion -ge 4439)
			{
				Write-ScriptLog -Step 'SQL Check' -Status Passed -LogString "Operations DB Server: This is SQL 2014. We detected a version that is greater than SQL 2014 SP1 CU5, so no patch/update is required on server ($OpsSQLServer)." -ForegroundColor Green
				Write-ScriptLog -Step 'SQL Check' -Status Passed -LogString "Minimum version: (12.0.4439.1)" -ForegroundColor Green
				Write-ScriptLog -Step 'SQL Check' -Status Passed -LogString "Detected version: ($SQLVersion)" -ForegroundColor Green
				$failed = $false
			}
			ELSE
			{
				Write-ScriptLog -Step 'SQL Check' -Status Failed -LogString "Operations DB Server: This is SQL 2014, and we detected a version that does not support TLS 1.2 on server ($OpsSQLServer)" -ForegroundColor Red
				Write-ScriptLog -Step 'SQL Check' -Status Failed -LogString "Minimum version: (12.0.4439.1)" -ForegroundColor Red
				Write-ScriptLog -Step 'SQL Check' -Status Failed -LogString "Detected version: ($SQLVersion)" -ForegroundColor Red
				$failed = $true
			}
		}
		ELSEIF ($SQLMajorVersion -eq 11)
		{
			[int]$SQLMinorVersion = $SQLVersionSplit[2]
			IF ($SQLMinorVersion -ge 6216)
			{
				Write-ScriptLog -Step 'SQL Check' -Status Passed -LogString "Operations DB Server: This is SQL 2012. We detected a version that is greater than SQL 2012 SP3 with TLS Update, so no patch/update is required on server ($OpsSQLServer)." -ForegroundColor Green
				Write-ScriptLog -Step 'SQL Check' -Status Passed -LogString "Minimum version: (11.0.6216.0)" -ForegroundColor Green
				Write-ScriptLog -Step 'SQL Check' -Status Passed -LogString "Detected version: ($SQLVersion)" -ForegroundColor Green
				$failed = $false
			}
			ELSE
			{
				Write-ScriptLog -Step 'SQL Check' -Status Failed -LogString "Operations DB Server: This is SQL 2012, and we detected a version that does not support TLS 1.2 on server ($OpsSQLServer)" -ForegroundColor Red
				Write-ScriptLog -Step 'SQL Check' -Status Failed -LogString "Minimum version: (11.0.6216.0)" -ForegroundColor Red
				Write-ScriptLog -Step 'SQL Check' -Status Failed -LogString "Detected version: ($SQLVersion)" -ForegroundColor Red
				$failed = $true
			}
		}
		ELSEIF ($SQLMajorVersion -eq 10 -and $SQLVersionSplit[1] -eq 50)
		{
			[int]$SQLMinorVersion = $SQLVersionSplit[2]
			IF ($SQLMinorVersion -ge 6542)
			{
				Write-ScriptLog -Step 'SQL Check' -Status Passed -LogString "Operations DB Server: This is SQL 2008R2. We detected a version that is greater than SQL 2008R2 SP3 with TLS update, so no patch/update is required on server ($OpsSQLServer)." -ForegroundColor Green
				Write-ScriptLog -Step 'SQL Check' -Status Passed -LogString "Minimum version: (10.50.6542.0)" -ForegroundColor Green
				Write-ScriptLog -Step 'SQL Check' -Status Passed -LogString "Detected version: ($SQLVersion)" -ForegroundColor Green
				$failed = $false
			}
			ELSE
			{
				Write-ScriptLog -Step 'SQL Check' -Status Failed -LogString "Operations DB Server: This is SQL 2008R2, and we detected a version that does not support TLS 1.2 on server ($OpsSQLServer)" -ForegroundColor Red
				Write-ScriptLog -Step 'SQL Check' -Status Failed -LogString "Minimum version: (10.50.6542.0)" -ForegroundColor Red
				Write-ScriptLog -Step 'SQL Check' -Status Failed -LogString "Detected version: ($SQLVersion)" -ForegroundColor Red
				$failed = $true
			}
		}
		ELSE
		{
			Write-ScriptLog -Step 'SQL Check' -Status Failed -LogString "Operations DB Server: We did not detect a supported version of SQL for SCOM and TLS 1.2 on server ($OpsSQLServer)" -ForegroundColor Red
			$failed = $true
		}
		Script-Failed -Step 'SQL Check' -failed $failed
		#endregion
		
		#region CheckDW
		# Connect to and query SQL for Data Warehouse SQL Server
		$SqlQuery = "SELECT SERVERPROPERTY('ProductVersion') AS 'Version'"
		$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
		$SqlConnection.ConnectionString = "Server=$DWSQLServer; Database=master; Integrated Security=True"
		$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
		$SqlCmd.Connection = $SqlConnection
		$SqlCmd.CommandText = $SqlQuery
		$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
		$SqlAdapter.SelectCommand = $SqlCmd
		$ds = New-Object System.Data.DataSet
		$SqlAdapter.Fill($ds) | Out-Null
		$SQLOutput = $ds.Tables[0]
		$SQLVersion = $SQLOutput.Version
		Write-ScriptLog -Step 'SQL Check' -ForegroundColor Gray -LogString "Data Warehouse DB ($DWDBName) SQL Server version: $SQLVersion"
		$SQLVersionSplit = $SQLVersion.split(".")
		[int]$SQLMajorVersion = $SQLVersionSplit[0]
		IF ($SQLMajorVersion -ge 13)
		{
			Write-ScriptLog -Step 'SQL Check' -Status Passed -LogString "Data Warehouse Server: This is SQL 2016 or later. All versions of SQL 2016 and later support TLS 1.2 so no patch/update is required on server ($DWSQLServer)" -ForegroundColor Green
		}
		ELSEIF ($SQLMajorVersion -eq 12)
		{
			[int]$SQLMinorVersion = $SQLVersionSplit[2]
			IF ($SQLMinorVersion -ge 4439)
			{
				Write-ScriptLog -Step 'SQL Check' -Status Passed -LogString "Data Warehouse Server: This is SQL 2014. We detected a version that is greater than SQL 2014 SP1 CU5, so no patch/update is required on server ($DWSQLServer)." -ForegroundColor Green
				Write-ScriptLog -Step 'SQL Check' -Status Passed -LogString "Minimum version: (12.0.4439.1)" -ForegroundColor Green
				Write-ScriptLog -Step 'SQL Check' -Status Passed -LogString "Detected version: ($SQLVersion)" -ForegroundColor Green
				$failed = $false
			}
			ELSE
			{
				Write-ScriptLog -Step 'SQL Check' -Status Failed -LogString "Data Warehouse Server: This is SQL 2014, and we detected a version that does not support TLS 1.2 on server ($DWSQLServer)" -ForegroundColor Red
				Write-ScriptLog -Step 'SQL Check' -Status Failed -LogString "Minimum version: (12.0.4439.1)" -ForegroundColor Red
				Write-ScriptLog -Step 'SQL Check' -Status Failed -LogString "Detected version: ($SQLVersion)" -ForegroundColor Red
				$failed = $true
			}
		}
		ELSEIF ($SQLMajorVersion -eq 11)
		{
			[int]$SQLMinorVersion = $SQLVersionSplit[2]
			IF ($SQLMinorVersion -ge 6216)
			{
				Write-ScriptLog -Step 'SQL Check' -Status Passed -LogString "Data Warehouse Server: This is SQL 2012. We detected a version that is greater than SQL 2012 SP3 with TLS Update, so no patch/update is required on server ($DWSQLServer)." -ForegroundColor Green
				Write-ScriptLog -Step 'SQL Check' -Status Passed -LogString "Minimum version: (11.0.6216.0)" -ForegroundColor Green
				Write-ScriptLog -Step 'SQL Check' -Status Passed -LogString "Detected version: ($SQLVersion)" -ForegroundColor Green
				$failed = $false
			}
			ELSE
			{
				Write-ScriptLog -Step 'SQL Check' -Status Failed -LogString "Data Warehouse Server: This is SQL 2012, and we detected a version that does not support TLS 1.2 on server ($DWSQLServer)" -ForegroundColor Red
				Write-ScriptLog -Step 'SQL Check' -Status Failed -LogString "Minimum version: (11.0.6216.0)" -ForegroundColor Red
				Write-ScriptLog -Step 'SQL Check' -Status Failed -LogString "Detected version: ($SQLVersion)" -ForegroundColor Red
				$failed = $true
			}
		}
		ELSEIF ($SQLMajorVersion -eq 10 -and $SQLVersionSplit[1] -eq 50)
		{
			[int]$SQLMinorVersion = $SQLVersionSplit[2]
			IF ($SQLMinorVersion -ge 6542)
			{
				Write-ScriptLog -Step 'SQL Check' -Status Passed -LogString "Data Warehouse Server: This is SQL 2008R2. We detected a version that is greater than SQL 2008R2 SP3 with TLS update, so no patch/update is required on server ($DWSQLServer)." -ForegroundColor Green
				Write-ScriptLog -Step 'SQL Check' -Status Passed -LogString "Minimum version: (10.50.6542.0)" -ForegroundColor Green
				Write-ScriptLog -Step 'SQL Check' -Status Passed -LogString "Detected version: ($SQLVersion)" -ForegroundColor Green
				$failed = $false
			}
			ELSE
			{
				Write-ScriptLog -Step 'SQL Check' -Status Failed -LogString "Data Warehouse Server: This is SQL 2008R2, and we detected a version that does not support TLS 1.2 on server ($DWSQLServer)" -ForegroundColor Red
				Write-ScriptLog -Step 'SQL Check' -Status Failed -LogString "Minimum version: (10.50.6542.0)" -ForegroundColor Red
				Write-ScriptLog -Step 'SQL Check' -Status Failed -LogString "Detected version: ($SQLVersion)" -ForegroundColor Red
				$failed = $true
			}
		}
		ELSE
		{
			Write-ScriptLog -Step 'SQL Check' -Status Failed -LogString "Data Warehouse Server: We did not detect a supported version of SQL for SCOM and TLS 1.2 on server ($DWSQLServer)" -ForegroundColor Red
			$failed = $true
		}
		Script-Failed -Step 'SQL Check' -failed $failed
		#endregion
	}
	###################################################
	#endregion
	
	#region SoftwarePrerequisites
	###################################################
	# Software Prerequisites for Management Servers and Web Console servers
	IF (-not $SkipSQLSoftwarePrerequisites -and ($ManagementServer -or $WebConsoleServer) -or $IsSQLServer)
	{
		Write-ScriptLog -Step 'Check SQL Prerequisites' -LogString "Checking OLEDB version, ODBC Driver, and SQL Client version version for TLS 1.2 support."
		$failed = $false
		$Error.Clear()
		
		#region OLEDB
		### Check if OLEDB Driver is installed
		$MSOLEDB = "$env:SYSTEMROOT\system32\msoledbsql.dll"
		
		function Install-MSOLEDB
		{
			$Error.Clear()
			$MSOLEDBInstallFlag = $true
			$MSOLEDB = $null
			try
			{
				$MSOLEDB = Get-Item "$DirectoryForPrerequisites\msoledbsql_*.msi" -ErrorAction Stop | Select-Object -First 1 -ErrorAction Stop
				Write-ScriptLog -Step 'Check SQL Prerequisites' -Status 'Found File' -LogString "Found file with this name: '$($MSOLEDB.FullName)'" -ForegroundColor Green
			}
			catch
			{
				Write-ScriptLog -Step 'Check SQL Prerequisites' -Status 'File not found' -LogString "Did not detect any file with this name: 'msoledbsql_*.msi'" -ForegroundColor Red
			}
			if (-not $MSOLEDB)
			{
				try
				{
					$MSOLEDB = Get-Item "$DirectoryForPrerequisites\msoledbsql.msi" -ErrorAction Stop
					Write-ScriptLog -Step 'Check SQL Prerequisites' -Status 'Found File' -LogString "Found file with this name: '$($MSOLEDB.FullName)'" -ForegroundColor Green
				}
				catch
				{
					Write-ScriptLog -Step 'Check SQL Prerequisites' -Status 'File not found' -LogString "Could not locate file: msoledbsql.msi" -ForegroundColor Red
					$failed = $true
					Script-Failed -step 'Check SQL Prerequisites' -failed $failed
				}
			}
			if ($MSOLEDB)
			{
				msiexec /qb /i "$($MSOLEDB.FullName)" IACCEPTMSOLEDBSQLLICENSETERMS=YES | Out-Null
				IF ($Error)
				{
					Write-ScriptLog "Error occurred. Error is: ($Error)"
					$failed = $true
				}
			}
			else
			{
				Write-ScriptLog "Unable to locate the file: msoledbsql.msi"
			}
		}
		
		IF (Test-Path $MSOLEDB)
		{
			$MSOLEDBGood = $false
			[version]$MSOLEDBversion = (Get-ItemProperty $MSOLEDB).VersionInfo.ProductVersion
			if ($MSOLEDBversion.Major -ge 19)
			{
				Write-ScriptLog -Step 'Check SQL Prerequisites' -Status Passed -LogString "MSOLEDB - is now installed and on a valid version ($MSOLEDBversion) (Don't forget you need to do extra configuration for the Certificate on this version of MSOLEDB: https://learn.microsoft.com/sql/database-engine/configure-windows/manage-certificates)." -ForegroundColor Green
				$MSOLEDBGood = $true
			}
			elseif ($MSOLEDBversion.Major -ge 18)
			{
				Write-ScriptLog -Step 'Check SQL Prerequisites' -Status Passed -LogString "MSOLEDB - version $MSOLEDBversion is installed" -ForegroundColor Green
				$MSOLEDBGood = $true
			}
			else
			{
				Write-ScriptLog -Step 'Check SQL Prerequisites' -LogString "MSOLEDB - is installed but is not within the valid versions (18 and newer). We will attempt to upgrade now." -ForegroundColor Yellow
				
				#region UpgradeMSOLEDB
				$MSOLEDBFileExists = Test-Path "$DirectoryForPrerequisites\msoledbsql.msi"
				IF (!($MSOLEDBFileExists))
				{
					Write-ScriptLog -Step 'Check SQL Prerequisites' -Status Failed -LogString "Path to MSOLEDB install file not found. Ensure that the file (msoledbsql.msi) is in the same directory as this script." -ForegroundColor Red
					$failed = $true
				}
				else
				{
					Install-MSOLEDB
				}
				#endregion
			}
			Script-Failed -step 'Check SQL Prerequisites' -failed $failed
		}
		else
		{
			Write-ScriptLog -Step 'Check SQL Prerequisites' -LogString "MSOLEDB - is NOT installed." -ForegroundColor Yellow
			if (-NOT $AssumeYes)
			{
				do
				{
					$InstallOLEDB = Read-Host "$(Get-CurrentDate)Do you want to install MSOLEDB? (Y/N)"
					Write-ScriptLog -LogString "Do you want to install MSOLEDB? (Y/N): $InstallOLEDB" -NoOutput
				}
				until ($InstallOLEDB -match "^Y|^N")
			}
			else
			{
				$InstallOLEDB = 'Y'
			}
			
			
			if ($InstallOLEDB -match "^Y")
			{
				Write-ScriptLog -Step 'Check SQL Prerequisites' -LogString "Installing MSOLEDB." -ForegroundColor Yellow
				Install-MSOLEDB
			}
			else
			{
				Write-ScriptLog -Step 'Check SQL Prerequisites' -LogString "NOT installing MSOLEDB." -ForegroundColor Yellow
			}
			### Recheck if MSOLEDB is installed after an install attempt
			IF ((Test-Path $MSOLEDB) -and ($InstallOLEDB -match "^Y"))
			{
				$MSOLEDBGood = $false
				[version]$MSOLEDBversion = (Get-ItemProperty $MSOLEDB).VersionInfo.ProductVersion
				if ($MSOLEDBversion.Major -ge 19)
				{
					Write-ScriptLog -Step 'Check SQL Prerequisites' -Status Passed -LogString "MSOLEDB - is now installed and on a valid version ($MSOLEDBversion) (Don't forget you need to do extra configuration for the Certificate on this version of MSOLEDB: https://learn.microsoft.com/sql/database-engine/configure-windows/manage-certificates)." -ForegroundColor Green
					$MSOLEDBGood = $true
				}
				elseif ($MSOLEDBversion.Major -ge 18)
				{
					Write-ScriptLog -Step 'Check SQL Prerequisites' -Status Passed -LogString "MSOLEDB - is now installed and on a valid version ($MSOLEDBversion)." -ForegroundColor Green
					$MSOLEDBGood = $true
				}
				else
				{
					Write-ScriptLog -Step 'Check SQL Prerequisites' -LogString "MSOLEDB - is installed but is not within the valid versions (18 and newer)." -ForegroundColor Yellow
					$MSOLEDBGood = $false
				}
				
			}
		}
		#endregion
		
		#region SQLClient
		function Install-SQLClient
		{
			$Error.Clear()
			# Check if SQL Client 'sqlncli.msi' is present
			$SQLClient = $null
			try
			{
				$SQLClient = Get-Item "$DirectoryForPrerequisites\sqlncli_*.msi" -ErrorAction Stop | Select-Object -First 1
				Write-ScriptLog -Step 'Check SQL Prerequisites' -Status 'Found File' -LogString "Found file with this name: '$($SQLClient.FullName)'" -ForegroundColor Green
			}
			catch
			{
				Write-Verbose "Did not detect any file with this name: 'sqlncli_*.msi'"
			}
			if (-not $SQLClient)
			{
				try
				{
					$SQLClient = Get-Item "$DirectoryForPrerequisites\sqlncli.msi" -ErrorAction Stop
					Write-ScriptLog -Step 'Check SQL Prerequisites' -Status 'Found File' -LogString "Found file with this name: '$($SQLClient.FullName)'" -ForegroundColor Green
				}
				catch
				{
					Write-ScriptLog -Step 'Check SQL Prerequisites' -Status 'File not found' -LogString "Path to SQL Native Client 11.4.7001.0 install file not found. Ensure that sqlncli.msi is in the same directory as this script." -ForegroundColor Red
					$failed = $true
					Script-Failed -step 'Check SQL Prerequisites' -failed $failed
				}
			}
			
			# Install SQL Client
			msiexec /qb /i "$SQLClient" IACCEPTSQLNCLILICENSETERMS=YES | Out-Null
			IF ($Error)
			{
				Write-ScriptLog -Step 'Check SQL Prerequisites' -Status Failed -LogString "Error occurred. Error is: ($Error)"
				$failed = $true
			}
			Script-Failed -Step 'Check SQL Prerequisites' -failed $failed
		}
		if ($SCOM2012 -or $SCOM2016 -and -not $MSOLEDBGood)
		{
			### Check if SQL Client is installed
			$RegPath = "HKLM:\SOFTWARE\Microsoft\SQLNCLI11"
			IF (Test-Path $RegPath)
			{
				[string]$SQLClient11VersionString = (Get-ItemProperty $RegPath)."InstalledVersion"
				[version]$SQLClient11Version = [version]$SQLClient11VersionString
			}
			[version]$MinSQLClient11Version = [version]"11.4.7001.0"
			$SQLClientInstallFlag = $false
			IF ($SQLClient11Version -ge $MinSQLClient11Version)
			{
				Write-ScriptLog -Step 'Check SQL Prerequisites' -Status Passed -LogString "SQL Client - is installed and version: ($SQLClient11VersionString) and greater or equal to the minimum version required: (11.4.7001.0)" -ForegroundColor Green
			}
			ELSEIF ($SQLClient11VersionString)
			{
				Write-ScriptLog -Step 'Check SQL Prerequisites' -LogString "SQL Client - is installed and version: ($SQLClient11VersionString) but below the minimum version of (11.4.7001.0)." -ForegroundColor Yellow
				$SQLClientInstallFlag = $true
			}
			ELSE
			{
				Write-ScriptLog -Step 'Check SQL Prerequisites' -LogString "SQL Client - is NOT installed." -ForegroundColor Yellow
				$SQLClientInstallFlag = $true
			}
			IF ($SQLClientInstallFlag)
			{
				if (-NOT $AssumeYes)
				{
					do
					{
						$InstallSQLClient = Read-Host "$(Get-CurrentDate)Do you want to install SQL Client? (Y/N)"
						Write-ScriptLog -LogString "Do you want to install SQL Client? (Y/N): $InstallSQLClient" -NoOutput
					}
					until ($InstallSQLClient -match "^Y|^N")
				}
				else
				{
					$InstallSQLClient = 'Y'
				}
				
				
				if ($InstallSQLClient -match "^Y")
				{
					Write-ScriptLog -Step 'Check SQL Prerequisites' -LogString "Installing SQL Client." -ForegroundColor Yellow
					Install-SQLClient
				}
				else
				{
					Write-ScriptLog -Step 'Check SQL Prerequisites' -LogString "NOT installing SQL Client." -ForegroundColor Yellow
				}
			}
			### Recheck if SQL Client is installed after an install attempt
			IF ($SQLClientInstallFlag)
			{
				### Check if SQL Client is installed
				$RegPath = "HKLM:\SOFTWARE\Microsoft\SQLNCLI11"
				IF (Test-Path $RegPath)
				{
					[string]$SQLClient11VersionString = (Get-ItemProperty $RegPath)."InstalledVersion"
					[version]$SQLClient11Version = [version]$SQLClient11VersionString
				}
				[version]$MinSQLClient11Version = [version]"11.4.7001.0"
				IF ($SQLClient11Version -ge $MinSQLClient11Version)
				{
					Write-ScriptLog -Step 'Check SQL Prerequisites' -Status Passed -LogString "SQL Client - is installed and version: ($SQLClient11VersionString) and greater or equal to the minimum version required: (11.4.7001.0)" -ForegroundColor Green
					$failed = $false
				}
				ELSE
				{
					Write-ScriptLog -Step 'Check SQL Prerequisites' -Status Failed -LogString "We could not verify that SQL Client 11 is installed and is a version that supports TLS. Version Expected: (11.4.7001.0) Version detected ($SQLClient11VersionString)." -ForegroundColor Red
					$failed = $true
				}
			}
			Script-Failed -Step 'Check SQL Prerequisites' -failed $failed
		}
		
		#endregion
		
		#region ODBC
		### Check if ODBC 13 (or later) driver is installed
		$RegPath = "HKLM:\SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers"
		$ODBCGood = $false
		$ODBCInstallFlag = $false
		function Install-ODBC
		{
			$Error.Clear()
			$ODBCInstallFlag = $true
			$ODBC = $null
			try
			{
				$ODBC = Get-Item "$DirectoryForPrerequisites\msodbcsql_*.msi" -ErrorAction Stop | Select-Object -First 1
				Write-ScriptLog -Step 'Check SQL Prerequisites' -Status 'Found File' -LogString "Found file with this name: '$($ODBC.FullName)'" -ForegroundColor Green
			}
			catch
			{
				Write-ScriptLog -Step 'Check SQL Prerequisites' -Status 'File not found' -LogString "Did not detect any file with this name: 'msodbcsql_*.msi'" -ForegroundColor Red
			}
			if (-not $ODBC)
			{
				try
				{
					$ODBC = Get-Item "$DirectoryForPrerequisites\msodbcsql.msi" -ErrorAction Stop
					Write-ScriptLog -Step 'Check SQL Prerequisites' -Status 'Found File' -LogString "Found file with this name: '$($ODBC.FullName)'" -ForegroundColor Green
				}
				catch
				{
					Write-ScriptLog -Step 'Check SQL Prerequisites' -Status 'File not found' -LogString "Could not locate file: msodbcsql.msi" -ForegroundColor Red
					$failed = $true
					Script-Failed -step 'Check SQL Prerequisites' -failed $failed
				}
			}
			if ($ODBC)
			{
				msiexec /qb /i "$ODBC" IACCEPTMSODBCSQLLICENSETERMS=YES | Out-Null
				IF ($Error)
				{
					Write-ScriptLog "Error occurred. Error is: ($Error)" -Status Error
					$failed = $true
				}
			}
			else
			{
				Write-ScriptLog "Unable to locate the file: msodbcsql.msi"
			}
		}
		$scriptText = $null
		IF (($SCOM1801_1807 -or $SCOM2016 -or $SCOM2019 -or $SCOM2022 -or $SCOM2022andUP) -and -NOT $ODBCGood -and (Get-ItemProperty $RegPath)."ODBC Driver 19 for SQL Server" -eq "Installed")
		{
			$scriptText = "ODBC Driver - version $((Get-ItemProperty "$env:WINDIR\system32\msodbcsql19.dll").VersionInfo.ProductVersion) is installed (Don't forget you may need to do extra configuration for the Certificate on this version of ODBC: https://learn.microsoft.com/sql/database-engine/configure-windows/manage-certificates"
			$failed = $false
			$ODBCGood = $true
		}
		ELSE
		{
			$scriptText = "We could not verify that ODBC Driver Version 19 is installed."
			$failed = $true
			$ODBCGood = $false
		}
		IF (($SCOM1801_1807 -or $SCOM2016 -or $SCOM2019 -or $SCOM2022 -or $SCOM2022andUP) -and -NOT $ODBCGood -and (Get-ItemProperty $RegPath)."ODBC Driver 18 for SQL Server" -eq "Installed")
		{
			$scriptText = "ODBC Driver - version $((Get-ItemProperty "$env:WINDIR\system32\msodbcsql18.dll").VersionInfo.ProductVersion) is installed (Don't forget you may need to do extra configuration for the Certificate on this version of ODBC: https://learn.microsoft.com/sql/database-engine/configure-windows/manage-certificates"
			$failed = $false
			$ODBCGood = $true
		}
		ELSE
		{
			if ($ODBCGood)
			{
				Out-Null
			}
			else
			{
				$scriptText = "We could not verify that ODBC Driver Version 18 is installed."
				$failed = $true
				$ODBCGood = $false
			}
		}
		IF (($SCOM1801_1807 -or $SCOM2016 -or $SCOM2019 -or $SCOM2022 -or $SCOM2022andUP) -and -NOT $ODBCGood -and (Get-ItemProperty $RegPath)."ODBC Driver 17 for SQL Server" -eq "Installed")
		{
			$scriptText = "ODBC Driver - version $((Get-ItemProperty "$env:WINDIR\system32\msodbcsql17.dll").VersionInfo.ProductVersion) is installed"
			$failed = $false
			$ODBCGood = $true
		}
		ELSE
		{
			if ($ODBCGood)
			{
				Out-Null
			}
			else
			{
				$scriptText = "We could not verify that ODBC Driver Version 17 is installed."
				$failed = $true
				$ODBCGood = $false
			}
		}
		IF (($SCOM2012 -or $SCOM2016) -and -NOT $ODBCGood -and (Get-ItemProperty $RegPath)."ODBC Driver 13 for SQL Server" -eq "Installed")
		{
			$scriptText = "ODBC Driver - version $((Get-ItemProperty "$env:WINDIR\system32\msodbcsql13.dll").VersionInfo.ProductVersion) is installed"
			$failed = $false
			$ODBCGood = $true
		}
		ELSE
		{
			if ($ODBCGood)
			{
				Out-Null
			}
			else
			{
				$scriptText = "We could not verify that ODBC Driver Version 13 is installed."
				$failed = $true
				$ODBCGood = $false
			}
		}
		if ($failed)
		{
			Out-Null
		}
		else
		{
			Write-ScriptLog -Step 'Check SQL Prerequisites' -Status Passed -LogString $scriptText -ForegroundColor Green
		}
		
		if (-NOT $ODBCGood)
		{
			Write-ScriptLog -Step 'Check SQL Prerequisites' -LogString "ODBC Driver is not installed." -ForegroundColor Yellow
			if (-NOT $AssumeYes)
			{
				do
				{
					$InstallODBC = Read-Host "$(Get-CurrentDate)Do you want to install ODBC? (Y/N)"
					Write-ScriptLog -LogString "Do you want to install ODBC? (Y/N): $InstallODBC" -NoOutput
				}
				until ($InstallODBC -match "^Y|^N")
			}
			else
			{
				$InstallODBC = 'Y'
			}
			if ($InstallODBC -match "^Y")
			{
				Write-ScriptLog -Step 'Check SQL Prerequisites' -LogString "Installing ODBC." -ForegroundColor Yellow
				Install-ODBC
			}
			else
			{
				Write-ScriptLog -Step 'Check SQL Prerequisites' -LogString "NOT installing ODBC." -ForegroundColor Yellow
			}
		}
		### Recheck if ODBC driver is installed after an install attempt
		IF ($InstallODBC -match "^Y")
		{
			### Check if ODBC driver is installed
			$RegPath = "HKLM:\SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers"
			$ODBCGood = $false
			IF (($SCOM1801_1807 -or $SCOM2016 -or $SCOM2019 -or $SCOM2022 -or $SCOM2022andUP) -and -NOT $ODBCGood -and ((Get-ItemProperty $RegPath)."ODBC Driver 19 for SQL Server" -eq "Installed"))
			{
				$scriptText = "ODBC Driver - version $((Get-ItemProperty "$env:WINDIR\system32\msodbcsql19.dll").VersionInfo.ProductVersion) is installed (Don't forget you need to do extra configuration for the Certificate on this version of ODBC: https://learn.microsoft.com/sql/database-engine/configure-windows/manage-certificates)"
				$failed = $false
				$ODBCGood = $true
			}
			ELSE
			{
				$scriptText = "We could not verify that ODBC Driver Version 19 is installed."
				$failed = $true
				$ODBCGood = $false
			}
			IF (($SCOM1801_1807 -or $SCOM2016 -or $SCOM2019 -or $SCOM2022 -or $SCOM2022andUP) -and -NOT $ODBCGood -and ((Get-ItemProperty $RegPath)."ODBC Driver 18 for SQL Server" -eq "Installed"))
			{
				$scriptText = "ODBC Driver - version $((Get-ItemProperty "$env:WINDIR\system32\msodbcsql18.dll").VersionInfo.ProductVersion) is installed."
				$failed = $false
				$ODBCGood = $true
			}
			ELSE
			{
				if ($ODBCGood)
				{
					Out-Null
				}
				else
				{
					$scriptText = "We could not verify that ODBC Driver Version 18 is installed."
					$failed = $true
					$ODBCGood = $false
				}
			}
			IF (($SCOM1801_1807 -or $SCOM2016 -or $SCOM2019 -or $SCOM2022 -or $SCOM2022andUP) -and -NOT $ODBCGood -and ((Get-ItemProperty $RegPath)."ODBC Driver 17 for SQL Server" -eq "Installed"))
			{
				$scriptText = "ODBC Driver - version $((Get-ItemProperty "$env:WINDIR\system32\msodbcsql17.dll").VersionInfo.ProductVersion) is installed"
				$failed = $false
				$ODBCGood = $true
			}
			ELSE
			{
				if ($ODBCGood)
				{
					Out-Null
				}
				else
				{
					$scriptText = "We could not verify that ODBC Driver Version 17 is installed."
					$failed = $true
					$ODBCGood = $false
				}
			}
			IF (($SCOM2012 -or $SCOM2016) -and -NOT $ODBCGood -and ((Get-ItemProperty $RegPath)."ODBC Driver 13 for SQL Server" -eq "Installed"))
			{
				$scriptText = "ODBC Driver - version $((Get-ItemProperty "$env:WINDIR\system32\msodbcsql13.dll").VersionInfo.ProductVersion) is installed"
				$failed = $false
				$ODBCGood = $true
			}
			ELSE
			{
				if ($ODBCGood)
				{
					Out-Null
				}
				else
				{
					$scriptText = "We could not verify that ODBC Driver Version 13 is installed."
					$failed = $true
					$ODBCGood = $false
				}
			}
		}
		if ($failed)
		{
			Write-ScriptLog -Step 'Check SQL Prerequisites' -Status Failed -LogString $scriptText -ForegroundColor Red
			Script-Failed -Step 'Check SQL Prerequisites' -failed $failed
		}
		elseif ($InstallODBC -match "^Y")
		{
			Write-ScriptLog -Step 'Check SQL Prerequisites' -Status Passed -LogString $scriptText -ForegroundColor Green
		}
		#endregion
	}
	#endregion
	###################################################
	#region ModifyRegistry
	function Start-TLSRegistryChecker
	{
		# Write the registry entries to enforce TLS 1.2
		Write-ScriptLog -Step 'Modify Registry' -LogString "Modifying Registry to enforce TLS 1.2 on Operating System"
		$Error.Clear()
		# Disable everything except TLS 1.2
		$ProtocolList = @("Multi-Protocol Unified Hello", "PCT 1.0", "SSL 2.0", "SSL 3.0", "TLS 1.0", "TLS 1.1", "TLS 1.2")
		$ProtocolSubKeyList = @("Client", "Server")
		$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\"
		
		$OSVersion = [System.Environment]::OSVersion.Version
		if ($OSVersion.Build -gt 20000)
		{
			$SupportsTLS1_3 = $true
			$ProtocolList += "TLS 1.3"
		}
		else
		{
			$SupportsTLS1_3 = $false
		}
		$olderTLSisGood = @()
		foreach ($Protocol in $ProtocolList)
		{
			foreach ($key in $ProtocolSubKeyList)
			{
				$currentRegPath = $registryPath + $Protocol + "\" + $key
				#Write-ScriptLog -Step 'Modify Registry' -LogString "Current Registry Path: `"$currentRegPath`""
				
				if (!(Test-Path $currentRegPath))
				{
					#Write-ScriptLog -Step 'Modify Registry' -LogString " >> `'$key`' not found: Creating new Registry Key"
					New-Item -Path $currentRegPath -Force | out-Null
				}
				
				if (($Protocol -eq "TLS 1.3") -and $SupportsTLS1_3)
				{
					if (-NOT $changeMade)
					{
						$changeMade = $false
					}
					$neededConfiguration = $false
					if ((Get-ItemProperty $currentRegPath)."DisabledByDefault" -ne 0)
					{
						$neededConfiguration = $true
						New-ItemProperty -Path $currentRegPath -Name "DisabledByDefault" -Value "0" -PropertyType DWORD -Force | Out-Null
					}
					
					if ((Get-ItemProperty $currentRegPath).Enabled -ne 1)
					{
						$neededConfiguration = $true
						New-ItemProperty -Path $currentRegPath -Name 'Enabled' -Value "1" -PropertyType DWORD -Force | Out-Null
					}
					if ($neededConfiguration)
					{
						Write-ScriptLog -Step 'Modify Registry' -LogString " >> Enabled - TLS 1.3 ($key)" -ForegroundColor Green
						$changeMade = $true
					}
					else
					{
						if (-NOT $TLS1_3enabled)
						{
							Write-ScriptLog -Step 'Modify Registry' -LogString "TLS 1.3 already enabled ($($registryPath + $Protocol))" -ForegroundColor Green -Status PASSED
							$TLS1_3enabled = $true
						}
					}
				}
				elseif ($Protocol -eq "TLS 1.2")
				{
					if (-NOT $changeMade)
					{
						$changeMade = $false
					}
					$neededConfiguration = $false
					if ((Get-ItemProperty $currentRegPath)."DisabledByDefault" -ne 0)
					{
						$neededConfiguration = $true
						New-ItemProperty -Path $currentRegPath -Name "DisabledByDefault" -Value "0" -PropertyType DWORD -Force | Out-Null
					}
					
					if ((Get-ItemProperty $currentRegPath).Enabled -ne 1)
					{
						$neededConfiguration = $true
						New-ItemProperty -Path $currentRegPath -Name 'Enabled' -Value "1" -PropertyType DWORD -Force | Out-Null
					}
					if ($neededConfiguration)
					{
						Write-ScriptLog -Step 'Modify Registry' -LogString " >> Enabled - TLS 1.2 ($key)" -ForegroundColor Green
						$changeMade = $true
					}
					else
					{
						if (-NOT $TLS1_2enabled)
						{
							Write-ScriptLog -Step 'Modify Registry' -LogString "TLS 1.2 already enabled ($($registryPath + $Protocol))" -ForegroundColor Green -Status PASSED
							$TLS1_2enabled = $true
						}
					}
				}
				else
				{
					if (-NOT $changeMade)
					{
						$changeMade = $false
					}
					$neededConfiguration = $false
					if ((Get-ItemProperty $currentRegPath)."DisabledByDefault" -ne 1)
					{
						$neededConfiguration = $true
						New-ItemProperty -Path $currentRegPath -Name "DisabledByDefault" -Value "1" -PropertyType DWORD -Force | Out-Null
					}
					
					if ((Get-ItemProperty $currentRegPath).Enabled -ne 0)
					{
						$neededConfiguration = $true
						New-ItemProperty -Path $currentRegPath -Name 'Enabled' -Value "0" -PropertyType DWORD -Force | Out-Null
					}
					
					if ($neededConfiguration)
					{
						Write-ScriptLog -Step 'Modify Registry' -LogString " >> Disabled - $Protocol ($key)" -ForegroundColor Yellow
						$olderTLSisGood += 'False'
						$changeMade = $true
					}
					else
					{
						$olderTLSisGood += 'True'
					}
				}
			}
		}
		if ($olderTLSisGood -notmatch "False")
		{
			Write-ScriptLog -Step 'Modify Registry' -LogString "Older TLS protocols are already disabled ($(($ProtocolList | Where-Object { $_ -notmatch "TLS 1.2|TLS 1.3" }) -join ", "))" -ForegroundColor Green -Status PASSED
		}
		IF ($Error)
		{
			Write-ScriptLog -Step 'Modify Registry' -Status Error -LogString "Something went wrong attempting to write to the registry. Review the error and try again. Error is ($Error)." -ForegroundColor Red
			$failed = $true
		}
		Script-Failed -Step 'Modify Registry' -failed $failed
	}
	if (-not $SkipModifyRegistry)
	{
		Start-TLSRegistryChecker
	}
	# Check the TLS settings again, if things were changed
	if ($changeMade)
	{
		Start-TLSRegistryChecker
	}
	$Error.Clear()
	Write-ScriptLog -Step 'Modify Registry' -LogString "Enforcing strong crypto for .NET Framework used by Operations Manager"
	# Tighten up the .NET Framework
	# https://learn.microsoft.com/dotnet/framework/network-programming/tls#configuring-security-via-the-windows-registry
	[array]$NetRegistryPath = "HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727", "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319"
	[array]$Properties = "SystemDefaultTlsVersions", "SchUseStrongCrypto"
	foreach ($Property in $Properties)
	{
		foreach ($RegistryPath in $NetRegistryPath)
		{
			if ($RegistryPath -match "WOW6432")
			{
				$RegistryType = '64bit'
			}
			else
			{
				$RegistryType = '32bit'
			}
			if (-NOT (Get-ItemProperty -Path $RegistryPath).SchUseStrongCrypto)
			{
				Write-ScriptLog -Step 'Modify Registry' -LogString "Enabling '$Property' $RegistryType ($RegistryPath)" -ForegroundColor Yellow
				New-ItemProperty -Path $RegistryPath -Name $Property -Value "1" -PropertyType DWORD -Force | Out-Null
			}
			else
			{
				Write-ScriptLog -Step 'Modify Registry' -LogString "Already configured '$Property' $RegistryType ($RegistryPath)" -ForegroundColor Green -Status PASSED
			}
			
			Start-Sleep -Milliseconds 90
			
		}
	}
	
	IF ($Error)
	{
		Write-ScriptLog -Step 'Modify Registry' -Status Error -LogString "Something went wrong attempting to write to the registry. Review the error and try again. Error is ($Error)." -ForegroundColor Red
		$failed = $true
	}
	
	Script-Failed -Step 'Modify Registry' -failed $failed
	#endregion
	#region ACS
	$Error.Clear()
	IF ($ACS)
	{
		Write-ScriptLog -Step 'Modify ACS Registry' -LogString "Modifying ACS Registry to enforce TLS 1.2"
		if (-not $SkipModifyRegistry)
		{
			#Get the DatabaseName\DSN
			$ACSParamReg = $ACSReg + '\Parameters'
			$ACSDSN = (Get-ItemProperty $ACSParamReg).ODBCConnection
			$ACSODBCReg = "HKLM:\SOFTWARE\ODBC\ODBC.INI\" + $ACSDSN
			
			$ACSODBCRegistry = Get-ItemProperty $ACSODBCReg
			
			# This will always use the higher version of ODBC if possible
			if (Test-Path $env:WINDIR\system32\msodbcsql19.dll)
			{
				$updateRequired = $false
				#Update the registry
				if (($ACSODBCRegistry).Driver -ne '%WINDIR%\system32\msodbcsql19.dll')
				{
					New-ItemProperty -Path $ACSODBCReg -Name "Driver" -Value "%WINDIR%\system32\msodbcsql19.dll" -PropertyType STRING -Force | Out-Null
					$updateRequired = $true
				}
				if ((Get-ItemProperty -Path "HKLM:\SOFTWARE\ODBC\ODBC.INI\ODBC Data Sources").$ACSDSN -ne 'ODBC Driver 19 for SQL Server')
				{
					New-ItemProperty -Path "HKLM:\SOFTWARE\ODBC\ODBC.INI\ODBC Data Sources" -Name $ACSDSN -Value "ODBC Driver 19 for SQL Server" -PropertyType STRING -Force | Out-Null
					$updateRequired = $true
				}
				if ($updateRequired)
				{
					Write-ScriptLog -Step 'Modify ACS Registry' -LogString "Adding ODBC Driver $((Get-ItemProperty "$env:WINDIR\system32\msodbcsql19.dll").VersionInfo.ProductVersion) for SQL Server" -ForegroundColor Green
				}
				else
				{
					Write-ScriptLog -Step 'Modify ACS Registry' -LogString "ODBC Driver $((Get-ItemProperty "$env:WINDIR\system32\msodbcsql19.dll").VersionInfo.ProductVersion) for SQL Server is already present" -ForegroundColor Green -Status PASSED
				}
				
			}
			elseif (Test-Path $env:WINDIR\system32\msodbcsql18.dll)
			{
				#Update the registry
				if (($ACSODBCRegistry).Driver -ne '%WINDIR%\system32\msodbcsql18.dll')
				{
					New-ItemProperty -Path $ACSODBCReg -Name "Driver" -Value "%WINDIR%\system32\msodbcsql18.dll" -PropertyType STRING -Force | Out-Null
					$updateRequired = $true
				}
				if ((Get-ItemProperty -Path "HKLM:\SOFTWARE\ODBC\ODBC.INI\ODBC Data Sources").$ACSDSN -ne 'ODBC Driver 18 for SQL Server')
				{
					New-ItemProperty -Path "HKLM:\SOFTWARE\ODBC\ODBC.INI\ODBC Data Sources" -Name $ACSDSN -Value "ODBC Driver 18 for SQL Server" -PropertyType STRING -Force | Out-Null
					$updateRequired = $true
				}
				if ($updateRequired)
				{
					Write-ScriptLog -Step 'Modify ACS Registry' -LogString "Adding ODBC Driver $((Get-ItemProperty "$env:WINDIR\system32\msodbcsql18.dll").VersionInfo.ProductVersion) for SQL Server" -ForegroundColor Green
				}
				else
				{
					Write-ScriptLog -Step 'Modify ACS Registry' -LogString "ODBC Driver $((Get-ItemProperty "$env:WINDIR\system32\msodbcsql18.dll").VersionInfo.ProductVersion) for SQL Server is already present" -ForegroundColor Green -Status PASSED
				}
			}
			elseif (Test-Path $env:WINDIR\system32\msodbcsql17.dll)
			{
				#Update the registry
				if (($ACSODBCRegistry).Driver -ne '%WINDIR%\system32\msodbcsql17.dll')
				{
					New-ItemProperty -Path $ACSODBCReg -Name "Driver" -Value "%WINDIR%\system32\msodbcsql17.dll" -PropertyType STRING -Force | Out-Null
					$updateRequired = $true
				}
				if ((Get-ItemProperty -Path "HKLM:\SOFTWARE\ODBC\ODBC.INI\ODBC Data Sources").$ACSDSN -ne 'ODBC Driver 17 for SQL Server')
				{
					New-ItemProperty -Path "HKLM:\SOFTWARE\ODBC\ODBC.INI\ODBC Data Sources" -Name $ACSDSN -Value "ODBC Driver 17 for SQL Server" -PropertyType STRING -Force | Out-Null
					$updateRequired = $true
				}
				if ($updateRequired)
				{
					Write-ScriptLog -Step 'Modify ACS Registry' -LogString "Adding ODBC Driver $((Get-ItemProperty "$env:WINDIR\system32\msodbcsql17.dll").VersionInfo.ProductVersion) for SQL Server" -ForegroundColor Green
				}
				else
				{
					Write-ScriptLog -Step 'Modify ACS Registry' -LogString "ODBC Driver $((Get-ItemProperty "$env:WINDIR\system32\msodbcsql17.dll").VersionInfo.ProductVersion) for SQL Server is already present" -ForegroundColor Green -Status PASSED
				}
			}
			elseif (Test-Path $env:WINDIR\system32\msodbcsql13.dll)
			{
				#Update the registry
				if (($ACSODBCRegistry).Driver -ne '%WINDIR%\system32\msodbcsql13.dll')
				{
					New-ItemProperty -Path $ACSODBCReg -Name "Driver" -Value "%WINDIR%\system32\msodbcsql13.dll" -PropertyType STRING -Force | Out-Null
					$updateRequired = $true
				}
				if ((Get-ItemProperty -Path "HKLM:\SOFTWARE\ODBC\ODBC.INI\ODBC Data Sources").$ACSDSN -ne 'ODBC Driver 13 for SQL Server')
				{
					New-ItemProperty -Path "HKLM:\SOFTWARE\ODBC\ODBC.INI\ODBC Data Sources" -Name $ACSDSN -Value "ODBC Driver 13 for SQL Server" -PropertyType STRING -Force | Out-Null
					$updateRequired = $true
				}
				if ($updateRequired)
				{
					Write-ScriptLog -Step 'Modify ACS Registry' -LogString "Adding ODBC Driver $((Get-ItemProperty "$env:WINDIR\system32\msodbcsql13.dll").VersionInfo.ProductVersion) for SQL Server" -ForegroundColor Green
				}
				else
				{
					Write-ScriptLog -Step 'Modify ACS Registry' -LogString "ODBC Driver $((Get-ItemProperty "$env:WINDIR\system32\msodbcsql13.dll").VersionInfo.ProductVersion) for SQL Server is already present" -ForegroundColor Green -Status PASSED
				}
			}
			elseif (Test-Path $env:WINDIR\system32\msodbcsql11.dll)
			{
				#Update the registry
				if (($ACSODBCRegistry).Driver -ne '%WINDIR%\system32\msodbcsql11.dll')
				{
					New-ItemProperty -Path $ACSODBCReg -Name "Driver" -Value "%WINDIR%\system32\msodbcsql11.dll" -PropertyType STRING -Force | Out-Null
					$updateRequired = $true
				}
				if ((Get-ItemProperty -Path "HKLM:\SOFTWARE\ODBC\ODBC.INI\ODBC Data Sources").$ACSDSN -ne 'ODBC Driver 11 for SQL Server')
				{
					New-ItemProperty -Path "HKLM:\SOFTWARE\ODBC\ODBC.INI\ODBC Data Sources" -Name $ACSDSN -Value "ODBC Driver 11 for SQL Server" -PropertyType STRING -Force | Out-Null
					$updateRequired = $true
				}
				if ($updateRequired)
				{
					Write-ScriptLog -Step 'Modify ACS Registry' -LogString "Adding ODBC Driver $((Get-ItemProperty "$env:WINDIR\system32\msodbcsql11.dll").VersionInfo.ProductVersion) for SQL Server" -ForegroundColor Green
				}
				else
				{
					Write-ScriptLog -Step 'Modify ACS Registry' -LogString "ODBC Driver $((Get-ItemProperty "$env:WINDIR\system32\msodbcsql11.dll").VersionInfo.ProductVersion) for SQL Server is already present" -ForegroundColor Green -Status PASSED
				}
			}
			else
			{
				Write-ScriptLog -Step 'Modify ACS Registry' -Status Error -LogString "Unable to locate any supported ODBC Driver" -ForegroundColor Red
				$failed = $true
			}
		}
	}
	#endregion
	IF ($Error)
	{
		Write-ScriptLog -Step 'Modify ACS Registry' -Status Error -LogString "Something went wrong attempting to write to the registry. Review the error and try again. Error is ($Error)." -ForegroundColor Red
		$failed = $true
	}
	Script-Failed -Step 'Modify ACS Registry' -failed $failed
	
	if (-not $SkipSQLSoftwarePrerequisites)
	{
		$prereqs = ' prerequisites,'
	}
	else
	{
		$prereqs = ''
	}
	
	if (-not $SkipSQLSoftwarePrerequisites -or -not $SkipModifyRegistry)
	{
		$DoWeReboot = ' We must REBOOT the server before this will take effect.'
	}
	else
	{
		$DoWeReboot = ''
	}
	function Start-EndOfScript
	{
		Write-ScriptLog -Step 'Wrapping Up' -LogString "Script completed on $env:COMPUTERNAME" -ForegroundColor Green
		break
	}
	if (-not $AssumeYes)
	{
		if (-not $SkipSQLSoftwarePrerequisites -or -not $SkipModifyRegistry)
		{
			Write-ScriptLog -Step 'Wrapping Up' -LogString "Completed TLS 1.2$prereqs configuration, and registry modification.$DoWeReboot" -ForegroundColor Yellow
			do
			{
				$Answer = Read-Host "$(Get-CurrentDate)Reboot this server now? (Y/N)"
				Write-ScriptLog -LogString "Reboot this server now? (Y/N): $Answer" -NoOutput
			}
			until ($Answer -match "^Y|^N")
		}
		else
		{
			Start-EndOfScript
		}
		
	}
	else
	{
		$Answer = 'Y'
	}
	IF ($Answer -match "^Y")
	{
		Write-ScriptLog -Step 'Wrapping Up' -LogString "Reboot was selected. Rebooting server NOW."
		Restart-Computer -Force
	}
	ELSE
	{
		Write-ScriptLog -Step 'Wrapping Up' -LogString "You chose not to reboot. We must REBOOT the server before TLS 1.2 enforcement changes will take effect." -ForegroundColor Yellow
	}
	Start-EndOfScript
	#End of Script
}
if ($AssumeYes -or $SkipDotNetCheck -or $SkipModifyRegistry -or $SkipRoleCheck -or $SkipSQLQueries -or $SkipSQLSoftwarePrerequisites -or $SkipVersionCheck -or $SkipDownloadPrerequisites -or $DirectoryForPrerequisites -or $ForceDownloadPrerequisites)
{
	Start-SCOMTLSEnforcement -AssumeYes:$AssumeYes -ForceDownloadPrerequisites:$ForceDownloadPrerequisites -SkipDotNetCheck:$SkipDotNetCheck -SkipModifyRegistry:$SkipModifyRegistry -SkipRoleCheck:$SkipRoleCheck -SkipSQLQueries:$SkipSQLQueries -SkipSQLSoftwarePrerequisites:$SkipSQLSoftwarePrerequisites -SkipVersionCheck:$SkipVersionCheck -SkipDownloadPrerequisites:$SkipDownloadPrerequisites -DirectoryForPrerequisites $DirectoryForPrerequisites
}
else
{
	# Modify the line below to change what happens when you run from PowerShell ISE.
	Start-SCOMTLSEnforcement
}
<#
    Copyright (c) Microsoft Corporation. MIT License
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#>
