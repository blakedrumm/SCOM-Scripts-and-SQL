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

            PS C:\> .\Get-UserRights.ps1 -ComputerName $env:COMPUTERNAME, SQL.contoso.com

    .EXAMPLE
        Get user account rights for specific users on a remote server:

            PS C:\> .\Get-UserRights.ps1 -ComputerName SQL.contoso.com -UserName CONTOSO\User1, CONTOSO\User2

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
	[ValidateSet('CSV', 'Text', '')]
	[Alias('Type', 'OutputFileType')]
	[string]$FileOutputType,
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
			[Alias('servers')]
			[array]$ComputerName,
			[Parameter(Position = 1,
					   HelpMessage = 'Specifies the usernames to filter the results.')]
			[Alias('user')]
			[array]$UserName,
			[Parameter(Position = 2,
					   HelpMessage = '(e.g., C:\Temp) Location to store the output file. Set the type with FileOutputType.')]
			[Alias('path')]
			[string]$FileOutputPath,
			[Parameter(Position = 3,
					   HelpMessage = '(CSV or Text) Sets the type of file you would like to output. Combine with the FileOutputPath parameter.')]
			[ValidateSet('CSV', 'Text', '')]
			[Alias('type')]
			[string]$FileOutputType,
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
			if ($FileOutputType -eq 'Text')
			{
				Write-Output "$(Time-Stamp)Writing output to `'$FileOutputPath\UserLogonRights.txt`'."
				$output | Format-Table -AutoSize | Out-String -Width 2048 | Out-File "$FileOutputPath\UserLogonRights.txt" -Force
			}
			elseif ($FileOutputType -eq 'CSV')
			{
				Write-Output "$(Time-Stamp)Writing output to `'$FileOutputPath\UserLogonRights.csv`'."
				$output | Export-CSV $FileOutputPath\UserLogonRights.csv -NoTypeInformation
			}
			else
			{
				Write-Output "Unsupported File Output Type."
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
		Edit line 494 to modify the default command run when this script is executed.
		Example:
			For outputting multiple servers to a text file: 
				Get-UserRights -ComputerName MS01-2019, IIS-2019 -FileOutputPath C:\Temp -FileOutputType Text
			or
			Example for gathering locally:
				Get-UserRights
		#>
		Get-UserRights
	}
}
END
{
	Write-Verbose "$(Time-Stamp)Script Completed!"

# SIG # Begin signature block
# MIIoSAYJKoZIhvcNAQcCoIIoOTCCKDUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBvJCaUms5HKTyl
# /Ib2Cxj6rh5pQTdt4IE5UMe8yV/bQKCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
# DkyjTQVBAAAAAAOvMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjMxMTE2MTkwOTAwWhcNMjQxMTE0MTkwOTAwWjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDOS8s1ra6f0YGtg0OhEaQa/t3Q+q1MEHhWJhqQVuO5amYXQpy8MDPNoJYk+FWA
# hePP5LxwcSge5aen+f5Q6WNPd6EDxGzotvVpNi5ve0H97S3F7C/axDfKxyNh21MG
# 0W8Sb0vxi/vorcLHOL9i+t2D6yvvDzLlEefUCbQV/zGCBjXGlYJcUj6RAzXyeNAN
# xSpKXAGd7Fh+ocGHPPphcD9LQTOJgG7Y7aYztHqBLJiQQ4eAgZNU4ac6+8LnEGAL
# go1ydC5BJEuJQjYKbNTy959HrKSu7LO3Ws0w8jw6pYdC1IMpdTkk2puTgY2PDNzB
# tLM4evG7FYer3WX+8t1UMYNTAgMBAAGjggFzMIIBbzAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQURxxxNPIEPGSO8kqz+bgCAQWGXsEw
# RQYDVR0RBD4wPKQ6MDgxHjAcBgNVBAsTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEW
# MBQGA1UEBRMNMjMwMDEyKzUwMTgyNjAfBgNVHSMEGDAWgBRIbmTlUAXTgqoXNzci
# tW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3JsMGEG
# CCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3J0
# MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIBAISxFt/zR2frTFPB45Yd
# mhZpB2nNJoOoi+qlgcTlnO4QwlYN1w/vYwbDy/oFJolD5r6FMJd0RGcgEM8q9TgQ
# 2OC7gQEmhweVJ7yuKJlQBH7P7Pg5RiqgV3cSonJ+OM4kFHbP3gPLiyzssSQdRuPY
# 1mIWoGg9i7Y4ZC8ST7WhpSyc0pns2XsUe1XsIjaUcGu7zd7gg97eCUiLRdVklPmp
# XobH9CEAWakRUGNICYN2AgjhRTC4j3KJfqMkU04R6Toyh4/Toswm1uoDcGr5laYn
# TfcX3u5WnJqJLhuPe8Uj9kGAOcyo0O1mNwDa+LhFEzB6CB32+wfJMumfr6degvLT
# e8x55urQLeTjimBQgS49BSUkhFN7ois3cZyNpnrMca5AZaC7pLI72vuqSsSlLalG
# OcZmPHZGYJqZ0BacN274OZ80Q8B11iNokns9Od348bMb5Z4fihxaBWebl8kWEi2O
# PvQImOAeq3nt7UWJBzJYLAGEpfasaA3ZQgIcEXdD+uwo6ymMzDY6UamFOfYqYWXk
# ntxDGu7ngD2ugKUuccYKJJRiiz+LAUcj90BVcSHRLQop9N8zoALr/1sJuwPrVAtx
# HNEgSW+AKBqIxYWM4Ev32l6agSUAezLMbq5f3d8x9qzT031jMDT+sUAoCw0M5wVt
# CUQcqINPuYjbS1WgJyZIiEkBMIIHejCCBWKgAwIBAgIKYQ6Q0gAAAAAAAzANBgkq
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGigwghokAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAOvMEAOTKNNBUEAAAAAA68wDQYJYIZIAWUDBAIB
# BQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILpYZ673HJepiTsZe8BUu1Cw
# 0clI2RLsCrojNSMdkcHAMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQC0hrsW2Pdd/WAIxZfa2NLww+AjZGtmAPnGBZGGumo8bqyJUCMhc1WS
# e/cfSUHU/8vu31YeDoqIz7BWefuuHsofc7sKv4A7+DeXXxp9XEkxNeU1QX3ZJya1
# dpxx8IWxXGV3HDWZwOpaUE+Yp0Dur4nyyqBfKBO6TC9BmwkUyJFS9UpD3LlVqBja
# oDznMpAM9ebjQNOtXW6x6Wj7O75A1Dx6ZtHhK47DZo8mL1sET1ue/h+y5Ok8Rhok
# /Q8FFY2qKoDavJLG0Z38pfWigBn5osFZEjzIPaU0r01rm9bikif1AVY3Df/7bjWS
# FHvmXRnBwrrqS2goY5b+d3mMtvjqFhgCoYIXsDCCF6wGCisGAQQBgjcDAwExghec
# MIIXmAYJKoZIhvcNAQcCoIIXiTCCF4UCAQMxDzANBglghkgBZQMEAgEFADCCAVoG
# CyqGSIb3DQEJEAEEoIIBSQSCAUUwggFBAgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEIPCSHGnwLh55UJzOkOMy/KhA4lwNehJHm3EvX4w12pgBAgZm60my
# 35EYEzIwMjQxMDA3MTc1MDA4LjY0MlowBIACAfSggdmkgdYwgdMxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jvc29mdCBJ
# cmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEnMCUGA1UECxMeblNoaWVsZCBUU1Mg
# RVNOOjRDMUEtMDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFt
# cCBTZXJ2aWNloIIR/jCCBygwggUQoAMCAQICEzMAAAH/Ejh898Fl1qEAAQAAAf8w
# DQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
# b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
# dGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcN
# MjQwNzI1MTgzMTE5WhcNMjUxMDIyMTgzMTE5WjCB0zELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9zb2Z0IElyZWxhbmQg
# T3BlcmF0aW9ucyBMaW1pdGVkMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046NEMx
# QS0wNUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZp
# Y2UwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDJ6JXSkHtuDz+pz+aS
# IN0lefMlY9iCT2ZMZ4jenNCmzKtElERZwpgd3/11v6DfPh1ThUKQBkReq+TE/lA1
# O0Ebkil7GmmHg+FuIkrC9f5RLgqRIWF/XB+UMBjW270JCqGHF8cVXu+G2aocsIKY
# PGFk+YIGH39d8UlAhTBVlHxG1SSDOY31uZaJiB9fRH5sMCedxR22nXGMaYKl0EzK
# CT8rSHdtRNTNAdviQ9/bKWQo+hYVifYY1iBbDw8YFQ7S9MwqNgPqkt4E/SFkOHk/
# d/jGEYubrH3zG4hCn9EWfMFuC2HJJcaX41PVxkCobISFPsvRJ1HupCW/mnAM16ts
# rdhIQMqTewOH1LrSEsk2o/vWIcqQbXvkcDKDrOYTmnd842v398gSk8CULxiKzFdo
# ZfhGkMFhUqkaPQUJnCKyJmzGbRf3DplKTw45d/wnFNhYip9G5bN1SKvRneOI461o
# Ortd3KkHiBmuGv3Qpw9MNHC/LrTOtBxr/UPUns9AkAk5tuJpuiLXa6xXxrG2VP90
# J48Lid1wVxqvW/5+cKWGz27cWfouQcNFl83OFeAsMTBvp0DjLezob6BDfmj3SPaL
# pqZprwmxX9wIX6INIbMDFljWxDWat0ybPF9bNc3qw8kzLj212xZMiBlZU5JL25Qe
# FJiRuAzGct6Ipd4HkwH1Axw5JwIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFMP6leT+
# tP93sT/RATuEfTDP7pRhMB8GA1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1Gely
# MF8GA1UdHwRYMFYwVKBSoFCGTmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lv
# cHMvY3JsL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNy
# bDBsBggrBgEFBQcBAQRgMF4wXAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9z
# b2Z0LmNvbS9wa2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBD
# QSUyMDIwMTAoMSkuY3J0MAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYB
# BQUHAwgwDgYDVR0PAQH/BAQDAgeAMA0GCSqGSIb3DQEBCwUAA4ICAQA5I03kykuL
# K6ebzrp+tYiLSF1rMo0uBGndZk9+FiA8Lcr8M0zMuWJhBQCnpa2CiUitq2K9eM4b
# WUiNrIb2vp7DgfWfldl0N8nXYMuOilqnl7WJT9iTR660/J86J699uwjNOT8bnX66
# JQmTvvadXNq7qEjYobIYEk68BsBUVHSDymlnAuCFPjPeaQZmOr87hn89yZUa2Mam
# zZMK0jitmM81bw7hz/holGZhD811b3UlGs5dGnJetMpQ97eQ3w3nqOmX2Si0uF29
# 3z1Fs6wk1/ZfOpsBXteNXhxoKCUDZu3MPFzJ9/BeEu70cxTd0thMAj3WBM1QXsED
# 2rUS9KUIoqU3w3XRjiJTSfIiR+lHFjIBtHKrlA9g8kcYDRPLQ8PzdoK3v1FrQh0M
# gxK7BeWlSfIjLHCsPKWB84bLKxYHBD+Ozbj1upA5g92nI52BF7y1d0auAOgF65U4
# r5xEKVemKY1jCvrWhnb+Q8zNWvNFRgyQFd71ap1J7OHy3K266VhhxEr3mqKEXSKt
# Czr9Y5AmW1Bfv2XMVcT0UWWf0yLHRqz4Lgc/N35LRsE3cDddFE7AC/TXogK5PyFj
# UifJbuPBWY346RDXN6LroutTlG0DPSdPHHk54/KOdNoi1NJjg4a4ZTVJdofj0lI/
# e3zIZgD++ittbhWd54PvbUWDBolOgcWQ4jCCB3EwggVZoAMCAQICEzMAAAAVxedr
# ngKbSZkAAAAAABUwDQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRp
# ZmljYXRlIEF1dGhvcml0eSAyMDEwMB4XDTIxMDkzMDE4MjIyNVoXDTMwMDkzMDE4
# MzIyNVowfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQG
# A1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwggIiMA0GCSqGSIb3
# DQEBAQUAA4ICDwAwggIKAoICAQDk4aZM57RyIQt5osvXJHm9DtWC0/3unAcH0qls
# TnXIyjVX9gF/bErg4r25PhdgM/9cT8dm95VTcVrifkpa/rg2Z4VGIwy1jRPPdzLA
# EBjoYH1qUoNEt6aORmsHFPPFdvWGUNzBRMhxXFExN6AKOG6N7dcP2CZTfDlhAnrE
# qv1yaa8dq6z2Nr41JmTamDu6GnszrYBbfowQHJ1S/rboYiXcag/PXfT+jlPP1uyF
# Vk3v3byNpOORj7I5LFGc6XBpDco2LXCOMcg1KL3jtIckw+DJj361VI/c+gVVmG1o
# O5pGve2krnopN6zL64NF50ZuyjLVwIYwXE8s4mKyzbnijYjklqwBSru+cakXW2dg
# 3viSkR4dPf0gz3N9QZpGdc3EXzTdEonW/aUgfX782Z5F37ZyL9t9X4C626p+Nuw2
# TPYrbqgSUei/BQOj0XOmTTd0lBw0gg/wEPK3Rxjtp+iZfD9M269ewvPV2HM9Q07B
# MzlMjgK8QmguEOqEUUbi0b1qGFphAXPKZ6Je1yh2AuIzGHLXpyDwwvoSCtdjbwzJ
# NmSLW6CmgyFdXzB0kZSU2LlQ+QuJYfM2BjUYhEfb3BvR/bLUHMVr9lxSUV0S2yW6
# r1AFemzFER1y7435UsSFF5PAPBXbGjfHCBUYP3irRbb1Hode2o+eFnJpxq57t7c+
# auIurQIDAQABo4IB3TCCAdkwEgYJKwYBBAGCNxUBBAUCAwEAATAjBgkrBgEEAYI3
# FQIEFgQUKqdS/mTEmr6CkTxGNSnPEP8vBO4wHQYDVR0OBBYEFJ+nFV0AXmJdg/Tl
# 0mWnG1M1GelyMFwGA1UdIARVMFMwUQYMKwYBBAGCN0yDfQEBMEEwPwYIKwYBBQUH
# AgEWM2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0
# b3J5Lmh0bTATBgNVHSUEDDAKBggrBgEFBQcDCDAZBgkrBgEEAYI3FAIEDB4KAFMA
# dQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAW
# gBTV9lbLj+iiXGJo0T2UkFvXzpoYxDBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8v
# Y3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXRf
# MjAxMC0wNi0yMy5jcmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRw
# Oi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dF8yMDEw
# LTA2LTIzLmNydDANBgkqhkiG9w0BAQsFAAOCAgEAnVV9/Cqt4SwfZwExJFvhnnJL
# /Klv6lwUtj5OR2R4sQaTlz0xM7U518JxNj/aZGx80HU5bbsPMeTCj/ts0aGUGCLu
# 6WZnOlNN3Zi6th542DYunKmCVgADsAW+iehp4LoJ7nvfam++Kctu2D9IdQHZGN5t
# ggz1bSNU5HhTdSRXud2f8449xvNo32X2pFaq95W2KFUn0CS9QKC/GbYSEhFdPSfg
# QJY4rPf5KYnDvBewVIVCs/wMnosZiefwC2qBwoEZQhlSdYo2wh3DYXMuLGt7bj8s
# CXgU6ZGyqVvfSaN0DLzskYDSPeZKPmY7T7uG+jIa2Zb0j/aRAfbOxnT99kxybxCr
# dTDFNLB62FD+CljdQDzHVG2dY3RILLFORy3BFARxv2T5JL5zbcqOCb2zAVdJVGTZ
# c9d/HltEAY5aGZFrDZ+kKNxnGSgkujhLmm77IVRrakURR6nxt67I6IleT53S0Ex2
# tVdUCbFpAUR+fKFhbHP+CrvsQWY9af3LwUFJfn6Tvsv4O+S3Fb+0zj6lMVGEvL8C
# wYKiexcdFYmNcP7ntdAoGokLjzbaukz5m/8K6TT4JDVnK+ANuOaMmdbhIurwJ0I9
# JZTmdHRbatGePu1+oDEzfbzL6Xu/OHBE0ZDxyKs6ijoIYn/ZcGNTTY3ugm2lBRDB
# cQZqELQdVTNYs6FwZvKhggNZMIICQQIBATCCAQGhgdmkgdYwgdMxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jvc29mdCBJ
# cmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEnMCUGA1UECxMeblNoaWVsZCBUU1Mg
# RVNOOjRDMUEtMDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFt
# cCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQCpE4xsxLwlxSVyc+TBEsVE9cWymaCB
# gzCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAk
# BgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEB
# CwUAAgUA6q4q5jAiGA8yMDI0MTAwNzA5Mzk1MFoYDzIwMjQxMDA4MDkzOTUwWjB3
# MD0GCisGAQQBhFkKBAExLzAtMAoCBQDqrirmAgEAMAoCAQACAgi/AgH/MAcCAQAC
# AhRqMAoCBQDqr3xmAgEAMDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKg
# CjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJKoZIhvcNAQELBQADggEBAHBQmuEF
# eekEi4GSlimfBMJz1JIsg1vFlRL4LkA0IZDbx+9vnbmuYRsOUguVcq/4wbeJDvu9
# W3m55gp6B+gFZlUOvRGdmVxXuTQ6vHATQN7xQcAPwdICpLa1G4X8rcZS4KsONdWq
# u867oYql1GtKZAg4PMLF2Ea3VDO4pbIbj5Sgmw40wWZ5JCxeZTSqcliZZwDHZrTf
# cGV09gfYS8P+LIvRexLMgCEazQwa4x+axToFc2Luvfxd+L4srLaNq4X3dLITh6Hc
# +RlaahFGZesX1K3JTHpNyhhj9kUKw5PqX3vgNUFRqfD9Kue6C8Lz/Plv+qXv/9H2
# 9+8AxteN0xCx1gYxggQNMIIECQIBATCBkzB8MQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQ
# Q0EgMjAxMAITMwAAAf8SOHz3wWXWoQABAAAB/zANBglghkgBZQMEAgEFAKCCAUow
# GgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCAt3D1y
# DkziX05f5tbHinj6sCDrHCR6ldDQx87WQY0+bDCB+gYLKoZIhvcNAQkQAi8xgeow
# gecwgeQwgb0EIOQy777JAndprJwi4xPq8Dsk24xpU4jeoONIRXy6nKf9MIGYMIGA
# pH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UE
# AxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAH/Ejh898Fl1qEA
# AQAAAf8wIgQgpOtgRPnfPcta+K4rjV4435LsNRLCzLnuWvu7OV16NbgwDQYJKoZI
# hvcNAQELBQAEggIAh6M5P57YlJ6EqJiC+NFiSzs3tmNxGpCAIZjVIRKIgz80oIKX
# j/m67U8c6sb+nCN9yu7wIvt+Q34K3XHQmZUrk+jBxSrRAWubYuEZQFjp9QGL5TEU
# 6PKTgz3g09oRDW3B4a5ZJbZlisb+hZgoihUXVf3Yp40rbJ+5ufRa1JLM5ZcX/uU7
# 7XsQ7fzFWuZZXApcu+/1sZG0wAnLHpU5Jjm+Isb8sjS6NtlpALpsySs1PLNvYw9H
# i7+uBjexUH+v8KYnNJKd8KFbl1OG+ElZgHryIj2zZyW1J6MUBEoQMFZVX8FsU2hn
# ZZItVinYKghRWCznLqM9zbIOTfMG56id0qAiyaV+KLu/XcYgKDX+9QZqbovCn3JY
# dwoe1jJEoCOvsmx9yOGXPWNXASjju2Z38IK0vDHb6asVmyLxNcKtb9GpuumCbcwB
# PW6LdEopOSie8g/aMl96tw37cIkTze7Rhh0TFOW43VADJfsoNQErZ09s/TfNBBog
# MTuj632zdlp/e7psfFRw8m7bWJv46XUPtKyBQos0o6ajMUyyW8ha+oFBOxmcJcji
# 1sNvQ2JVF6UuH4CBufeKOG1fls+uvCFG7wde15za7raeftbjwHsJNzIR65GmBDtv
# 3i+CyqLsiZ+tOUE29E0CglzzcJ98/FIgRCoyCCrovyQGABQs0aKqi24t11A=
# SIG # End signature block
