<#
	.NOTE
	Name: SignCertManageNixAgent.ps1
	Author: Tyson Paul 
	Version History:
	2020.07.20 - Published online with a few additional comments.
	2017/07/xx - Initial version
	
	.Description
	NOTE: This script is intended to be customized by someone who has a basic understanding of PowerShell fundamentals. This can be automated with SCORCH or run from SCOM mgmt server. 
    Original Article: https://monitoringguys.com/2020/07/20/automated-linux-agent-deployment-for-scom/

  This script is intended to run on an System Center Orchestrator Runbook server but CAN be run entirely on SCOM mgmt server by specifying 'localhost' as the $mgmtserver variable. 
  Launch this script as the "automation" RunAs account with the -CreatePassword switch to prompt for the service account password. This password will get encrypted and stored in the $SCOMFolder path. 
  The password file contents can only be decrypted when this script is launched as the automation service account which created the password. 

	This script will construct a sriptblock which *may* get remotely executed on the SCOM management server. 
	The scriptblock will make use of the WinSCP .NET assembly (on the machine designated as the $mgmtserver) to do the following:
  Connect to the target nix machine via SSH on the designated port.
  Make a copy of the original PEM cert file.
  Copy the original PEM cert file locally; from the nix agent to the SCOM mgmt server. A backup copy of the original is made/stored locally.
  Sign the cert with SCXCertconfig.exe utility. 
  Upload the signed cert to the nix server, replacing the original PEM file. A copy of the original cert will exist locally AND on the target nix server.
  Then initiate management of the nix server by the SCOM management group.


  REQUIREMENT 1: This WinSCP PowerShell module is required on the designated $mgmtserver: https://www.powershellgallery.com/packages/WinSCP/5.9.6.0
  
  REQUIREMENT 2: This PSPKI (NOT "PKI") Module is required wherever THIS script is launched from (SCORCH or SCOM server): https://pspki.codeplex.com/releases/view/625365
	Vadims Podāns Blog: https://www.sysadmins.lv/blog-en/powershell-pki-module-v326-is-out.aspx


#>


Param(
	# If the script is run with this parameter, it will set the encrypted service account password to file, then exit.
    [switch]$CreatePassword = $False,
    [int]$WriteToEventLog=0
)

# CONFIGURE THESE MANUALLY FOR YOUR ENVIRONMENT
$SCOMFolder = "C:\SCOMNixAgentDeploy" # Local resource folder on server where this script will be launched.
$NixServerCSVFileName = "NixTargets.csv"# CSV has two columns: ServerDNSName,Port. Put target server names in this file
$NixAgentTargetFilePath = (Join-Path $SCOMFolder $NixServerCSVFileName) 
$LocalSigningFolderPath = $SCOMFolder    #Path on remote SCOM mgmt server where nix certs will be stored temporarily while being signed
$mgmtserver = 'LOCALHOST' # SCOM management server FQDN. Use "localhost" if running this entirely from SCOM mgmt server.
$scomaccountname = 'ENTER_SCOM_ACCOUNT_HERE' # Account to be used to SSH to nix server; retrieve cert file, rename original remotely, then upload signed cert back to nix server. 
$SCOMDeployLogPath = (Join-Path $SCOMFolder "DeploymentLog.txt" )  # Local log file on server where this script will be launched.
$passwdfile = "scomaccount_passwd.txt" # This will be located in your $SCOMFolder path above
$NixResourcePoolName = 'Nix Resource Pool'  # If you have only one Unix/Linux resource pool, enter it here. Otherwise you should customize the Get-NixResourcePoolName function below instead and comment this line out.

#$WriteToEventLog = 2
[int]$info=0
[int]$warn=2
[int]$critical=1




# UNCOMMENT BELOW FOR TESTING ONLY
<#
 $scomaccountname = "tpaul"  # SCOM action account for nix discovery and monitoring. Unprivileged, SSH enabled
 $mgmtserver = 'ms02.contoso.com'
 $scomaccountname = "tpaul"  # SCOM action account for nix discovery and monitoring. Unprivileged, SSH enabled
 #$NixResourcePoolName =  "CSMC UNIX/Linux Monitoring Resource Pool"
 $NixResourcePoolName = 'Nix Resource Pool'
 $WriteToEventLog=2
 #$TargetServerDNSName = "NIX01"
 $Port = 22
