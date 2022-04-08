function Invoke-SqlCommand
{
	[CmdletBinding(DefaultParameterSetName = 'Default')]
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 0)]
		[string]$ServerInstance,
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[string]$Database,
		[Parameter(Mandatory = $false,
				   Position = 2)]
		[int]$Timeout = 30,
		[System.Data.SqlClient.SQLConnection]$Connection,
		[string]$Username,
		[string]$Password,
		[System.Data.CommandType]$CommandType = [System.Data.CommandType]::Text,
		[string]$Query,
		[ValidateScript({ Test-Path -Path $_ })]
		[string]$Path,
		[hashtable]$Parameters,
		[ValidateSet('DataSet', 'DataTable', 'DataRow', 'PSCustomObject', 'Scalar', 'NonQuery')]
		[string]$As = "PSCustomObject"
	)
	
	begin
	{
		
		trap
		{
			$ErrorDetails = @"

User:
$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

Error Details:
$($Error[0])

SQL Query:
$Query
"@
			Write-Warning "Encountered exception while running SQL Query: $ErrorDetails"
			
			[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")
			[Microsoft.VisualBasic.Interaction]::MsgBox(@"
Event ID:
11

User:
$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

Error Details:
$($Error[0])

For more details see the Application Event Log.
"@, "OKOnly,SystemModal,Critical,DefaultButton2", "Encountered exception while attempting to run SQL Query") | Out-Null
		}
		
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
				$Connection.ConnectionString = "Server=$($ServerInstance);Database=$($Database);User Id=$($Username);Password=$($Password);"
			}
			else
			{
				$Connection.ConnectionString = "Server=$($ServerInstance);Database=$($Database);Integrated Security=SSPI;"
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
		try
		{
			$result = Invoke-Command -ScriptBlock $ScriptBlock
		}
		catch
		{
			$ErrorDetails = @"

User:
$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

Error Details:
$($Error[0])

SQL Query:
$Query
"@
			Write-Warning "Encountered exception while running SQL Query: $ErrorDetails"
			
			[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")
			[Microsoft.VisualBasic.Interaction]::MsgBox(@"
Event ID:
10

User:
$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

Error Details:
$($Error[0])

For more details see the Application Event Log.
"@, "OKOnly,SystemModal,Critical,DefaultButton2", "Encountered exception while attempting to run SQL Query") | Out-Null
		}
		$command.Parameters.Clear()
	}
	
	end
	{
		if ($createConnection) { $Connection.Close() }
		
		$result
	}
}
