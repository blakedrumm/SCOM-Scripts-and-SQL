cls

<#
Get All Domain Controllers in AD:

    $Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
    $AllComputers = ($Forest.Sites | % { $_.Servers } | SORT Domain,name).Name 
#>
$AllComputers = 'DC01.contoso.com'

function Time-Stamp
{
	$TimeStamp = Get-Date -Format "MM/dd/yyy hh:mm:ss tt"
	Write-Host $TimeStamp -NoNewLine -ForegroundColor DarkGray
}
Write-Host @"
====================
Updating SCOM Agents
====================
"@
ForEach ($Computer in $AllComputers)
{
	Time-Stamp
	Write-Host "  $Computer" -ForegroundColor DarkCyan
    #Copy Agent Installer from C:\Temp to C:\Temp on remote computer
	Copy-Item "C:\Temp\MOMAgent.msi" "\\$Computer\C`$\temp\" -Force -ErrorAction Stop
    #Copy Agent Update Rollup from C:\Temp to C:\Temp on remote computer
	Copy-Item "C:\Temp\KB4580254-amd64-Agent.msp" "\\$Computer\C`$\temp\" -Force -ErrorAction Stop
	Invoke-Command -ComputerName $Computer -ScriptBlock {
		Stop-process -Name msiexec -Force
		function Time-Stamp
		{
			$TimeStamp = Get-Date -Format "MM/dd/yyy hh:mm:ss tt"
			Write-Host $TimeStamp -NoNewLine -ForegroundColor DarkGray
		}
		$path_to_install = 'C:\Temp\MOMAgent.msi'
		# Uninstall Agent
		Time-Stamp
		Write-Host "`t - Uninstalling Agent" -ForegroundColor Cyan
		<#
			2012 R2 install
			msiexec.exe /i \\agent1.contoso.com\stagetools\SCOMAgent2012R2x64\MOMAgent.msi /qn USE_SETTINGS_FROM_AD=0 USE_MANUALLY_SPECIFIED_SETTINGS=1 MANAGEMENT_GROUP=Beta2019 MANAGEMENT_SERVER_DNS=MS1.contoso.com MANAGEMENT_SERVER_AD_NAME=MS1.contoso.com SECURE_PORT=5723 ACTIONS_USE_COMPUTER_ACCOUNT=1 AcceptEndUserLicenseAgreement=1

			2012 R2 Patch UR14
			msiexec.exe /p \\agent1.contoso.com\stagetools\SCOMAgent2016x64\KB4024942-AMD64-Agent.msp /qn AcceptEndUserLicenseAgreement=1

			2016 upgrade - Upgraded my agent from 2012 R2 UR14 to 2016 RTM
			msiexec.exe /i \\agent1.contoso.com\stagetools\SCOMAgent2016x64\MOMAgent.msi /qn AcceptEndUserLicenseAgreement=1

			2016 patch UR9 - - Then I patched from 2016 RTM to UR9
			msiexec.exe /p \\agent1.contoso.com\stagetools\SCOMAgent2016x64\KB4546986-AMD64-Agent.msp /qn AcceptEndUserLicenseAgreement=1

			2016 patch UR10 - - Then I patched from 2016 RTM to UR10
			msiexec.exe /p \\agent1.contoso.com\stagetools\SCOMAgent2016x64\KB4580254-AMD64-Agent.msp /qn AcceptEndUserLicenseAgreement=1

			2019 upgrade
			msiexec.exe /i \\agent1.contoso.com\stagetools\SCOMAgent2019x64\MOMAgent.msi /qn AcceptEndUserLicenseAgreement=1

			2019 patch UR1
			msiexec.exe /p \\agent1.contoso.com\stagetools\SCOMAgent2016x64\KB4533415-AMD64-Agent.msp /qn AcceptEndUserLicenseAgreement=1

			2019 patch UR2
			msiexec.exe /p KB4558752-amd64-Agent.msp /qn AcceptEndUserLicenseAgreement=1

			2019 patch UR3
			msiexec.exe /p \\uncpath\share\KB4594078-amd64-Agent.msp /qn AcceptEndUserLicenseAgreement=1
		#>
		start-process -FilePath "msiexec.exe" -ArgumentList "/x $path_to_install /qn /l*v C:\Temp\AgentUninstall.log" -Wait -ErrorAction Stop
		Sleep 1
		$args = "USE_SETTINGS_FROM_AD=0 USE_MANUALLY_SPECIFIED_SETTINGS=1 MANAGEMENT_GROUP=ManagementGroup1 MANAGEMENT_SERVER_DNS=MS1.contoso.com MANAGEMENT_SERVER_AD_NAME=MS1.contoso.com SECURE_PORT=5723 ACTIONS_USE_COMPUTER_ACCOUNT=1 AcceptEndUserLicenseAgreement=1"
		$args = "/i " + $path_to_install + " /quiet /qn /l*v C:\Temp\SCOMAgentInstall.log " + $args
		# Install Ops Manager Agent
		Time-Stamp
		Write-Host "`t - Installing MOMAgent.msi" -ForegroundColor Cyan
		start-process -FilePath "msiexec.exe" -ArgumentList $args -Wait -ErrorAction Stop
		sleep 1
        # Adding 'NT Authority\System' via HSLockdown
		Time-Stamp
		Write-Host "`t - Adding 'NT Authority\System' via HSLockdown" -ForegroundColor Cyan
		start-process -FilePath "C:\Program Files\Microsoft Monitoring Agent\Agent\HSLockdown.exe" -ArgumentList "/A `"NT Authority\System`"" -Wait -ErrorAction Stop
		sleep 1
        # Restarting Microsoft Monitoring Agent
		Time-Stamp
		Write-Host "`t - Restarting Microsoft Monitoring Agent" -ForegroundColor Cyan
		Restart-Service HealthService -Force
		# Install Ops Manager Agent Update Rollup
		$path_to_install = 'C:\Temp\KB4580254-amd64-Agent.msp'
		$msiArgs = "/update `"$path_to_install`" /quiet"
		Time-Stamp
		Write-Host "`t - Installing Agent Update Rollup" -ForegroundColor Cyan
		Start-Process -FilePath msiexec -ArgumentList $msiArgs -Wait -ErrorAction Stop
		Time-Stamp
		Write-Host "`t -- Complete!" -ForegroundColor Green
	}
	
}