#>



$setupKey = Get-Item -Path "HKLM:\Software\Microsoft\System Center Operations Manager\12\Setup"
$installDirectory = $setupKey.GetValue("InstallDirectory") | Split-Path
# Make sure the Opsman PowerShell module gets loaded correctly
$psmPath = (Join-Path $installdirectory 'Operations Manager\Powershell\OperationsManager\OperationsManager.psm1')
Import-Module $psmPath
Import-Module pspki

#------------------------------------
Function LogIt {
Param (
    $EventID = 9990,
    [int]$EntryType = 2,
    $Message = "No message provided. Check the script logging statement for supplied message data.",
    [int]$Proceed = 2
)

    If ($Proceed) {
        $TimeStamp = (get-date -format "yyyy-MM-dd-HHmmss")
        $output = @($TimeStamp,"",$Message)

        If ($Proceed -gt 1) {
            $output += @"


Any Errors: 
-------- Begin Error Data ---------
$Error
-------- End  Error  Data ---------


"@

        }
  		$oEvent = New-Object -comObject 'MOM.ScriptAPI'
		$oEvent.LogScriptEvent("SignCertManageAgent.ps1",$EventID,$EntryType,$output)
    # Regardless of level 1 or greater, will write to log if greater than 0 (0=off/no logging)
    # Write-EventLog -LogName $LogName -Source $Source -EventID $EventID -EntryType $EntryType -Message $Message
    }
}
#------------------------------------

#Here's the encryption function for reference. 
Function encrypt-envelope ($unprotectedcontent, $cert) {
    [System.Reflection.Assembly]::LoadWithPartialName("System.Security") | Out-Null
    $utf8content = [Text.Encoding]::UTF8.GetBytes($unprotectedcontent)
    $content = New-Object Security.Cryptography.Pkcs.ContentInfo -argumentList (,$utf8content)
    $env = New-Object Security.Cryptography.Pkcs.EnvelopedCms $content
    $recpient = (New-Object System.Security.Cryptography.Pkcs.CmsRecipient($cert))
    $env.Encrypt($recpient)
    $base64string = [Convert]::ToBase64String($env.Encode())
    return $base64string
}
#------------------------------------
Function decrypt-envelope ($base64string) {
    [System.Reflection.Assembly]::LoadWithPartialName("System.Security") | Out-Null
    $content = [Convert]::FromBase64String($base64string)
    $env = New-Object Security.Cryptography.Pkcs.EnvelopedCms
    $env.Decode($content)
    $env.Decrypt()
    $utf8content = [text.encoding]::UTF8.getstring($env.ContentInfo.Content)
    return $utf8content
}
#------------------------------------
Function Create-SCXSSHCredential {
Param(
    [string]$scomaccountname,
    [string]$Passphrase
)

    $SSHCredential = ""
    $scred = ""
    $SSHCredential = New-Object Microsoft.SystemCenter.CrossPlatform.ClientLibrary.CredentialManagement.Core.CredentialSet
    $scred = New-Object Microsoft.SystemCenter.CrossPlatform.ClientLibrary.CredentialManagement.Core.PosixHostCredential
    $scred.Usage = 2

    $scred.PrincipalName = $scomaccountname

  
    $sPassphrase = ConvertTo-SecureString $Passphrase -AsPlainText -Force    
    $scred.Passphrase = $sPassphrase
    #add posixhost credential to credential set
    $SSHCredential.Add($scred)

    $sudocred = New-Object Microsoft.SystemCenter.CrossPlatform.ClientLibrary.CredentialManagement.Core.PosixHostCredential
    $sudocred.Usage = 16 #sudo elevation
    $SSHCredential.Add($sudocred)
    Return $SSHCredential
}
#------------------------------------
Function Create-SSHCredWinSCP {
Param(
    [string]$scomaccountname,
    [string]$Passphrase
)

    $SecurePassphrase = $Passphrase | ConvertTo-SecureString -AsPlainText -Force
    $WSCredential = New-Object System.Management.Automation.PSCredential ($scomaccountname, $SecurePassphrase)
    Return $WSCredential
}
#------------------------------------

