<#
    .SYNOPSIS
        This script was designed to help with forcibly removing the SCOM Agent.

    .DESCRIPTION
        If there are issues in removing the SCOM Agent, this script may be able to help forcibly remove the application from the server.
        Commands and references used in the script are taken from a SCOM 2019 agent installation and may be different in other versions.

        This is not 100% foolproof nor does it guarantee complete removal of all components, the intent is to remove as many _obvious_ references
        as possible so that the machine is no longer recognized to have an agent installed, or had one previously.

        This script will attempt to remove all registered services, performance counters, DLLs, and program files. This script makes direct deletions
        from the registry and file system.

        One external file is REQUIRED: RegistryKeys.txt

    .NOTES
        This script assumes:
            - You are running this script as an Administrator
            - You have exhausted other options for agent removal
            - You have a full backup/snapshot/etc. of this machine and the registry in particular
            - You assume all responsibility for what happens when you run this script - USE AT YOUR OWN RISK
            - The creator and Microsoft is not liable for any damage or loss done with this script
            - You have vetted the validity of this script and is approved to use in your environment
    
    .NOTICE
        By using this script, you in no way hold the author or Microsoft responsible for any damage or loss occured to the systems it is run on.
        You agree to have validated the script in its entirety and vetted it to be safe to use, assuming all responsibility for any ensuing issues.

    .AUTHOR
        Lorne Sepaugh (lornesepaugh@microsoft.com)
#>

Start-Transcript -Path $PSScriptRoot\MMAgentUninstallLog.txt
Write-Host "Beginning removal of the Microsoft Monitoring Agent`n"

