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

# Usage example
Invoke-SCXWinRMEnumeration -Servers 'rhel7-9.contoso-2019.com' -Username 'testuser' -Password 'Password1' -AuthenticationMethod 'Basic'
