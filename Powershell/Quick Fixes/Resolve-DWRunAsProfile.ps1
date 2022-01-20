#Associate Run As Account association in Data Warehouse and Report Deployment Run As Profile.
# Original Author: Udish Mudiar
# Original Location: https://github.com/Udish17/SCOM-PowerShell-Scripts/blob/SCOM-PowerShell-Scripts/master/DWRunAsProfile.ps1

Write-Host "Script started.." -ForegroundColor Green

Import-Module OperationsManager

#Get the run as profiles
$DWActionAccountProfile = Get-SCOMRunAsProfile -DisplayName "Data Warehouse Account"
$ReportDeploymentProfile = Get-SCOMRunAsProfile -DisplayName "Data Warehouse Report Deployment Account"

#Get the run as accounts
$DWActionAccount = Get-SCOMrunAsAccount -Name "Data Warehouse Action Account"
$DWReportDeploymentAccount = Get-SCOMrunAsAccount -Name "Data Warehouse Report Deployment Account"

#Get all the required classes
$CollectionServerClass = Get-SCOMClass -DisplayName "Collection Server"
$DataSetClass = Get-SCOMClass -DisplayName "Data Set"
$APMClass = Get-SCOMClass -DisplayName "Operations Manager APM Data Transfer Service"
$DWSyncClass = Get-SCOMClass -DisplayName "Data Warehouse Synchronization Server"

#Setting the association
Write-Host "Setting the Run As Account Association for Data Warehouse Account Profile" -ForegroundColor Cyan
Set-SCOMRunAsProfile -Action "Add" -Profile $DWActionAccountProfile -Account $DWActionAccount -Class $CollectionServerClass,$DataSetClass,$APMClass,$DWSyncClass
Write-Host "Setting the Run As Account Association for Data Warehouse Report Deployment Account Profile" -ForegroundColor Cyan
Set-SCOMRunAsProfile -Action "Add" -Profile $ReportDeploymentProfile -Account $DWReportDeploymentAccount -Class $CollectionServerClass,$DWSyncClass


Write-Host "Script end.." -ForegroundColor Green
