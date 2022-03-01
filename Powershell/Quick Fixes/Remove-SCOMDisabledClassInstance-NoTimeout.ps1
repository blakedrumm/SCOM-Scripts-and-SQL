function Load-SDK()
{
       [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.EnterpriseManagement.OperationsManager.Common") | Out-Null
       [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.EnterpriseManagement.OperationsManager") | Out-Null
 
}
 
$thisComputer = $env:COMPUTERNAME
 
#Load SDK
Load-SDK
 
#Connect to management group
$mg = [Microsoft.EnterpriseManagement.ManagementGroup]::Connect($thisComputer)
 
#Remove Disabled Discovery Objects
$mg.EntityObjects.DeleteDisabledObjects()
