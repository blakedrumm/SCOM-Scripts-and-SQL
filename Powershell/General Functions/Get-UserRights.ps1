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
        Last Modified on: September 18th, 2024

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
     <# Edit line 468 to modify the default command run when this script is executed.
       Example for output multiple servers to a text file: 
         Get-UserRights -ComputerName MS01-2019, IIS-2019 -FileOutputPath C:\Temp -FileOutputType Text
       Example for gathering locally:
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
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCApdXxe/eK2cjPy
# 4bty+tFUEsQBoXCWium4WjN/d79zEKCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGgwwghoIAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAOvMEAOTKNNBUEAAAAAA68wDQYJYIZIAWUDBAIB
# BQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIE1G5/j1n/B7ui3AX+6hc7H7
# kZiC35v1akQSFk5NzcEhMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQAmtQgx1W7jYLMlbkMNX/Bq6QGBblSznMHN/+8jIuZc4BpM7qpVU5Sa
# f5AE0H9JXpAIFN8Lyo7SON38Ffx/1TmBLDWkxzJl7ETmapp8D7yxmdPK3qEMgToq
# Aac1Rj/Z0eHRS5D1d/RdqMYG+HAnpb+7zU7QRnmXqFQOly3fbtR9FO1/kK4ZM/yM
# m/bApqoHyTVNWKhcRVSEuoULPMD+q+hHwEbcBcpp/SCUzm7MfAxAi1T6Dh52xrC4
# S3an2+NU1CYjO/FEo+hxqX4RnhV8ezO0H/H8Hc+NwdsFobvPCRvCZfIOXOxr6dXS
# jJ984uWPpoGkiY/72p7SiNDef01oYt6boYIXlDCCF5AGCisGAQQBgjcDAwExgheA
# MIIXfAYJKoZIhvcNAQcCoIIXbTCCF2kCAQMxDzANBglghkgBZQMEAgEFADCCAVIG
# CyqGSIb3DQEJEAEEoIIBQQSCAT0wggE5AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEIMLwhJnpFTMpX+D0EM+kwVEvH8OLfYIqCh1att5vdPlwAgZm4tGQ
# qO8YEzIwMjQwOTI2MjMxNTA1LjAzN1owBIACAfSggdGkgc4wgcsxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBB
# bWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjpBNDAw
# LTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vydmlj
# ZaCCEeowggcgMIIFCKADAgECAhMzAAAB7OArpILQkVKAAAEAAAHsMA0GCSqGSIb3
# DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAk
# BgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4XDTIzMTIwNjE4
# NDUzOFoXDTI1MDMwNTE4NDUzOFowgcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlv
# bnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjpBNDAwLTA1RTAtRDk0NzElMCMG
# A1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBALBH9G4JNuDFRZWb9V26Xba7B0RmbQigAWzqgivf
# 1Ur8i0/zRyf7xOa0/ruJpsHgOYAon0Yfp0kaEQ8mlji9MpFI7CtE3FUgqg895QXd
# /hXIcRyj+7VBRp2XAPXfY25kLFueHoyLaUsbukO+zNmowbtLcwKLZuTae+0Yp14A
# gv4fvuAvivTVNJZvuuwTYlvU/83pj9bUKoOLX8hvf/NGpZe3jPG90gZw+NLhkrJA
# QXdIRkCrhciOLKjA8dqo1tnF1/aRY79qN19NTzm33fgJcCKdvSj65D0q1oo0tVVw
# 1/lClLh/r8yxc68gW4JgxF0oOOma+jAB4v7WPbtsLEIGkNAetaR8/Nmn9f5u30Ls
# TmE8/odVGioFhHu7WBR/kYSr7mvUcDSNqOfRDo699hyQTQd06/opZr6wCYkbs8O9
# Nlp7vuGibPHog+qCBWk1m4KTv1J9Wacq70XnxQCdTnxOoMcTMaxCcxRAqy1LfOOf
# pJTQ0sQU0J62W5oqSpYNFUsRZu7fb0gSHe2pc9d/LpGH/AJvB71IIkiiq0F7EGs/
# JBgDZdrPV8r3KxOzHSQD1XUnBVXjghr1z4zC0BHqyop0CBGj9uz9e7yC5rwsN7op
# bK73vh72YZbtk7ydqsMWsBPURcYcO57KBIq+/YrvAHyUCAwYmPvcJC+v6OqhbDHp
# d3J5AgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQU9FrQR2T+K/XCFhCxXxSAR/hMhYYw
# HwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKg
# UIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0
# JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwGCCsGAQUFBwEBBGAw
# XjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
# ZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcnQw
# DAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8E
# BAMCB4AwDQYJKoZIhvcNAQELBQADggIBAJK8xKQxKu+OUM9qDwBFvQ4WsBC1IswO
# k3RRjcWO8+HAYoOuuLGae4x+OuZWNGrW7wiGQO8YX9t99sVOv4gCcNJ6DxMH3N8b
# /jJuSe6imSVt4aNu3swvGl+GiUIRHIRzbQ8xkonP1K/N+47WfnGuss4vybSea/mQ
# Fy/7LUBcnlBwuJyaF7Yinf8PrsR3qg+pAjTeYONhpLU1CEE227nvA8pdnUSg1OgG
# TxsDrzf3DXX1v5r1ZOioiyR1Eag/nGMMi/6ZzS8EeFkaQlW98iGbgCnzOm0LvFUC
# XLSN46/l1QYwJiBmO+hOaB3jluoDC6d2Y+Ua6vt6V5Zh50tB/uzcvn6p9pj/ESH/
# 26jXtKcz+AdVIYDO+et4aE6sHYu10qhVJ7kttimKFdy0N7vqJi0v6aHFc8SnN1rd
# smWE9M5Dco4RkClUREGjnKW1aM8JaVfHIKmXmOP2djSd93TvVt6aei7wDetRmt2A
# ohq62wftIc6I55tkao277rba8m1rd4BiwIBrEBwH0GIk+Vrtdp32qtNh1PjlWUJh
# O0FJjihVGx51IAO/32O/+JggAbLVsLK25rSj9Cq/16sqbNAJNUxdoNzbkNMtwwYm
# tG5rcrTGK922egF7HNUmvrJeoz4FrbCEhVG8ZyuIGQpfQUkV5buvb1df6TR7gOcb
# qIEcpCN5zpU3MIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJmQAAAAAAFTANBgkq
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
# MScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046QTQwMC0wNUUwLUQ5NDcxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiIwoBATAHBgUrDgMCGgMV
# AI4c+2BV3P0RbSI80v8FeomipUx/oIGDMIGApH4wfDELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3Rh
# bXAgUENBIDIwMTAwDQYJKoZIhvcNAQELBQACBQDqn8OYMCIYDzIwMjQwOTI2MTEy
# NzIwWhgPMjAyNDA5MjcxMTI3MjBaMHQwOgYKKwYBBAGEWQoEATEsMCowCgIFAOqf
# w5gCAQAwBwIBAAICKAAwBwIBAAICE/YwCgIFAOqhFRgCAQAwNgYKKwYBBAGEWQoE
# AjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGGoDANBgkq
# hkiG9w0BAQsFAAOCAQEABynwf8rAb/zpaxWSrQ3Rr/qPe9aofCIjvYd2Xha8EICv
# VZejnSuP10fGWWUEGKHpb3SoZY4jXO3o9Sgn0wetotgxDyfCxSLW7KHXLPkgvmGD
# i9EYc5yqCyMq8hy8W4u4091woqaUS54EulrIXqMKpIO95DmAETO46bOoe0M5jSV0
# dGD+oE2uc06RIWbdNq+RDqM5iB35p6Kzn8xYX/4LqcFp2YXp55MITwYqVl82ZSek
# TxROMghjUdM9RyXguWyYXuAGk5jOYRuCJPw6PVrUFGZ/u4jCDAfHX1coOE3VxRa6
# NVp68lPGdXvZwAxCj4/ht/irL2XL7RPESsc7Yx2MITGCBA0wggQJAgEBMIGTMHwx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1p
# Y3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB7OArpILQkVKAAAEAAAHs
# MA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQw
# LwYJKoZIhvcNAQkEMSIEIAnIWg7qH+Cb8gLI5fENuHfalO+GtSUFOCimHjeB4S+h
# MIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQgJwnm9Wp9N8iHHbVAEFsrKj/F
# yJAhdqgxZQt6MATVCoMwgZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0Eg
# MjAxMAITMwAAAezgK6SC0JFSgAABAAAB7DAiBCAQIE8yKlsZx1lm1oN3NUUWLQba
# vsZfrydvkMcM+OkU6jANBgkqhkiG9w0BAQsFAASCAgAVuQdBRtlqlSB29L1c+k0G
# qo2u8gmlu98/EAi/xx+60y+hmv5Ta/rUNfAJvE/pJF9EaSz4KLNUtk8yLoTCHnAK
# 9BWyme0HkNMCve8CdjBC1sd57jnYWmhZe4KmGkK/bPHJkJNaYHifR7cwhc7csrgK
# Wmn5kQJQAa0jQnGVuXkF6Fc0UvYuLT7W158fGSaSde1/8KjtkNdz8URjY3OuUuyl
# 6HChOZPkQWti7eZmBomvyUPWJSOHlQxBw/rbsB0KaJAHJTMXWrWERlcNky5a8LS+
# gNdVlIjQEP0IBU56zyigKw+mMd67jua4JHw4eNrLeqC1YdLJJrr/T9UwYQHGq3bY
# vnB567d/QaFVK7BPAfOEfa/jhA5VmDznER9iwglA1Ujls+iN3Tq2kLRzUDDlYbbJ
# MapxtSOc5/qA2Z/G1J7n7JtQrcvWcgivq7g7ngkFo2TBiCofvaOOYYrBa7g3oZpM
# 0ri/HlV0Oj+ZBE3d63sEvZbSDQyh+0OBQgy8P4g47Snm2ZChH5jwxRtBJdodL6e+
# tHRIMHvvJcB2VA5/69fGba6KIzlv6O91Uw06PlE9o/dgi9y0ymr+03emN1CEKHfZ
# SZnZEPKYja5pql8FCEaaR1tuMMiy58NGlNZm5hJH8cg0LTEHymBd10PVdujQP3sP
# RDqMappOq/PYDUU/Vhn42A==
# SIG # End signature block
