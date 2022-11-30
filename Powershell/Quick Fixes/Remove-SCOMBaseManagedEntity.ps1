<#
	.SYNOPSIS
		Remove-SCOMBaseManagedEntity
	
	.DESCRIPTION
		This script removes any BME ID's in the OperationsManager DB related to the Display Name provided with the -Servers switch.
	
	.PARAMETER AssumeYes
		Optionally assume yes to any question asked by this script.
	
	.PARAMETER Database
		The name of the OperationsManager Database for SCOM.
	
	.PARAMETER DontStop
		Optionally force the script to not stop when an error occurs connecting to the Management Server.
	
	.PARAMETER Id
		You may provide any Base Managed Entity Id's to be deleted specifically from the Operations Manager Database.
	
	.PARAMETER ManagementServer
		The Management Server to remotely connect to. If you are running script is running on a Management Server it is not necessary to provide this paramter.
	
	.PARAMETER Name
		The Base Managed Entity Display Name of the object you are wanting to delete from the Operations Manager Database.
	
	.PARAMETER Servers
		Each Server (comma separated) you want to Remove related BME ID's related to the Display Name in the OperationsManager Database.
	
	.PARAMETER SqlServer
		SQL Server/Instance,Port that hosts OperationsManager Database for SCOM.
	
	.EXAMPLE
		Remove SCOM BME Related Data from the OperationsManager DB, on every Agent in the Management Group.
		PS C:\> Get-SCOMAgent | %{.\Remove-SCOMBaseManagedEntity.ps1 -Servers $_}
		
		Remove SCOM BME Related Data for 2 Agent machines:
		PS C:\> .\Remove-SCOMBaseManagedEntity.ps1 -Servers IIS-Server.contoso.com, WindowsServer.contoso.com
		
		Remove SCOM BME IDs from the Operations Manager Database:
		PS C:\> .\Remove-SCOMBaseManagedEntity -Id C1E9B41B-0A35-C069-16EB-00AC43BB9C47, CB29ECDE-BCE8-2213-D5DD-0353116EDA6B
	
	.NOTES
		.AUTHOR
		Blake Drumm (blakedrumm@microsoft.com)
		
		.NOTE
		Blog Post:
		https://blakedrumm.com/blog/remove-data-from-scom-database/
		
		Github Page:
		https://github.com/blakedrumm/SCOM-Scripts-and-SQL/blob/master/Powershell/Quick%20Fixes/Remove-SCOMBaseManagedEntity.ps1
		
		Website:
		https://blakedrumm.com/
		
		.CREATED
		April 10th, 2021
		
		.MODIFIED
		October 2nd, 2022