# This is useful when more than one nix resource pool exists
<#
Function Get-NixResourcePoolName {
Param(
    [string]$TargetName
)
 This is for a specific customer. Set the regex as you see fit.
    If ($TargetName -match "^az[tdp]") {
        # Backup datacenter location resource pool
        $name = "UNIX/Linux DC2 Monitoring Resource Pool"
    }
    Else {
        # Standard resource pool
        $name = "UNIX/Linux Monitoring Resource Pool"
    }

    Return $name
}
#>
#------------------------------------


# SCRIPTBLOCK
#==================================
# This scriptblock exists so that you can run this script from a SCORCH server. If running this script from a SCOM management server, simply use "localhost" for the $mgmtserver variable above.
#region SCRIPTBLOCK
$ScriptBlock = {

Param (
    [string]$LocalSigningFolderPath,
    [System.Management.Automation.PSCredential]$NixCredential,
    [int]$Port = 22,
    [string]$NixResourcePoolName,
    $LocalCertSigningToolPath = "",  #not required
    [string]$TargetServerDNSName = '',
    [int]$WriteToEventLog = 0
)


[int]$info=0
[int]$warn=2
[int]$critical=1
$Transcript = @()
$Message = @()
$BackupFolderName = "OriginalCerts"
$SignedFolderName = "Signed"
$CertSignTool = 'scxcertconfig.exe'

Function LogIt {
Param (
    $EventID = 9990,
    [int]$EntryType = 2,
    $Message = "No message provided. Check the script logging statement for supplied message data.",
    [int]$Proceed = 2
)

    If ($Proceed) {
        $TimeStamp = (get-date -format "yyyy-MM-dd-HHmmss")
        $output = @($TimeStamp,"",$Message)

        If ($Proceed -gt 1) {
            $output += @"

TargetServerDNSName:[$($TargetServerDNSName)]
Port:[$($Port)]


Any Errors: 
-------- Begin Error Data ---------
$Error
-------- End  Error  Data ---------


"@

        }
  		$oEvent = New-Object -comObject 'MOM.ScriptAPI'
		$oEvent.LogScriptEvent("SignCertManageAgent.ps1",$EventID,$EntryType,$output)
    # Regardless of level 1 or greater, will write to log if greater than 0 (0=off/no logging)
    # Write-EventLog -LogName $LogName -Source $Source -EventID $EventID -EntryType $EntryType -Message $Message
    }
}

try{
    Import-Module WinSCP
}catch {
    $Transcript += @"

WinSCP module not found. Aborting.
"@
    LogIt -Message $Transcript -Proceed $WriteToEventLog -EventID 9998 -EntryType $critical
}

# Create folder to store certs while signing
New-Item -ItemType Directory -Path $LocalSigningFolderPath -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path (Join-Path $LocalSigningFolderPath $BackupFolderName) -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path (Join-Path $LocalSigningFolderPath $SignedFolderName) -Force -ErrorAction SilentlyContinue

try{
    # Create a WinSCP Session without using host key fingerprint.
    # -SshHostKeyFingerprint "ssh-rsa 2048 xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx"
    $Session = New-WinSCPSession -Hostname $TargetServerDNSName -Credential $NixCredential -Protocol Sftp -GiveUpSecurityAndAcceptAnySshHostKey
}
Catch {
    $Message = "Failed to establish connection to target server. Aborting."
    Write-Host $Message
    LogIt -EventID 9999 -EntryType $critical -Message $Message -Proceed $WriteToEventLog
}

# Might have to use 'realpath' instead
$Command = 'readlink -f /etc/opt/microsoft/scx/ssl/scx.pem'
$Response = (Invoke-WinSCPCommand -WinSCPSession $Session -Command $Command)
$CertFileRemotePath = $Response.Output
$Transcript += @"

Session:[$([bool]$Session)]
Command:[$($Command)]
Response.Output:[$($Response.Output)]
Response.ErrorOutput:[$($Response.ErrorOutput)]
CertFileRemotePath:[$($CertFileRemotePath)]
Errors:
$Error
"@

# If problem exists it is likely because readlink is not available (AIX/Unix).
# Try to locate the cert the hard way
If ($Response.ExitCode -ne 0){
    $TargetNixHostname = (Invoke-WinSCPCommand -WinSCPSession $Session -Command 'hostname').Output
    $Pattern1 = '/etc/opt/microsoft/scx/ssl/*.pem ! -name *signed*'
    $Response = (Invoke-WinSCPCommand -WinSCPSession $Session -Command "find $Pattern1 | grep $($TargetNixHostname.ToLower())")
    If ($Response.Output -match "pem"){
        $CertFileRemotePath = $($Response.Output)
    }
    Else {     # Assume cert is in newer omi path, attempt to confirm location
        $Pattern2 = '/etc/opt/omi/ssl/*.pem ! -name *signed'
        $Response = (Invoke-WinSCPCommand -WinSCPSession $Session -Command "find $Pattern2 | grep $($TargetNixHostname.ToLower())")
        If ($Response.Output -match "pem"){
            $CertFileRemotePath = $($Response.Output)
        }
        Else {
            $Transcript += @"

    Something went wrong trying to locate the CertFileRemotePath.
    Searched for cert file with these two commands: 
    1)find $Pattern1 | grep $($TargetNixHostname.ToLower())
    2)find $Pattern2 | grep $($TargetNixHostname.ToLower())
"@
            LogIt -EventID 9998 -EntryType $critical -Message $Transcript -Proceed $WriteToEventLog
        }
    }
}

