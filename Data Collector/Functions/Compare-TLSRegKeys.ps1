	Function Compare-TLSRegKeys
	{
		[CmdletBinding()]
		Param
		(
			[string[]]$Servers
		)
		Write-Host "  Accessing Registry on:`n" -NoNewline -ForegroundColor Gray
		foreach ($server in $servers)
		{
			Write-Host "     $server" -NoNewline -ForegroundColor Cyan
			$localresults = @()
			Invoke-Command -ComputerName $server {
				Write-Host "-" -NoNewline -ForegroundColor Green
				$LHost = $env:computername
				$ProtocolList = "TLS 1.0", "TLS 1.1", "TLS 1.2"
				$ProtocolSubKeyList = "Client", "Server"
				$DisabledByDefault = "DisabledByDefault"
				$Enabled = "Enabled"
				$registryPath = "HKLM:\\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\"
				#write-output "Working on $LHost"
				foreach ($Protocol in $ProtocolList)
				{
					foreach ($key in $ProtocolSubKeyList)
					{
						#write-output "Checking for $protocol\$key"
						Write-Host "-" -NoNewline -ForegroundColor Green
						$currentRegPath = $registryPath + $Protocol + "\" + $key
						
						$IsDisabledByDefault = @()
						$IsEnabled = @()
						$localresults = @()
						if (!(Test-Path $currentRegPath))
						{
							#write-output "$currentRegPath Does not exist on $lhost"
							$IsDisabledByDefault = "Null"
							$IsEnabled = "Null"
						}
						else
						{
							$IsDisabledByDefault = (Get-ItemProperty -Path $currentRegPath -Name $DisabledByDefault -ea 0).DisabledByDefault
							if ($IsDisabledByDefault -eq 4294967295)
							{
								$IsDisabledByDefault = "0xffffffff"
							}
							if ($IsDisabledByDefault -eq $null)
							{
								$IsDisabledByDefault = "DoesntExist"
							}
							
							$IsEnabled = (Get-ItemProperty -Path $currentRegPath -Name $Enabled -ea 0).Enabled
							if ($IsEnabled -eq 4294967295)
							{
								$isEnabled = "0xffffffff"
							}
							if ($IsEnabled -eq $null)
							{
								$IsEnabled = "DoesntExist"
							}
							
						}
						$localresults = "PipeLineKickStart" | select @{ n = 'Server'; e = { $LHost } },
																	 @{ n = 'Protocol'; e = { $Protocol } },
																	 @{ n = 'Type'; e = { $key } },
																	 @{ n = 'DisabledByDefault'; e = { $IsDisabledByDefault } },
																	 @{ n = 'IsEnabled'; e = { $IsEnabled } }
						$localresults
					}
				}
			}
			Write-Host "> Completed!`n" -NoNewline -ForegroundColor Green
		}
	}