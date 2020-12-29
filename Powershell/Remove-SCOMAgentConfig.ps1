Function Remove-SCOMAgentConfig
{
	[cmdletbinding()]
	param (
		[String[]]$Servers
	)
	# ----------> THIS SCRIPT SHOULD BE USED IF YOU ARE MIGRATING TO AZURE LOG ANALYTICS FROM ON-PREM SCOM <----------
	#If there is not any servers passed, get all Agents from SCOM
	if ($null -eq $Servers)
	{
		do
		{
			
			$answer = Read-Host -Prompt "Would you like to remove the Configuration from every Agent in SCOM? (Y/N)"
			
		}
		until ($answer -eq "y" -or $answer -eq "n")
		if ($answer -eq "y")
		{
			try { $Servers = Get-SCOMAgent | Select-Object -Property DisplayName -ExpandProperty DisplayName }
			catch { Write-Warning "The Command for Get-SCOMAgent could not be found, it is possible you are running this Powershell Script from something other than a Management Server.`nExiting Script."; exit 1 }
		}
		else
		{
			$Servers = Read-Host -Prompt "Please provide the Agents you would like to Remove Configuration for (FQDN, FQDN)"
			$Servers = ($Servers.Split(",") -replace (" ", ""))
			$TextInfo = (Get-Culture).TextInfo
			$Servers = $TextInfo.ToTitleCase($Servers.ToLower())
			do
			{
				
				$answer = Read-Host "Running actions against the following Machines: $Servers`; Would you like to Proceed? (Y/N)"
				
			}
			until ($answer -eq "y" -or $answer -eq "n")
			if ($answer -eq "n")
			{
				$Servers = Read-Host -Prompt "Please provide the Agents you would like to Remove Configuration for (FQDN, FQDN)"
				$Servers = ($Servers.Split(",") -replace (" ", ""))
				$TextInfo = (Get-Culture).TextInfo
				$Servers = $TextInfo.ToTitleCase($Servers.ToLower())
				do
				{
					
					$answer = Read-Host "Running actions against the following Machines: $Servers`; Would you like to Proceed? (Y/N)"
					
				}
				until ($answer -eq "y" -or $answer -eq "n")
				if ($answer -eq "n")
				{
					Write-Warning "Stopping Script, start the script again to use."
					exit 1
				}
			}
		}
		
		
	}
	$servers = $servers | select -Unique
	foreach ($server in $servers)
	{
		Write-Host "`n`nRunning Actions on: $server" -ForegroundColor Green
		#Start Remote Execution
		Invoke-Command -ComputerName $server {
			Write-Host "Stopping Health Service on $using:server";
			net stop healthservice | Out-Null
			$stateDirectory = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\HealthService\Parameters" | Select-Object -Property "State Directory" -ExpandProperty "State Directory"
			Remove-Item "$stateDirectory" -Recurse
			$pathCheck = Test-Path "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Agent Management Groups"
			if ($pathCheck -eq $true)
			{
				$mgmtgroup = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Agent Management Groups" -Name
				Write-Host " Removing SCOM Agent Settings from: $using:server"
				$mgmtgroup | % { Write-Host "  Registry Location:" -NoNewline; Remove-Item "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Agent Management Groups\$_" -Recurse; Write-Host "   `'HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Agent Management Groups\$_`'" -NoNewline }
			}
			$pathCheck2 = Test-Path "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Agent Management Groups"
			if ($pathCheck2 -eq $true)
			{
				Write-Host "`n  Changing EnableADIntegration to 0"
				Write-Host "    Registry Location:" -NoNewline
				Write-Host "     `'HKLM:\SYSTEM\CurrentControlSet\Services\HealthService\Parameters\ConnectorManager`'" -ForegroundColor Green -NoNewline
				Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\HealthService\Parameters\ConnectorManager' -Name 'EnableADIntegration' -Value '0'
			}
			$pathCheck3 = Test-Path "HKLM:\SYSTEM\CurrentControlSet\Services\HealthService\Parameters\Management Groups"
			if ($pathCheck3 -eq $true)
			{
				Write-Host "`n  Identifying Connector CLSID & Removing Registered Connectors"
				$mgmtgroup = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Agent Management Groups" -Name
				$mgmtgroup | % {
					Write-Host "   Management Group: $_" -ForegroundColor Cyan
					Write-Host "    Registry Location:" -NoNewline
					$cslid = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\HealthService\Parameters\Management Groups\$_" | Select-Object -Property "Connector CLSID" -ExpandProperty "Connector CLSID"
					$cslid | % { Remove-Item "HKLM:\SYSTEM\CurrentControlSet\Services\HealthService\Parameters\Registered Connectors\$_" -Recurse; Remove-Item "HKLM:\SYSTEM\CurrentControlSet\Services\HealthService\Parameters\Registered Connectors\$_"; Write-Host "     `'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\HealthService\Parameters\Registered Connectors\$_`'" -NoNewline; }
					Remove-Item "HKLM:\SYSTEM\CurrentControlSet\Services\HealthService\Parameters\Management Groups\$_"
				}
				if ($_ -eq $null) { Write-Host "`tUnable to Locate any Management Groups" }
			}
			else { Write-Warning "   Unable to locate any data for: HKLM:\SYSTEM\CurrentControlSet\Services\HealthService\Parameters\Management Groups" }
			Write-Host "`tStarting Health Service on $using:server";
			net start healthservice | Out-Null
		}
		#End Remote Execution
		Write-Host "`nCompleted!" -ForegroundColor Green
		exit 0
	}
}
Remove-SCOMAgentConfig


