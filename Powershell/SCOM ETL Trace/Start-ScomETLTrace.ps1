<#
	.SYNOPSIS
		Start-ScomETLTrace
	
	.DESCRIPTION
		This will allow you to gather an ETL Trace from an Operations Manager Server or Agent.
		The Script will detect the location of the ETL Tools based on this registry path:
		HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup
	
	.PARAMETER GetAdvisor
		Gather the Advisor Trace Logs.
	
	.PARAMETER GetAPM
		Gather the APM Trace Logs.
	
	.PARAMETER GetApmConnector
		Gather the APM Connector Trace Logs.
	
	.PARAMETER GetBID
		Gather the BID Trace Logs.
	
	.PARAMETER GetConfigService
		Gather the ConfigService Trace Logs.
	
	.PARAMETER GetDAS
		Gather the DAS Trace Logs.
	
	.PARAMETER GetFailover
		Gather the Failover Trace Logs.
	
	.PARAMETER GetManaged
		Gather the Managed Trace Logs.
	
	.PARAMETER GetNASM
		Gather the NASM Trace Logs.
	
	.PARAMETER GetNative
		Gather the Native Trace Logs.
	
	.PARAMETER GetScript
		Gather the Script Trace Logs.
	
	.PARAMETER GetUI
		Gather the UI Trace Logs.
	
	.PARAMETER DebugTrace
		Gather Debug Trace, the Same as: StartTracing.cmd DBG
	
	.PARAMETER VerboseTrace
		Gather Verbose Trace, the Same as: StartTracing.cmd VER
	
	.PARAMETER NetworkTrace
		A description of the NetworkTrace parameter.
	
	.PARAMETER OpsMgrModuleLogging
		Gather OpsMgr Module Logging Data as detailed here: https://docs.microsoft.com/system-center/scom/manage-monitoring-unix-linux?#enable-operations-manager-module-logging
	
	.PARAMETER RestartSCOMServices
		If you want to stop the SCOM Services / start the SCOM Services back up when the ETL Trace starts running.
	
	.PARAMETER DetectOpsMgrEventID
		Detect in the Operations Manager Event Logs for an specific Event Id.
	
	.PARAMETER SleepSeconds
		How often to wait between checks for Event Ids. Or how long to wait until Automatic stop.
	
	.EXAMPLE
		Gather Verbose ETL Trace while detecting for Event ID 1210, sleep 60 seconds between each check for the Event ID.
		PS C:\> .\Start-ScomETLTrace.ps1 -VerboseTrace -DetectOpsMgrEventID 1210 -SleepSeconds 60
		
		Gather ETL Trace with all the traces gathered by default, wait 300 seconds (5 minutes) and then automatically stop the ETL Trace and zip up the output folder:
		PS C:\> .\Start-ScomETLTrace.ps1 -SleepSeconds 300

		Gather logs for Operations Manager Module Logging, good for troubleshooting linux discovery issues:
		PS C:\> .\Start-ScomETLTrace.ps1 -OpsMgrModuleLogging
	
	.NOTES
		.AUTHOR
		Blake Drumm (https://github.com/blakedrumm)
		
		.CREATED
		September 3rd 2020
		
		.MODIFIED
		February 10th, 2021
#>
[CmdletBinding()]
[OutputType([string])]
param
(
    [Parameter(Mandatory = $false,
        Position = 1)]
    [switch]$GetAdvisor,
    [Parameter(Mandatory = $false,
        Position = 2)]
    [switch]$GetAPM,
    [Parameter(Mandatory = $false,
        Position = 3)]
    [switch]$GetApmConnector,
    [Parameter(Mandatory = $false,
        Position = 4)]
    [switch]$GetBID,
    [Parameter(Mandatory = $false,
        Position = 5)]
    [switch]$GetConfigService,
    [Parameter(Mandatory = $false,
        Position = 6)]
    [switch]$GetDAS,
    [Parameter(Mandatory = $false,
        Position = 7)]
    [switch]$GetFailover,
    [Parameter(Mandatory = $false,
        Position = 8)]
    [switch]$GetManaged,
    [Parameter(Mandatory = $false,
        Position = 9)]
    [switch]$GetNASM,
    [Parameter(Mandatory = $false,
        Position = 10)]
    [switch]$GetNative,
    [Parameter(Mandatory = $false,
        Position = 11)]
    [switch]$GetScript,
    [Parameter(Mandatory = $false,
        Position = 12)]
    [switch]$GetUI,
    [Parameter(Mandatory = $false,
        Position = 13)]
    [switch]$DebugTrace,
    [Parameter(Mandatory = $false,
        Position = 14)]
    [switch]$VerboseTrace,
    [Parameter(Mandatory = $false,
        Position = 15)]
    [switch]$NetworkTrace,
    [Parameter(Position = 16)]
    [switch]$OpsMgrModuleLogging,
    [Parameter(Mandatory = $false,
        Position = 17)]
    [switch]$RestartSCOMServices,
    [Parameter(Mandatory = $false,
        Position = 18)]
    [int64]$DetectOpsMgrEventID,
    [Parameter(Mandatory = $false,
        Position = 19)]
    [Alias('Sleep')]
    [int64]$SleepSeconds
)
trap {
    Write-Warning "Encountered an Exception: $_"
}
Write-Host @"
===============================================================
System Center Operations Manager ETL / Network Trace Gathering
===============================================================

"@
Function Start-ETLTrace {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false,
            Position = 1)]
        [switch]$GetAdvisor,
        [Parameter(Mandatory = $false,
            Position = 2)]
        [switch]$GetAPM,
        [Parameter(Mandatory = $false,
            Position = 3)]
        [switch]$GetApmConnector,
        [Parameter(Mandatory = $false,
            Position = 4)]
        [switch]$GetBID,
        [Parameter(Mandatory = $false,
            Position = 5)]
        [switch]$GetConfigService,
        [Parameter(Mandatory = $false,
            Position = 6)]
        [switch]$GetDAS,
        [Parameter(Mandatory = $false,
            Position = 7)]
        [switch]$GetFailover,
        [Parameter(Mandatory = $false,
            Position = 8)]
        [switch]$GetManaged,
        [Parameter(Mandatory = $false,
            Position = 9)]
        [switch]$GetNASM,
        [Parameter(Mandatory = $false,
            Position = 10)]
        [switch]$GetNative,
        [Parameter(Mandatory = $false,
            Position = 11)]
        [switch]$GetScript,
        [Parameter(Mandatory = $false,
            Position = 12)]
        [switch]$GetUI,
        [Parameter(Mandatory = $false,
            Position = 13)]
        [switch]$DebugTrace,
        [Parameter(Mandatory = $false,
            Position = 14)]
        [switch]$VerboseTrace,
        [Parameter(Mandatory = $false,
            Position = 15)]
        [switch]$NetworkTrace,
        [Parameter(Position = 16)]
        [switch]$OpsMgrModuleLogging,
        [Parameter(Mandatory = $false,
            Position = 17)]
        [switch]$RestartSCOMServices,
        [Parameter(Mandatory = $false,
            Position = 18)]
        [int64]$DetectOpsMgrEventID,
        [Parameter(Mandatory = $false,
            Position = 19)]
        [Alias('Sleep')]
        [int64]$SleepSeconds
    )
    $Loc = $env:COMPUTERNAME
    $date = Get-Date -Format "MM.dd.yyyy-hh.mmtt"
    $Mod = $loc + "-" + $date
    $TempETLTrace = "$env:HOMEDRIVE$env:HOMEPATH\Desktop\scomETLtrace"
    if (!(Test-Path $TempETLTrace) | Out-Null) {
        mkdir $TempETLTrace -Force | Out-Null
    }
    if (!$SleepSeconds) {
        $SleepSeconds = 10
    }
    try {
        $installdir = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup" -ErrorAction Stop | Select-Object -Property "InstallDirectory" -ExpandProperty "InstallDirectory"
        $installdir = $installdir + "Tools"
    }
    catch {
        Write-Warning "Exiting Script: Unable to locate the Install Directory: `nHKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup"
        exit 1
    }
    $healthService = Get-Service -Name healthservice -ErrorAction SilentlyContinue
    $OMSDK = Get-Service -Name OMSDK -ErrorAction SilentlyContinue
    $cshost = Get-Service -Name cshost -ErrorAction SilentlyContinue
	
    Function Out-TimeStamp {
        $TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
        return "$TimeStamp - "
    }
	
    if ($null -ne ($GetAdvisor -or $GetAPM -or $GetApmConnector -or $GetBID -or $GetConfigService -or $GetDAS -or $GetFailover -or $GetManaged -or $GetNASM -or $GetNative -or $GetScript -or $GetUI -or $DebugTrace -or $VerboseTrace -or $NetworkTrace -or $RestartSCOMServices -or $DetectOpsMgrEventID -or $SleepSeconds)) {
        $TempDirectory = "$env:HOMEDRIVE$env:HOMEPATH\Desktop\SCOMTracingTemp"
        if (!(test-path $TempDirectory)) {
            Write-Host "$(Out-TimeStamp)Creating temporary directory: `"$TempDirectory`"" -ForegroundColor Gray
            New-Item -ItemType Directory -Force -Path $TempDirectory | Out-Null
        }
        else {
            Write-Host "$(Out-TimeStamp)Temporary directory found: `"$TempDirectory`"" -ForegroundColor Gray
            $directorycontents = Get-ChildItem $TempDirectory\*.txt
            if ($directorycontents) {
                Write-Host "$(Out-TimeStamp)Moving .txt files in `"$TempDirectory`" back to `"$installdir`"" -ForegroundColor Gray
                Move-Item $TempDirectory\*.txt "$installdir" -Force | Out-Null
            }
        }
    }
	
    # Start GetAdvisor Switch
    if ($GetAdvisor) {
        $TracingFiles = Get-ChildItem -Path "$installdir" -File Tracing* | Where-Object { $_.Name -ne "TracingReadMe.txt" -and $_.Name -notlike "*Advisor*" }
        $TracingFiles | ForEach-Object { mv "$installdir`\$_" $TempDirectory }
    }
	
    # Start GetAPM Switch
    if ($GetAPM) {
        $APMTracingFiles = Get-ChildItem -Path "$installdir" -File Tracing* | Where-Object { $_.Name -ne "TracingReadMe.txt" -and $_.Name -notlike "*APM*" }
        $APMTracingFiles | ForEach-Object { mv "$installdir`\$_" $TempDirectory }
    }
	
    # Start GetApmConnector Switch
    if ($GetApmConnector) {
        $APMTracingFiles = Get-ChildItem -Path "$installdir" -File Tracing* | Where-Object { $_.Name -ne "TracingReadMe.txt" -and $_.Name -notlike "*ApmConnector*" }
        $APMTracingFiles | ForEach-Object { mv "$installdir`\$_" $TempDirectory }
    }
	
    # Start GetBID Switch
    if ($GetBID) {
        $APMTracingFiles = Get-ChildItem -Path "$installdir" -File Tracing* | Where-Object { $_.Name -ne "TracingReadMe.txt" -and $_.Name -notlike "*BID*" }
        $APMTracingFiles | ForEach-Object { mv "$installdir`\$_" $TempDirectory }
    }
	
    # Start GetConfigService Switch
    if ($GetConfigService) {
        $APMTracingFiles = Get-ChildItem -Path "$installdir" -File Tracing* | Where-Object { $_.Name -ne "TracingReadMe.txt" -and $_.Name -notlike "*ConfigService*" }
        $APMTracingFiles | ForEach-Object { mv "$installdir`\$_" $TempDirectory }
    }
	
    # Start GetDAS Switch
    if ($GetDAS) {
        $APMTracingFiles = Get-ChildItem -Path "$installdir" -File Tracing* | Where-Object { $_.Name -ne "TracingReadMe.txt" -and $_.Name -notlike "*DAS*" }
        $APMTracingFiles | ForEach-Object { mv "$installdir`\$_" $TempDirectory }
    }
	
    # Start GetFailover Switch
    if ($GetFailover) {
        $APMTracingFiles = Get-ChildItem -Path "$installdir" -File Tracing* | Where-Object { $_.Name -ne "TracingReadMe.txt" -and $_.Name -notlike "*Failover*" }
        $APMTracingFiles | ForEach-Object { mv "$installdir`\$_" $TempDirectory }
    }
	
    # Start GetManaged Switch
    if ($GetManaged) {
        $APMTracingFiles = Get-ChildItem -Path "$installdir" -File Tracing* | Where-Object { $_.Name -ne "TracingReadMe.txt" -and $_.Name -notlike "*Managed*" }
        $APMTracingFiles | ForEach-Object { mv "$installdir`\$_" $TempDirectory }
    }
	
    # Start GetNASM Switch
    if ($GetNASM) {
        $APMTracingFiles = Get-ChildItem -Path "$installdir" -File Tracing* | Where-Object { $_.Name -ne "TracingReadMe.txt" -and $_.Name -notlike "*NASM*" }
        $APMTracingFiles | ForEach-Object { mv "$installdir`\$_" $TempDirectory }
    }
	
    # Start GetNative Switch
    if ($GetNative) {
        $APMTracingFiles = Get-ChildItem -Path "$installdir" -File Tracing* | Where-Object { $_.Name -ne "TracingReadMe.txt" -and $_.Name -notlike "*Native*" }
        $APMTracingFiles | ForEach-Object { mv "$installdir`\$_" $TempDirectory }
    }
	
    # Start GetScript Switch
    if ($GetScript) {
        $APMTracingFiles = Get-ChildItem -Path "$installdir" -File Tracing* | Where-Object { $_.Name -ne "TracingReadMe.txt" -and $_.Name -notlike "*Script*" }
        $APMTracingFiles | ForEach-Object { mv "$installdir`\$_" $TempDirectory }
    }
	
    # Start GetUI Switch
    if ($GetUI) {
        $APMTracingFiles = Get-ChildItem -Path "$installdir" -File Tracing* | Where-Object { $_.Name -ne "TracingReadMe.txt" -and $_.Name -notlike "*UI*" }
        $APMTracingFiles | ForEach-Object { mv "$installdir`\$_" $TempDirectory }
    }
	
    #The Following makes a copy of the formattracing.cmd file but working when run as a service with no interactive desktop
    #Do not edit this!
    $formatTrace = @("
param(
[string] `$ServerToolsPath
)

#'FormatTracing Started'
cd `$ServerToolsPath

`$env:TRACE_FORMAT_PREFIX='[%9!d!]%8!d!.%3!d!::%4!s! [%1!s!] [%!FLAGS!] [%!LEVEL!] %!COMPNAME!:%!FUNC!{%2}'
Get-ChildItem Env:TRACE_FORMAT_PREFIX


# Detect downlevel OS
`$IsDownlevel='NO'
if(([System.Environment]::OSVersion.Version).Major -lt 6)
{
    `$IsDownlevel='YES'
}

If (`$IsDownlevel -eq 'NO' )
{
       `$OpsMgrTracePath=`$Env:windir+'\Logs\OpsMgrTrace'
} ELSE {
       `$OpsMgrTracePath=`$Env:windir+'\temp\OpsMgrTrace'
}

`$OpsMgrTracePath

IF ((Test-Path `$OpsMgrTracePath) -eq `$false)
{

    `$error = 'ERROR: ' + `$OpsMgrTracePath + ' does not exist' 
    `$error
       return
}

