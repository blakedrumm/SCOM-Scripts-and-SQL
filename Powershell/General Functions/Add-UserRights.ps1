<#
	.Synopsis
		Grant User Right(s) to defined user(s) and computer(s).
	
	.DESCRIPTION
		Add User Rights via Powershell.
	
	.Parameter ComputerName
		Defines the name of the computer where the user right should be granted. This can be multiple values, comma seperated.
		Default is the local computer on which the script is run.
	
	.Parameter Username
		Defines the Username under which the service should run. This can be multiple values, comma seperated.
		Use the form: domain\Username.
		Default is the user under which the script is run.
	
	.PARAMETER UserRight
		Defines the User Right you want to set. This can be multiple values, comma seperated.
		Name of the right you want to add to: SeServiceLogonRight
		There is no default for this argument

		Some (but not all) of the Options you can use:
			"Log on as a batch job (SeBatchLogonRight)"
			"Allow log on locally (SeInteractiveLogonRight)"
			"Access this computer from the network (SeNetworkLogonRight)"
			"Allow log on through Remote Desktop Services (SeRemoteInteractiveLogonRight)"
			"Log on as a service (SeServiceLogonRight)"
			"Deny log on as a batch job (SeDenyBatchLogonRight)"
			"Deny log on locally (SeDenyInteractiveLogonRight)"
			"Deny access to this computer from the network (SeDenyNetworkLogonRight)"
			"Deny log on through Remote Desktop Services (SeDenyRemoteInteractiveLogonRight)"
			"Deny log on as a service (SeDenyServiceLogonRight)"
	
	.Example
		Usage:
		Single Users
		Add User Right "Log on as a service" to CONTOSO\User:
		.\Add-UserRights.ps1 -Username CONTOSO\User -UserRight SeServiceLogonRight
		
		Add User Right "Log on as a batch job" to CONTOSO\User:
		.\Add-UserRights.ps1 -Username CONTOSO\User -UserRight SeBatchLogonRight
		
		Add User Right "Allow log on locally" to current user:
		.\Add-UserRights.ps1 -UserRight SeInteractiveLogonRight
		
		Multiple Users / Services / Computers
		Add User Right "Log on as a service" and "Log on as a batch job" to CONTOSO\User and run on, local machine and SQL.contoso.com:
		.\Add-UserRights.ps1 -UserRight SeServiceLogonRight, SeBatchLogonRight -ComputerName $env:COMPUTERNAME, SQL.contoso.com -UserName CONTOSO\User1, CONTOSO\User2
	
	.Notes
		Original Creator: Bill Loytty (weloytty)
		Based heavily on the script found here: https://github.com/weloytty/QuirkyPSFunctions/blob/ab4b02f9cc05505eee97d2f744f4c9c798143af1/Source/Users/Grant-LogOnAsService.ps1
		I modified to my own needs: https://github.com/blakedrumm/SCOM-Scripts-and-SQL/blob/master/Powershell/Add-UserRights.ps1
		
		My blog post: https://blakedrumm.com/blog/add-and-check-user-rights-assignment/#/
		
		Author: Blake Drumm (blakedrumm@microsoft.com)
		First Created on: January 5th, 2022
		Last Modified on: January 10th, 2022
