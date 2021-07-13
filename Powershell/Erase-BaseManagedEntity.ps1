<#
	.SYNOPSIS
		Erase-BaseManagedEntity
	
	.DESCRIPTION
		This script removes any BME ID's related to the Display Name provided with the -Agents switch.
	
	.PARAMETER ManagementServer
		A description of the ManagementServer parameter.
	
	.PARAMETER SqlServer
		SQL Server/Instance,Port that hosts OperationsManager Database for SCOM.
	
	.PARAMETER Database
		The name of the OperationsManager Database for SCOM.
	
	.PARAMETER Agents
		Each Server (comma seperated) you want to Remove related BME ID's related to the Display Name in the OperationsManager Database.
	
	.PARAMETER AssumeYes
		Optionally assume yes to any question asked by this script.
	
	.EXAMPLE
		Remove SCOM BME Related Data from the OperationsManager DB, on every Agent in the in Management Group.
		PS C:\> Get-SCOMAgent | %{.\Erase-BaseManagedEntity.ps1 -Agents $_}
		
		PS C:\> .\Erase-BaseManagedEntity.ps1 -Agents IIS-Server.contoso.com, WindowsServer.contoso.com
	
	.NOTES
		.AUTHOR
		Blake Drumm (v-bldrum@microsoft.com)
		
		.MODIFIED
		July 12th, 2021
