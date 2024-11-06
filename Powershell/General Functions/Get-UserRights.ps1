<#
    .SYNOPSIS
        Retrieves local user account rights from the local or remote machine's security policy.

    .DESCRIPTION
        This script gathers the local security policy user rights assignments from the local machine or specified remote machines. It allows you to output the results to the console, a file (CSV or Text), or pass the results through the pipeline for further processing.

    .PARAMETER ComputerName
        Specifies a comma-separated list of servers to run this script against. To run locally, omit this parameter. This parameter accepts values from the pipeline.

    .PARAMETER UserName
        Specifies the usernames to filter the results. Use this parameter to retrieve user rights assignments for specific users. Provide the username in the format: domain\Username. If omitted, all user rights assignments will be retrieved.

    .PARAMETER FileOutputPath
        Specifies the location where the output file will be stored. Use this parameter in combination with -FileOutputType to define the output format.

    .PARAMETER FileOutputType
        Specifies the type of file to output. Valid options are 'CSV' or 'Text'. This parameter should be used with -FileOutputPath.

    .PARAMETER PassThru
        Indicates that the script should output the results as objects to the pipeline, allowing for further manipulation or filtering.

    .EXAMPLE
        Get local user account rights and output to the console:

            PS C:\> .\Get-UserRights.ps1

    .EXAMPLE
        Get user account rights from a remote server:

            PS C:\> .\Get-UserRights.ps1 -ComputerName SQL.contoso.com

    .EXAMPLE
        Get user account rights from the local machine and multiple remote servers:

            PS C:\> .\Get-UserRights.ps1 -ComputerName "$env:COMPUTERNAME", "SQL.contoso.com"

    .EXAMPLE
        Get user account rights for specific users on a remote server:

            PS C:\> .\Get-UserRights.ps1 -ComputerName SQL.contoso.com -UserName "CONTOSO\User1", "CONTOSO\User2"

    .EXAMPLE
        Output results to a CSV file in 'C:\Temp':

            PS C:\> .\Get-UserRights.ps1 -FileOutputPath C:\Temp -FileOutputType CSV

    .EXAMPLE
        Output results to a text file in 'C:\Temp':

            PS C:\> .\Get-UserRights.ps1 -FileOutputPath C:\Temp -FileOutputType Text

    .EXAMPLE
        Pass through objects and filter for a specific Privilege name:

            PS C:\> .\Get-UserRights.ps1 -ComputerName SQL.contoso.com -PassThru | Where-Object { $_.PrivilegeName -eq "Deny log on locally" }

    .NOTES
        Author: Blake Drumm (blakedrumm@microsoft.com)
        First Created on: June 10th, 2021
        Last Modified on: October 7th, 2024

        GitHub Repository:
        https://github.com/blakedrumm/SCOM-Scripts-and-SQL

        Exact Location:
        https://github.com/blakedrumm/SCOM-Scripts-and-SQL/blob/master/Powershell/General%20Functions/Get-UserRights.ps1
		
		------------------------------------------------------------------------------
		
		MIT License
		Copyright (c) Microsoft
		
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
		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
		SOFTWARE.
		
	.LINK
	    https://blakedrumm.com/blog/set-and-check-user-rights-assignment/
#>

[CmdletBinding()]
param
(
	[Parameter(ValueFromPipeline = $true,
			   Position = 0,
			   HelpMessage = '(Server1, Server2) Comma-separated list of servers you want to run this script against. To run locally, run without this parameter. This argument accepts values from the pipeline.')]
	[Alias('Computers', 'Servers')]
	[array]$ComputerName,
	[Parameter(Position = 1,
			   HelpMessage = 'Specifies the usernames to filter the results.')]
	[Alias('User', 'Principal')]
	[array]$UserName,
	[Parameter(Position = 2,
			   HelpMessage = '(e.g., C:\Temp) Location to store the output file. Set the type with FileOutputType.')]
	[Alias('Path', 'OutputDirectory')]
	[string]$FileOutputPath,
	[Parameter(Position = 3,
			   HelpMessage = '(CSV or Text) Sets the type of file you would like to output. Combine with the FileOutputPath parameter.')]
	[ValidateSet('CSV', 'Text', 'None')]
	[Alias('Type', 'OutputFileType')]
	[string]$FileOutputType = "None",
	[Parameter(Position = 4,
			   HelpMessage = 'Outputs the result as an object that you can manipulate or access.')]
	[switch]$PassThru
)

