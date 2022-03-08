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
		sleep 5
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
		$certs = [Array] (dir cert:\LocalMachine\my\)
		$text1 = "Running against server: $env:COMPUTERNAME"
		$out += "`n" + $text1
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
			$out += "`n" + $text2
			break
		}
		$x = 0
		$a = 0
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
				-1 .. -19 | % { $certSerialReversed += $certSerial[2 * $_] + $certSerial[2 * $_ + 1] }
				
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
						$regKeys.ChannelCertificateSerialNumber | % { $regSerial += $_.ToString("X2") }
						if ($regSerial -eq "" -or $null) { $regSerial = "`{Empty`}" }
						if ($regSerial -ne $certSerialReversed)
						{
							$i = $i
							$i++
							$NotPresentCount = $i
							$text36 = "Serial Number written to the registry does not match"
							$out += "`n" + $text36
							Write-Verbose $text36
							$text37 = @"
    The certificate serial number is does not match what is written to registry.
    Need to run MomCertImport.exe
"@
							Write-Verbose $text37
							$out += "`n" + $text37
							continue
                                <# Do Nothing.#>
						}
					}
				}
			}
			$certificateReversed = -1 .. - $($cert.SerialNumber.Length) | % { $cert.SerialNumber[2 * $_] + $cert.SerialNumber[2 * $_ + 1] }
			$text4 = @"
=====================================================================================================================

=====================================================================================================================
$(if (!$SerialNumber -and $All) { "($x`/$($certs.Count)) " })Examining Certificate`n`nSubject: "$($cert.Subject)"

$(if ($cert.FriendlyName) { "Friendly name: $($cert.FriendlyName)`n`n" })Serial Number: "$($cert.SerialNumber)"

Serial Number Reversed: $($certificateReversed)
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
			
			$enhancedKeyUsageExtension = $cert.Extensions | ? { $_.ToString() -match "X509EnhancedKeyUsageExtension" }
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
						$usages | %{ $text22 = "      $($_.Value)"; $out += "`n" + $text22; Write-Host $text22 }
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
			
			$keyUsageExtension = $cert.Extensions | ? { $_.ToString() -match "X509KeyUsageExtension" }
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
			-1 .. -19 | % { $certSerialReversed += $certSerial[2 * $_] + $certSerial[2 * $_ + 1] }
			
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
			}
			else
			{
				$regKeys = get-itemproperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Machine Settings"
				if ($regKeys.ChannelCertificateSerialNumber -eq $null)
				{
					$text38 = "Serial Number is not written to registry"
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
					$regKeys.ChannelCertificateSerialNumber | % { $regSerial += $_.ToString("X2") }
					if ($regSerial -eq "" -or $null) { $regSerial = "`{Empty`}" }
					if ($regSerial -ne $certSerialReversed)
					{
						$text40 = "Serial Number (mismatch) written to registry"
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
					else { $text42 = "The serial number is written the to registry"; $out += "`n" + $text42; Write-Host $text42 -BackgroundColor Green -ForegroundColor Black }
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
				$out += "`n" + $text44
				Write-Host $text44
			}
			else
			{
				$rootCaCert = $chain.ChainElements | select -property Certificate -last 1
				$localMachineRootCert = dir cert:\LocalMachine\Root | ? { $_ -eq $rootCaCert.Certificate }
				if ($localMachineRootCert -eq $null)
				{
					$text45 = "Certification Chain Root CA Missing"
					$out += "`n" + $text45
					Write-Host $text45 -BackgroundColor Yellow -ForegroundColor Black
					$text46 = @"
    This certificate has a valid certification chain installed, but
    a root CA certificate verifying the issuer $($cert.Issuer)
    was not found in the Local Machine Trusted Root Authorities store.
    Make sure the proper root CA certificate is installed there, and not in
    the Current User Trusted Root Authorities store.
"@
					$out += "`n" + $text46
					Write-Host $text46
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
			
			
			if ($pass) { $text49 = "***This certificate is properly configured and imported for System Center Operations Manager.***"; $out += "`n" + $text49; Write-Host $text49 -ForegroundColor Green }
			$out += "`n" + " " # This is so there is white space between each Cert. Makes it less of a jumbled mess.
		}
		if ($certs.Count -eq $NotPresentCount)
		{
			$text49 = "Unable to locate any certificates on this server that match the criteria specified OR the serial number in the registry does not match any certificates present."; $out += "`n" + $text49; Write-Host $text49 -ForegroundColor Red
		}
		$out += "`n" + @"

$(Time-Stamp) : Script Completed
"@
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
			$Servers = $Servers | select -Unique
		}
		foreach ($server in $Servers)
		{
			$startofline = @" 

========================================================
Certificate Checker

"@
			Write-Host $startofline
			$MainScriptOutput += $startofline
			if ($server -ne $env:COMPUTERNAME)
			{
				$MainScriptOutput += Invoke-Command -ComputerName $server -ArgumentList $InnerCheckSCOMCertificateFunctionScript, $All -ScriptBlock {
					Param ($script,
						$All)
					. ([ScriptBlock]::Create($script))
					return Inner-SCOMCertCheck -All:$All
				} -ErrorAction SilentlyContinue
			}
			else
			{
				$MainScriptOutput += Inner-SCOMCertCheck -Servers $Servers -All:$All -SerialNumber:$SerialNumber -ErrorAction SilentlyContinue
			}
		}
		if ($OutputFile)
		{
			$MainScriptOutput | Out-File $OutputFile -Width 4096
			start C:\Windows\explorer.exe -ArgumentList "/select, $OutputFile"
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
		#Modify line 730 if you want to change the default behavior when running this script through Powershell ISE
		# Example: Check-SCOMCertificate -SerialNumber 1f00000008c694dac94bcfdc4a000000000008
		# Example: Check-SCOMCertificate -All
		# Example: Check-SCOMCertificate -All -OutputFile C:\Temp\Certs-Output.txt
		Check-SCOMCertificate
	}
	#endregion DefaultActions
}
END
{
	Write-Host "Script Completed!"
}
