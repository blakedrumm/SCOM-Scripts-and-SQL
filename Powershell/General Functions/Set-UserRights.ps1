<#
	.Synopsis
		Add and Remove User Right(s) for defined user(s) and computer(s).
	
	.DESCRIPTION
		Add and Remove User Rights via Powershell.
	
	.PARAMETER AddRight
		You want to Add a user right.
	
	.Parameter ComputerName
		Defines the name of the computer where the user right should be granted. This can be multiple values, comma seperated.
		Default is the local computer on which the script is run.
	
	.PARAMETER RemoveRight
		You want to Remove a user right.
	
	.Parameter Username
		Defines the Username under which the service should run. This can be multiple values, comma seperated.
		Use the form: domain\Username.
		Default is the user under which the script is run.
	
	.PARAMETER UserRight
		Defines the User Right you want to set. This can be multiple values, comma seperated.
		Name of the right you want to add to: SeServiceLogonRight
		There is no default for this argument
		
		All of the Options you can use:
			Replace a process level token (SeAssignPrimaryTokenPrivilege)
			Generate security audits (SeAuditPrivilege)
			Back up files and directories (SeBackupPrivilege)
			Log on as a batch job (SeBatchLogonRight)
			Bypass traverse checking (SeChangeNotifyPrivilege)
			Create global objects (SeCreateGlobalPrivilege)
			Create a pagefile (SeCreatePagefilePrivilege)
			Create permanent shared objects (SeCreatePermanentPrivilege)
			Create symbolic links (SeCreateSymbolicLinkPrivilege)
			Create a token object (SeCreateTokenPrivilege)
			Debug programs (SeDebugPrivilege)
			Obtain an impersonation token for another user in the same session (SeDelegateSessionUserImpersonatePrivilege)
			Deny log on as a batch job (SeDenyBatchLogonRight)
			Deny log on locally (SeDenyInteractiveLogonRight)
			Deny access to this computer from the network (SeDenyNetworkLogonRight)
			Deny log on through Remote Desktop Services (SeDenyRemoteInteractiveLogonRight)
			Deny log on as a service (SeDenyServiceLogonRight)
			Enable computer and user accounts to be trusted for delegation (SeEnableDelegationPrivilege)
			Impersonate a client after authentication (SeImpersonatePrivilege)
			Increase scheduling priority (SeIncreaseBasePriorityPrivilege)
			Adjust memory quotas for a process (SeIncreaseQuotaPrivilege)
			Increase a process working set (SeIncreaseWorkingSetPrivilege)
			Allow log on locally (SeInteractiveLogonRight)
			Load and unload device drivers (SeLoadDriverPrivilege)
			Lock pages in memory (SeLockMemoryPrivilege)
			Add workstations to domain (SeMachineAccountPrivilege)
			Perform volume maintenance tasks (SeManageVolumePrivilege)
			Access this computer from the network (SeNetworkLogonRight)
			Profile single process (SeProfileSingleProcessPrivilege)
			Modify an object label (SeRelabelPrivilege)
			Allow log on through Remote Desktop Services (SeRemoteInteractiveLogonRight)
			Force shutdown from a remote system (SeRemoteShutdownPrivilege)
			Restore files and directories (SeRestorePrivilege)
			Manage auditing and security log (SeSecurityPrivilege)
			Log on as a service (SeServiceLogonRight)
			Shut down the system (SeShutdownPrivilege)
			Synchronize directory service data (SeSyncAgentPrivilege)
			Modify firmware environment values (SeSystemEnvironmentPrivilege)
			Profile system performance (SeSystemProfilePrivilege)
			Change the system time (SeSystemtimePrivilege)
			Take ownership of files or other objects (SeTakeOwnershipPrivilege)
			Act as part of the operating system (SeTcbPrivilege)
			Change the time zone (SeTimeZonePrivilege)
			Access Credential Manager as a trusted caller (SeTrustedCredManAccessPrivilege)
			Remove computer from docking station (SeUndockPrivilege)
	
	.Example
		Usage:
		Single Users
			Add User Right "Log on as a service" for CONTOSO\User:
			.\Set-UserRights.ps1 -AddRight -Username CONTOSO\User -UserRight SeServiceLogonRight
			
			Add User Right "Log on as a batch job" for CONTOSO\User:
			.\Set-UserRights.ps1 -AddRight -Username CONTOSO\User -UserRight SeBatchLogonRight

			Remove User Right "Log on as a batch job" for CONTOSO\User:
			.\Set-UserRights.ps1 -RemoveRight -Username CONTOSO\User -UserRight SeBatchLogonRight
			
			Add User Right "Allow log on locally" for current user:
			.\Set-UserRights.ps1 -AddRight -UserRight SeInteractiveLogonRight

			Remove User Right "Allow log on locally" for current user:
			.\Set-UserRights.ps1 -RemoveRight -UserRight SeInteractiveLogonRight
		
		Multiple Users / Services / Computers
			Add User Right "Log on as a service" and "Log on as a batch job" for CONTOSO\User and run on, local machine and SQL.contoso.com:
			.\Set-UserRights.ps1 -AddRight -UserRight SeServiceLogonRight, SeBatchLogonRight -ComputerName $env:COMPUTERNAME, SQL.contoso.com -UserName CONTOSO\User1, CONTOSO\User2
	
	.Notes
		Original Creator: Bill Loytty (weloytty)
		Based on this script found here: https://github.com/weloytty/QuirkyPSFunctions/blob/main/Source/Users/Grant-LogOnAsService.ps1
		I modified to my own needs: https://github.com/blakedrumm/SCOM-Scripts-and-SQL/blob/master/Powershell/General%20Functions/Set-UserRights.ps1
		
		My blog post: https://blakedrumm.com/blog/set-and-check-user-rights-assignment/
		
		Author: Blake Drumm (blakedrumm@microsoft.com)
		First Created on: January 5th, 2022
		Last Modified on: December 22nd, 2023