#>
[OutputType([string])]
param
(
	[Parameter(Mandatory = $false,
			   Position = 1,
			   HelpMessage = 'Optionally assume yes to any question asked by this script.')]
	[Alias('yes')]
	[Switch]$AssumeYes,
	[Parameter(Mandatory = $false,
			   Position = 2,
			   HelpMessage = 'The name of the OperationsManager Database for SCOM.')]
	[String]$Database,
	[Parameter(Mandatory = $false,
			   Position = 3,
			   HelpMessage = 'Optionally force the script to not stop when an error occurs connecting to the Management Server.')]
	[Alias('ds')]
	[Switch]$DontStop,
	[Parameter(Position = 4,
			   HelpMessage = "You may provide any Base Managed Entity Id's to be deleted specifically from the Operations Manager Database.")]
	[Array]$Id,
	[Parameter(Mandatory = $false,
			   Position = 5,
			   HelpMessage = 'SCOM Management Server that we will remotely connect to. If running on a Management Server, there is no need to provide this parameter.')]
	[Alias('ms')]
	[String]$ManagementServer,
	[Parameter(Position = 6,
			   HelpMessage = 'The Base Managed Entity Display Name of the object you are wanting to delete from the Operations Manager Database.')]
	[Array]$Name,
	[Parameter(Mandatory = $false,
			   ValueFromPipeline = $true,
			   Position = 7,
			   HelpMessage = "Each Server (comma separated) you want to Remove related BME ID's related to the Display Name in the OperationsManager Database. This will also remove from Agent Managed.")]
	[Array]$Servers,
	[Parameter(Mandatory = $false,
			   Position = 8,
			   HelpMessage = 'SQL Server/Instance, Port that hosts OperationsManager Database for SCOM.')]
	[String]$SqlServer
)
BEGIN
{
	# This script will run the Kevin Holman steps to Purge Agent Data from the OperationsManager DB as well as attempt to remove the server from Agent Managed:
	# https://kevinholman.com/2018/05/03/deleting-and-purging-data-from-the-scom-database/
	#----------------------------------------------------------------------------------------------------------------------------------
	# Author: Blake Drumm (blakedrumm@microsoft.com)
	
	Function Time-Stamp
	{
		$TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
		return "$TimeStamp - "
	}
	
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
}
PROCESS
{
	Function Remove-SCOMBaseManagedEntity
	{
		[OutputType([string])]
		param
		(
			[Parameter(Mandatory = $false,
					   Position = 1,
					   HelpMessage = 'Optionally assume yes to any question asked by this script.')]
			[Alias('yes')]
			[Switch]$AssumeYes,
			[Parameter(Mandatory = $false,
					   Position = 2,
					   HelpMessage = 'The name of the OperationsManager Database for SCOM.')]
			[String]$Database,
			[Parameter(Mandatory = $false,
					   Position = 3,
					   HelpMessage = 'Optionally force the script to not stop when an error occurs connecting to the Management Server.')]
			[Alias('ds')]
			[Switch]$DontStop,
			[Parameter(Position = 4,
					   HelpMessage = "You may provide any Base Managed Entity Id's to be deleted specifically from the Operations Manager Database.")]
			[Array]$Id,
			[Parameter(Mandatory = $false,
					   Position = 5,
					   HelpMessage = "SCOM Management Server that we will remotely connect to. If running on a Management Server, there is no need to provide this parameter.")]
			[Alias('ms')]
			[String]$ManagementServer,
			[Parameter(Position = 6,
					   HelpMessage = 'The Base Managed Entity Display Name of the object you are wanting to delete from the Operations Manager Database.')]
			[Array]$Name,
			[Parameter(Mandatory = $false,
					   ValueFromPipeline = $true,
					   Position = 7,
					   HelpMessage = "Each Server (comma separated) you want to Remove related BME ID's related to the Display Name in the OperationsManager Database. This will also remove from Agent Managed.")]
			[Array]$Servers,
			[Parameter(Mandatory = $false,
					   Position = 8,
					   HelpMessage = 'SQL Server/Instance, Port that hosts OperationsManager Database for SCOM.')]
			[String]$SqlServer
		)
		#-----------------------------------------------------------
		#region ScriptVariables
		#-----------------------------------------------------------
		#In the format of: ServerName\SQLInstance
		#ex: SQL01\SCOM2019
		if (!$ManagementServer)
		{
			$ManagementServer = $env:COMPUTERNAME
		}
		if (!$SqlServer)
		{
			try
			{
				$sqlInput = Get-ItemProperty -Path 'HKLM:\Software\Microsoft\System Center\2010\Common\Database\' -ErrorAction Stop | Select-Object DatabaseName, DatabaseServerName
				$SqlServer = $sqlInput.DatabaseServerName
				if (!$Database)
				{
					$Database = $sqlInput.DatabaseName
				}
			}
			catch
			{
				Write-Warning 'Please Provide the -Database Parameter. The script is unable to detect Database settings in this registry path: HKLM:\Software\Microsoft\System Center\2010\Common\Database\'
				Write-Warning "$(Time-Stamp)Exiting script due to no SQL database connection detected."
				[GC]::Collect()
				Break
			}
		}
		
		if (!$Servers -and !$Id -and !$Name)
		{
			Write-Host "$(Time-Stamp)Missing required parameters: -Servers OR -Id OR -Name"
			[GC]::Collect()
			break
		}
		if (!$Servers)
		{
		<#
		#Name of Server to Remove from SCOM DB
		#Fully Qualified (FQDN)
		[array]$Servers = "IIS-Server"
		#>
			Write-Verbose "Missing Servers to be removed, run the script with -Servers argument to remove SCOM Servers by name from the Operations Manager database. (ex: -Servers Agent1.contoso.com)"
		}
		if (!$Id)
		{
			Write-Verbose "Missing Base Managed Entity Id, pass like this: -Id 94D26D20-4539-7CFD-2FFD-259C957F1FE0"
		}
		elseif (!$Name)
		{
			Write-Verbose "Missing name of the BMEs you are trying to delete, pass like this: -Name CdpSvc"
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
		Write-Verbose "Timeout is set to 900 seconds."
		try
		{
			if ($Servers)
			{
				if ($ManagementServer -match "^$env:COMPUTERNAME")
				{
					Write-Verbose "Locally running commands to remove Agent Managed Server from SCOM on: $ManagementServer"
					Import-Module OperationsManager
					$administration = (Get-SCOMManagementGroup).GetAdministration();
					$agentManagedComputerType = [Microsoft.EnterpriseManagement.Administration.AgentManagedComputer];
					$genericListType = [System.Collections.Generic.List``1]
					$genericList = $genericListType.MakeGenericType($agentManagedComputerType)
					$agentList = new-object $genericList.FullName
					foreach ($serv in $Servers)
					{
						if (!$AssumeYes)
						{
							do
							{
								$answer = Read-Host -Prompt 'Do you want to delete the SCOM Agent from Managed Computers? (Y/N)'
							}
							until ($answer -eq "y" -or $answer -eq "n")
							
						}
						else
						{
							$answer = 'y'
						}
						if ($answer -eq 'y')
						{
							Write-Host "$(Time-Stamp)Deleting SCOM Agent: `'$serv`' from Agent Managed Computers"
							$agent = Get-SCOMAgent $serv*
							$agentList.Add($agent);
						}
						else
						{
							Write-Host "$(Time-Stamp)Skipping deletion from Agent Managed Computers."
						}
						
					}
					$genericReadOnlyCollectionType = [System.Collections.ObjectModel.ReadOnlyCollection``1]
					$genericReadOnlyCollection = $genericReadOnlyCollectionType.MakeGenericType($agentManagedComputerType)
					$agentReadOnlyCollection = new-object $genericReadOnlyCollection.FullName @( ,$agentList);
					try
					{
						$administration.DeleteAgentManagedComputers($agentReadOnlyCollection);
					}
					catch { Write-Host "$(Time-Stamp)Unable to delete from Agent Managed Computers" -ForegroundColor Cyan }
				}
				else
				{
					Write-Verbose "Remotely running commands to remove Agent Managed Server from SCOM on: $ManagementServer"
					Invoke-Command -ComputerName $ManagementServer -ScriptBlock {
						Import-Module OperationsManager
						$administration = (Get-SCOMManagementGroup).GetAdministration();
						$agentManagedComputerType = [Microsoft.EnterpriseManagement.Administration.AgentManagedComputer];
						$genericListType = [System.Collections.Generic.List``1]
						$genericList = $genericListType.MakeGenericType($agentManagedComputerType)
						$agentList = new-object $genericList.FullName
						foreach ($serv in $using:Servers)
						{
							Write-Host "$(Time-Stamp)Deleting SCOM Agent: `'$serv`' from Agent Managed Computers"
							$agent = Get-SCOMAgent *$serv*
							$agentList.Add($agent);
						}
						$genericReadOnlyCollectionType = [System.Collections.ObjectModel.ReadOnlyCollection``1]
						$genericReadOnlyCollection = $genericReadOnlyCollectionType.MakeGenericType($agentManagedComputerType)
						$agentReadOnlyCollection = new-object $genericReadOnlyCollection.FullName @( ,$agentList);
						try
						{
							$administration.DeleteAgentManagedComputers($agentReadOnlyCollection);
						}
						catch { Write-Host "$(Time-Stamp)Unable to delete from Agent Managed Computers" -ForegroundColor Cyan }
					} -ErrorAction Stop
				}
			}
			
		}
		catch
		{
			Write-Warning "$(Time-Stamp)$_`n`nNo Changes have been made."
			if (!$DontStop)
			{
				[GC]::Collect()
				break
			}
		}
		if ($Id)
		{
			foreach ($bmeId in $Id)
			{
				$bme_query = @"
--Query 1
--
SELECT BaseManagedEntityId, FullName, DisplayName, IsDeleted, Path, Name
FROM BaseManagedEntity WHERE IsDeleted = '0' AND BaseManagedEntityId = '$bmeId'
ORDER BY FullName
"@
				Write-Verbose $bme_query
				$Specific_BMEIDs = (Invoke-SqlCommand -Timeout $Timeout -Server $SqlServer -Database $Database -Query $bme_query)
				
				if (!$Specific_BMEIDs)
				{
					Write-Warning "$(Time-Stamp)Unable to find any data in the OperationsManager DB associated with: $bmeId"
					continue
				}
				
				Write-Host "$(Time-Stamp)Found the following data associated with: " -NoNewline
				Write-Host $bmeId -ForegroundColor Magenta
				$Specific_BMEIDs | Select-Object FullName, DisplayName, Path, IsDeleted, BaseManagedEntityId | Format-Table * -AutoSize | Out-String -Width 4096
				if (!$yes)
				{
					do
					{
						$answer3 = Read-Host -Prompt "Do you want to delete the above $(($Specific_BMEIDs.BaseManagedEntityId).Count) item(s) from the OperationsManager DB? (Y/N)"
					}
					until ($answer3 -eq "y" -or $answer3 -eq "n")
				}
				else
				{ $answer3 = 'y' }
				if ($answer3 -eq "n")
				{ continue }
				foreach ($BaseManagedEntityID in $Specific_BMEIDs)
				{
					Write-Host "$(Time-Stamp) Gracefully deleting the following from OperationsManager Database:`n`tName: " -NoNewline
					$BaseManagedEntityID.FullName | Write-Host -ForegroundColor Green
					Write-Host "$(Time-Stamp) `tBME ID: " -NoNewline
					$BaseManagedEntityID.BaseManagedEntityId | Write-Host -ForegroundColor Gray
					
					Write-Host ''
					
					$current_bme = $BaseManagedEntityID.BaseManagedEntityId.Guid
					Write-Verbose "Current BME: $current_bme"
					
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
					Write-Verbose $delete_query
					Invoke-SqlCommand -Timeout $Timeout -Server $SqlServer -Database $Database -Query $delete_query
				}
			}
		}
		else
		{
			foreach ($machine in $Servers)
			{
				$bme_query = @"
--Query 1
--First get the Base Managed Entity ID of the object you think is orphaned/bad/needstogo:
--
DECLARE @name varchar(255) = '%$machine%'
--
SELECT BaseManagedEntityId, FullName, DisplayName, IsDeleted, Path, Name
FROM BaseManagedEntity WHERE IsDeleted = '0' AND FullName like @name OR DisplayName like @name
ORDER BY FullName
"@
				Write-Verbose $bme_query
				$BME_IDs = (Invoke-SqlCommand -Timeout $Timeout -Server $SqlServer -Database $Database -Query $bme_query)
				
				if (!$BME_IDs)
				{
					Write-Warning "$(Time-Stamp)Unable to find any data in the OperationsManager DB associated with: $machine"
					continue
				}
				
				Write-Host "$(Time-Stamp)Found the following data associated with: " -NoNewline
				Write-Host $machine -ForegroundColor Green
				$BME_IDs | Select-Object FullName, DisplayName, Path, IsDeleted, BaseManagedEntityId | Format-Table * -AutoSize | Out-String -Width 4096
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
					Write-Host "$(Time-Stamp) Gracefully deleting the following from OperationsManager Database:`n`tName: " -NoNewline
					$BaseManagedEntityID.FullName | Write-Host -ForegroundColor Green
					Write-Host "$(Time-Stamp) `tBME ID: " -NoNewline
					$BaseManagedEntityID.BaseManagedEntityId | Write-Host -ForegroundColor Gray
					
					Write-Host ''
					
					$current_bme = $BaseManagedEntityID.BaseManagedEntityId.Guid
					Write-Verbose "Current BME: $current_bme"
					
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
					Write-Verbose $delete_query
					Invoke-SqlCommand -Timeout $Timeout -Server $SqlServer -Database $Database -Query $delete_query
					Start-Sleep -Seconds 1
				}
				
				$remove_pending_management = @"
exec p_AgentPendingActionDeleteByAgentName "$machine"
"@
				Write-Verbose $remove_pending_management
				Invoke-SqlCommand -Timeout $Timeout -Server $SqlServer -Database $Database -Query $remove_pending_management
				
				Write-Host "$(Time-Stamp)Cleared $machine from Pending Management List in SCOM Console." -ForegroundColor DarkGreen
			}
		}
		$remove_count_query = @"
--Query 4
--Get an idea of how many BMEs are in scope to purge
SELECT count(*) FROM BaseManagedEntity WHERE IsDeleted = 1
"@
		Write-Verbose $remove_count_query
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
		{ Write-Host "$(Time-Stamp)No action was taken to purge from OperationsManager DB. (Purging will happen on its own eventually)" -ForegroundColor Cyan; [GC]::Collect(); break }
		$purge_deleted_query = @"
--Query 5
--This query statement for SCOM 20xx will purge all IsDeleted=1 objects immediately
--Normally this is a 2-3day wait before this would happen naturally
--This only purges 10000 records. If you have more it will require multiple runs
--Purge IsDeleted=1 data from the SCOM 20xx DB:
DECLARE @TimeGenerated DATETIME, @BatchSize INT, @RowCount INT
SET @TimeGenerated = GETUTCDATE()
SET @BatchSize = 10000
EXEC p_DiscoveryDataPurgingByRelationship @TimeGenerated, @BatchSize, @RowCount
EXEC p_DiscoveryDataPurgingByTypedManagedEntity @TimeGenerated, @BatchSize, @RowCount
EXEC p_DiscoveryDataPurgingByBaseManagedEntity @TimeGenerated, @BatchSize, @RowCount
"@
		Write-Verbose $purge_deleted_query
		try
		{
			Invoke-SqlCommand -Timeout $Timeout -Server $SqlServer -Database $Database -Query $purge_deleted_query
			Write-Host "$(Time-Stamp)Successfully Purged the OperationsManager DB of Deleted Data!" -ForegroundColor Green
		}
		catch
		{
			Write-Error "Unable to Purge the Deleted Items from the OperationsManager DB`n`nCould not run the following command against the OperationsManager DB:`n$purge_deleted_query"
		}
		if ($Servers)
		{
			Write-Host "$(Time-Stamp)After running this script, attempt to Rediscover the Agent from the SCOM Console. Once you discover it`nthe server may go into Pending Management, if so run the following command:`nGet-SCOMPendingManagement | Approve-SCOMPendingManagement`n`nAlso run this Clear Cache Script on the Agent (do not modify, just copy to Powershell ISE on the Agent):`nhttps://github.com/blakedrumm/SCOM-Scripts-and-SQL/blob/master/Powershell/Clear-SCOMCache.ps1"
			[GC]::Collect()
			break
		}
	}
	
	if ($ManagementServer -or $Id -or $SqlServer -or $Database -or $Servers -or $AssumeYes -or $DontStop)
	{
		Remove-SCOMBaseManagedEntity -ManagementServer $ManagementServer -Id $Id -SqlServer $SqlServer -Database $Database -Servers $Servers -AssumeYes:$AssumeYes -DontStop:$DontStop
	}
	else
	{
<# Edit line 752 to modify the default command run when this script is executed.
   Example:
   Remove-SCOMBaseManagedEntity -ManagementServer MS1-2019.contoso.com -SqlServer SQL-2019\SCOM2019 -Database OperationsManager -Servers Agent1.contoso.com, Agent2.contoso.com
   
   OR
   If you are already running on a Management Server, just run like this:
   Remove-SCOMBaseManagedEntity -Servers Agent1.contoso.com

   OR
   If you need to remove specific Base Managed Entity ID's from the Database:
   Remove-SCOMBaseManagedEntity -Id C1E9B41B-0A35-C069-16EB-00AC43BB9C47, CB29ECDE-BCE8-2213-D5DD-0353116EDA6B
   #>
		Remove-SCOMBaseManagedEntity
	}
}
END
{
	Write-Host "$(Time-Stamp)Script has Completed!" -ForegroundColor Green
	[GC]::Collect()
}

