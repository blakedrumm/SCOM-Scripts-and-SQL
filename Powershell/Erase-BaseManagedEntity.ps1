<#
	.SYNOPSIS
		Erase-BaseManagedEntity
	
	.DESCRIPTION
		This script removes any BME ID's related  to the Display Name provided with the -Servers switch.
	
	.PARAMETER SqlServer
		SQL Server/Instance that hosts OperationsManager Database for SCOM.

	.PARAMETER Database
		The name of the OperationsManager Database for SCOM.

	.PARAMETER Servers
		Each Server (comma seperated) you want to Remove related BME ID's related to the Display Name in the OperationsManager Database.
	
	.PARAMETER AssumeYes
		Optionally assume yes to any question asked by this script.
	
	.EXAMPLE		
		Remove SCOM BME Related Data from the OperationsManager DB, on every Agent in the in Management Group.
		PS C:\> Get-SCOMAgent | %{.\Erase-BaseManagedEntity.ps1 -Servers $_}
		
		Clear SCOM cache and reboot the Servers specified.
		PS C:\> .\Erase-BaseManagedEntity.ps1 -Servers IIS-Server.contoso.com, WindowsServer.contoso.com
	
	.NOTES
		.AUTHOR
		Blake Drumm (v-bldrum@microsoft.com)
		
		.MODIFIED
		May 31st, 2021
#>
[OutputType([string])]
param
(
	[Parameter(Mandatory = $false,
			   Position = 1,
			   HelpMessage = "SQL Server/Instance that hosts OperationsManager Database for SCOM.")]
	[String]$SqlServer,
	[Parameter(Mandatory = $false,
			   Position = 2,
			   HelpMessage = "The name of the OperationsManager Database for SCOM.")]
	[String]$Database,
	[Parameter(Mandatory = $false,
			   ValueFromPipeline = $true,
			   Position = 3,
			   HelpMessage = "Each Server (comma seperated) you want to Remove related BME ID's related to the Display Name in the OperationsManager Database.")]
	[Array]$Servers,
	[Parameter(Mandatory = $false,
			   Position = 4,
			   HelpMessage = 'Optionally reboot the server after stopping the SCOM Services and clearing SCOM Cache. This will always perform on the local server last.')]
	[Alias('yes')]
	[Switch]$AssumeYes
)
#This script will run the Kevin Holman steps to Purge Agent Data from the OperationsManager DB: https://kevinholman.com/2018/05/03/deleting-and-purging-data-from-the-scom-database/
#----------------------------------------------------------------------------------------------------------------------------------
#-Requires: SQL Server Powershell Module (https://docs.microsoft.com/en-us/sql/powershell/download-sql-server-ps-module)
#Author: Blake Drumm (v-bldrum@microsoft.com)
#Date Created: 4/10/2021
cls