#>
[OutputType([string])]
param
(
	[Parameter(Mandatory = $false,
			   Position = 1,
			   HelpMessage = "SCOM Management Server that we will remotely or locally connect to.")]
	[String]$ManagementServer,
	[Parameter(Mandatory = $false,
			   Position = 2,
			   HelpMessage = "SQL Server/Instance,Port that hosts OperationsManager Database for SCOM.")]
	[String]$SqlServer,
	[Parameter(Mandatory = $false,
			   Position = 3,
			   HelpMessage = "The name of the OperationsManager Database for SCOM.")]
	[String]$Database,
	[Parameter(Mandatory = $false,
			   ValueFromPipeline = $true,
			   Position = 4,
			   HelpMessage = "Each Server (comma seperated) you want to Remove related BME ID's related to the Display Name in the OperationsManager Database.")]
	[Array]$Agents,
	[Parameter(Mandatory = $false,
			   Position = 5,
			   HelpMessage = "Optionally assume yes to any question asked by this script.")]
	[Alias('yes')]
	[Switch]$AssumeYes,
	[Parameter(Mandatory = $false,
			   Position = 5,
			   HelpMessage = "Optionally force the script to not stop when an error occurs.")]
	[Alias('ds')]
	[Switch]$DontStop
)
#This script will run the Kevin Holman steps to Purge Agent Data from the OperationsManager DB: https://kevinholman.com/2018/05/03/deleting-and-purging-data-from-the-scom-database/
#----------------------------------------------------------------------------------------------------------------------------------
#-Requires: SQL Server Powershell Module (https://docs.microsoft.com/en-us/sql/powershell/download-sql-server-ps-module)
#Author: Blake Drumm (v-bldrum@microsoft.com)
#Date Created: 4/10/2021
cls
function Invoke-SqlCommand
{
    <#
        .SYNOPSIS
            Executes an SQL statement. Executes using Windows Authentication unless the Username and Password are provided.

        .PARAMETER Server
            The SQL Server instance name.

        .PARAMETER Database
            The SQL Server database name where the query will be executed.

        .PARAMETER Timeout
            The connection timeout.

        .PARAMETER Connection
            The System.Data.SqlClient.SQLConnection instance used to connect.

        .PARAMETER Username
            The SQL Authentication Username.

        .PARAMETER Password
            The SQL Authentication Password.

        .PARAMETER CommandType
            The System.Data.CommandType value specifying Text or StoredProcedure.

        .PARAMETER Query
            The SQL query to execute.

         .PARAMETER Path
            The path to an SQL script.

        .PARAMETER Parameters
            Hashtable containing the key value pairs used to generate as collection of System.Data.SqlParameter.

        .PARAMETER As
            Specifies how to return the result.

            PSCustomObject
             - Returns the result set as an array of System.Management.Automation.PSCustomObject objects.
            DataSet
             - Returns the result set as an System.Data.DataSet object.
            DataTable
             - Returns the result set as an System.Data.DataTable object.
            DataRow
             - Returns the result set as an array of System.Data.DataRow objects.
            Scalar
             - Returns the first column of the first row in the result set. Should be used when a value with no column name is returned (i.e. SELECT COUNT(*) FROM Test.Sample).
            NonQuery
             - Returns the number of rows affected. Should be used for INSERT, UPDATE, and DELETE.

        .EXAMPLE
            PS C:\> Invoke-SqlCommand -Server "DATASERVER" -Database "Web" -Query "SELECT TOP 1 * FROM Test.Sample"

            datetime2         : 1/17/2013 8:46:22 AM
            ID                : 202507
            uniqueidentifier1 : 1d0cf1c0-9fb1-4e21-9d5a-b8e9365400fc
            bool1             : False
            datetime1         : 1/17/2013 12:00:00 AM
            double1           : 1
            varchar1          : varchar11
            decimal1          : 1
            int1              : 1

            Returned the first row as a System.Management.Automation.PSCustomObject.

        .EXAMPLE
            PS C:\> Invoke-SqlCommand -Server "DATASERVER" -Database "Web" -Query "SELECT COUNT(*) FROM Test.Sample" -As Scalar

            9544            
    #>
	[CmdletBinding(DefaultParameterSetName = "Default")]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string]$Server,
		[Parameter(Mandatory = $true, Position = 1)]
		[string]$Database,
		[Parameter(Mandatory = $false, Position = 2)]
		[int]$Timeout = 30,
		[System.Data.SqlClient.SQLConnection]$Connection,
		[string]$Username,
		[string]$Password,
		[System.Data.CommandType]$CommandType = [System.Data.CommandType]::Text,
		[string]$Query,
		[ValidateScript({ Test-Path -Path $_ })]
		[string]$Path,
		[hashtable]$Parameters,
		[ValidateSet("DataSet", "DataTable", "DataRow", "PSCustomObject", "Scalar", "NonQuery")]
		[string]$As = "PSCustomObject"
	)
	
	begin
	{
		if ($Path)
		{
			$Query = [System.IO.File]::ReadAllText("$((Resolve-Path -Path $Path).Path)")
		}
		else
		{
			if (-not $Query)
			{
				throw (New-Object System.ArgumentNullException -ArgumentList "Query", "The query statement is missing.")
			}
		}
		
		$createConnection = (-not $Connection)
		
		if ($createConnection)
		{
			$Connection = New-Object System.Data.SqlClient.SQLConnection
			if ($Username -and $Password)
			{
				$Connection.ConnectionString = "Server=$($Server);Database=$($Database);User Id=$($Username);Password=$($Password);"
			}
			else
			{
				$Connection.ConnectionString = "Server=$($Server);Database=$($Database);Integrated Security=SSPI;"
			}
			if ($PSBoundParameters.Verbose)
			{
				$Connection.FireInfoMessageEventOnUserErrors = $true
				$Connection.Add_InfoMessage([System.Data.SqlClient.SqlInfoMessageEventHandler] { Write-Verbose "$($_)" })
			}
		}
		
		if (-not ($Connection.State -like "Open"))
		{
			try { $Connection.Open() }
			catch [Exception] { throw $_ }
		}
	}
	
	process
	{
		$command = New-Object System.Data.SqlClient.SqlCommand ($query, $Connection)
		$command.CommandTimeout = $Timeout
		$command.CommandType = $CommandType
		if ($Parameters)
		{
			foreach ($p in $Parameters.Keys)
			{
				$command.Parameters.AddWithValue($p, $Parameters[$p]) | Out-Null
			}
		}
		
		$scriptBlock = {
			$result = @()
			$reader = $command.ExecuteReader()
			if ($reader)
			{
				$counter = $reader.FieldCount
				$columns = @()
				for ($i = 0; $i -lt $counter; $i++)
				{
					$columns += $reader.GetName($i)
				}
				
				if ($reader.HasRows)
				{
					while ($reader.Read())
					{
						$row = @{ }
						for ($i = 0; $i -lt $counter; $i++)
						{
							$row[$columns[$i]] = $reader.GetValue($i)
						}
						$result += [PSCustomObject]$row
					}
				}
			}
			$result
		}
		
		if ($As)
		{
			switch ($As)
			{
				"Scalar" {
					$scriptBlock = {
						$result = $command.ExecuteScalar()
						$result
					}
				}
				"NonQuery" {
					$scriptBlock = {
						$result = $command.ExecuteNonQuery()
						$result
					}
				}
				default {
					if ("DataSet", "DataTable", "DataRow" -contains $As)
					{
						$scriptBlock = {
							$ds = New-Object System.Data.DataSet
							$da = New-Object System.Data.SqlClient.SqlDataAdapter($command)
							$da.Fill($ds) | Out-Null
							switch ($As)
							{
								"DataSet" { $result = $ds }
								"DataTable" { $result = $ds.Tables }
								default { $result = $ds.Tables | ForEach-Object -Process { $_.Rows } }
							}
							$result
						}
					}
				}
			}
		}
		
		$result = Invoke-Command -ScriptBlock $ScriptBlock
		$command.Parameters.Clear()
	}
	
	end
	{
		if ($createConnection) { $Connection.Close() }
		
		$result
	}
}

