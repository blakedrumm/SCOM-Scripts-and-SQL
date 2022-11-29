<#
	.SYNOPSIS
		Get-EventLogs
	
	.DESCRIPTION
		This Script Collects Event Log data from Remote Servers and the Local Machine if defined. It will collect all of these and finally zip the files up into a easy to transport zip file.
		If you need to collect more logs than just Application, System, and Operations Manager. Please change line 79 [String[]]$Logs.
	
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

# SIG # Begin signature block
# MIInlQYJKoZIhvcNAQcCoIInhjCCJ4ICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAzWma5++mHhhbD
# vzTpmjD1BpW78yPgAOd7qHgqBwHUuaCCDXYwggX0MIID3KADAgECAhMzAAACy7d1
# OfsCcUI2AAAAAALLMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjIwNTEyMjA0NTU5WhcNMjMwNTExMjA0NTU5WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQC3sN0WcdGpGXPZIb5iNfFB0xZ8rnJvYnxD6Uf2BHXglpbTEfoe+mO//oLWkRxA
# wppditsSVOD0oglKbtnh9Wp2DARLcxbGaW4YanOWSB1LyLRpHnnQ5POlh2U5trg4
# 3gQjvlNZlQB3lL+zrPtbNvMA7E0Wkmo+Z6YFnsf7aek+KGzaGboAeFO4uKZjQXY5
# RmMzE70Bwaz7hvA05jDURdRKH0i/1yK96TDuP7JyRFLOvA3UXNWz00R9w7ppMDcN
# lXtrmbPigv3xE9FfpfmJRtiOZQKd73K72Wujmj6/Su3+DBTpOq7NgdntW2lJfX3X
# a6oe4F9Pk9xRhkwHsk7Ju9E/AgMBAAGjggFzMIIBbzAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUrg/nt/gj+BBLd1jZWYhok7v5/w4w
# RQYDVR0RBD4wPKQ6MDgxHjAcBgNVBAsTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEW
# MBQGA1UEBRMNMjMwMDEyKzQ3MDUyODAfBgNVHSMEGDAWgBRIbmTlUAXTgqoXNzci
# tW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3JsMGEG
# CCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3J0
# MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIBAJL5t6pVjIRlQ8j4dAFJ
# ZnMke3rRHeQDOPFxswM47HRvgQa2E1jea2aYiMk1WmdqWnYw1bal4IzRlSVf4czf
# zx2vjOIOiaGllW2ByHkfKApngOzJmAQ8F15xSHPRvNMmvpC3PFLvKMf3y5SyPJxh
# 922TTq0q5epJv1SgZDWlUlHL/Ex1nX8kzBRhHvc6D6F5la+oAO4A3o/ZC05OOgm4
# EJxZP9MqUi5iid2dw4Jg/HvtDpCcLj1GLIhCDaebKegajCJlMhhxnDXrGFLJfX8j
# 7k7LUvrZDsQniJZ3D66K+3SZTLhvwK7dMGVFuUUJUfDifrlCTjKG9mxsPDllfyck
# 4zGnRZv8Jw9RgE1zAghnU14L0vVUNOzi/4bE7wIsiRyIcCcVoXRneBA3n/frLXvd
# jDsbb2lpGu78+s1zbO5N0bhHWq4j5WMutrspBxEhqG2PSBjC5Ypi+jhtfu3+x76N
# mBvsyKuxx9+Hm/ALnlzKxr4KyMR3/z4IRMzA1QyppNk65Ui+jB14g+w4vole33M1
# pVqVckrmSebUkmjnCshCiH12IFgHZF7gRwE4YZrJ7QjxZeoZqHaKsQLRMp653beB
# fHfeva9zJPhBSdVcCW7x9q0c2HVPLJHX9YCUU714I+qtLpDGrdbZxD9mikPqL/To
# /1lDZ0ch8FtePhME7houuoPcMIIHejCCBWKgAwIBAgIKYQ6Q0gAAAAAAAzANBgkq
# hkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEwOTA5WjB+MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQg
# Q29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+laUKq4BjgaBEm6f8MMHt03
# a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc6Whe0t+bU7IKLMOv2akr
# rnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4Ddato88tt8zpcoRb0Rrrg
# OGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+lD3v++MrWhAfTVYoonpy
# 4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nkkDstrjNYxbc+/jLTswM9
# sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6A4aN91/w0FK/jJSHvMAh
# dCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmdX4jiJV3TIUs+UsS1Vz8k
# A/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL5zmhD+kjSbwYuER8ReTB
# w3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zdsGbiwZeBe+3W7UvnSSmn
# Eyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3T8HhhUSJxAlMxdSlQy90
# lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS4NaIjAsCAwEAAaOCAe0w
# ggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRIbmTlUAXTgqoXNzcitW2o
# ynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYD
# VR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBDuRQFTuHqp8cx0SOJNDBa
# BgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2Ny
# bC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3JsMF4GCCsG
# AQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3J0MIGfBgNV
# HSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEFBQcCARYzaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1hcnljcHMuaHRtMEAGCCsG
# AQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkAYwB5AF8AcwB0AGEAdABl
# AG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn8oalmOBUeRou09h0ZyKb
# C5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7v0epo/Np22O/IjWll11l
# hJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0bpdS1HXeUOeLpZMlEPXh6
# I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/KmtYSWMfCWluWpiW5IP0
# wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvyCInWH8MyGOLwxS3OW560
# STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBpmLJZiWhub6e3dMNABQam
# ASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJihsMdYzaXht/a8/jyFqGa
# J+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYbBL7fQccOKO7eZS/sl/ah
# XJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbSoqKfenoi+kiVH6v7RyOA
# 9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sLgOppO6/8MO0ETI7f33Vt
# Y5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtXcVZOSEXAQsmbdlsKgEhr
# /Xmfwb1tbWrJUnMTDXpQzTGCGXUwghlxAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAALLt3U5+wJxQjYAAAAAAsswDQYJYIZIAWUDBAIB
# BQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDICuRUHSTkfBDqGkQtQb5UB
# lSp4M1P4RsO65NkqsIbaMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQCL9+4bPeOMyrR1VUY8G9g1VRN6PpfX1MyooDoVqVYaf6YPjEjIHIPD
# 5wYgRiu/vARUU2xYSTXdqlvdqH4Cd7J99l/UDcyZ0fT4N+85wYodXC+EvtOaW+vu
# +BIsbnKJC721zAIHQ5jvCztzXWsq9r4L09x5jy1EOUC/gZpDzN1awh8rdcM65uUs
# OnDGO7BH9iPwI34OThyg8TeSQWG3qeo4HMYLlgPFFBhgIoBfcKadELF3TDIKTjuC
# /bMU5wIIebpWtSN1FJLzguS3HN+1iEr/Py1sWmHJIwLKwabBnUDZSctYmOvyf2jB
# wvPOoxKJVtVW4ZvCCEoSv7KHEEh/UOwJoYIW/TCCFvkGCisGAQQBgjcDAwExghbp
# MIIW5QYJKoZIhvcNAQcCoIIW1jCCFtICAQMxDzANBglghkgBZQMEAgEFADCCAVEG
# CyqGSIb3DQEJEAEEoIIBQASCATwwggE4AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEIHZyG9dGEfdyuZB0lE+BazqIyyjiLF20wP2wuL+831y+AgZjbUPP
# 8SIYEzIwMjIxMTI5MjAzMDI5LjA2NlowBIACAfSggdCkgc0wgcoxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBB
# bWVyaWNhIE9wZXJhdGlvbnMxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOjIyNjQt
# RTMzRS03ODBDMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNl
# oIIRVDCCBwwwggT0oAMCAQICEzMAAAHBPqCDnOAJr8UAAQAAAcEwDQYJKoZIhvcN
# AQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQG
# A1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcNMjIxMTA0MTkw
# MTI3WhcNMjQwMjAyMTkwMTI3WjCByjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9u
# czEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046MjI2NC1FMzNFLTc4MEMxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQDksdczJ3DaFQLiklTQjm48mcx5GbwsoLjFogO7cXHH
# ciln9Z7apcuPg06ajD9Y8V5ji9pPj9LhP3GgOwUaDnAQkzo4tlV9rsFQ27S0O3iu
# SXtAFg0fPPqlyv1vBqraqbvHo/3KLlbRjyyOiP5BOC2aZejEKg1eEnWgboZuoANB
# cNmRNwOMgCK14TpPGuEGkhvt7q6mJ9MZk19wKE9+7MerrUVIjAnRcLFxpHUHACVI
# qFv81Q65AY+v1nN3o6chwD5Fy3HAqB84oH1pYQQeW3SOEoqCkQG9wmcww/5ZpPCY
# yGhvV76GgIQXH+cjRge6mLrTzaQV00WtoTvaaw5hCvCtTJYJ5KY3bTYtkOlPPFlW
# 3LpCsE6T5/4ESuxH4zl6+Qq5RNZUkcje+02Bvorn6CToS5DDShywN2ymI+n6qXEF
# pbnTJRuvrCd/NiMmHtCQ9x8EhlskCFZAdpXS5LdPs6Q5t0KywJExYftVZQB5Jt6a
# 5So5cJHut2kVN9j9Jco72UIhAEBBKH7DPCHlm/Vv6NPbNbBWXzYHLdgeZJPxvwIq
# dFdIKMu2CjLLsREvCRvM8iQJ8FdzJWd4LXDb/BSeo+ICMrTBB/O19cV+gxCvxhRw
# secC16Tw5U0+5EhXptwRFsXqu0VeaeOMPhnBXEhn8czhyN5UawTCQUD1dPOpf1bU
# /wIDAQABo4IBNjCCATIwHQYDVR0OBBYEFF+vYwnrHvIT6A/m5f3FYZPClEL6MB8G
# A1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCG
# Tmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUy
# MFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4w
# XAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2Vy
# dHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwG
# A1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZIhvcNAQELBQAD
# ggIBAF+6JoGCx5we8z3RFmJMOV8duUvT2v1f7mr1yS4xHQGzVKvkHYwAuFPljRHe
# CAu59FfpFBBtJztbFFcgyvm0USAHnPL/tiDzUKfZ2FN/UbOMJvv+ffC0lIa2vZDA
# exrV6FhZ0x+L4RMugRfUbv1U8WuzS3oaLCmvvi2/4IsTezqbXRU7B7zTA/jK5Pd6
# IV+pFXymhQVJ0vbByWBAqhLBsKlsmU0L8RJoNBttAWWL247mPZ/8btLhMwb+DLLG
# 8xDlAm6L0XDazuqSWajNChfYCHhoq5sp739Vm96IRM1iXUBk+PSSPWDnVU3JaO8f
# D4fPXFl6RYil8xdASLTCsZ1Z6JbiLyX3atjdlt0ewSsVirOHoVEU55eBrM2x+Qub
# DL5MrXuYDsJMRTNoBYyrn5/0rhj/eaEHivpSuKy2Ral2Q9YSjxv21uR0pJjTQT4V
# LkNS2OAB0JpEE1oG7xwVgJsSuH2uhYPFz4iy/zIxABQO4TBdLLQTGcgCVxUiuHMv
# jQ6wbZxrlHkGAB68Y/UeP16PiX/L5KHQdVw303ouY8OYj8xpTasRntj6NF8JnV36
# XkMRJ0tcjENPKxheRP7dUz/XOHrLazRmxv/e89oaenbN6PB/ZiUZaXVekKE1lN6U
# Xl44IJ9LNRSfeod7sjLIMqFqGBucqmbBwSQxUGz5EdtWQ1aoMIIHcTCCBVmgAwIB
# AgITMwAAABXF52ueAptJmQAAAAAAFTANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0
# IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMTAwHhcNMjEwOTMwMTgyMjI1
# WhcNMzAwOTMwMTgzMjI1WjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAOThpkzntHIhC3miy9ckeb0O
# 1YLT/e6cBwfSqWxOdcjKNVf2AX9sSuDivbk+F2Az/1xPx2b3lVNxWuJ+Slr+uDZn
# hUYjDLWNE893MsAQGOhgfWpSg0S3po5GawcU88V29YZQ3MFEyHFcUTE3oAo4bo3t
# 1w/YJlN8OWECesSq/XJprx2rrPY2vjUmZNqYO7oaezOtgFt+jBAcnVL+tuhiJdxq
# D89d9P6OU8/W7IVWTe/dvI2k45GPsjksUZzpcGkNyjYtcI4xyDUoveO0hyTD4MmP
# frVUj9z6BVWYbWg7mka97aSueik3rMvrg0XnRm7KMtXAhjBcTyziYrLNueKNiOSW
# rAFKu75xqRdbZ2De+JKRHh09/SDPc31BmkZ1zcRfNN0Sidb9pSB9fvzZnkXftnIv
# 231fgLrbqn427DZM9ituqBJR6L8FA6PRc6ZNN3SUHDSCD/AQ8rdHGO2n6Jl8P0zb
# r17C89XYcz1DTsEzOUyOArxCaC4Q6oRRRuLRvWoYWmEBc8pnol7XKHYC4jMYcten
# IPDC+hIK12NvDMk2ZItboKaDIV1fMHSRlJTYuVD5C4lh8zYGNRiER9vcG9H9stQc
# xWv2XFJRXRLbJbqvUAV6bMURHXLvjflSxIUXk8A8FdsaN8cIFRg/eKtFtvUeh17a
# j54WcmnGrnu3tz5q4i6tAgMBAAGjggHdMIIB2TASBgkrBgEEAYI3FQEEBQIDAQAB
# MCMGCSsGAQQBgjcVAgQWBBQqp1L+ZMSavoKRPEY1Kc8Q/y8E7jAdBgNVHQ4EFgQU
# n6cVXQBeYl2D9OXSZacbUzUZ6XIwXAYDVR0gBFUwUzBRBgwrBgEEAYI3TIN9AQEw
# QTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9E
# b2NzL1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQMMAoGCCsGAQUFBwMIMBkGCSsGAQQB
# gjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/
# MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fOmhjEMFYGA1UdHwRPME0wS6BJ
# oEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01p
# Y1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYB
# BQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljUm9v
# Q2VyQXV0XzIwMTAtMDYtMjMuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQCdVX38Kq3h
# LB9nATEkW+Geckv8qW/qXBS2Pk5HZHixBpOXPTEztTnXwnE2P9pkbHzQdTltuw8x
# 5MKP+2zRoZQYIu7pZmc6U03dmLq2HnjYNi6cqYJWAAOwBb6J6Gngugnue99qb74p
# y27YP0h1AdkY3m2CDPVtI1TkeFN1JFe53Z/zjj3G82jfZfakVqr3lbYoVSfQJL1A
# oL8ZthISEV09J+BAljis9/kpicO8F7BUhUKz/AyeixmJ5/ALaoHCgRlCGVJ1ijbC
# HcNhcy4sa3tuPywJeBTpkbKpW99Jo3QMvOyRgNI95ko+ZjtPu4b6MhrZlvSP9pEB
# 9s7GdP32THJvEKt1MMU0sHrYUP4KWN1APMdUbZ1jdEgssU5HLcEUBHG/ZPkkvnNt
# yo4JvbMBV0lUZNlz138eW0QBjloZkWsNn6Qo3GcZKCS6OEuabvshVGtqRRFHqfG3
# rsjoiV5PndLQTHa1V1QJsWkBRH58oWFsc/4Ku+xBZj1p/cvBQUl+fpO+y/g75LcV
# v7TOPqUxUYS8vwLBgqJ7Fx0ViY1w/ue10CgaiQuPNtq6TPmb/wrpNPgkNWcr4A24
# 5oyZ1uEi6vAnQj0llOZ0dFtq0Z4+7X6gMTN9vMvpe784cETRkPHIqzqKOghif9lw
# Y1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGCAsswggI0AgEBMIH4oYHQpIHNMIHK
# MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
# bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxN
# aWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMSYwJAYDVQQLEx1UaGFsZXMgVFNT
# IEVTTjoyMjY0LUUzM0UtNzgwQzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3Rh
# bXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUARIo61IrtFVUr5KL5qoV3RhJj5U+g
# gYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYw
# JAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0B
# AQUFAAIFAOcwzYAwIhgPMjAyMjExMzAwMjI3MTJaGA8yMDIyMTIwMTAyMjcxMlow
# dDA6BgorBgEEAYRZCgQBMSwwKjAKAgUA5zDNgAIBADAHAgEAAgITlzAHAgEAAgIT
# tDAKAgUA5zIfAAIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAow
# CAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUAA4GBAEYmRSYO/YSU
# IhZO44dzoaQO3t7QqR+4mOZEX6YvPVj2sBvKCRIOJFbASOBVaQqtsyBVeR/qndI6
# ACA+DuYq/jSJiK8/3ZcotMt0uRf5dFC4vOnG5MQTH4YwnOTw+7GgIPgYC17fb4eY
# vU7qd3V21z/j+v5PSBHgC9kLs6S8Iio4MYIEDTCCBAkCAQEwgZMwfDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAHBPqCDnOAJr8UAAQAAAcEwDQYJYIZI
# AWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG
# 9w0BCQQxIgQgc/qkbkmu+vdo4ZI00Tv0vrYoTbc/PgUS5Fqvi0bEF+AwgfoGCyqG
# SIb3DQEJEAIvMYHqMIHnMIHkMIG9BCAKuSDq2Bgd5KAiw3eilHbPsQTFYDRiSKuS
# 9VhJMGB21DCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMz
# AAABwT6gg5zgCa/FAAEAAAHBMCIEIJp/KY4Gkv/lVKK8eJn1k6RO7iFpSCEe3th9
# luJqmsHnMA0GCSqGSIb3DQEBCwUABIICAIvzjVIzxfurx0xIVEGRrPIg/rvlFSf6
# cCNpN9v6KkQJSUCsUZtPirRovZdc+LdlYGW+8i/DycTJE7N/iaybBNCmbkP9g1D0
# t4vd2UQ4F64rkOagHchDd+RT3xvEeHDOcBBiH2ybMVPIRf+ny4vo+chE5ZnHVxiQ
# YcVjtN/V9Mh0HwMvIKTDkdfuHFhXC+mVbj1qqs+GCGDqOkpH4mvq70yFeMUpNJ0L
# hQlP2WGaNP8J6WrEKcOi2C4gEcS3DoutDie3SEM4Yul/Km+IlNvoxQ4Vu4VqpLJ9
# 6zqGXO2LFl7mkCYVofIeOIG/5q8rSNZaJXvzOCic2vwzskksJX452UyrNEPqLYud
# SXbvaRqq4DN6WjysQiopuUP3XwpUFpC8dgb0T6rtrshXIfUmniR18qfrCUyzXIVz
# myPhvfSM2JxvKB7kDWdD4weOxfWCiah1uvIVl5RMzzlVHW78EvZPXQPPKpRicJod
# r6BMdOEnCkAW7Pi0gQ8aqe+Fbe4TjNEQmBiAFzxCowZnoAvAOxtiTSCINObzpW5U
# vPlcxLrqnp+Y0AeJihUUb5Xbf2eJLc/0D0oNu0m7NlK7BBKmMkt2gugDQD5xq7ou
# Ey3W6/1Cnu8Fjo98f3IvKmym4cg/x8t0BukY/9YnbXbvJcct0dzgL+PepDVW8sD2
# RRv2zlfpUTJv
# SIG # End signature block