Function Erase-BaseManagedEntity
{
	[OutputType([string])]
	param
	(
		[Parameter(Mandatory = $false,
				   Position = 1,
				   HelpMessage = "SQL Server/Instance that hosts OperationsManager Database for SCOM.")]
		[String]$SqlServer,
		[Parameter(Mandatory = $false,
				   Position = 2,
				   HelpMessage = "The name of the OperationsManager Database for SCOM.")]
		[String]$Database,
		[Parameter(Mandatory = $false,
				   ValueFromPipeline = $true,
				   Position = 3,
				   HelpMessage = "Each Server (comma seperated) you want to Remove related BME ID's related to the Display Name in the OperationsManager Database.")]
		[Array]$Servers,
		[Parameter(Mandatory = $false,
				   Position = 4,
				   HelpMessage = 'Optionally reboot the server after stopping the SCOM Services and clearing SCOM Cache. This will always perform on the local server last.')]
		[Alias('yes')]
		[Switch]$AssumeYes
	)
	#-----------------------------------------------------------
	#region ScriptVariables
	#-----------------------------------------------------------
	#In the format of: ServerName\SQLInstance
	#ex: SQL01\SCOM2019
	if (!$SqlServer)
	{
		$SqlServer = "SQL-2019\SCOM2019"
	}
	
	if (!$Database)
	{
		$Database = "OperationsManager"
	}
	
	if (!$Servers)
	{
		#Name of Agent to Erase from SCOM
		#Fully Qualified (FQDN)
		[array]$Servers = "Agent1.contoso.com", "Agent2.contoso.com"
	}
	if (!$AssumeYes)
	{
		#If you want to assume yes on all the questions asked typically.
		$yes = $false
	}
	else
	{
		$yes = $true
	}
	#endregion
	#-----------------------------------------------------------
	
<#
DO NOT EDIT PAST THIS POINT
#>
	
	if (!(Get-Command Invoke-Sqlcmd -ErrorAction SilentlyContinue))
	{
		Write-Warning "Unable to run this script due to missing dependency:`n`t`tSQL Server Powershell Module (https://docs.microsoft.com/en-us/sql/powershell/download-sql-server-ps-module)`n`nTry running this script on a SQL Server if you cannot download the Powershell Module."
		break
	}
	foreach ($machine in $Servers)
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
		
		$BME_IDs = (Invoke-Sqlcmd -ServerInstance $SqlServer -Database $Database -Query $bme_query -OutputSqlErrors $true)
		
		if (!$BME_IDs)
		{
			Write-Warning "Unable to find any data in the OperationsManager DB associated with: $machine"
			continue
		}
		
		Write-Host "Found the following data associated with: " -NoNewline
		Write-Host $machine -ForegroundColor Green
		$BME_IDs | Select FullName, DisplayName, Path, IsDeleted, BaseManagedEntityId
		$count = $BME_IDs.Count
		if (!$yes)
		{
			do
			{
				$answer1 = Read-Host -Prompt "Do you want to delete the above $count item(s) from the OperationsManager DB? (Y/N)"
			}
			until ($answer1 -eq "y" -or $answer1 -eq "n")
		}
		else
		{ $answer1 = 'y' }
		if ($answer1 -eq "n")
		{ continue }
		foreach ($BaseManagedEntityID in $BME_IDs)
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
			Invoke-Sqlcmd -ServerInstance $SqlServer -Database $Database -Query $delete_query -OutputSqlErrors $true
		}
		
		$remove_pending_management = @"
exec p_AgentPendingActionDeleteByAgentName "$machine"
"@
		
		Invoke-Sqlcmd -ServerInstance $SqlServer -Database $Database -Query $remove_pending_management -OutputSqlErrors $true
		
		Write-Host "Cleared $machine from Pending Management List in SCOM Console." -ForegroundColor DarkGreen
		
	}
	$remove_count_query = @"
--Query 4
--Get an idea of how many BMEs are in scope to purge
SELECT count(*) FROM BaseManagedEntity WHERE IsDeleted = 1
"@
	
	$remove_count = (Invoke-Sqlcmd -ServerInstance $SqlServer -Database $Database -Query $remove_count_query -OutputSqlErrors $true).Column1
	
	"OperationsManager DB has " | Write-Host -NoNewline
	$remove_count | Write-Host -NoNewline -ForegroundColor Green
	" object(s) pending to Delete`n" | Write-Host
	if ($remove_count -eq '0')
	{
		$yes = $true
		$answer2 = 'n'
	}
	if (!$yes)
	{
		do
		{
			$answer2 = Read-Host -Prompt "Do you want to purge the deleted item(s) from the OperationsManager DB? (Y/N)"
		}
		until ($answer2 -eq "y" -or $answer2 -eq "n")
	}
	if ($answer2 -eq "n")
	{ Write-Host "No action was taken to purge from OperationsManager DB. (Purging will happen on its own eventually)`nScript has Completed." -ForegroundColor Cyan; break }
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
	
	try
	{
		Invoke-Sqlcmd -ServerInstance $SqlServer -Database $Database -Query $purge_deleted_query -OutputSqlErrors $true
		Write-Host "Successfully Purged the OperationsManager DB of Deleted Data!" -ForegroundColor Green
	}
	catch
	{
		Write-Error "Unable to Purge the Deleted Items from the OperationsManager DB`n`nCould not run the following command against the OperationsManager DB:`n$purge_deleted_query"
	}
	break
}

if ($SqlServer -or $Database -or $Servers -or $AssumeYes)
{
	Erase-BaseManagedEntity -SqlServer $SqlServer -Database $Database -Servers $Servers -AssumeYes:$AssumeYes
}
else
{
<# Edit line 265 to modify the default command run when this script is executed.
   Example: 
   Erase-BaseManagedEntity -SqlServer SQL-2019\SCOM2019 -Database OperationsManager -Servers Agent1.contoso.com, Agent2.contoso.com
   #>
	Erase-BaseManagedEntity
}