# Extract all of the TMF files from the .\tmf\*.cab files.
#'Expanding TMFs'

`$tmfPath = `$ServerToolsPath + '\tmf\*.*'
`$tmfCabs = Get-ChildItem -Path `$tmfPath -Include *.cab

foreach(`$tmfCab in `$tmfCabs)
{
    `$fileName = '.\tmf\' + (`$tmfCab.Name.Split('.'))[0] + '.tmf'
    expand.exe `$tmfCab.FullName -F:*.tmf `$fileName
}


# Cat all TMF files into one TMF file, a required operation for our aggregate TMF files.

#'Cat all TMFs into one TMF'

`$command = '/c type .\tmf\*.tmf > .\all.tmf'
`$command
start-process cmd.exe -ArgumentList `$command  -WorkingDirectory `$ServerToolsPath -wait -WorkingDirectory $installdir -NoNewWindow -Wait 

`$processcount = 0

`$ETLs = Get-ChildItem -Path (`$OpsMgrTracePath + '\*.*') -Include *.etl
foreach(`$ETL in `$ETLs)
{
    while(`$processcount -ge 3)
    {        
        Sleep -Seconds 10
        `$processes = Get-WmiObject Win32_Process -Filter `"name = 'tracefmtsm.exe'`"      
        `$processcount = `$processes.Count
    }   

    `$logName = `$OpsMgrTracePath + '\' + (`$ETL.Name.Substring(0, `$ETL.Name.LastIndexOf('.'))) + '.log'
    'Formatting ' + `$logName
    `$command = `$ETL.FullName + ' -tmf .\all.tmf -o ' + `$logName
    start-process .\tracefmtsm.exe -ArgumentList `$command -WorkingDirectory `$ServerToolsPath -WorkingDirectory $installdir -NoNewWindow -Wait
    `$processcount += 1
}

#'Waiting for all tracefmt processes to complete'
while(`$processcount -gt 0)
{
#Wait for all processes to complete
    `$count = 0
    Sleep -Seconds 10
    `$processes = Get-WmiObject Win32_Process -Filter `"name = 'tracefmtsm.exe'`"    
    `$processcount = `$processes.count
}
#'Format complete'
exit 0
")
	
    #Check if this script is already running. If so exit
    $currentPID = ([System.Diagnostics.Process]::GetCurrentProcess()).Id
    $runningPowerShellInstances = Get-WmiObject Win32_Process -Filter "name = 'powershell.exe'"
    foreach ($process in $runningPowerShellInstances) {
        if (($currentPID -ne $process.ProcessId)) {
            try {
                if (($process.Commandline.Contains('FormatTrace.ps1'))) {
                    #Exit the script since we are already running
                    'Script already running in another powershell instance.  This one will exit' | WriteLog
                    EventCreate /T INFORMATION /ID 50 /SO "AlertSubDiagnosticTask" /L "Operations Manager" /D "Diagnostic Task Already running. This instance will exit." | WriteLog
                    break;
                }
            }
            catch { }
        }
    }
	
    Function Start-ScomETLTrace {
        write-host "$(Out-TimeStamp)Stopping any existing Trace(s)" -ForegroundColor DarkCyan
        try {
            Start-Process "$env:SystemRoot\SYSWOW64\cmd.exe" "/c `"$installdir`\StopTracing.cmd`"" -WorkingDirectory $installdir -Wait | out-null
            if ($NetworkTrace) {
                write-host "$(Out-TimeStamp)  Stopping any existing Network Trace" -ForegroundColor Gray -NoNewline
                do { Write-Host "." -NoNewline -ForegroundColor DarkCyan; sleep 1 }
                until (Netsh trace stop)
                Write-Host " "
            }
        }
        catch {
            Write-Host $(Out-TimeStamp)$_
        }
        do {
            if (!$VerboseTrace -and !$DebugTrace) {
                Write-Host "$(Out-TimeStamp)No Trace Type Selected (Verbose / Debug), will proceed with Verbose as default." -ForegroundColor DarkGray
                $global:answer = "verbose"
            }
            if ($VerboseTrace) {
                $global:answer = "verbose"
            }
            elseif ($DebugTrace) {
                $global:answer = "debug"
            }
        }
        until (($global:answer -eq "verbose" -or "v") -or ($global:answer -eq "debug" -or "d"))
        if ($RestartSCOMServices) {
            if ($OMSDK) {
                write-host "$(Out-TimeStamp)Stopping `'System Center Data Access Service`'" -ForegroundColor DarkCyan
                stop-service OMSDK -ErrorAction SilentlyContinue
            }
            if ($cshost) {
                write-host "$(Out-TimeStamp)Stopping `'System Center Management Configuration`' Service" -ForegroundColor DarkCyan
                stop-service cshost -ErrorAction SilentlyContinue
            }
            if ($healthService) {
                write-host "$(Out-TimeStamp)Stopping `'Microsoft Monitoring Agent`' Service" -ForegroundColor DarkCyan
                stop-service healthservice -ErrorAction SilentlyContinue
            }
        }
        write-host "$(Out-TimeStamp)Removing stale log files" -ForegroundColor DarkCyan
        try {
            Remove-Item C:\Windows\Logs\OpsMgrTrace\* -force -Confirm:$false -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Warning "$(Out-TimeStamp)Attempted to remove the files in directory `"C:\Windows\Logs\OpsMgrTrace\*`" and received:`n`t`t`t`t$_"
            try {
                Move-Item -Destination C:\Windows\Logs\OpsMgrTrace C:\Windows\Logs\OpsMgrTrace.old -Force -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Warning "$(Out-TimeStamp)Attempted to Move Folder from `"C:\Windows\Logs\OpsMgrTrace`" to `"C:\Windows\Logs\OpsMgrTrace.old`" and receieved the following message:`n`t`t`t`t$_"
            }
        }
        if ($OpsMgrModuleLogging) {
            Write-Host "$(Out-TimeStamp)Removing any related stale logs for WinRM OpsMgrTrace Logging: `n$env:windir\Temp\SCX*.log `n$env:windir\Temp\SSHCommand* `n$env:windir\Temp\*.vbs.log" -ForegroundColor DarkCyan
            Get-Item $env:windir\Temp\SCX*.log, $env:windir\Temp\SSHCommand*, $env:windir\Temp\*.vbs.log | Remove-Item -Confirm:$false | Out-Null
            try {
                New-Item "$env:windir\TEMP\EnableOpsMgrModuleLogging" -Confirm:$false -ErrorAction Stop | Out-Null
            }
            catch [System.IO.IOException] {
                #$Error[0].exception.GetType().fullname
                #
                # File is already there
            }
            catch {
                Write-Host "$(Out-TimeStamp)Unable to create the file for logging: $env:windir\TEMP\EnableOpsMgrModuleLogging" -ForegroundColor Red
            }
        }
        if ($NetworkTrace) {
            Write-Host "$(Out-TimeStamp)Starting Network Trace" -ForegroundColor Cyan
            $NetworkTracePath = "$TempETLTrace`\Network Trace"
            if (!(Test-Path $NetworkTracePath)) {
                mkdir "$TempETLTrace`\Network Trace" -Force | Out-Null
            }
            else {
                Remove-Item "$TempETLTrace`\Network Trace\*" -Confirm:$false | Out-Null
            }
            Netsh trace start capture=yes persistent=yes filemode=circular maxSize=3000MB tracefile="$TempETLTrace`\Network Trace\$mod.etl" | out-null
        }
        if (($global:answer -eq "verbose") -or ($global:answer -eq "v")) {
            try {
                if ($RestartSCOMServices) {
                    $LogFiles = $null
                    $LogFiles = Get-ChildItem "$installdir\*.txt"
                    if (!$LogFiles) {
                        $LogFiles = Get-ChildItem "$installdir\*.DBG"
                    }
                    if (!$LogFiles) {
                        $LogFiles = Get-ChildItem "$installdir\*.VER"
                    }
                    Foreach ($LogFile in $LogFiles) {
                        $OldName = $null
                        $OldName = $LogFile.name
                        $newNameRaw = $OldName.split('.')[0]
                        $newName = "$newNameRaw" + ".VER"
                        Write-Host "$(Out-TimeStamp)Renaming `"$LogFile`" to `"$newName`"" -ForegroundColor Gray
                        rename-item $logfile $newName -force -Confirm:$false
                    }
                }
                write-host "$(Out-TimeStamp)Starting ETL trace at Verbose level" -ForegroundColor Cyan
                Start-Process "$env:SystemRoot\SYSWOW64\cmd.exe" "/c `"$installdir`\StartTracing.cmd`" VER" -WorkingDirectory $installdir -Wait | out-null
				
                write-host "$(Out-TimeStamp)Process Completed!" -ForegroundColor DarkCyan
            }
            catch {
                Write-Host $(Out-TimeStamp)$_
            }
        }
        elseif (($global:answer -eq "debug") -or ($global:answer -eq "d")) {
            try {
                if ($RestartSCOMServices) {
                    $LogFiles = $null
                    $LogFiles = Get-ChildItem "$installdir\*.txt"
                    if (!$LogFiles) {
                        $LogFiles = Get-ChildItem "$installdir\*.DBG"
                    }
                    if (!$LogFiles) {
                        $LogFiles = Get-ChildItem "$installdir\*.VER"
                    }
                    Foreach ($LogFile in $LogFiles) {
                        $OldName = $null
                        $OldName = $LogFile.name
                        $newNameRaw = $OldName.split('.')[0]
                        $newName = "$newNameRaw" + ".DBG"
                        Write-Host "$(Out-TimeStamp)Renaming `"$LogFile`" to `"$newName`"" -ForegroundColor Gray
                        rename-item $logfile $newName -force -Confirm:$false
                    }
                }
                write-host "$(Out-TimeStamp)Starting ETL trace at Debug level" -ForegroundColor Cyan
                Start-Process "$env:SystemRoot\SYSWOW64\cmd.exe" "/c `"$installdir`\StartTracing.cmd`" DBG" -WorkingDirectory $installdir -Wait | out-null
                write-host "$(Out-TimeStamp)Process Completed!" -ForegroundColor DarkCyan
            }
            catch {
                Write-Host $(Out-TimeStamp)$_
            }
        }
        if ($RestartSCOMServices) {
            if ($healthService) {
                write-host "$(Out-TimeStamp)Starting `'Microsoft Monitoring Agent`' Service" -ForegroundColor DarkCyan
                start-service healthservice -ErrorAction SilentlyContinue
            }
            if ($OMSDK) {
                write-host "$(Out-TimeStamp)Starting `'System Center Data Access Service`'" -ForegroundColor DarkCyan
                start-service OMSDK -ErrorAction SilentlyContinue
            }
            if ($cshost) {
                write-host "$(Out-TimeStamp)Starting `'System Center Management Configuration`' Service" -ForegroundColor DarkCyan
                start-service cshost -ErrorAction SilentlyContinue
            }
        }
    }
    Start-ScomETLTrace
    if ($DetectOpsMgrEventID) {
        Write-Host "$(Out-TimeStamp)Starting Detection of OperationsManager Event ID " -NoNewLine -ForegroundColor Cyan
        Write-Host "(Checking every $SleepSeconds seconds): " -NoNewline -ForegroundColor Cyan
        Write-Host $DetectOpsMgrEventID -NoNewline -ForegroundColor Cyan
        do {
            Write-Host '.' -NoNewline -ForegroundColor DarkCyan
            $Date = $null
            $events = $null
            $foundEventID = $false
            $Date = (Get-Date).AddSeconds("`-" + ($SleepSeconds + 1))
            $events = Get-WinEvent -FilterHashtable @{ LogName = 'Operations Manager'; StartTime = $Date; Id = $DetectOpsMgrEventID } -ErrorAction SilentlyContinue
            if ($events) {
                Write-Host ' '
                Write-Host "$(Out-TimeStamp)Found the Event ID: " -ForegroundColor Green -NoNewline
                Write-Host $DetectOpsMgrEventID -NoNewline -ForegroundColor Cyan
                Write-Host "!" -ForegroundColor Green
                $foundEventID = $true
            }
            else {
                sleep $SleepSeconds
            }
        }
        until ($foundEventID)
    }
    else {
		
        if (!($PSBoundParameters.ContainsKey('SleepSeconds'))) {
            Write-Host "$(Out-TimeStamp)Once you have reproduced the issue, Press Enter to continue." -ForegroundColor Green
            pause
        }
        else {
            Write-Host "$(Out-TimeStamp)Sleeping for $SleepSeconds seconds and then continuing automatically." -ForegroundColor DarkCyan
            sleep $SleepSeconds
        }
		
    }
	
    Write-Host "$(Out-TimeStamp)Stopping ETL Trace" -ForegroundColor Cyan
    Start-Process "$env:SystemRoot\SYSWOW64\cmd.exe" "/c `"$installdir`\StopTracing.cmd`"" -WorkingDirectory $installdir -Wait | out-null
	
    if (($global:answer -eq "debug") -or ($global:answer -eq "d")) {
        $logfiles = $null
        $LogFiles = Get-ChildItem "$installdir\*.DBG"
        Foreach ($LogFile in $LogFiles) {
            $OldName = $null
            $OldName = $LogFile.name
            $newNameRaw = $OldName.split('.')[0]
            $newName = "$newNameRaw" + ".txt"
            Write-Host "$(Out-TimeStamp)Renaming $LogFile back to $newName" -ForegroundColor Gray
            rename-item $logfile $newName -force -Confirm:$false
        }
    }
    elseif (($global:answer -eq "verbose") -or ($global:answer -eq "v")) {
        $logfiles = $null
        $LogFiles = Get-ChildItem "$installdir\*.VER"
        Foreach ($LogFile in $LogFiles) {
            $OldName = $null
            $OldName = $LogFile.name
            $newNameRaw = $OldName.split('.')[0]
            $newName = "$newNameRaw" + ".txt"
            Write-Host "$(Out-TimeStamp)Renaming $LogFile back to $newName" -ForegroundColor Gray
            rename-item $logfile $newName -force -Confirm:$false
        }
    }
    if ($OpsMgrModuleLogging) {
        Write-Host "$(Out-TimeStamp)Stopping Logging for WinRM OpsMgr Logging." -ForegroundColor Cyan
        Remove-Item -Path "$env:windir\TEMP\EnableOpsMgrModuleLogging" -Confirm:$false | Out-Null
		
        $winRMLoggingFolder = "$TempETLTrace`\WinRM OpsMgr Logging"
        if (!(Test-Path $winRMLoggingFolder)) {
            mkdir $winRMLoggingFolder | Out-Null
        }
        else {
            Remove-Item -Path $winRMLoggingFolder\* -Recurse -Confirm:$false | Out-Null
        }
        Move-Item -Path $env:windir\Temp\SCX*.log -Destination $winRMLoggingFolder -Confirm:$false | Out-Null
    }
    if ($NetworkTrace) {
        Write-Host "$(Out-TimeStamp)Stopping Network Trace" -ForegroundColor Cyan -NoNewLine
        do { Write-Host "." -NoNewLine -ForegroundColor Cyan; Sleep 1 }
        until (Netsh trace stop)
        Write-Host " "
    }
    Write-Host "$(Out-TimeStamp)Formatting ETL Trace" -ForegroundColor Cyan
    #& $installdir`\FormatTracing.cmd
    #[string]$formatTraceFile = '$TempETLTrace`\FormatTrace.ps1'
    #$formatTrace | out-file -FilePath $formatTraceFile -Encoding ascii
    #FormatTracing using the non-interactive FormatTracing file
    #$command = $formatTraceFile + " `"'" + $installdir + "'`""
    #start-process powershell.exe -ArgumentList $command -WorkingDirectory $installdir -Wait -WorkingDirectory $installdir -NoNewWindow -Wait
	
    #Start-Process -FilePath cmd.exe -ArgumentList '/c', "`"$installdir`\FormatTracing.cmd`"" -WorkingDirectory $installdir -Wait -WorkingDirectory $installdir -NoNewWindow -Wait
	
    Start-Process "$env:SystemRoot\SYSWOW64\cmd.exe" "/c `"$installdir`\FormatTracing.cmd`"" -WorkingDirectory $installdir -Wait | out-null
	
    #Move Files
    Write-Host "$(Out-TimeStamp)Moving/Copying Files around" -ForegroundColor Gray
    $directorycontents = Get-ChildItem $TempDirectory\*.txt
    if ($directorycontents) {
        Write-Host "$(Out-TimeStamp)Moving .txt files in `"$TempDirectory`" back to `"$installdir`"" -ForegroundColor Gray
        Move-Item $TempDirectory\*.txt "$installdir" -Force | Out-Null
    }
	
    $ETLFolder = "$TempETLTrace`\ETL"
    if (!(Test-Path $ETLFolder)) {
        mkdir $ETLFolder | Out-Null
    }
    else {
        Remove-Item $TempETLTrace`\ETL\* -Confirm:$false | Out-Null
    }
    Copy-Item "C:\Windows\Logs\OpsMgrTrace\*" "$TempETLTrace`\ETL" -Force | Out-Null
	
    #Zip output
    $Error.Clear()
    Write-Host "$(Out-TimeStamp)Zipping up Trace Output." -ForegroundColor DarkCyan
    [Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
    [System.AppDomain]::CurrentDomain.GetAssemblies() | Out-Null
    $SourcePath = Resolve-Path "$TempETLTrace"
	
    [string]$destfilename = "$Mod`.zip"
    [string]$destfile = "$env:HOMEDRIVE$env:HOMEPATH\Desktop\$destfilename"
    if (Test-Path $destfile) {
        #File exists from a previous run on the same day - delete it
        Write-Host "$(Out-TimeStamp)Found existing zip file: $destfile.`n Deleting existing file." -ForegroundColor DarkGreen
        Remove-Item $destfile -Force | Out-Null
    }
    $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
    $includebasedir = $false
    [System.IO.Compression.ZipFile]::CreateFromDirectory($SourcePath, $destfile, $compressionLevel, $includebasedir) | Out-Null
    Write-Host "$(Out-TimeStamp)Removing $TempDirectory" -ForegroundColor DarkCyan
    Remove-Item "$TempDirectory" -Recurse -Confirm:$false
    if ($Error) {
        Write-Warning "$(Out-TimeStamp)Error creating zip file."
        Write-Host $error
    }
    else {
        Write-Host "$(Out-TimeStamp)Cleaning up output directory." -ForegroundColor DarkCyan
        Remove-Item "$TempETLTrace" -Recurse | Out-Null
        Write-Host "$(Out-TimeStamp)Saved zip file to: $destfile`." -ForegroundColor Cyan
    }
	
    C:\Windows\explorer.exe "/select,$destfile"
}
if ($GetAdvisor -or $GetAPM -or $GetApmConnector -or $GetBID -or $GetConfigService -or $GetDAS -or $GetFailover -or $GetManaged -or $GetNASM -or $GetNative -or $GetScript -or $GetUI -or $DebugTrace -or $VerboseTrace -or $NetworkTrace -or $RestartSCOMServices -or $DetectOpsMgrEventID -or $SleepSeconds -or $OpsMgrModuleLogging) {
    Start-ETLTrace -GetAdvisor:$GetAdvisor -GetApmConnector:$GetApmConnector -GetBID:$GetBID -GetConfigService:$GetConfigService -GetDAS:$GetDAS -GetFailover:$GetFailover -GetManaged:$GetManaged -GetNASM:$GetNASM -GetNative:$GetNative -GetScript:$GetScript -GetUI:$GetUI -DebugTrace:$DebugTrace -VerboseTrace:$VerboseTrace -NetworkTrace:$NetworkTrace -OpsMgrModuleLogging:$OpsMgrModuleLogging -RestartSCOMServices:$RestartSCOMServices -DetectOpsMgrEventID $DetectOpsMgrEventID -SleepSeconds $SleepSeconds
}
else {
    # Enter Switches here that you want to run if no switches are specified during runtime.
    Start-ETLTrace
}
