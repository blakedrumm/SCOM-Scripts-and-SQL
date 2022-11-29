<#
	.SYNOPSIS
		System Center Operations Manager - Certificate Checker
	
	.DESCRIPTION
		The steps for configuring certificates in System Center Operations Manager are numerous and one can easily get them confused.
		I see posts to the newsgroups and discussion lists regularly trying to troubleshoot why certificate authentication is not working, perhaps for a workgroup machine or gateway.
		Sometimes it takes 3 or 4 messages back and forth before I or anyone else can diagnose what the problem actually is but once this is finally done we can suggest how to fix the problem.
		
		In an attempt to make this diagnosis stage easier I put together a PowerShell script that automatically checks installed certificates for the needed properties and configuration.
		If you think everything is set up correctly but the machines just won't communicate, try running this script on each computer and it will hopefully point you to the issue.
		I have tried to provide useful knowledge for fixing the problems.
		
		This script was originally designed for stand-alone PowerShell 1.0 - it does not require the OpsMgr PowerShell snapins.
		Technet Article: https://gallery.technet.microsoft.com/scriptcenter/Troubleshooting-OpsMgr-27be19d3
	
	.PARAMETER All
		Check All Certificates in Local Machine Store.
	
	.PARAMETER OutputFile
		Where to Output the File (txt, log, etc) for Script Execution.
	
	.PARAMETER SerialNumber
		Check a specific Certificate serial number in the Local Machine Personal Store. Not reversed.
	
	.PARAMETER Servers
		Each Server you want to Check SCOM Certificates on.
	
	.EXAMPLE
		Check All Certificates on 4 Servers and outputting the results to C:\Temp\Output.txt:
		PS C:\> .\Check-SCOMCertificates.ps1 -Servers ManagementServer1, ManagementServer2.contoso.com, Gateway.contoso.com, Agent1.contoso.com -All -OutputFile C:\Temp\Output.txt
	
	.EXAMPLE
		Check for a specific Certificate serialnumber in the Local Machine Personal Certificate store:
		PS C:\> .\Check-SCOMCertificates.ps1 -SerialNumber 1f00000008c694dac94bcfdc4a000000000008
	
	.EXAMPLE
		Check all certificates on the local machine:
		PS C:\> .\Check-SCOMCertificates.ps1 -All
	
	.NOTES
		Update 09/2022 (Blake Drumm, https://github.com/blakedrumm/ )
		Fixed bug introduced in last update. Certificates are checked correctly now.
	
		Update 09/2022 (Blake Drumm, https://github.com/blakedrumm/ )
		Added ability to gather issuer. Fixed bug in output.

		Update 03/2022 (Blake Drumm, https://github.com/blakedrumm/ )
		Major Update / alot of changes to how this script acts remotely and locally and added remoting abilites that are much superior to previous versions
		
		Update 02/2022 (Blake Drumm, https://github.com/blakedrumm/ )
		Fix some minor bugs and do some restructuring
		
		Update 01/2022 (Blake Drumm, https://github.com/blakedrumm/ )
		The script will now allow an -SerialNumber parameter so you can only gather the certificate you are expecting.
		
		Update 06/2021 (Blake Drumm, https://github.com/v-bldrum/ )
		The Script will now by default only check every Certificate only if you have the -All Switch. Otherwise it will just check the certificate Serial Number (Reversed) that is present in the Registry.
		
		Update 11/2020 (Blake Drumm, https://github.com/v-bldrum/ )
		Shows Subject Name instead of Issuer for each Certificate Checked.
		
		Update 08/2020 (Blake Drumm, https://github.com/v-bldrum/ )
		Fixed formatting in output.
		
		Update 06/2020 (Blake Drumm, https://github.com/v-bldrum/ )
		Added ability to OutputFile script to file.
		
		Update 2017.11.17 (Tyson Paul, https://blogs.msdn.microsoft.com/tysonpaul/ )
		Fixed certificate SerialNumber parsing error.
		
		Update 7/2009
		Fix for workgroup machine subjectname validation
		
		Update 2/2009
		Fixes for subjectname validation
		Typos
		Modification for CA chain validation
		Adds needed check for MachineKeyStore property on the private key
		
		Original Publish Date 1/2009
		(Lincoln Atkinson?, https://blogs.technet.microsoft.com/momteam/author/latkin/ )
#>
[CmdletBinding()]
[OutputType([string])]
param
(
	[Parameter(Mandatory = $false,
			   Position = 1,
			   HelpMessage = 'Check All Certificates in Local Machine Store.')]
	[Switch]$All,
	[Parameter(Mandatory = $false,
			   Position = 2,
			   HelpMessage = 'Where to Output the Text Log for Script.')]
	[String]$OutputFile,
	[Parameter(Mandatory = $false,
			   Position = 3,
			   HelpMessage = 'Check a specific Certificate serial number in the Local Machine Personal Store. Not reversed.')]
	[ValidateScript({ (Get-ChildItem cert:\LocalMachine\my\).SerialNumber })]
	[string]$SerialNumber,
	[Parameter(Mandatory = $false,
			   Position = 4,
			   HelpMessage = 'Each Server you want to Check SCOM Certificates on.')]
	[Array]$Servers
)
begin
{
	#region CheckPermission
	$checkingpermission = "Checking for elevated permissions..."
	$MainScriptOutput = @()
	Write-Host $checkingpermission -ForegroundColor Gray
	$MainScriptOutput += $checkingpermission
	if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator"))
	{
		$nopermission = "Insufficient permissions to run this script. Open the PowerShell console as an administrator and run this script again."
		$MainScriptOutput += $nopermission
		Write-Warning $nopermission
		Start-Sleep 5
		break
	}
	else
	{
		$permissiongranted = " Currently running as administrator - proceeding with script execution..."
		$MainScriptOutput += $permissiongranted
		Write-Host $permissiongranted -ForegroundColor Green
	}
	#endregion CheckPermission
	Function Time-Stamp
	{
		
		$TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
		return $TimeStamp
	}
	function Inner-SCOMCertCheck
	{
		[OutputType([string])]
		param
		(
			[Parameter(Mandatory = $false,
					   Position = 1,
					   HelpMessage = 'Check All Certificates in Local Machine Store.')]
			[Switch]$All,
			[Parameter(Mandatory = $false,
					   Position = 2,
					   HelpMessage = 'Where to Output the Text Log for Script.')]
			[String]$OutputFile,
			[Parameter(Mandatory = $false,
					   Position = 3,
					   HelpMessage = 'Check a specific Certificate serial number in the Local Machine Personal Store. Not reversed.')]
			[string]$SerialNumber,
			[Parameter(Mandatory = $false,
					   Position = 4,
					   HelpMessage = 'Each Server you want to Check SCOM Certificates on.')]
			[Array]$Servers
		)
		
		Function Time-Stamp
		{
			
			$TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
			return $TimeStamp
		}
		$out = @()
		$out += "`n" + @"
$(Time-Stamp) : Starting Script

"@
		# Consider all certificates in the Local Machine "Personal" store
		$certs = [Array] (Get-ChildItem cert:\LocalMachine\my\)
		$text1 = "Running against server: $env:COMPUTERNAME"
		$out += "`n" + $text1
		Write-Host $text1 -ForegroundColor Cyan
		if ($certs -eq $null)
		{
			$text2 = @"
    There are no certificates in the Local Machine `"Personal`" store.
    This is where the client authentication certificate should be imported.
    Check if certificates were mistakenly imported to the Current User
    `"Personal`" store or the `"Operations Manager`" store.
"@
			Write-Host $text2 -ForegroundColor Red
			$out += "`n" + $text2
			break
		}
		$x = 0
		$a = 0
		$alreadyCheckedThis = $false
		if ($All)
		{
			$FoundCount = "Found: $($certs.Count) certificates"
			$out += "`n" + $FoundCount
			Write-Host $FoundCount
			$text3 = "Verifying each certificate."
			$out += "`n" + $text3
			Write-Host $text3
		}
		foreach ($cert in $certs)
		{
			$x++
			$x = $x
			#If the serialnumber argument is present
			if ($SerialNumber)
			{
				if ($SerialNumber -ne $cert.SerialNumber)
				{
					$a++
					$a = $a
					$NotPresentCount = $a
					continue
				}
				$All = $true
			}
			if (!$All)
			{
				$certSerial = $cert.SerialNumber
				$certSerialReversed = [System.String]("")
				-1 .. -19 | ForEach-Object { $certSerialReversed += $certSerial[2 * $_] + $certSerial[2 * $_ + 1] }
				if (! (Test-Path "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Machine Settings"))
				{
					$text36 = "Serial Number is not written to registry"
					$out += "`n" + $text36
					Write-Host $text36 -BackgroundColor Red -ForegroundColor Black
					$text37 = @"
    The certificate serial number is not written to registry.
    Need to run MomCertImport.exe
"@
					$out += "`n" + $text37
					Write-Host $text37
					$pass = $false
					break
				}
				else
				{
					$regKeys = get-itemproperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Machine Settings"
					if ($regKeys.ChannelCertificateSerialNumber -eq $null)
					{
						$text36 = "Serial Number is not written to registry"
						$out += "`n" + $text36
						Write-Host $text36 -BackgroundColor Red -ForegroundColor Black
						$text37 = @"
    The certificate serial number is not written to registry.
    Need to run MomCertImport.exe
"@
						$out += "`n" + $text37
						Write-Host $text37
						$pass = $false
						break
					}
					else
					{
						$regSerial = ""
						$regKeys.ChannelCertificateSerialNumber | ForEach-Object { $regSerial += $_.ToString("X2") }
						if ($regSerial -eq "" -or $null) { $regSerial = "`{Empty`}" }
						if ($regSerial -ne $($certSerialReversed -Join (" ")))
						{
							continue
						}
					}
				}
			}
			$certificateReversed = -1 .. - $($cert.SerialNumber.Length) | ForEach-Object { $cert.SerialNumber[2 * $_] + $cert.SerialNumber[2 * $_ + 1] }
			$text4 = @"
=====================================================================================================================
$(if (!$SerialNumber -and $All) { "($x`/$($certs.Count)) " })Examining Certificate

`tSubject: "$($cert.Subject)" $(if ($cert.FriendlyName) { "`n`n`tFriendly name: $($cert.FriendlyName)" })

`tIssued by: $(($cert.Issuer -split ',' | Where-Object { $_ -match "CN=|DC=" }).Replace("CN=", '').Replace("DC=", '').Trim() -join '.')

`tSerial Number: "$($cert.SerialNumber)"

`tSerial Number Reversed: $($certificateReversed)
=====================================================================================================================
"@
			Write-Host $text4
			$out += "`n" + "`n" + $text4
			
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
					$text5 = "Certificate Subjectname Mismatch"
					$out += "`n" + $text5
					Write-Host $text5 -BackgroundColor Red -ForegroundColor Black
					
					$text6 = @"
    The Subjectname of this certificate does not match the FQDN of this machine.
		Actual: $($cert.SubjectName.Name)
		Expected (case insensitive): CN=$fqdn
"@
					$out += "`n" + $text6
					Write-Host $text6
					$false
				}
				else { $true; $text7 = "Certificate Subjectname is Good"; $out += "`n" + $text7; Write-Host $text7 -BackgroundColor Green -ForegroundColor Black }
			}
			
			# Verify private key
			
			if (!($cert.HasPrivateKey))
			{
				$text8 = "Private Key Missing"
				$out += "`n" + $text8
				Write-Host $text8 -BackgroundColor Red -ForegroundColor Black
				$text9 = @"
    This certificate does not have a private key.
    Verify that proper steps were taken when installing this cert.
"@
				$out += "`n" + $text9
				Write-Host $text9
				$pass = $false
			}
			elseif (!($cert.PrivateKey.CspKeyContainerInfo.MachineKeyStore))
			{
				$text10 = "Private Key not issued to Machine Account"
				$out += "`n" + $text10
				Write-Host $text10 -BackgroundColor Red -ForegroundColor Black
				$text11 = @"
    This certificate's private key is not issued to a machine account.
		One possible cause of this is that the certificate
		was issued to a user account rather than the machine,
		then copy/pasted from the Current User store to the Local
		Machine store.  A full export/import is required to switch
		between these stores.
"@
				$out += "`n" + $text11
				Write-Host $text11
				$pass = $false
			}
			else { $text12 = "Private Key is Good"; $out += "`n" + $text12; Write-Host $text12 -BackgroundColor Green -ForegroundColor Black }
			
			# Check expiration dates
			
			if (($cert.NotBefore -gt [DateTime]::Now) -or ($cert.NotAfter -lt [DateTime]::Now))
			{
				$text13 = "Expiration Out-of-Date"
				$out += "`n" + $text13
				Write-Host $text13 -BackgroundColor Red -ForegroundColor Black
				$text14 = @"
    This certificate is not currently valid.
    It will be valid between $($cert.NotBefore) and $($cert.NotAfter)
"@
				$out += "`n" + $text14
				Write-Host $text14
				$pass = $false
			}
			else
			{
				$text15 = @"
Expiration
    Not Expired: (valid from $($cert.NotBefore) thru $($cert.NotAfter))
"@
				$out += "`n" + $text15
				Write-Host $text15 -BackgroundColor Green -ForegroundColor Black
			}
			
			
			# Enhanced key usage extension
			
			$enhancedKeyUsageExtension = $cert.Extensions | Where-Object { $_.ToString() -match "X509EnhancedKeyUsageExtension" }
			if ($enhancedKeyUsageExtension -eq $null)
			{
				$text16 = "Enhanced Key Usage Extension Missing"
				$out += "`n" + $text16
				Write-Host $text16 -BackgroundColor Red -ForegroundColor Black
				$text17 = "    No enhanced key usage extension found."
				$out += "`n" + $text17
				Write-Host $text17
				$pass = $false
			}
			else
			{
				$usages = $enhancedKeyUsageExtension.EnhancedKeyUsages
				if ($usages -eq $null)
				{
					$text18 = "Enhanced Key Usage Extension Missing"
					$out += "`n" + $text18
					Write-Host $text18 -BackgroundColor Red -ForegroundColor Black
					$text19 = "    No enhanced key usages found."
					$out += "`n" + $text19
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
						$text20 = "Enhanced Key Usage Extension Issue"
						$out += "`n" + $text20
						Write-Host $text20 -BackgroundColor Red -ForegroundColor Black
						$text21 = @"
    Enhanced key usage extension does not meet requirements.
    Required EKUs are 1.3.6.1.5.5.7.3.1 and 1.3.6.1.5.5.7.3.2
    EKUs found on this cert are:
"@
						$out += "`n" + $text21
						Write-Host $text21
						$usages | ForEach-Object{ $text22 = "      $($_.Value)"; $out += "`n" + $text22; Write-Host $text22 }
						$pass = $false
					}
					else
					{
						$text23 = @"
Enhanced Key Usage Extension is Good
"@;
						$out += "`n" + $text23; Write-Host $text23 -BackgroundColor Green -ForegroundColor Black
					}
				}
			}
			
			# KeyUsage extension
			
			$keyUsageExtension = $cert.Extensions | Where-Object { $_.ToString() -match "X509KeyUsageExtension" }
			if ($keyUsageExtension -eq $null)
			{
				$text24 = "Key Usage Extensions Missing"
				$out += "`n" + $text24
				Write-Host $text24 -BackgroundColor Red -ForegroundColor Black
				$text25 = @"
    No key usage extension found.
    A KeyUsage extension matching 0xA0 (Digital Signature, Key Encipherment)
    or better is required.
"@
				$out += "`n" + $text25
				Write-Host $text25
				$pass = $false
			}
			else
			{
				$usages = $keyUsageExtension.KeyUsages
				if ($usages -eq $null)
				{
					$text26 = "Key Usage Extensions Missing"
					$out += "`n" + $text26
					Write-Host $text26 -BackgroundColor Red -ForegroundColor Black
					$text27 = @"
    No key usages found.
    A KeyUsage extension matching 0xA0 (DigitalSignature, KeyEncipherment)
    or better is required.
"@
					$out += "`n" + $text27
					Write-Host $text27
					$pass = $false
				}
				else
				{
					if (($usages.value__ -band 0xA0) -ne 0xA0)
					{
						$text28 = "Key Usage Extensions Issue"
						$out += "`n" + $text28
						Write-Host $text28 -BackgroundColor Red -ForegroundColor Black
						$text29 = @"
    Key usage extension exists but does not meet requirements.
    A KeyUsage extension matching 0xA0 (Digital Signature, Key Encipherment)
    or better is required.
    KeyUsage found on this cert matches:
    $usages"
"@
						$out += "`n" + $text29
						Write-Host $text29
						$pass = $false
					}
					else { $text30 = "Key Usage Extensions are Good"; $out += "`n" + $text30; Write-Host $text30 -BackgroundColor Green -ForegroundColor Black }
				}
			}
			
			# KeySpec
			
			$keySpec = $cert.PrivateKey.CspKeyContainerInfo.KeyNumber
			if ($keySpec -eq $null)
			{
				$text31 = "KeySpec Missing / Not Found"
				$out += "`n" + $text31
				Write-Host $text31 -BackgroundColor Red -ForegroundColor Black
				$text32 = "    Keyspec not found.  A KeySpec of 1 is required"
				$out += "`n" + $text32
				Write-Host $text32
				$pass = $false
			}
			elseif ($keySpec.value__ -ne 1)
			{
				$text33 = "KeySpec Incorrect"
				$out += "`n" + $text33
				Write-Host $text33 -BackgroundColor Red -ForegroundColor Black
				$text34 = @"
    Keyspec exists but does not meet requirements.
    A KeySpec of 1 is required.
    KeySpec for this cert: $($keySpec.value__)
"@
				$out += "`n" + $text34
				Write-Host $text34
				$pass = $false
			}
			else { $text35 = "KeySpec is Good"; $out += "`n" + $text35; Write-Host $text35 -BackgroundColor Green -ForegroundColor Black }
			
			
			# Check that serial is written to proper reg
			
			$certSerial = $cert.SerialNumber
			$certSerialReversed = [System.String]("")
			-1 .. -19 | ForEach-Object { $certSerialReversed += $certSerial[2 * $_] + $certSerial[2 * $_ + 1] }
			
			if (! (Test-Path "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Machine Settings"))
			{
				$text36 = "Serial Number is not written to the registry"
				$out += "`n" + $text36
				Write-Host $text36 -BackgroundColor Red -ForegroundColor Black
				$text37 = @"
    The certificate serial number is not written to registry.
    Need to run MomCertImport.exe
"@
				$out += "`n" + $text37
				Write-Host $text37
				$pass = $false
			}
			else
			{
				$regKeys = get-itemproperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Machine Settings"
				if ($regKeys.ChannelCertificateSerialNumber -eq $null)
				{
					$text38 = "Serial Number is not written to the registry"
					$out += "`n" + $text38
					Write-Host $text38 -BackgroundColor Red -ForegroundColor Black
					$text39 = @"
    The certificate serial number is not written to registry.
    Need to run MomCertImport.exe
"@
					$out += "`n" + $text39
					Write-Host $text39
					$pass = $false
				}
				else
				{
					$regSerial = ""
					$regKeys.ChannelCertificateSerialNumber | ForEach-Object { $regSerial += $_.ToString("X2") }
					if ($regSerial -eq "" -or $null) { $regSerial = "`{Empty`}" }
					if ($regSerial -ne $certSerialReversed)
					{
						$text40 = "Serial Number (mismatch) written to the registry"
						$out += "`n" + $text40
						Write-Host $text40 -BackgroundColor Red -ForegroundColor Black
						$text41 = @"
    The serial number written to the registry does not match this certificate
    Expected registry entry: $certSerialReversed
    Actual registry entry:   $regSerial
"@
						$out += "`n" + $text41
						Write-Host $text41
						$pass = $false
					}
					else { $text42 = "Serial Number is written to the registry"; $out += "`n" + $text42; Write-Host $text42 -BackgroundColor Green -ForegroundColor Black }
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
				$text43 = "Certification Chain Issue"
				$out += "`n" + $text43
				Write-Host $text43 -BackgroundColor Red -ForegroundColor Black
				$text44 = @"
    The following error occurred building a certification chain with this certificate:
    $($chain.ChainStatus[0].StatusInformation)
    This is an error if the certificates on the remote machines are issued
    from this same CA - $($cert.Issuer)
    Please ensure the certificates for the CAs which issued the certificates configured
    on the remote machines are installed to the Local Machine Trusted Root Authorities
    store on this machine. (certlm.msc)
"@
				$out += "`n" + $text44
				Write-Host $text44 -ForegroundColor Yellow
				$pass = $false
			}
			else
			{
				$rootCaCert = $chain.ChainElements | Select-Object -property Certificate -last 1
				$localMachineRootCert = Get-ChildItem cert:\LocalMachine\Root | Where-Object { $_ -eq $rootCaCert.Certificate }
				if ($localMachineRootCert -eq $null)
				{
					$text45 = "Certification Chain Root CA Missing"
					$out += "`n" + $text45
					Write-Host $text45 -BackgroundColor Red -ForegroundColor Black
					$text46 = @"
    This certificate has a valid certification chain installed, but
    a root CA certificate verifying the issuer $($cert.Issuer)
    was not found in the Local Machine Trusted Root Authorities store.
    Make sure the proper root CA certificate is installed there, and not in
    the Current User Trusted Root Authorities store. (certlm.msc)
"@
					$out += "`n" + $text46
					Write-Host $text46 -ForegroundColor Yellow
					$pass = $false
				}
				else
				{
					$text47 = "Certification Chain looks Good"
					$out += "`n" + $text47
					Write-Host $text47 -BackgroundColor Green -ForegroundColor Black
					$text48 = @"
    There is a valid certification chain installed for this cert,
    but the remote machines' certificates could potentially be issued from
    different CAs.  Make sure the proper CA certificates are installed
    for these CAs.
"@
					$out += "`n" + $text48
					Write-Host $text48
				}
				
			}
			
			
			if ($pass)
			{
				$text49 = "`n*** This certificate is properly configured and imported for System Center Operations Manager ***"; $out += "`n" + $text49; Write-Host $text49 -ForegroundColor Green
			}
			else
			{
				$text49 = "`n*** This certificate is NOT properly configured for System Center Operations Manager ***"; $out += "`n" + $text49; Write-Host $text49 -ForegroundColor White -BackgroundColor Red
			}
			$out += "`n" + " " # This is so there is white space between each Cert. Makes it less of a jumbled mess.
		}
		if ($certs.Count -eq $NotPresentCount)
		{
			$text49 = "Unable to locate any certificates on this server that match the criteria specified OR the serial number in the registry does not match any certificates present."; $out += "`n" + $text49; Write-Host $text49 -ForegroundColor Red
		}
		$out += "`n" + @"

$(Time-Stamp) : Script Completed
"@
		Write-Verbose "$out"
		return $out
	}
	$InnerCheckSCOMCertificateFunctionScript = "function Inner-SCOMCertCheck { ${function:Inner-SCOMCertCheck} }"
}
PROCESS
{
	#region Function
	function Check-SCOMCertificate
	{
		[OutputType([string])]
		[CmdletBinding()]
		param
		(
			[Parameter(Mandatory = $false,
					   Position = 1,
					   HelpMessage = 'Check All Certificates in Local Machine Store.')]
			[Switch]$All,
			[Parameter(Mandatory = $false,
					   Position = 2,
					   HelpMessage = 'Where to Output the Text Log for Script.')]
			[String]$OutputFile,
			[Parameter(Mandatory = $false,
					   Position = 3,
					   HelpMessage = 'Check a specific Certificate serial number in the Local Machine Personal Store. Not reversed.')]
			[string]$SerialNumber,
			[Parameter(Mandatory = $false,
					   Position = 4,
					   HelpMessage = 'Each Server you want to Check SCOM Certificates on.')]
			[Array]$Servers
		)
		if ($null -eq $Servers) { $Servers = $env:COMPUTERNAME }
		else
		{
			$Servers = ($Servers.Split(",").Split(" ") -replace (" ", ""))
			$Servers = $Servers | Select-Object -Unique
		}
		foreach ($server in $Servers)
		{
			$startofline = @" 

========================================================
Certificate Checker

"@
			Write-Host '========================================================'
			Write-Host @"
Certificate Checker

"@ -ForegroundColor Black -BackgroundColor Cyan
			$MainScriptOutput += $startofline
			if ($server -ne $env:COMPUTERNAME)
			{
				$MainScriptOutput += Invoke-Command -ComputerName $server -ArgumentList $InnerCheckSCOMCertificateFunctionScript, $All, $SerialNumber -ScriptBlock {
					Param ($script,
						$All,
						$SerialNumber,
						$VerbosePreference)
					. ([ScriptBlock]::Create($script))
					return Inner-SCOMCertCheck -All:$All -SerialNumber $SerialNumber
					
				} -ErrorAction SilentlyContinue
			}
			else
			{
				if ($VerbosePreference.value__ -ne 0)
				{
					$MainScriptOutput += Inner-SCOMCertCheck -Servers $Servers -All:$All -SerialNumber:$SerialNumber -Verbose -ErrorAction SilentlyContinue
				}
				else
				{
					$MainScriptOutput += Inner-SCOMCertCheck -Servers $Servers -All:$All -SerialNumber:$SerialNumber -ErrorAction SilentlyContinue
				}
				
			}
		}
		if ($OutputFile)
		{
			$MainScriptOutput | Out-File $OutputFile -Width 4096
			Start-Process C:\Windows\explorer.exe -ArgumentList "/select, $OutputFile"
		}
		#return $out
		continue
	}
	#endregion Function
	#region DefaultActions
	if ($Servers -or $OutputFile -or $All -or $SerialNumber)
	{
		Check-SCOMCertificate -Servers $Servers -OutputFile $OutputFile -All:$All -SerialNumber:$SerialNumber
	}
	else
	{
		# Modify line 753 if you want to change the default behavior when running this script through Powershell ISE
		#
		# Examples: 
		# Check-SCOMCertificate -SerialNumber 1f00000008c694dac94bcfdc4a000000000008
		# Check-SCOMCertificate -All
		# Check-SCOMCertificate -All -OutputFile C:\Temp\Certs-Output.txt
		# Check-SCOMCertificate -Servers MS01, MS02
		Check-SCOMCertificate
	}
	#endregion DefaultActions
}

# SIG # Begin signature block
# MIInoQYJKoZIhvcNAQcCoIInkjCCJ44CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBeJPpNRK/3UYpC
# ut5KVMOe8Ih4QVlIC3Cp1AAeWGPqBaCCDXYwggX0MIID3KADAgECAhMzAAACy7d1
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGYEwghl9AgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAALLt3U5+wJxQjYAAAAAAsswDQYJYIZIAWUDBAIB
# BQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHvwEhGeBo5av4e5CmhVL/F6
# 4upqs2qwtqGrCU6xC/SfMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQBO3BZUFxNfcbKlyzBVQp+EJ/457td6jDNbi1eNBZD0k0NjBbpgXgME
# XojXEONoBXbByrNgORyDTtnVX5frpz/ob0VoOqFblsmEyn1SYQBAmh0R4dKJvvXO
# eQr/iIBaIv4+L+EczdVrt10GH45RlaxcwuHaAESBc5TiPZNg26tdSkUxvcIz1Rvv
# /557ZQcvAQ34VlDLa+WEICaTjtGHe0Gx0xLFAXms6FzurjKtR8a7hJzP+Ut1pAOp
# bfemhItrfLM19IWxXE4acd+Ik8Tu60Mo3un8iY2/7tonGsk30oNcQaYQwgiTVMq9
# zz5KsAw+E+PVbw8SXC4kDutFcKKbcHDqoYIXCTCCFwUGCisGAQQBgjcDAwExghb1
# MIIW8QYJKoZIhvcNAQcCoIIW4jCCFt4CAQMxDzANBglghkgBZQMEAgEFADCCAVUG
# CyqGSIb3DQEJEAEEoIIBRASCAUAwggE8AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEIKzjKNukuo42bDq1CWYoolLNe3dPMsIZijM3D2P/dgjMAgZjc74n
# UUAYEzIwMjIxMTI5MTgyNTA0Ljk0N1owBIACAfSggdSkgdEwgc4xCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAsTIE1pY3Jvc29mdCBP
# cGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjpG
# NzdGLUUzNTYtNUJBRTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vy
# dmljZaCCEVwwggcQMIIE+KADAgECAhMzAAABqqUxmwvLsggOAAEAAAGqMA0GCSqG
# SIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# JjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4XDTIyMDMw
# MjE4NTEyNloXDTIzMDUxMTE4NTEyNlowgc4xCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1
# ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjpGNzdGLUUzNTYtNUJB
# RTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCAiIwDQYJ
# KoZIhvcNAQEBBQADggIPADCCAgoCggIBAKBP7HK51bWHf+FDSh9O7YyrQtkNMvdH
# zHiazvOdI9POGjyJIYrs1WOMmSCp3o/mvsuPnFSP5c0dCeBuUq6u6J30M81ZaNOP
# /abZrTwYrYN+N5nStrOGdCtRBum76hy7Tr3AZDUArLwvhsGlXhLlDU1wioaxM+BV
# wCNI7LmTaYKqjm58hEgsYtKIHk59LzOnI4aenbPLBP/VYYjI6a4KIcun0EZErAuk
# t5PC/mKUaOphUMGYm0PxfpY9BkG5sPfczFyIfA13LLRS4sGhbUrcM54EvE2FlWBQ
# aJo7frKW7CVjITLEX4E2lxwQG/MuZ+1wDYg9OOErT5h+6zecj67eenwxeUoaOEbK
# tiUxaJUYnyQKxCWTkNdWRXTKSmIxx0tbsP5irWjqXvT6t/zeJKw05NY8hPT56vW2
# 0q0DYK2NteOCDD0UD6ZNAFLV87GOkl0eBqXcToFVdeJwwOTE6aA4RqYoNr2QUPBI
# U6JEiUGBs9c4qC5mBHTY46VaR/odaFDLcxQI4OPkn5al/IPsd8/raDmMfKik66xc
# Nh2qN4yytYM3uiDenX5qeFdx3pdi43pYAFN/S1/3VRNk+/GRVUUYWYBjDZSqxsli
# dE8hsxC7K8qLfmNoaQ2aAsu13h1faTMSZIEVxosz1b9yIeXmtM6NlrjV3etwS7JX
# YwGhHMdVYEL1AgMBAAGjggE2MIIBMjAdBgNVHQ4EFgQUP5oUvFOHLthfd0Wz3hGt
# nQVGpJ4wHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYDVR0fBFgw
# VjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWlj
# cm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwGCCsGAQUF
# BwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3Br
# aW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgx
# KS5jcnQwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcDCDANBgkqhkiG
# 9w0BAQsFAAOCAgEA3wyATZBFEBogrcwHs4zI7qX2y0jbKCI6ZieGAIR96RiMrjZv
# WG39YPA/FL2vhGSCtO7ea3iBlwhhTyJEPexLugT4jB4W0rldOLP5bEc0zwxs9NtT
# FS8Ul2zbJ7jz5WxSnhSHsfaVFUp7S6B2a1bjKmWIo/Svd3W1V3mcIYzhbpLIUVlP
# 3CbTJEE+cC3hX+JggnSYRETyo+mI7Hz/KMWFaRWBUYI4g0BrwiV2lYqKyekjNp6r
# j7b8l6OhbgX/JP0bzNxv6io0Y4iNlIzz/PdIh/E2pj3pXPiQJPRlEkMksRecE8Vn
# FyqhR4fb/F6c5ywY4+mEpshIAg2YUXswFqqbK9Fv+U8YYclYPvhK/wRZs+/5auK4
# FM+QTjywj0C5rmr8MziqmUGgAuwZQYyHRCopnVdlaO/xxSZCfaZR7w7B3OBEl8j+
# Voofs1Kfq9AmmQAWZOjt4DnNk5NnxThPvjQVuOU/y+HTErwqD/wKRCl0AJ3UPTJ8
# PPYp+jbEXkKmoFhU4JGer5eaj22nX19pujNZKqqart4yLjNUOkqWjVk4KHpdYRGc
# JMVXkKkQAiljUn9cHRwNuPz/Tu7YmfgRXWN4HvCcT2m1QADinOZPsO5v5j/bExw0
# WmFrW2CtDEApnClmiAKchFr0xSKE5ET+AyubLapejENr9vt7QXNq6aP1XWcwggdx
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
# Ooo6CGJ/2XBjU02N7oJtpQUQwXEGahC0HVUzWLOhcGbyoYICzzCCAjgCAQEwgfyh
# gdSkgdEwgc4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAn
# BgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQL
# Ex1UaGFsZXMgVFNTIEVTTjpGNzdGLUUzNTYtNUJBRTElMCMGA1UEAxMcTWljcm9z
# b2Z0IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUA4G0m0J4eAllj
# cP/jvOv9/pm/68aggYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAx
# MDANBgkqhkiG9w0BAQUFAAIFAOcwsRowIhgPMjAyMjExMjkyMDI2MDJaGA8yMDIy
# MTEzMDIwMjYwMlowdDA6BgorBgEEAYRZCgQBMSwwKjAKAgUA5zCxGgIBADAHAgEA
# AgIIkjAHAgEAAgISfjAKAgUA5zICmgIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgor
# BgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUA
# A4GBAH20tJ4Ov1h3gsnTiXPD1pL2wcAyeZpNG2AqKv96g3J5dPc/ifO0ZS3XV9wN
# IpPoPSi5fJ/V1uRKOJtcOKLMWJTzcB6azi2Q9p8NGtoC0aA+x71TRfqdeJZRsXQu
# VDSkOxwKuVMOCiBQJSp7ihhGlqNUttoKhHAqe9FcfoFGxnrLMYIEDTCCBAkCAQEw
# gZMwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UE
# AxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGqpTGbC8uyCA4A
# AQAAAaowDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0B
# CRABBDAvBgkqhkiG9w0BCQQxIgQgytWw7vEGBZxyhBvLZmzORtsBu2yE7PFQH1Oh
# Th9OXFwwgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCBWtQJDHFq8EeBz3TXu
# gCqRhSI/JCZbATYEIwTG8bMewDCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwAhMzAAABqqUxmwvLsggOAAEAAAGqMCIEII+QKJ3y+Xq4HwNH4W7P
# IZZ5TfPr307y5i/IrCwCxsgQMA0GCSqGSIb3DQEBCwUABIICACHGdWOWqPldB3ZB
# iGhwL58FypIsXJmSWhRiS9zxEJKw9b5IE8TP3ZOJSDtlUa7ywYv11CyK3dChUkhp
# 1jqfp+UrgQs4ISNjfVJ3RNq8NRyYXek51NT286f4w8OxW4a5MPWwhqfCk263g/g9
# juhsocN2DpOtjiCfnSFefpwJdeLY32tw9tmLpzHsvSjGtcZj/t9A5qRMYaTJQOEI
# cCQ3KOFg0k+ybItcBpEsLnnNuZEjVN/5idFG7pQ2am/cQOx+UzFXwlY80uRUwfCu
# DhUG2PG1XiDQnppJR002254DubaqasCaTSJMiQBmUOqu4FicdPqvuasZgEa1p4Sm
# +9S1CLgKlU062CjpOUpyCek03UZ4SvmW+JcjNP2kzkcdJemYVYFRWeySN68YWapI
# 3C5txOkCG7PoH1lV9LRNXcOquXbRjsX1jrUhwjVV2DFA3H4PQ/P+AB0gAtphGOUw
# UyI19S4Lw3USCApv7fr8S0ssxJQEZ9CBnX5gjunS9mNrJ3+fIy2UOHsJF4g+yt57
# UhucZOoY8jtkgPRzTkRRrKRV+Ihp/Y3gZKG6dnBEH96Jmz8YbDYd1x66mp/Y3opM
# eLa7u6Tl20R88UaNiAnTVvPBDAQiJgXfCcx3b13x5ljiIGve/2c/i440euS2/fVp
# Ozv3k70tcr0Ah2NMzpKmxqLYnIkJ
# SIG # End signature block
