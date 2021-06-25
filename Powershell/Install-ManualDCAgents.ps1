cls
<#
$Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
$AllComputers = ($Forest.Sites | % { $_.Servers } | SORT Domain,name).Name 
#>
Write-Host 'Updating Agents!'
$AllComputers = 'DomainController1.contoso.com'
ForEach ($Computer in $AllComputers)
{
    Write-Host "*** $Computer ***"
    ##$Computer
    Copy-Item "C:\Temp\MOMAgent.msi" "\\$Computer\C`$\temp\" -Force -ErrorAction Stop
    Copy-Item "C:\Temp\KB4580254-amd64-Agent.msp" "\\$Computer\C`$\temp\" -Force -ErrorAction Stop
    Invoke-Command -ComputerName $Computer -ScriptBlock {
    $path_to_install = 'C:\Temp\MOMAgent.msi'
    Write-Host "Uninstalling Agent"
    start-process -FilePath "msiexec.exe" -ArgumentList "/x $path_to_install /qn /l*v C:\Temp\AgentUninstall.log"
    $args = "USE_SETTINGS_FROM_AD=0 USE_MANUALLY_SPECIFIED_SETTINGS=1 MANAGEMENT_GROUP=ManagementGroup1 MANAGEMENT_SERVER_DNS=MS1.contoso.com MANAGEMENT_SERVER_AD_NAME=MS1.contoso.com SECURE_PORT=5723 ACTIONS_USE_COMPUTER_ACCOUNT=1 AcceptEndUserLicenseAgreement=1"
    $args = "/i " + $path_to_install + " /quiet /qn /l*v C:\Temp\SCOMAgentInstall.log " + $args
    # Install Ops Manager Agent
    Write-Host 'Installing MOMAgent.msi'
    start-process -FilePath "msiexec.exe" -ArgumentList $args
    sleep 10
    Write-Host 'Starting HSLockdown'
    start-process -FilePath "C:\Program Files\Microsoft Monitoring Agent\Agent\HSLockdown.exe" -ArgumentList "/A `"NT Authority\System`""
    sleep 10
    Write-Host 'Restarting Microsoft Monitoring Agent.'
    Restart-Service HealthService -Force
    $path_to_install = 'C:\Temp\KB4580254-amd64-Agent.msp'
    $args = "AcceptEndUserLicenseAgreement=1"
    $args = "/i " + $path_to_install + " /quiet /qn /l*v C:\Temp\SCOMUpgradeInstall.log " + $args
    # Install Ops Manager Agent
    Write-Host 'Installing Agent Update Rollup'
    start-process -FilePath "msiexec.exe" -ArgumentList $args
    }
}
