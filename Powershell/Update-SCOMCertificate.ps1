<#
.SYNOPSIS
    Script to manage and configure certificates for System Center Operations Manager and Remote Desktop Protocol.

.DESCRIPTION
    This PowerShell script imports certificates for SCOM and RDP, updates registry settings, and restarts services as necessary. 
    It allows for management of certificates based on various parameters such as FriendlyName, SubjectName, SerialNumber, etc.

.PARAMETER FriendlyName
    Optional. The friendly name of the certificate to import.

.PARAMETER SubjectName
    Optional. The subject name of the certificate.

.PARAMETER SerialNumber
    Optional. The serial number of the certificate.

.PARAMETER DateIssued
    Optional. The issue date of the certificate.

.PARAMETER ExpirationDate
    Optional. The expiration date of the certificate.

.PARAMETER ShowAllCertificates
    Switch to display all certificates in the Local Computer Personal Certificate Store.

.PARAMETER UpdateRegistry
    Switch to update the registry with the script. This is required for the script to make changes.

.EXAMPLE
    .\YourScriptName.ps1 -FriendlyName "MyCert" -UpdateRegistry
    This example imports a certificate with the friendly name "MyCert" and updates the registry.

.NOTES
    Author: Blake Drumm (blakedrumm@microsoft.com)
    Date Created: June 6th, 2023
    Date Modified: June 14th, 2023
    Version: 1.0

    This script is designed for use with Microsoft System Center Operations Manager. Ensure you have the appropriate permissions before running this script.

.LINK
    https://blakedrumm.com/
#>
param
(
	[string]$FriendlyName,
	[string]$SubjectName,
	[string]$SerialNumber,
	[string]$DateIssued,
	[string]$ExpirationDate,
	[switch]$ShowAllCertificates,
	[switch]$UpdateRegistry
)

# Author: Blake Drumm (blakedrumm@microsoft.com)
# Date Created: June 6th, 2023
# Date Modified: June 14th, 2023

#region ImportCertAndUsePassword

$PathToPassword = 'C:\Certs\password.txt'

#region ExportPassword
if (-NOT $(Get-Item $PathToPassword -ErrorAction SilentlyContinue))
{
	# This Section can be removed once you write the password to a file
	$SecurePassword = ConvertTo-SecureString "Password1" -AsPlainText -Force
	$PasswordBytes = ConvertFrom-SecureString -SecureString $SecurePassword
	Set-Content -Path $PathToPassword -Value $PasswordBytes
	pause
	#endregion
}

$PasswordBytes = Get-Content -Path $PathToPassword
$pwd = ConvertTo-SecureString -String $PasswordBytes

$RDPCertPlusPath = "C:\Certs\$env:COMPUTERNAME-RDPCertPlusPath.pfx"
$RDPCertPlusPathFound = (Resolve-Path -Path $RDPCertPlusPath -ErrorAction SilentlyContinue).Path
if ($RDPCertPlusPath)
{
	$ImportRDPCert = Import-PfxCertificate -FilePath $RDPCertPlusPath -CertStoreLocation Cert:\LocalMachine\My -Password $pwd
	WMIC /namespace:\\root\cimv2\TerminalServicesPATH Win32_TSGeneralSettingSet SSLCertificateSHA1Hash="$($ImportRDPCert.Thumbprint)"
}
else
{
	Write-Host "Cannot find file: $RDPCertPlusPath" -ForegroundColor Red
}

$SCOMPath = "C:\Certs\$env:COMPUTERNAME-SCCM_SCOMCertPlusPath.pfx"
$SCOMPathFound = (Resolve-Path -Path $SCOMPath -ErrorAction SilentlyContinue).Path
if ($SCOMPath)
{
	$ImportSCOMCert = Import-PfxCertificate -FilePath $SCOMPath -CertStoreLocation Cert:\LocalMachine\My -Password $pwd
}
else
{
	Write-Host "Cannot find file: $SCOMPath" -ForegroundColor Red
}



if ($ImportSCOMCert)
{
	$SerialNumber = $ImportSCOMCert.SerialNumber
}
#endregion

# -------------------------------------------------------------------------------------------------
#region Variables
# -------------------------------------------------------------------------------------------------

if (-NOT $FriendlyName)
{
	$FriendlyName = "" # OPTIONAL : This allows you to import a certificate with a specific Friendly Name.
}
if (-NOT $SubjectName)
{
	$SubjectName = "" # OPTIONAL : This allows you to import a certificate with a specific Subject Name. If left blank, the script will check the Subject Name against the computer name of the local machine.
}
if (-NOT $SerialNumber)
{
	$SerialNumber = "" # OPTIONAL : This allows you to import a certificate with a specific Serial Number.
}
if (-NOT $DateIssued)
{
	$DateIssued = "" # OPTIONAL : This allows you to import a certificate with a specific Date Issued. (Example value: 2/7/2023 7:22:52 PM)
}
if (-NOT $ExpirationDate)
{
	$ExpirationDate = "" # OPTIONAL : This allows you to import a certificate with a specific Expiration Date. (Example value: 2/7/2025 7:22:52 PM)
}
if (-NOT $ShowAllCertificates)
{
	[string]$ShowAllCertificates = "No" # OPTIONAL : This allows you to show all the certificates in the Local Computer Personal Certificate Store. (Acceptable values are: (Y)es or (N)o)
}
else
{
	[string]$ShowAllCertificates = "No"
}
if (-NOT $UpdateRegistry)
{
	[string]$UpdateRegistry = "Yes" # REQUIRED : This allows you update the registry with the script, or you can see what happens without the script making changes. (Acceptable values are: (Y)es or (N)o)
}
else
{
	[string]$UpdateRegistry = "Yes"
}


