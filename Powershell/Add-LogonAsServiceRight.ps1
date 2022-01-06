<#
.Synopsis
  Grant logon as a service right to the defined user.
.Parameter ComputerName
  Defines the name of the computer where the user right should be granted.
  Default is the local computer on which the script is run.
.Parameter Username
  Defines the Username under which the service should run.
  Use the form: domain\Username.
  Default is the user under which the script is run.
.Example
  Usage:
  .\Add-LogonAsServiceRight.ps1 -Username "domain\Username"
.Notes
  Originally found here: https://github.com/weloytty/QuirkyPSFunctions/blob/ab4b02f9cc05505eee97d2f744f4c9c798143af1/Source/Users/Grant-LogOnAsService.ps1
  I modified to my own needs: https://github.com/blakedrumm/SCOM-Scripts-and-SQL/edit/master/Powershell/Add-LogonAsServiceRight.ps1
#>
param (
	[array]$ComputerName,
	[array]$Username
)
BEGIN
{

	Write-Host '===================================================================' -ForegroundColor DarkYellow
	Write-Host '==========================  Start of Script =======================' -ForegroundColor DarkYellow
	Write-Host '===================================================================' -ForegroundColor DarkYellow
	
	$checkingpermission = "Checking for elevated permissions..."
	$scriptout += $checkingpermission
	Write-Host $checkingpermission -ForegroundColor Gray
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
		Write-Host $permissiongranted -ForegroundColor Green
	}
	
	Function Time-Stamp
	{
		$TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
		return "$TimeStamp - "
	}
}
PROCESS
{
	function Add-LogonAsServiceRight
	{
    param (
	    [array]$ComputerName = ("{0}.{1}" -f $env:ComputerName.ToLower(), $env:USERDNSDOMAIN.ToLower()),
	    [array]$Username = ("{0}\{1}" -f $env:USERDOMAIN, $env:Username)
    )
		Invoke-Command -ComputerName $ComputerName -Script {
			param ([string]$Username)
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
				Write-Host ("$(Time-Stamp)Granting SeServiceLogonRight to user account: {0} on host: {1}." -f $Username, $env:ComputerName)
				$sid = ((New-Object System.Security.Principal.NTAccount($Username)).Translate([System.Security.Principal.SecurityIdentifier])).Value
				secedit /export /cfg $export | Out-Null
                #Change the below to any right you would like
				$sids = (Select-String $export -Pattern "SeServiceLogonRight").Line
				foreach ($line in @("[Unicode]", "Unicode=yes", "[System Access]", "[Event Audit]", "[Registry Values]", "[Version]", "signature=`"`$CHICAGO$`"", "Revision=1", "[Profile Description]", "Description=GrantLogOnAsAService security template", "[Privilege Rights]", "$sids,*$sid"))
				{
					Add-Content $import $line
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
				Write-Host ("$(Time-Stamp)Failed to grant SeServiceLogonRight to user account: {0} on host: {1}." -f $Username, $ComputerName)
				$error[0]
			}
		} -ArgumentList $Username
	}
    if ($ComputerName -or $Username)
    {
	    foreach ($computer in $ComputerName)
        {
            foreach ($user in $Username)
            {
                Add-LogonAsServiceRight -ComputerName $computer -Username $user
            }
        }
    }
    else
    {
 <# Edit line 115 to modify the default command run when this script is executed.
   Example: 
   Add-LogonAsServiceRight -ComputerName -Username CONTOSO\Administrator, CONTOSO\User
   #>
        Add-LogonAsServiceRight -ComputerName MS01-2019, MS02-2019 -Username 'CONTOSO\Administrator', 'CONTOSO\User'
    }
}
END
{
	Write-Output "$(Time-Stamp)Script Completed!"
}