# SIG # Begin signature block
# MIIRKwYJKoZIhvcNAQcCoIIRHDCCERgCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDpF9AFsHaZ/bnM
# YqvGWFepi6Cy2z+5Il9K194kbW1/uqCCDB4wggM3MIICI6ADAgECAhBid7E8Kyy6
# okrKDBZQBZ7/MAkGBSsOAwIdBQAwGTEXMBUGA1UEAxMOQW50aG9ueSBEdWd1aWQw
# IBcNMTcwNTI0MDIxNjI2WhgPMjE3NDAxMTUxNDAwMDBaMBkxFzAVBgNVBAMTDkFu
# dGhvbnkgRHVndWlkMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3NXP
# 0qsalOagDYU6g7VAQqeqZYlICq+yClVDSBb+3DNSFIy8M2IogpocMT5wAwOvnBBO
# Yz34mgjqc03B7/uvXFDva1PW/4gRwL5jC+PJxg/FG4ghD+fRlKCDYC/55nNos04D
# P2APbkO1VLo9LjCVQRUfXjtbifOWtMHOzcw/AzY5PuxzLc5YCPXdXBCMw94aL4jX
# ABdkXp2o3kO9opsWkeZpG7VPsnGe0Ov4A0kHo5/33wVtNOWWQKDD8qJA/wZLDmKA
# aQX60/hJKzzV7P7hNKoWmUxBAILe/N/soprlj8m5Li+Avx82XumDyH8LPyUad2YL
# oNcsAZFcNokt3S+QlQIDAQABo4GAMH4wDwYDVR0TAQH/BAUwAwIBADAfBgNVHSUE
# GDAWBggrBgEFBQcDAwYKKwYBBAGCNwoDDTBKBgNVHQEEQzBBgBA0bMynuhE47c/y
# Vt4RcHC7oRswGTEXMBUGA1UEAxMOQW50aG9ueSBEdWd1aWSCEGJ3sTwrLLqiSsoM
# FlAFnv8wCQYFKw4DAh0FAAOCAQEALkbCgE0Z3XNqhtD+COhaMyN+CiifirdRVUwL
# jbwNjlq50x3MPx8Ty6/xs8W8nlM5Gl84S2LKDHYf/ycR/rR4L5BAR7HX1dLzVrbU
# DvoFA1r2vCwUdk0fODBASIb1reort7EyBX8ofE4neW6J6uMrvy8IGmWH4caAJ9jU
# o5pStCgn8aDvXS9Fx3nW+wwU3vUzcQYXXolnh0/EzB049/3KPhPQkWbZoxTRGSRb
# VnhrGIcvqLJN8fm5flG343Om32QDnzmEsQIWkjq8hiQXt4oIyLuoQoEcK52zPJ6R
# A44Icpr6kqYx/zjBrVdWL04cdNIFHles4CiiuOfkfIuxtXp+8DCCBBUwggL9oAMC
# AQICCwQAAAAAATGJxlAEMA0GCSqGSIb3DQEBCwUAMEwxIDAeBgNVBAsTF0dsb2Jh
# bFNpZ24gUm9vdCBDQSAtIFIzMRMwEQYDVQQKEwpHbG9iYWxTaWduMRMwEQYDVQQD
# EwpHbG9iYWxTaWduMB4XDTExMDgwMjEwMDAwMFoXDTI5MDMyOTEwMDAwMFowWzEL
# MAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExMTAvBgNVBAMT
# KEdsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gU0hBMjU2IC0gRzIwggEiMA0G
# CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCqm47DqxFRJQG2lpTiT9jBCPZGI9lF
# xZWXW6sav9JsV8kzBh+gD8Y8flNIer+dh56v7sOMR+FC7OPjoUpsDBfEpsG5zVvx
# HkSJjv4L3iFYE+5NyMVnCxyys/E0dpGiywdtN8WgRyYCFaSQkal5ntfrV50rfCLY
# FNfxBx54IjZrd3mvr/l/jk7htQgx/ertS3FijCPxAzmPRHm2dgNXnq0vCEbc0oy8
# 9I50zshoaVF2EYsPXSRbGVQ9JsxAjYInG1kgfVn2k4CO+Co4/WugQGUfV3bMW44E
# Tyyo24RQE0/G3Iu5+N1pTIjrnHswJvx6WLtZvBRykoFXt3bJ2IAKgG4JAgMBAAGj
# gegwgeUwDgYDVR0PAQH/BAQDAgEGMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0O
# BBYEFJIhp0qVXWSwm7Qe5gA3R+adQStMMEcGA1UdIARAMD4wPAYEVR0gADA0MDIG
# CCsGAQUFBwIBFiZodHRwczovL3d3dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0b3J5
# LzA2BgNVHR8ELzAtMCugKaAnhiVodHRwOi8vY3JsLmdsb2JhbHNpZ24ubmV0L3Jv
# b3QtcjMuY3JsMB8GA1UdIwQYMBaAFI/wS3+oLkUkrk1Q+mOai97i3Ru8MA0GCSqG
# SIb3DQEBCwUAA4IBAQAEVoJKfNDOyb82ZtG+NZ6TbJfoBs4xGFn5bEFfgC7AQiW4
# GMf81LE3xGigzyhqA3RLY5eFd2E71y/j9b0zopJ9ER+eimzvLLD0Yo02c9EWNvG8
# Xuy0gJh4/NJ2eejhIZTgH8Si4apn27Occ+VAIs85ztvmd5Wnu7LL9hmGnZ/I1JgF
# snFvTnWu8T1kajteTkamKl0IkvGj8x10v2INI4xcKjiV0sDVzc+I2h8otbqBaWQq
# taai1XOv3EbbBK6R127FmLrUR8RWdIBHeFiMvu8r/exsv9GU979Q4HvgkP0gGHgY
# Il0ILowcoJfzHZl9o52R0wZETgRuehwg4zbwtlC5MIIExjCCA66gAwIBAgIMJFS4
# fx4UU603+qF4MA0GCSqGSIb3DQEBCwUAMFsxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMTEwLwYDVQQDEyhHbG9iYWxTaWduIFRpbWVzdGFt
# cGluZyBDQSAtIFNIQTI1NiAtIEcyMB4XDTE4MDIxOTAwMDAwMFoXDTI5MDMxODEw
# MDAwMFowOzE5MDcGA1UEAwwwR2xvYmFsU2lnbiBUU0EgZm9yIE1TIEF1dGhlbnRp
# Y29kZSBhZHZhbmNlZCAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
# AQEA2XhhoZauEv+j/yf2RGB7alYtZ+NfnzGSKkjt+QWEDm1OIlbK2JmXjmnKn3sP
# CMgqK2jRKGErn+Qm7rq497DsXmob4li1tL0dCe3N6D3UZv++IiJtNibPEXiX6VUA
# KMPpN069GeUXhEiyHCGt7HPS86in6V/oNc6FE6cim6yC6f7xX8QSWrH3DEDm0qDg
# TWjQ7QwMEB2PBV9kVfm7KEcGDNgGPzfDJjYljHsPJ4hcODGlAfZeZN6DwBRc4OfS
# XsyN6iOAGSqzYi5gx6pn1rNA7lJ/Vgzv2QXXlSBdhRVAz16RlVGeRhoXkb7BwAd1
# skv3NrrFVGxfihv7DShhyInwFQIDAQABo4IBqDCCAaQwDgYDVR0PAQH/BAQDAgeA
# MEwGA1UdIARFMEMwQQYJKwYBBAGgMgEeMDQwMgYIKwYBBQUHAgEWJmh0dHBzOi8v
# d3d3Lmdsb2JhbHNpZ24uY29tL3JlcG9zaXRvcnkvMAkGA1UdEwQCMAAwFgYDVR0l
# AQH/BAwwCgYIKwYBBQUHAwgwRgYDVR0fBD8wPTA7oDmgN4Y1aHR0cDovL2NybC5n
# bG9iYWxzaWduLmNvbS9ncy9nc3RpbWVzdGFtcGluZ3NoYTJnMi5jcmwwgZgGCCsG
# AQUFBwEBBIGLMIGIMEgGCCsGAQUFBzAChjxodHRwOi8vc2VjdXJlLmdsb2JhbHNp
# Z24uY29tL2NhY2VydC9nc3RpbWVzdGFtcGluZ3NoYTJnMi5jcnQwPAYIKwYBBQUH
# MAGGMGh0dHA6Ly9vY3NwMi5nbG9iYWxzaWduLmNvbS9nc3RpbWVzdGFtcGluZ3No
# YTJnMjAdBgNVHQ4EFgQU1Ie4jeblQDydWgZjxkWE2d27HMMwHwYDVR0jBBgwFoAU
# kiGnSpVdZLCbtB7mADdH5p1BK0wwDQYJKoZIhvcNAQELBQADggEBACRyUKUMvEAJ
# psH01YJqTkFfzseIOdPkfPkibDh4uPS692vhJOudfM1IrIvstXZMj9yCaQiW57rh
# Z7bwpr8YCELh680ZWDmlEWEj1hnXAOm70vlfQfsEPv6KIGAM0U8jWhkaGO/Yxt7W
# X1ShepPhtneFwPuxRsQJri9T+5WcjibiSuTE5jw177rG2bnFzc0Hm2O7PQ9hvFV8
# IxC1jIqj0mhFsUC6oN08GxVAuEl4b+WUwG1WSzz2EirUhfNIEwXhuzBFCkG3fJJu
# vk6SYILKW2TmVdPSB96dX5uhAe2b8MNduxnwGAyaoBzpaggLPelml6d1Hg+/KNcJ
# Iw3iFvq68zQxggRjMIIEXwIBATAtMBkxFzAVBgNVBAMTDkFudGhvbnkgRHVndWlk
# AhBid7E8Kyy6okrKDBZQBZ7/MA0GCWCGSAFlAwQCAQUAoEwwGQYJKoZIhvcNAQkD
# MQwGCisGAQQBgjcCAQQwLwYJKoZIhvcNAQkEMSIEIA/T47hKejL8SqFCgT6tuESf
# FnD0h1CEnXHre7B2GeEmMA0GCSqGSIb3DQEBAQUABIIBADFlqGzqiJCDbmWZrkxB
# eBb4vGtFRWKF43X/hTtIuu9ivAUZfpH+l57v9jvxnulzWijkPX4o7CdMshk6UrjG
# HSrq3Y/RSB0WFnRtQTglldWSEnDKvARLZyYdrYSRmt+ChKwT47G7TAxtOlCsb4Fg
# lmlweo/e25CNA53GpOvZAz8y57QzwG/SbH58GMonwbkvutkpakp8nf4/sSKm0W+Q
# r7RUkFjx9AjELT500weraclbPR3KH9ISdXbb4j/teb592tyJfmzCPI9+811E/xTQ
# 0jlen0lI0/UGiWOwF5K5SyXaCUsQ0OUsN+9CZgCrmEjGc5LLaTDZ6ORXrDIABtvr
# DWShggK5MIICtQYJKoZIhvcNAQkGMYICpjCCAqICAQEwazBbMQswCQYDVQQGEwJC
# RTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTExMC8GA1UEAxMoR2xvYmFsU2ln
# biBUaW1lc3RhbXBpbmcgQ0EgLSBTSEEyNTYgLSBHMgIMJFS4fx4UU603+qF4MA0G
# CWCGSAFlAwQCAQUAoIIBDDAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqG
# SIb3DQEJBTEPFw0yMDA4MDYxNTAxNTBaMC8GCSqGSIb3DQEJBDEiBCA9DUc/I3ug
# oqEClQ69KCttDkVx5LzIpf762KFw62l/cjCBoAYLKoZIhvcNAQkQAgwxgZAwgY0w
# gYowgYcEFD7HZtXU1HLiGx8hQ1IcMbeQ2UtoMG8wX6RdMFsxCzAJBgNVBAYTAkJF
# MRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMTEwLwYDVQQDEyhHbG9iYWxTaWdu
# IFRpbWVzdGFtcGluZyBDQSAtIFNIQTI1NiAtIEcyAgwkVLh/HhRTrTf6oXgwDQYJ
# KoZIhvcNAQEBBQAEggEAE2nXRtwKzB8HTKBij34MZH2YbNidjv20Nmi+UI8HAR4e
# DTfEARDrmVfRUWa8TvzxQvmCe8R+/czmGBG/D+20vXXI4HlzEA32IX1lZZmhxjOw
# /l8zjv0u9BD5o56dvJJNGW3EUuZcubGInhn97Arm5Ada7X1B54fCAErjr9v5pS4W
# 0jD5GdAzVP2AgD7brNWB8AlcvLd+MN1/eNqEs/H6m3Z9pEoiaVJDjSCkh81APkbm
# u0P/N4AU6BViyJEZH5Ph1GGanRGMiyCessKlzvLwNVjiCSvL+Z5e8nWlXpYiepl+
# q1M8Wb0xzRUaBMxh4GasJeDGmPIOTp97bANGvk+5Iw==
# SIG # End signature block