# -------------------------------------------------------------------------------------------------
#endregion
# -------------------------------------------------------------------------------------------------

# DO NOT EDIT PAST THIS LINE

# -------------------------------------------------------------------------------------------------

$RegistryPath = "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Machine Settings"

[string]$SerialNumber = $SerialNumber.Replace(" ", "")

$certs = [Array] (Get-ChildItem cert:\LocalMachine\my\) | Sort-Object NotAfter -Descending

foreach ($cert in $certs)
{
	$skipForeach = $null
	# Check if FriendlyName variable is set
	if ($FriendlyName)
	{
		if ($FriendlyName -ne $cert.FriendlyName)
		{
			$skipForeach = $true
		}
	}
	# Check if SubjectName starts with the machine name
	if ($SubjectName)
	{
		if ($cert.SubjectName.Name -notmatch "$SubjectName")
		{
			$skipForeach = $true
		}
	}
	elseif ($cert.SubjectName.Name -notmatch $env:COMPUTERNAME)
	{
		if ($FriendlyName -or $SerialNumber -or $DateIssued -or $ExpirationDate -or ($ShowAllCertificates -match "^(Y|Yes)$"))
		{
			Out-Null
		}
		else
		{
			$skipForeach = $true
		}
	}
	# Check if SerialNumber variable is set
	if ($SerialNumber)
	{
		if ($cert.SerialNumber.ToString().ToLower() -ne "$($SerialNumber.ToLower())")
		{
			$skipForeach = $true
		}
	}
	# Check if Date Issued variable is set
	if ($DateIssued)
	{
		if ($cert.GetEffectiveDateString() -notmatch "$DateIssued")
		{
			$skipForeach = $true
		}
	}
	# Check if ExpirationDate variable is set
	if ($ExpirationDate)
	{
		# Convert from datetime to a string and check if the Expiration Date doesn't equal what is set in the ExprirationDate variable.
		if ($cert.NotAfter.ToString() -notmatch "$ExpirationDate")
		{
			$skipForeach = $true
		}
	}
	elseif ($cert.NotAfter -lt $(Get-Date))
	{
		$skipForeach = $true
	}
	if ($skipForeach)
	{
		continue
	}
	[string]$certSerial = $cert.SerialNumber
	$certSerialReversed = $Null
	$certSerialReversed = [String]("")
	-1 .. -19 | ForEach-Object {
		$certSerialReversed += $($certSerial[2 * $_]) + $($certSerial[2 * $_ + 1])
	}
	Write-Host @"

-----------------------------------------------------------------
"@ -ForegroundColor DarkCyan
	if ($cert.FriendlyName)
	{
		[string]$certFriendlyName = $cert.FriendlyName
	}
	else
	{
		[string]$certFriendlyName = "<null>"
	}
	if ($cert.SubjectName.Name)
	{
		$certSubjectName = $cert.SubjectName.Name
	}
	else
	{
		$certSubjectName = "<null>"
	}
	$certificateIssuedTo = $cert.SubjectName.Name.Split("=").Split(",") | Select-Object -Index 1
	if ($certificateIssuedTo)
	{
		$certIssuedTo = $certificateIssuedTo
	}
	else
	{
		$certIssuedTo = "<null>"
	}
	$fqdn = [System.Net.Dns]::GetHostEntry([System.Net.Dns]::GetHostName()).HostName
	Write-Output @"
Friendly Name:                 $certFriendlyName
Issued To:                     $certIssuedTo
Subject Name:                  $certSubjectName (FQDN of machine: $fqdn)
Date Issued:                   $($cert.NotBefore.ToString())
Expiration:                    $($cert.NotAfter.ToString())
Serial Number:                 $($cert.SerialNumber.ToLower())
Serial Number (Reversed):      $($certSerialReversed.ToLower())
Certificate Hash (Thumbprint): $($cert.Thumbprint.ToLower())
"@
	if ($UpdateRegistry -imatch "^(Y|Yes)$" -and $ShowAllCertificates -notmatch "^(Y|Yes)$")
	{
		Write-Host "Setting registry key values:   $RegistryPath" -ForegroundColor Green
		Set-ItemProperty -Path $RegistryPath -Name ChannelCertificateHash -Value $cert.Thumbprint.ToLower() | Out-Null
		New-ItemProperty -PropertyType Binary -Path $RegistryPath -Name ChannelCertificateSerialNumber -Value ([byte[]](($certSerialReversed -split '([a-fA-F0-9]{2})' | Where-Object { $_ } | ForEach-Object { [byte]("0x$_") }))) -Force | Out-Null
		Write-Host "Restarting Service:            Microsoft Monitoring Agent (HealthService)" -ForegroundColor Green
		Restart-Service HealthService
	}
	if ($ShowAllCertificates -notmatch "^(Y|Yes)$")
	{
		break
	}
}
Write-Host @"
-----------------------------------------------------------------
"@ -ForegroundColor DarkCyan
