cls

<#
$Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
$AllComputers = ($Forest.Sites | % { $_.Servers } | SORT Domain,name).Name 
#>
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
# The Domain Controller you want to Install an Agent on
$AllComputers = 'DC01.contoso.com'
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
