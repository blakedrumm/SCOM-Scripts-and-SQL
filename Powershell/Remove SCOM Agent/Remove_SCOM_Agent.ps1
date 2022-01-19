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
        Blake Drumm (blakedrumm@microsoft.com)

    .MODIFIED
        January 18th, 2022
#>
BEGIN {
    if (!$PSScriptRoot) {
        if ($pwd.Path.EndsWith("\")) {
            $cwdOriginal = $pwd
            $cwd = $pwd -replace “.$”
        }
        else {
            $cwdOriginal = $pwd
            $cwd = $pwd
        }
    }
    else {
        $cwdOriginal = $pwd
        $cwd = $PSScriptRoot
    }
    try {
        Start-Transcript -Path $cwd\SCOMAgent-CleanupLog.txt -ErrorAction Stop
    }
    catch {
        # This may be needed when running from Powershell ISE.
        Start-Transcript -Path $cwd\SCOMAgent-CleanupLog.txt -ErrorAction SilentlyContinue
    }
}
PROCESS {

    function Invoke-SCOMAgentRemoval {
        <#
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
        [Parameter(Mandatory = $false,
                   ValueFromPipeline = $true,
			       Position = 1,
			       HelpMessage = 'Optionally, each server you want to run this script against. You can pipe objects to this parameter.')]
	    [String[]]$ComputerName
    )
    #>
        Function Time-Stamp {
            $TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
            return "$TimeStamp - "
        }
        Write-Output "$(Time-Stamp)Beginning removal of the Microsoft Monitoring Agent"
        # Get Agent Installation Path
        try {
            $installDirectory = (Get-ItemPropertyValue -Path Registry::'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup' -Name InstallDirectory -ErrorAction Stop).TrimEnd('\')
            $installDateTime = (Get-ItemPropertyValue -Path Registry::'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup' -Name InstalledOn -ErrorAction Stop)
        }
        catch {
            Write-Output "$(Time-Stamp)Unable to locate Installation Directory in the following registry location: `'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup`'"
        }
        If ($null -eq $installDirectory) { $installDirectory = 'none' }
        If ($null -eq $installDateTime) { $installDateTime = 'none' }
        # Check Installed Agent Version if available (GUIDs obtained from the 'ProductCode' property of the MSI installer)
        $productGUIDs = @(
            [pscustomobject]@{Version = 'SCOM 2012R2'; GUID = '{786970C5-E6F6-4A41-B238-AE25D4B91EEA}' },
            [pscustomobject]@{Version = 'SCOM 2016'; GUID = '{742D699D-56EB-49CC-A04A-317DE01F31CD}' },
            [pscustomobject]@{Version = 'SCOM 2019'; GUID = '{CEB9E45B-2152-4C10-A022-0825B53B632F}' },
            [pscustomobject]@{Version = 'Azure'; GUID = '{88EE688B-31C6-4B90-90DF-FBB345223F94}' }
        )

        $installedVersion = 'none'
        $installedGUID = 'none'

        $productGuids | ForEach-Object {
            If (Test-Path Registry::HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($_.GUID) ) {
                $installedVersion = $_.Version
                $installedGUID = $_.GUID
            } 
        }

        $object = @{
            "Agent Version Installed" = $installedVersion
            "GUID"                    = $installedGUID
            "Installation Path"       = $installDirectory
            "Installed On"            = $installDateTime
        }

        Write-Output "$(Time-Stamp) $($object | Sort-Object -Property Name -Descending | Out-String)"


        <#############################

Stop Services, attempt MSI Uninstall

#############################>

        # Stop MMA Services
        $allServices = (Get-Service)
        $services = @('HealthService', 'AdtAgent', 'System Center Management APM')
        foreach ($service in $services) {
            if ($service -notin $allServices.Name) {
                Write-Output "$(Time-Stamp)Could not locate service: $service"
            }
            Write-Output "$(Time-Stamp)Attempting to stop service: $service"
            try {
                Stop-Service $service -ErrorAction Stop -Verbose
            }
            catch {
                Write-Output "$(Time-Stamp)Experienced error while stopping service: $service"
                Write-Verbose $error[0]
            }
        }
        # First, try to use the MSIExec to do the uninstall
        If ($installedGUID -notlike "none") { 
            Write-Output "$(Time-Stamp)Attempting to uninstall the agent with MSIEXEC first..."
            $param = "/qn /l*v $($cwd)/MSIuninstaller.log /x $($installedGUID)"
            $msiResult = (Start-Process -FilePath msiexec.exe -ArgumentList $param -Wait -Passthru).ExitCode
            Write-Verbose "$(Time-Stamp)Running this command: `'Start-Process -FilePath msiexec.exe -ArgumentList $param -Wait`'"
        }

        # Check if the uninstall was successful
        If (($msiResult -notlike 0) -and ($installedGUID -notlike "none")) {
            Write-Warning "$(Time-Stamp)There was an issue with the MSI Uninstaller process, we'll proceed with removing things manually." -ErrorAction Continue
        } 
        else {
            Write-Output "$(Time-Stamp)The MSI Uninstaller process claimed to be successful, exiting the script. Continuing with cleanup in case it missed something."
            Write-Output "$(Time-Stamp)MSI Uninstaller logs are here: $($cwd)\MSIuninstaller.log"
        }


        <#############################

Clean up Services and Registry

- Note that all items are stored in a separate list, please confirm that you're ok with cleaning-
those keys before allowing this to continue.

##############################>

        # Unregister the Services
        Write-Output "$(Time-Stamp)Unregistering Services"
        foreach ($service in $services) {
            Write-Output "$(Time-Stamp)Attempting to delete service: $service"
            $scOutput = sc.exe delete "$service"
            if ($scOutput -match "does not exist") {
                Write-Warning "$(Time-Stamp)Could not find service: $service"
            }
        }
        $performanceCounters = @('HealthService', 'AdtService', 'MOMConnector')
        Write-Output "$(Time-Stamp)Attempting to unregister Performance Counters"
        foreach ($perfCounter in $performanceCounters) {
            # Unregister Performance Counters
            $perfCounterOutput = Unlodctr $perfCounter
            if ($perfCounterOutput -match "Unable to open driver") {
                Write-Warning "$(Time-Stamp)Unable to locate performance counter: `'$perfCounter`'"
            }
        }

        Write-Output "$(Time-Stamp)Cleaning up registry entries"

        # Remove DLL registrations and additional registry keys
        $additionalRegistryKeys = Get-Content $cwd\RegistryKeys.txt -ErrorAction SilentlyContinue
        if (!$additionalRegistryKeys) {
            Write-Warning "$(Time-Stamp)Unable to Locate RegistryKeys.txt file in script root folder: $cwdOriginal"
            Write-Output  "$(Time-Stamp)Using the built in Registry Key list."
            Write-Verbose  "$(Time-Stamp)Using the built in Registry Key list: `$builtInRegistryKeys"
            $additionalRegistryKeys = $null
            $additionalRegistryKeys = @()
            $builtInRegistryKeys = @"
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\MOMConnector
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\HealthService\
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\HealthService
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\EventLog\Operations Manager
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AdtAgent
HKEY_LOCAL_MACHINE\SYSTEM\ControlSet002\Services\MOMConnector
HKEY_LOCAL_MACHINE\SYSTEM\ControlSet002\Services\HealthService\
HKEY_LOCAL_MACHINE\SYSTEM\ControlSet002\Services\HealthService
HKEY_LOCAL_MACHINE\SYSTEM\ControlSet002\Services\EventLog\Operations Manager
HKEY_LOCAL_MACHINE\SYSTEM\ControlSet002\Services\AdtAgent
HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\MOMConnector
HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\HealthService\
HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\HealthService
HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\EventLog\Operations Manager
HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\AdtAgent
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\FE6BDAB7AAC8EF44F8007173B3ADC6CE
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\FDA6CA06677B3F63E9A59007BE488EE6
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\FCDBA014A5A179344B3EE631810CE5FB
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\FCC23AF654548A546913497A51E4E11B
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\FAC8A27AFCDD4FD3E81A7D4A69398095
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\F9D06247446DB3242B4D2019AEB48AEB
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\F82F3BCB7663F4A3C98A023838EABBC6
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\F736F5EDD8A53274D8D720CBE9F2EAF2
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\F716C7801431BBE45A0DD065FDB9360E
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\F62BC7746B52B4E3FB49CD383C620C07
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\F51B9C74325E53244881CBD476D8BE1C
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\F4E215E663E53F94789BA71DA5EEF33D
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\F4A4E4662321DEC31B8E9C23C89A369C
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\F4368E41AEA81DC4CA84EBFBAD8125A3
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\F35CADC5920F8EE32A8061881980A8F0
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\F23F1434F6EBE5940AA16899EB45651B
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\F22D18A1F77FC4E4C9086236DAD2F799
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\F176D4732223A7E43A65F4046D322582
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\F08FD1F455400C6408E4915FB91E5D60
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\EEB0664E67A3341458034B86021CCC5D
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\EE33D94DEB62F1535944B8D66D63C460
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\EE27ACE2C642E2F40B3D6AC61EC7B3B5
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\EDBAB3921FAB2C3388C1067E8DE4B7DB
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\ED07BC866611B0642B109CD43301C894
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\EC55FFC0CF198F74E8C650E5C0FDB226
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\EB15E1BD3A9E56E4EA265888054D511C
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\EA0B9B5313E4A8742B06A738AF7CC22E
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\E9980A3B21DFA5947BD538A0366F9F45
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\E56971DAD056CAA39B8E4DA57607CE25
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\E1E4201776DE92D4E8462AED1BB3FBDA
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\E02CAFCCE1D160441BCC7C0DBBCAB112
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\DFCB955485834624C9051C18E2BB78AB
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\DED2C7E3B6D03854FBE4E720E49EFF53
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\DEA3E05B75C40B9448D34EA6A8037FBE
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\DE6AD137BA182EE4F9BA12C10BB5A85E
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\DD9A963BDC97179328B7109E5CFEDE48
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\DC888C054D6836F318EAE013E3607A1E
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\DBE4BED32C25C544899C7E73601689FC
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\DBC4973C9474ACA35AEB3D45AD5CC3B3
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\DAE9B5109E611734A9F67EF31DF2068E
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\D9960A263C3B3F948AE9C9793043B7C9
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\D825CE80938D4DE408F820EEBBA90F51
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\D818D987D1F917A4B8D2CF96C0669766
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\D787961966CEA9A3AA96F9F5D34D2E75
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\D773A6D892686534FA909C8DC7EF320C
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\D6D4CB9ADAA6B434788B18983257821E
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\D5DFF130CFF21044A975D08A956A8ED8
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\D5BDE81C06CD68948A50C82940DA9182
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\D5809CBDFCE868C40A437A61F46A97D9
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\D4E6F3BCCDC92103E90C35DA2430F3CA
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\D400FC409E118A24D8B6D1AD467C05CA
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\D3DC212A891C99736945433F7388DBB4
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\D32069F2DAF5B624D9DBFCD0625CB5F2
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\D2F85ADFA77EFCF4484C8B9D7BB4B9EC
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\D243EA284B520954D81DF87E8621817E
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\D04C010E2EFF5BC4FB129162A88FB46B
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\CE0E017C4CB8BFA46BA04BE3FB4D92B2
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\CD0AD2A8AD292D04F9193BC9B07DFA10
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\CBDB858D7361BC932AF2324E94A4DF2A
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\CA5FE6BF0B657B842B08889A2BAC3A7B
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\C96EDC8A0E435EE319D82BCFC573A2FC
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\C79E4AD35C4996941A6370B64E7C4E8F
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\C7432B46E38E3B74E9B75203477E5C45
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\C6EFF7379D5E33A4BA60C5198EE0DC08
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\C6E2582B78213B544AE5B255255878FD
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\C5D0EB9A98D64CB418B5197A29D8F492
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\C4FBD4ADAAD9F4A36A97127FFF794B6C
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\C2DB8584B99141538AD5BA152264830B
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\C1CE68A3C09C13B49B94BD761E44FF6E
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\C120BE5757DEEF533BF31342624F44A9
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\C08A07674CC0FF634B6F0ED7F69597A8
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\C02D4953D7837CE3C9D18ECC57C9B35B
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\BFE49C63AC47DC3499A7C22DD3A8AE3A
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\BF658BA8C148E704E8E5A6A3F2CD7298
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\BCDE637C715C5723A8C5810353CC21BC
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\BC4878CCE4A84BB45BD10E29609A06F9
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\BBB7A26BC88DE80489DDD5E661A5BA17
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\BB65420A01B38BD44AD75E6C9E882AE9
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\B9E1887B6FBE3D646B366F4D25E6D9D0
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\B8F41C64FCA6F944B8DA47F7BF205FC1
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\B88587BFA1BFEDF30B2BCED5AABB0C53
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\B860C101096B68E4187BE8AD063E2CEB
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\B7CEE6EE9D46E594F9F1CD70BEF92C48
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\B701D6A4EBBB23A4B94C0FD7810F91C7
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\B65BB9CB861494042952438193B369C0
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\B5D508C6FC933384296C5BA5638209CD
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\B5A8C52E9A3DC8C458B3AF8C4475AF46
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\B58674754669246468A02D99EDFF33C7
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\B552EB2572DF6B333A963F504EDE34DE
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\B426C075C75D1DC40931B1088C0090B3
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\B312282E87656744EBF979B773C5DB0E
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\B2C8825064F19E64381F7601FCFBAD6E
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\B1B844A43EE5C6848B8A889471BB8055
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\B06368B688229704DA5D1429D8704A8C
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\B027EECB22DF98048A4CF68CC04D76D9
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\AF4492A9A6454F134B9063C4D9DB9CA5
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\ADB61DF2D3DD5984F895C314CA23F656
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\ADADDCD3B28416C37949B6B955A74DD9
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\ABFAA3DF1850E4434AD9D959F30C756C
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\AB373FDF49EA7F4408F27E1F48F94A38
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\AB26914F0D47A6F499E44AFA52A13D7E
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\A8725EA122834924A8AE7ED6E315FD35
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\A5144FA008ED2744F9BC0ED3A1C4D869
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\A48F63A9765DD1C45881F31E67890D9F
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\A40B4BD5C43F6B84BB6F381F3C228D0E
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\A050BF8AEA53A1D49A841D58DF84C8B9
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\9CA02E59FBCB479489C626C1AF16A0F1
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\9BF89C9F95A220843BFD2A83D45024F4
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\9BCBDFCFF6FE9EE3AA0985577279668E
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\9B2648699712D9B4A87D23CE8D386024
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\9AD3212E99AD19E4A9E45D52CFBF2D08
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\9A40777B57F5B52328948797DC4CBDFC
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\97E5389D5A0EC9849B744955C557D20B
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\97670B9820044454E9A5087569A14EA9
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\972CCF96AEAABE141A945B5E3873CD4A
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\9723F81BBC1EFC1448750B6BBF8D0937
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\96E6A719DF357224B8DD70EE178029D4
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\9671FD61D17C1D3469314C07BA405FFA
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\96179D68124C46E41945318B793484E0
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\9146B99F3DB0D53438903A9473B6F0DE
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\902355BEBCFAAA444B15E0896B9789E0
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\8FC3C3276B37D06408B88AF98FFC373C
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\8F49BFE91A2DB723B9AF0547C629169B
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\8EF6C48D17197B949A376B6F49BE788B
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\8EA47638022B3814FA78879A2EF3259C
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\8E2995878CCF4A44DB2A49F4EF50DB09
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\8E1D627980E234649BAA06FB3F421E0D
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\8E01D59350086034DB5D9F4672AE4926
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\8DED0411FE5481D3DA0D5A98723259E7
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\8D19E61C5272D5A49881E92AEF9DB2E2
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\8BAC1C582D2D3FC33A26C9981E05D7B4
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\89E51028103A90143ADD4B6BB6E0A299
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\89B581389628C5C358CE8102881454BD
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\88FBB63CDBA6CB03286F7BC70EF1140A
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\88D842E388D97C33EAF0BB5D31FEB95C
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\88C883A4F0440E54F81A7011527992B6
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\885193807229C1C429BBD47F4549F52B
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\86EB5EF163D698741846EA4C15D673EE
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\868E637134C951A48A092CB71976D627
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\8525EFC1B9C05814A9BDA31DE07929B8
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\84029B5E95851FA4EADA9BE7FB000B78
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\83F6D602BDEDB87498ACCE002193695A
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\832D6CABEEDF470459BB55A4D9F38A89
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\832C2F6E2FF24364EAD0C64C2166DA97
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\83091001EF816174C90E302B958E82BD
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\82D52BE443E39D336978B77BDA6FB5DC
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\82A01B6372C2AD3458045941CF0E3755
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\818903453AEBB1546A5F85C6A6A3934D
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\80E7CD4F084F1904EA418D0F5C79D210
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\804CD1156631EC03DB38134DDC6F0F76
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\7FC769C0424A7BB42A17241720B3E1A7
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\7DC2357A52FEADE31BD63F420C8CB6DD
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\7B453692554162A41A60349813B6EB86
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\7AD07885D97E4273C96615F04EC8D48D
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\7A7C3C7DE532B5F48BC7AEB49351F1C2
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\790CD94456B75BF409130AFDB1D77DCD
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\7808DC071100766438BD7882E1D9306C
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\778AE13D716BB193B8BAEF94B7E094DD
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\770C7E310AF17D53B8C9F0403A434F40
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\76EAAED5685367A44950F96A0825EDF3
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\749C53802D6D25E4FA4120130DE488AE
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\74722E20CDB882532A34B0FA4C6D0965
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\742DE90A1E353494A99D94C78EB59A90
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\73870B5143957433ABE83C5613137BB5
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\71BC6B0E7D7C8134D9B1C472B615FCDD
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\719979F5A80471740995BB0DE69B4BF3
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\713EDBB08B54DB7358C70CB21543C533
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\709F2450C53A1FF3DA9F3DEC5802AFB6
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\709795BB7DB7CDA4C80FC0F32E78F9DA
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\708D1B25F29DFAC46A02A6C067363D44
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\705FC1E148E075646B0C736AA8CB59AF
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\6EB8102FAB632B134AC9E937B888E818
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\6D2A380A5CC5DBE459D374FCC180B16E
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\6C630234E452FF63CBE79789ABB3F3EC
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\6C06FF4763D4AB3349F50B65BAA9FD4D
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\6B29332593E99B64DA5CE3EA90BE5780
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\6A51C30E24219F8368AE959DE73368ED
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\699BE56B2FB540C41870CF665B5F6C4A
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\693FC31B178EC834BBDEDFF21AE02108
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\6897E72AD88BE364BA6788F1DC253244
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\66C9979E809D318349E99B027A307A19
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\6534F651F22BC004DBD0FA9D780CF183
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\6500FECCD69B71D42804B218958742CE
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\648502EF20071E94399E7642AFDAAADD
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\6379A262CC8DCFE4EAF6B36F0FC13A97
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\631020E262060814BBF1A55DADB09005
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\627E0DEE17DB95340A2E819CC2EE339A
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\620015C8561C27446B5C65DF281660CA
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\5FF5ADB352A4865319341E98EECB57B7
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\5F61CCDE98928EA469D4603F8473632B
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\5EA2844D360373441BB75789417B6CA1
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\5CF3FD228F368AC499AE1DCDDFA39697
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\5B35EFC959BC983409B8C6DF58F9D9F0
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\5AC0E935ED6832336ACBC852CBDA63F9
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\59F6BAF420956C14DBA2E1B512D8E260
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\59B30FCD5A35AA239BA165040D8D0047
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\5879F3FC728050D4B952B88EA40BBA8F
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\5843235400E609A4EA317B82C3031BB7
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\577FA088148131A498E564D708753F29
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\56077B47D5C9F204C9E592A89C75E8CB
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\554DBB771753BE548BA8699ACF7A490D
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\5313B3B2518127B43B54948FC1548542
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\52DF52B58628C1E3499E3813F347F542
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\52CD88A3661A50135830D5B9AA627DD0
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\5254118787B4EA83AA960150DCFEFEC3
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\5218C728DBAD7334D9B93BA3B8E4C1E7
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\5217256742EE02845A2402F781929417
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\51F54799C2249853290001CE2AC8DD87
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\4F4055AC6A3CC534CBABFEB71654142B
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\4DC25B41893999037B13D7A48CB90883
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\4DB69EF2E261208418A9C5D093DB2512
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\4B5F317ABA0041548B2340E4743F666E
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\4B0F91558337FA94A9F9DB720300F631
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\49D73377DE353653DB2783146F5474D5
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\468EDC3C6A6DDD84B90A112D1744EA47
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\458D9B30696C1314CAFE825AED158F4C
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\4406BEB89C886A233896E857F17AEFC1
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\42F1B828A3B43D73C9ECC53ABD27A004
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\4287F0B3D5C375F33954B0109E0649D2
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\4270354C6A6A50132901B2FDF8A2E4CD
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\42651494C8639034D8096CBD4CEA5FFB
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\422B27F7838042A4E9554DE6FC9D00E5
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\42254B55A62ACDC468CD25C62203C3D1
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\41F649C939EF99E40AA81715D396D121
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\40C8E1DB256B13337900F4BE5D3E8B9E
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\3F7B1B3B83FDF9A399C09C2BB1E53C43
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\3F5DD1570DA222242A95796553CFC5FE
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\3F57578EC6CAC2648BF5E8F16E721161
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\3E1DADF06A4907031B5FB98FA3328271
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\3DC357C96BF5DF54E811DFD40E2E4542
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\3D7E22F15159CED489C7E6C0ACB47FA7
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\3D6A28C6AD6FD20358628752FF5B611C
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\3A8AA9427D9D14544B918F5F673FA368
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\3A1E08CA6FC6B1447AE769A39A2FB580
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\386F79B7AE6BC5848B1BFD185DA340EE
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\385255BEE48759642BC2E0A96F449587
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\37F2074C1AD37593CAFAFA783A07D592
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\36B6521E4981CE64FA0C930615A79625
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\32C93D5CF13EF7C3DBCF5854D1A00122
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\31B7A233EB49EA744AE8E98855CB0278
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\31AC22523118EEA468FBE8CD5B7033F1
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\30ADDA06017145942B999A4FD28D986A
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\2FB73EE2DBFB2764086BC4F25887D569
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\2F1CCF71C708677468059DC88DFD8507
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\2DC4193F7E6715144854C4478ADBB269
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\2CBDA32F1B53E654FAF442301AEBB06E
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\2C3B30A03763B4337A7ACA7A7E7E7D86
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\2B897177FB3A2B730BA39C26FDD32AE7
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\2B457C2A6EC2ECC4B979CFA4C4B6DB0F
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\2A19C123D8455E63095FF615F20C0FE1
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\287ECB11272842B328BEC73A1A01CF7D
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\283B4E94BE025BD46BB3C6ADDCAAF113
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\25AF7B44265A92A4B8295CBD439E4EF2
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\24602B91787764A4A90DCDE2E53C63B1
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\2448B4A26924C624083AF5FE3D20BA13
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\236CBCA6308D79842ADE55EF80A52FFD
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\22DD613BDE1E75E428B38BB0B2285A2F
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\225FD965E324278478F413201E3694CE
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\21BD94DB136EC523ABB431CA9AE029A3
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\20894491F3C994940BCF33958BC3B315
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\20807E8179EB3DF4E8599401C32B01AD
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\201A5F3B3772ADA438492973E07B8E0E
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\1F9D5FCC909416F458FAF999439565BE
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\1F6320DCA8B4B27409F7B01968BA6CD4
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\1EC8F086C814EA747B561DB2FC6B6BA1
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\1EAFEEB97C467D1449E8F8B7AD6FDAC1
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\1E48DA47125CF1244A406E42B19260E4
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\1E242116EF41F8F4C8AF562D35C3A0C9
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\1E18CDA26C38AF83A853556FF716DEAB
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\1C59208640FAD584F8CB707F421CA239
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\1BBA90FEAA0E8B84FA7328988055FBBE
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\1B495CBED8A3AC140B44FE5A4A8BD087
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\1A694D2D4F3E8D2428696516D807568F
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\1A0CEBBCEAA24684E9E4EC6FCC54FF26
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\1880446D4C2AC103A87E25C34A949CB0
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\17475634C26077347B54C53074D26A4A
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\1712F7C85EDD65D4EB05620203173B6C
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\16FC69AF22655FB3EAB8BE2F0C24B807
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\16EADB297B30B963C88B63F6C54BC2A5
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\16180FEC735C52348BA493D2FE4AC2C7
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\150098AC1A7080335B458076DC707C9B
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\145BE8956EFCE884ABF0EB2B2857C870
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\13C0089962F4B9D4CA0A02F9417F9C4B
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\138B51828655C2247ACEACCD4E96574F
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\113617239653A4B438CEA00C1DFD2059
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\0F2381A5F3ECA264DAEFF629E480161B
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\0E785EB1FE20B7C3D829ABAF2A75950F
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\0E18734C77329863A91FBCD02CC485DB
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\0DBAEE7CE522106358C3EFCA8659E1B1
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\0DB7EC344F8CB453F8FA38D4FA5993AD
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\0DA28B0E8B9B5D542B45BE94259A6F4D
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\0D8CE9EEA6AF4A14E8CA582B50576674
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\0B52257869674D04695D4115967357DB
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\0A996544D0A8A224CAE737122AE514DF
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\0A977954D0A8A4D4FAE773121AE514DF
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\0A38C0B4AB10F6541B03D7449CCC653D
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\0A0A3ED1C7FAE7A4D83932913737B817
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\09B9481F017C13D42B7CD6CDA6BBABE1
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\093F899B889F5E9498B42B4CEB87813C
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\0893FF8FBB53739319FE09DF8CF0E9AA
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\06B36C7D06281724A9B71C774022DC34
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\053EB4D5FE3FE833EB8688DDB142FCB1
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\048F5ECCFCABE624AAB70688F75E06AB
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\04520A70B61BE2E4C8BBE01DBA4CDED1
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\034F1859984584E42B96B9E6F1A93ED1
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\031DBCD87EE476A43B329CAE22A066D0
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\02B38B369BA194F40B2B449827C49AC6
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\0212AF4DF3993DD4A97F86FA98A9E37C
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\005389D4CE6E59C4894C8A060F6A7FE3
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel\NameSpace\{1d4108cc-ac08-45d4-8349-b05522bee527}
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Tracing\Microsoft\MOM\GENERAL
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Tracing\Microsoft\MOM
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\SystemCertificates\Microsoft Monitoring Agent
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\System Center Operations Manager
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\System Center
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft Operations Manager
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\TypeLib\{D0F0E165-351A-401E-869C-E1BD2289FC76}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\SCOMMaintenanceMode.SCOMMaintenanceMode
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\SCOMMaintenanceMode.SCOMMaintenanceMo.1
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\RunMOMNTSignatureMapper.1
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\RunMOMNTSignatureMapper
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\RunMOMNTPerfMapperCondition.1
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\RunMOMNTPerfMapperCondition
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\RunMOMEventMapperCondition.1
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\RunMOMEventMapperCondition
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\RunMOM2005WMIEventMapper.1
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\RunMOM2005WMIEventMapper
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\RunMOM2005ResponseContextMapper.1
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\RunMOM2005ResponseContextMapper
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\RunMOM2005DiscoveryDataMapper.1
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\RunMOM2005DiscoveryDataMapper
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOMWebAppDataType.1
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOMWebAppDataType
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOMURLDataType.1
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOMURLDataType
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOMRegistryDataType.1
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOMRegistryDataType
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOMNTPerfDataType.1
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOMNTPerfDataType
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOMNTEventDataType.1
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOMNTEventDataType
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOMEventDataType.1
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOMEventDataType
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOMConolidatorDataType.1
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOMConolidatorDataType
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOM2005ResponseContextDataType.1
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOM2005ResponseContextDataType
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOM2005PerfDataType.1
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOM2005PerfDataType
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOM2005EventDataType.1
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOM2005EventDataType
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOM2005AppLogDataSource.1
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOM2005AppLogDataSource
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOM2005AlertDataType.1
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOM2005AlertDataType
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOM.ScriptAPI.1
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\MOM.ScriptAPI
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{F473EA49-A341-4C91-A0D2-F060F2B8794E}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{F01766C3-EE18-42C5-8065-F162BADDFD72}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{ECAA7309-3078-4133-94C0-7764059956B8}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{E80004E9-9D8C-4953-A404-F8601BE31160}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{DE4A9EA9-DB7B-4EE8-9A09-F930F3B0F47D}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{D6D4BBF5-413F-4BB3-ADED-59BCDBEF25C0}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{D49D077A-9830-4512-9C1C-08A00640540E}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{CB7F0443-4108-4192-A909-2BAE36CFFA3F}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{BE27656D-6FB8-4FEA-A32C-3359B35469DF}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{BD3CA6B1-39B5-4DAB-BA7C-170A0946BF5B}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{BA0C2E15-9899-4C66-A1A6-66A29F44E126}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{A4E79E8A-9494-47A4-A280-8C7D35C88A2F}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{A25E5DC6-38A5-4186-8826-0E4F3DAFE9E7}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{9F353DC8-A0A3-4D49-8542-D033C2C6C205}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{9BB42CB8-DC3D-4B92-B791-45240E70A82D}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{952197C8-F448-4A99-9EDC-3883752D8483}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{92D4FA3E-6CB6-4E19-A656-F65E775FDA71}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{916F8039-2466-4186-9675-CB7067FD6CA0}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{9008D27B-E4E3-4133-97EE-433B30E2AB9E}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{84CB7BF8-4684-4980-84CF-2C99FD3CEFFA}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{8440CA64-8382-4738-AB45-348AE9FA4DF0}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{80568272-6F9C-4B60-A448-0C97945EF30A}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{7D4FA78B-5FC4-4B35-957E-677E3F4AD509}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{677FCD85-1031-4D3F-AD01-5AF3D1F172E3}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{6356B200-105F-424A-BA49-73C7868ADB85}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{602776E2-229A-4547-A7FF-179B85E6F135}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{5F5AA7E5-DE3D-4F0D-9215-5DB4925A23AC}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{5711DB17-4641-4449-BC10-B0FEFD26B39B}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{4D845E06-9E11-4C4D-AC6C-29A436B0C3A7}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{49CF325D-12BE-47eb-91C8-D74AB3479F92}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{465B6F56-D749-4439-8A83-801F46F62B74}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{3F6642B3-F15A-4F93-8B8C-3AFC917B09CC}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{30615C8D-7F41-4277-97A9-71847230E62E}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{2DBC71E1-BD3A-4A33-A3FF-A70A2F48E246}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{292269A9-A6AA-416D-A328-41C05C93B1DC}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{21FE2ECA-B46C-4E85-BFC8-918128391398}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{2123A8E8-1EA9-428A-B4EB-7887415A0906}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{14DAE79A-B9E3-4A9E-B055-F014737101C5}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{1413EBEE-2C74-4C4E-941C-8249C5F2305E}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{0B6976BF-01A8-44F0-B45F-07446AB6C779}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{0A226CA6-D688-4D0D-AB32-12AA8C168C8C}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Interface\{067D887A-A440-42DF-BA3F-16225725377F}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{eae677d0-9d4f-11d9-9669-0800200c9a66}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{c214366a-a4fc-4e05-8f7b-20ba04aef520}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{FFB4307F-F0BF-4E10-816C-3A3DCF098398}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{F473EA49-A341-4C91-A0D2-F060F2B8794E}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{F180EFE1-4803-4505-9FE1-ADB3A46F8F20}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{EC35BBCA-75DD-45F6-B545-CE63307C93D1}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{EC20D35C-E55D-411F-B2BE-47069FC741D2}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{EB1EE5D9-6A74-4E30-98F8-6A9E9A255356}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{E56790D9-07E7-4B4D-BD6C-1BCCB0BD82D0}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{E4B833C6-F11D-487C-A03C-BD107E5E7918}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{DB0ACC98-3B33-4C35-8EED-6991F2D936B0}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{D9E9B922-6C2F-40DF-8D70-F406C0EFFBDE}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{D49D077A-9830-4512-9C1C-08A00640540E}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{D3C8F83C-C8C6-4DD9-8D0D-CD93BB65AF11}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{D239DB52-BE8B-4373-94C2-6EE78FA58D55}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{D116EFD9-0274-4BD9-8FD5-94BB2138FA7F}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{CBBE09D5-8DF8-4843-87A9-DD5AED662D29}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{C75C06DE-A537-4744-BDF9-5775E63E014A}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{C66A80D9-5130-4520-BD5A-0DDE195A72F7}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{C6410789-C1BB-4AF1-B818-D01A5367781D}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{C39EC9F2-50D3-42C6-85AA-846B6505DE24}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{C3713D4D-B1FF-4835-A644-8EF774830FA2}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{C3339855-80B3-4c06-B7AB-5C5D97B59A0D}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{B98BD20C-3CC8-4AFE-9F68-5702C74D73DB}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{B61F43BC-A2D3-4E31-9C62-5B2FEE0B4C55}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{B5F80055-46B5-446d-9C71-A8B5ED74B780}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{B5A35748-86F5-46A3-9BC2-F9A494E36B25}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{B4BE2EB9-6D55-46C1-86CB-D87057ECFC8A}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{B3B71AB0-4D83-4A8A-BAA8-3F07B7C3F18D}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{B39686DA-52A8-484A-B1DB-ABBA594FF664}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{B2D19FEF-965A-4733-B897-FADC8076AA04}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{B27EBEAC-E711-40BF-896B-714A4C02EB39}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{B14B621A-B4D5-44D7-A4A2-ADE021CE68C1}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{B065E6F2-1B98-4DDF-B905-948573DB1AC1}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{B000FD63-FD06-47AC-AC1F-8EE8C42CC479}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{AF75FC67-9061-4E54-913B-5983BAD2A4D0}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{AF08D207-AF2F-4A40-B0DD-6B26AD302CB2}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{AEB2011B-7AD5-4A03-910F-312228EAE0F7}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{AD5651A8-B5C8-46CA-A11B-E82AEC2B8E78}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{ABCE0F22-CD3F-4F51-A686-4A168EC754C3}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{AA56A2C2-232D-4FDA-80FC-31067ED5607B}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{A9348597-CAFD-4E57-9A20-2BCC4E3ED9CB}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{A55A26F6-84F8-40D7-993E-C80AAE40F3A3}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{A29CCF51-C540-4B99-B8CA-BBB20F05C8B8}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{A24B0E65-CE0B-4B8A-BDA6-6A2B5164D700}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{A1260A5C-9F58-462E-82C1-1C317E5AD970}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{A0D4D11B-7F8C-4DD2-8E7D-C5B9D0D7C413}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{9F96E9EF-EA39-4352-AE5B-E6E0AB20E4CA}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{97b1ef21-757c-4004-86bb-57939e2c98d8}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{9614C109-D7CD-43A4-BC95-F015D9B1A224}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{92CA1E5F-C050-405E-8947-381690C6182D}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{92C599FD-6639-4A9F-90DA-E1350162A318}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{92A40C04-DE27-47E2-ADB3-CD960E6BD9E2}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{9184E8F9-6C50-47D7-987C-7CE31AD115A9}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{915E1B16-C101-4C0C-85ED-4301786AE09A}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{91564CE8-81DE-4D52-9AC5-A6FB6B9AB0EB}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{8b1626e2-7ec1-4cf2-8ecb-8263991e13c4}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{8F446429-71AC-49e0-B833-671696193552}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{8DE9515F-F20F-4E97-BE09-AD61C8536590}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{8D61C900-109A-4320-9F90-B6312DFF59F0}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{8D17B92F-528D-4DF6-A9FA-55D59AE33AD2}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{8BE998E8-B943-4ABB-B3AF-8A3709044576}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{89CD40BD-EBCA-41E4-B645-DCCD1434361A}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{8816FFC0-0CE4-4300-99B2-EB480001284B}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{866FC490-7070-425c-BD55-9C52F9F30238}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{84CB7BF8-4684-4980-84CF-2C99FD3CEFFA}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{7fd22897-9e63-4464-84be-b0b0857dfa64}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{7E57E3DA-20A9-48E8-9057-68577CD56B37}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{7BC84A29-F833-4628-9A39-983E95914AF4}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{7B250F68-BA8C-4353-BC72-8D41A0D4C2C0}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{79004B60-87D8-4260-BEFA-B885F6B1EA2B}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{786842B8-B525-468A-B1D0-20A2E8E6283F}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{72175454-D77A-4548-90A2-7DE023AF6F2C}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{71553f30-e3fb-4772-be22-3c7b3b555c40}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{6D3D4B56-96BB-445A-8C7F-F7709D8A2CA7}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{6BB6ADFC-85E3-4D65-9998-2566C3C17F70}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{6ADE8BCE-E401-49FD-9EB3-CAF88D7E183F}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{6A1B86BB-5F6B-479C-B9E1-BF56DF61B5D1}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{68D7C190-7E3C-4573-A528-6AA79070F36B}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{657FB77F-8C2D-4C4F-BBE9-BBFA6DA61D85}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{64D5DB86-322D-4A18-AAA9-4BFE063624A5}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{647DA0F2-0751-4B27-8E00-C77D120B955B}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{5B44DF33-D67D-4500-85AE-7AE29CA11985}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{5A75A2D5-600D-48DA-91CD-2E35D4E9E7B3}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{5904DC85-F8C6-48FF-843B-FA2688B82EA2}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{57C03BDE-8B68-4C87-902C-BF1F4F166D18}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{54935827-f4e2-47e8-bb0a-a36d9327c4e7}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{534E71F9-7970-42D6-921F-59CFB873855F}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{52BC4FD4-C20F-4A2E-80E7-1024C57F30ED}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{51BB7C80-E68F-489F-BEBD-8BAFE3128CCE}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{4C1A6886-70CB-4F88-B901-C7830013C5FA}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{4B5C675C-83FB-40F4-87D6-A99F3BB7E019}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{4A8BA0EA-AFE0-46A6-937D-FCE887B455D9}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{49CF325D-12BE-47eb-91C8-D74AB3479F92}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{47AA3039-7E86-4b81-B295-67187EDFF3D7}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{472364F2-A1F0-41C0-9A8F-E00C92C2AB31}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{465B6F56-D749-4439-8A83-801F46F62B74}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{44f33133-bc88-49d6-9ac9-c46ede08e63a}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{4427C733-42AE-4133-84FD-BEE4A3830EC0}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{41EB45CD-BF11-4E2A-8349-07DA48DEA806}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{41E122D5-B2BD-41DE-935A-F4F3451DC492}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{3A0D9F65-8CC0-4C53-93DA-7E5E5DDB117E}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{398113D9-D7B4-45E1-B360-A38A75695096}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{37BA5579-8FEF-41BD-A125-76B788E94908}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{32455E3E-D321-40DD-9023-82D4949D6E1B}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{2BC378C1-7AB6-46FA-B264-62EE1B794194}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{2B72C328-CDBB-421a-ACC3-A1994DBD52BB}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{2B72C327-CDBB-421a-ACC3-A1994DBD52BB}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{2B72C326-CDBB-421a-ACC3-A1994DBD52BB}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{29D0D61F-7540-4937-97D9-D991E3E79513}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{29A5E631-EE28-44BE-A1F0-301A65381CFC}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{28BE3571-7EDD-42B8-98F8-38171F52A29A}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{2566BCEB-BF6B-45D6-BA1A-F99E5CACB8B2}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{24075BB8-759B-492D-B14F-C69C5600A5F3}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{23BEB21F-D602-4B89-8690-20EF7E641DAF}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{21a13095-6fb0-4629-8152-3f4dfd1649fe}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{20073FC6-F8BA-466A-BAB8-92DEF165BF6F}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{1dd52140-33e1-4b39-ac7b-638f21772428}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{1d4108cc-ac08-45d4-8349-b05522bee527}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{1E06AAF5-C4E0-4F57-A4F6-2C8A6A5E8E53}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{1DB91BE4-DAF4-4E49-9AA8-8E14F4985F2C}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{1D020D8F-6B17-4299-BBAD-64BE1F80901C}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{193B7F70-1730-419F-9E3A-D06FC08145B2}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{16D53AB0-D822-4a42-B44F-1B4375EEEB4A}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{16B61683-51F2-4210-B5BB-F89435F0F131}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{15AB4910-9CB9-11D9-9669-0800200C9A66}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{12B8034F-EF22-448F-AA54-C2E805A88AE4}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{0E6AF9F6-754A-42c8-A5D9-0AE71A53F96E}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{0D1FB777-4721-4862-A4BE-87138D56207F}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{0BFF64A1-4B2B-4DD5-ADB5-62C48074AB82}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{06CF61F8-55E9-42E5-A3FF-A89D1A64B6C9}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{05C8C114-7D2A-4159-B3AB-52BA3F40439B}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{059D50D5-2321-4CC1-8562-65F0D38C5497}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{009BE441-F1AD-4074-AD46-15F3BABCF0E5}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{00672A0F-9FE0-4DB3-87F5-25C95A11D14A}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{39C90EFB-6CA7-4198-995E-79447D91DB4D}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{4A441B28-CB75-4E38-B2B6-38FE330CA58D}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{4D3804D3-DAC8-4511-A534-D5538C2D8B18}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{6718C869-AC41-4A00-9DD7-15471F5B7A9F}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{9806CEFE-835B-4278-92AE-790FE5A25564}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{A052BD1A-7DDC-4BB1-B9F8-CEA9F31F61E7}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{F1864C01-1E70-4B6B-BA71-45CBB98D7319}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{F0EC90CF-0C9B-4C91-B8AD-5A5DA6264F5E}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{C0E953AF-5448-436c-A146-63B8AE52FD86}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{A27071EB-F6BD-4FBC-9FC7-7AE507739D33}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{9923CF3A-4BC6-458B-87B1-3060C0BCA37A}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{8CAE0BB3-EDE1-429D-8E89-301CC3B12B0E}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{66DE1BFB-922B-42B6-81AD-1306564B710B}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{647CEE06-3875-413D-BEB0-84456CEE4965}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{62DD1D6B-4B8F-4831-9A98-E30AEAA6C349}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{5C75AE84-172D-4A6D-AD3F-F2067A52C6E5}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{28F5174A-2D3E-45FE-913B-BDD69CF0AA00}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{1E9102B9-2CD9-4196-85DD-E90A45DF986F}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\{1543DF6F-C092-4209-85FC-DEAACDFF3881}
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AppID\AgentConfigManager.DLL
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AgentConfigManager.MgmtSvcCfg.1
HKEY_LOCAL_MACHINE\SOFTWARE\Classes\AgentConfigManager.MgmtSvcCfg
"@
            $builtInRegistryKeys.Split("`n").ForEach{ Write-Verbose "$(Time-Stamp)Adding `'$_`' to Powershell Variable `$additionalRegistryKeys"; $additionalRegistryKeys += $_ }
        }
        ForEach ($key in $additionalRegistryKeys) {
            try {
                if (Get-ItemProperty -Path Registry::$key -ErrorAction SilentlyContinue) {
                    Write-Output "$(Time-Stamp)Attempting to remove key: `'$key`'"
                    Remove-Item -Path Registry::$key -Force -Verbose -Recurse -ErrorAction Stop
                    Write-Output "$(Time-Stamp)Successfully removed key: `'$key`'"
                }
                else {
                    Write-Verbose "$(Time-Stamp)Unable to locate key: `'$key`'"
                }
            }
            catch {
                Write-Verbose $error[0]
            }
        }


        # Removes Control Panel Options
        $MuiKey = ((Get-Item "Registry::HKEY_CLASSES_ROOT\Local Settings\MuiCache\*\" -ErrorAction SilentlyContinue).Name) + "\52C64B7E"
        if ($MuiKey) {
            try {
                Write-Output "$(Time-Stamp)Attempting to remove the Control Panel Options for: `"*System Center*`""
                Remove-ItemProperty "Registry::$MUIKey" -Name "*System Center*" -Force -ErrorAction Stop
                Write-Output "$(Time-Stamp)Successfully removed the Control Panel Options for: `"*System Center*`""
            }
            catch {
                Write-Output "$(Time-Stamp)Experienced an issue when removing the Control Panel Options for: `"*System Center*`""
                Write-Verbose $error[0]
            }
            try {
                Write-Output "$(Time-Stamp)Attempting to remove the Control Panel Options for: `"*Microsoft Monitoring Agent*`""
                Remove-ItemProperty "Registry::$MUIKey" -Name "*Microsoft Monitoring Agent*" -Force -ErrorAction Stop
                Write-Output "$(Time-Stamp)Successfully removed the Control Panel Options for: `"*Microsoft Monitoring Agent*`""
            }
            catch {
                Write-Output "$(Time-Stamp)Experienced an issue when removing the Control Panel Options for: `"*Microsoft Monitoring Agent*`""
                Write-Verbose $error[0]
            }
        }


        # Removes Installer Registration
        $installerRegistration = $null
        $installerRegistration = @()
        $installerRegistration = Get-ChildItem Registry::"HKEY_CLASSES_ROOT\Installer\Products\"  -Recurse -ErrorAction SilentlyContinue | Where-Object { if (( Get-ItemProperty -Path $_.PsPath) -match "Microsoft Monitoring Agent") { $_.PsPath } }
        if ($installerRegistration) {
            ForEach ($registration in $installerRegistration) {
                Write-Output "$(Time-Stamp)Attempting to remove the registration key in: `'$registration`'"
                Remove-Item -Path $registration -Recurse -Force -ErrorAction Stop | Out-Null
                Write-Output "$(Time-Stamp)Successfully removed to remove the registration key in: `'$registration`'"   
            }
        }
        else {

        }
        # Removes Uninstaller Registration
        $uninstallKey = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($installedGUID)"
        If (Test-Path "Registry::$($uninstallKey)") {
            try {
                Write-Output "$(Time-Stamp)Attempting to remove Uninstaller Registration key: `'$uninstallKey`'"
                Remove-Item "Registry::$($uninstallKey)" -Force -Recurse -ErrorAction Stop | Out-Null
                Write-Output "$(Time-Stamp)Successfully removed Uninstaller Registration key: `'$uninstallKey`'"
            }
            catch {
                Write-Output "$(Time-Stamp)Experienced an issue removing key: `'$uninstallKey`'"
                Write-Verbose $error[0]
            }
        }
        else { Write-Output "$(Time-Stamp)Uninstaller Key Invalid, GUID Missing" }


        # Cleanup Certificate Tasks for the Agent
        try {
            Remove-CertificateNotificationTask -Name ReplaceOMCert -ErrorAction Stop
            Write-Output "$(Time-Stamp)ReplaceOMCert"
        }
        catch {
            Write-Output "$(Time-Stamp)Unable to execute task: Remove-CertificateNotificationTask -Name ReplaceOMCert"
            Write-Verbose $error[0]
        }



        <#############################

Clean up Program Files

#############################>

        Write-Output "$(Time-Stamp)Attempting to clean up Program Files"

        # Removes Policy Definitions
        try {
            $policyDefinitions = Get-ChildItem 'C:\Windows\PolicyDefinitions\' -Recurse -Filter *HealthService* -ErrorAction Stop
            if ($policyDefinitions) {
                ForEach ($policy in $policyDefinitions) {
                    Write-Output "$(Time-Stamp)Removing Policy Definition: `'$policy`'"
                    Remove-Item -Path $policy -Force -Verbose -ErrorAction SilentlyContinue
                } 
            }
            else {
                Write-Output "$(Time-Stamp)Unable to locate any files matching the filter `"*HealthService*`" in `'C:\Windows\PolicyDefinitions\`'"
            }
        }
        catch {
            Write-Output "$(Time-Stamp)Unable to locate any Policy Definitions (C:\Windows\PolicyDefinitions\) to remove related to `"*HealthService*`"."
            Write-Verbose $error[0]
        }

        # Remove residual installation directories if they exist
        $programFolders = @(
            $installDirectory,
            "C:\Windows\assembly\GAC_MSIL\*OperationsManager*",
            "C:\Windows\Microsoft.Net\assembly\GAC_MSIL\*OperationsManager*",
            "C:\Program Files\Common Files\microsoft shared\Operations Manager",
            "C:\Windows\INF\MOMConnector",
            "C:\Windows\INF\HealthService"
        )
        ForEach ($programFolder in $programFolders) {
            if (Test-Path $programFolder) {
                try {
                    $folders = Get-Item $programFolder -ErrorAction Stop
                    ForEach ($folder in $folders) {
                        try {
                            Remove-Item -Path $folder -Force -Recurse -ErrorAction Stop
                        }
                        catch {
                            Write-Output "$(Time-Stamp)Experienced an issue when removing folder: `'$folder`'"
                            Write-Verbose $error[0]
                        }
                    }
                }
                catch {
                    Write-Output "Unable to locate folder: `'$progamFolder`'"
                    Write-Verbose $error[0]
                }
            }
        }
    }
    # This is what the script will run by default when executed. Edit Line 936 to make modifications to the default, ie. Add Verbose logging -Verbose.
    Invoke-SCOMAgentRemoval
}
END {
<#############################

    ~fin

#############################>

    Write-Output "$(Time-Stamp)Agent removal process complete" 

    Stop-Transcript
}
