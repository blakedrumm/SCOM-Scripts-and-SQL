<#
	.SYNOPSIS
		Get-SCOMEventLogs
	
	.DESCRIPTION
		This Script Collects Event Log data from Remote Servers and the Local Machine if defined. It will collect all of these and finally zip the files up into a easy to transport zip file. 
		If you need to collect more logs than just Application, System, and Operations Manager. Please change line 35 [String[]]$Logs.
	
	.PARAMETER Servers
		Add DNS Hostnames you would like to retrieve the Event Logs from like this: Agent1.contoso.com, Agent2.contoso.com
	
	.PARAMETER CaseNumber
		A description of the CaseNumber parameter.
	
	.EXAMPLE
				PS C:\> .\Get-SCOMEventLogs.ps1 -Servers Agent1.contoso.com, Agent2.contoso.com
	
	.NOTES
		Additional information about the file.
#>
[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false,
			   Position = 1)]
	[String[]]$Servers,
	[Parameter(Mandatory = $false,
			   Position = 2)]
	[string]$CaseNumber
)
# --------------------------------------------------------------------
# --------------------------------------------------------------------

#Modify this if you need more logs
[String[]]$Logs = "Application", "System", "Operations Manager"

#Add FQDN of Servers here (Comment this line to run against the local machine):
$DefinedServers = @("Agent2.contoso.com", "Agent1.contoso.com", "MS1.contoso.com", "MS2.contoso.com", "Exch1.contoso.com")

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
function Get-SCOMEventLogs
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $false,
				   Position = 1)]
		[String[]]$Servers,
		[Parameter(Position = 2)]
		[string]$CaseNumber
	)
	
	$ScriptPath = "$env:USERPROFILE\Documents"
	
	if ($CaseNumber)
	{
		$CaseNumber | Out-String
		$OutputPath = "$ScriptPath\Event Log Output - $CaseNumber"
	}
	else
	{
		$OutputPath = "$ScriptPath\Event Log Output"
	}
	
	IF (!(Test-Path $OutputPath))
	{
		Time-Stamp
		Write-Host "Output folder not found.  Creating folder: $OutputPath" -ForegroundColor Gray
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
			Time-Stamp
			Write-Host "  Exporting log: " -NoNewline
			Write-Host $log -ForegroundColor Magenta -NoNewline
			Write-Host " "
			if ($server -notmatch $env:COMPUTERNAME)
			{
				try
				{
					Invoke-Command -ComputerName $server {
						$fileCheck = test-path "c:\windows\Temp\$using:server.$using:log.evtx"
						if ($fileCheck -eq $true)
						{
							Remove-Item "c:\windows\Temp\$using:server.$using:log.evtx" -Force
						}
						wevtutil epl $using:log "c:\windows\Temp\$using:server.$using:log.evtx"
						wevtutil al "c:\windows\Temp\$using:server.$using:log.evtx"
					} -ErrorAction Stop
					$fileCheck2 = test-path "$OutputPath\$server" -ErrorAction Stop
					if (!($fileCheck2))
					{
						New-Item -ItemType directory -Path "$OutputPath" -Name "$server" -ErrorAction Stop | Out-Null
						New-Item -ItemType directory -Path "$OutputPath\$server" -Name "localemetadata" -ErrorAction Stop | Out-Null
					}
					Copy-Item "\\$server\c$\windows\temp\$server.$log.evtx" "$OutputPath\$server" -force -ErrorAction Stop
					#"Get-ChildItem \\$server\c$\windows\temp\localemetadata\"
					Get-ChildItem "\\$server\c$\windows\temp\localemetadata\" -ErrorAction Stop |
					where { $_.name -like "*$server*" -and $_.name -like "*$log*" } |
					Copy-Item -Destination "$OutputPath\$server\localemetadata\" -recurse -force -ErrorAction Stop
				}
				catch
				{
					Time-Stamp
					Write-Warning "  Unable to access $server remotely"
					break
				}
				
			}
			else
			{
				$fileCheck = test-path "c:\windows\Temp\$server.$log.evtx"
				if ($fileCheck -eq $true)
				{
					Remove-Item "c:\windows\Temp\$server.$log.evtx" -Force | Out-Null
				}
				wevtutil epl $log "c:\windows\Temp\$server.$log.evtx"
				wevtutil al "c:\windows\Temp\$server.$log.evtx"
				
				$fileCheck2 = test-path "$OutputPath\$server"
				if (!($fileCheck2))
				{
					New-Item -ItemType directory -Path "$OutputPath" -Name "$server" | Out-Null
					New-Item -ItemType directory -Path "$OutputPath\$server" -Name "localemetadata" | Out-Null
				}
				Copy-Item "C:\windows\temp\$server.$log.evtx" "$OutputPath\$server" -force
				#"Get-ChildItem \\$server\c$\windows\temp\localemetadata\"
				Get-ChildItem "C:\windows\temp\localemetadata\" |
				where { $_.name -like "*$server*" -and $_.name -like "*$log*" } |
				Copy-Item -Destination "$OutputPath\$server\localemetadata\" -recurse -force
			}
		}
		
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
		Write-Host "Found existing zip file: $destfile.`n Deleting existing file." -ForegroundColor DarkGreen
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

#Change FQDN of Servers Below

if ($DefinedServers)
{
	Get-SCOMEventLogs -Servers $DefinedServers
}
else
{
	Get-SCOMEventLogs
}