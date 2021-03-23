#Verify that the location "C:\SCOM Backup" exists
#Change Microsoft to either a portion of the name, or use the full Name of the MP you are Looking to get information from
<#
Modified By: Blake Drumm (v-bldrum@microsoft.com)
#>
$mp = "Microsoft"
$Path = Test-Path “C:\SCOM Backup”
If (!$Path){
md $Path
}
Get-SCOMManagementPack | where {$_ -like "*$mp*"} | select -property name -ExpandProperty Name | % { Get-SCOMManagementPack -Name $_ | Get-SCOMRule | Select DisplayName, Description, Name, Enabled, Target | Export-Csv -Path “C:\SCOM Backup\$_.Rules.csv”; Get-SCOMManagementPack -Name $_ | Get-SCOMMonitor | Select DisplayName, Description, Name, Enabled, Target | Export-Csv -Path “C:\SCOM Backup\$_.Monitors.csv” }
