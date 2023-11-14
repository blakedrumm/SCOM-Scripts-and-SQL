function Invoke-WinRMEnumeration {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ServerName,

        [Parameter(Mandatory=$true)]
        [string]$Username,

        [Parameter(Mandatory=$true)]
        [string]$Password,

        [Parameter(Mandatory=$false)]
        [ValidateSet("Basic", "Kerberos")]
        [string]$AuthenticationMethod = "Basic"
    )

    $baseUri = "http://schemas.microsoft.com/wbem/wscim/1/cim-schema/2/"
    $cimNamespace = "?__cimnamespace=root/scx"
    $endpoint = "https://$ServerName`:1270/wsman"
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

    foreach ($class in $scxClasses) {
        $uri = $baseUri + $class + $cimNamespace

        if ($AuthenticationMethod -eq "Basic") {
            $command = "winrm enumerate $uri -username:$Username -password:$Password -r:$endpoint -auth:Basic -skipCAcheck -skipCNcheck -skipRevocationcheck -encoding:utf-8"
        }
        elseif ($AuthenticationMethod -eq "Kerberos") {
            $command = "winrm e $uri -r:$endpoint -u:$Username -p:$Password -auth:Kerberos -skipcacheck -skipcncheck -encoding:utf-8"
        }

        Invoke-Expression $command
    }
}

#Invoke-WinRMEnumeration -ServerName RHEL7-9.contoso-2019.com -Username test -Password Password1 -AuthenticationMethod Basic