# Get Agent Installation Path
$installDirectory = (Get-ItemPropertyValue -Path Registry::'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup' -Name InstallDirectory).TrimEnd('\')
$installDateTime = Get-ItemPropertyValue -Path Registry::'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup' -Name InstalledOn
If ($null -eq $installDirectory) { $installDirectory = "C:\Program Files\Microsoft Monitoring Agent\Agent" }

# Check Installed Agent Version if available (GUIDs obtained from the 'ProductCode' property of the MSI installer)
$productGUIDs = @(
    [pscustomobject]@{Version='SCOM 2012R2'; GUID='{786970C5-E6F6-4A41-B238-AE25D4B91EEA}'},
    [pscustomobject]@{Version='SCOM 2016';   GUID='{742D699D-56EB-49CC-A04A-317DE01F31CD}'},
    [pscustomobject]@{Version='SCOM 2019';   GUID='{CEB9E45B-2152-4C10-A022-0825B53B632F}'},
    [pscustomobject]@{Version='Azure';       GUID='{88EE688B-31C6-4B90-90DF-FBB345223F94}'}
)

$installedVersion = "none"
$installedGUID = "none"

$productGuids | ForEach-Object {
    If (Test-Path Registry::HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($_.GUID) ) {
        $installedVersion = $_.Version
        $installedGUID = $_.GUID
    } 
}

Write-Host "`nAgent Version Installed: $installedVersion`nGUID: $installedGUID`nInstallationPath: $installDirectory`nInstalledOn: $installDateTime`n"


<#############################

Stop Services, attempt MSI Uninstall

#############################>

# Stop MMA Services
Write-Information "Stopping Services"
Stop-Service "HealthService" -ErrorAction SilentlyContinue -Verbose
Stop-Service "AdtAgent" -ErrorAction SilentlyContinue -Verbose
Stop-Service "System Center Management APM" -ErrorAction SilentlyContinue -Verbose

# First, try to use the MSIExec to do the uninstall
If ($installedGUID -notlike "none") { 
    Write-Warning "Attempting to uninstall the agent with MSIEXEC first..."
    $param = "/qn /l*v $($PSScriptRoot)/MSIuninstaller.log /x $($installedGUID)"
    $msiResult = (Start-Process -FilePath msiexec.exe -ArgumentList $param -Wait -Passthru).ExitCode
}

# Check if the uninstall was successful
If (($msiResult -notlike 0) -and ($installedGUID -notlike "none")) {
    Write-Warning "There was an issue with the MSI Uninstaller process, we'll proceed with removing things manually." -ErrorAction Continue
} 
else {
    Write-Output "The MSI Uninstaller process claimed to be successful, exiting the script. Continuing with cleanup in case it missed something."
    Write-Output "MSI Uninstaller logs are here: $($PSScriptRoot)\MSIuninstaller.log"
}


Write-Information "Pause for 15 seconds..."
Start-Sleep -s 15 



<#############################

Clean up Services and Registry

- Note that all items are stored in a separate list, please confirm that you're ok with cleaning-
those keys before allowing this to continue.

##############################>

# Unregister the Services
Write-Information "Unregistering Services"
sc.exe delete "HealthService"
sc.exe delete "AdtAgent"
sc.exe delete "System Center Management APM"

# Unregister Performance Counters
Write-Information "Unregistering Performance Counters"
Unlodctr HealthService
Unlodctr AdtService
Unlodctr MOMConnector


Write-Information "Pause for 15 seconds..."
Start-Sleep -s 15 


Write-Information "Cleaning up registry entries"

# Remove DLL registrations and additional registry keys
$addtionalRegistryKeys = Get-Content $PSScriptRoot\RegistryKeys.txt
$addtionalRegistryKeys | ForEach-Object { Remove-Item -Path Registry::$_ -Force -Verbose -Recurse -ErrorAction SilentlyContinue }


# Removes Control Panel Options
$MuiKey = ((Get-Item "REGISTRY::HKEY_CLASSES_ROOT\Local Settings\MuiCache\*\").Name) + "\52C64B7E"
    Remove-ItemProperty "Registry::$MUIKey" -Name "*System Center*" -Force -Verbose -ErrorAction SilentlyContinue
    Remove-ItemProperty "Registry::$MUIKey" -Name "*Microsoft Monitoring Agent*" -Force -Verbose -ErrorAction SilentlyContinue


# Removes Installer Registration
Get-ChildItem Registry::"HKEY_CLASSES_ROOT\Installer\Products\"  -Recurse -ErrorAction SilentlyContinue | 
    Where-Object { if(( Get-ItemProperty -Path $_.PsPath) -match "Microsoft Monitoring Agent") { $_.PsPath} } | 
    Remove-Item -Recurse -Force -Verbose -ErrorAction SilentlyContinue

# Removed Uninstaller Registration
$uninstallKey = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($installedGUID)"
If (Test-Path "Registry::$($uninstallKey)") {
    Remove-Item "Registry::$($uninstallKey)" -Force -Verbose -Recurse -ErrorAction SilentlyContinue
}
else { Write-Output "Uninstaller Key Invalid, GUID Missing - skipping"}


# Cleanup Certificate Tasks for the Agent
Remove-CertificateNotificationTask -Name ReplaceOMCert -Verbose -ErrorAction SilentlyContinue



<#############################

Clean up Program Files

#############################>

Write-Information "Cleaning up program files"

# Removes Policy Definitions
Get-ChildItem 'C:\Windows\PolicyDefinitions\' -Recurse -Filter *HealthService* | Remove-Item -Force -Verbose -ErrorAction SilentlyContinue


# Remove residual installation directories if they exist
$programFolders = @(
    $installDirectory,
    "C:\Windows\assembly\GAC_MSIL\*OperationsManager*",
    "C:\Windows\Microsoft.Net\assembly\GAC_MSIL\*OperationsManager*",
    "C:\Program Files\Common Files\microsoft shared\Operations Manager",
    "C:\Windows\INF\MOMConnector",
    "C:\Windows\INF\HealthService"
)
$programFolders | ForEach-Object { 
    Get-Item $_ | 
        Remove-Item -Force -Recurse -Verbose -ErrorAction SilentlyContinue
}


<#############################

    ~fin

#############################>

Write-Information "Agent removal process complete" 

Stop-Transcript