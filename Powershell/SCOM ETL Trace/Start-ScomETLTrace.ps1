<#
	.SYNOPSIS
		Start-ScomETLTrace
	
	.DESCRIPTION
		This will allow you to gather an ETL Trace from an Operations Manager Server or Agent.
		The Script will detect the location of the ETL Tools based on this registry path: 
		HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup
	
	.PARAMETER GetAdvisor
		Gather the Advisor.
	
	.PARAMETER GetAPM
		Gather the APM.
	
	.PARAMETER GetApmConnector
		Gather the APM Connector.
	
	.PARAMETER GetBID
		Gather the BID.
	
	.PARAMETER GetConfigService
		Gather the ConfigService.
	
	.PARAMETER GetDAS
		Gather the DAS.
	
	.PARAMETER GetFailover
		Gather the Failover.
	
	.PARAMETER GetManaged
		Gather the Managed.
	
	.PARAMETER GetNASM
		Gather the NASM.
	
	.PARAMETER GetNative
		Gather the Native.
	
	.PARAMETER GetScript
		Gather the Script.
	
	.PARAMETER GetUI
		Gather the UI.
	
	.PARAMETER DebugTrace
		Gather Debug Trace, the Same as: StartTracing.cmd DBG
	
	.PARAMETER VerboseTrace
		Gather Verbose Trace, the Same as: StartTracing.cmd VER
	
	.PARAMETER NetworkTrace
		A description of the NetworkTrace parameter.
	
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
		.\Start-ScomETLTrace.ps1 -SleepSeconds 300
	
	.NOTES
		.AUTHOR
		Blake Drumm (https://github.com/blakedrumm)
		
		.CREATED
		September 3rd 2020
		
		.MODIFIED
		July 19th, 2021
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
	[Parameter(Mandatory = $false,
			   Position = 16)]
	[switch]$RestartSCOMServices,
	[Parameter(Mandatory = $false,
			   Position = 17)]
	[int64]$DetectOpsMgrEventID,
	[Parameter(Mandatory = $false,
			   Position = 18)]
	[int64]$SleepSeconds = 10
)
trap
{
	Write-Warning "Encountered an Exception: $_"
}
Write-Host @"
===============================================================
System Center Operations Manager ETL / Network Trace Gathering
===============================================================

