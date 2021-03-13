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

Clear-Host
Write-Host `n"Starting SCOM TLS 1.2 Configuration." -ForegroundColor Yellow
Start-Sleep -s 1
Write-Host `n"PowerShell Unrestricted Execution Policy access is required to run this script." -ForegroundColor Yellow
Start-Sleep -s 1
Write-Host `n"If applicable, please use the (Set-ExecutionPolicy Unrestricted) command to allow the script to run." -ForegroundColor Yellow
Start-Sleep -s 1
Write-Host `n"Logging will be written to C:\Windows\Temp" -ForegroundColor Yellow
Start-Sleep -s 1

Write-Host `n"Creating log file...." -ForegroundColor Magenta
Start-Sleep -s 2
$Error.Clear()
[string]$LogPath = "C:\Windows\Temp"
[string]$LogName = "SCOM_TLS_Config.log"
[string]$LogFile = $LogPath + "\" + $LogName
IF (!(Test-Path $LogPath))
{
  Write-Host `n"ERROR: Cannot access logging directory ($LogPath).  Terminating.`n" -ForegroundColor Red
  PAUSE
  EXIT
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
  LogWrite "Error ocurred.  Error is: ($Error)" 
}


###################################################
# Find out if SCOM of any kind is installed Section

Write-Host `n"Checking to see if SCOM is installed and gather the SCOM Role...." -ForegroundColor Magenta
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
      Write-Host `n"SCOM Roles:  Gateway Role was detected." -ForegroundColor Green
      LogWrite "SCOM Roles:  Gateway Role was detected."
      Start-Sleep -s 1
    }
    ELSE
    {
      $ManagementServer = $true
      Write-Host `n"SCOM Roles:  Management Server Role was detected." -ForegroundColor Green
      LogWrite "SCOM Roles:  Management Server Role was detected."
      Start-Sleep -s 1
    }
  }
  ELSE
  {
    Write-Host `n"SCOM Roles:  No Management Server nor Gateway roles detected." -ForegroundColor Green
    LogWrite "SCOM Roles:  No Management Server nor Gateway roles detected."
    Start-Sleep -s 1
  }
  #Find out if this is a SCOM Web Console Server
  $SCOMInstallPath = (Get-ItemProperty $SCOMRegPath).InstallDirectory
  $WebConsolePath = $SCOMInstallPath -replace "\\Server\\","\WebConsole\"
  [string]$WebConsoleMVPath = $WebConsolePath + "MonitoringView"
  $WebConsoleServer = Test-Path $WebConsoleMVPath
  IF ($WebConsoleServer)
  {
    Write-Host `n"SCOM Roles:  Web Console Role was detected." -ForegroundColor Green
    LogWrite "SCOM Roles:  Web Console Role was detected."
    Start-Sleep -s 1
  }
  ELSE
  {
    Write-Host `n"SCOM Roles:  No Web Console Role was detected." -ForegroundColor Green
    LogWrite "SCOM Roles: No Web Console Role was detected."
    Start-Sleep -s 1
  }

  #Find out of this is a Management Server and has ACS Colector installed

  IF ($ManagementServer)
  {
    $ACSReg = "HKLM:\SYSTEM\CurrentControlSet\Services\AdtServer"
    IF (Test-Path $ACSReg)
    {
      #This is an ACS Collector server
      Write-Host `n"SCOM Roles:  ACS Collector Role was detected." -ForegroundColor Green
      LogWrite "SCOM Roles:  ACS Collector Role was detected."
      $ACS = $true
      Start-Sleep -s 1
    }
    ELSE
    {
      #This is NOT an ACS Collector server
      Write-Host `n"SCOM Roles:  No ACS Collector Role was detected." -ForegroundColor Green
      LogWrite "SCOM Roles:  No ACS Collector Role was detected."
      Start-Sleep -s 1  
    }
  }
}


###################################################
# Ensure SCOM 1801, 1807, 2019, SCOM 2016 UR4 (or later) or SCOM 2012 UR14 (or later) is installed