Function Erase-BaseManagedEntity
{
	[OutputType([string])]
	param
	(
		[Parameter(Mandatory = $false,
				   Position = 1,
				   HelpMessage = "SCOM Management Server that we will remotely or locally connect to.")]
		[String]$ManagementServer,
		[Parameter(Mandatory = $false,
				   Position = 2,
				   HelpMessage = "SQL Server/Instance,Port that hosts OperationsManager Database for SCOM.")]
		[String]$SqlServer,
		[Parameter(Mandatory = $false,
				   Position = 3,
				   HelpMessage = "The name of the OperationsManager Database for SCOM.")]
		[String]$Database,
		[Parameter(Mandatory = $false,
				   ValueFromPipeline = $true,
				   Position = 4,
				   HelpMessage = "Each Server (comma seperated) you want to Remove related BME ID's related to the Display Name in the OperationsManager Database.")]
		[Array]$Agents,
		[Parameter(Mandatory = $false,
				   Position = 5,
				   HelpMessage = "Optionally assume yes to any question asked by this script.")]
		[Alias('yes')]
		[Switch]$AssumeYes
	)
	#-----------------------------------------------------------
	#region ScriptVariables
	#-----------------------------------------------------------
	#In the format of: ServerName\SQLInstance
	#ex: SQL01\SCOM2019
	if (!$ManagementServer)
	{
		$ManagementServer = 'MS1-2019'
	}
	if (!$SqlServer)
	{
		$SqlServer = "SQL-2019\SCOM2019"
	}
	
	if (!$Database)
	{
		$Database = "OperationsManager"
	}
	
	if (!$Agents)
	{
		#Name of Agent to Erase from SCOM
		#Fully Qualified (FQDN)
		[array]$Agents = "IIS-Server"
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
	
	$Timeout = '900'
	try
	{
		Invoke-Command -ComputerName $ManagementServer -ScriptBlock {
			Import-Module OperationsManager
			$administration = (Get-SCOMManagementGroup).GetAdministration();
			$agentManagedComputerType = [Microsoft.EnterpriseManagement.Administration.AgentManagedComputer];
			$genericListType = [System.Collections.Generic.List``1]
			$genericList = $genericListType.MakeGenericType($agentManagedComputerType)
			$agentList = new-object $genericList.FullName
			foreach ($serv in $using:Agents)
			{
				Write-Host "Deleting SCOM Agent: `'$serv`' from Agent Managed Computers"
				$agent = Get-SCOMAgent *$serv*
				$agentList.Add($agent);
			}
			$genericReadOnlyCollectionType = [System.Collections.ObjectModel.ReadOnlyCollection``1]
			$genericReadOnlyCollection = $genericReadOnlyCollectionType.MakeGenericType($agentManagedComputerType)
			$agentReadOnlyCollection = new-object $genericReadOnlyCollection.FullName @( ,$agentList);
			$administration.DeleteAgentManagedComputers($agentReadOnlyCollection);
		} -ErrorAction Stop
	}
	catch
	{
		Write-Warning "$_`n`nNo Changes have been made."
		if (!$DontStop)
		{
			break
		}
	}
	foreach ($machine in $Agents)
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
		
		$BME_IDs = (Invoke-SqlCommand -Timeout $Timeout -Server $SqlServer -Database $Database -Query $bme_query)
		
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
			Invoke-SqlCommand -Timeout $Timeout -Server $SqlServer -Database $Database -Query $delete_query
		}
		
		$remove_pending_management = @"
exec p_AgentPendingActionDeleteByAgentName "$machine"
"@
		
		Invoke-SqlCommand -Timeout $Timeout -Server $SqlServer -Database $Database -Query $remove_pending_management
		
		Write-Host "Cleared $machine from Pending Management List in SCOM Console." -ForegroundColor DarkGreen
	}
	$remove_count_query = @"
--Query 4
--Get an idea of how many BMEs are in scope to purge
SELECT count(*) FROM BaseManagedEntity WHERE IsDeleted = 1
"@
	
	$remove_count = (Invoke-SqlCommand -Timeout $Timeout -Server $SqlServer -Database $Database -Query $remove_count_query -As DataTable).Column1
	
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
		Invoke-SqlCommand -Timeout $Timeout -Server $SqlServer -Database $Database -Query $purge_deleted_query
		Write-Host "Successfully Purged the OperationsManager DB of Deleted Data!" -ForegroundColor Green
	}
	catch
	{
		Write-Error "Unable to Purge the Deleted Items from the OperationsManager DB`n`nCould not run the following command against the OperationsManager DB:`n$purge_deleted_query"
	}
	Write-Host "After running this script, attempt to Rediscover the Agent from the SCOM Console. Once you discover it, it may go into Pending Management, if so run the following command:`nGet-SCOMPendingManagement | Approve-SCOMPendingManagement"
	break
}

if ($ManagementServer -or $SqlServer -or $Database -or $Agents -or $AssumeYes -or $DontStop)
{
	Erase-BaseManagedEntity -ManagementServer $ManagementServer -SqlServer $SqlServer -Database $Database -Agents $Agents -AssumeYes:$AssumeYes -DontStop:$DontStop
}
else
{
<# Edit line 530 to modify the default command run when this script is executed.
   Example: 
   Erase-BaseManagedEntity -ManagementServer MS1-2019.contoso.com -SqlServer SQL-2019\SCOM2019 -Database OperationsManager -Agents Agent1.contoso.com, Agent2.contoso.com
   #>
	Erase-BaseManagedEntity
}
