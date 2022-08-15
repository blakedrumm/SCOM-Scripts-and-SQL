<#
    .SYNOPSIS
        Get Local User Account rights from the Local Security Policy
    
    .DESCRIPTION
        This script will gather the local security policy User Rights from the local, or a remote machine.
    
    .PARAMETER ComputerName
        Comma separated list of servers you want to run this script against. To run locally, run without this switch.
    
    .PARAMETER FileOutputPath
        Location to store the Output File. Set the Type (CSV or Text) with FileOutputType
    
    .PARAMETER FileOutputType
        Set the type of file you would like to output as. Combine with the OutputPath parameter.
    
    .PARAMETER PassThru
        Output as an object that you can manipulate / access.
    
    .EXAMPLE
        Usage:
        Get Local User Account Rights and output to text in console:
        PS C:\> .\Get-UserRights.ps1
        
        Get Remote Server User Account Rights:
        PS C:\> .\Get-UserRights.ps1 -ComputerName SQL.contoso.com
        
        Get Local Machine and Multiple Server User Account Rights:
        PS C:\> .\Get-UserRights.ps1 -ComputerName $env:COMPUTERNAME, SQL.contoso.com
        
        Output to CSV in 'C:\Temp':
        PS C:\> .\Get-UserRights.ps1 -FileOutputPath C:\Temp -FileOutputType CSV
        
        Output to Text in 'C:\Temp':
        PS C:\> .\Get-UserRights.ps1 -FileOutputPath C:\Temp -FileOutputType Text
        Pass thru object:
        PS C:\> .\Get-UserRights.ps1 -ComputerName SQL.contoso.com -PassThru | Where {$_.Principal -match "Administrator"}
    
    .NOTES
        This script is located in the following GitHub Repository: https://github.com/blakedrumm/SCOM-Scripts-and-SQL
        Exact location: https://github.com/blakedrumm/SCOM-Scripts-and-SQL/blob/master/Powershell/General%20Functions/Get-UserRights.ps1
        
        Blog post: https://blakedrumm.com/blog/set-and-check-user-rights-assignment/
        
        Author: Blake Drumm (blakedrumm@microsoft.com)
        First Created on: June 10th, 2021
        Last Modified on: August 15th, 2022