IF ($ManagementServer -or $WebConsoleServer -or $Gateway)
{
  Start-Sleep -s 1
  Write-Host `n"Checking to ensure the your version of SCOM supports TLS 1.2 enforcement (2012R2 UR14, 2016 UR4, or later)...." -ForegroundColor Magenta
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
      Write-Host `n"PASSED:  Gateway Server role version 1801/1807/2019 or later detected which supports TLS 1.2" -ForegroundColor Green
      LogWrite "PASSED:  Gateway Server role 1801/1807/2019 or later detected which supports TLS 1.2"
      Start-Sleep -s 1      
    }
    ELSEIF ($MajorSCOMGWVersion -eq "8.0")
    {
      # This is a SCOM 2016 Gateway
      [int]$URVersion = $GWURFileVersionSplit[2]
      IF ($URVersion -ge 10977)
      {
        #This is UR4 or later
        Write-Host `n"PASSED:  UR4 or later detected on this SCOM 2016 Gateway" -ForegroundColor Green
        LogWrite "PASSED:  UR4 or later detected on this SCOM 2016 Gateway"
        Start-Sleep -s 1
      }
      ELSE
      {
        Write-Host `n"FAILED:  UR4 was not found on this SCOM 2016 Gateway.  Please ensure UR4 is applied before continuing." -ForegroundColor Red
        Write-Host "Version found for Healthservice.dll ($GWURFileVersion)" -ForegroundColor Red
        LogWrite "FAILED:  UR4 was not found on this SCOM 2016 Gateway.  Please ensure UR4 is applied before continuing."
        LogWrite "Version found for Healthservice.dll ($GWURFileVersion)"
        PAUSE
        EXIT
      }
    }
    ELSEIF ($MajorSCOMGWVersion -eq "7.1")
    {
      # This is a SCOM 2012R2 Gateway
      [int]$URVersion = $GWURFileVersionSplit[2]
      IF ($URVersion -ge 10305)
      {
        #This is UR4 or later
        Write-Host `n"PASSED:  UR14 or later detected on this SCOM 2012 R2 Gateway" -ForegroundColor Green
        LogWrite "PASSED:  UR14 or later detected on this SCOM 2012 R2 Gateway"
        Start-Sleep -s 1
      }
      ELSE
      {
        Write-Host `n"FAILED:  UR14 was not found on this Gateway.  Please ensure UR14 is applied before continuing." -ForegroundColor Red
        Write-Host "Version found for Healthservice.dll ($GWURFileVersion)" -ForegroundColor Red
        LogWrite "FAILED:  UR14 was not found on this Gateway.  Please ensure UR14 is applied before continuing."
        LogWrite "Version found for Healthservice.dll ($GWURFileVersion)"
        PAUSE
        EXIT
      }
    }
    ELSE
    {
      Write-Host `n"FAILED:  A SCOM Gateway Server Role was detected however it is not a known version supported by this script" -ForegroundColor Red
      Write-Host "  Version found for Healthservice.dll ($GWURFileVersion)" -ForegroundColor Red
      LogWrite "FAILED:  A SCOM Gateway Server Role was detected however it is not a known version."
      LogWrite "  Version found for Healthservice.dll ($GWURFileVersion)"
      PAUSE
      EXIT
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
      Write-Host `n"PASSED:  Management Server role version 1801/1807/2019 or later detected which supports TLS 1.2" -ForegroundColor Green
      LogWrite "PASSED:  Management Server role 1801/1807/2019 or later detected which supports TLS 1.2"
      Start-Sleep -s 1
    }
    ELSEIF ($MajorSCOMVersion -eq "7.2")
    {
      # This is a SCOM 2016 ManagementServer
      [int]$URVersion = $ServerURFileVersionSplit[2]
      IF ($URVersion -ge 11938)
      {
        #This is UR4 or later
        Write-Host `n"PASSED:  Management Server role version 2016 UR4 or later detected which supports TLS 1.2" -ForegroundColor Green
        LogWrite "PASSED:  Management Server role version 2016 UR4 or later detected which supports TLS 1.2"
        Start-Sleep -s 1
      }
      ELSE
      {
        Write-Host `n"FAILED:  UR4 or later was not found on this SCOM 2016 ManagementServer.  Please ensure UR4 or later is applied before continuing." -ForegroundColor Red
        Write-Host "Version found for Microsoft.EnterpriseManagement.RuntimeService.dll ($ServerURFileVersion)" -ForegroundColor Red
        LogWrite "FAILED:  UR4 or later was not found on this SCOM 2016 ManagementServer.  Please ensure UR4 or later is applied before continuing."
        LogWrite "Version found for Microsoft.EnterpriseManagement.RuntimeService.dll ($ServerURFileVersion)"
        PAUSE
        EXIT
      }
    }
    ELSEIF ($MajorSCOMVersion -eq "7.1")
    {
      # This is a SCOM 2012R2 ManagementServer
      [int]$URVersion = $ServerURFileVersionSplit[3]
      IF ($URVersion -ge 1387)
      {
        #This is UR14 or later
        Write-Host `n"PASSED:  Management Server role version 2012R2 UR14 or later detected which supports TLS 1.2" -ForegroundColor Green
        LogWrite "PASSED:  Management Server role version 2012R2 UR14 or later detected which supports TLS 1.2"
        Start-Sleep -s 1
      }
      ELSE
      {
        Write-Host `n"FAILED:  UR14 or later was not found on this SCOM 2012R2 ManagementServer.  Please ensure UR14 or later is applied before continuing." -ForegroundColor Red
        Write-Host "Version found for Microsoft.EnterpriseManagement.RuntimeService.dll ($ServerURFileVersion)" -ForegroundColor Red
        LogWrite "FAILED:  UR14 or later was not found on this SCOM 2012R2 ManagementServer.  Please ensure UR14 or later is applied before continuing."
        LogWrite "Version found for Microsoft.EnterpriseManagement.RuntimeService.dll ($ServerURFileVersion)"
        PAUSE
        EXIT
      }
    }
    ELSE
    {
      Write-Host `n"FAILED:  A SCOM Management Server Role was detected however it is not a known version supported by this script" -ForegroundColor Red
      Write-Host "Version found for Microsoft.EnterpriseManagement.RuntimeService.dll ($ServerURFileVersion)" -ForegroundColor Red
      LogWrite "FAILED:  A SCOM Management Server Role was detected however it is not a known version."
      LogWrite "Version found for Microsoft.EnterpriseManagement.RuntimeService.dll ($ServerURFileVersion)"
      PAUSE
      EXIT
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
      Write-Host `n"PASSED:  Web Console Server role version 1801/1807/2019 or later detected which supports TLS 1.2" -ForegroundColor Green
      LogWrite "PASSED:  Web Console Server role 1801/1807/2019 or later detected which supports TLS 1.2"
      Start-Sleep -s 1
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
        Write-Host `n"PASSED:  Web Console Server role version 2016 UR4 or later detected which supports TLS 1.2" -ForegroundColor Green
        LogWrite "PASSED:  Web Console Server role version 2016 UR4 or later detected which supports TLS 1.2"
        Start-Sleep -s 1
      }
      ELSE
      {
        Write-Host `n"FAILED:  UR4 was not found on this SCOM 2016 WebConsole.  Please ensure UR4 is applied before continuing." -ForegroundColor Red
        Write-Host "Version found for Microsoft.EnterpriseManagement.Management.DataProviders.dll ($WebConsole2016URFileVersion)" -ForegroundColor Red
        LogWrite "FAILED:  UR4 was not found on this SCOM 2016 WebConsole.  Please ensure UR4 is applied before continuing."
        LogWrite "Version found for Microsoft.EnterpriseManagement.Management.DataProviders.dll ($WebConsole2016URFileVersion)"
        PAUSE
        EXIT
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
        Write-Host `n"PASSED:  Web Console Server role version 2012R2 UR14 or later detected which supports TLS 1.2" -ForegroundColor Green
        LogWrite "PASSED:  Web Console Server role version 2012R2 UR14 or later detected which supports TLS 1.2"
        Start-Sleep -s 1
      }
      ELSE
      {
        Write-Host `n"FAILED:  UR14 was not found on this SCOM 2012R2 WebConsole.  Please ensure UR14 is applied before continuing." -ForegroundColor Red
        Write-Host "Version found for Microsoft.EnterpriseManagement.Management.DataProviders.dll ($WebConsole2012URFileVersion)" -ForegroundColor Red
        LogWrite "FAILED:  UR14 was not found on this SCOM 2012R2 WebConsole.  Please ensure UR14 is applied before continuing."
        LogWrite "Version found for Microsoft.EnterpriseManagement.Management.DataProviders.dll ($WebConsole2012URFileVersion)"
        PAUSE
        EXIT
      }
    }
    ELSE
    {
      Write-Host `n"FAILED:  A SCOM Web Console Server Role was detected however it is not a known version supported by this script" -ForegroundColor Red
      Write-Host "Version found for ($WebConsoleFilePath) is ($WebConsoleFileVersion)" -ForegroundColor Red
      LogWrite "FAILED:  A SCOM Management Server Role was detected however it is not a known version."
      LogWrite "Version found for ($WebConsoleFilePath) is ($WebConsoleFileVersion)"
      PAUSE
      EXIT    
    }
  }
}



###################################################
# Test .NET Framework version on ALL servers
Start-Sleep -s 1
Write-Host `n"Checking .NET Framework Version is 4.6 or later...." -ForegroundColor Magenta
LogWrite "Checking .NET Framework Version is 4.6 or later"
Start-Sleep -s 2
$Error.Clear()

# Get version from registry
$RegPath = "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\"
[int]$ReleaseRegValue = (Get-ItemProperty $RegPath).Release
# Interpret .NET version
[string]$VersionString = switch($ReleaseRegValue)
{
    "378389" {".NET Framework 4.5"}
    "378675" {".NET Framework 4.5.1"}
    "378758" {".NET Framework 4.5.1"}
    "379893" {".NET Framework 4.5.2"}
    "393295" {".NET Framework 4.6"}
    "393297" {".NET Framework 4.6"}
    "394254" {".NET Framework 4.6.1"}
    "394271" {".NET Framework 4.6.1"}
    "394802" {".NET Framework 4.6.2"}
    "394806" {".NET Framework 4.6.2"}
    "460798" {".NET Framework 4.7"}
    "460805" {".NET Framework 4.7"}
    "461308" {".NET Framework 4.7.1"}
    "461310" {".NET Framework 4.7.1"}
    "461808" {".NET Framework 4.7.2"}
    "461814" {".NET Framework 4.7.2"}
    "528040" {".NET Framework 4.8"}
    "528049" {".NET Framework 4.8"}
    default {"Unknown version of .NET version: $ReleaseRegValue"}
}
# Check if version is 4.6 or higher
IF ($ReleaseRegValue -ge 393295)
{
    Write-Host `n"PASSED:  .NET version is 4.6 or later" -ForegroundColor Green
    Write-Host "  Detected version is: ($VersionString)" -ForegroundColor Green
    LogWrite "PASSED:  .NET version is 4.6 or later"
    LogWrite "  Detected version is: ($VersionString)"
    Start-Sleep -s 1
}
ELSE
{
    Write-Host `n"FAILED:  .NET Version is NOT 4.6 or later" -ForegroundColor Red
    Write-Host "  Detected version is: ($VersionString)" -ForegroundColor Red
    LogWrite "FAILED:  .NET Version is NOT 4.6 or later"
    LogWrite "  Detected version is: ($VersionString)"
    PAUSE
    EXIT
}


###################################################
# Get SQL Server Version to check for TLS Support

IF ($ManagementServer)
{
  Start-Sleep -s 1
  Write-Host `n"Checking SQL Server Versions to ensure they support TLS 1.2 ...." -ForegroundColor Magenta
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
    Write-Host `n"PASSED:  Operations DB Server: This is SQL 2016 or later.  All versions of SQL 2016 and later support TLS 1.2 so no update is required on server ($OpsSQLServer)" -ForegroundColor Green
    LogWrite "PASSED:  Operations DB Server: This is SQL 2016 or later.  All versions of SQL 2016 and later support TLS 1.2 so no update is required on server ($OpsSQLServer)"
    Start-Sleep -s 1
  }
  ELSEIF ($SQLMajorVersion -eq 12)
  {
    [int]$SQLMinorVersion = $SQLVersionSplit[2]  
    IF ($SQLMinorVersion -ge 4439)
    {
        Write-Host `n"PASSED:  Operations DB Server: This is SQL 2014.  We detected a version that is greater than SQL 2014 SP1 CU5, so no update is required on server ($OpsSQLServer)." -ForegroundColor Green
        Write-Host "  Minimum version: (12.0.4439.1)" -ForegroundColor Green
        Write-Host "  Detected version: ($SQLVersion)" -ForegroundColor Green
        LogWrite "PASSED:  Operations DB Server: This is SQL 2014.  We detected a version that is greater than SQL 2014 SP1 CU5, so no update is required on server ($OpsSQLServer)."
        LogWrite "  Minimum version: (12.0.4439.1)"
        LogWrite "  Detected version: ($SQLVersion)"
        Start-Sleep -s 1
    }
    ELSE
    {
        Write-Host `n"FAILED.  Operations DB Server: This is SQL 2014, and we detected a version that does not support TLS 1.2 on server ($OpsSQLServer)" -ForegroundColor Red
        Write-Host "  Minimum version: (12.0.4439.1)" -ForegroundColor Red
        Write-Host "  Detected version: ($SQLVersion)" -ForegroundColor Red
        LogWrite "FAILED.  Operations DB Server: This is SQL 2014, and we detected a version that does not support TLS 1.2 on server ($OpsSQLServer)"
        LogWrite "  Minimum version: (12.0.4439.1)"
        LogWrite "  Detected version: ($SQLVersion)"
        PAUSE
        EXIT
    }
  }
  ELSEIF ($SQLMajorVersion -eq 11)
  {
    [int]$SQLMinorVersion = $SQLVersionSplit[2]  
    IF ($SQLMinorVersion -ge 6216)
    {
        Write-Host `n"PASSED:  Operations DB Server: This is SQL 2012.  We detected a version that is greater than SQL 2012 SP3 with TLS Update, so no update is required on server ($OpsSQLServer)." -ForegroundColor Green
        Write-Host "  Minimum version: (11.0.6216.0)" -ForegroundColor Green
        Write-Host "  Detected version: ($SQLVersion)" -ForegroundColor Green
        LogWrite "PASSED:  Operations DB Server: This is SQL 2012.  We detected a version that is greater than SQL 2012 SP3 with TLS Update, so no update is required on server ($OpsSQLServer)."
        LogWrite "  Minimum version: (11.0.6216.0)"
        LogWrite "  Detected version: ($SQLVersion)"
        Start-Sleep -s 1
    }
    ELSE
    {
        Write-Host `n"FAILED.  Operations DB Server: This is SQL 2012, and we detected a version that does not support TLS 1.2 on server ($OpsSQLServer)" -ForegroundColor Red
        Write-Host "  Minimum version: (11.0.6216.0)" -ForegroundColor Red
        Write-Host "  Detected version: ($SQLVersion)" -ForegroundColor Red
        LogWrite "FAILED.  Operations DB Server: This is SQL 2012, and we detected a version that does not support TLS 1.2 on server ($OpsSQLServer)"
        LogWrite "  Minimum version: (11.0.6216.0)"
        LogWrite "  Detected version: ($SQLVersion)"
        PAUSE
        EXIT
    }
  }
  ELSEIF ($SQLMajorVersion -eq 10 -and $SQLVersionSplit[1] -eq 50)
  {
    [int]$SQLMinorVersion = $SQLVersionSplit[2]  
    IF ($SQLMinorVersion -ge 6542)
    {
        Write-Host `n"PASSED:  Operations DB Server: This is SQL 2008R2.  We detected a version that is greater than SQL 2008R2 SP3 with TLS update, so no update is required on server ($OpsSQLServer)." -ForegroundColor Green
        Write-Host "  Minimum version: (10.50.6542.0)" -ForegroundColor Green
        Write-Host "  Detected version: ($SQLVersion)" -ForegroundColor Green
        LogWrite "PASSED:  Operations DB Server: This is SQL 2008R2.  We detected a version that is greater than SQL 2008R2 SP3 with TLS update, so no update is required on server ($OpsSQLServer)."
        LogWrite "  Minimum version: (10.50.6542.0)"
        LogWrite "  Detected version: ($SQLVersion)"
        Start-Sleep -s 1
    }
    ELSE
    {
        Write-Host `n"FAILED.  Operations DB Server: This is SQL 2008R2, and we detected a version that does not support TLS 1.2 on server ($OpsSQLServer)" -ForegroundColor Red
        Write-Host "  Minimum version: (10.50.6542.0)" -ForegroundColor Red
        Write-Host "  Detected version: ($SQLVersion)" -ForegroundColor Red
        LogWrite "FAILED.  Operations DB Server: This is SQL 2008R2, and we detected a version that does not support TLS 1.2 on server ($OpsSQLServer)"
        LogWrite "  Minimum version: (10.50.6542.0)"
        LogWrite "  Detected version: ($SQLVersion)"
        PAUSE
        EXIT
    }
  }
  ELSE
  {
    Write-Host `n"FAILED.  Operations DB Server: We did not detect a supported version of SQL for SCOM and TLS 1.2 on server ($OpsSQLServer)" -ForegroundColor Red
    LogWrite "FAILED.  Operations DB Server: We did not detect a supported version of SQL for SCOM and TLS 1.2 on server ($OpsSQLServer)"
    PAUSE
    EXIT
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
    Write-Host `n"PASSED:  DataWarehouse Server: This is SQL 2016 or later.  All versions of SQL 2016 or later support TLS 1.2 so no update is required on server ($DWSQLServer)" -ForegroundColor Green
    LogWrite "PASSED:  DataWarehouse Server: This is SQL 2016 or later.  All versions of SQL 2016 or later support TLS 1.2 so no update is required on server ($DWSQLServer)"
    Start-Sleep -s 1
  }
  ELSEIF ($SQLMajorVersion -eq 12)
  {
    [int]$SQLMinorVersion = $SQLVersionSplit[2]  
    IF ($SQLMinorVersion -ge 4439)
    {
        Write-Host `n"PASSED:  DataWarehouse Server: This is SQL 2014.  We detected a version that is greater than SQL 2014 SP1 CU5, so no update is required on server ($DWSQLServer)." -ForegroundColor Green
        Write-Host "  Minimum version: (12.0.4439.1)" -ForegroundColor Green
        Write-Host "  Detected version: ($SQLVersion)" -ForegroundColor Green
        LogWrite "PASSED:  DataWarehouse Server: This is SQL 2014.  We detected a version that is greater than SQL 2014 SP1 CU5, so no update is required on server ($DWSQLServer)."
        LogWrite "  Minimum version: (12.0.4439.1)"
        LogWrite "  Detected version: ($SQLVersion)"
        Start-Sleep -s 1
    }
    ELSE
    {
        Write-Host `n"FAILED.  DataWarehouse Server: This is SQL 2014, and we detected a version that does not support TLS 1.2 on server ($DWSQLServer)" -ForegroundColor Red
        Write-Host "  Minimum version: (12.0.4439.1)" -ForegroundColor Red
        Write-Host "  Detected version: ($SQLVersion)" -ForegroundColor Red
        LogWrite "FAILED.  DataWarehouse Server: This is SQL 2014, and we detected a version that does not support TLS 1.2 on server ($DWSQLServer)"
        LogWrite "  Minimum version: (12.0.4439.1)"
        LogWrite "  Detected version: ($SQLVersion)"
        PAUSE
        EXIT
    }
  }
  ELSEIF ($SQLMajorVersion -eq 11)
  {
    [int]$SQLMinorVersion = $SQLVersionSplit[2]  
    IF ($SQLMinorVersion -ge 6216)
    {
        Write-Host `n"PASSED:  DataWarehouse Server: This is SQL 2012.  We detected a version that is greater than SQL 2012 SP3 with TLS update, so no update is required on server ($DWSQLServer)." -ForegroundColor Green
        Write-Host "  Minimum version: (11.0.6216.0)" -ForegroundColor Green
        Write-Host "  Detected version: ($SQLVersion)" -ForegroundColor Green
        LogWrite "PASSED:  DataWarehouse Server: This is SQL 2012.  We detected a version that is greater than SQL 2012 SP3 with TLS update, so no update is required on server ($DWSQLServer)."
        LogWrite "  Minimum version: (11.0.6216.0)"
        LogWrite "  Detected version: ($SQLVersion)"
        Start-Sleep -s 1
    }
    ELSE
    {
        Write-Host `n"FAILED.  DataWarehouse Server: This is SQL 2012, and we detected a version that does not support TLS 1.2 on server ($DWSQLServer)" -ForegroundColor Red
        Write-Host "  Minimum version: (11.0.6216.0)" -ForegroundColor Red
        Write-Host "  Detected version: ($SQLVersion)" -ForegroundColor Red
        LogWrite "FAILED.  DataWarehouse Server: This is SQL 2012, and we detected a version that does not support TLS 1.2 on server ($DWSQLServer)"
        LogWrite "  Minimum version: (11.0.6216.0)"
        LogWrite "  Detected version: ($SQLVersion)"
        PAUSE
        EXIT
    }
  }
  ELSEIF ($SQLMajorVersion -eq 10 -and $SQLVersionSplit[1] -eq 50)
  {
    [int]$SQLMinorVersion = $SQLVersionSplit[2]  
    IF ($SQLMinorVersion -ge 6542)
    {
        Write-Host `n"PASSED:  This is SQL 2008R2.  DataWarehouse Server: We detected a version that is greater than SQL 2008R2 SP3 with TLS update, so no update is required on server ($DWSQLServer)." -ForegroundColor Green
        Write-Host "  Minimum version: (10.50.6542.0)" -ForegroundColor Green
        Write-Host "  Detected version: ($SQLVersion)" -ForegroundColor Green
        LogWrite "PASSED:  This is SQL 2008R2.  DataWarehouse Server: We detected a version that is greater than SQL 2008R2 SP3 with TLS update, so no update is required on server ($DWSQLServer)."
        LogWrite "  Minimum version: (10.50.6542.0)"
        LogWrite "  Detected version: ($SQLVersion)"
        Start-Sleep -s 1
    }
    ELSE
    {
        Write-Host `n"FAILED.  DataWarehouse Server: This is SQL 2008R2, and we detected a version that does not support TLS 1.2 on server ($DWSQLServer)" -ForegroundColor Red
        Write-Host "  Minimum version: (10.50.6542.0)" -ForegroundColor Red
        Write-Host "  Detected version: ($SQLVersion)" -ForegroundColor Red
        LogWrite "FAILED.  DataWarehouse Server: This is SQL 2008R2, and we detected a version that does not support TLS 1.2 on server ($DWSQLServer)"
        LogWrite "  Minimum version: (10.50.6542.0)"
        LogWrite "  Detected version: ($SQLVersion)"
        PAUSE
        EXIT
    }
  }
  ELSE
  {
    Write-Host `n"FAILED.  DataWarehouse Server: We did not detect a supported version of SQL for SCOM and TLS 1.2 on server ($DWSQLServer)" -ForegroundColor Red
    LogWrite "FAILED.  DataWarehouse Server: We did not detect a supported version of SQL for SCOM and TLS 1.2 on server ($DWSQLServer)"
    PAUSE
    EXIT
  }
}



###################################################
# Software Prerequisites for Management Servers and Web Console servers
IF ($ManagementServer -or $WebConsoleServer)
{
    Start-Sleep -s 1
    Write-Host `n"Checking SQL Client version and ODBC Driver version for TLS 1.2 support...." -ForegroundColor Magenta
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
      Write-Host `n"PASSED:  SQL Client - is installed and version: ($SQLClient11VersionString) and greater or equal to the minimum version required: (11.4.7001.0)" -ForegroundColor Green
      LogWrite "PASSED:  SQL Client - is installed and version: ($SQLClient11VersionString) and greater or equal to the minimum version required: (11.4.7001.0)"
    }
    ELSEIF ($SQLClient11VersionString)
    {
      Write-Host `n"SQL Client - is installed and version: ($SQLClient11VersionString) but below the minimum version of (11.4.7001.0).  We will attempt upgrade now." -ForegroundColor Yellow
      LogWrite "SQL Client - is installed and version: ($SQLClient11VersionString) but below the minimum version of (11.4.7001.0).  We will attempt upgrade now."
      $SQLClientInstallFlag = $true
      Start-Sleep -s 1
    }
    ELSE
    {
      Write-Host `n"SQL Client - is NOT installed.  Installing now..." -ForegroundColor Yellow
      LogWrite "SQL Client - is NOT installed.  Installing now..."
      $SQLClientInstallFlag = $true
    }

    IF ($SQLClientInstallFlag)
    {
      Start-Sleep -s 1
      $SQLClientFileExists = Test-Path ".\sqlncli.msi"
      IF (!($SQLClientFileExists))
      {
        Write-Host `n"FAILED.  Path to SQL Native Client 11.4.7001.0 install file not found.  Ensure that sqlncli.msi is in the same directory as this script.  Terminating...." -ForegroundColor Red
        LogWrite "FAILED.  Path to SQL Native Client 11.4.7001.0 install file not found.  Ensure that sqlncli.msi is in the same directory as this script.  Terminating...."
        EXIT
      }    
      $Error.Clear()
      $SQLClient = Get-Item ".\sqlncli.msi"
      msiexec /qb /i "$SQLClient" IACCEPTSQLNCLILICENSETERMS=YES | Out-Null
      IF ($Error) 
      {
        Write-Host `n"Error ocurred.  Error is: ($Error)"
        LogWrite "Error ocurred.  Error is: ($Error)"
      }  
    }

    ### Recheck if SQL Client is installed after an install attempt
    IF ($SQLClientInstallFlag)
    {
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
        Write-Host `n"PASSED:  SQL Client - is installed and version: ($SQLClient11VersionString) and greater or equal to the minimum version required: (11.4.7001.0)" -ForegroundColor Green
        LogWrite "PASSED:  SQL Client - is installed and version: ($SQLClient11VersionString) and greater or equal to the minimum version required: (11.4.7001.0)"
      }
      ELSE
      {
        Write-Host `n"FAILED.  We could not verify that SQL Client 11 is installed and is a version that supports TLS.  Version Expected: (11.4.7001.0)  Version detected ($SQLClient11VersionString).  Terminating...." -ForegroundColor Red
        LogWrite "FAILED.  We could not verify that SQL Client 11 is installed and is a version that supports TLS.  Version Expected: (11.4.7001.0)  Version detected ($SQLClient11VersionString).  Terminating...."
        EXIT
      }
    }

    
    ### Check if ODBC 13 driver is installed
    $RegPath = "HKLM:SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers"
    [string]$ODBCDriver13 = (Get-ItemProperty $RegPath)."ODBC Driver 13 for SQL Server"
    Start-Sleep -s 1

    IF ($ODBCDriver13 -eq "Installed")
    {
      Write-Host `n"PASSED:  ODBC Driver - Version 13 is already installed" -ForegroundColor Green
      LogWrite "PASSED:  ODBC Driver - Version 13 is already installed"
    }
    ELSE
    {
      Write-Host `n"ODBC Driver - Version 13 is not installed.  Installing now..." -ForegroundColor Yellow
      LogWrite "ODBC Driver - Version 13 is not installed.  Installing now..."
      Start-Sleep -s 2
      $ODBC13FileExists = Test-Path ".\msodbcsql.msi"
      IF (!($ODBC13FileExists))
      {
        Write-Host `n"FAILED.  Path to ODBC Drivers version 13 install file not found.  Ensure that msodbcsql.msi is in the same directory as this script.  Terminating...." -ForegroundColor Red
        LogWrite "FAILED.  Path to ODBC Drivers version 13 install file not found.  Ensure that msodbcsql.msi is in the same directory as this script.  Terminating...."
        EXIT
      }
      $Error.Clear()
      $ODBCInstallFlag = $true
      $ODBC13 = Get-Item ".\msodbcsql.msi"
      msiexec /qb /i "$ODBC13" IACCEPTMSODBCSQLLICENSETERMS=YES | Out-Null
      IF ($Error) 
      { 
        Write-Host `n"Error ocurred.  Error is: ($Error)"
        LogWrite "Error ocurred.  Error is: ($Error)" 
      }
    }

    ### Recheck if ODBC 13 driver is installed after an install attempt
    IF ($ODBCInstallFlag)
    {
      ### Check if ODBC 13 driver is installed
      $RegPath = "HKLM:SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers"
      [string]$ODBCDriver13 = (Get-ItemProperty $RegPath)."ODBC Driver 13 for SQL Server"

      IF ($ODBCDriver13 -eq "Installed")
      {
        Write-Host `n"PASSED:  ODBC Driver - Version 13 is installed" -ForegroundColor Green
        LogWrite "PASSED:  ODBC Driver - Version 13 is installed"
      }
      ELSE
      {
        Write-Host `n"FAILED.  We could not verify that ODBC Driver Version 13 is installed.  Terminating...." -ForegroundColor Red
        LogWrite "FAILED.  We could not verify that ODBC Driver Version 13 is installed.  Terminating...."
        EXIT
      }
    }
}


###################################################
# Write the registry entries to enforce TLS 1.2
Start-Sleep -s 1
Write-Host `n"Modify Registry to enforce TLS 1.2 ...." -ForegroundColor Magenta
LogWrite "Modify Registry to enforce TLS 1.2"
Start-Sleep -s 2

$a = new-object -comobject wscript.shell 
$ConsoleAnswer = $a.popup("Do you want to modify the registry and enforce TLS 1.2 ONLY?",0,"Modify Registry Now?",4)
IF($ConsoleAnswer -eq 6)
{
    $Error.Clear()
    Write-Host `n"Modifying Registry Now ...." -ForegroundColor Magenta
    LogWrite "Modifying Registry Now ...."
    # Disable everything except TLS 1.2
    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client"
    IF (!(Test-Path $RegPath))
    {
      New-Item -Path $RegPath -Force | Out-Null
    }
    New-ItemProperty -Path $RegPath -Name "Enabled" -Value "0" -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name "DisabledByDefault" -Value "1" -PropertyType DWORD -Force | Out-Null
    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server"
    IF (!(Test-Path $RegPath))
    {
      New-Item -Path $RegPath -Force | Out-Null
    }
    New-ItemProperty -Path $RegPath -Name "Enabled" -Value "0" -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name "DisabledByDefault" -Value "1" -PropertyType DWORD -Force | Out-Null
    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client"
    IF (!(Test-Path $RegPath))
    {
      New-Item -Path $RegPath -Force | Out-Null
    }
    New-ItemProperty -Path $RegPath -Name "Enabled" -Value "0" -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name "DisabledByDefault" -Value "1" -PropertyType DWORD -Force | Out-Null
    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server"
    IF (!(Test-Path $RegPath))
    {
      New-Item -Path $RegPath -Force | Out-Null
    }
    New-ItemProperty -Path $RegPath -Name "Enabled" -Value "0" -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name "DisabledByDefault" -Value "1" -PropertyType DWORD -Force | Out-Null
    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client"
    IF (!(Test-Path $RegPath))
    {
      New-Item -Path $RegPath -Force | Out-Null
    }
    New-ItemProperty -Path $RegPath -Name "Enabled" -Value "0" -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name "DisabledByDefault" -Value "1" -PropertyType DWORD -Force | Out-Null
    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server"
    IF (!(Test-Path $RegPath))
    {
      New-Item -Path $RegPath -Force | Out-Null
    }
    New-ItemProperty -Path $RegPath -Name "Enabled" -Value "0" -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name "DisabledByDefault" -Value "1" -PropertyType DWORD -Force | Out-Null
    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client"
    IF (!(Test-Path $RegPath))
    {
      New-Item -Path $RegPath -Force | Out-Null
    }
    New-ItemProperty -Path $RegPath -Name "Enabled" -Value "0" -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name "DisabledByDefault" -Value "1" -PropertyType DWORD -Force | Out-Null
    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server"
    IF (!(Test-Path $RegPath))
    {
      New-Item -Path $RegPath -Force | Out-Null
    }
    New-ItemProperty -Path $RegPath -Name "Enabled" -Value "0" -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name "DisabledByDefault" -Value "1" -PropertyType DWORD -Force | Out-Null
    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client"
    IF (!(Test-Path $RegPath))
    {
      New-Item -Path $RegPath -Force | Out-Null
    }
    New-ItemProperty -Path $RegPath -Name "Enabled" -Value "1" -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name "DisabledByDefault" -Value "0" -PropertyType DWORD -Force | Out-Null
    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server"
    IF (!(Test-Path $RegPath))
    {
      New-Item -Path $RegPath -Force | Out-Null
    }
    New-ItemProperty -Path $RegPath -Name "Enabled" -Value "1" -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $RegPath -Name "DisabledByDefault" -Value "0" -PropertyType DWORD -Force | Out-Null

    # Tighten up the .NET Framework
    $NetRegistryPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727"
    New-ItemProperty -Path $NetRegistryPath -Name "SchUseStrongCrypto" -Value "1" -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $NetRegistryPath -Name "SystemDefaultTlsVersions" -Value "1" -PropertyType DWORD -Force | Out-Null

    $NetRegistryPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319"
    New-ItemProperty -Path $NetRegistryPath -Name "SchUseStrongCrypto" -Value "1" -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $NetRegistryPath -Name "SystemDefaultTlsVersions" -Value "1" -PropertyType DWORD -Force | Out-Null

    $NetRegistryPath = "HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727"
    New-ItemProperty -Path $NetRegistryPath -Name "SchUseStrongCrypto" -Value "1" -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $NetRegistryPath -Name "SystemDefaultTlsVersions" -Value "1" -PropertyType DWORD -Force | Out-Null
    
    $NetRegistryPath = "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319"
    New-ItemProperty -Path $NetRegistryPath -Name "SchUseStrongCrypto" -Value "1" -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $NetRegistryPath -Name "SystemDefaultTlsVersions" -Value "1" -PropertyType DWORD -Force | Out-Null

    IF ($ACS)
    {
      #Get the DatabaseName\DSN
      $ACSParamReg = $ACSReg + '\Parameters'
      $ACSDSN = (Get-ItemProperty $ACSParamReg).ODBCConnection
      $ACSODBCReg = "HKLM:\SOFTWARE\ODBC\ODBC.INI\" + $ACSDSN
      #Update the registry
      New-ItemProperty -Path $ACSODBCReg -Name "Driver" -Value "%WINDIR%\system32\msodbcsql13.dll" -PropertyType STRING -Force | Out-Null
      New-ItemProperty -Path "HKLM:\SOFTWARE\ODBC\ODBC.INI\ODBC Data Sources" -Name $ACSDSN -Value "ODBC Driver 13 for SQL Server" -PropertyType STRING -Force | Out-Null
    }

    IF ($Error)
    {
      Write-Host `n"Something Went wrong attempting to write to the registry.  Review the error and try again.  Error is ($Error)." -ForegroundColor Red
      LogWrite "Something Went wrong attempting to write to the registry.  Review the error and try again.  Error is ($Error)."
      Start-Sleep -s 2
      PAUSE
      EXIT
    }
}
ELSE
{
  Write-Host `n"Registry NOT modifed" -ForegroundColor Yellow
  LogWrite "Registry NOT modifed"
  EXIT
}

Write-Host `n"Completed TLS 1.2 prerequsites, configuration, and registry modification.  We must REBOOT the server before this will take effect." -ForegroundColor Yellow
LogWrite "Completed TLS 1.2 prerequsites, configuration, and registry modification.  We must REBOOT the server before this will take effect."
Start-Sleep -s 2
$a = new-object -comobject wscript.shell 
$ConsoleAnswer = $a.popup("REBOOT this server NOW?",0,"REBOOT?",4)
IF($ConsoleAnswer -eq 6)
{
  LogWrite "Reboot was selected.  Rebooting server NOW."
  Restart-Computer
}
ELSE
{
  Write-Host `n"You chose not to reboot.  We must REBOOT the server before settings will take effect." -ForegroundColor Red
  LogWrite "You chose not to reboot.  We must REBOOT the server before settings will take effect."
  PAUSE
}

#End of Script