# SIG # Begin signature block
# MIInmAYJKoZIhvcNAQcCoIIniTCCJ4UCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCTgbi3D25GvIN7
# NHMI98+3dy1iCUPw1iVHjm+rpYTHtaCCDXYwggX0MIID3KADAgECAhMzAAACy7d1
# OfsCcUI2AAAAAALLMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjIwNTEyMjA0NTU5WhcNMjMwNTExMjA0NTU5WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQC3sN0WcdGpGXPZIb5iNfFB0xZ8rnJvYnxD6Uf2BHXglpbTEfoe+mO//oLWkRxA
# wppditsSVOD0oglKbtnh9Wp2DARLcxbGaW4YanOWSB1LyLRpHnnQ5POlh2U5trg4
# 3gQjvlNZlQB3lL+zrPtbNvMA7E0Wkmo+Z6YFnsf7aek+KGzaGboAeFO4uKZjQXY5
# RmMzE70Bwaz7hvA05jDURdRKH0i/1yK96TDuP7JyRFLOvA3UXNWz00R9w7ppMDcN
# lXtrmbPigv3xE9FfpfmJRtiOZQKd73K72Wujmj6/Su3+DBTpOq7NgdntW2lJfX3X
# a6oe4F9Pk9xRhkwHsk7Ju9E/AgMBAAGjggFzMIIBbzAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUrg/nt/gj+BBLd1jZWYhok7v5/w4w
# RQYDVR0RBD4wPKQ6MDgxHjAcBgNVBAsTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEW
# MBQGA1UEBRMNMjMwMDEyKzQ3MDUyODAfBgNVHSMEGDAWgBRIbmTlUAXTgqoXNzci
# tW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3JsMGEG
# CCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3J0
# MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIBAJL5t6pVjIRlQ8j4dAFJ
# ZnMke3rRHeQDOPFxswM47HRvgQa2E1jea2aYiMk1WmdqWnYw1bal4IzRlSVf4czf
# zx2vjOIOiaGllW2ByHkfKApngOzJmAQ8F15xSHPRvNMmvpC3PFLvKMf3y5SyPJxh
# 922TTq0q5epJv1SgZDWlUlHL/Ex1nX8kzBRhHvc6D6F5la+oAO4A3o/ZC05OOgm4
# EJxZP9MqUi5iid2dw4Jg/HvtDpCcLj1GLIhCDaebKegajCJlMhhxnDXrGFLJfX8j
# 7k7LUvrZDsQniJZ3D66K+3SZTLhvwK7dMGVFuUUJUfDifrlCTjKG9mxsPDllfyck
# 4zGnRZv8Jw9RgE1zAghnU14L0vVUNOzi/4bE7wIsiRyIcCcVoXRneBA3n/frLXvd
# jDsbb2lpGu78+s1zbO5N0bhHWq4j5WMutrspBxEhqG2PSBjC5Ypi+jhtfu3+x76N
# mBvsyKuxx9+Hm/ALnlzKxr4KyMR3/z4IRMzA1QyppNk65Ui+jB14g+w4vole33M1
# pVqVckrmSebUkmjnCshCiH12IFgHZF7gRwE4YZrJ7QjxZeoZqHaKsQLRMp653beB
# fHfeva9zJPhBSdVcCW7x9q0c2HVPLJHX9YCUU714I+qtLpDGrdbZxD9mikPqL/To
# /1lDZ0ch8FtePhME7houuoPcMIIHejCCBWKgAwIBAgIKYQ6Q0gAAAAAAAzANBgkq
# hkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEwOTA5WjB+MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQg
# Q29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+laUKq4BjgaBEm6f8MMHt03
# a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc6Whe0t+bU7IKLMOv2akr
# rnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4Ddato88tt8zpcoRb0Rrrg
# OGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+lD3v++MrWhAfTVYoonpy
# 4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nkkDstrjNYxbc+/jLTswM9
# sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6A4aN91/w0FK/jJSHvMAh
# dCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmdX4jiJV3TIUs+UsS1Vz8k
# A/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL5zmhD+kjSbwYuER8ReTB
# w3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zdsGbiwZeBe+3W7UvnSSmn
# Eyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3T8HhhUSJxAlMxdSlQy90
# lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS4NaIjAsCAwEAAaOCAe0w
# ggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRIbmTlUAXTgqoXNzcitW2o
# ynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYD
# VR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBDuRQFTuHqp8cx0SOJNDBa
# BgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2Ny
# bC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3JsMF4GCCsG
# AQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3J0MIGfBgNV
# HSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEFBQcCARYzaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1hcnljcHMuaHRtMEAGCCsG
# AQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkAYwB5AF8AcwB0AGEAdABl
# AG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn8oalmOBUeRou09h0ZyKb
# C5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7v0epo/Np22O/IjWll11l
# hJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0bpdS1HXeUOeLpZMlEPXh6
# I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/KmtYSWMfCWluWpiW5IP0
# wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvyCInWH8MyGOLwxS3OW560
# STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBpmLJZiWhub6e3dMNABQam
# ASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJihsMdYzaXht/a8/jyFqGa
# J+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYbBL7fQccOKO7eZS/sl/ah
# XJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbSoqKfenoi+kiVH6v7RyOA
# 9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sLgOppO6/8MO0ETI7f33Vt
# Y5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtXcVZOSEXAQsmbdlsKgEhr
# /Xmfwb1tbWrJUnMTDXpQzTGCGXgwghl0AgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAALLt3U5+wJxQjYAAAAAAsswDQYJYIZIAWUDBAIB
# BQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIP1gv7wn9OXs4G+R54mkjZlb
# sGgMDP/86KYdNMRSToexMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQAqcZFe1Iu5HI1dZDU4NiYdyoqetTccVdthjl/RtA2Ox/T8zHTic8m9
# qy18IxYBj/tP/QNdgUjFyPAjtDhFXvpcROE58twQ04VQVELMKKhnHzN0Ro2vH24d
# /C1N/f+crYa68e9MIOqsRQCYvyTFqZR33yMb17bV2Dps5j4uy0YUZS8UkbnjiG1X
# VEu1PvGRUik/mNgxpTZmVNgDkkplWMMNZB/PNrDrqgjcbaIHXzBJObwlYYPoc82+
# r90to5ukFHJODQYT6GQT30YpKEe/kF1BKVfGQ1q93YYyxntC495oPiTRerOOhVOd
# KI1anBUUYfZjkSEbkJgRTQEJ1b8bewBmoYIXADCCFvwGCisGAQQBgjcDAwExghbs
# MIIW6AYJKoZIhvcNAQcCoIIW2TCCFtUCAQMxDzANBglghkgBZQMEAgEFADCCAVEG
# CyqGSIb3DQEJEAEEoIIBQASCATwwggE4AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEIFKj/vkLaUDFPMVbD7WZcygtA6isZSYSpD3KHUljxXUEAgZjbOKH
# NigYEzIwMjIxMTI5MjAzMDE1LjQyMlowBIACAfSggdCkgc0wgcoxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBB
# bWVyaWNhIE9wZXJhdGlvbnMxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOkREOEMt
# RTMzNy0yRkFFMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNl
# oIIRVzCCBwwwggT0oAMCAQICEzMAAAHFA83NIaH07zkAAQAAAcUwDQYJKoZIhvcN
# AQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQG
# A1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcNMjIxMTA0MTkw
# MTMyWhcNMjQwMjAyMTkwMTMyWjCByjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9u
# czEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046REQ4Qy1FMzM3LTJGQUUxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQCrSF2zvR5fbcnulqmlopdGHP5NPsknc69V/f43x82n
# FGzmNjiES/cFX/DkRZdtl07ibfGPTWVMj/EOSr7K2O6I97zEZexnEOe2/svUTMx3
# mMhKon55i7ySBXTnqaqzx0GjnnFk889zF/m7X3OfThoxAXk9dX8LhktKMVr0gU1y
# uJt06beUZbWtBEVraNSy6nqC/rfirlTAfT1YYa7TPz1Fu1vIznm+YGBZXx53ptkJ
# mtyhgiMwvwVFO8aXOeqboe3Bl1czAodPdr+QtRI+IYCysiATPPs2kGl46yCz1OvD
# JZNkE1sHDIgAKZDfiP65Hh63aFmT40fj0qEQnJgPb504hoMYHYRQ0VJhzLUySC1m
# 3V5GoEHSb5g9jPseOhw/KQpg1BntO/7OCU598KJrHWM5vS7ohgLlfUmvwDBNyxoP
# K7eoCHHxwVA30MOCJVnD5REVnyjKgOTqwhXWfHnNkvL6E21qR49f1LtjyfWpZ8CO
# hc8TorT91tPDzsQ4kv8GUkZwqgVPK2vTM+D8w0lJvp/Zr/AORegYIZYmJCsZPGM4
# /5H3r+cggbTl4TUumTLYU51gw8HgOFbu0F1lq616lNO5KGaCf4YoRHwCgDWBJKTU
# QLllfhymlWeAmluUwG7yv+0KF8dV1e+JjqENKEfBAKZmpl5uBJgeceXi6sT7grpk
# LwIDAQABo4IBNjCCATIwHQYDVR0OBBYEFFTquzi/WbE1gb+u2kvCtXB6TQVrMB8G
# A1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCG
# Tmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUy
# MFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4w
# XAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2Vy
# dHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwG
# A1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZIhvcNAQELBQAD
# ggIBAIyo3nx+swc5JxyIr4J2evp0rx9OyBAN5n1u9CMK7E0glkn3b7Gl4pEJ/der
# jup1HKSQpSdkLp0eEvC3V+HDKLL8t91VD3J/WFhn9GlNL7PSGdqgr4/8gMCJQ2bf
# Y1cuEMG7Q/hJv+4JXiM641RyYmGmkFCBBWEXH/nsliTUsJ2Mh57/8atx9uRC2Jih
# v05r3cNKNuwPWOpqJwSeRyVQ3+YSb1mycKcDX785AOn/xDhw98f3gszgnpfQ200F
# 5XLC9YfTC4xo4nMeAMsJ4lSQUT0cTywENV52aPrM8kAj7ujMuNirDuLhEVuJK19Z
# lIaPC36UslBlFZQJxPdodi9OjVhYNmySiFaDvvD18XZBuI70N+eqhntCjMeLtGI+
# luOCQkwCGuGl5N/9q3Z734diQo5tSaA8CsfVaOK/CbV3s9haxqsvu7mpm6TfoZvW
# YRNLWgDZdff4LeuC3NGiE/z2plV/v2VW+OaDfg20gIr+kyT31IG62CG2KkVIxB1t
# dSdLah4u31wq6/Uwm76AnzepdM2RDZCqHG01G9sT1CqaolDDlVb/hJnN7Wk9fHI5
# M7nIOr6JEhS5up5DOZRwKSLI24IsdaHw4sIjmYg4LWIu1UN/aXD15auinC7lIMm1
# P9nCohTWpvZT42OQ1yPWFs4MFEQtpNNZ33VEmJQj2dwmQaD+MIIHcTCCBVmgAwIB
# AgITMwAAABXF52ueAptJmQAAAAAAFTANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0
# IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMTAwHhcNMjEwOTMwMTgyMjI1
# WhcNMzAwOTMwMTgzMjI1WjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAOThpkzntHIhC3miy9ckeb0O
# 1YLT/e6cBwfSqWxOdcjKNVf2AX9sSuDivbk+F2Az/1xPx2b3lVNxWuJ+Slr+uDZn
# hUYjDLWNE893MsAQGOhgfWpSg0S3po5GawcU88V29YZQ3MFEyHFcUTE3oAo4bo3t
# 1w/YJlN8OWECesSq/XJprx2rrPY2vjUmZNqYO7oaezOtgFt+jBAcnVL+tuhiJdxq
# D89d9P6OU8/W7IVWTe/dvI2k45GPsjksUZzpcGkNyjYtcI4xyDUoveO0hyTD4MmP
# frVUj9z6BVWYbWg7mka97aSueik3rMvrg0XnRm7KMtXAhjBcTyziYrLNueKNiOSW
# rAFKu75xqRdbZ2De+JKRHh09/SDPc31BmkZ1zcRfNN0Sidb9pSB9fvzZnkXftnIv
# 231fgLrbqn427DZM9ituqBJR6L8FA6PRc6ZNN3SUHDSCD/AQ8rdHGO2n6Jl8P0zb
# r17C89XYcz1DTsEzOUyOArxCaC4Q6oRRRuLRvWoYWmEBc8pnol7XKHYC4jMYcten
# IPDC+hIK12NvDMk2ZItboKaDIV1fMHSRlJTYuVD5C4lh8zYGNRiER9vcG9H9stQc
# xWv2XFJRXRLbJbqvUAV6bMURHXLvjflSxIUXk8A8FdsaN8cIFRg/eKtFtvUeh17a
# j54WcmnGrnu3tz5q4i6tAgMBAAGjggHdMIIB2TASBgkrBgEEAYI3FQEEBQIDAQAB
# MCMGCSsGAQQBgjcVAgQWBBQqp1L+ZMSavoKRPEY1Kc8Q/y8E7jAdBgNVHQ4EFgQU
# n6cVXQBeYl2D9OXSZacbUzUZ6XIwXAYDVR0gBFUwUzBRBgwrBgEEAYI3TIN9AQEw
# QTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9E
# b2NzL1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQMMAoGCCsGAQUFBwMIMBkGCSsGAQQB
# gjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/
# MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fOmhjEMFYGA1UdHwRPME0wS6BJ
# oEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01p
# Y1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYB
# BQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljUm9v
# Q2VyQXV0XzIwMTAtMDYtMjMuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQCdVX38Kq3h
# LB9nATEkW+Geckv8qW/qXBS2Pk5HZHixBpOXPTEztTnXwnE2P9pkbHzQdTltuw8x
# 5MKP+2zRoZQYIu7pZmc6U03dmLq2HnjYNi6cqYJWAAOwBb6J6Gngugnue99qb74p
# y27YP0h1AdkY3m2CDPVtI1TkeFN1JFe53Z/zjj3G82jfZfakVqr3lbYoVSfQJL1A
# oL8ZthISEV09J+BAljis9/kpicO8F7BUhUKz/AyeixmJ5/ALaoHCgRlCGVJ1ijbC
# HcNhcy4sa3tuPywJeBTpkbKpW99Jo3QMvOyRgNI95ko+ZjtPu4b6MhrZlvSP9pEB
# 9s7GdP32THJvEKt1MMU0sHrYUP4KWN1APMdUbZ1jdEgssU5HLcEUBHG/ZPkkvnNt
# yo4JvbMBV0lUZNlz138eW0QBjloZkWsNn6Qo3GcZKCS6OEuabvshVGtqRRFHqfG3
# rsjoiV5PndLQTHa1V1QJsWkBRH58oWFsc/4Ku+xBZj1p/cvBQUl+fpO+y/g75LcV
# v7TOPqUxUYS8vwLBgqJ7Fx0ViY1w/ue10CgaiQuPNtq6TPmb/wrpNPgkNWcr4A24
# 5oyZ1uEi6vAnQj0llOZ0dFtq0Z4+7X6gMTN9vMvpe784cETRkPHIqzqKOghif9lw
# Y1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGCAs4wggI3AgEBMIH4oYHQpIHNMIHK
# MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
# bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxN
# aWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMSYwJAYDVQQLEx1UaGFsZXMgVFNT
# IEVTTjpERDhDLUUzMzctMkZBRTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3Rh
# bXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUAIQAa9hdkkrtxSjrb4u8RhATHv+eg
# gYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYw
# JAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0B
# AQUFAAIFAOcwbO0wIhgPMjAyMjExMjkxOTM1MDlaGA8yMDIyMTEzMDE5MzUwOVow
# dzA9BgorBgEEAYRZCgQBMS8wLTAKAgUA5zBs7QIBADAKAgEAAgISKgIB/zAHAgEA
# AgIRuzAKAgUA5zG+bQIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMC
# oAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUAA4GBAMX4G3gw
# 0jHHyZM8n0vILFqaFFA2cYWrZglzk26vmC5dyM9NMdeC4Lyq4ufduDbZ/UWCISv9
# f2xBSXfWg80gUlIiQS4tAK1NLL1epigvncj4GKKmm5MTRNc9HTXzlkqvK299ikfc
# htDh0zoJx8jxiA45T3/o86H3DzD+8OHFqlgJMYIEDTCCBAkCAQEwgZMwfDELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9z
# b2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAHFA83NIaH07zkAAQAAAcUwDQYJ
# YIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkq
# hkiG9w0BCQQxIgQgSMGNbkfPOXP4aPaCWrBVT9jDUkGIBhHrXhmDJ49xjZgwgfoG
# CyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCAZAbGR9iR3TAr5XT3A7Sw76ybyAAzK
# PkS4o+q81D98sTCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
# AhMzAAABxQPNzSGh9O85AAEAAAHFMCIEIFlWNoD0jhdBVpSAlVibub4qR+rAzjwO
# S8ics/rkuWH1MA0GCSqGSIb3DQEBCwUABIICAGV8XYT5vHd+I897rp7hwMhL7r85
# 0eLDa+H5HbiNnHlwTCBDuNBQ5N4B5qx8Ac923dV+Etsire0Swcj8zGCy9aBE7LR4
# pamq4rma034RqQPvbI91sBAD+xFdJZSDue1xfbfwr6myhiBt5bJejy06UrDcbrwA
# cdMe0lf5QKd3eGZQ7N2IQ/Y16hBnshZwquy2loN0FIwrYzeR9C/MpRpMug55yI6y
# wTO+XoEToEDgvaP1jlNfteAXKFedXpha9zzGDZ7RX2kfyVJFhNda7Z84zGlqpWfa
# Vt3FZvfmQFs/epBxdYGf2QUKtPQvcKZxFQNZQk+QyR7lobctzeofKF87BZXBmVrs
# vR6xXZud9gEzwTgDxg9fG22zYr20pTxegz7HwHf1BcFVG2wQ2knVruqeAiGyAXQ0
# whXihA2tinS0vYl38jN6NSURPzjbV97TmmB+JTj28NeRBRYx1HVdlfBtT53Sd7C7
# iFgSEnRH7PL0GsaxzDeqzgyDGUMYoFOR7bc9kaULhjsBA14wHWKuiy6RjL/cGsUn
# T9pAWddY+eLh5yM83aXbXn5lYHdRkjIi/enJyeZ/5yYb3iGBZbPraQjcax64aVz1
# 42XGyVt9ro7UkQTHyST0bNkT6fQqDseSZU8ou3c1n9FRUGBk5xwoTOl58V99XCWk
# yV708qBUXAGQgIW4
# SIG # End signature block