"@
Function Start-ETLTrace
{
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
		[Parameter(Mandatory = $false,
				   Position = 16)]
		[switch]$RestartSCOMServices,
		[Parameter(Mandatory = $false,
				   Position = 17)]
		[int64]$DetectOpsMgrEventID,
		[Parameter(Mandatory = $false,
				   Position = 18)]
		[int64]$SleepSeconds = 10
	)
	$Loc = $env:COMPUTERNAME
	$date = Get-Date -Format "MM.dd.yyyy-hh.mmtt"
	$Mod = $loc + "-" + $date
	try
	{
		$installdir = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup" -ErrorAction Stop | Select-Object -Property "InstallDirectory" -ExpandProperty "InstallDirectory"
		$installdir = $installdir + "Tools"
	}
	catch
	{
		Write-Warning "Exiting Script: Unable to locate the Install Directory`nHKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup"
		exit 1
	}
	Function Time-Stamp
	{
		
		$TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
		
		write-host "$TimeStamp - " -NoNewline
		
	}
	
	if ($null -ne ($GetAdvisor -or $GetAPM -or $GetApmConnector -or $GetBID -or $GetConfigService -or $GetDAS -or $GetFailover -or $GetManaged -or $GetNASM -or $GetNative -or $GetScript -or $GetUI -or $DebugTrace -or $VerboseTrace -or $NetworkTrace -or $RestartSCOMServices -or $DetectOpsMgrEventID -or $SleepSeconds))
	{
		$TempDirectory = "C:\Windows\Temp\SCOMTracingTemp"
		if (!(test-path $TempDirectory))
		{
			New-Item -ItemType Directory -Force -Path $TempDirectory
		}
	}
	
	# Start GetAdvisor Switch
	if ($GetAdvisor)
	{
		$TracingFiles = Get-ChildItem -Path "$installdir" -File Tracing* | Where { $_.Name -ne "TracingReadMe.txt" -and $_.Name -notlike "*Advisor*" }
		$TracingFiles | % { mv "$installdir`\$_" $TempDirectory }
	}
	
	# Start GetAPM Switch
	if ($GetAPM)
	{
		$APMTracingFiles = Get-ChildItem -Path "$installdir" -File Tracing* | Where { $_.Name -ne "TracingReadMe.txt" -and $_.Name -notlike "*APM*" }
		$APMTracingFiles | % { mv "$installdir`\$_" $TempDirectory }
	}
	
	# Start GetApmConnector Switch
	if ($GetApmConnector)
	{
		$APMTracingFiles = Get-ChildItem -Path "$installdir" -File Tracing* | Where { $_.Name -ne "TracingReadMe.txt" -and $_.Name -notlike "*ApmConnector*" }
		$APMTracingFiles | % { mv "$installdir`\$_" $TempDirectory }
	}
	
	# Start GetBID Switch
	if ($GetBID)
	{
		$APMTracingFiles = Get-ChildItem -Path "$installdir" -File Tracing* | Where { $_.Name -ne "TracingReadMe.txt" -and $_.Name -notlike "*BID*" }
		$APMTracingFiles | % { mv "$installdir`\$_" $TempDirectory }
	}
	
	# Start GetConfigService Switch
	if ($GetConfigService)
	{
		$APMTracingFiles = Get-ChildItem -Path "$installdir" -File Tracing* | Where { $_.Name -ne "TracingReadMe.txt" -and $_.Name -notlike "*ConfigService*" }
		$APMTracingFiles | % { mv "$installdir`\$_" $TempDirectory }
	}
	
	# Start GetDAS Switch
	if ($GetDAS)
	{
		$APMTracingFiles = Get-ChildItem -Path "$installdir" -File Tracing* | Where { $_.Name -ne "TracingReadMe.txt" -and $_.Name -notlike "*DAS*" }
		$APMTracingFiles | % { mv "$installdir`\$_" $TempDirectory }
	}
	
	# Start GetFailover Switch
	if ($GetFailover)
	{
		$APMTracingFiles = Get-ChildItem -Path "$installdir" -File Tracing* | Where { $_.Name -ne "TracingReadMe.txt" -and $_.Name -notlike "*Failover*" }
		$APMTracingFiles | % { mv "$installdir`\$_" $TempDirectory }
	}
	
	# Start GetManaged Switch
	if ($GetManaged)
	{
		$APMTracingFiles = Get-ChildItem -Path "$installdir" -File Tracing* | Where { $_.Name -ne "TracingReadMe.txt" -and $_.Name -notlike "*Managed*" }
		$APMTracingFiles | % { mv "$installdir`\$_" $TempDirectory }
	}
	
	# Start GetNASM Switch
	if ($GetNASM)
	{
		$APMTracingFiles = Get-ChildItem -Path "$installdir" -File Tracing* | Where { $_.Name -ne "TracingReadMe.txt" -and $_.Name -notlike "*NASM*" }
		$APMTracingFiles | % { mv "$installdir`\$_" $TempDirectory }
	}
	
	# Start GetNative Switch
	if ($GetNative)
	{
		$APMTracingFiles = Get-ChildItem -Path "$installdir" -File Tracing* | Where { $_.Name -ne "TracingReadMe.txt" -and $_.Name -notlike "*Native*" }
		$APMTracingFiles | % { mv "$installdir`\$_" $TempDirectory }
	}
	
	# Start GetScript Switch
	if ($GetScript)
	{
		$APMTracingFiles = Get-ChildItem -Path "$installdir" -File Tracing* | Where { $_.Name -ne "TracingReadMe.txt" -and $_.Name -notlike "*Script*" }
		$APMTracingFiles | % { mv "$installdir`\$_" $TempDirectory }
	}
	
	# Start GetUI Switch
	if ($GetUI)
	{
		$APMTracingFiles = Get-ChildItem -Path "$installdir" -File Tracing* | Where { $_.Name -ne "TracingReadMe.txt" -and $_.Name -notlike "*UI*" }
		$APMTracingFiles | % { mv "$installdir`\$_" $TempDirectory }
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
	foreach ($process in $runningPowerShellInstances)
	{
		if (($currentPID -ne $process.ProcessId))
		{
			try
			{
				if (($process.Commandline.Contains('FormatTrace.ps1')))
				{
					#Exit the script since we are already running
					'Script already running in another powershell instance.  This one will exit' | WriteLog
					EventCreate /T INFORMATION /ID 50 /SO "AlertSubDiagnosticTask" /L "Operations Manager" /D "Diagnostic Task Already running. This instance will exit." | WriteLog
					break;
				}
			}
			catch { }
		}
	}
	
	Function Start-ScomETLTrace
	{
		Time-Stamp
		write-host "Stopping any existing Trace(s)" -ForegroundColor DarkCyan
		try
		{
			Start-Process "$env:SystemRoot\SYSWOW64\cmd.exe" "/c `"$installdir`\StopTracing.cmd`"" -WorkingDirectory $installdir -Wait | out-null
			if ($NetworkTrace)
			{
				Time-Stamp
				write-host "  Stopping any existing Network Trace" -ForegroundColor Gray
				do { Write-Host "." -NoNewline -ForegroundColor DarkCyan; sleep 1 }
				until (Netsh trace stop)
			}
			Write-Host " "
		}
		catch
		{
			Time-Stamp
			Write-Host $_
		}
		do
		{
			if (!$VerboseTrace -and !$DebugTrace)
			{
				Time-Stamp
				Write-Host "No Trace Type Selected (Verbose / Debug), will proceed with Verbose as default." -ForegroundColor DarkGray
				$answer = "verbose"
			}
			if ($VerboseTrace)
			{
				$answer = "verbose"
			}
			elseif ($DebugTrace)
			{
				$answer = "debug"
			}
		}
		until (($answer -eq "verbose" -or "v") -or ($answer -eq "debug" -or "d"))
		if ($RestartSCOMServices)
		{
			Time-Stamp
			write-host "Stopping `'System Center Data Access Service`'" -ForegroundColor DarkCyan
			stop-service OMSDK -ErrorAction SilentlyContinue
			Time-Stamp
			write-host "Stopping `'System Center Management Configuration`' Service" -ForegroundColor DarkCyan
			stop-service cshost -ErrorAction SilentlyContinue
			Time-Stamp
			write-host "Stopping `'Microsoft Monitoring Agent`' Service" -ForegroundColor DarkCyan
			stop-service healthservice -ErrorAction SilentlyContinue
		}
		Time-Stamp
		write-host "Removing stale log files" -ForegroundColor DarkCyan
		try
		{
			Remove-Item C:\Windows\Logs\OpsMgrTrace\* -force -Confirm:$false -ErrorAction Stop | Out-Null
		}
		catch
		{
			Time-Stamp
			Write-Warning "Attempted to remove the files in directory `"C:\Windows\Logs\OpsMgrTrace\*`" and received:`n`t`t`t`t$_"
			try
			{
				Move-Item -Destination C:\Windows\Logs\OpsMgrTrace C:\Windows\Logs\OpsMgrTrace.old -Force -ErrorAction Stop | Out-Null
			}
			catch
			{
				Time-Stamp
				Write-Warning "Attempted to Move Folder from `"C:\Windows\Logs\OpsMgrTrace`" to `"C:\Windows\Logs\OpsMgrTrace.old`" and receieved the following message:`n`t`t`t`t$_"
			}
		}
		if ($NetworkTrace)
		{
			Time-Stamp
			Write-Host "Starting Network Trace" -ForegroundColor Cyan
			Netsh trace start scenario=netconnection capture=yes maxsize=3000 tracefile=C:\Windows\Temp\$mod.etl | out-null
		}
		if (($answer -eq "verbose") -or ($answer -eq "v"))
		{
			try
			{
				Time-Stamp
				write-host "Starting ETL trace at Verbose level" -ForegroundColor Cyan
				Start-Process "$env:SystemRoot\SYSWOW64\cmd.exe" "/c `"$installdir`\StartTracing.cmd`" VER" -WorkingDirectory $installdir -Wait | out-null
				#[string] $Out = $ps.StandardOutput.ReadToEnd();
				#[void](Invoke-Item "" 'VER' -)
				Time-Stamp
				write-host "Process Completed!" -ForegroundColor DarkCyan
			}
			catch
			{
				Time-Stamp
				Write-Host $_
			}
		}
		elseif (($answer -eq "debug") -or ($answer -eq "d"))
		{
			try
			{
				Time-Stamp
				write-host "Starting ETL trace at Debug level" -ForegroundColor Cyan
				Start-Process "$env:SystemRoot\SYSWOW64\cmd.exe" "/c `"$installdir`\StartTracing.cmd`" DBG" -WorkingDirectory $installdir -Wait | out-null
				Time-Stamp
				write-host "Process Completed!" -ForegroundColor DarkCyan
			}
			catch
			{
				Time-Stamp
				Write-Host $_
			}
		}
		if ($RestartSCOMServices)
		{
			Time-Stamp
			write-host "Starting `'Microsoft Monitoring Agent`' Service" -ForegroundColor DarkCyan
			start-service healthservice -ErrorAction SilentlyContinue
			Time-Stamp
			write-host "Starting `'System Center Data Access Service`'" -ForegroundColor DarkCyan
			start-service OMSDK -ErrorAction SilentlyContinue
			Time-Stamp
			write-host "Starting `'System Center Management Configuration`' Service" -ForegroundColor DarkCyan
			start-service cshost -ErrorAction SilentlyContinue
		}
	}
	Start-ScomETLTrace
	if ($DetectOpsMgrEventID)
	{
		Time-Stamp
		Write-Host "Starting Detection of OperationsManager Event ID " -NoNewLine -ForegroundColor DarkGreen
		Write-Host "(Checking every $SleepSeconds seconds): " -NoNewline -ForegroundColor DarkCyan
		Write-Host $DetectOpsMgrEventID -NoNewline -ForegroundColor Cyan
		do
		{
			Write-Host '.' -NoNewline -ForegroundColor DarkCyan
			$Date = $null
			$events = $null
			$foundEventID = $false
			$Date = (Get-Date).AddSeconds("`-" + ($SleepSeconds + 2))
			$events = Get-WinEvent -FilterHashtable @{ LogName = 'Operations Manager'; StartTime = $Date; Id = $DetectOpsMgrEventID } -ErrorAction SilentlyContinue
			if ($events)
			{
				Write-Host ' '
				Time-Stamp
				Write-Host 'Found the Event ID:' -ForegroundColor Green -NoNewline
				Write-Host $DetectOpsMgrEventID -NoNewline -ForegroundColor Cyan
				Write-Host "!" -ForegroundColor DarkCyan
				$foundEventID = $true
			}
			else
			{
				sleep $SleepSeconds
			}
		}
		until ($foundEventID)
	}
	else
	{
		if ($SleepSeconds -eq 10)
		{
			Time-Stamp
			Write-Host "Once you have reproduced the issue, Press Enter to continue." -ForegroundColor Green
			pause
		}
		else
		{
			Time-Stamp
			Write-Host "Sleeping for $SleepSeconds seconds and then continuing automatically." -ForegroundColor DarkCyan
			sleep $SleepSeconds
		}
		
	}
	
	Time-Stamp
	Write-Host "Stopping ETL Trace" -ForegroundColor Cyan
	Start-Process "$env:SystemRoot\SYSWOW64\cmd.exe" "/c `"$installdir`\StopTracing.cmd`"" -WorkingDirectory $installdir -Wait | out-null
	if ($NetworkTrace)
	{
		Time-Stamp
		Write-Host "Stopping Network Trace" -ForegroundColor Cyan -NoNewLine
		do { Write-Host "." -NoNewLine -ForegroundColor Cyan; Sleep 1 }
		until (Netsh trace stop)
		Write-Host " "
	}
	Time-Stamp
	Write-Host "Formatting ETL Trace" -ForegroundColor Cyan
	#& $installdir`\FormatTracing.cmd
	#[string]$formatTraceFile = 'C:\Windows\Temp\scomETLtrace\FormatTrace.ps1'
	#$formatTrace | out-file -FilePath $formatTraceFile -Encoding ascii
	#FormatTracing using the non-interactive FormatTracing file
	#$command = $formatTraceFile + " `"'" + $installdir + "'`""
	#start-process powershell.exe -ArgumentList $command -WorkingDirectory $installdir -Wait -WorkingDirectory $installdir -NoNewWindow -Wait
	
	#Start-Process -FilePath cmd.exe -ArgumentList '/c', "`"$installdir`\FormatTracing.cmd`"" -WorkingDirectory $installdir -Wait -WorkingDirectory $installdir -NoNewWindow -Wait
	
	Start-Process "$env:SystemRoot\SYSWOW64\cmd.exe" "/c `"$installdir`\FormatTracing.cmd`"" -WorkingDirectory $installdir -Wait | out-null
	
	#Move Files
	Time-Stamp
	Write-Host "Moving/Copying Files around"
	
	$TempETLTrace = "C:\Windows\Temp\scomETLtrace"
	if ($NetworkTrace)
	{
		$NetworkTracePath = "C:\Windows\Temp\scomETLtrace\Network Trace"
		if (!(Test-Path $NetworkTracePath) | Out-Null)
		{
			mkdir "C:\Windows\Temp\scomETLtrace\Network Trace" -Force | Out-Null
		}
		Move-Item "C:\Windows\Temp\$mod`.etl" "C:\Windows\Temp\scomETLtrace\Network Trace" -Force | Out-Null
	}
	$ETLFolder = "C:\Windows\Temp\scomETLtrace\ETL"
	if (!(Test-Path $TempETLTrace) | Out-Null)
	{
		mkdir C:\Windows\Temp\scomETLtrace -Force | Out-Null
	}
	
	
	Move-Item $TempDirectory\*.txt "$installdir" -Force | Out-Null
	
	if (!(Test-Path $ETLFolder))
	{
		mkdir C:\Windows\Temp\scomETLtrace\ETL | Out-Null
	}
	else
	{
		Remove-Item C:\Windows\Temp\scomETLtrace\* -Recurse -Confirm:$false | Out-Null
	}
	Copy-Item "C:\Windows\Logs\OpsMgrTrace\*" "C:\Windows\Temp\scomETLtrace\ETL" -Force | Out-Null
	
	#Zip output
	Time-Stamp
	Write-Host "Zipping up Trace Output." -ForegroundColor DarkCyan
	[Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
	[System.AppDomain]::CurrentDomain.GetAssemblies() | Out-Null
	$SourcePath = Resolve-Path "C:\Windows\Temp\scomETLtrace"
	
	[string]$destfilename = "$Mod`.zip"
	
	[string]$destfile = "C:\Windows\Temp\$destfilename"
	if (Test-Path $destfile)
	{
		#File exists from a previous run on the same day - delete it
		Time-Stamp
		Write-Host "Found existing zip file: $destfile.`n Deleting existing file." -ForegroundColor DarkGreen
		Remove-Item $destfile -Force | Out-Null
	}
	$compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
	$includebasedir = $false
	[System.IO.Compression.ZipFile]::CreateFromDirectory($SourcePath, $destfile, $compressionLevel, $includebasedir) | Out-Null
	Remove-Item "C:\Windows\Temp\scomETLtrace" -Recurse -Confirm:$false
	if ($Error)
	{
		Time-Stamp
		Write-Warning "Error creating zip file."
		Write-Host $_
	}
	else
	{
		Time-Stamp
		Write-Host "Cleaning up output directory." -ForegroundColor DarkCyan
		Remove-Item "C:\Windows\Temp\scomETLtrace" -Recurse | Out-Null
		Time-Stamp
		Write-Host "Saved zip file to: $destfile`." -ForegroundColor Cyan
	}
	
	C:\Windows\explorer.exe "/select,$destfile"
}
if ($GetAdvisor -or $GetAPM -or $GetApmConnector -or $GetBID -or $GetConfigService -or $GetDAS -or $GetFailover -or $GetManaged -or $GetNASM -or $GetNative -or $GetScript -or $GetUI -or $DebugTrace -or $VerboseTrace -or $NetworkTrace -or $RestartSCOMServices -or $DetectOpsMgrEventID)
{
	Start-ETLTrace -GetAdvisor:$GetAdvisor -GetApmConnector:$GetApmConnector -GetBID:$GetBID -GetConfigService:$GetConfigService -GetDAS:$GetDAS -GetFailover:$GetFailover -GetManaged:$GetManaged -GetNASM:$GetNASM -GetNative:$GetNative -GetScript:$GetScript -GetUI:$GetUI -DebugTrace:$DebugTrace -VerboseTrace:$VerboseTrace -NetworkTrace:$NetworkTrace -RestartSCOMServices:$RestartSCOMServices -DetectOpsMgrEventID $DetectOpsMgrEventID -SleepSeconds $SleepSeconds
}
else
{
	# Enter Switches here that you want to run if no switches are specified during runtime.
	Start-ETLTrace
}