BEGIN
{
	#region Initialization
	if (!$PassThru)
	{
		Write-Host @"
===================================================================
==========================  Start of Script =======================
===================================================================
"@
	}
	$checkingpermission = "Checking for elevated permissions..."
	$scriptout += $checkingpermission
	if (!$PassThru)
	{
		Write-Host $checkingpermission
	}
	if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
	{
		$currentPath = $myinvocation.mycommand.definition
		$nopermission = "Insufficient permissions to run this script. Attempting to open the PowerShell script ($currentPath) as administrator."
		$scriptout += $nopermission
		Write-Warning $nopermission
		# We are not running "as Administrator" - so relaunch as administrator
		# ($MyInvocation.Line -split '\.ps1[\s\''\"]\s*', 2)[-1]
		Start-Process powershell.exe "-File", ('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
		break
	}
	else
	{
		$permissiongranted = " Currently running as administrator - proceeding with script execution..."
		if (!$PassThru)
		{
			Write-Host $permissiongranted
		}
	}
	Function Time-Stamp
	{
		$TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
		return "$TimeStamp - "
	}
	function Get-SecurityPolicy
	{
		param
		(
			$UserName
		)
		#requires -version 2
		# Fail script if we can't find SecEdit.exe
		$SecEdit = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::System)) "SecEdit.exe"
		if (-not (Test-Path $SecEdit))
		{
			Write-Error "File not found - '$SecEdit'" -Category ObjectNotFound
			return
		}
		Write-Verbose "Found Executable: $SecEdit"
		
		# LookupPrivilegeDisplayName Win32 API doesn't resolve logon right display
		# names, so use this hashtable
		$UserLogonRights = @{
			"SeAssignPrimaryTokenPrivilege"			    = "Replace a process level token"
			"SeAuditPrivilege"						    = "Generate security audits"
			"SeBackupPrivilege"						    = "Back up files and directories"
			"SeBatchLogonRight"						    = "Log on as a batch job"
			"SeChangeNotifyPrivilege"				    = "Bypass traverse checking"
			"SeCreateGlobalPrivilege"				    = "Create global objects"
			"SeCreatePagefilePrivilege"				    = "Create a pagefile"
			"SeCreatePermanentPrivilege"			    = "Create permanent shared objects"
			"SeCreateSymbolicLinkPrivilege"			    = "Create symbolic links"
			"SeCreateTokenPrivilege"				    = "Create a token object"
			"SeDebugPrivilege"						    = "Debug programs"
			"SeDenyBatchLogonRight"					    = "Deny log on as a batch job"
			"SeDenyInteractiveLogonRight"			    = "Deny log on locally"
			"SeDenyNetworkLogonRight"				    = "Deny access to this computer from the network"
			"SeDenyRemoteInteractiveLogonRight"		    = "Deny log on through Remote Desktop Services"
			"SeDenyServiceLogonRight"				    = "Deny log on as a service"
			"SeEnableDelegationPrivilege"			    = "Enable computer and user accounts to be trusted for delegation"
			"SeImpersonatePrivilege"				    = "Impersonate a client after authentication"
			"SeIncreaseBasePriorityPrivilege"		    = "Increase scheduling priority"
			"SeIncreaseQuotaPrivilege"				    = "Adjust memory quotas for a process"
			"SeIncreaseWorkingSetPrivilege"			    = "Increase a process working set"
			"SeInteractiveLogonRight"				    = "Allow log on locally"
			"SeLoadDriverPrivilege"					    = "Load and unload device drivers"
			"SeLockMemoryPrivilege"					    = "Lock pages in memory"
			"SeMachineAccountPrivilege"				    = "Add workstations to domain"
			"SeManageVolumePrivilege"				    = "Perform volume maintenance tasks"
			"SeNetworkLogonRight"					    = "Access this computer from the network"
			"SeProfileSingleProcessPrivilege"		    = "Profile single process"
			"SeRelabelPrivilege"					    = "Modify an object label"
			"SeRemoteInteractiveLogonRight"			    = "Allow log on through Remote Desktop Services"
			"SeRemoteShutdownPrivilege"				    = "Force shutdown from a remote system"
			"SeRestorePrivilege"					    = "Restore files and directories"
			"SeSecurityPrivilege"					    = "Manage auditing and security log"
			"SeServiceLogonRight"					    = "Log on as a service"
			"SeShutdownPrivilege"					    = "Shut down the system"
			"SeSyncAgentPrivilege"					    = "Synchronize directory service data"
			"SeSystemEnvironmentPrivilege"			    = "Modify firmware environment values"
			"SeSystemProfilePrivilege"				    = "Profile system performance"
			"SeSystemtimePrivilege"					    = "Change the system time"
			"SeTakeOwnershipPrivilege"				    = "Take ownership of files or other objects"
			"SeTcbPrivilege"						    = "Act as part of the operating system"
			"SeTimeZonePrivilege"					    = "Change the time zone"
			"SeTrustedCredManAccessPrivilege"		    = "Access Credential Manager as a trusted caller"
			"SeUndockPrivilege"						    = "Remove computer from docking station"
			"SeDelegateSessionUserImpersonatePrivilege" = "Obtain an impersonation token for another user in the same session"
			"SeSynchronizePrivilege"				    = "Required to use the object wait functions"
			"SePrivilegeNotHeld"					    = "Privilege not held"
		}
		try
		{
			# Attempt to reference the 'Win32.AdvApi32' type to check if it already exists.
			# Casting to [void] suppresses any output or errors if the type doesn't exist.
			[void][Win32.AdvApi32]
		}
		catch
		{
			# If the type does not exist, an exception is thrown and caught here.
			# We proceed to define the type using the Add-Type cmdlet.
			
			# Use Add-Type to define a new .NET type in C# code.
			# The -TypeDefinition parameter accepts a string containing the C# code.
			Add-Type -TypeDefinition @"
    // Include necessary namespaces for the C# code.
    using System;
    using System.Runtime.InteropServices;
    using System.Text;

    // Define a namespace called 'Win32' to contain our class.
    namespace Win32
    {
        // Define a public class 'AdvApi32' to hold our P/Invoke method.
        public class AdvApi32
        {
            // Use the DllImport attribute to import the 'LookupPrivilegeDisplayName' function from 'advapi32.dll'.
            // SetLastError = true allows us to retrieve error information if the call fails.
            [DllImport("advapi32.dll", SetLastError = true)]
            public static extern bool LookupPrivilegeDisplayName(
              string systemName,         // The name of the target system (null for local).
              string privilegeName,      // The name of the privilege to look up.
              StringBuilder displayName, // A StringBuilder to receive the privilege's display name.
              ref uint cbDisplayName,    // The size of the displayName buffer; updated with the actual size used.
              out uint languageId        // Receives the language identifier for the returned display name.
            );
        }
    }
"@ -PassThru | Out-Null
			# -PassThru outputs the generated type, but we pipe it to Out-Null to suppress output.
		}
		
		
		# Use LookupPrivilegeDisplayName Win32 API to get display name of privilege
		# (except for user logon rights)
		function Get-PrivilegeDisplayName
		{
			param (
				[String]$name # The privilege name to look up
			)
			
			# Create a StringBuilder object to receive the display name of the privilege
			$displayNameSB = New-Object System.Text.StringBuilder 1024
			$languageId = 0
			
			# Call the LookupPrivilegeDisplayName API function to get the display name
			$ok = [Win32.AdvApi32]::LookupPrivilegeDisplayName($null, $name, $displayNameSB, [Ref]$displayNameSB.Capacity, [Ref]$languageId)
			
			# If the API call is successful, return the display name as a string
			if ($ok)
			{
				return $displayNameSB.ToString()
			}
			# If the API call fails, check the hashtable for the privilege name
			else
			{
				# Use an if statement to check if the key exists in the hashtable
				if ($UserLogonRights[$name])
				{
					return $UserLogonRights[$name]
				}
				else
				{
					return $name
				}
			}
		}
		
		
		# Outputs list of hashtables as a PSObject
		function Out-Object
		{
			param (
				[System.Collections.Hashtable[]]$hashData
			)
			$order = @()
			$result = @{ }
			$hashData | ForEach-Object {
				$order += ($_.Keys -as [Array])[0]
				$result += $_
			}
			$out = New-Object PSObject -Property $result | Select-Object $order
			return $out
		}
		# Translates a SID in the form *S-1-5-... to its account name;
		function Get-AccountName
		{
			param (
				[String]$principal
			)
			try
			{
				$sid = New-Object System.Security.Principal.SecurityIdentifier($principal.Substring(1))
				$sid.Translate([Security.Principal.NTAccount])
			}
			catch { $principal }
		}
		$TemplateFilename = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
		$LogFilename = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
		$StdOut = & $SecEdit /export /cfg $TemplateFilename /areas USER_RIGHTS /log $LogFilename
		Write-Verbose "$StdOut"
		if ($LASTEXITCODE -eq 0)
		{
			$dtable = $null
			$dtable = New-Object System.Data.DataTable
			$dtable.Columns.Add("Privilege", "System.String") | Out-Null
			$dtable.Columns.Add("PrivilegeName", "System.String") | Out-Null
			$dtable.Columns.Add("Principal", "System.String") | Out-Null
			$dtable.Columns.Add("ComputerName", "System.String") | Out-Null
			Select-String '^(Se\S+) = (\S+)' $TemplateFilename | Foreach-Object {
				$Privilege = $_.Matches[0].Groups[1].Value
				$Principals = $_.Matches[0].Groups[2].Value -split ','
				foreach ($Principal in $Principals)
				{
					$PrincipalName = Get-AccountName $Principal
					
					# If $UserName is provided, filter the output
					if (-not $UserName -or ($UserName -contains $PrincipalName))
					{
						$nRow = $dtable.NewRow()
						$nRow.Privilege = $Privilege
						$nRow.PrivilegeName = Get-PrivilegeDisplayName $Privilege
						$nRow.Principal = $PrincipalName
						$nRow.ComputerName = $env:COMPUTERNAME
						$dtable.Rows.Add($nRow)
					}
				}
				return $dtable
			}
		}
		else
		{
			$OFS = ""
			Write-Error "$StdOut"
		}
		Remove-Item $TemplateFilename, $LogFilename -ErrorAction SilentlyContinue
	}
	if (!$PassThru)
	{
		Write-Output "$(Time-Stamp)Starting get user rights script execution."
	}
	#endregion Initialization
}
PROCESS
{
	#region MainFunctionSection
	function Get-UserRights
	{
		param
		(
			[Parameter(ValueFromPipeline = $true,
					   Position = 0,
					   HelpMessage = '(Server1, Server2) Comma-separated list of servers you want to run this script against. To run locally, run without this parameter. This argument accepts values from the pipeline.')]
			[Alias('Computers', 'Servers')]
			[array]$ComputerName,
			[Parameter(Position = 1,
					   HelpMessage = 'Specifies the usernames to filter the results.')]
			[Alias('User', 'Principal')]
			[array]$UserName,
			[Parameter(Position = 2,
					   HelpMessage = '(e.g., C:\Temp) Location to store the output file. Set the type with FileOutputType.')]
			[Alias('Path', 'OutputDirectory')]
			[string]$FileOutputPath,
			[Parameter(Position = 3,
					   HelpMessage = '(CSV or Text) Sets the type of file you would like to output. Combine with the FileOutputPath parameter.')]
			[ValidateSet('CSV', 'Text', 'None')]
			[Alias('Type', 'OutputFileType')]
			[string]$FileOutputType = "None",
			[Parameter(Position = 4,
					   HelpMessage = 'Outputs the result as an object that you can manipulate or access.')]
			[switch]$PassThru
		)
		if (!$ComputerName)
		{
			$ComputerName = $env:COMPUTERNAME
		}
		[array]$localrights = $null
		foreach ($ComputerName in $ComputerName)
		{
			if (!$PassThru)
			{
				Write-Output "$(Time-Stamp)Gathering current User Account Rights on: $ComputerName"
			}
			#region Non-LocalMachine
			if ($ComputerName -notmatch $env:COMPUTERNAME)
			{
				$GetSecurityPolicyFunction = "function Get-SecurityPolicy { ${function:Get-SecurityPolicy} }"
				$localrights += Invoke-Command -ScriptBlock {
					param ($GetSecurityPolicyFunctionContents,
						$UserName,
						[int]$VerbosePreference)
					. ([ScriptBlock]::Create($GetSecurityPolicyFunctionContents))
					return Get-SecurityPolicy -UserName $UserName
				} -ArgumentList $GetSecurityPolicyFunction, $UserName, $VerbosePreference -ComputerName $ComputerName -HideComputerName | Select-Object * -ExcludeProperty RunspaceID, PSShowComputerName, PSComputerName -Unique
			} #endregion Non-LocalMachine
			else
			#region LocalMachine
			{
				$localrights += Get-SecurityPolicy -UserName $UserName
			} #endregion LocalMachine
			$output += $localrights
			if (!$PassThru)
			{
				Write-Output "$(Time-Stamp)Gathering for $ComputerName completed."
			}
		}
		if (!$PassThru)
		{
			Write-Output "$(Time-Stamp)Main script execution completed!"
		}
		$output = $output | Select-Object Privilege, PrivilegeName, Principal, ComputerName -Unique | Sort-Object Privilege, ComputerName
		if ($PassThru)
		{
			return $output
		}
		elseif (!$FileOutputPath)
		{
			$output | Format-Table -AutoSize | Out-String -Width 2048
		}
		else
		{
			#region FileOutputType
			switch ($FileOutputType) {
				'Text' {
					Write-Output "$(Time-Stamp)Writing output to `'$FileOutputPath\UserLogonRights.txt`'."
					$output | Format-Table -AutoSize | Out-String -Width 2048 | Out-File "$FileOutputPath\UserLogonRights.txt" -Force
				}
				'CSV' {
					Write-Output "$(Time-Stamp)Writing output to `'$FileOutputPath\UserLogonRights.csv`'."
					$output | Export-CSV $FileOutputPath\UserLogonRights.csv -NoTypeInformation
				}
				default {
					Write-Output "Unsupported File Output Type."
				}
			}
			#endregion FileOutputType
		}
	}
	#endregion MainFunctionSection
	if ($FileOutputPath -or $UserName -or $FileOutputType -or $ComputerName -or $PassThru)
	{
		Get-UserRights -UserName $UserName -FileOutputPath:$FileOutputPath -FileOutputType:$FileOutputType -ComputerName:$ComputerName -PassThru:$PassThru
	}
	else
	{
		<# 
		Edit line 493 to modify the default command run when this script is executed.
		Example:
			- For outputting multiple servers to a text file: 
				Get-UserRights -ComputerName MS01-2019, IIS-2019 -FileOutputPath C:\Temp -FileOutputType Text

			- Example for gathering locally:
				Get-UserRights
		#>
		Get-UserRights
	}
}
END
{
	Write-Verbose "$(Time-Stamp)Script Completed!"
}
# SIG # Begin signature block
# MIIoLAYJKoZIhvcNAQcCoIIoHTCCKBkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDPUev2LU+LYSgW
# crI/Twa49PPriwKaWNVwqg2rs4T4jKCCDXYwggX0MIID3KADAgECAhMzAAAEBGx0
# Bv9XKydyAAAAAAQEMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjQwOTEyMjAxMTE0WhcNMjUwOTExMjAxMTE0WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQC0KDfaY50MDqsEGdlIzDHBd6CqIMRQWW9Af1LHDDTuFjfDsvna0nEuDSYJmNyz
# NB10jpbg0lhvkT1AzfX2TLITSXwS8D+mBzGCWMM/wTpciWBV/pbjSazbzoKvRrNo
# DV/u9omOM2Eawyo5JJJdNkM2d8qzkQ0bRuRd4HarmGunSouyb9NY7egWN5E5lUc3
# a2AROzAdHdYpObpCOdeAY2P5XqtJkk79aROpzw16wCjdSn8qMzCBzR7rvH2WVkvF
# HLIxZQET1yhPb6lRmpgBQNnzidHV2Ocxjc8wNiIDzgbDkmlx54QPfw7RwQi8p1fy
# 4byhBrTjv568x8NGv3gwb0RbAgMBAAGjggFzMIIBbzAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQU8huhNbETDU+ZWllL4DNMPCijEU4w
# RQYDVR0RBD4wPKQ6MDgxHjAcBgNVBAsTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEW
# MBQGA1UEBRMNMjMwMDEyKzUwMjkyMzAfBgNVHSMEGDAWgBRIbmTlUAXTgqoXNzci
# tW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3JsMGEG
# CCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3J0
# MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIBAIjmD9IpQVvfB1QehvpC
# Ge7QeTQkKQ7j3bmDMjwSqFL4ri6ae9IFTdpywn5smmtSIyKYDn3/nHtaEn0X1NBj
# L5oP0BjAy1sqxD+uy35B+V8wv5GrxhMDJP8l2QjLtH/UglSTIhLqyt8bUAqVfyfp
# h4COMRvwwjTvChtCnUXXACuCXYHWalOoc0OU2oGN+mPJIJJxaNQc1sjBsMbGIWv3
# cmgSHkCEmrMv7yaidpePt6V+yPMik+eXw3IfZ5eNOiNgL1rZzgSJfTnvUqiaEQ0X
# dG1HbkDv9fv6CTq6m4Ty3IzLiwGSXYxRIXTxT4TYs5VxHy2uFjFXWVSL0J2ARTYL
# E4Oyl1wXDF1PX4bxg1yDMfKPHcE1Ijic5lx1KdK1SkaEJdto4hd++05J9Bf9TAmi
# u6EK6C9Oe5vRadroJCK26uCUI4zIjL/qG7mswW+qT0CW0gnR9JHkXCWNbo8ccMk1
# sJatmRoSAifbgzaYbUz8+lv+IXy5GFuAmLnNbGjacB3IMGpa+lbFgih57/fIhamq
# 5VhxgaEmn/UjWyr+cPiAFWuTVIpfsOjbEAww75wURNM1Imp9NJKye1O24EspEHmb
# DmqCUcq7NqkOKIG4PVm3hDDED/WQpzJDkvu4FrIbvyTGVU01vKsg4UfcdiZ0fQ+/
# V0hf8yrtq9CkB8iIuk5bBxuPMIIHejCCBWKgAwIBAgIKYQ6Q0gAAAAAAAzANBgkq
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGgwwghoIAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAQEbHQG/1crJ3IAAAAABAQwDQYJYIZIAWUDBAIB
# BQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPg9N2LWIDv8Ol6yaXwYzoRC
# uGpT65ffNV+Gn11N0L9PMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQBWHptQ3yJ8ukrEAQrar8C3R/qKwFKHA97cU5NxfudtWc9sNf7GjWJa
# x6F4+yc8n/e0qLdhW6KlyvhY22l2s+6ddd8PMPEtTXlIKGyLvwPk3HyKRERagnyu
# EfFQ0/7fYh1WtCyuaPo+PSnhwIIFEwY80qaZcZvlM7+KUz+xlDpTnSb2rOBEzC+U
# 1aB2fLpIi+D9SYOBfa1pQrgKIkZ4X1b02p0vVFT74VcB6NnAslNx9bjIIbcKGQOu
# JLYEwq2w1wnqo9+rv1tSRslRw6e9CHDDP97FoFq3KFCbl+doKfHicyrQRk4PgDgx
# jLHp2KL6X6GRCNa22EJfbD9zbYtTtZpMoYIXlDCCF5AGCisGAQQBgjcDAwExgheA
# MIIXfAYJKoZIhvcNAQcCoIIXbTCCF2kCAQMxDzANBglghkgBZQMEAgEFADCCAVIG
# CyqGSIb3DQEJEAEEoIIBQQSCAT0wggE5AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEIJS1QmW7MFCydtlurlgvF8pHTP9wBboty81zrnTM4sdlAgZnGoQ7
# CPQYEzIwMjQxMTA1MjMxNTA5LjgzNFowBIACAfSggdGkgc4wgcsxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBB
# bWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjo3RjAw
# LTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vydmlj
# ZaCCEeowggcgMIIFCKADAgECAhMzAAAB8Cp8HVk75h+tAAEAAAHwMA0GCSqGSIb3
# DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAk
# BgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4XDTIzMTIwNjE4
# NDU1MVoXDTI1MDMwNTE4NDU1MVowgcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlv
# bnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjo3RjAwLTA1RTAtRDk0NzElMCMG
# A1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBALUeLVOjOHc7RzMTzF9GevKaUk0JoZaiaY/LR4g1
# /7gQmvut/y1LOWATwiXhmPjxPl9NM4CHqchNF/aUrv66lydn/GDQAqgNikFA5asv
# 05sVKHKUgd+v8NDg+xFfwZG0ie4mwyTBKDrdt8HhDZSKQwQ/8K1keLzFble0Aqn3
# lyzea9QIy8gADzcmv9TIAMAIldVTiZpiKxzNTPsnXXV4PUqsb2ZD4hOCdFH9fbFM
# MwLP6KjxlkUcbARmD5ze+Y+nzubg6o4pbKFyoxS6k+947+BAL1G/izMs0YNqh494
# rohTQmpwaNerFtwShL+zWEKA93tTHphZ5atRdrFtv4miyA5rNSBQazVqqmcuPPRg
# p9SqfyLlNuZHV2oSVHhAD45l95WGlOiesziwT8yUnUkulHYXAAgdR4x+i1c1CLK1
# h9EFQ4kcV4lgR+VmBWTRfH/iRkF3OAVA85Z9V3Y2jNeULZ6ka1SNqW4Daiw69Adn
# MY6gpO9ZQ9f30yywY5s7TEkd3QPKA/8kBWn5tEYmpra7sCoubb60BPbrIjm95xwO
# Y1myDe8OHUdykIlr1ClFb8wPdr4AXbKBXWxGcZVRUbdU4NfcGEZPxMxT8aJTLeHs
# KVc7GZn7B4K4g7MKRMNsrk6UBLypI+mCn5caU4sQ9ozfUyB/phOmkBp4/SimHHfj
# miG3AgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQU0IKyp1dHL8yaNkZVMC/HtgVamyUw
# HwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKg
# UIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0
# JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwGCCsGAQUFBwEBBGAw
# XjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
# ZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcnQw
# DAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8E
# BAMCB4AwDQYJKoZIhvcNAQELBQADggIBADgi9JueviMQ+CjlbjGPf/7R0IbCzPzr
# dAZnaYH1nhLC0YYsy/B+xFSzc0iU8P8uxYDF1VgeSUDPAtPBDkz49F3L3YMZ+3IQ
# 4Ywd+63sarwvdFRy+u+vQAv80218SlsASQIXOx57G1jmzeHOPetfbC+gFmbbK2HB
# wt5mYyAdAKaNmn/bR8dYmCuM9iOx7pEMm1ROW9SyOv7zvz+36+tAQiqWZ5sJ4SL5
# VBXFzvAXQu4xPD+AJZ1yoeiovnYmi3ErNjyNlJDtxw0eELh4cYVGlop6JJDQZe2V
# sYhs/iRbU7cnOUqN/AbrY0JK9+YzWI8P3RdiIWbv/yaBHXoCap58Ox+MEJbB/eqF
# 4gx+BnNap4TPyVoWYzwN2ReO44JAT/YvRPGGuNS10yQBN9d1mNhGWxwEPKvzMYyW
# msULstzGoJeWHGG13YIz6alxNzxEHYPcSivRR2g/fpD2vhdYJVX/YqfQBe29bG8h
# /I4WblouXR4TOSF+/9eZSUF44ISVLuN111akGVCMm4cdQeM5UZeWslPtfiGJwXWj
# bfHlT6Puo8oFx6vI/b/WjF+Ydzq4FeVcEq6RX9AJkFUCIExgmGeS1qRYemj24h5K
# dhPpDHvB/ZFq5gcgRHxItGZuUzM86z4kdDOu+HvFK3HfXQs6n7QNo5ezzGNm+Gmf
# 5a5mKPlGZmKMMIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJmQAAAAAAFTANBgkq
# hkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IDIwMTAwHhcNMjEwOTMwMTgyMjI1WhcNMzAwOTMwMTgzMjI1WjB8MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQg
# VGltZS1TdGFtcCBQQ0EgMjAxMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAOThpkzntHIhC3miy9ckeb0O1YLT/e6cBwfSqWxOdcjKNVf2AX9sSuDivbk+
# F2Az/1xPx2b3lVNxWuJ+Slr+uDZnhUYjDLWNE893MsAQGOhgfWpSg0S3po5GawcU
# 88V29YZQ3MFEyHFcUTE3oAo4bo3t1w/YJlN8OWECesSq/XJprx2rrPY2vjUmZNqY
# O7oaezOtgFt+jBAcnVL+tuhiJdxqD89d9P6OU8/W7IVWTe/dvI2k45GPsjksUZzp
# cGkNyjYtcI4xyDUoveO0hyTD4MmPfrVUj9z6BVWYbWg7mka97aSueik3rMvrg0Xn
# Rm7KMtXAhjBcTyziYrLNueKNiOSWrAFKu75xqRdbZ2De+JKRHh09/SDPc31BmkZ1
# zcRfNN0Sidb9pSB9fvzZnkXftnIv231fgLrbqn427DZM9ituqBJR6L8FA6PRc6ZN
# N3SUHDSCD/AQ8rdHGO2n6Jl8P0zbr17C89XYcz1DTsEzOUyOArxCaC4Q6oRRRuLR
# vWoYWmEBc8pnol7XKHYC4jMYctenIPDC+hIK12NvDMk2ZItboKaDIV1fMHSRlJTY
# uVD5C4lh8zYGNRiER9vcG9H9stQcxWv2XFJRXRLbJbqvUAV6bMURHXLvjflSxIUX
# k8A8FdsaN8cIFRg/eKtFtvUeh17aj54WcmnGrnu3tz5q4i6tAgMBAAGjggHdMIIB
# 2TASBgkrBgEEAYI3FQEEBQIDAQABMCMGCSsGAQQBgjcVAgQWBBQqp1L+ZMSavoKR
# PEY1Kc8Q/y8E7jAdBgNVHQ4EFgQUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXAYDVR0g
# BFUwUzBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQM
# MAoGCCsGAQUFBwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQE
# AwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQ
# W9fOmhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNv
# bS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBa
# BggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MA0GCSqG
# SIb3DQEBCwUAA4ICAQCdVX38Kq3hLB9nATEkW+Geckv8qW/qXBS2Pk5HZHixBpOX
# PTEztTnXwnE2P9pkbHzQdTltuw8x5MKP+2zRoZQYIu7pZmc6U03dmLq2HnjYNi6c
# qYJWAAOwBb6J6Gngugnue99qb74py27YP0h1AdkY3m2CDPVtI1TkeFN1JFe53Z/z
# jj3G82jfZfakVqr3lbYoVSfQJL1AoL8ZthISEV09J+BAljis9/kpicO8F7BUhUKz
# /AyeixmJ5/ALaoHCgRlCGVJ1ijbCHcNhcy4sa3tuPywJeBTpkbKpW99Jo3QMvOyR
# gNI95ko+ZjtPu4b6MhrZlvSP9pEB9s7GdP32THJvEKt1MMU0sHrYUP4KWN1APMdU
# bZ1jdEgssU5HLcEUBHG/ZPkkvnNtyo4JvbMBV0lUZNlz138eW0QBjloZkWsNn6Qo
# 3GcZKCS6OEuabvshVGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJsWkBRH58oWFsc/4K
# u+xBZj1p/cvBQUl+fpO+y/g75LcVv7TOPqUxUYS8vwLBgqJ7Fx0ViY1w/ue10Cga
# iQuPNtq6TPmb/wrpNPgkNWcr4A245oyZ1uEi6vAnQj0llOZ0dFtq0Z4+7X6gMTN9
# vMvpe784cETRkPHIqzqKOghif9lwY1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGC
# A00wggI1AgEBMIH5oYHRpIHOMIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25z
# MScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046N0YwMC0wNUUwLUQ5NDcxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiIwoBATAHBgUrDgMCGgMV
# AMIoBkoq/mWx0LbKgwYpiJDLv2n/oIGDMIGApH4wfDELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3Rh
# bXAgUENBIDIwMTAwDQYJKoZIhvcNAQELBQACBQDq1NPPMCIYDzIwMjQxMTA1MTcy
# NjM5WhgPMjAyNDExMDYxNzI2MzlaMHQwOgYKKwYBBAGEWQoEATEsMCowCgIFAOrU
# 088CAQAwBwIBAAICIrgwBwIBAAICFEAwCgIFAOrWJU8CAQAwNgYKKwYBBAGEWQoE
# AjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGGoDANBgkq
# hkiG9w0BAQsFAAOCAQEAfaxQYUIynkkHxuPO9r+WC1oWfUZ+8U20Hz6AzdUOrLcI
# LVxZvK8UWJ9rSYJip20DAjBXj7mRXYhjib/9svVvSJpT45yiMzbhfIzHTvCrr2Kb
# cPUwh2UPKywIheju4sU+hV3G1L+eseOfK8gUpcO5lcbT9/UbcLd8fzFAI+eq84TP
# 74Yobjq5/pIxA5QwePj9oiivYgGWeig1j5HlwXO+B3IVVT/Fp02e5g4uAF3r3Klv
# 1oLvaPAMDbovR/1lkEYFVs1COuCcAdK/ctir41WW6evvzrkDaYf+aixyRU1Nl5mC
# XfKivqkJqZertiLnBFTVYoyIexsfRe9P7LDuzfbvDDGCBA0wggQJAgEBMIGTMHwx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1p
# Y3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB8Cp8HVk75h+tAAEAAAHw
# MA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQw
# LwYJKoZIhvcNAQkEMSIEICWObyjISprgZEsBFjihZYta9GGQPKAb+LosQ+GH8AyX
# MIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQgXAGao6Vy/eRTuYAHmxZHvhAU
# CJLqZv4IzpqycUBlS4swgZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0Eg
# MjAxMAITMwAAAfAqfB1ZO+YfrQABAAAB8DAiBCCnxc901Pkrn9N0t24WnjZgkaBW
# Sqo0zGZEMJrdBQmLUTANBgkqhkiG9w0BAQsFAASCAgAmhYiK8EtVfkzgC6d4vN6D
# dCApb/D76nWyVLvooPDZwLCmU3AvXjZAq1iC7gCQ+uqms3c4CD2QxD+MAGm7cP5s
# rzOPcsK9yvFFLcRAThGMNIHNNkLa8gFgOfzSAMB0rKGvogzJYIyMRtmY4QfjYGOK
# uwCVRKaG7L9Z7xXCDTaHTjhtz3F8g2RYrv0gEI+G00OCpf7ZM3qki/IC2bF0j+Dr
# usPmtamqzpDJiltBHM9PJVvxSfPSW8huYQkNBi68Nx/aF2W76K39lpqOHxueQaQm
# 5EG5jtquPAT9ldosAjfxbRnto32mHSLGTbzxA8SKmsyolml/GBgLK1vjR4PwdXTm
# mXyQTOVRQniYZLiwcAGkAdvl0PTHxfXXvwYppDTG+DmQ9R1RxLdzZ3n38dwcdno9
# ShuFBdbok6kPFSQrv5Ed7HPpexLOfKn5bN8Pfg5qEdZL9u6dZWMOmzS4yghLLmCt
# aBrQlqn44buxci+g7gmbrr0Urt81fXIT1A0RmNuQ6G4CR0Vvb2g49hPdVO4SxLl+
# CYrlztCN5w0ZTrWtgmbKnyqcVOxc3jwsCCxFjbahs+2xFbTq9wCTtLrLEfZlJk/S
# zunVR9kLz/MT7nRR0dGcziIp+7clUkcRUaHq8SVihhvingJ9Yq9vxjtLQJtFOKRk
# 6YFe1pHsoo378UdW5YSHSw==
# SIG # End signature block
