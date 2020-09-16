<#
	.SYNOPSIS
		OMCertCheck.ps1
	
	.DESCRIPTION
		The steps for configuring certificates in System Center Operations Manager are numerous and one can easily get them confused.
		I see posts to the newsgroups and discussion lists regularly trying to troubleshoot why certificate authentication is not working, perhaps for a workgroup machine or gateway.
		Sometimes it takes 3 or 4 messages back and forth before I or anyone else can diagnose what the problem actually is but once this is finally done we can suggest how to fix the problem.

		In an attempt to make this diagnosis stage easier I put together a PowerShell script that automatically checks installed certificates for the needed properties and configuration. 
		If you think everything is set up correctly but the machines just won't communicate, try running this script on each computer and it will hopefully point you to the issue.
		I have tried to provide useful knowledge for fixing the problems.

		This script is for stand-alone PowerShell 1.0 - it does not require the OpsMgr PowerShell snapins.
		Technet Article: https://gallery.technet.microsoft.com/scriptcenter/Troubleshooting-OpsMgr-27be19d3
	
	.EXAMPLE
				PS C:\> .\OMCertCheck.ps1 -Servers Agent1 Agent2
	
	.NOTES
	Original Publish Date 1/2009
	    (Lincoln Atkinson?, https://blogs.technet.microsoft.com/momteam/author/latkin/ )

	 Update 08/2020 (Blake Drumm, https://github.com/v-bldrum/ )
	    Fixed formatting in output.
	 Update 06/2020 (Blake Drumm, https://github.com/v-bldrum/ )
	    Added ability to output script to file.
	
	 Update 2017.11.17 (Tyson Paul, https://blogs.msdn.microsoft.com/tysonpaul/ )
	    Fixed certificate SerialNumber parsing error. 
	
	 Update 2/2009
	    Fixes for subjectname validation
	    Typos
	    Modification for CA chain validation
	    Adds needed check for MachineKeyStore property on the private key
	
	 Update 7/2009
	    Fix for workgroup machine subjectname validation
#>
[OutputType([string])]
[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false,
				Position = 2)]
	[String]$Output = "C:\Windows\temp\SCOM-CertChecker-Output.txt",
	[Parameter(Position = 1)]
	[Array]$Servers
)

$checkingpermission = "Checking for elevated permissions..."
$scriptout += $checkingpermission
Write-Host $checkingpermission -ForegroundColor Gray
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator"))
{
	$nopermission = "Insufficient permissions to run this script. Open the PowerShell console as an administrator and run this script again."
	$scriptout += $nopermission
	Write-Warning $nopermission
	sleep 5
	break
}
else
{
	$permissiongranted = " Currently running as administrator - proceeding with script execution..."
	$out += $permissiongranted
	Write-Host $permissiongranted -ForegroundColor Green
}
# START FUNCTION
function SCOM-CertCheck
{
    [OutputType([string])]
    [CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $false,
				   Position = 1)]
		[String]$Output = "C:\Windows\temp\SCOM-CertChecker-Output.txt",
		[Parameter(Position = 2)]
		[Array]$Servers
	)
    if($null -eq $Servers){$Servers = $env:COMPUTERNAME}
    else{
    Write-Host $Servers
    $Servers = ($Servers.Split(",").Split(" ") -replace (" ", ""))
    pause
	$Servers = $Servers | select -Unique
    }
	[string[]]$out = @()
	foreach ($server in $Servers)
	{
		Write-Output " "
		Write-Output "Certificate Checker"
		Invoke-Command -ComputerName $server {
            Function Time-Stamp
            {
		
	            $TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
	            return $TimeStamp
            }
			# Consider all certificates in the Local Machine "Personal" store
			$certs = [Array] (dir cert:\LocalMachine\my\)
			$out = [Array] @()
			$text1 += "Checking that there are certificates in the Local Machine Personal store for $env:COMPUTERNAME......"
			$time = Time-Stamp
			$out += @"
$time : Starting Script
 
"@
			$out += $text1
			Write-Host $text1
			if ($certs -eq $null)
			{
				$text2 = @"
    There are no certificates in the Local Machine `"Personal`" store.
    This is where the client authentication certificate should be imported.
    Check if certificates were mistakenly imported to the Current User
    `"Personal`" store or the `"Operations Manager`" store.
"@
				Write-Host $text2 -ForegroundColor Red
				$out += $text2
				exit
			}
			
			$text3 = "Verifying each cert..."
			$out += $text3
			Write-Host $text3
			foreach ($cert in $certs)
			{
				$text4 = @"

Examining Certificate - Subject: $($cert.Issuer -replace "CN=", $null) - Serial Number $($cert.SerialNumber)
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
"@
				Write-Host $text4
				$out += $text4
				
				$pass = $true
				
				# Check subjectname
				
				$pass = &{
					$fqdn = $env:ComputerName
					$fqdn += "." + [DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().Name
					trap [DirectoryServices.ActiveDirectory.ActiveDirectoryObjectNotFoundException]
					{
						# Not part of a domain
						continue;
					}
					
					$fqdnRegexPattern = "CN=" + $fqdn.Replace(".", "\.") + '(,.*)?$'
					
					if (!($cert.SubjectName.Name -match $fqdnRegexPattern))
					{
						$text5 = "Certificate Subjectname"
						$out += $text5
						Write-Host $text5 -BackgroundColor Red -ForegroundColor Black
						
						$text6 = @"
    The Subjectname of this certificate does not match the FQDN of this machine.
    Actual: $($cert.SubjectName.Name)
    Expected (case insensitive): CN=$fqdn
"@
						$out += $text6
						Write-Host $text6
						$false
					}
					else { $true; $text7 = "Certificate Subjectname"; $out += $text7; Write-Host $text7 -BackgroundColor Green -ForegroundColor Black }
				}
				
				# Verify private key
				
				if (!($cert.HasPrivateKey))
				{
					$text8 = "Private Key"
					$out += $text8
					Write-Host $text8 -BackgroundColor Red -ForegroundColor Black
					$text9 = @"
    This certificate does not have a private key.
    Verify that proper steps were taken when installing this cert.
"@
					$out += $text9
					Write-Host $text9
					$pass = $false
				}
				elseif (!($cert.PrivateKey.CspKeyContainerInfo.MachineKeyStore))
				{
					$text10 = "Private Key"
					$out += $text10
					Write-Host $text10 -BackgroundColor Red -ForegroundColor Black
					$text11 = @"
	This certificate's private key is not issued to a machine account.
	One possible cause of this is that the certificate
	was issued to a user account rather than the machine,
	then copy/pasted from the Current User store to the Local
	Machine store.  A full export/import is required to switch
	between these stores.
"@
					$out += $text11
					Write-Host $text11
					$pass = $false
				}
				else { $text12 = "Private Key"; $out += $text12; Write-Host $text12 -BackgroundColor Green -ForegroundColor Black }
				
				# Check expiration dates
				
				if (($cert.NotBefore -gt [DateTime]::Now) -or ($cert.NotAfter -lt [DateTime]::Now))
				{
					$text13 = "Expiration"
					$out += $text13
					Write-Host $text13 -BackgroundColor Red -ForegroundColor Black
					$text14 = @"
    This certificate is not currently valid.
    It will be valid between $($cert.NotBefore) and $($cert.NotAfter)
"@
					$out += $text14
					Write-Host $text14
					$pass = $false
				}
				else
				{
					$text15 = @"
Expiration
    Not Expired :: (valid from $($cert.NotBefore) thru $($cert.NotAfter))
"@
					$out += $text15
					Write-Host $text15 -BackgroundColor Green -ForegroundColor Black
				}
				
				
				# Enhanced key usage extension
				
				$enhancedKeyUsageExtension = $cert.Extensions | ? { $_.ToString() -match "X509EnhancedKeyUsageExtension" }
				if ($enhancedKeyUsageExtension -eq $null)
				{
					$text16 = "Enhanced Key Usage Extension"
					$out += $text16
					Write-Host $text16 -BackgroundColor Red -ForegroundColor Black
					$text17 = "No enhanced key usage extension found."
					$out += $text17
					Write-Host $text17
					$pass = $false
				}
				else
				{
					$usages = $enhancedKeyUsageExtension.EnhancedKeyUsages
					if ($usages -eq $null)
					{
						$text18 = "Enhanced Key Usage Extension"
						$out += $text18
						Write-Host $text18 -BackgroundColor Red -ForegroundColor Black
						$text19 = "    No enhanced key usages found."
						$out += $text19
						Write-Host $text19
						$pass = $false
					}
					else
					{
						$srvAuth = $cliAuth = $false
						foreach ($usage in $usages)
						{
							if ($usage.Value -eq "1.3.6.1.5.5.7.3.1") { $srvAuth = $true }
							if ($usage.Value -eq "1.3.6.1.5.5.7.3.2") { $cliAuth = $true }
						}
						if ((!$srvAuth) -or (!$cliAuth))
						{
							$text20 = "Enhanced Key Usage Extension"
							$out += $text20
							Write-Host $text20 -BackgroundColor Red -ForegroundColor Black
							$text21 = @"
    Enhanced key usage extension does not meet requirements.
    Required EKUs are 1.3.6.1.5.5.7.3.1 and 1.3.6.1.5.5.7.3.2
    EKUs found on this cert are:
"@
							
							$usages | %{ $text22 = "$($_.Value)"; $out += $text22; Write-Host $text22 }
							$pass = $false
						}
						else
						{
							$text23 = @"
Enhanced Key Usage Extension
    Meets Requirements
"@;
							$out += $text23; Write-Host $text23 -BackgroundColor Green -ForegroundColor Black
						}
					}
				}
				
				# KeyUsage extension
				
				$keyUsageExtension = $cert.Extensions | ? { $_.ToString() -match "X509KeyUsageExtension" }
				if ($keyUsageExtension -eq $null)
				{
					$text24 = "Key Usage Extensions"
					$out += $text24
					Write-Host $text24 -BackgroundColor Red -ForegroundColor Black
					$text25 = @"
    No key usage extension found.
    A KeyUsage extension matching 0xA0 (Digital Signature, Key Encipherment)
    or better is required.
"@
					$out += $text25
					Write-Host $text25
					$pass = $false
				}
				else
				{
					$usages = $keyUsageExtension.KeyUsages
					if ($usages -eq $null)
					{
						$text26 = "Key Usage Extensions"
						$out += $text26
						Write-Host $text26 -BackgroundColor Red -ForegroundColor Black
						$text27 = @"
    No key usages found.
    A KeyUsage extension matching 0xA0 (DigitalSignature, KeyEncipherment)
    or better is required.
"@
						$out += $text27
						Write-Host $text27
						$pass = $false
					}
					else
					{
						if (($usages.value__ -band 0xA0) -ne 0xA0)
						{
							$text28 = "Key Usage Extensions"
							$out += $text28
							Write-Host $text28 -BackgroundColor Red -ForegroundColor Black
							$text29 = @"
    Key usage extension exists but does not meet requirements.
    A KeyUsage extension matching 0xA0 (Digital Signature, Key Encipherment)
    or better is required.
    KeyUsage found on this cert matches:
    $usages"
"@
							$out += $text29
							Write-Host $text29
							$pass = $false
						}
						else { $text30 = "Key Usage Extensions"; $out += $text30; Write-Host $text30 -BackgroundColor Green -ForegroundColor Black }
					}
				}
				
				# KeySpec
				
				$keySpec = $cert.PrivateKey.CspKeyContainerInfo.KeyNumber
				if ($keySpec -eq $null)
				{
					$text31 = "KeySpec"
					$out += $text31
					Write-Host $text31 -BackgroundColor Red -ForegroundColor Black
					$text32 = "    Keyspec not found.  A KeySpec of 1 is required"
					$out += $text32
					Write-Host $text32
					$pass = $false
				}
				elseif ($keySpec.value__ -ne 1)
				{
					$text33 = "KeySpec"
					$out += $text33
					Write-Host $text33 -BackgroundColor Red -ForegroundColor Black
					$text34 = @"
    Keyspec exists but does not meet requirements.
    A KeySpec of 1 is required.
    KeySpec for this cert: $($keySpec.value__)
"@
					$out += $text34
					Write-Host $text34
					$pass = $false
				}
				else { $text35 = "KeySpec"; $out += $text35; Write-Host $text35 -BackgroundColor Green -ForegroundColor Black }
				
				
				# Check that serial is written to proper reg
				
				$certSerial = $cert.SerialNumber
				$certSerialReversed = [System.String]("")
				-1 .. -19 | % { $certSerialReversed += $certSerial[2 * $_] + $certSerial[2 * $_ + 1] }
				
				if (! (Test-Path "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Machine Settings"))
				{
					$text36 = "Serial Number written to registry"
					$out += $text36
					Write-Host $text36 -BackgroundColor Red -ForegroundColor Black
					$text37 = @"
    The certificate serial number is not written to registry.
    Need to run MomCertImport.exe
"@
					$out += $text37
					Write-Host $text37
					$pass = $false
				}
				else
				{
					$regKeys = get-itemproperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Machine Settings"
					if ($regKeys.ChannelCertificateSerialNumber -eq $null)
					{
						$text38 = "Serial Number written to registry"
						$out += $text38
						Write-Host $text38 -BackgroundColor Red -ForegroundColor Black
						$text39 = @"
    The certificate serial number is not written to registry.
    Need to run MomCertImport.exe
"@
						$out += $text39
						Write-Host $text39
						$pass = $false
					}
					else
					{
						$regSerial = ""
						$regKeys.ChannelCertificateSerialNumber | % { $regSerial += $_.ToString("X2") }
						if ($regSerial -eq "" -or $null) { $regSerial = "`{Empty`}" }
						if ($regSerial -ne $certSerialReversed)
						{
							$text40 = "Serial Number written to registry"
							$out += $text40
							Write-Host $text40 -BackgroundColor Red -ForegroundColor Black
							$text41 = @"
    The serial number written to the registry does not match this certificate
    Expected registry entry: $certSerialReversed
    Actual registry entry:   $regSerial
"@
							$out += $text41
							Write-Host $text41
							$pass = $false
						}
						else { $text42 = "Serial Number written to registry"; $out += $text42; Write-Host $text42 -BackgroundColor Green -ForegroundColor Black }
					}
				}
				
<#
	Check that the cert's issuing CA is trusted (This is not technically required
	as it is the remote machine cert's CA that must be trusted.  Most users leverage
	the same CA for all machines, though, so it's worth checking
#>
				$chain = new-object Security.Cryptography.X509Certificates.X509Chain
				$chain.ChainPolicy.RevocationMode = 0
				if ($chain.Build($cert) -eq $false)
				{
					$text43 = "Certification Chain"
					$out += $text43
					Write-Host $text43 -BackgroundColor Yellow -ForegroundColor Black
					$text44 = @"
    The following error occurred building a certification chain with this certificate:
    $($chain.ChainStatus[0].StatusInformation)
    This is an error if the certificates on the remote machines are issued
    from this same CA - $($cert.Issuer)
    Please ensure the certificates for the CAs which issued the certificates configured
    on the remote machines is installed to the Local Machine Trusted Root Authorities
    store on this machine.
"@
					$out += $text44
					Write-Host $text44
				}
				else
				{
					$rootCaCert = $chain.ChainElements | select -property Certificate -last 1
					$localMachineRootCert = dir cert:\LocalMachine\Root | ? { $_ -eq $rootCaCert.Certificate }
					if ($localMachineRootCert -eq $null)
					{
						$text45 = "Certification Chain"
						$out += $text45
						Write-Host $text45 -BackgroundColor Yellow -ForegroundColor Black
						$text46 = @"
    This certificate has a valid certification chain installed, but
    a root CA certificate verifying the issuer $($cert.Issuer)
    was not found in the Local Machine Trusted Root Authorities store.
    Make sure the proper root CA certificate is installed there, and not in
    the Current User Trusted Root Authorities store.
"@
						$out += $text46
						Write-Host $text46
					}
					else
					{
						$text47 = "Certification Chain"
						$out += $text47
						Write-Host $text47 -BackgroundColor Green -ForegroundColor Black
						$text48 = @"
    There is a valid certification chain installed for this cert,
    but the remote machines' certificates could potentially be issued from
    different CAs.  Make sure the proper CA certificates are installed
    for these CAs.
"@
						$out += $text48
						Write-Host $text48
					}
					
				}
				
				
				if ($pass) { $text49 = "***This certificate is properly configured and imported for System Center Operations Manager.***"; $out += $text49; Write-Host $text49 -ForegroundColor Green }
			}
			if ($Output)
			{
				$time = Time-Stamp
				$out += @"

$time : Script Completed
"@
            $out | Out-File $Output
			}
			start C:\Windows\explorer.exe -ArgumentList "/select, $Output"
			#return $out
            exit 0
		}
	}
}
if($null -eq $Servers){ SCOM-CertCheck }else{ SCOM-CertCheck -Servers $Servers }

		
# SIG # Begin signature block
# MIIRKwYJKoZIhvcNAQcCoIIRHDCCERgCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA8zLMfFvYZZvfY
# o9sm71sqJ58sQZektSQ75vNwS+DBfaCCDB4wggM3MIICI6ADAgECAhBid7E8Kyy6
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
# MQwGCisGAQQBgjcCAQQwLwYJKoZIhvcNAQkEMSIEIDpL+JNiEED7Hy6+nr3Y73uZ
# 4UlWhy5pfqt2ZhPB8ayCMA0GCSqGSIb3DQEBAQUABIIBAAmqKkBGbV45eKBnexS8
# 1/eorvxrqGpKGxf8dEOHdWImjAMmxUqh0Xz2VruffgxBBV0c2zJfghOU6tsTk0fM
# j6nPAfm7TdhoFxVQoM20kDAmCj5frk08etYu1W6hYLxn7vQeQ3D3qB+N05N/GAUu
# kEUn/K/BNcyi/LNliudamACsv5XeYaOEUCzFwxt/+HGTt2/1TL6spQW4SQp1557W
# RlPLrw6hWv2yaQq/SYiecccfrUxenN6NsF4jBYNvNfg63QTbiWd6AGZtC4VqH1af
# xqmSEhP2qN94nEhK+vuXGJC06wfYF+oswESYmX4073bkWkFgmfhgaNPfD07ZKToH
# AHShggK5MIICtQYJKoZIhvcNAQkGMYICpjCCAqICAQEwazBbMQswCQYDVQQGEwJC
# RTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTExMC8GA1UEAxMoR2xvYmFsU2ln
# biBUaW1lc3RhbXBpbmcgQ0EgLSBTSEEyNTYgLSBHMgIMJFS4fx4UU603+qF4MA0G
# CWCGSAFlAwQCAQUAoIIBDDAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqG
# SIb3DQEJBTEPFw0yMDA3MTYwNjE4NTdaMC8GCSqGSIb3DQEJBDEiBCDGeuMIBf4p
# R8Mue9iyw6rJ0iABVT+yA+v4WHkHYCQb1zCBoAYLKoZIhvcNAQkQAgwxgZAwgY0w
# gYowgYcEFD7HZtXU1HLiGx8hQ1IcMbeQ2UtoMG8wX6RdMFsxCzAJBgNVBAYTAkJF
# MRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMTEwLwYDVQQDEyhHbG9iYWxTaWdu
# IFRpbWVzdGFtcGluZyBDQSAtIFNIQTI1NiAtIEcyAgwkVLh/HhRTrTf6oXgwDQYJ
# KoZIhvcNAQEBBQAEggEA05/d+OWM6olGN1Qp1+f9grZLpxzQaVL3LsrMwLiZW3rX
# yqRdOsC23WSs00g8YzazobOxfLi2y/teDFOtaMwmqBM07N4c7cSaZg0YAHWeNmyr
# d63jykKUo4keqXRNwQ84drZXncjNNzeemUrWSn7IEb6bIr85KCBaTm4Ca7p+bfdQ
# A6y5yW9MaWE0Jmcp3eHvGbx2ZaLwYq6tiGY2gBGb7TMKFBurFyAmIo31zwFQxKv/
# iU/enr67uh7Ki8iEW2MP7EZsbq3u8jTsY7sflfwQvGRE2rZpHreGefAu4ZJrOX1M
# D9ABuPRWKalZz+oebX+EXqUUaJI0qUVsPrOJfFuIZg==
# SIG # End signature block