#in theory this conditional statement should never be true. 
If ( -not($CertFileRemotePath -like "*.pem*")) {
    #indicates problem with cert file path. Abort.
    $Transcript += @"

Problem with cert file path. Does not contain '.pem': [$($CertFileRemotePath)]. Aborting.
"@
    LogIt -EventID 9997 -EntryType $critical  -Message $Transcript -Proceed $WriteToEventLog
}

# Make backup of original cert file on remote nix server
$CertFileName = (Split-Path -Leaf $CertFileRemotePath)
$CertFileBackupRemotePath = $CertFileRemotePath + ".orig"
$Command = "cp -n $CertFileRemotePath $CertFileBackupRemotePath"
$Response = (Invoke-WinSCPCommand -WinSCPSession $Session -Command $Command)
$Transcript += @"

Copy Command:[$($Command)]
Response.Output:[$($Response.Output)]
Response.ErrorOutput:[$($Response.ErrorOutput)]
"@

If ($Response.IsSuccess -ne "True"){
    $Transcript += "Problem with duplicating cert file. Response : [$($Response)]. Aborting"
    LogIt -EventID 9999 -EntryType $critical  -Message $Transcript -Proceed $WriteToEventLog
}

$Transcript += @"

Made a backup copy of remote file: $CertFileRemotePath
Backup location: $CertFileBackupRemotePath

"@


# Using the WinSCPSession, download the file from the remote host to the local host.
Receive-WinSCPItem -WinSCPSession $session -Path $CertFileRemotePath -Destination $LocalSigningFolderPath
If ($Response.IsSuccess -ne "True"){
    $Transcript += @"

Problem with retrieving cert file. Response : [$($Response)]. Aborting.
"@
    LogIt -EventID 9999 -EntryType $critical  -Message $Transcript -Proceed $WriteToEventLog
}
$Transcript += @"

Retrieved remote file: $CertFileRemotePath
Saved local:$LocalSigningFolderPath
"@

# Create backup of original cert locally
Copy-Item -Path (Join-Path $LocalSigningFolderPath $CertFileName) -Destination (Join-Path $LocalSigningFolderPath $BackupFolderName)
If ($?) {
    $Transcript += @"

Created backup of original cert [$($CertFileName)] into folder: $(Join-Path $LocalSigningFolderPath $BackupFolderName)
"@
}

