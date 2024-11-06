<#
    .SYNOPSIS
        Add and Remove User Right(s) for defined user(s) and computer(s).
    
    .DESCRIPTION
        Add and Remove User Rights via PowerShell.
    
    .PARAMETER AddRight
        Specifies that you want to add a user right.

    .PARAMETER RemoveRight
        Specifies that you want to remove a user right.

    .PARAMETER ComputerName
        Defines the name of the computer where the user right should be granted. This can be multiple values, comma-separated.
        Default is the local computer on which the script is run.

    .PARAMETER Username
        Defines the username(s) for which the user rights should be modified. This can be multiple values, comma-separated.
        Use the form: domain\Username when possible.
        Default is the user under which the script is run.

    .PARAMETER UserRight
        Defines the user right(s) you want to set. This can be multiple values, comma-separated.
        There is no default for this parameter.

        **Available Options:**
        - Replace a process level token (SeAssignPrimaryTokenPrivilege)
        - Generate security audits (SeAuditPrivilege)
        - Back up files and directories (SeBackupPrivilege)
        - Log on as a batch job (SeBatchLogonRight)
        - Bypass traverse checking (SeChangeNotifyPrivilege)
        - Create global objects (SeCreateGlobalPrivilege)
        - Create a pagefile (SeCreatePagefilePrivilege)
        - Create permanent shared objects (SeCreatePermanentPrivilege)
        - Create symbolic links (SeCreateSymbolicLinkPrivilege)
        - Create a token object (SeCreateTokenPrivilege)
        - Debug programs (SeDebugPrivilege)
        - Obtain an impersonation token for another user in the same session (SeDelegateSessionUserImpersonatePrivilege)
        - Deny log on as a batch job (SeDenyBatchLogonRight)
        - Deny log on locally (SeDenyInteractiveLogonRight)
        - Deny access to this computer from the network (SeDenyNetworkLogonRight)
        - Deny log on through Remote Desktop Services (SeDenyRemoteInteractiveLogonRight)
        - Deny log on as a service (SeDenyServiceLogonRight)
        - Enable computer and user accounts to be trusted for delegation (SeEnableDelegationPrivilege)
        - Impersonate a client after authentication (SeImpersonatePrivilege)
        - Increase scheduling priority (SeIncreaseBasePriorityPrivilege)
        - Adjust memory quotas for a process (SeIncreaseQuotaPrivilege)
        - Increase a process working set (SeIncreaseWorkingSetPrivilege)
        - Allow log on locally (SeInteractiveLogonRight)
        - Load and unload device drivers (SeLoadDriverPrivilege)
        - Lock pages in memory (SeLockMemoryPrivilege)
        - Add workstations to domain (SeMachineAccountPrivilege)
        - Perform volume maintenance tasks (SeManageVolumePrivilege)
        - Access this computer from the network (SeNetworkLogonRight)
        - Profile single process (SeProfileSingleProcessPrivilege)
        - Modify an object label (SeRelabelPrivilege)
        - Allow log on through Remote Desktop Services (SeRemoteInteractiveLogonRight)
        - Force shutdown from a remote system (SeRemoteShutdownPrivilege)
        - Restore files and directories (SeRestorePrivilege)
        - Manage auditing and security log (SeSecurityPrivilege)
        - Log on as a service (SeServiceLogonRight)
        - Shut down the system (SeShutdownPrivilege)
        - Synchronize directory service data (SeSyncAgentPrivilege)
        - Modify firmware environment values (SeSystemEnvironmentPrivilege)
        - Profile system performance (SeSystemProfilePrivilege)
        - Change the system time (SeSystemtimePrivilege)
        - Take ownership of files or other objects (SeTakeOwnershipPrivilege)
        - Act as part of the operating system (SeTcbPrivilege)
        - Change the time zone (SeTimeZonePrivilege)
        - Access Credential Manager as a trusted caller (SeTrustedCredManAccessPrivilege)
        - Remove computer from docking station (SeUndockPrivilege)
    
    .EXAMPLE
    Add User Right "Log on as a service" for CONTOSO\User:

        .\Set-UserRights.ps1 -AddRight -Username CONTOSO\User -UserRight SeServiceLogonRight

    .EXAMPLE
    Add User Right "Log on as a batch job" for CONTOSO\User:

        .\Set-UserRights.ps1 -AddRight -Username CONTOSO\User -UserRight SeBatchLogonRight

    .EXAMPLE
    Remove User Right "Log on as a batch job" for CONTOSO\User:

        .\Set-UserRights.ps1 -RemoveRight -Username CONTOSO\User -UserRight SeBatchLogonRight

    .EXAMPLE
    Add User Right "Allow log on locally" for current user:

        .\Set-UserRights.ps1 -AddRight -UserRight SeInteractiveLogonRight

    .EXAMPLE
    Remove User Right "Allow log on locally" for current user:

        .\Set-UserRights.ps1 -RemoveRight -UserRight SeInteractiveLogonRight

    .EXAMPLE
    Add User Right "Log on as a service" and "Log on as a batch job" for multiple users on local machine and SQL.contoso.com:

        .\Set-UserRights.ps1 -AddRight -UserRight "SeServiceLogonRight", "SeBatchLogonRight" -ComputerName "$env:COMPUTERNAME", "SQL.contoso.com" -Username "CONTOSO\User1", "CONTOSO\User2"

    .NOTES
        Original Creator: Bill Loytty (weloytty)
        Based on this script found here: https://github.com/weloytty/QuirkyPSFunctions/blob/main/Source/Users/Grant-LogOnAsService.ps1
        Modified by: Blake Drumm (blakedrumm@microsoft.com)
        First Created on: January 5th, 2022
        Last Modified on: October 7th, 2024
		
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
	[Parameter(Position = 0,
			   HelpMessage = 'Specify this switch to add a user right.')]
	[Alias('Add')]
	[switch]$AddRight,
	[Parameter(Position = 1,
			   HelpMessage = 'Defines the computer(s) where the user right should be modified.')]
	[Alias('Computers', 'Servers')]
	[array]$ComputerName,
	[Parameter(Position = 2,
			   HelpMessage = 'Specify this switch to remove a user right.')]
	[Alias('Remove')]
	[switch]$RemoveRight,
	[Parameter(Position = 3,
			   HelpMessage = 'Defines the username(s) whose rights will be modified.')]
	[Alias('User', 'Principal')]
	[array]$Username,
	[Parameter(Mandatory = $false,
			   Position = 4,
			   HelpMessage = 'Specifies the user right(s) to modify.')]
	[ValidateSet(
				 'SeNetworkLogonRight',
				 'SeBackupPrivilege',
				 'SeChangeNotifyPrivilege',
				 'SeSystemtimePrivilege',
				 'SeCreatePagefilePrivilege',
				 'SeDebugPrivilege',
				 'SeRemoteShutdownPrivilege',
				 'SeAuditPrivilege',
				 'SeIncreaseQuotaPrivilege',
				 'SeIncreaseBasePriorityPrivilege',
				 'SeLoadDriverPrivilege',
				 'SeBatchLogonRight',
				 'SeServiceLogonRight',
				 'SeInteractiveLogonRight',
				 'SeSecurityPrivilege',
				 'SeSystemEnvironmentPrivilege',
				 'SeProfileSingleProcessPrivilege',
				 'SeSystemProfilePrivilege',
				 'SeAssignPrimaryTokenPrivilege',
				 'SeRestorePrivilege',
				 'SeShutdownPrivilege',
				 'SeTakeOwnershipPrivilege',
				 'SeDenyNetworkLogonRight',
				 'SeDenyInteractiveLogonRight',
				 'SeUndockPrivilege',
				 'SeManageVolumePrivilege',
				 'SeRemoteInteractiveLogonRight',
				 'SeImpersonatePrivilege',
				 'SeCreateGlobalPrivilege',
				 'SeIncreaseWorkingSetPrivilege',
				 'SeTimeZonePrivilege',
				 'SeCreateSymbolicLinkPrivilege',
				 'SeDelegateSessionUserImpersonatePrivilege',
				 'SeMachineAccountPrivilege',
				 'SeTrustedCredManAccessPrivilege',
				 'SeTcbPrivilege',
				 'SeCreateTokenPrivilege',
				 'SeCreatePermanentPrivilege',
				 'SeDenyBatchLogonRight',
				 'SeDenyServiceLogonRight',
				 'SeDenyRemoteInteractiveLogonRight',
				 'SeEnableDelegationPrivilege',
				 'SeLockMemoryPrivilege',
				 'SeRelabelPrivilege',
				 'SeSyncAgentPrivilege',
				 IgnoreCase = $true)]
	[Alias('Right', 'Privilege')]
	[array]$UserRight
)

