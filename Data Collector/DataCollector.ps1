<#
	.SYNOPSIS
		This script collects data from your SCOM Environment that can be very helpful in troubleshooting.
	
	.DESCRIPTION
		For full support, please run this script from a Management Server..
	
	.PARAMETER Servers
		Set additional servers to run checks against.
	
	.PARAMETER GetRunAsAccounts
		Get RunAs Accounts that are set on each Management Server.
	
	.PARAMETER GetEventLogs
		Gather Event Logs with the localemetadata to ensure that you are able to open the Event log from any machine.
	
	.PARAMETER CheckCertificates
		Check the Certificates for validity for SCOM use, output in TXT format.
	
	.PARAMETER CheckTLSRegKeys
		Check for TLS Settings via Registry Keys, output in TXT format.
	
	.PARAMETER ExportMPs
		Export all Unsealed MP's.
	
	.PARAMETER MSInfo32
		Export MSInfo32 for viewing in TXT Format.
	
	.PARAMETER CaseNumber
		Add an Optional Case Number to the Output of the Zip File.
	
	.PARAMETER AssumeYes
		This will allow you to not be prompted for anything.
	
	.PARAMETER GenerateHTML
		Generate a HTML Report Page {EXPERIMENTAL}
	
	.EXAMPLE
		PS C:\> .\DataCollector.ps1 -Servers Agent1.contoso.com, Agent2.contoso.com -CheckTLSRegKeys -CheckCertificates -GetEventLogs -MSInfo32 -ExportMPs -CaseNumber 0123456789 -GenerateHTML -AssumeYes
	
	.NOTES
		This script is intended for System Center Operations Manager Environments. This is currently in development by the SCEM Support Team with Microsoft.
	
	.VERSION
		v3.2.1 - October 23rd, 2020
#>
[CmdletBinding()]
[OutputType([string])]
param
(
	[Parameter(ValueFromPipeline = $true,
			   Position = 1)]
	[Array]$Servers,
	[Parameter(ValueFromPipeline = $true,
			   Position = 2)]
	[switch]$GetRunAsAccounts,
	[Parameter(Mandatory = $false,
			   ValueFromPipeline = $true,
			   Position = 3)]
	[switch]$GetEventLogs,
	[Parameter(Mandatory = $false,
			   ValueFromPipeline = $true,
			   Position = 4)]
	[switch]$CheckCertificates,
	[Parameter(Mandatory = $false,
			   ValueFromPipeline = $true,
			   Position = 5)]
	[switch]$CheckTLSRegKeys,
	[Parameter(Mandatory = $false,
			   ValueFromPipeline = $true,
			   Position = 6)]
	[switch]$ExportMPs,
	[Parameter(Mandatory = $false,
			   ValueFromPipeline = $true,
			   Position = 7)]
	[switch]$MSInfo32,
	[Parameter(Mandatory = $false,
			   ValueFromPipeline = $true,
			   Position = 8)]
	[string]$CaseNumber,
	[Parameter(Mandatory = $false,
			   ValueFromPipeline = $true,
			   Position = 9)]
	[switch]$AssumeYes,
	[Parameter(Mandatory = $false,
			   ValueFromPipeline = $true,
			   Position = 10)]
	[switch]$GenerateHTML
)
$StartTime = Get-Date

Write-Host '===================================================================' -ForegroundColor DarkYellow
Write-Host '==========================  Start of Script =======================' -ForegroundColor DarkYellow
Write-Host '===================================================================' -ForegroundColor DarkYellow
whoami
#Get the script path
[string]$ScriptPath = $PSScriptRoot
$currentPath = $myinvocation.mycommand.definition
$OutputPath = "$ScriptPath\Output"
$CSVFile = $ScriptPath

Get-Item $PSScriptRoot\Functions | Unblock-File | Out-Null