# Get the install path for the SCOM bits on the mgmt server.
$setupKey = Get-Item -Path "HKLM:\Software\Microsoft\Microsoft Operations Manager\3.0\Setup"
$installDirectory = $setupKey.GetValue("InstallDirectory") | Split-Path
# Make sure the Opsman PowerShell module gets loaded correctly
$psmPath = $installdirectory + '\Powershell\OperationsManager\OperationsManager.psm1'
Import-Module $psmPath
If (-not($?)) {
    $Transcript += @"

Problem importing SCOM Posh module, path:[$($psmPath)]. Aborting. 
"@
    LogIt -EventID 9999 -EntryType $critical -Message $Transcript -Proceed $WriteToEventLog
}

New-SCOMManagementGroupConnection -ComputerName 'Localhost'
If (-not($?)) {
    $Transcript += @"

Problem connecting to scom mgmtgroup on 'localhost'. Aborting. 
"@
    LogIt -EventID 9999 -EntryType $critical -Message $Transcript -Proceed $WriteToEventLog
}

$NixResourcePool = Get-SCOMResourcePool -DisplayName $NixResourcePoolName
If (-not($?)) {
    $Transcript += @"

Problem getting NixResourcePool from pool display name. Aborting. 
NixResourcePoolName:[$($NixResourcePoolName)]
NixResourcePool:[$($NixResourcePool)]
"@
    LogIt -EventID 9999 -EntryType $critical -Message $Transcript -Proceed $WriteToEventLog
}

If (-not ($LocalCertSigningToolPath)){
    $LocalCertSigningToolPath = (Join-Path (Join-Path $installDirectory "Server" -Resolve) $CertSignTool)
    $Transcript += @"

Set LocalCertSigningToolPath: [$($LocalCertSigningToolPath)]. 
"@
}
Else{
    $Transcript += @"

LocalCertSigningToolPath: [$($LocalCertSigningToolPath)]. 
"@
}

If (-not(Test-Path $LocalCertSigningToolPath -PathType Leaf)) {
    $Transcript += @"

Problem with path to cert signing tool: [$($LocalCertSigningToolPath)]. Aborting.
"@
    LogIt -EventID 9999 -EntryType $critical  -Message $Transcript -Proceed $WriteToEventLog
}

# If signed cert file already exists, remove it.
Remove-Item -Path (Join-Path (Join-Path $LocalSigningFolderPath $SignedFolderName) $CertFileName) -Recurse -Force -ErrorAction SilentlyContinue

# Sign the cert, storing it into the "signed" folder. 
$SignResult = & $LocalCertSigningToolPath -sign (Join-Path $LocalSigningFolderPath $CertFileName) (Join-Path (Join-Path $LocalSigningFolderPath $SignedFolderName) $CertFileName)

If (-not(Test-Path (Join-Path (Join-Path $LocalSigningFolderPath $SignedFolderName) $CertFileName))) {
    $Transcript += @"

Problem signing cert. Cert not in expected location:[$((Join-Path (Join-Path $LocalSigningFolderPath $SignedFolderName) $CertFileName))]. Aborting."
Signing result:[$($SignResult)]
"@
    LogIt -EventID 9999 -EntryType $critical -Message $Transcript -Proceed $WriteToEventLog
}
Else {
    $Message = @"

Cert signing successfull! :[$((Join-Path (Join-Path $LocalSigningFolderPath $SignedFolderName) $CertFileName))]."
Signing result:[$($SignResult)]
"@
    $Transcript += $Message
    LogIt -EventID 9990 -EntryType $info -Message $Message -Proceed $WriteToEventLog
}

