# Original Author: Udish Mudiar
# Original Blog Post: https://udishtech.com/associate-scom-data-warehouse-profile-using-powershell/
# =========================================================================================================================
# Modified by: Blake Drumm (blakedrumm@microsoft.com)
# Last Modified: March 8th, 2024
# Blog Post: https://blakedrumm.com/blog/data-reader-account-provided-is-not-same-as-that-in-the-management-group/

function Invoke-TimeStamp
{
	$TimeStamp = (Get-Date).DateTime
	return "$TimeStamp - "
}
Write-Host "`n`n------------------------------------------------------------" -ForegroundColor Green
#Associate Run As Account association in Data Warehouse and Report Deployment Run As Profile.
Write-Output "$(Invoke-TimeStamp)Script started"

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
Write-Output "$(Invoke-TimeStamp)Setting the Run As Account Association for Data Warehouse Account Profile"
$error.Clear()
try
{
	if ($APMClass)
	{
		Set-SCOMRunAsProfile -ErrorAction Stop -Action "Add" -Profile $DWActionAccountProfile -Account $DWActionAccount -Class $CollectionServerClass, $DataSetClass, $APMClass, $DWSyncClass
	}
	else
	{
		Set-SCOMRunAsProfile -ErrorAction Stop -Action "Add" -Profile $DWActionAccountProfile -Account $DWActionAccount -Class $CollectionServerClass, $DataSetClass, $DWSyncClass
	}
	Write-Output "$(Invoke-TimeStamp)Completed Successfully!"
}
catch
{
	Write-Output "$(Invoke-TimeStamp)Unable to set the RunAs accounts, try removing all accounts from inside the RunAs Profile (`"Data Warehouse Account`"), and run the script again."
	Write-Warning "$(Invoke-TimeStamp)$error"
}
Write-Output "$(Invoke-TimeStamp)Setting the Run As Account Association for Data Warehouse Report Deployment Account Profile"
$error.Clear()
try
{
	Set-SCOMRunAsProfile -ErrorAction Stop -Action "Add" -Profile $ReportDeploymentProfile -Account $DWReportDeploymentAccount -Class $CollectionServerClass, $DWSyncClass
	Write-Output "$(Invoke-TimeStamp)Completed Successfully!"
}
catch
{
	Write-Output "$(Invoke-TimeStamp)Unable to set the RunAs accounts, try removing all accounts from inside the RunAs Profile (`"Data Warehouse Report Deployment Account`"), and run the script again."
	Write-Warning "$(Invoke-TimeStamp)$error"
}

Write-Output "$(Invoke-TimeStamp)Script ended"
Write-Host '------------------------------------------------------------' -ForegroundColor Green