BEGIN
{
	#region Initialization
	Write-Output '==================================================================='
	Write-Output '==========================  Start of Script ======================='
	Write-Output '==================================================================='
	
	$checkingpermission = "Checking for elevated permissions..."
	$scriptout += $checkingpermission
	Write-Output $checkingpermission
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
		Write-Output $permissiongranted
	}
	
	Function Time-Stamp
	{
		$TimeStamp = Get-Date -UFormat "%B %d, %Y @ %r"
		return "$TimeStamp - "
	}
	#endregion Initialization
}
PROCESS
{
	#region MainFunctionSection
	function Inner-SetUserRights
	{
		param
		(
			[Parameter(Position = 0,
					   HelpMessage = 'You want to Add a user right.')]
			[Alias('add')]
			[switch]$AddRight,
			[Parameter(Position = 1)]
			[Alias('computer')]
			[array]$ComputerName,
			[Parameter(Position = 2,
					   HelpMessage = 'You want to Remove a user right.')]
			[switch]$RemoveRight,
			[Parameter(Position = 3)]
			[Alias('user')]
			[array]$Username,
			[Parameter(Mandatory = $false,
					   Position = 4)]
			[Alias('right')]
			[array]$UserRight
		)
		if (!$UserRight)
		{
			Write-Warning "Inner Function: Unable to continue because you did not supply the '-UserRight' parameter."
			break
		}
		if (!$AddRight -and !$RemoveRight)
		{
			Write-Warning "Inner Function: Unable to continue because you did not supply the '-AddRight' or '-RemoveRight' switches."
			break
		}
		elseif ($AddRight -and $RemoveRight)
		{
			Write-Warning "Inner Function: Unable to continue because you used both the '-AddRight' and '-RemoveRight' switches. Run again with just one of these present, either Add or Remove."
			break
		}
		elseif ($AddRight)
		{
			Write-Verbose "Inner Function: Detected -AddRight switch in execution."
			$ActionType = 'Adding'
		}
		elseif ($RemoveRight)
		{
			Write-Verbose "Inner Function: Detected -RemoveRight switch in execution."
			$ActionType = 'Removing'
		}
		else
		{
			Write-Warning "Something is wrong, detected logic is broken before executing main function. Exiting."
			break
		}
		Function Time-Stamp
		{
			$TimeStamp = Get-Date -UFormat "%B %d, %Y @ %r"
			return "$TimeStamp - "
		}
		$tempPath = [System.IO.Path]::GetTempPath()
		$import = Join-Path -Path $tempPath -ChildPath "import.inf"
		if (Test-Path $import) { Remove-Item -Path $import -Force }
		$export = Join-Path -Path $tempPath -ChildPath "export.inf"
		if (Test-Path $export) { Remove-Item -Path $export -Force }
		$secedt = Join-Path -Path $tempPath -ChildPath "secedt.sdb"
		if (Test-Path $secedt) { Remove-Item -Path $secedt -Force }
		$Error.Clear()
		try
		{
			foreach ($right in $UserRight)
			{
				$UserLogonRight = switch ($right)
				{
					"SeAssignPrimaryTokenPrivilege"              { "Replace a process level token (SeAssignPrimaryTokenPrivilege)" }
					"SeAuditPrivilege"                           { "Generate security audits (SeAuditPrivilege)" }
					"SeBackupPrivilege"                          { "Back up files and directories (SeBackupPrivilege)" }
					"SeBatchLogonRight"                          { "Log on as a batch job (SeBatchLogonRight)" }
					"SeChangeNotifyPrivilege"                    { "Bypass traverse checking (SeChangeNotifyPrivilege)" }
					"SeCreateGlobalPrivilege"                    { "Create global objects (SeCreateGlobalPrivilege)" }
					"SeCreatePagefilePrivilege"                  { "Create a pagefile (SeCreatePagefilePrivilege)" }
					"SeCreatePermanentPrivilege"                 { "Create permanent shared objects (SeCreatePermanentPrivilege)" }
					"SeCreateSymbolicLinkPrivilege"              { "Create symbolic links (SeCreateSymbolicLinkPrivilege)" }
					"SeCreateTokenPrivilege"                     { "Create a token object (SeCreateTokenPrivilege)" }
					"SeDebugPrivilege"                           { "Debug programs (SeDebugPrivilege)" }
					"SeDelegateSessionUserImpersonatePrivilege"  { "Obtain an impersonation token for another user in the same session (SeDelegateSessionUserImpersonatePrivilege)" }
					"SeDenyBatchLogonRight"                      { "Deny log on as a batch job (SeDenyBatchLogonRight)" }
					"SeDenyInteractiveLogonRight"                { "Deny log on locally (SeDenyInteractiveLogonRight)" }
					"SeDenyNetworkLogonRight"                    { "Deny access to this computer from the network (SeDenyNetworkLogonRight)" }
					"SeDenyRemoteInteractiveLogonRight"          { "Deny log on through Remote Desktop Services (SeDenyRemoteInteractiveLogonRight)" }
					"SeDenyServiceLogonRight"                    { "Deny log on as a service (SeDenyServiceLogonRight)" }
					"SeEnableDelegationPrivilege"                { "Enable computer and user accounts to be trusted for delegation (SeEnableDelegationPrivilege)" }
					"SeImpersonatePrivilege"                     { "Impersonate a client after authentication (SeImpersonatePrivilege)" }
					"SeIncreaseBasePriorityPrivilege"            { "Increase scheduling priority (SeIncreaseBasePriorityPrivilege)" }
					"SeIncreaseQuotaPrivilege"                   { "Adjust memory quotas for a process (SeIncreaseQuotaPrivilege)" }
					"SeIncreaseWorkingSetPrivilege"              { "Increase a process working set (SeIncreaseWorkingSetPrivilege)" }
					"SeInteractiveLogonRight"                    { "Allow log on locally (SeInteractiveLogonRight)" }
					"SeLoadDriverPrivilege"                      { "Load and unload device drivers (SeLoadDriverPrivilege)" }
					"SeLockMemoryPrivilege"                      { "Lock pages in memory (SeLockMemoryPrivilege)" }
					"SeMachineAccountPrivilege"                  { "Add workstations to domain (SeMachineAccountPrivilege)" }
					"SeManageVolumePrivilege"                    { "Perform volume maintenance tasks (SeManageVolumePrivilege)" }
					"SeNetworkLogonRight"                        { "Access this computer from the network (SeNetworkLogonRight)" }
					"SeProfileSingleProcessPrivilege"            { "Profile single process (SeProfileSingleProcessPrivilege)" }
					"SeRelabelPrivilege"                         { "Modify an object label (SeRelabelPrivilege)" }
					"SeRemoteInteractiveLogonRight"              { "Allow log on through Remote Desktop Services (SeRemoteInteractiveLogonRight)" }
					"SeRemoteShutdownPrivilege"                  { "Force shutdown from a remote system (SeRemoteShutdownPrivilege)" }
					"SeRestorePrivilege"                         { "Restore files and directories (SeRestorePrivilege)" }
					"SeSecurityPrivilege"                        { "Manage auditing and security log (SeSecurityPrivilege)" }
					"SeServiceLogonRight"                        { "Log on as a service (SeServiceLogonRight)" }
					"SeShutdownPrivilege"                        { "Shut down the system (SeShutdownPrivilege)" }
					"SeSyncAgentPrivilege"                       { "Synchronize directory service data (SeSyncAgentPrivilege)" }
					"SeSystemEnvironmentPrivilege"               { "Modify firmware environment values (SeSystemEnvironmentPrivilege)" }
					"SeSystemProfilePrivilege"                   { "Profile system performance (SeSystemProfilePrivilege)" }
					"SeSystemtimePrivilege"                      { "Change the system time (SeSystemtimePrivilege)" }
					"SeTakeOwnershipPrivilege"                   { "Take ownership of files or other objects (SeTakeOwnershipPrivilege)" }
					"SeTcbPrivilege"                             { "Act as part of the operating system (SeTcbPrivilege)" }
					"SeTimeZonePrivilege"                        { "Change the time zone (SeTimeZonePrivilege)" }
					"SeTrustedCredManAccessPrivilege"            { "Access Credential Manager as a trusted caller (SeTrustedCredManAccessPrivilege)" }
					"SeUndockPrivilege"                          { "Remove computer from docking station (SeUndockPrivilege)" }
					Default                                      { "($right)" }
				}
				
				Write-Output ("$(Time-Stamp)$ActionType `"$UserLogonRight`" right for user account: '$Username' on host: '$env:COMPUTERNAME'")
				if ($Username -match "^S-.*-.*-.*$|^S-.*-.*-.*-.*-.*-.*$|^S-.*-.*-.*-.*-.*$|^S-.*-.*-.*-.*$")
				{
					$sid = $Username
				}
				else
				{
					$sid = ((New-Object System.Security.Principal.NTAccount($Username)).Translate([System.Security.Principal.SecurityIdentifier])).Value
				}
				secedit /export /cfg $export | Out-Null
				#Change the below to any right you would like
				$sids = (Select-String $export -Pattern "$right").Line
				if ($ActionType -eq 'Adding')
				{
					# If right has no value it needs to be added
					if ($sids -eq $null)
					{
						$sids = "$right = *$sid"
						$sidList = $sids
					}
					else
					{
						$sidList = "$sids,*$sid"
					}
				}
				elseif ($ActionType -eq 'Removing')
				{
					$sidList = "$($sids.Replace("*$sid", '').Replace("$Username", '').Replace(",,", ',').Replace("= ,", '= '))"
				}
				Write-Verbose $sidlist
				foreach ($line in @("[Unicode]", "Unicode=yes", "[System Access]", "[Event Audit]", "[Registry Values]", "[Version]", "signature=`"`$CHICAGO$`"", "Revision=1", "[Profile Description]", "Description=$ActionType `"$UserLogonRight`" right for user account: $Username", "[Privilege Rights]", "$sidList"))
				{
					Add-Content $import $line
				}
			}
			
			secedit /import /db $secedt /cfg $import | Out-Null
			secedit /configure /db $secedt | Out-Null
			gpupdate /force | Out-Null
			Write-Verbose "The script will not delete the following paths due to running in verbose mode, please remove these files manually if needed:"
			Write-Verbose "`$import : $import"
			Write-Verbose "`$export : $export"
			Write-Verbose "`$secedt : $secedt"
			
			if ($VerbosePreference.value__ -eq 0)
			{
				Remove-Item -Path $import -Force | Out-Null
				Remove-Item -Path $export -Force | Out-Null
				Remove-Item -Path $secedt -Force | Out-Null
			}
		}
		catch
		{
			Write-Output ("$(Time-Stamp)Failure occurred while granting `"$right`" to user account: '$Username' on host: '$env:COMPUTERNAME'")
			Write-Output "Error Details: $error"
		}
	}
	$InnerSetUserRightFunctionScript = "function Inner-SetUserRights { ${function:Inner-SetUserRights} }"
	function Set-UserRights
	{
		param
		(
			[Parameter(Position = 0,
					   HelpMessage = 'You want to Add a user right.')]
			[Alias('add')]
			[switch]$AddRight,
			[Parameter(Position = 1)]
			[Alias('computer')]
			[array]$ComputerName,
			[Parameter(Position = 2,
					   HelpMessage = 'You want to Remove a user right.')]
			[switch]$RemoveRight,
			[Parameter(Position = 3)]
			[Alias('user')]
			[array]$Username,
			[Parameter(Mandatory = $false,
					   Position = 4)]
			[ValidateSet('SeNetworkLogonRight', 'SeBackupPrivilege', 'SeChangeNotifyPrivilege', 'SeSystemtimePrivilege', 'SeCreatePagefilePrivilege', 'SeDebugPrivilege', 'SeRemoteShutdownPrivilege', 'SeAuditPrivilege', 'SeIncreaseQuotaPrivilege', 'SeIncreaseBasePriorityPrivilege', 'SeLoadDriverPrivilege', 'SeBatchLogonRight', 'SeServiceLogonRight', 'SeInteractiveLogonRight', 'SeSecurityPrivilege', 'SeSystemEnvironmentPrivilege', 'SeProfileSingleProcessPrivilege', 'SeSystemProfilePrivilege', 'SeAssignPrimaryTokenPrivilege', 'SeRestorePrivilege', 'SeShutdownPrivilege', 'SeTakeOwnershipPrivilege', 'SeDenyNetworkLogonRight', 'SeDenyInteractiveLogonRight', 'SeUndockPrivilege', 'SeManageVolumePrivilege', 'SeRemoteInteractiveLogonRight', 'SeImpersonatePrivilege', 'SeCreateGlobalPrivilege', 'SeIncreaseWorkingSetPrivilege', 'SeTimeZonePrivilege', 'SeCreateSymbolicLinkPrivilege', 'SeDelegateSessionUserImpersonatePrivilege', 'SeMachineAccountPrivilege', 'SeTrustedCredManAccessPrivilege', 'SeTcbPrivilege', 'SeCreateTokenPrivilege', 'SeCreatePermanentPrivilege', 'SeDenyBatchLogonRight', 'SeDenyServiceLogonRight', 'SeDenyRemoteInteractiveLogonRight', 'SeEnableDelegationPrivilege', 'SeLockMemoryPrivilege', 'SeRelabelPrivilege', 'SeSyncAgentPrivilege', IgnoreCase = $true)]
			[Alias('right')]
			[array]$UserRight
		)
		if (!$Username)
		{
			$Username = "$env:USERDOMAIN`\$env:USERNAME"
		}
		if (!$UserRight)
		{
			Write-Warning "Main Function: Unable to continue because you did not supply the '-UserRight' parameter."
			break
		}
		if (!$AddRight -and !$RemoveRight)
		{
			Write-Warning "Main Function: Unable to continue because you did not supply the '-AddRight' or '-RemoveRight' switches."
			break
		}
		elseif ($AddRight -and $RemoveRight)
		{
			Write-Warning "Main Function: Unable to continue because you used both the '-AddRight' and '-RemoveRight' switches. Run again with just one of these present, either Add or Remove."
			break
		}
		elseif ($AddRight)
		{
			Write-Verbose "Main Function: Detected -AddRight switch in execution."
			$ActionType = 'Adding'
		}
		elseif ($RemoveRight)
		{
			Write-Verbose "Main Function: Detected -RemoveRight switch in execution."
			$ActionType = 'Removing'
		}
		if (!$ComputerName)
		{
			$ComputerName = $env:ComputerName
		}
		foreach ($user in $Username)
		{
			foreach ($right in $UserRight)
			{
				foreach ($computer in $ComputerName)
				{
					if ($computer -match $env:COMPUTERNAME)
					{
						Inner-SetUserRights -UserRight $right -Username $user -AddRight:$AddRight -RemoveRight:$RemoveRight
					}
					else
					{
						Invoke-Command -ComputerName $Computer -Script {
							param ($script,
								[string]$Username,
								[Parameter(Mandatory = $true)]
								[array]$UserRight,
								$AddRight,
								$RemoveRight,
								$VerbosePreference)
							. ([ScriptBlock]::Create($script))
							$VerbosePreference = $VerbosePreference
							$Error.Clear()
							try
							{
								if ($VerbosePreference -eq 0)
								{
									Inner-SetUserRights -Username $Username -UserRight $UserRight -AddRight:$AddRight -RemoveRight:$RemoveRight
								}
								else
								{
									Inner-SetUserRights -Username $Username -UserRight $UserRight -AddRight:$AddRight -RemoveRight:$RemoveRight -Verbose
								}
							}
							catch
							{
								$info = [PSCustomObject]@{
									Exception = $Error.Exception.Message
									Reason    = $Error.CategoryInfo.Reason
									Target    = $Error.CategoryInfo.TargetName
									Script    = $Error.InvocationInfo.ScriptName
									Line	  = $Error.InvocationInfo.ScriptLineNumber
									Column    = $Error.InvocationInfo.OffsetInLine
									Date	  = Get-Date
									User	  = $env:username
								}
								Write-Warning "$info"
							}
							
						} -ArgumentList $InnerSetUserRightFunctionScript, $user, $right, $AddRight, $RemoveRight, $VerbosePreference
					}
				}
			}
		}
	}
	#endregion MainFunctionSection
	if ($ComputerName -or $Username -or $UserRight -or $RemoveRight)
	{
		if (!$Username)
		{
			$Username = "$env:USERDOMAIN`\$env:USERNAME"
		}
		foreach ($user in $Username)
		{
			Set-UserRights -ComputerName $ComputerName -Username $user -UserRight $UserRight -AddRight:$AddRight -RemoveRight:$RemoveRight
		}
	}
	else
	{
	<# 
	Edit line 564 to modify the default command run when this script is executed.
	Example: 
		- Add multiple user rights to specified users on specified computers:
			Set-UserRights -AddRight -UserRight SeServiceLogonRight, SeBatchLogonRight -ComputerName $env:COMPUTERNAME, SQL.contoso.com -UserName CONTOSO\User1, CONTOSO\User2
		
		- Add a single user right to a user identified by their Security Identifier (SID):
			Set-UserRights -AddRight -UserRight SeBatchLogonRight -Username S-1-5-11
		
		- Remove a user right from a specified user:
			Set-UserRights -RemoveRight -UserRight SeBatchLogonRight -Username CONTOSO\User2
		
		- Remove multiple user rights from a specified user:
			Set-UserRights -RemoveRight -UserRight SeServiceLogonRight, SeBatchLogonRight -Username CONTOSO\User1
	#>
		Set-UserRights
	}
}
END
{
	Write-Output "$(Time-Stamp)Script Completed!"
}

