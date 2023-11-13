<#
.SYNOPSIS
    Invoke-SCXWinRMEnumeration - Enumerates various SCX (System Center Cross Platform) classes on specified servers using Windows Remote Management (WinRM).

.DESCRIPTION
    This script is designed to enumerate a set of SCX classes on one or more servers using WinRM. It supports both Basic and Kerberos authentication methods. The script is useful for querying and collecting information from remote servers about various system components like disk drives, filesystems, memory, processors, etc.

.PARAMETER Servers
    An array of server names or IP addresses on which the SCX class enumeration will be performed. This parameter is mandatory.

.PARAMETER Username
    The username to be used for authentication on the target server(s). It is not mandatory, but if specified without a password, the script will prompt for the password.

.PARAMETER Password
    The password for the provided username. If the Basic authentication method is chosen, the password is mandatory.

.PARAMETER AuthenticationMethod
    The authentication method to be used. Valid options are "Basic" and "Kerberos". The default is "Basic". If Kerberos is chosen, ensure that Kerberos tickets are available or the Kerberos setup is appropriately configured.

.EXAMPLE
    PS> .\Invoke-SCXWinRMEnumeration.ps1 -Servers "Server1","Server2" -Username "admin" -Password "password" -AuthenticationMethod "Basic"
    This command enumerates SCX classes on Server1 and Server2 using Basic authentication with the provided username and password.

.EXAMPLE
    PS> .\Invoke-SCXWinRMEnumeration.ps1 -Servers "Server3" -Username "admin" -AuthenticationMethod "Kerberos"
    This command enumerates SCX classes on Server3 using Kerberos authentication. The script assumes Kerberos is configured and tickets are available.

.NOTES
    Author: Blake Drumm (blakedrumm@microsoft.com)
    Website: https://blakedrumm.com/
    Version: 1.0
    Created: November 13, 2023
    Requirements: PowerShell 5.0 or later, WinRM must be configured on the target server(s).

#>
param (
	[Parameter(Mandatory = $true)]
	[string[]]$Servers,
	[string]$Username,
	[string]$Password,
	[Parameter(Mandatory = $false)]
	[ValidateSet("Basic", "Kerberos")]
	[string]$AuthenticationMethod = "Basic"
)

function Invoke-SCXWinRMEnumeration
{
	param (
		[Parameter(Mandatory = $true)]
		[string[]]$Servers,
		[string]$Username,
		[string]$Password,
		[Parameter(Mandatory = $false)]
		[ValidateSet("Basic", "Kerberos")]
		[string]$AuthenticationMethod = "Basic"
	)
	
	if ($AuthenticationMethod -eq 'Basic' -and -NOT $Password)
	{
		Write-Warning "Missing the -Password parameter."
		break
	}
	
	$baseUri = "http://schemas.microsoft.com/wbem/wscim/1/cim-schema/2/"
	$cimNamespace = "?__cimnamespace=root/scx"
	
	$scxClasses = @(
		"SCX_Agent",
		"SCX_DiskDrive",
		"SCX_DiskDriveStatisticalInformation",
		"SCX_EthernetPortStatistics",
		"SCX_FileSystem",
		"SCX_FileSystemStatisticalInformation",
		"SCX_IPProtocolEndpoint",
		"SCX_LogFile",
		"SCX_MemoryStatisticalInformation",
		"SCX_OperatingSystem",
		"SCX_ProcessorStatisticalInformation",
		"SCX_StatisticalInformation",
		"SCX_UnixProcess",
		"SCX_UnixProcessStatisticalInformation",
		"SCX_Application_Server"
	)
	
	foreach ($ServerName in $Servers)
	{
		$endpoint = "https://$ServerName`:1270/wsman"
		
		foreach ($class in $scxClasses)
		{
			$uri = $baseUri + $class + $cimNamespace
			
			if ($AuthenticationMethod -eq "Basic")
			{
				$command = "winrm enumerate $uri -username:$Username -password:$Password -r:$endpoint -auth:Basic -skipCAcheck -skipCNcheck -skipRevocationcheck -encoding:utf-8"
			}
			elseif ($AuthenticationMethod -eq "Kerberos")
			{
				$command = "winrm enumerate $uri -r:$endpoint -username:$Username -password:$Password -auth:Kerberos -skipcacheck -skipcncheck -encoding:utf-8"
			}
			
			Invoke-Expression $command
		}
	}
}

if ($Servers -or $Username -or $Password -or $AuthenticationMethod)
{
	Invoke-SCXWinRMEnumeration -Servers $Servers -Username $Username -Password $Password -AuthenticationMethod:$AuthenticationMethod
}
else
{
	Invoke-SCXWinRMEnumeration
}