$scriptout = [Array] @()
[String]$Comp = Resolve-DnsName $env:COMPUTERNAME -Type A | Select-Object -Property Name -ExpandProperty Name
$checkingpermission = "Checking for elevated permissions..."
$scriptout += $checkingpermission
Write-Host $checkingpermission -ForegroundColor Gray
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator"))
{
	$nopermission = "Insufficient permissions to run this script. Attempting to open the PowerShell script ($currentPath) as administrator."
	$scriptout += $nopermission
	Write-Warning $nopermission
   # We are not running "as Administrator" - so relaunch as administrator
   Start-Process powershell.exe '-File',$currentPath,'-Verb','RunAs' -WorkingDirectory $ScriptPath
   break
}
else
{
	$permissiongranted = " Currently running as administrator - proceeding with script execution..."
	$out += $permissiongranted
	Write-Host $permissiongranted -ForegroundColor Green
}
$omsdkUserOrig = (Get-WmiObject Win32_Service -Filter "Name='omsdk'").StartName -split '@'
$omsdkUserSplit = ($omsdkUserOrig)[0]
if($omsdkUserOrig[1])
{
$omsdkUser = $omsdkUserOrig[1] + "\" + $omsdkUserOrig[0]
}
$currentUser = ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name).split('\')[1]

function Start-ScomDataCollector
{
	[CmdletBinding()]
	param
	(
		[Parameter(ValueFromPipeline = $true,
				   Position = 1)]
		[Array]$Servers,
		[Parameter(ValueFromPipeline = $true,
				   Position = 2)]
		[switch]$GetRunAsAccounts,
		[Parameter(Mandatory = $false,
				   ValueFromPipeline = $true,
				   Position = 3)]
		[switch]$GetEventLogs,
		[Parameter(Mandatory = $false,
				   ValueFromPipeline = $true,
				   Position = 4)]
		[switch]$CheckCertificates,
		[Parameter(Mandatory = $false,
				   ValueFromPipeline = $true,
				   Position = 5)]
		[switch]$CheckTLSRegKeys,
		[Parameter(Mandatory = $false,
				   ValueFromPipeline = $true,
				   Position = 6)]
		[switch]$ExportMPs,
		[Parameter(Mandatory = $false,
				   ValueFromPipeline = $true,
				   Position = 7)]
		[switch]$MSInfo32,
		[Parameter(Mandatory = $false,
				   ValueFromPipeline = $true,
				   Position = 8)]
		[string]$CaseNumber,
		[Parameter(Mandatory = $false,
				   ValueFromPipeline = $true,
				   Position = 9)]
		[switch]$AssumeYes,
		[Parameter(Mandatory = $false,
				   ValueFromPipeline = $true,
				   Position = 10)]
		[switch]$GenerateHTML
	)

    if ($omsdkUserSplit -ne $currentUser)
    {
	    do
	    {
            if(!$AssumeYes)
            {
            $currentPathFormat = """$currentPath"""
		    $answer = Read-Host "Would you like to run this script as the SDK Account ($omsdkUser)? (Y/N)"
            }
            else{$answer = "n"}
	    }
	    until ($answer -eq "y" -or $answer -eq "n")
	    if ($answer -eq "y")
	    {
            try{$Credentials = Get-Credential -Message "Please provide credentials to run this script with" $omsdkUser}catch{Write-Warning $_}
            try{Start-Process powershell.exe -Credential $Credentials -ArgumentList "-File",$currentPathFormat -NoNewWindow}catch{Write-Warning $_}
		    exit 0
	    }
	
}
	
	#=================================================================================
	#  SCOM Health SQL Query Collection Script
	#
	#  Author: Kevin Holman
	#  v1.5
	#  Heavily modified, with permission, by Michael Kallhoff (mikallho) & Blake Drumm (v-bdrumm) & Bobby King (v-bking)
	#=================================================================================
	# Constants section - modify stuff here:
	#=================================================================================
	#$OpsDB_SQLServer = "SQL2A.opsmgr.net"
	#$OpsDB_SQLDBName =  "OperationsManager"
	#$DW_SQLServer = "SQL2A.opsmgr.net"
	#$DW_SQLDBName =  "OperationsManagerDW"
	#=================================================================================
	# Begin MAIN script section
	#=================================================================================
	#Clear-Host
	# Check if this is running on a SCOM Management Server
	# Get SQLServer info from Registry if so
	Import-Module OperationsManager -ErrorAction SilentlyContinue
	$MSKey = "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Server Management Groups"
	IF (Test-Path $MSKey)
	{
		# This is a management server.  Try to get the database values.
		$SCOMKey = "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup"
		$SCOMData = Get-ItemProperty $SCOMKey
		$OpsDB_SQLServer = ($SCOMData).DatabaseServerName
		$OpsDB_SQLServerOriginal = $OpsDB_SQLServer
		$OpsDB_SQLDBName = ($SCOMData).DatabaseName
		$DW_SQLServer = ($SCOMData).DataWarehouseDBServerName
		$DW_SQLServerOriginal = $DW_SQLServer
		$DW_SQLDBName = ($SCOMData).DataWarehouseDBName
		$mgmtserver = 1
	}
	ELSE
	{
		if ($RemoteMGMTserver)
		{
			$ComputerName = $RemoteMGMTserver
		}
		else
		{
			$ComputerName = read-host "Please enter the name of a SCOM management server $env:userdomain\$env:USERNAME has permissions on"
		}
		$Hive = [Microsoft.Win32.RegistryHive]::LocalMachine
		$KeyPath = 'SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup'
		$OpsDBServer = 'DatabaseServerName'
		$OpsDBName = 'DatabaseName'
		$DWServer = 'DataWarehouseDBServerName'
		$DWDB = 'DataWarehouseDBName'
		$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hive, $ComputerName)
		$key = $reg.OpenSubKey($KeyPath)
		$OpsDB_SQLServerOriginal = $key.GetValue($OpsDBServer)
		$OpsDB_SQLDBName = $key.GetValue($OpsDBName)
		$DW_SQLServerOriginal = $key.GetValue($DWServer)
		$DW_SQLDBName = $key.GetValue($DWDB)
	}
	
	$Populated = 1
	
	. $ScriptPath`\Functions\SQL-Queries.ps1
	SQL-Queries
	
	#$TLSservers = import-csv $OutputPath\ManagementServers.csv
	$ManagementServers = Get-SCOMManagementServer | where { $_.IsGateway -eq $false } | Sort-Object DisplayName -Descending | Select-Object DisplayName -ExpandProperty DisplayName
	[string[]]$TLSservers = $ManagementServers
	[string[]]$TLSservers += $DW_SQLServer
	[string[]]$TLSservers += $OpsDB_SQLServer
	
	if ($Servers)
	{
		$Servers = ($Servers.Split(",").Split(" ") -replace (" ", ""))
		$Servers = $Servers | select -Unique
		foreach ($Server in $Servers)
		{
			[string[]]$TLSservers += $Server
		}
	}
	
	[string[]]$TLSservers = $TLSservers | select -Unique | Where { $null -ne $_ }
	try { $TLSservers | % { [array]$DNSCheckedServers += ([System.Net.Dns]::GetHostByName(("$_"))).Hostname } }
	catch { Write-Warning $_ }
	[array]$DNSVerifiedServers = $DNSCheckedServers | select -Unique | Sort-Object
	#$TLSservers += "DC22"   # fictitious server added to simulate a no access/server down situation
	$DNSCount = ($DNSVerifiedServers).Count
	write-Output " "
	Write-Output "================================`nTesting Connectivity to Servers (Count: $DNSCount)"
	[string[]]$TestedTLSservers = @()
	foreach ($Rsrv in $DNSVerifiedServers)
	{
		Write-Host "  Testing $Rsrv" -ForegroundColor Gray
		$test = $null
		$test = test-path "\\$Rsrv\c$"
		if ($test)
		{
			Write-Host "    Successfully Accessed : $Rsrv" -ForegroundColor Green
			$TestedTLSservers += $Rsrv.Split(",")
		}
		else
		{
			Write-Host "    Access to $Rsrv Failed! Removing from Server Array! 
    Please verify that the server is online, and that your account has remote access to it.`n" -ForegroundColor Gray
		}
	}
	if ($GetRunAsAccounts)
	{
		Write-Output " "
		Write-Host "================================`nGathering RunAs Accounts" -NoNewLine
		. $ScriptPath`\Functions\Get-RunasAccount.ps1
		foreach ($RunAsSvr in $ManagementServers)
		{
			Write-Host "`n    Running against : " -NoNewline -ForegroundColor Gray
			Write-Host "$RunAsSvr" -NoNewline -ForegroundColor Cyan
			Get-SCOMRunasAccount -ManagementServer $RunAsSvr -OrderByAccount | ft * | Out-File $OutputPath\$RunAsSvr.RunAsAccountInfo.txt
		}
	}
	if ($CheckCertificates)
	{
		Write-Output " "
		Write-Output "================================`nStarting Certificate Checker"
		. $ScriptPath`\Functions\Certificate-Check.ps1
		foreach ($CertChkSvr in $TestedTLSservers)
		{
			SCOM-CertCheck -Servers $CertChkSvr | Out-String | Add-Content $OutputPath\$CertChkSvr.CertificateInfo.txt
		}
	}
	
	if ($CheckTLSRegKeys)
	{
		Write-Output " "
		Write-Output "================================`nStarting TLS Registry Checker"
		. $ScriptPath`\Functions\Compare-TLSRegKeys.ps1
		# This will be updated with CipherSuite checks at some point
		Compare-TLSRegKeys -Servers $TestedTLSservers |
		sort server, protocol, type |
		ft Server, Protocol, Type, Disabledbydefault, IsEnabled -autosize |
		out-string |
		Out-File $OutputPath\TLSRegKeys.txt
	}
	
	if ($GetEventLogs)
	{
		Write-Output " "
		Write-Output "================================`nStarting Event Log Gathering"
		. $ScriptPath`\Functions\Get-EventLog.ps1
		if ((Test-Path -Path "$OutputPath\Event Logs") -eq $false)
		{
			Write-Host "  Creating Folder: $OutputPath\Event Logs" -ForegroundColor Gray
			md "$OutputPath\Event Logs" | out-null
		}
		else
		{
			Write-Host "  Existing Folder Found: $OutputPath\Event Logs" -ForegroundColor Gray
			Remove-Item "$OutputPath\Event Logs" -Recurse | Out-Null
			Write-Host "   Deleting folder contents" -ForegroundColor Gray
			md "$OutputPath\Event Logs" | out-null
			Write-Host "    Folder Created: $OutputPath\Event Logs" -ForegroundColor Gray
		}
		foreach ($ElogServer in $TestedTLSservers)
		{
			Get-SCOMEventLogs -Servers $ELogServer
		}
		Write-Output " "
	}
	
	if ($ExportMPs)
	{
		try
		{
			if ($mgmtserver = 1)
			{
				Write-Output "================================`nStarting Unsealed MP Export"
				. $ScriptPath`\Functions\ExportMP.ps1
				MP-Export
    <#
        md $OutputPath\MPSealed | out-null
        try{
           (Get-SCOMManagementPack).where{$_.Sealed -eq $true} | Export-SCOMManagementPack -path $OutputPath\MPSealed
        }catch{
           
        }
    #>
				
			}
			else
			{
				Write-Warning "  Exporting Management Packs is only possible from a management server"
			}
		}
		catch { Write-Warning $_ }
	}
	
	if ($msinfo32)
	{
		write-output " "
		Write-Host "================================`nStarting MSInfo32 reporting"
		. $ScriptPath`\Functions\MsInfo32.ps1
		MSInfo32-Gathering
	}
	Write-Host "`n`n================================`nGathering Agent(s) Pending Management"
	$pendingMgmt = Get-SCOMPendingManagement | Out-File -FilePath "$OutputPath\Pending Management.txt"
	Write-Host "    Running Powershell Command: " -NoNewLine -ForegroundColor Cyan
	Write-Host "`n      Get-SCOMPendingManagement" -NoNewLine -ForegroundColor Magenta
	Write-Host " against" -NoNewLine -ForegroundColor Cyan
	Write-Host " $env:COMPUTERNAME" -NoNewLine -ForegroundColor Magenta
	Write-Host "-" -NoNewline -ForegroundColor Green
	do { Write-Host "-" -NoNewline -ForegroundColor Green; sleep 1 }
	while ($pendingMgmt)
	Write-Host "> Command Execution Completed!`n" -NoNewline -ForegroundColor Green
	
	write-Output " "
	Write-Output "================================`nGathering System Center Operations Manager General Information"
	Write-Host "    Executing Function" -NoNewLine -ForegroundColor Cyan
	Write-Host "-" -NoNewline -ForegroundColor Green
	. $ScriptPath`\Functions\General-Info.ps1
	$collectCompleted = Get-SCOMGeneralInfo
	do { Write-Host "-" -NoNewline -ForegroundColor Green; sleep 1 }
	until ($collectCompleted)
	Write-Host "> Completed!`n" -NoNewline -ForegroundColor Green
	
	if ($GenerateHTML)
	{
		Write-Output "`n================================`nGenerating System Center Operations Manager Report Webpage"
		. $ScriptPath`\Functions\Report-Webpage.ps1
		Write-Host "    Generating Report Webpage to be viewed in a Web Browser" -NoNewLine -ForegroundColor Cyan
		Write-Host "-" -NoNewline -ForegroundColor Green
		$reportWebpageCompleted = Report-Webpage
		do { Write-Host "-" -NoNewline -ForegroundColor Green; sleep 1 }
		until ($reportWebpageCompleted)
		Write-Host "> Completed!`n" -NoNewline -ForegroundColor Green
	}
	write-output " "
	write-output "================================`n   Wrapping Up`n================================"
	Write-Host "Moving stuff around and zipping everything up for easy transport" -ForegroundColor Gray
	. $ScriptPath`\Functions\Wrapping-Up.ps1
	Wrap-Up
	Write-Host "Script has completed" -ForegroundColor Green -NoNewline
	$x = 1
	do { $x++; Write-Host "." -NoNewline -ForegroundColor Green; Sleep 1 }
	until ($x -eq 3)
	Write-Output " "
	Write-Warning "Exiting script..."
	start C:\Windows\explorer.exe -ArgumentList "/select, $destfile"
	exit 0
}

if (($CheckTLSRegKeys -or $CheckCertificates -or $GetEventLogs -or $MSInfo32 -or $AssumeYes -or $ExportMPs -or $CaseNumber -or $Servers -or $GenerateHTML -or $GetRunAsAccounts))
{
	Start-ScomDataCollector -Servers:$Servers -GetRunAsAccounts:$GetRunAsAccounts -CheckTLSRegKeys:$CheckTLSRegKeys -CheckCertificates:$CheckCertificates -GetEventLogs:$GetEventLogs -MSInfo32:$MSInfo32 -ExportMPs:$ExportMPs -CaseNumber:$CaseNumber -GenerateHTML:$GenerateHTML -AssumeYes:$AssumeYes
}
else
{
	# Enter Switches here that you want to run if no switches are specified during runtime.
	Start-ScomDataCollector -AssumeYes
}
Write-Host "Something is wrong, Script has been stopped" -ForegroundColor Green -NoNewline
$x = 1
do { $x++; Write-Host "." -NoNewline -ForegroundColor Green; Sleep 1 }
until ($x -eq 3)
Write-Output " "
Write-Warning "Exiting script..."
exit 1


# SIG # Begin signature block
# MIIRKwYJKoZIhvcNAQcCoIIRHDCCERgCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDS455tIQ+9OHCA
# fw7jN/kXcnUF+JiJgh6s5XyaYx045KCCDB4wggM3MIICI6ADAgECAhBid7E8Kyy6
# okrKDBZQBZ7/MAkGBSsOAwIdBQAwGTEXMBUGA1UEAxMOQW50aG9ueSBEdWd1aWQw
# IBcNMTcwNTI0MDIxNjI2WhgPMjE3NDAxMTUxNDAwMDBaMBkxFzAVBgNVBAMTDkFu
# dGhvbnkgRHVndWlkMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3NXP
# 0qsalOagDYU6g7VAQqeqZYlICq+yClVDSBb+3DNSFIy8M2IogpocMT5wAwOvnBBO
# Yz34mgjqc03B7/uvXFDva1PW/4gRwL5jC+PJxg/FG4ghD+fRlKCDYC/55nNos04D
# P2APbkO1VLo9LjCVQRUfXjtbifOWtMHOzcw/AzY5PuxzLc5YCPXdXBCMw94aL4jX
# ABdkXp2o3kO9opsWkeZpG7VPsnGe0Ov4A0kHo5/33wVtNOWWQKDD8qJA/wZLDmKA
# aQX60/hJKzzV7P7hNKoWmUxBAILe/N/soprlj8m5Li+Avx82XumDyH8LPyUad2YL
# oNcsAZFcNokt3S+QlQIDAQABo4GAMH4wDwYDVR0TAQH/BAUwAwIBADAfBgNVHSUE
# GDAWBggrBgEFBQcDAwYKKwYBBAGCNwoDDTBKBgNVHQEEQzBBgBA0bMynuhE47c/y
# Vt4RcHC7oRswGTEXMBUGA1UEAxMOQW50aG9ueSBEdWd1aWSCEGJ3sTwrLLqiSsoM
# FlAFnv8wCQYFKw4DAh0FAAOCAQEALkbCgE0Z3XNqhtD+COhaMyN+CiifirdRVUwL
# jbwNjlq50x3MPx8Ty6/xs8W8nlM5Gl84S2LKDHYf/ycR/rR4L5BAR7HX1dLzVrbU
# DvoFA1r2vCwUdk0fODBASIb1reort7EyBX8ofE4neW6J6uMrvy8IGmWH4caAJ9jU
# o5pStCgn8aDvXS9Fx3nW+wwU3vUzcQYXXolnh0/EzB049/3KPhPQkWbZoxTRGSRb
# VnhrGIcvqLJN8fm5flG343Om32QDnzmEsQIWkjq8hiQXt4oIyLuoQoEcK52zPJ6R
# A44Icpr6kqYx/zjBrVdWL04cdNIFHles4CiiuOfkfIuxtXp+8DCCBBUwggL9oAMC
# AQICCwQAAAAAATGJxlAEMA0GCSqGSIb3DQEBCwUAMEwxIDAeBgNVBAsTF0dsb2Jh
# bFNpZ24gUm9vdCBDQSAtIFIzMRMwEQYDVQQKEwpHbG9iYWxTaWduMRMwEQYDVQQD
# EwpHbG9iYWxTaWduMB4XDTExMDgwMjEwMDAwMFoXDTI5MDMyOTEwMDAwMFowWzEL
# MAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExMTAvBgNVBAMT
# KEdsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gU0hBMjU2IC0gRzIwggEiMA0G
# CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCqm47DqxFRJQG2lpTiT9jBCPZGI9lF
# xZWXW6sav9JsV8kzBh+gD8Y8flNIer+dh56v7sOMR+FC7OPjoUpsDBfEpsG5zVvx
# HkSJjv4L3iFYE+5NyMVnCxyys/E0dpGiywdtN8WgRyYCFaSQkal5ntfrV50rfCLY
# FNfxBx54IjZrd3mvr/l/jk7htQgx/ertS3FijCPxAzmPRHm2dgNXnq0vCEbc0oy8
# 9I50zshoaVF2EYsPXSRbGVQ9JsxAjYInG1kgfVn2k4CO+Co4/WugQGUfV3bMW44E
# Tyyo24RQE0/G3Iu5+N1pTIjrnHswJvx6WLtZvBRykoFXt3bJ2IAKgG4JAgMBAAGj
# gegwgeUwDgYDVR0PAQH/BAQDAgEGMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0O
# BBYEFJIhp0qVXWSwm7Qe5gA3R+adQStMMEcGA1UdIARAMD4wPAYEVR0gADA0MDIG
# CCsGAQUFBwIBFiZodHRwczovL3d3dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0b3J5
# LzA2BgNVHR8ELzAtMCugKaAnhiVodHRwOi8vY3JsLmdsb2JhbHNpZ24ubmV0L3Jv
# b3QtcjMuY3JsMB8GA1UdIwQYMBaAFI/wS3+oLkUkrk1Q+mOai97i3Ru8MA0GCSqG
# SIb3DQEBCwUAA4IBAQAEVoJKfNDOyb82ZtG+NZ6TbJfoBs4xGFn5bEFfgC7AQiW4
# GMf81LE3xGigzyhqA3RLY5eFd2E71y/j9b0zopJ9ER+eimzvLLD0Yo02c9EWNvG8
# Xuy0gJh4/NJ2eejhIZTgH8Si4apn27Occ+VAIs85ztvmd5Wnu7LL9hmGnZ/I1JgF
# snFvTnWu8T1kajteTkamKl0IkvGj8x10v2INI4xcKjiV0sDVzc+I2h8otbqBaWQq
# taai1XOv3EbbBK6R127FmLrUR8RWdIBHeFiMvu8r/exsv9GU979Q4HvgkP0gGHgY
# Il0ILowcoJfzHZl9o52R0wZETgRuehwg4zbwtlC5MIIExjCCA66gAwIBAgIMJFS4
# fx4UU603+qF4MA0GCSqGSIb3DQEBCwUAMFsxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMTEwLwYDVQQDEyhHbG9iYWxTaWduIFRpbWVzdGFt
# cGluZyBDQSAtIFNIQTI1NiAtIEcyMB4XDTE4MDIxOTAwMDAwMFoXDTI5MDMxODEw
# MDAwMFowOzE5MDcGA1UEAwwwR2xvYmFsU2lnbiBUU0EgZm9yIE1TIEF1dGhlbnRp
# Y29kZSBhZHZhbmNlZCAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
# AQEA2XhhoZauEv+j/yf2RGB7alYtZ+NfnzGSKkjt+QWEDm1OIlbK2JmXjmnKn3sP
# CMgqK2jRKGErn+Qm7rq497DsXmob4li1tL0dCe3N6D3UZv++IiJtNibPEXiX6VUA
# KMPpN069GeUXhEiyHCGt7HPS86in6V/oNc6FE6cim6yC6f7xX8QSWrH3DEDm0qDg
# TWjQ7QwMEB2PBV9kVfm7KEcGDNgGPzfDJjYljHsPJ4hcODGlAfZeZN6DwBRc4OfS
# XsyN6iOAGSqzYi5gx6pn1rNA7lJ/Vgzv2QXXlSBdhRVAz16RlVGeRhoXkb7BwAd1
# skv3NrrFVGxfihv7DShhyInwFQIDAQABo4IBqDCCAaQwDgYDVR0PAQH/BAQDAgeA
# MEwGA1UdIARFMEMwQQYJKwYBBAGgMgEeMDQwMgYIKwYBBQUHAgEWJmh0dHBzOi8v
# d3d3Lmdsb2JhbHNpZ24uY29tL3JlcG9zaXRvcnkvMAkGA1UdEwQCMAAwFgYDVR0l
# AQH/BAwwCgYIKwYBBQUHAwgwRgYDVR0fBD8wPTA7oDmgN4Y1aHR0cDovL2NybC5n
# bG9iYWxzaWduLmNvbS9ncy9nc3RpbWVzdGFtcGluZ3NoYTJnMi5jcmwwgZgGCCsG
# AQUFBwEBBIGLMIGIMEgGCCsGAQUFBzAChjxodHRwOi8vc2VjdXJlLmdsb2JhbHNp
# Z24uY29tL2NhY2VydC9nc3RpbWVzdGFtcGluZ3NoYTJnMi5jcnQwPAYIKwYBBQUH
# MAGGMGh0dHA6Ly9vY3NwMi5nbG9iYWxzaWduLmNvbS9nc3RpbWVzdGFtcGluZ3No
# YTJnMjAdBgNVHQ4EFgQU1Ie4jeblQDydWgZjxkWE2d27HMMwHwYDVR0jBBgwFoAU
# kiGnSpVdZLCbtB7mADdH5p1BK0wwDQYJKoZIhvcNAQELBQADggEBACRyUKUMvEAJ
# psH01YJqTkFfzseIOdPkfPkibDh4uPS692vhJOudfM1IrIvstXZMj9yCaQiW57rh
# Z7bwpr8YCELh680ZWDmlEWEj1hnXAOm70vlfQfsEPv6KIGAM0U8jWhkaGO/Yxt7W
# X1ShepPhtneFwPuxRsQJri9T+5WcjibiSuTE5jw177rG2bnFzc0Hm2O7PQ9hvFV8
# IxC1jIqj0mhFsUC6oN08GxVAuEl4b+WUwG1WSzz2EirUhfNIEwXhuzBFCkG3fJJu
# vk6SYILKW2TmVdPSB96dX5uhAe2b8MNduxnwGAyaoBzpaggLPelml6d1Hg+/KNcJ
# Iw3iFvq68zQxggRjMIIEXwIBATAtMBkxFzAVBgNVBAMTDkFudGhvbnkgRHVndWlk
# AhBid7E8Kyy6okrKDBZQBZ7/MA0GCWCGSAFlAwQCAQUAoEwwGQYJKoZIhvcNAQkD
# MQwGCisGAQQBgjcCAQQwLwYJKoZIhvcNAQkEMSIEIB2cwFil4O32TJuZKf0x7mqf
# 8ZssoTh8kZV21sLWomc4MA0GCSqGSIb3DQEBAQUABIIBAKCaGlKAJga1L68sTKY7
# tw4+GrVQi6UpBnydRNu4ihtyz7M7oXVjUyBT5rwilbLD5FMsekzfNU5HW6S8Y6U2
# imDnxNm301WPqLpRrDqTrkgWDspQyrM02fYT5CeEl4TETlfWtHY/ugPyaOV/VX35
# s5EbxCX0msikOE6WCw5YW1kCf3fXPUjCw7Z+B64p6KTssO3DmZLzcyJlkVzxI6T0
# NuiKKNY/Be1GxHSrB0s0DWWHM2XINHv7/79wDo2D2pEmo0ytB2ivfhbnJLcJLo0T
# hV7ECNriKG4Z+f0tQV2M7JdZ6la9tsPYW6R4rYByAK5qubjiNRZ9Jpk3ZqwNC7Yh
# I+ChggK5MIICtQYJKoZIhvcNAQkGMYICpjCCAqICAQEwazBbMQswCQYDVQQGEwJC
# RTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTExMC8GA1UEAxMoR2xvYmFsU2ln
# biBUaW1lc3RhbXBpbmcgQ0EgLSBTSEEyNTYgLSBHMgIMJFS4fx4UU603+qF4MA0G
# CWCGSAFlAwQCAQUAoIIBDDAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqG
# SIb3DQEJBTEPFw0yMDA3MjkwMTMxNDNaMC8GCSqGSIb3DQEJBDEiBCA3gPY6Lcua
# iL46ptZFidOCN+CS7DWZB/drOVtP/art8DCBoAYLKoZIhvcNAQkQAgwxgZAwgY0w
# gYowgYcEFD7HZtXU1HLiGx8hQ1IcMbeQ2UtoMG8wX6RdMFsxCzAJBgNVBAYTAkJF
# MRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMTEwLwYDVQQDEyhHbG9iYWxTaWdu
# IFRpbWVzdGFtcGluZyBDQSAtIFNIQTI1NiAtIEcyAgwkVLh/HhRTrTf6oXgwDQYJ
# KoZIhvcNAQEBBQAEggEAbr3bv1P/2HJkavg825ppfM5FRVOAvzQkrCIQdCR5v45V
# Bf5gQufyZODPETBoAVHwG/3xXPDwxf3vC+ilnNRUJMgg70XsJOoyy92dUbvcMiHf
# UqVG1So1itQI7BOLvznLivxR9sIXnLiID+kw47+dp0NFqu1jHhscSYq1ukMrtZPV
# 5cPJtdXXMY+Ieqr2X24zafwbGYas4hIONq57B8T0Uybjk8kwTZNBFMwMWK+1itoN
# IHB/TkWW347EfUbPPts0HUgCBPHD8adlPMFOgD2GzQWnIKt4vHM6KpPd1a6FOHYA
# yivknuCFbNXxp7eXsxen/Apx4Tgqdyq4xUBDZvrOuA==
# SIG # End signature block