# SIG # Begin signature block
# MIIoLwYJKoZIhvcNAQcCoIIoIDCCKBwCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC2oEAtHQyopXzN
# cQ1sOJxZS6mMLrnC/8ciuijk+2p9s6CCDXYwggX0MIID3KADAgECAhMzAAAEBGx0
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGg8wghoLAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAQEbHQG/1crJ3IAAAAABAQwDQYJYIZIAWUDBAIB
# BQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHsfRJKYMVIvVtkYPSPFQPqz
# mmotEK2DeAlUckpxf9dRMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQBfJjRoUGSfhCAFu/Dt4nOXe1o9WS2v0re+f14RvTXxPxlrJhYQvzIR
# XhwFKzrmKmIbYiPYllB3G3sS6sFGRwe+uYCEyrUALlWnY07CcVTnj6bncws3kM4S
# ZwVyDPDUDdFQDUiGBRQehygMteHJopQgOl4r3B1h9WOyJE4zPRX5C7LdwxTuR+O8
# UoPL1EPiK2leQkjRs5z6VKOvvBg8+y3AhpcgTJHPOirlDcNvmoLAjGCPbG3pxZ2h
# ci9hDrQGwpbpWAFNKyQhMSZRDvrNtGKT1I4wX/NqnGzhelTvs2/BUkw/8tpq5Z+M
# Y1IRajp3d11DZYRxnWCH3wsqNkVQTWLhoYIXlzCCF5MGCisGAQQBgjcDAwExgheD
# MIIXfwYJKoZIhvcNAQcCoIIXcDCCF2wCAQMxDzANBglghkgBZQMEAgEFADCCAVIG
# CyqGSIb3DQEJEAEEoIIBQQSCAT0wggE5AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEIBd/688COT7A0N6GMz76rprFlbMkoFkRX1fobiaDv4gYAgZnGn56
# pDwYEzIwMjQxMTA1MjMxNTExLjUxMVowBIACAfSggdGkgc4wgcsxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBB
# bWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjo4RDAw
# LTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vydmlj
# ZaCCEe0wggcgMIIFCKADAgECAhMzAAAB88UKQ64DzB0xAAEAAAHzMA0GCSqGSIb3
# DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAk
# BgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4XDTIzMTIwNjE4
# NDYwMloXDTI1MDMwNTE4NDYwMlowgcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlv
# bnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjo4RDAwLTA1RTAtRDk0NzElMCMG
# A1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBAP6fptrhK4H2JI7lYyFueCpgBv7Pch/M2lkhZL+y
# B9eGUtiYaexS2sZfc5VyD7ySsl2LG41Qw7tkA6oJmxdSM7PzNyfVpQPkPavY+HNU
# qMe2K9YaAaPjHnCpZ7VCi/e8zPxYewqx9p0iVaN8EydUpWiY7JtDv7aNzhp/OPZc
# lBBKYT2NBGgGiAPCaplqR5icjHQSY665w+vrvhPr9hpM+IhiUZ/5dXa7qhAcCQwb
# nrFg9CKSK1COM1YcAN8GpsERqqmlqy3GlE1ziJ3ZLXFVDFxAZeOcCB55Vts9sCgQ
# uFvD7PdV61HC4QUlHNPqFtYSC/P0sxg9JuKgcvzD5mJajfG7DdHt8myp7umqyePC
# +eI/ux8TW61+LuTQ1Bkym+I6z//bf0fp4Dog5W0XzDrqKkTvURitxI2s4aVObm6q
# r6zI7W51k54ozTFjvbw1wYMWqeO4U9sQSbr561kp+1T2PEsJLOpc5U7N2oDw7ldr
# cTjWPezsyVMXhDsFitCZunGqFO9+4iVjAjYDN47c6K9x7MnAGPYVCBOJUdpy8xAO
# BIDsTm/K1qTT4wsGbQBxbgg96vwDiA4YP2hKmubIC7UnrAWQGt/ZKOf6J42roXHS
# 1aPwimDe5C9y6DfuNJp0XqrWtQRqg8hqNkIZWT6jnCfqu35zB0nf1ERTjdpYLCfQ
# L5fHAgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQUw2QV9qURUQyMDcCmhTH2oOsNCiQw
# HwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKg
# UIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0
# JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwGCCsGAQUFBwEBBGAw
# XjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
# ZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcnQw
# DAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8E
# BAMCB4AwDQYJKoZIhvcNAQELBQADggIBAN/EHI/80f7v29zeWI7hzudcz9QoVwCb
# nDrUXFHE/EJdFeWI2NnuwOo0/QPNRMFT21LkOqSpFKIhXXmPurx7p6WDz9wPdu/S
# xbgaj0AwviWEDkwGDfDMp2KF8nQT8cipwdfXWbC1ulOILayABSHv45mdv1PAkTul
# sQE8lBTHG4KJLn+vSzZBWKkGaL/wwRbZ4iLiYn68cjkMJoAaihPgDXn/ug2P3PLN
# EAFNQgI02tLX0p+vIQ3l2HmSo4bhCBxr3DovsIv5K65NmLRJnxmrrmIraFDwgwA5
# XF7AKkPiVkvo0OxU1LAE1c5SWzE4A7cbTA1P5wG6D8cPjcHsTah1V+zofYRgJnFR
# LWuBF4Z3a6pDGBDbCsy5NvnKQ76p37ieFp//1I3eB62ia1CfkjOF8KStpPUqdkXx
# MjfJ7Vnemd6vQKf+nXkfvA3AOQECJn7aLP01QR5gt8wab28SsNUENEyMawT8eqpj
# tBNJO0O9Tv7NnBE8aOJhhQVdP5WCR90eIWkrDjZeybQx8vlo5rfUXIIzXv+k9Mgp
# NGIqwMXfvRLAjBkCNXOIP/1CEQUG72miMVQs5m/O4vmJIQkhyqilUDB1s12uhmLY
# c3yd8OPMlrwIxORB5J9CxCkqvzc6EGYTcwXazPyCp7eWhzTkNbwk29nfbwmmzcsk
# IAu3StA8lic7MIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJmQAAAAAAFTANBgkq
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
# A1AwggI4AgEBMIH5oYHRpIHOMIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25z
# MScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046OEQwMC0wNUUwLUQ5NDcxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiIwoBATAHBgUrDgMCGgMV
# AG76BizYtGFrmkU7v2DcuR/ApGcooIGDMIGApH4wfDELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3Rh
# bXAgUENBIDIwMTAwDQYJKoZIhvcNAQELBQACBQDq1M4PMCIYDzIwMjQxMTA1MTcw
# MjA3WhgPMjAyNDExMDYxNzAyMDdaMHcwPQYKKwYBBAGEWQoEATEvMC0wCgIFAOrU
# zg8CAQAwCgIBAAICD7cCAf8wBwIBAAICEyswCgIFAOrWH48CAQAwNgYKKwYBBAGE
# WQoEAjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGGoDAN
# BgkqhkiG9w0BAQsFAAOCAQEAbnzTrLoq6rMeJfAz0idpKs7GoHgm/ckXRvsbQWpK
# RPawMXMO4u345T16X2Vuriiyc1kmLCJuKggzs5nyyFoAdFDpHN7IDQxmXX4PrUxD
# Oy89ICac3PSPlvSgXMAEU0BeuHjdATbGz+o2CrWywdk2sbfmBe6YZUM12vIg08LB
# eOBnCLOa9z0lnYqdIGJ/gi/xAC5pyEDeQoytfRA16nrAjRdB5qyZlceVassYZqIT
# MFN4BwmMVLXZSxktIFw8bDN2bI91xpIsK9ce38bI5bHXleC/qlDijOVe2BZ5Fdlh
# ibROEGQOo+5rlMin/zmjXR472gbggA3YYYXpCPWRJChgJzGCBA0wggQJAgEBMIGT
# MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
# ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMT
# HU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB88UKQ64DzB0xAAEA
# AAHzMA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQ
# AQQwLwYJKoZIhvcNAQkEMSIEIKa4ENkUK8c3c4E29PP+SgACy4D1MKZEiTVdy45x
# ClN6MIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQgGLzZNIu24bhWSnzAGYmT
# 9P5ECHzjWwb9oM7DGDo7YugwgZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQ
# Q0EgMjAxMAITMwAAAfPFCkOuA8wdMQABAAAB8zAiBCC3KY2Mdu7eE4IGG83OG80z
# QQi2MnVGyeTLy5E6afN6TzANBgkqhkiG9w0BAQsFAASCAgDX7dq08GS7aSkuL1Fw
# GG7/ovEdXfQfr8+9ew9Nt7K+4xjWdQQ7Ctop2xXdcn0dHbJQMoPeAJOVxcqF/i7h
# ohADp1Zdif9hYRQEonekaXkgACbQiY1ldVKSDCa490JE32lNW8rxkas1VpcsQ5Dh
# ocoMlz/3jgiL9f/el3BOH9x4jybKx+x4jmmUgnUEBVX4J/vgZKNrvNQ2SY1z/8uL
# iQnJSLMUk/9bkznjEXm3bktNDCrvpdm7x1hnoYF7nBT6vTkJtVLUapA2fzEmarkz
# cd0fj0V/0sYXJoYLhFrkdonPlnfCAxCfWoiN4TVJzHB2M7A+UbNoNMeyeNum1sdP
# HxM3fiJGgU7aygH171dT72wrXSHAcQOvu5EM/kVHA7EmhwOJfTkbwNlPXnJL9xBE
# kF0/oI3N6ccmPLtGJxoUzTvlnQnkfnpwUEXcwI17XRFCS1PNV9RvEcJoLNjNmPik
# l/NXWq7r4cu5iNam9yxCoaOZ1gWzW+UALHmFE3kzDrHrZ426Ke3Z+95kzsOPvhQF
# PUYid9kdywMYIa3gqVDDVXr5826uvov8fyzBCNHGPVR6V7p77W9O3nKV5hKAEmxf
# SQi6Fr3B6k2ifuKEoa8A1MhJEeAwR2OVKb+YYlMPM7YW18Fbx3I+eKpaeumrgQTl
# 9WVsSaEb4H+KnaO5VYyU1zuiBw==
# SIG # End signature block
