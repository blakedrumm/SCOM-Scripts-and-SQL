<#
    .SYNOPSIS
        Check TLS Settings for SCOM
    .DESCRIPTION
        Gathers TLS settings from the registry.
    .PARAMETER Servers
        The servers you would like to run this script to check TLS settings for Operations Manager.
    .EXAMPLE
        Local Machine:
        PS C:\> .\Get-TLSRegistryKeys.ps1
        Remote Machine
        PS C:\> .\Get-TLSRegistryKeys.ps1 -Servers MS01-2019.contoso.com, MS02-2019.contoso.com
    .NOTES
        Original Author: Mike Kallhoff
        Author: Blake Drumm (blakedrumm@microsoft.com)
        Website: https://blakedrumm.com/
        Modified: April 18th, 2024
        Hosted here: https://github.com/blakedrumm/SCOM-Scripts-and-SQL/blob/master/Powershell/Get-TLSRegistryKeys.ps1
#>
[CmdletBinding()]
Param
(
	[string[]]$Servers
)

Function Get-TLSRegistryKeys
{
	[CmdletBinding()]
	Param
	(
		[string[]]$Servers
	)
	function Write-Console
	{
		param
		(
			[string]$Text,
			$ForegroundColor,
			[switch]$NoNewLine
		)
		
		if ([Environment]::UserInteractive)
		{
			if ($ForegroundColor)
			{
				Write-Host $Text -ForegroundColor $ForegroundColor -NoNewLine:$NoNewLine
			}
			else
			{
				Write-Host $Text -NoNewLine:$NoNewLine
			}
		}
		else
		{
			Write-Output $Text
		}
	}
	
	if (!$Servers)
	{
		$Servers = $env:COMPUTERNAME
	}
	$Servers = $Servers | Sort-Object
	Write-Console "  Accessing Registry on:`n" -NoNewline -ForegroundColor Gray
	$scriptOut = $null
	function Inner-TLSRegKeysFunction
	{
		[CmdletBinding()]
		param ()
		function Write-Console
		{
			param
			(
				[string]$Text,
				$ForegroundColor,
				[switch]$NoNewLine
			)
			if ($ForegroundColor)
			{
				Write-Host $Text -ForegroundColor $ForegroundColor -NoNewLine:$NoNewLine
			}
			else
			{
				Write-Host $Text -NoNewLine:$NoNewLine
			}
		}
		$finalData = @()
		$ProtocolList = "TLS 1.0", "TLS 1.1", "TLS 1.2", "TLS 1.3"
		$ProtocolSubKeyList = "Client", "Server"
		$DisabledByDefault = "DisabledByDefault"
		$Enabled = "Enabled"
		$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\"
		Write-Output "Computer Name`n-------------`n$env:COMPUTERNAME`n"
		Write-Output "Path`n----`n$registryPath"
		foreach ($Protocol in $ProtocolList)
		{
			foreach ($key in $ProtocolSubKeyList)
			{
				Write-Console "-" -NoNewline -ForegroundColor Green
				#Write-Console "Checking for $protocol\$key"
				$currentRegPath = $registryPath + $Protocol + "\" + $key
				$IsDisabledByDefault = @()
				$IsEnabled = @()
				$localresults = @()
				if (!(Test-Path $currentRegPath))
				{
					$IsDisabledByDefault = "DoesntExist"
					$IsEnabled = "DoesntExist"
				}
				else
				{
					$IsDisabledByDefault = (Get-ItemProperty -Path $currentRegPath -Name $DisabledByDefault -ErrorAction 0).DisabledByDefault
					if ($IsDisabledByDefault -eq 4294967295)
					{
						$IsDisabledByDefault = "0xffffffff"
					}
					if ($null -eq $IsDisabledByDefault)
					{
						$IsDisabledByDefault = "DoesntExist"
					}
					$IsEnabled = (Get-ItemProperty -Path $currentRegPath -Name $Enabled -ErrorAction 0).Enabled
					if ($IsEnabled -eq 4294967295)
					{
						$isEnabled = "0xffffffff"
					}
					if ($null -eq $IsEnabled)
					{
						$IsEnabled = "DoesntExist"
					}
				}
				$localresults = "PipeLineKickStart" | Select-Object @{ n = 'Protocol'; e = { $Protocol } },
																	@{ n = 'Type'; e = { $key } },
																	@{
					n = 'DisabledByDefault'; e = {
						$output = ($IsDisabledByDefault).ToString()
						if ($output -eq '0')
						{
							$output.Replace('0', 'False').Replace('1', 'True')
						}
						elseif ($output -eq '$0xffffffff')
						{
							"$output (True)"
						}
						else
						{
							$output
						}
						
					}
				},
																	@{
					n = 'IsEnabled'; e = {
						$output = ($IsEnabled).ToString()
						if ($output -eq '0')
						{
							$output.Replace('0', 'False').Replace('1', 'True')
						}
						elseif ($output -eq '$0xffffffff')
						{
							"$output (True)"
						}
						else
						{
							$output
						}
						
					}
				}
				$finalData += $localresults
			}
		}
		$results += $finaldata | Select-Object -Property * -ExcludeProperty PSComputerName, RunspaceId, PSShowComputerName | Format-Table * -AutoSize
		$CrypKey1 = "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319"
		$CrypKey2 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319"
		$Strong = "SchUseStrongCrypto"
		$Crypt1 = (Get-ItemProperty -Path $CrypKey1 -Name $Strong -ErrorAction 0).SchUseStrongCrypto
		If ($crypt1 -eq 1)
		{
			$Crypt1 = $true
		}
		else
		{
			$Crypt1 = $False
		}
		$crypt2 = (Get-ItemProperty -Path $CrypKey2 -Name $Strong -ErrorAction 0).SchUseStrongCrypto
		if ($crypt2 -eq 1)
		{
			$Crypt2 = $true
		}
		else
		{
			$Crypt2 = $False
		}
		$DefaultTLSVersions = (Get-ItemProperty -Path $CrypKey1 -Name $Strong -ErrorAction 0).SystemDefaultTlsVersions
		If ($DefaultTLSVersions -eq 1)
		{
			$DefaultTLSVersions = $true
		}
		else
		{
			$DefaultTLSVersions = $False
		}
		$DefaultTLSVersions64 = (Get-ItemProperty -Path $CrypKey2 -Name $Strong -ErrorAction 0).SystemDefaultTlsVersions
		if ($DefaultTLSVersions64 -eq 1)
		{
			$DefaultTLSVersions64 = $true
		}
		else
		{
			$DefaultTLSVersions64 = $False
		}
		##  ODBC : https://www.microsoft.com/en-us/download/details.aspx?id=50420
		##  OLEDB : https://docs.microsoft.com/en-us/sql/connect/oledb/download-oledb-driver-for-sql-server?view=sql-server-ver15
		[string[]]$data = (Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -like "*sql*" }).name
		$odbcOutput = $data | Where-Object { $_ -like "Microsoft ODBC Driver *" } # Need to validate version
		$odbc = @()
		foreach ($driver in $odbcOutput)
		{
			Write-Console '-' -NoNewline -ForegroundColor Green
			if ($driver -match "11|13|17|18")
			{
				Write-Verbose "FOUND $driver"
				$odbc += "$driver (Good)"
			}
			elseif ($driver)
			{
				Write-Verbose "FOUND $driver"
				$odbc += "$driver"
			}
			else
			{
				$odbc = "Not Found."
			}
		}
		$odbc = $odbc -split "`n" | Out-String -Width 2048
		$oledb = $data | Where-Object { $_ -like "Microsoft OLE DB Driver*" }
		if ($oledb)
		{
			Write-Verbose "Found: $oledb"
			$OLEDB_Output = @()
			foreach ($software in $oledb)
			{
				if ($software -eq 'Microsoft OLE DB Driver 19 for SQL Server')
				{
					$OLEDB_Output += "$software - $((Get-ItemProperty HKLM:\SOFTWARE\Microsoft\MSOLEDBSQL19).InstalledVersion) (Good)"
				}
				elseif ($software -eq 'Microsoft OLE DB Driver for SQL Server')
				{
					$OLEDB_Output += "$software - $((Get-ItemProperty HKLM:\SOFTWARE\Microsoft\MSOLEDBSQL).InstalledVersion) (Good)"
				}
				else
				{
					$OLEDB_Output += "$software - $((Get-ItemProperty HKLM:\SOFTWARE\Microsoft\MSOLEDBSQL*).InstalledVersion) (Good)"
				}
			}
		}
		else
		{
			$OLEDB = "Not Found."
		}
		foreach ($Protocol in $ProtocolList)
		{
			Write-Console '-' -NoNewline -ForegroundColor Green
			foreach ($key in $ProtocolSubKeyList)
			{
				#Write-Console "Checking for $protocol\$key"
				$currentRegPath = $registryPath + $Protocol + "\" + $key
				$IsDisabledByDefault = @()
				$IsEnabled = @()
				$localresults = @()
				if (!(Test-Path $currentRegPath))
				{
					$IsDisabledByDefault = "Not Present"
					$IsEnabled = "Not Present"
				}
				else
				{
					$IsDisabledByDefault = (Get-ItemProperty -Path $currentRegPath -Name $DisabledByDefault -ErrorAction 0).DisabledByDefault
					if ($IsDisabledByDefault -eq 4294967295)
					{
						$IsDisabledByDefault = "0xffffffff"
					}
					if ($null -eq $IsDisabledByDefault)
					{
						$IsDisabledByDefault = "DoesntExist"
					}
					$IsEnabled = (Get-ItemProperty -Path $currentRegPath -Name $Enabled -ErrorAction 0).Enabled
					if ($IsEnabled -eq 4294967295)
					{
						$isEnabled = "0xffffffff"
					}
					if ($null -eq $IsEnabled)
					{
						$IsEnabled = "DoesntExist"
					}
				}
				$localresults = "PipeLineKickStart" | Select-Object @{ n = 'Protocol'; e = { $Protocol } },
																	@{ n = 'Type'; e = { $key } },
																	@{ n = 'DisabledByDefault'; e = { ($IsDisabledByDefault).ToString().Replace('0', 'False').Replace('1', 'True') } },
																	@{ n = 'IsEnabled'; e = { ($IsEnabled).ToString().Replace('0', 'False').Replace('1', 'True') } }
				$finalData += $localresults
			}
		}
		### Check if SQL Client is installed 
		$RegPath = "HKLM:SOFTWARE\Microsoft\SQLNCLI11"
		IF (Test-Path $RegPath)
		{
			[string]$SQLClient11VersionString = (Get-ItemProperty $RegPath)."InstalledVersion"
			[version]$SQLClient11Version = [version]$SQLClient11VersionString
		}
		[version]$MinSQLClient11Version = [version]"11.4.7001.0"
		Write-Console '-' -NoNewline -ForegroundColor Green
		$SQLClientProgramVersion = $data | Where-Object { $_ -like "Microsoft SQL Server 2012 Native Client" } # Need to validate version
		IF ($SQLClient11Version -ge $MinSQLClient11Version)
		{
			Write-Verbose "SQL Client - is installed and version: ($SQLClient11VersionString) and greater or equal to the minimum version required: (11.4.7001.0)"
			$SQLClient = "$SQLClientProgramVersion $SQLClient11Version (Good)"
		}
		ELSEIF ($SQLClient11VersionString)
		{
			Write-Verbose "SQL Client - is installed and version: ($SQLClient11VersionString) but below the minimum version of (11.4.7001.0)."
			$SQLClient = "$SQLClientProgramVersion $SQLClient11VersionString (Below minimum)"
		}
		ELSE
		{
			Write-Verbose "    SQL Client - is NOT installed."
			$SQLClient = "Not Found."
		}
		###################################################
		# Test .NET Framework version on ALL servers
		# Get version from registry
		$NetVersion = @()
		$RegPath = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\"
		$ReleaseRegValues = (Get-ItemProperty $RegPath)
		foreach ($ReleaseRegValue in $ReleaseRegValues)
		{
            <#
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
				"461814" { ".NET Framework 4.7.2" }
				"461808" { ".NET Framework 4.7.2" }
				"461814" { ".NET Framework 4.7.2" }
				"528040" { ".NET Framework 4.8" }
				"528372" { ".NET Framework 4.8" }
				"528049" { ".NET Framework 4.8" }
				"528449" { ".NET Framework 4.8" }
				default { "Unknown .NET version: $ReleaseRegValue" }
			}
            #>
			Write-Console '-' -NoNewline -ForegroundColor Green
			# Check if version is 4.6 or higher
			IF ($ReleaseRegValue.Release -ge 393295)
			{
				Write-Verbose ".NET version is 4.6 or later (Detected: $($ReleaseRegValue.Version)) (Good)"
				$NetVersion += ".NET Framework $($ReleaseRegValue.Version) (Good)"
			}
			ELSE
			{
				Write-Verbose ".NET version is NOT 4.6 or later (Detected: $ReleaseRegValue.Version) (Bad)"
				$NetVersion += ".NET Framework $($ReleaseRegValue.Version) (Does not match required version, .NET 4.6 ATLEAST is required)"
			}
		}
		$SChannelLogging = Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\SecurityProviders\SCHANNEL' -Name EventLogging | Select-Object EventLogging -ExpandProperty EventLogging
		$SChannelSwitch = switch ($SChannelLogging)
		{
			1 { '0x0001 - Log error messages. (Default)' }
			2 { '0x0002 - Log warnings. (Modified)' }
			3 { '0x0003 - Log warnings and error messages. (Modified)' }
			4 { '0x0004 - Log informational and success events. (Modified)' }
			5 { '0x0005 - Log informational, success events and error messages. (Modified)' }
			6 { '0x0006 - Log informational, success events and warnings. (Modified)' }
			7 { '0x0007 - Log informational, success events, warnings, and error messages (all log levels). (Modified)' }
			0 { '0x0000 - Do not log. (Modified)' }
			default { "$SChannelLogging - Unknown Log Level Possibly Misconfigured. (Modified)" }
		}
		try
		{
			Write-Console '-' -NoNewline -ForegroundColor Green
			$odbcODBCDataSources = Get-ItemProperty 'HKLM:\SOFTWARE\ODBC\ODBC.INI\ODBC Data Sources' -ErrorAction Stop | Select-Object OpsMgrAC -ExpandProperty OpsMgrAC -ErrorAction Stop
		}
		catch { $odbcODBCDataSources = 'Not Found.' }
		try
		{
			$odbcOpsMgrAC = Get-ItemProperty 'HKLM:\SOFTWARE\ODBC\ODBC.INI\OpsMgrAC' -ErrorAction Stop | Select-Object Driver -ExpandProperty Driver -ErrorAction Stop
		}
		catch { $odbcOpsMgrAC = 'Not Found.' }
		try
		{
			$SSLCiphers = ((Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002').Functions).Split(",") | Sort-Object | Out-String
		}
		catch { $SSLCiphers = 'Not Found' }
		try
		{
			$FIPS = Get-ItemProperty "HKLM:\System\CurrentControlSet\Control\LSA\FIPSAlgorithmPolicy" | Select-Object Enabled, PSPath
		}
		catch
		{
			$FIPS = 'PipelineKickstart' | Select-Object @{ n = 'Enabled'; e = { 'Not Found.' } }, @{ n = 'PSPath'; e = { 'HKLM:\System\CurrentControlSet\Control\LSA\FIPSAlgorithmPolicy' } }
		}
		$additional = ('PipeLineKickStart' | Select-Object @{ n = 'SchUseStrongCrypto'; e = { $Crypt1 } },
														   @{ n = 'SchUseStrongCrypto_WOW6432Node'; e = { $Crypt2 } },
														   @{ n = 'FIPS Enabled'; e = { ($FIPS.Enabled).ToString().Replace("0", "False").Replace("1", "True") } },
														   @{ n = 'DefaultTLSVersions'; e = { $DefaultTLSVersions } },
														   @{ n = 'DefaultTLSVersions_WOW6432Node'; e = { $DefaultTLSVersions64 } },
														   @{ n = 'OLEDB'; e = { $OLEDB_Output -split "`n" | Out-String -Width 2048 } },
														   @{ n = 'ODBC'; e = { $odbc } },
														   @{ n = 'ODBC (ODBC Data Sources\OpsMgrAC)'; e = { $odbcODBCDataSources } },
														   @{ n = 'ODBC (OpsMgrAC\Driver)'; e = { $odbcOpsMgrAC } },
														   @{ n = 'SQLClient'; e = { $SQLClient } },
														   @{ n = '.NetFramework'; e = { $NetVersion -split "`n" | Out-String -Width 2048 } },
														   @{ n = 'SChannel Logging'; e = { $SChannelSwitch } },
														   @{ n = 'SSL Cipher Suites'; e = { $SSLCiphers } }
		)
		$results += $additional | Select-Object -Property * -ExcludeProperty PSComputerName, RunspaceId, PSShowComputerName
		$results += "====================================================="
		return $results
	}
	foreach ($server in $servers)
	{
		Write-Console "     $server" -NoNewline -ForegroundColor Cyan
		if ($server -notcontains $env:COMPUTERNAME)
		{
			$InnerTLSRegKeysFunctionScript = "function Inner-TLSRegKeysFunction { ${function:Inner-TLSRegKeysFunction} }"
			$scriptOut += (Invoke-Command -ComputerName $server -ArgumentList $InnerTLSRegKeysFunctionScript, $VerbosePreference -ScriptBlock {
					Param ($script,
						$VerbosePreference)
					. ([ScriptBlock]::Create($script))
					function Write-Console
					{
						param
						(
							[string]$Text,
							$ForegroundColor,
							[switch]$NoNewLine
						)
						if ($ForegroundColor)
						{
							Write-Host $Text -ForegroundColor $ForegroundColor -NoNewLine:$NoNewLine
						}
						else
						{
							Write-Host $Text -NoNewLine:$NoNewLine
						}
					}
					Write-Console "-" -NoNewLine -ForegroundColor Green
					if ($VerbosePreference -eq 'Continue')
					{
						return Inner-TLSRegKeysFunction -Verbose
					}
					else
					{
						return Inner-TLSRegKeysFunction
					}
				} -HideComputerName | Out-String) -replace "RunspaceId.*", ""
			Write-Console "> Completed!`n" -NoNewline -ForegroundColor Green
		}
		else
		{
			Write-Console "-" -NoNewLine -ForegroundColor Green
			if ($VerbosePreference -eq 'Continue')
			{
				$scriptOut += Inner-TLSRegKeysFunction -Verbose
			}
			else
			{
				$scriptOut += Inner-TLSRegKeysFunction
			}
			Write-Console "> Completed!`n" -NoNewline -ForegroundColor Green
		}
	}
	$scriptOut | Out-String -Width 4096
}
if ($Servers)
{
	Get-TLSRegistryKeys -Servers $Servers
}
else
{
	Get-TLSRegistryKeys
}
