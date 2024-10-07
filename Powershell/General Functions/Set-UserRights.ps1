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

        .\Set-UserRights.ps1 -AddRight -UserRight SeServiceLogonRight, SeBatchLogonRight -ComputerName $env:COMPUTERNAME, SQL.contoso.com -Username CONTOSO\User1, CONTOSO\User2

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
	 <# Edit line 558 to modify the default command run when this script is executed.
	   Example: 
	        Set-UserRights -AddRight -UserRight SeServiceLogonRight, SeBatchLogonRight -ComputerName $env:COMPUTERNAME, SQL.contoso.com -UserName CONTOSO\User1, CONTOSO\User2
	        or
	        Set-UserRights -AddRight -UserRight SeBatchLogonRight -Username S-1-5-11
	        or
	        Set-UserRights -RemoveRight -UserRight SeBatchLogonRight -Username CONTOSO\User2
	        or
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
# MIIoSAYJKoZIhvcNAQcCoIIoOTCCKDUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBwTFXzCEoWMYqU
# hqzJExLuyUnwsxb3SD9P8QIYQ7E5zqCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIL3hNmF43z1MFJVsk64iqkJ9
# PcUjsq3H32Xln0TRJr8rMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQDMoumqRVTGSC1vAxUoVKhGtuFa/y7ctv7DKrI/XB5Pm0aBAAxNR7o5
# 5PEVjtul1ipwK5M77SYmUpxKg8YQ79r6/HO8a6f4uuVeRv+/bu5p5QR+kk0iQA80
# jK79hB1HfGW6OGf19XxYjqhMNFzKyRQmeRqRXcOrdmE7xRiXV//XY+F6IomnwWQB
# NWDtUeaUYa+5CNckMHTehNN5iNvJ1tEND2VG0VSSaba0dKqpSzuajCGT4N6bPp7u
# peVbBJHy/90RNHKjO0n4zxTzdj8oPlQGDIvmNne+hhggufQERcDoA0tCSQnhj3Jl
# YkSzzcNtwlWhQKpE9yWVrdyNSTKMNgaDoYIXsDCCF6wGCisGAQQBgjcDAwExghec
# MIIXmAYJKoZIhvcNAQcCoIIXiTCCF4UCAQMxDzANBglghkgBZQMEAgEFADCCAVoG
# CyqGSIb3DQEJEAEEoIIBSQSCAUUwggFBAgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEIPfXhN1siATtnjZ3Qju7fgfsonOrC1F5KrY6FycV7VYqAgZm60my
# 36cYEzIwMjQxMDA3MTc1MDA5LjMzM1owBIACAfSggdmkgdYwgdMxCzAJBgNVBAYT
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
# GgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCBwJews
# TV/otFncE//1DxNaJh7gVDmD32B31N9fU1PCIDCB+gYLKoZIhvcNAQkQAi8xgeow
# gecwgeQwgb0EIOQy777JAndprJwi4xPq8Dsk24xpU4jeoONIRXy6nKf9MIGYMIGA
# pH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UE
# AxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAH/Ejh898Fl1qEA
# AQAAAf8wIgQgpOtgRPnfPcta+K4rjV4435LsNRLCzLnuWvu7OV16NbgwDQYJKoZI
# hvcNAQELBQAEggIAxaB3VH2NK7U7mOQXfYxTZwPrAqzX1K6aVW418RpvzICYZmMV
# tP1GV+b7B2uCuLW75m+OpbaWO/VTtdhKG4xKnY8T+J+jDzvxX61MXYckKxiI1cLV
# Jk27QXIT8JvCAjOMSv2+JIM2ghrzAZgsH3TNeea27FgIFEqbu5SdH3vJkGEImmkD
# AwF7kUH1YhbEVOQgOGN6tlrCXmjRfYoDRcFLGP2ybJnifQhP/OroVgldvOHyt57V
# hXpFjH2NAXAF4Tq0fsXvnBRt65SMLPnx9P0+0sWyqQVjQUEhIf+dX15y5lPDC9dm
# PCUqsUu1Sivwbu4Ri0e1LsIo8XobZJ+O4QwFdCrUMMWXUrFtaDpFbSLkXLezKnt2
# VNpQ235JgiLrJVJ0QCrgpgWEAz9fXJ1Hau5oOJc7qkiRve+RQy4i3MRVj1T+Mrjj
# aVJQlfUciQ9qkjpCUdHkciz0k/uN4/0MD/BowyfpOviPAOFR5baeQnHqNpmAPXxN
# 6VFCwAClc+kkmvigWS40Mhe49KYaUQJ8id24MZpctYb5XArcbZ2DobCcMtzZh7S+
# WzDKOyCWU/6Qi9rg81AplTKl4Np8OxCn/y3W/F0zJAghmHTBnkQE7VnWU4lLW+jQ
# GRTJo8lExNTnfT6M4ZB8FmIkhQ50hEBKW+xpgi+xbIYFxM3Ga7r3ehaUEjo=
# SIG # End signature block
