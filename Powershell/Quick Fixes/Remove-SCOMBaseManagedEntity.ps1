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
		Each Server (comma seperated) you want to Remove related BME ID's related to the Display Name in the OperationsManager Database.
	
	.PARAMETER SqlServer
		SQL Server/Instance,Port that hosts OperationsManager Database for SCOM.
	
	.EXAMPLE
		Remove SCOM BME Related Data from the OperationsManager DB, on every Agent in the Management Group.
		PS C:\> Get-SCOMAgent | %{.\Remove-SCOMBaseManagedEntity.ps1 -Agents $_}
		
		Remove SCOM BME Related Data for 2 Agents machines:
		PS C:\> .\Remove-SCOMBaseManagedEntity.ps1 -Servers IIS-Server.contoso.com, WindowsServer.contoso.com
		
		Remove SCOM BME IDs from the Operations Manager Database:
		PS C:\> .\Remove-SCOMBaseManagedEntity -Id C1E9B41B-0A35-C069-16EB-00AC43BB9C47, CB29ECDE-BCE8-2213-D5DD-0353116EDA6B
	
	.NOTES
		.AUTHOR
		Blake Drumm (blakedrumm@microsoft.com)
		
		Github Page:
		https://github.com/blakedrumm/SCOM-Scripts-and-SQL/blob/master/Powershell/Remove-SCOMBaseManagedEntity.ps1
		
		Website:
		https://blakedrumm.com/
		
		.CREATED
		April 10th, 2021
		
		.MODIFIED
		February 26th, 2022
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
			   HelpMessage = "Each Server (comma seperated) you want to Remove related BME ID's related to the Display Name in the OperationsManager Database. This will also remove from Agent Managed.")]
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
					   HelpMessage = "Each Server (comma seperated) you want to Remove related BME ID's related to the Display Name in the OperationsManager Database. This will also remove from Agent Managed.")]
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
					catch { Write-Host 'Unable to delete from Agent Managed Computers' -ForegroundColor Cyan }
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
<# Edit line 726 to modify the default command run when this script is executed.
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
