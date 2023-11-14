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
    [string[]]$Servers,
    [string]$Username,
    [string]$Password,
    [Parameter(Mandatory = $false)]
    [ValidateSet("Basic", "Kerberos")]
    [string]$AuthenticationMethod = "Basic"
)
function Invoke-SCXWinRMEnumeration {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Servers,
        [string]$Username,
        [string]$Password,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic", "Kerberos")]
        [string]$AuthenticationMethod = "Basic"
    )

    if (-not $Password -and $AuthenticationMethod -eq 'Basic') {
        Write-Warning "Missing the -Password parameter for Basic authentication."
        return
    }

    foreach ($ServerName in $Servers) {
    $error.Clear()
        try {
            Invoke-WinRMEnumeration -ServerName $ServerName -AuthenticationMethod $AuthenticationMethod -Username $Username -Password $Password -ErrorAction Stop
        } catch {
            $e = $_.Exception
            $line = $_.InvocationInfo.ScriptLineNumber
            $msg = $e.Message
            $errorDetails = $_ | Select *

            Write-Warning "Caught Exception: $e"
            Write-Warning "Message: $msg"
        }

    }
}
if ($Servers -or $Username -or $Password)
{
    Invoke-SCXWinRMEnumeration -Servers $Servers -Username $Username -Password $Password -AuthenticationMethod $AuthenticationMethod
}
else
{
    # Usage example
    Invoke-SCXWinRMEnumeration -Servers 'rhel7-9.contoso-2019.com' -Username 'monuser' -Password 'Password1' -AuthenticationMethod 'Basic'
}
