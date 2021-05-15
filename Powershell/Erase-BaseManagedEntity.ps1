#This script will run the Kevin Holman steps to Purge Agent Data from the OperationsManager DB: https://kevinholman.com/2018/05/03/deleting-and-purging-data-from-the-scom-database/
#----------------------------------------------------------------------------------------------------------------------------------
#-Requires: SQL Server Powershell Module (https://docs.microsoft.com/en-us/sql/powershell/download-sql-server-ps-module)
#Author: Blake Drumm (v-bldrum@microsoft.com)
#Date Created: 4/10/2021
cls

#-----------------------------------------------------------
#region ScriptVariables
#-----------------------------------------------------------
#In the format of: ServerName\SQLInstance
#ex: SQL01\SCOM2019
$SQLServer = "SQL01"
$db1 = "OperationsManager"

#Name of Agent to Erase from SCOM
#Fully Qualified (FQDN)
$MachineToRemove = "Agent1.contoso.com", "Agent2.contoso.com"
#If you want to assume yes on all the questions asked typically.
$yes = $false
#endregion

#-----------------------------------------------------------

<#
DO NOT EDIT PAST THIS POINT
#>

if(!(Get-Command Invoke-Sqlcmd -ErrorAction SilentlyContinue))
{
Write-Warning "Unable to run this script due to missing dependency:`n`t`tSQL Server Powershell Module (https://docs.microsoft.com/en-us/sql/powershell/download-sql-server-ps-module)`n`nTry running this script on a SQL Server if you cannot download the Powershell Module."
break
}
foreach($machine in $MachineToRemove)
{
$bme_query = @"
--Query 1
--First get the Base Managed Entity ID of the object you think is orphaned/bad/needstogo:
--
DECLARE @name varchar(255) = '%$machine%'
--
SELECT BaseManagedEntityId, FullName, DisplayName, IsDeleted, Path, Name
FROM BaseManagedEntity WHERE FullName like @name OR DisplayName like @name
ORDER BY FullName
"@

$BME_IDs = (Invoke-Sqlcmd -ServerInstance $SQLServer -Database $db1 -Query $bme_query -OutputSqlErrors $true)

if(!$BME_IDs)
{
Write-Warning "Unable to find any data in the OperationsManager DB associated with: $machine"
break
}

Write-Host "Found the following data associated with: " -NoNewline
Write-Host $machine -ForegroundColor Green
$BME_IDs | Select FullName, DisplayName, Path, IsDeleted, BaseManagedEntityId
$count = $BME_IDs.Count
if(!$yes)
{
do
{
$answer1 = Read-Host -Prompt "Do you want to delete the above $count item(s) from the OperationsManager DB? (Y/N)"
}
until ($answer1 -eq "y" -or $answer1 -eq "n")
}
else
{$answer1 = 'y'}
if($answer1 -eq "n")
{ Write-Host "Exiting Script.."; break }
foreach($BaseManagedEntityID in $BME_IDs)
{
Write-Host " Gracefully deleting the following from OperationsManager Database:`n`tName: " -NoNewline
$BaseManagedEntityID.FullName | Write-Host -ForegroundColor Green
Write-Host " `tBME ID: " -NoNewline
$BaseManagedEntityID.BaseManagedEntityId | Write-Host -ForegroundColor Gray

Write-Host ''

$current_bme = $BaseManagedEntityID.BaseManagedEntityId.Guid

$delete_query = @"
--Query 2
--Next input that BaseManagedEntityID into the delete statement
--This will delete specific typedmanagedentities more gracefully than setting IsDeleted=1
--change "00000000-0000-0000-0000-000000000000" to the ID of the invalid entity
--
DECLARE @EntityId uniqueidentifier = '$current_bme'
--
DECLARE @TimeGenerated datetime;
SET @TimeGenerated = getutcdate();
BEGIN TRANSACTION
EXEC dbo.p_TypedManagedEntityDelete @EntityId, @TimeGenerated;
COMMIT TRANSACTION
"@
Invoke-Sqlcmd -ServerInstance $SQLServer -Database $db1 -Query $delete_query -OutputSqlErrors $true
}

$remove_count_query = @"
--Query 4
--Get an idea of how many BMEs are in scope to purge
SELECT count(*) FROM BaseManagedEntity WHERE IsDeleted = 1
"@

$remove_count = (Invoke-Sqlcmd -ServerInstance $SQLServer -Database $db1 -Query $remove_count_query -OutputSqlErrors $true).Column1

"OperationsManager DB has " | Write-Host -NoNewline
$remove_count | Write-Host -NoNewline -ForegroundColor Green
" object(s) pending to Delete`n" | Write-Host
if(!$yes)
{
do
{
$answer2 = Read-Host -Prompt "Do you want to purge the deleted item(s) from the OperationsManager DB? (Y/N)"
}
until ($answer2 -eq "y" -or $answer2 -eq "n")
}

$remove_pending_management = @"
exec p_AgentPendingActionDeleteByAgentName "$machine"
"@

Invoke-Sqlcmd -ServerInstance $SQLServer -Database $db1 -Query $remove_pending_management -OutputSqlErrors $true

Write-Host "Cleared $machine from Pending Management List in SCOM Console." -ForegroundColor DarkGreen

$purge_deleted_query = @"
--Query 5
--This query statement for SCOM 2012 will purge all IsDeleted=1 objects immediately
--Normally this is a 2-3day wait before this would happen naturally
--This only purges 10000 records. If you have more it will require multiple runs
--Purge IsDeleted=1 data from the SCOM 2012 DB:
DECLARE @TimeGenerated DATETIME, @BatchSize INT, @RowCount INT
SET @TimeGenerated = GETUTCDATE()
SET @BatchSize = 10000
EXEC p_DiscoveryDataPurgingByRelationship @TimeGenerated, @BatchSize, @RowCount
EXEC p_DiscoveryDataPurgingByTypedManagedEntity @TimeGenerated, @BatchSize, @RowCount
EXEC p_DiscoveryDataPurgingByBaseManagedEntity @TimeGenerated, @BatchSize, @RowCount
"@

try{
Invoke-Sqlcmd -ServerInstance $SQLServer -Database $db1 -Query $purge_deleted_query -OutputSqlErrors $true
Write-Host "Successfully Purged the OperationsManager DB of Deleted Data!" -ForegroundColor Green
}
catch
{
Write-Error "Unable to Purge the Deleted Items from the OperationsManager DB`n`nCould not run the following command against the OperationsManager DB:`n$purge_deleted_query"
}
}