#>
param
(
	[Parameter(Position = 0)]
	[Alias('computer')]
	[array]$ComputerName = ("{0}.{1}" -f $env:ComputerName.ToLower(), $env:USERDNSDOMAIN.ToLower()),
	[Parameter(Position = 1)]
	[Alias('user')]
	[array]$Username = ("{0}\{1}" -f $env:USERDOMAIN, $env:Username),
	[Parameter(Mandatory = $true,
			   Position = 2)]
	[ValidateSet('SeAssignPrimaryTokenPrivilege', 'SeAuditPrivilege', 'SeBackupPrivilege', 'SeBatchLogonRight', 'SeChangeNotifyPrivilege', 'SeCreateGlobalPrivilege', 'SeCreatePagefilePrivilege', 'SeCreateSymbolicLinkPrivilege', 'SeDebugPrivilege', 'SeDelegateSessionUserImpersonatePrivilege', 'SeImpersonatePrivilege', 'SeIncreaseBasePriorityPrivilege', 'SeIncreaseQuotaPrivilege', 'SeIncreaseWorkingSetPrivilege', 'SeInteractiveLogonRight', 'SeLoadDriverPrivilege', 'SeManageVolumePrivilege', 'SeNetworkLogonRight', 'SeProfileSingleProcessPrivilege', 'SeRemoteInteractiveLogonRight', 'SeRemoteShutdownPrivilege', 'SeRestorePrivilege', 'SeSecurityPrivilege', 'SeServiceLogonRight', 'SeShutdownPrivilege', 'SeSystemEnvironmentPrivilege', 'SeSystemProfilePrivilege', 'SeSystemtimePrivilege', 'SeTakeOwnershipPrivilege', 'SeTimeZonePrivilege', 'SeUndockPrivilege', IgnoreCase = $true)]
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
		$TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
		return "$TimeStamp - "
	}
}
PROCESS
{
	function Add-UserRights
	{
		param
		(
			[Parameter(Position = 0)]
			[Alias('computer')]
			[array]$ComputerName = ("{0}.{1}" -f $env:ComputerName.ToLower(), $env:USERDNSDOMAIN.ToLower()),
			[Parameter(Position = 1)]
			[Alias('user')]
			[array]$Username = ("{0}\{1}" -f $env:USERDOMAIN, $env:Username),
			[Parameter(Mandatory = $true,
					   Position = 2)]
			[ValidateSet('SeAssignPrimaryTokenPrivilege', 'SeAuditPrivilege', 'SeBackupPrivilege', 'SeBatchLogonRight', 'SeChangeNotifyPrivilege', 'SeCreateGlobalPrivilege', 'SeCreatePagefilePrivilege', 'SeCreateSymbolicLinkPrivilege', 'SeDebugPrivilege', 'SeDelegateSessionUserImpersonatePrivilege', 'SeImpersonatePrivilege', 'SeIncreaseBasePriorityPrivilege', 'SeIncreaseQuotaPrivilege', 'SeIncreaseWorkingSetPrivilege', 'SeInteractiveLogonRight', 'SeLoadDriverPrivilege', 'SeManageVolumePrivilege', 'SeNetworkLogonRight', 'SeProfileSingleProcessPrivilege', 'SeRemoteInteractiveLogonRight', 'SeRemoteShutdownPrivilege', 'SeRestorePrivilege', 'SeSecurityPrivilege', 'SeServiceLogonRight', 'SeShutdownPrivilege', 'SeSystemEnvironmentPrivilege', 'SeSystemProfilePrivilege', 'SeSystemtimePrivilege', 'SeTakeOwnershipPrivilege', 'SeTimeZonePrivilege', 'SeUndockPrivilege', IgnoreCase = $true)]
			[Alias('right')]
			[array]$UserRight
		)
		foreach ($user in $Username)
		{
			foreach ($rights in $UserRight)
			{
				foreach ($computer in $ComputerName)
				{
					Invoke-Command -ComputerName $Computer -Script {
						param ([string]$Username,
							[Parameter(Mandatory = $true)]
							[array]$UserRight,
							[string]$ComputerName)
						Function Time-Stamp
						{
							$TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
							return "$TimeStamp - "
						}
						$tempPath = [System.IO.Path]::GetTempPath()
						$import = Join-Path -Path $tempPath -ChildPath "import.inf"
						if (Test-Path $import) { Remove-Item -Path $import -Force }
						$export = Join-Path -Path $tempPath -ChildPath "export.inf"
						if (Test-Path $export) { Remove-Item -Path $export -Force }
						$secedt = Join-Path -Path $tempPath -ChildPath "secedt.sdb"
						if (Test-Path $secedt) { Remove-Item -Path $secedt -Force }
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
								Write-Output ("$(Time-Stamp)Granting `"$UserLogonRight`" to user account: {0} on host: {1}." -f $Username, $ComputerName)
								$sid = ((New-Object System.Security.Principal.NTAccount($Username)).Translate([System.Security.Principal.SecurityIdentifier])).Value
								secedit /export /cfg $export | Out-Null
								#Change the below to any right you would like
								$sids = (Select-String $export -Pattern "$right").Line
								foreach ($line in @("[Unicode]", "Unicode=yes", "[System Access]", "[Event Audit]", "[Registry Values]", "[Version]", "signature=`"`$CHICAGO$`"", "Revision=1", "[Profile Description]", "Description=GrantLogOnAsAService security template", "[Privilege Rights]", "$sids,*$sid"))
								{
									Add-Content $import $line
								}
							}
							
							secedit /import /db $secedt /cfg $import | Out-Null
							secedit /configure /db $secedt | Out-Null
							gpupdate /force | Out-Null
							Remove-Item -Path $import -Force | Out-Null
							Remove-Item -Path $export -Force | Out-Null
							Remove-Item -Path $secedt -Force | Out-Null
						}
						catch
						{
							Write-Output ("$(Time-Stamp)Failed to grant `"$right`" to user account: {0} on host: {1}." -f $Username, $ComputerName)
							$error[0]
						}
					} -ArgumentList $user, $rights, $Computer
				}
			}
		}
		
	}
	if ($ComputerName -or $Username -or $UserRight)
	{
		foreach ($user in $Username)
		{
			Add-UserRights -ComputerName $ComputerName -Username $user -UserRight $UserRight
		}
	}
	else
	{
	 <# Edit line 209 to modify the default command run when this script is executed.
	   Example: 
	   Add-UserRights -UserRight SeServiceLogonRight, SeBatchLogonRight -ComputerName $env:COMPUTERNAME, SQL.contoso.com -UserName CONTOSO\User1, CONTOSO\User2
	   #>
		Add-UserRights
	}
}
END
{
	Write-Output "$(Time-Stamp)Script Completed!"
}