# Remove the original cert from remote nix server
# Make sure original cert is backed up locally; original remote cert file path is correct before attempting to remove.
If ( ($CertFileRemotePath -like "*$TargetNixHostname*.pem") `
        -and (Test-Path -PathType Leaf (Join-Path (Join-Path $LocalSigningFolderPath $BackupFolderName) $CertFileName)) `
        -and (Test-WinSCPPath -Path $CertFileBackupRemotePath -WinSCPSession $Session) `
) {
    $Response = (Invoke-WinSCPCommand -WinSCPSession $Session -Command "rm -rf $CertFileRemotePath")
}
Else {
    $Transcript += @"

Before removing original cert from remote nix server, problem with verification: 'remote cert file path is correct, original cert is backed up locally and remotely'. Aborting.
CertFileRemotePath:[$($CertFileRemotePath)]
CertFileBackupRemotePath:[$($CertFileBackupRemotePath)]
CertBackupFilePath:[$((Join-Path (Join-Path $LocalSigningFolderPath $BackupFolderName) $CertFileName))]
"@
    LogIt -EventID 9999 -EntryType $critical -Message $Transcript -Proceed $WriteToEventLog
}

# Copy the signed cert back to the target nix server
# Permissions issues may exist with this cmdlet below. 
Send-WinSCPItem -WinSCPSession $session -Path (Join-Path (Join-Path $LocalSigningFolderPath $SignedFolderName) $CertFileName) -Destination $CertFileRemotePath

# Alternative to Send-WinSCPItem could be sudo cat contents of pem to remote file. 

# Remove the WinSCPSession after completion.
Remove-WinSCPSession -WinSCPSession $session


} 
#endregion SCRIPTBLOCK 
# =======================================================================================

If ( -not($cert = ( Get-ChildItem 'Cert:\CurrentUser\My'  | Where-Object {$_.Subject -like "*GenericEncryptionCert*"}  | Select-Object -First 1 ))) {
    # Create new generic cert for encryption in the user personal store
    # $cert = New-SelfSignedCertificate -Type DocumentEncryptionCertLegacyCsp -DnsName 'GenericEncryptionCert' -HashAlgorithm SHA256 -CertStoreLocation 'Cert:\CurrentUser\My'
    $cert = New-SelfSignedCertificateEx -KeyUsage DataEncipherment -AlgorithmName RSA -Subject 'CN=GenericEncryptionCert' -StoreLocation CurrentUser -FriendlyName 'SCOMNixDeploymentPasswdEncryption'
}

# If this switch is used, will prompt user for scomaccount password to be stored encrypted in the desigated file path. Then exit.
# You would run this as the "runas" SCORCH service account so that only the service account can decrypt the password at a future time.
If ($CreatePassword) {
    If (-not(Test-Path $SCOMFolder )) { New-Item -Path $SCOMFolder -ItemType Directory -Force}
    Set-Content -Path (Join-Path $SCOMFolder $passwdfile) -Value (encrypt-envelope (Read-Host "Enter password to encrypt. ( Saved to $(Join-Path $SCOMFolder $passwdfile) ) " ) $cert ) -Force

    #CLS
    Write-Host "Password Saved to " -NoNewline -F Green; Write-Host "$(Join-Path $SCOMFolder $passwdfile)" -ForegroundColor Yellow
    Read-Host "Press any key to exit..."
    Exit
}


############   NEAL SMITH    ###################
# Use PowerSCCM cmdlets to get the nix server names. 
# https://github.com/PowerShellMafia
# Use this to store the collection/array of servers names from SCCM

# $arrSCCMNixServers = Whatever cmdlet to get server names

New-SCOMManagementGroupConnection -ComputerName $mgmtserver
$Targets = (Get-SCXAgent ).name

$Targets = (Compare-Object $arrSCCMNixServers $Targets).InputObject

# Import list of targets from csv file
#$Targets = Import-Csv -Path $NixAgentTargetFilePath
If ( (-not($?)) -or ($Targets.Count -eq 0) ) {
    $Message = "No Targets exist or invalid path to target file: $NixAgentTargetFilePath"
    Write-Error $Message
    $Message | Out-File -FilePath $SCOMDeployLogPath -Append
}

#region TargetsExist
Else {
    # SCOM folder and encrypted password file must already exist at this point.
    $NixCredential1 = Create-SSHCredWinSCP -Passphrase (decrypt-envelope (Get-Content (Join-Path $SCOMFolder $passwdfile))) -scomaccountname $scomaccountname
    $NixCredential2 = Create-SCXSSHCredential -Passphrase (decrypt-envelope (Get-Content (Join-Path $SCOMFolder $passwdfile))) -scomaccountname $scomaccountname


ForEach ($Target in $Targets) {
    If (Test-Connection -ComputerName $Target.ServerDNSName -Quiet ) {
        If ( -not($NixResourcePoolName) ) { 
            $NixResourcePoolName = Get-NixResourcePoolName -TargetName $Target.ServerDNSName 
        }
        $Result = Invoke-Command -ComputerName $mgmtserver -ScriptBlock $ScriptBlock -ArgumentList $LocalSigningFolderPath, $NixCredential1, $Target.Port, $NixResourcePoolName, $false, $Target.ServerDNSName, $WriteToEventLog

        If ($Result) {
            #New-SCOMManagementGroupConnection -ComputerName $mgmtserver
            $NixResourcePool = Get-SCOMResourcePool -DisplayName $NixResourcePoolName
            $DiscoveryResult = Invoke-SCXDiscovery  -Name $Target.ServerDNSName -ResourcePool $NixResourcePool -SshCredential $NixCredential2 -WsManCredential $NixCredential1

            #TEST
            #$NixResourcePool = Get-SCOMResourcePool -DisplayName "Nix Resource Pool"
            #$DiscoveryResult = Invoke-SCXDiscovery  -Name "nix01" -ResourcePool $NixResourcePool -SshCredential $NixCredential2 -WsManCredential $NixCredential1
            #TEST

            If ($DiscoveryResult.Succeeded) {
                # If target is successfully discovered (as a valid target), proceed to "manage" it.
                $InstallResult =''
                $InstallResult = $DiscoveryResult | Install-SCXAgent
                $Transcript += @"

            Discovery Result:
            HostName:$($DiscoveryResult.HostName), Succeeded:$($DiscoveryResult.Succeeded), ErrorData:$($DiscoveryResult.ErrorData)

            Install Result:
            $($InstallResult | Select-Object *) 

"@
            # If result object exists, assume success. Failure usually results in nothing/null
            If ($InstallResult) {
                # Log to "Success" file
                $Target | Export-Csv -Path ($NixAgentTargetFilePath + "_SUCCESS.CSV") -Append
                LogIt -Message "Successful Install:$($Target.ServerDNSName) " -Proceed $WriteToEventLog -EventID 9990 -EntryType $info
                # Remove successful targets from the array.
                $Targets = $Targets | Where-Object {$_.ServerDNSName -ne $Target.ServerDNSName}
            }

            }
            Else {

                $Transcript += @"

            FAILURE. Discovery Result:
            TargetServerDNSName:$($Target.ServerDNSName)
            NixResourcePool.DisplayName:[$($NixResourcePool.DisplayName)]
            NixCredential.UserName:[$($nixcredential.UserName)]

            HostName:$($DiscoveryResult.HostName), Succeeded?:$($DiscoveryResult.Succeeded), ErrorData:$($DiscoveryResult.ErrorData)
"@
            }
        }
        # No Discovery result
        Else {
            $Message = "No Discovery Result! Target.ServerDNSName:$($Target.ServerDNSName)"
            $Transcript += @"

    $Message

"@
            # Export failed target object (info) to CSV
            $Target | Export-Csv -Path ($NixAgentTargetFilePath + "_FAILED.CSV") -Append
            LogIt -Message $Message  -Proceed 2 -EventID 9998 -EntryType $critical
        }
            (Get-Date) | Out-File -FilePath $SCOMDeployLogPath -Append
            $Transcript | Out-File -FilePath $SCOMDeployLogPath -Append
    } # Not Reacheable

    Else {
            $Transcript += @"

    ERROR: $($Target.ServerDNSName) not reachable. Check ServerDNSName, make sure SCORCH server can resolve name to IP

"@
    }
} #End Foreach

}
#endregion TargetsExist

<#
Rename-Item $NixAgentTargetFilePath  -NewName ((Split-Path $NixAgentTargetFilePath -Leaf)+"_OLD_"+ ("{0:yyyy}{0:MM}{0:dd}_{0:HH}{0:mm}{0:ss}" -f (Get-Date)) ) -Force
# If targets remain in the array then it implies that at least one deployment was not successful and those server names shall remain in the target file.
If ($Targets){
    $Targets | Export-Csv -Path $NixAgentTargetFilePath -Force
}
#>


