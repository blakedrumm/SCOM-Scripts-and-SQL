Function Get-SCOMEventLogs
{
	[cmdletbinding()]
	param (
		[String[]]$Servers
	)
	
	[String[]]$Logs = "Application", "System", "Operations Manager"
	$servers = $servers | select -Unique
	
	foreach ($server in $servers)
	{
		Write-Output " "
		foreach ($log in $logs)
		{
			If ($Comp -match $server)
			{
				# If running locally do the below
				Write-Host "    Locally " -NoNewline -ForegroundColor DarkCyan
				Write-Host "Exporting Event Log " -NoNewline -ForegroundColor Cyan
				Write-Host "on " -NoNewline -ForegroundColor DarkCyan
				Write-Host "$server " -NoNewline -ForegroundColor Cyan
				Write-Host ": " -NoNewline -ForegroundColor DarkCyan
				Write-Host "$log" -NoNewline -ForegroundColor Cyan
				$fileCheck = test-path "c:\windows\Temp\$server.$log.evtx"
				if ($fileCheck -eq $true)
				{
					Remove-Item "c:\windows\Temp\$server.$log.evtx" -Force
				}
				Write-Host "-" -NoNewline -ForegroundColor Green;
				$eventcollect = wevtutil epl $log "c:\windows\Temp\$server.$log.evtx"; wevtutil al "c:\windows\Temp\$server.$log.evtx"
				do { Write-Host "-" -NoNewline -ForegroundColor Green; sleep 1 }
				while ($eventcollect)
				Write-Host "> Collected Events`n" -NoNewline -ForegroundColor Green
				try
				{
					Write-Host "     Locally moving files using Move-Item" -NoNewline -ForegroundColor DarkCyan
					$movelocalevtx = Move-Item "C:\Windows\temp\$server.$log.evtx" $ScriptPath\output -force -ErrorAction Stop; Move-Item "C:\Windows\temp\localemetadata\*.mta" $ScriptPath\output -force -ErrorAction Stop
					Write-Host "-" -NoNewline -ForegroundColor Green
					do { Write-Host "-" -NoNewline -ForegroundColor Green; sleep 1 }
					while ($movelocalevtx | Out-Null)
					Write-Host "> Transfer Completed!" -NoNewline -ForegroundColor Green
					Write-Output " "
					continue
				}
				catch
				{
					Write-Warning $_
				}
				try
				{
					Write-Host "     Locally moving files using Robocopy" -NoNewline -ForegroundColor DarkCyan
					Robocopy "C:\Windows\temp" "$ScriptPath\output" "$server.$log.evtx" /MOVE /R:2 /W:10 | Out-Null
					Robocopy "C:\Windows\temp\localemetadata" "$ScriptPath\output" "*.MTA" /MOVE /R:2 /W:10 | Out-Null
					Write-Host "      Transfer Completed!" -NoNewline -ForegroundColor Green
					Write-Output " "
					continue
				}
				catch
				{
					Write-Warning $_
				}
			}
			else
			{
				# If not the Computer Running this Script, do the below.
				Write-Host "    Remotely " -NoNewline -ForegroundColor DarkCyan
				Write-Host "Exporting Event Log " -NoNewline -ForegroundColor Cyan
				Write-Host "on " -NoNewline -ForegroundColor DarkCyan
				Write-Host "$server " -NoNewline -ForegroundColor Cyan
				Write-Host ": " -NoNewline -ForegroundColor DarkCyan
				Write-Host "$log" -NoNewline -ForegroundColor Cyan
				Write-Host "-" -NoNewline -ForegroundColor Green
				try
				{
					Invoke-Command -ComputerName $server {
						
						
						$localAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
						if ($localadmin) { $LA = "$true" }
						else { $LA = "$false" }
						
						
						$fileCheck = test-path "c:\windows\Temp\$using:server.$using:log.evtx"
						if ($fileCheck -eq $true)
						{
							Remove-Item "c:\windows\Temp\$using:server.$using:log.evtx" -Force
						}
						Write-Host "-" -NoNewline -ForegroundColor Green
						if ($la -eq $true)
						{
							try
							{
								$eventcollect = wevtutil epl $using:log "c:\windows\Temp\$using:server.$using:log.evtx"; wevtutil al "c:\windows\Temp\$using:server.$using:log.evtx"
								do { Write-Host "-" -NoNewline -ForegroundColor Green; sleep 1 }
								while ($eventcollect)
								Write-Host "> Collected Events" -NoNewline -ForegroundColor Green
							}
							catch
							{
								Write-Warning $_
							}
						}
						Write-Output " "
						continue
					}
				}
				catch { Write-Warning $_ }
				try
				{
					Write-Host "     Transferring using Move-Item" -NoNewLine -ForegroundColor DarkCyan
					$moveevents = Move-Item "\\$server\c$\windows\temp\$server.$log.evtx" $ScriptPath\output -force -ErrorAction Stop; Move-Item "\\$server\c$\windows\temp\localemetadata\*.mta" $ScriptPath\output -force -ErrorAction Stop
					Write-Host "-" -NoNewline -ForegroundColor Green
					do { Write-Host "-" -NoNewline -ForegroundColor Green; sleep 1 }
					while ($moveevents)
					Write-Host "> Transfer Completed!" -NoNewline -ForegroundColor Green
					Write-Output " "
					continue
				}
				catch
				{
					Write-Warning $_
				}
				try
				{
					Write-Host "     Transferring using Robocopy" -NoNewline -ForegroundColor DarkCyan
					Robocopy "\\$server\c$\windows\temp" "$ScriptPath\output" "$server.$log.evtx" /MOVE /R:2 /W:10 | Out-Null
					Robocopy "\\$server\c$\windows\temp\localemetadata" "$ScriptPath\output" "*.MTA" /MOVE /R:2 /W:10 | Out-Null
					Write-Host "      Transfer Completed!" -NoNewline -ForegroundColor Green
					continue
				}
				catch
				{
					Write-Warning $_
				}
			}
		}
	}
	
}