#>
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
BEGIN
{
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
}
PROCESS
{
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
		Add-Type -AssemblyName "System.DirectoryServices.AccountManagement"
		
		$TypeLoaded = [AppDomain]::CurrentDomain.GetAssemblies() |
		Where-Object { $_.FullName -like "*System.DirectoryServices.AccountManagement*" }
		
		if (-NOT $TypeLoaded)
		{
			Write-Warning "Unable to load 'System.DirectoryServices.AccountManagement' type in the PowerShell script."
			break
		}
		
		function Is-GroupName
		{
			param (
				[string]$name
			)
			
			try
			{
				$contextType = [System.DirectoryServices.AccountManagement.ContextType]::Domain
				$principalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext($contextType)
				
				# Attempt to find the group in the domain
				$groupPrincipal = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($principalContext, $name)
				
				if ($groupPrincipal -ne $null)
				{
					return $true
				}
				
				# If not found in domain, check local machine
				$contextType = [System.DirectoryServices.AccountManagement.ContextType]::Machine
				$principalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext($contextType)
				
				$groupPrincipal = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($principalContext, $name)
				
				return $groupPrincipal -ne $null
			}
			catch
			{
				Write-Warning "Error occurred while checking group: $_"
				return $false
			}
		}
		
		foreach ($item in $Username)
		{
			if (Is-GroupName -name $item)
			{
				Write-Host "$(Time-Stamp)$item is a group."
				$userType = 'Group'
			}
			else
			{
				Write-Host "$(Time-Stamp)$item is a user."
				$userType = 'User'
			}
		}
		
		
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
					"SeBatchLogonRight"				    { "Log on as a batch job (SeBatchLogonRight)" }
					"SeDenyBatchLogonRight"			    { "Deny log on as a batch job (SeDenyBatchLogonRight)" }
					"SeDenyInteractiveLogonRight"	    { "Deny log on locally (SeDenyInteractiveLogonRight)" }
					"SeDenyNetworkLogonRight"		    { "Deny access to this computer from the network (SeDenyNetworkLogonRight)" }
					"SeDenyRemoteInteractiveLogonRight" { "Deny log on through Remote Desktop Services (SeDenyRemoteInteractiveLogonRight)" }
					"SeDenyServiceLogonRight"		    { "Deny log on as a service (SeDenyServiceLogonRight)" }
					"SeInteractiveLogonRight"		    { "Allow log on locally (SeInteractiveLogonRight)" }
					"SeNetworkLogonRight"			    { "Access this computer from the network (SeNetworkLogonRight)" }
					"SeRemoteInteractiveLogonRight"	    { "Allow log on through Remote Desktop Services (SeRemoteInteractiveLogonRight)" }
					"SeServiceLogonRight"			    { "Log on as a service (SeServiceLogonRight)" }
					Default 							{ "($right)" }
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
				Write-Verbose "$userType ($Username) SID: $sid"
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
			
			if ($VerbosePreference.value__ -eq 0)
			{
				Write-Verbose "The script will not delete the following paths due to running in verbose mode, please remove these files manually if needed:"
				Write-Verbose "`$import : $import"
				Write-Verbose "`$export : $export"
				Write-Verbose "`$secedt : $secedt"
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
	if ($ComputerName -or $Username -or $UserRight -or $RemoveRight)
	{
		foreach ($user in $Username)
		{
			Set-UserRights -ComputerName $ComputerName -Username $user -UserRight $UserRight -AddRight:$AddRight -RemoveRight:$RemoveRight
		}
	}
	else
	{
		
	 <# Edit line 500 to modify the default command run when this script is executed.
	   
		Example:
	        Set-UserRights -AddRight -UserRight SeServiceLogonRight, SeBatchLogonRight -ComputerName $env:COMPUTERNAME, SQL.contoso.com -UserName CONTOSO\User1, CONTOSO\User2
	        or
	        Set-UserRights -AddRight -UserRight SeBatchLogonRight -Username S-1-5-11
			or
			Set-UserRights -AddRight -UserRight SeServiceLogonRight, SeBatchLogonRight -Username Administrators
	        or
	        Set-UserRights -RemoveRight -UserRight SeBatchLogonRight -Username CONTOSO\User2
	        or
	        Set-UserRights -RemoveRight -UserRight SeServiceLogonRight, SeBatchLogonRight -Username CONTOSO\User1
	   #>
		Set-UserRights -AddRight -UserRight SeServiceLogonRight -Username Administrators -Verbose
	}
}
END
{
	Write-Output "$(Time-Stamp)Script Completed!"
}