#>
[CmdletBinding()]
[OutputType([string])]
param
(
	[Parameter(ValueFromPipeline = $true,
			   Position = 0,
			   HelpMessage = '(Server1, Server2) Comma separated list of servers you want to run this script against. To run locally, run without this switch. This argument accepts values from the pipeline.')]
	[Alias('servers')]
	[array]$ComputerName,
	[Parameter(Position = 1,
			   HelpMessage = '(ex. C:\Temp) Location to store the Output File. Set the Type with FileOutputType')]
	[string]$FileOutputPath,
	[Parameter(Position = 2,
			   HelpMessage = '(CSV or Text) Set the type of file you would like to output as. Combine with the OutputPath parameter.')]
	[ValidateSet('CSV', 'Text', '')]
	[string]$FileOutputType,
	[Parameter(Position = 3,
			   HelpMessage = 'Output as an object that you can manipulate / access.')]
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
	if (!$PassThru)
	{
		Write-Output "$(Time-Stamp)Starting main script execution."
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
					   HelpMessage = '(Server1, Server2) Comma separated list of servers you want to run this script against. To run locally, run without this switch. This argument accepts values from the pipeline.')]
			[Alias('servers')]
			[array]$ComputerName,
			[Parameter(Position = 1,
					   HelpMessage = '(ex. C:\Temp) Location to store the Output File. Set the Type with FileOutputType')]
			[string]$FileOutputPath,
			[Parameter(Mandatory = $false,
					   Position = 2,
					   HelpMessage = '(CSV or Text) Set the type of file you would like to output as. Combine with the OutputPath parameter.')]
			[ValidateSet('CSV', 'Text', '')]
			[string]$FileOutputType,
			[Parameter(Position = 3,
					   HelpMessage = 'Output as an object that you can manipulate / access.')]
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
				$localrights += Invoke-Command -ScriptBlock {
					param ([int]$VerbosePreference)
					function Get-SecurityPolicy
					{
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
							"SeBatchLogonRight"				    = "Log on as a batch job"
							"SeDenyBatchLogonRight"			    = "Deny log on as a batch job"
							"SeDenyInteractiveLogonRight"	    = "Deny log on locally"
							"SeDenyNetworkLogonRight"		    = "Deny access to this computer from the network"
							"SeDenyRemoteInteractiveLogonRight" = "Deny log on through Remote Desktop Services"
							"SeDenyServiceLogonRight"		    = "Deny log on as a service"
							"SeInteractiveLogonRight"		    = "Allow log on locally"
							"SeNetworkLogonRight"			    = "Access this computer from the network"
							"SeRemoteInteractiveLogonRight"	    = "Allow log on through Remote Desktop Services"
							"SeServiceLogonRight"			    = "Log on as a service"
						}
						# Create type to invoke LookupPrivilegeDisplayName Win32 API
						$Win32APISignature = @'
[DllImport("advapi32.dll", SetLastError=true)]
public static extern bool LookupPrivilegeDisplayName(
  string systemName,
  string privilegeName,
  System.Text.StringBuilder displayName,
  ref uint cbDisplayName,
  out uint languageId
);
'@
						$AdvApi32 = Add-Type advapi32 $Win32APISignature -Namespace LookupPrivilegeDisplayName -PassThru
						# Use LookupPrivilegeDisplayName Win32 API to get display name of privilege
						# (except for user logon rights)
						function Get-PrivilegeDisplayName
						{
							param (
								[String]$name
							)
							$displayNameSB = New-Object System.Text.StringBuilder 1024
							$languageId = 0
							$ok = $AdvApi32::LookupPrivilegeDisplayName($null, $name, $displayNameSB, [Ref]$displayNameSB.Capacity, [Ref]$languageId)
							if ($ok)
							{
								$displayNameSB.ToString()
							}
							else
							{
								# Doesn't lookup logon rights, so use hashtable for that
								if ($UserLogonRights[$name])
								{
									$UserLogonRights[$name]
								}
								else
								{
									$name
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
									$nRow = $dtable.NewRow()
									$nRow.Privilege = $Privilege
									$nRow.PrivilegeName = Get-PrivilegeDisplayName $Privilege
									$nRow.Principal = Get-AccountName $Principal
									$nRow.ComputerName = $env:COMPUTERNAME
									$dtable.Rows.Add($nRow)
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
					return Get-SecurityPolicy
				} -ArgumentList $VerbosePreference -computer $ComputerName -HideComputerName | Select-Object * -ExcludeProperty RunspaceID, PSShowComputerName, PSComputerName -Unique
			} #endregion Non-LocalMachine
			else #region LocalMachine
			{
				function Get-SecurityPolicy
				{
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
						"SeBatchLogonRight"				    = "Log on as a batch job"
						"SeDenyBatchLogonRight"			    = "Deny log on as a batch job"
						"SeDenyInteractiveLogonRight"	    = "Deny log on locally"
						"SeDenyNetworkLogonRight"		    = "Deny access to this computer from the network"
						"SeDenyRemoteInteractiveLogonRight" = "Deny log on through Remote Desktop Services"
						"SeDenyServiceLogonRight"		    = "Deny log on as a service"
						"SeInteractiveLogonRight"		    = "Allow log on locally"
						"SeNetworkLogonRight"			    = "Access this computer from the network"
						"SeRemoteInteractiveLogonRight"	    = "Allow log on through Remote Desktop Services"
						"SeServiceLogonRight"			    = "Log on as a service"
					}
					# Create type to invoke LookupPrivilegeDisplayName Win32 API
					$Win32APISignature = @'
[DllImport("advapi32.dll", SetLastError=true)]
public static extern bool LookupPrivilegeDisplayName(
  string systemName,
  string privilegeName,
  System.Text.StringBuilder displayName,
  ref uint cbDisplayName,
  out uint languageId
);
'@
					$AdvApi32 = Add-Type advapi32 $Win32APISignature -Namespace LookupPrivilegeDisplayName -PassThru
					# Use LookupPrivilegeDisplayName Win32 API to get display name of privilege
					# (except for user logon rights)
					function Get-PrivilegeDisplayName
					{
						param (
							[String]$name
						)
						$displayNameSB = New-Object System.Text.StringBuilder 1024
						$languageId = 0
						$ok = $AdvApi32::LookupPrivilegeDisplayName($null, $name, $displayNameSB, [Ref]$displayNameSB.Capacity, [Ref]$languageId)
						if ($ok)
						{
							$displayNameSB.ToString()
						}
						else
						{
							# Doesn't lookup logon rights, so use hashtable for that
							if ($UserLogonRights[$name])
							{
								$UserLogonRights[$name]
							}
							else
							{
								$name
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
								$nRow = $dtable.NewRow()
								$nRow.Privilege = $Privilege
								$nRow.PrivilegeName = Get-PrivilegeDisplayName $Privilege
								$nRow.Principal = Get-AccountName $Principal
								$nRow.ComputerName = $env:COMPUTERNAME
								$dtable.Rows.Add($nRow)
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
				$localrights += Get-SecurityPolicy
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
	if ($FileOutputPath -or $FileOutputType -or $ComputerName -or $PassThru)
	{
		Get-UserRights -FileOutputPath:$FileOutputPath -FileOutputType:$FileOutputType -ComputerName:$ComputerName -PassThru:$PassThru
	}
	else
	{
     <# Edit line 467 to modify the default command run when this script is executed.
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
