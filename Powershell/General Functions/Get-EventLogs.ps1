<#
	.SYNOPSIS
		Get-EventLogs
	
	.DESCRIPTION
		This Script Collects Event Log data from Remote Servers and the Local Machine if defined. It will collect all of these and finally zip the files up into a easy to transport zip file.
		If you need to collect more logs than just Application, System, and Operations Manager. Please change line 81 [String[]]$Logs.
	
	.PARAMETER Servers
		Add DNS Hostnames you would like to retrieve the Event Logs from like this: Agent1.contoso.com, Agent2.contoso.com
	
	.PARAMETER Logs
		Gather specific Event Logs from Remote or Local Machine.
	
	.PARAMETER CaseNumber
		Set the casenumber you would like to save with the filename in the output.
	
	.EXAMPLE
		PS C:\> .\Get-EventLogs.ps1 -Servers Agent1.contoso.com, Agent2.contoso.com -Logs Application, System
	
	.NOTES
		Additional information about the file.
		
		Last Modified: 1/14/2022
		
	    .AUTHOR
	        Blake Drumm (blakedrumm@microsoft.com)
#>
[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false,
			   Position = 1)]
	[String[]]$Servers,
	[Parameter(Mandatory = $false,
			   Position = 2)]
	[String[]]$Logs,
	[Parameter(Mandatory = $false,
			   Position = 3)]
	[string]$CaseNumber
)

# --------------------------------------------------------------------
# --------------------------------------------------------------------

if ($Servers)
{
	$DefinedServers = $Servers
}

