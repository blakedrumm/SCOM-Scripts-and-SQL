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
