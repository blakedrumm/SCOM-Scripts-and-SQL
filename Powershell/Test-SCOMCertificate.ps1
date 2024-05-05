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
    .PARAMETER Servers
        Each Server you want to Check SCOM Certificates on.
    .PARAMETER SerialNumber
        Check a specific Certificate serial number in the Local Machine Personal Store. Not reversed.
    .PARAMETER All
        Check All Certificates in Local Machine Store.
    .PARAMETER OutputFile
        Where to Output the File (txt, log, etc) for Script Execution.
    .EXAMPLE
        Check All Certificates on 4 Servers and outputting the results to C:\Temp\Output.txt:
        PS C:\> .\Test-SCOMCertificates.ps1 -Servers ManagementServer1, ManagementServer2.contoso.com, Gateway.contoso.com, Agent1.contoso.com -All -OutputFile C:\Temp\Output.txt
    .EXAMPLE
        Check for a specific Certificate serialnumber in the Local Machine Personal Certificate store:
        PS C:\> .\Test-SCOMCertificates.ps1 -SerialNumber 1f00000008c694dac94bcfdc4a000000000008
    .EXAMPLE
        Check all certificates on the local machine:
        PS C:\> .\Test-SCOMCertificates.ps1 -All
    .NOTES
        Update 05/2024 (Blake Drumm, https://blakedrumm.com/)
        	Updated the way the subject name is parsed against the DNS resolved name of the machine.
        Update 03/2024 (Blake Drumm, https://blakedrumm.com/)
        	Changed the name from Start-SCOMCertificateChecker to Test-SCOMCertificate.
        Update 05/2023 (Blake Drumm, https://blakedrumm.com/)
        	Added ability to check certificates missing a common name.
        Update 02/2023 (Blake Drumm, https://github.com/blakedrumm/)
        	Added the ability to check for duplicate subject common names.
        Update 01/2023 (Mike Kallhoff)
        	Added the ability to output the certificate chain information.
        Update 11/2022 (Blake Drumm, https://github.com/blakedrumm/)
        	Script will now let you know if your registry key does not match any certificates in the local machine store.
        Update 09/2022 (Blake Drumm, https://github.com/blakedrumm/)
        	Fixed bug introduced in last update. Certificates are checked correctly now.
        Update 09/2022 (Blake Drumm, https://github.com/blakedrumm/)
        	Added ability to gather issuer. Fixed bug in output.
        Update 03/2022 (Blake Drumm, https://github.com/blakedrumm/)
        	Major Update / alot of changes to how this script acts remotely and locally and added remoting abilites that are much superior to previous versions
        Update 02/2022 (Blake Drumm, https://github.com/blakedrumm/)
        	Fix some minor bugs and do some restructuring
        Update 01/2022 (Blake Drumm, https://github.com/blakedrumm/)
        	The script will now allow an -SerialNumber parameter so you can only gather the certificate you are expecting.
        Update 06/2021 (Blake Drumm, https://github.com/v-bldrum/)
        	The Script will now by default only check every Certificate only if you have the -All Switch. Otherwise it will just check the certificate Serial Number (Reversed) that is present in the Registry.
        Update 11/2020 (Blake Drumm, https://github.com/v-bldrum/)
        	Shows Subject Name instead of Issuer for each Certificate Checked.
        Update 08/2020 (Blake Drumm, https://github.com/v-bldrum/)
        	Fixed formatting in output.
        Update 06/2020 (Blake Drumm, https://github.com/v-bldrum/)
        	Added ability to OutputFile script to file.
        Update 2017.11.17 (Tyson Paul, https://blogs.msdn.microsoft.com/tysonpaul/)
        	Fixed certificate SerialNumber parsing error.
        Update 7/2009 (Lincoln Atkinson?, https://blogs.technet.microsoft.com/momteam/author/latkin/)
        	Fix for workgroup machine subjectname validation
        Update 2/2009 (Lincoln Atkinson?, https://blogs.technet.microsoft.com/momteam/author/latkin/)
        	Fixes for subjectname validation
        	Typos
        	Modification for CA chain validation
        	Adds needed check for MachineKeyStore property on the private key
        Original Publish Date 1/2009 (Lincoln Atkinson?, https://blogs.technet.microsoft.com/momteam/author/latkin/)
#>
[CmdletBinding()]
[OutputType([string])]
param
(
	[Parameter(Mandatory = $false,
			   Position = 1,
			   HelpMessage = 'Each Server you want to Check SCOM Certificates on.')]
	[Array]$Servers,
	[Parameter(Mandatory = $false,
			   Position = 2,
			   HelpMessage = 'Check a specific Certificate serial number in the Local Machine Personal Store. Not reversed.')]
	[ValidateScript({ (Get-ChildItem cert:\LocalMachine\my\).SerialNumber })]
	[string]$SerialNumber,
	[Parameter(Mandatory = $false,
			   Position = 3,
			   HelpMessage = 'Check All Certificates in Local Machine Store.')]
	[Switch]$All,
	[Parameter(Mandatory = $false,
			   Position = 4,
			   HelpMessage = 'Where to Output the Text Log for Script.')]
	[String]$OutputFile
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
	Function Invoke-TimeStamp
	{
		$TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
		return $TimeStamp
	}
	function Invoke-InnerSCOMCertCheck
	{
		[OutputType([string])]
		param
		(
			[Parameter(Mandatory = $false,
					   Position = 1,
					   HelpMessage = 'Each Server you want to Check SCOM Certificates on.')]
			[Array]$Servers,
			[Parameter(Mandatory = $false,
					   Position = 2,
					   HelpMessage = 'Check a specific Certificate serial number in the Local Machine Personal Store. Not reversed.')]
			[ValidateScript({ (Get-ChildItem cert:\LocalMachine\my\).SerialNumber })]
			[string]$SerialNumber,
			[Parameter(Mandatory = $false,
					   Position = 3,
					   HelpMessage = 'Check All Certificates in Local Machine Store.')]
			[Switch]$All,
			[Parameter(Mandatory = $false,
					   Position = 4,
					   HelpMessage = 'Where to Output the Text Log for Script.')]
			[String]$OutputFile
		)
		Function Invoke-TimeStamp
		{
			$TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
			return $TimeStamp
		}
		$out = @()
		$out += "`n" + @"
$(Invoke-TimeStamp) : Starting Script
"@
		# Consider all certificates in the Local Machine "Personal" store
		$certs = [Array] (Get-ChildItem cert:\LocalMachine\my\)
		$text1 = "Running against server: $env:COMPUTERNAME"
		$out += "`n" + $text1
		Write-Host $text1 -ForegroundColor Cyan
		if ($null -eq $certs)
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
					if ($null -eq $regKeys.ChannelCertificateSerialNumber)
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
						if (-NOT ($regSerial)) { $regSerial = "`{Empty`}" }
					}
					if ($($certSerialReversed -Join (" ")) -ne $regSerial)
					{
						$a++
						$a = $a
						$NotPresentCount = $a
						continue
					}
				}
			}
			$certificateReversed = -1 .. - $($cert.SerialNumber.Length) | ForEach-Object { $cert.SerialNumber[2 * $_] + $cert.SerialNumber[2 * $_ + 1] }
			$SN = $cert.SerialNumber
			#Create cert chain object
			$chain = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Chain
			#Get Certificate
			$Certificate = Get-ChildItem Cert:\LocalMachine\My\ -Recurse | where{ $_.SerialNumber -like $SN }
			$Issuer = $Certificate.Issuer
			$Subject = $Certificate.Subject
			#Build chain
			$chain.Build($Certificate)
			# List the chain elements
			# Write-Host $chain.ChainElements.Certificate.IssuerName.Name
			# List the chain elements verbose
			$ChainCerts = ($chain.ChainElements).certificate | select Subject, SerialNumber
			#$ChainCerts
			$chainCertFormatter = New-Object System.Text.StringBuilder
			foreach ($C1 IN $ChainCerts)
			{
				$chainCertFormatter.Append("`t`t") | Out-Null
				$chainCertFormatter.Append($C1.subject) | Out-Null
				$chainCertFormatter.Append(' ') | Out-Null
				$chainCertFormatter.AppendLine("($($C1.serialnumber))") | Out-Null
			}
			$ChainCertsOutput = $chainCertFormatter.ToString()
			#write-host $ChainCertsOutput
			#   ^^ needs to be justified. I suspect creating an object array and then exporting that to a string may 
			#   keep the justification and still allow it to be displayed.
			$text4 = @"
=====================================================================================================================
$(if (!$SerialNumber -and $All) { "($x`/$($certs.Count)) " })Examining Certificate
`tSubject: "$($cert.Subject)" $(if ($cert.FriendlyName) { "`n`n`tFriendly name: $($cert.FriendlyName)" })
`tIssued by: $(($cert.Issuer -split ',' | Where-Object { $_ -match "CN=|DC=" }).Replace("CN=", '').Replace("DC=", '').Trim() -join '.')
`tSerial Number: $($cert.SerialNumber)
`tSerial Number Reversed: $($certificateReversed)
`tChain Certs: 
$($ChainCertsOutput)
=====================================================================================================================
"@
			Write-Host $text4
			$out += "`n" + "`n" + $text4
			$pass = $true
			# Check subjectname
			$fqdn = (Resolve-DnsName $env:COMPUTERNAME -Type A | Select-Object -ExpandProperty Name -Unique) -join " "
			trap [DirectoryServices.ActiveDirectory.ActiveDirectoryObjectNotFoundException]
			{
				# Not part of a domain
				continue;
			}
			$subjectProblem = $false
			$fqdnRegexPattern = "CN=" + ($fqdn.Replace(".", "\.")).Replace(" ", "|CN=")
			try { $CheckForDuplicateSubjectCNs = ((($cert).Subject).Split(",") | %{ $_.Trim() } | Where { $_ -match "CN=" }).Trim("CN=") | % { $_.Split(".") | Select-Object -First 1 } | Group-Object | Where-Object { $_.Count -gt 1 } | Select -ExpandProperty Name }
			catch { $CheckForDuplicateSubjectCNs = $null }
			
			if (-NOT $cert.Subject)
			{
				$text5 = "Certificate Subject Common Name Missing"
				$out += "`n" + $text5
				Write-Host $text5 -BackgroundColor Red -ForegroundColor Black
				$text6 = @"
    The Subject Common Name of this certificate is not present.
        Actual: ""
        Expected (case insensitive): CN=$fqdn
"@
				$out += "`n" + $text6
				Write-Host $text6
				$pass = $false
				$subjectProblem = $true
			}
			elseif ((($cert.SubjectName.Name).ToUpper()) -notmatch ($fqdnRegexPattern.ToUpper()))
			{
				$text5 = "Certificate Subject Common Name Mismatch"
				$out += "`n" + $text5
				Write-Host $text5 -BackgroundColor Red -ForegroundColor Black
				$text6 = @"
    The Subjectname of this certificate does not match the FQDN of this machine.
        Actual: $($cert.SubjectName.Name)
        Expected (case insensitive): CN=$fqdn
"@
				$out += "`n" + $text6
				Write-Host $text6
				$pass = $false
				$subjectProblem = $true
			}
			elseif ($CheckForDuplicateSubjectCNs)
			{
				$CertDuplicateCN = "Certificate Subjectname Duplicate Common Names"
				$out += "`n" + $CertDuplicateCN
				Write-Host $CertDuplicateCN -BackgroundColor Red -ForegroundColor Black
				$checkCNtext = @"
    Found duplicate Subject Common Names (CN=)
    Operations Manager will only use one of these common names.
    Do not include the FQDN AND Netbios name in the Subjectname.
"@
				$out += "`n" + $checkCNtext
				Write-Host $checkCNtext -BackgroundColor Red -ForegroundColor Black
				$pass = $false
				$subjectProblem = $true
			}
			if (-NOT $subjectProblem)
			{
				$pass = $true;
				$text7 = "Certificate Subjectname is Good"; $out += "`n" + $text7; Write-Host $text7 -BackgroundColor Green -ForegroundColor Black
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
			if ($null -eq $enhancedKeyUsageExtension)
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
				if ($null -eq $usages)
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
			if ($null -eq $keyUsageExtension)
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
				if ($null -eq $usages)
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
			if ($null -eq $keySpec)
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
				if ($null -eq $regKeys.ChannelCertificateSerialNumber)
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
					if (-NOT ($regSerial)) { $regSerial = "`{Empty`}" }
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
                #>			$chain = new-object Security.Cryptography.X509Certificates.X509Chain
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
				if ($null -eq $localMachineRootCert)
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
			$text49 = "    Unable to locate any certificates on this server that match the criteria specified OR the serial number in the registry does not match any certificates present."; $out += "`n" + $text49; Write-Host $text49 -ForegroundColor Red
			$text50 = "    Data in registry: $certSerialReversed"; $out += "`n" + $text50; Write-Host $text50 -ForegroundColor Gray
		}
		$out += "`n" + @"
$(Invoke-TimeStamp) : Script Completed
"@ + "`n"
		Write-Verbose "$out"
		return $out
	}
	$InnerCheckSCOMCertificateFunctionScript = "function Invoke-InnerSCOMCertCheck { ${function:Invoke-InnerSCOMCertCheck} }"
}
PROCESS
{
	#region Function
	function Test-SCOMCertificate
	{
		[OutputType([string])]
		[CmdletBinding()]
		param
		(
			[Parameter(Mandatory = $false,
					   Position = 1,
					   HelpMessage = 'Each Server you want to Check SCOM Certificates on.')]
			[Array]$Servers,
			[Parameter(Mandatory = $false,
					   Position = 2,
					   HelpMessage = 'Check a specific Certificate serial number in the Local Machine Personal Store. Not reversed.')]
			[ValidateScript({ (Get-ChildItem cert:\LocalMachine\my\).SerialNumber })]
			[string]$SerialNumber,
			[Parameter(Mandatory = $false,
					   Position = 3,
					   HelpMessage = 'Check All Certificates in Local Machine Store.')]
			[Switch]$All,
			[Parameter(Mandatory = $false,
					   Position = 4,
					   HelpMessage = 'Where to Output the Text Log for Script.')]
			[String]$OutputFile
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
			Write-Host ' '
			$MainScriptOutput += $startofline
			if ($server -ne $env:COMPUTERNAME)
			{
				$MainScriptOutput += Invoke-Command -ComputerName $server -ArgumentList $InnerCheckSCOMCertificateFunctionScript, $All, $SerialNumber -ScriptBlock {
					Param ($script,
						$All,
						$SerialNumber,
						$VerbosePreference)
					. ([ScriptBlock]::Create($script))
					return Invoke-InnerSCOMCertCheck -All:$All -SerialNumber $SerialNumber
				} -ErrorAction SilentlyContinue
			}
			else
			{
				if ($VerbosePreference.value__ -ne 0)
				{
					$MainScriptOutput += Invoke-InnerSCOMCertCheck -Servers $Servers -All:$All -SerialNumber:$SerialNumber -Verbose -ErrorAction SilentlyContinue
				}
				else
				{
					$MainScriptOutput += Invoke-InnerSCOMCertCheck -Servers $Servers -All:$All -SerialNumber:$SerialNumber -ErrorAction SilentlyContinue
				}
			}
		}
		if ($OutputFile)
		{
			$MainScriptOutput.Replace('Certificate CheckerTrue', 'Certificate Checker') | Out-File $OutputFile -Width 4096
			Start-Process C:\Windows\explorer.exe -ArgumentList "/select, $OutputFile"
		}
		#return $out
		continue
	}
	#endregion Function
 
	#region DefaultActions
	if ($Servers -or $OutputFile -or $All -or $SerialNumber)
	{
		Test-SCOMCertificate -Servers $Servers -OutputFile $OutputFile -All:$All -SerialNumber:$SerialNumber
	}
	else
	{
		# Modify line 772 if you want to change the default behavior when running this script through Powershell ISE
		#
		# Examples: 
		# Test-SCOMCertificate -SerialNumber 1f00000008c694dac94bcfdc4a000000000008
		# Test-SCOMCertificate -All
		# Test-SCOMCertificate -All -OutputFile C:\Temp\Certs-Output.txt
		# Test-SCOMCertificate -Servers MS01, MS02
		Test-SCOMCertificate
	}
	#endregion DefaultActions
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