Function Time-Stamp
{
	$TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
	write-host "$TimeStamp - " -NoNewline
}
Time-Stamp
Write-Host "Starting Script to Gather Event Logs" -ForegroundColor Cyan
function Get-EventLogs
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $false,
				   Position = 1)]
		[String[]]$Servers,
		[Parameter(Mandatory = $false,
				   Position = 2)]
		[String[]]$Logs,
		[Parameter(Mandatory = $false,
				   Position = 3)]
		[string]$CaseNumber
	)
	
	$ScriptPath = "$env:USERPROFILE\Documents"
	
	#Modify this if you need more logs
	if ($Logs -eq $null)
	{
		[String[]]$Logs = 'Application', 'System', 'Security', 'Operations Manager', 'Windows PowerShell'
	}
	
	if ($CaseNumber)
	{
		$CaseNumber | Out-String
		$OutputPath = "$env:USERPROFILE\Desktop\Event Log Output - $CaseNumber"
	}
	else
	{
		$OutputPath = "$env:USERPROFILE\Desktop\Event Log Output"
	}
	
	IF (!(Test-Path $OutputPath))
	{
		Time-Stamp
		Write-Host "Output folder not found." -ForegroundColor Gray
		Time-Stamp
		Write-Host "Creating folder: " -ForegroundColor DarkYellow -NoNewline
		Write-Host "$OutputPath" -ForegroundColor DarkCyan
		md $OutputPath | Out-Null
	}
	if ($servers)
	{
		$servers = $servers | select -Unique | sort
	}
	else
	{
		$servers = $env:COMPUTERNAME
	}
	foreach ($server in $servers)
	{
		Time-Stamp
		Write-Host "$server" -ForegroundColor Green
		foreach ($log in $logs)
		{
			
			if ($server -notmatch $env:COMPUTERNAME)
			{
				try
				{
					if ($log -like '*/*')
					{ $logname = $log.split('/')[0] }
					else { $logname = $log }
					Invoke-Command -ComputerName $server {
						Function Time-Stamp
						{
							$TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
							write-host "$TimeStamp - " -NoNewline
						}
						trap
						{
							Time-Stamp
							Write-Warning "$($error[0]) at line $($_.InvocationInfo.ScriptLineNumber)"
						}
						IF (!(Test-Path $using:OutputPath))
						{
							Time-Stamp
							Write-Host " Creating output folder on remote server: " -ForegroundColor DarkYellow -NoNewline
							Write-Host "$using:OutputPath" -ForegroundColor DarkCyan
							md $using:OutputPath | Out-Null
						}
						$availableLogs = $null
						$availableLogs = Get-EventLog * | Select Log -ExpandProperty Log
						$remoteLog = $using:log
						if ($remoteLog -notin $availableLogs)
						{
							$logText = $remoteLog.ToString().Replace("/", ".")
							Time-Stamp
							Write-Host "  Unable to locate $logText event logs on $using:server."
							Out-File "$using:OutputPath`\Unable to locate $logText event logs on $using:server."
							continue
						}
						$fileCheck = test-path "$using:OutputPath\$using:server`.$using:logname.evtx"
						if ($fileCheck)
						{
							Remove-Item "$using:OutputPath\$using:server`.$using:logname.evtx" -Force
						}
						Time-Stamp
						Write-Host "  Exporting log: " -NoNewline
						Write-Host $using:log -ForegroundColor Magenta -NoNewline
						Write-Host " "
						wevtutil epl $using:log "$using:OutputPath\$using:server.$using:logname.evtx"
						wevtutil al "$using:OutputPath\$using:server`.$using:logname.evtx"
					} -ErrorAction Stop
					$fileCheck2 = test-path "$OutputPath\$server" -ErrorAction Stop
					if (!($fileCheck2))
					{
						New-Item -ItemType directory -Path "$OutputPath" -Name "$server" -ErrorAction Stop | Out-Null
						New-Item -ItemType directory -Path "$OutputPath\$server" -Name "localemetadata" -ErrorAction Stop | Out-Null
					}
					$UNCPath = ($OutputPath).Replace(":", "$")
					Move-Item "\\$server\$UNCPath\$server.$logname.evtx" "$OutputPath\$server" -force -ErrorAction Stop
					#"Get-ChildItem \\$server\c$\Users\$env:USERNAME\Desktop\localemetadata\"
					Get-ChildItem "\\$server\$UNCPath\localemetadata\" -ErrorAction Stop |
					where { $_.name -like "*$server*" -and $_.name -like "*$logname*" } |
					Move-Item -Destination "$OutputPath\$server\localemetadata\" -force -ErrorAction Stop
				}
				catch
				{
					Time-Stamp
					Write-Warning "$($error[0]) at line $($_.InvocationInfo.ScriptLineNumber)"
					break
				}
				
			}
			else
			{
				if ($log -like '*/*')
				{ $logname = $log.split('/')[0] }
				else { $logname = $log }
				$fileCheck = test-path "$OutputPath\$server.$logname.evtx"
				if ($fileCheck -eq $true)
				{
					Remove-Item "$OutputPath\$server.$logname.evtx" -Force | Out-Null
				}
				$availableLogs = $null
				$availableLogs = Get-EventLog * | Select Log -ExpandProperty Log
				if ($log -notin $availableLogs)
				{
					$logText = $log.ToString().Replace("/", ".")
					Time-Stamp
					Write-Host "  Unable to locate $logText event logs on $server."
					Out-File "$OutputPath`\Unable to locate $logText event logs on $server."
					continue
				}
				Time-Stamp
				Write-Host "  Exporting log: " -NoNewline
				Write-Host $log -ForegroundColor Magenta -NoNewline
				Write-Host " "
				wevtutil epl $log "$OutputPath\$server.$logname.evtx"
				wevtutil al "$OutputPath\$server.$logname.evtx"
				
				$fileCheck2 = test-path "$OutputPath\$server"
				if (!($fileCheck2))
				{
					New-Item -ItemType directory -Path "$OutputPath" -Name "$server" | Out-Null
					New-Item -ItemType directory -Path "$OutputPath\$server" -Name "localemetadata" | Out-Null
				}
				Move-Item "$OutputPath\$server.$logname.evtx" "$OutputPath\$server" -force
				#"Get-ChildItem \\$server\c$\Users\$env:USERNAME\Desktop\localemetadata\"
				Get-ChildItem "$OutputPath\localemetadata\" |
				where { $_.name -like "*$server*" -and $_.name -like "*$logname*" } |
				Move-Item -Destination "$OutputPath\$server\localemetadata\" -force
			}
		}
		Remove-Item "\\$server\$UNCPath" -Recurse -Confirm:$false -Force -ErrorAction SilentlyContinue
		Remove-Item $OutputPath\localemetadata -Confirm:$false -Force -ErrorAction SilentlyContinue
	}
	#Zip output
	Time-Stamp
	Write-Host "Zipping up Output." -ForegroundColor DarkCyan
	[Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
	[System.AppDomain]::CurrentDomain.GetAssemblies() | Out-Null
	$SourcePath = Resolve-Path "$OutputPath"
	
	$date = Get-Date -Format "MM.dd.yyyy-hh.mmtt"
	$Mod = "EventLogs" + "-" + $date
	[string]$destfilename = "$Mod`.zip"
	
	[string]$destfile = "$ScriptPath\$destfilename"
	if (Test-Path $destfile)
	{
		#File exists from a previous run on the same day - delete it
		Time-Stamp
		Write-Host "Found existing zip file: $destfile." -ForegroundColor DarkGreen
		Time-Stamp
		Write-Host "Deleting existing file." -ForegroundColor Gray
		Remove-Item $destfile -Force
	}
	$compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
	$includebasedir = $false
	[System.IO.Compression.ZipFile]::CreateFromDirectory($SourcePath, $destfile, $compressionLevel, $includebasedir) | Out-Null
	Time-Stamp
	Write-Host "Saved zip file to: $destfile`." -ForegroundColor Cyan
	Remove-Item $OutputPath -Recurse
	Write-Warning "Exiting script..."
	start C:\Windows\explorer.exe -ArgumentList "/select, $destfile"
}
if ($DefinedServers -or $Logs -or $CaseNumber)
{
	Get-EventLogs -Servers $DefinedServers -Logs $Logs -CaseNumber:$CaseNumber
}
else
{
	#Change the default action of this script by changing the below line. By default the script will run locally unless a -Servers parameter is present here.
	Get-EventLogs
}
