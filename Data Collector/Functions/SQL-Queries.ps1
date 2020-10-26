Function SQL-Queries
{
	## strip fqdn etc...
	If ($OpsDB_SQLServerOriginal -like "*,*")
	{
		$global:OpsDB_SQLServer = $OpsDB_SQLServerOriginal.split(',')[0]
		$global:OpsDB_SQLServerPort = $OpsDB_SQLServerOriginal.split(',')[1]
	}
	If ($DW_SQLServerOriginal -like "*,*")
	{
		$global:DW_SQLServer = $DW_SQLServerOriginal.split(',')[0]
		$global:DW_SQLServerPort = $DW_SQLServerOriginal.split(',')[1]
	}
	
	## strip fqdn etc...
	If ($OpsDB_SQLServerOriginal -like "*\*")
	{
		$global:OpsDB_SQLServer = $OpsDB_SQLServerOriginal.split('\')[0]
		$global:OpsDB_SQLServerInstance = $OpsDB_SQLServerOriginal.split('\')[1]
	}
	If ($DW_SQLServerOriginal -like "*\*")
	{
		$global:DW_SQLServer = $DW_SQLServerOriginal.split('\')[0]
		$global:DW_SQLServerInstance = $DW_SQLServerOriginal.split('\')[1]
	}
	
	$Populated = 1
	
	## Verify variables are populated
	If ($OpsDB_SQLServer -eq $null)
	{
		write-output "OpsDBServer not found"
		$populated = 0
	}
	If ($DW_SQLServer -eq $null)
	{
		write-output "DataWarehouse server not found"
		$populated = 0
	}
	If ($OpsDB_SQLDBName -eq $null)
	{
		write-output "OpsDBName Not found"
		$populated = 0
	}
	If ($DW_SQLDBName -eq $null)
	{
		write-output "DWDBName not found"
		$populated = 0
	}
	
	if ($Populated = 0)
	{
		"At least some SQL Information not found, exiting script..."
    <# 
        insert Holman's method from the original script here, then remove the break found below
    #>
		break
	}
	
	## Hate this output. Want to change it, will eventually, doesnt pose a problem functionally though 
	## so thats a task for a later date. Want a table, not a list like that. 
	## Combine the objects into a single object and display via table.
	$color = "Cyan"
	Write-Output " "
	Write-Host "OpsDB Server        : $OpsDB_SQLServer" -ForegroundColor $color -NoNewline
	if ($OpsDB_SQLServerInstance)
	{
		Write-Host "\$OpsDB_SQLServerInstance" -ForegroundColor $color -NoNewline
	}
	if ($OpsDB_SQLServerPort)
	{
		Write-Host "`nOpsDB Server Port   : $OpsDB_SQLServerPort" -ForegroundColor $color -NoNewline
	}
	Write-Host "`nOpsDB Name          : $OpsDB_SQLDBName" -ForegroundColor $color
	Write-Output " "
	Write-Host "DWDB Server         : $DW_SQLServer" -ForegroundColor $color -NoNewline
	if ($DW_SQLServerInstance)
	{
		Write-Host "\$DW_SQLServerInstance" -ForegroundColor $color -NoNewline
	}
	if ($DW_SQLServerPort)
	{
		Write-Host "`nDWDB Server Port    : $DW_SQLServerPort" -ForegroundColor $color -NoNewline
	}
	Write-Host "`nDWDB Name           : $DW_SQLDBName" -ForegroundColor $color
	Write-Output " "
	if (!$AssumeYes)
	{
		do
		{
			
			$answer = Read-Host -Prompt "Do you want to continue with these values? (Y/N)"
			
		}
		until ($answer -eq "y" -or $answer -eq "n")
	}
	else { $answer = "y" }
	IF ($answer -eq "y")
	{
		Write-Host "Connecting to SQL Server...." -ForegroundColor DarkGreen
	}
	ELSE
	{
		do
		{
			
			$answer = Read-Host -Prompt "Do you want to attempt to continue without Queries to your SQL Server? (Y/N)"
			
		}
		until ($answer -eq "y" -or $answer -eq "n")
		if ($answer -eq "n")
		{
			Write-Warning "Exiting script...."
			exit
		}
		Write-Warning "Be aware, this has not been implemented yet..."
	}
	# Query the OpsDB Database
	$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	[string]$currentuser = ([Environment]::UserDomainName + "\" + [Environment]::UserName)
	if (!$AssumeYes)
	{
		Write-Host "Currently Detecting User as: $currentuser"
		do
		{
			$answer2 = Read-Host -Prompt " Does the above user have the correct permissions to perform SQL Queries against $OpsDB_SQLServer`? (Y/N)"
		}
		until ($answer2 -eq "y" -or $answer2 -eq "n")
	}
	else { $answer2 = "y" }
	if ($answer2 -eq "n")
	{
		do
		{
			$answer3 = Read-Host -Prompt "  Are you setup for `'SQL Credentials`' or `'Domain Credentials`' on $OpsDB_SQLServer`? (SQL/Domain)"
		}
		until ($answer3 -eq "SQL" -or $answer3 -eq "Domain")
		$SQLuser = Read-Host '   What is your username?'
		$SQLpass = Read-Host '   What is your password?' -AsSecureString
		do
		{
			$proceed = Read-Host "    Would you like to proceed with $SQLuser`? (Y/N)"
			if ($proceed -eq "n")
			{
				$SQLuser = $null
				$SQLuser = Read-Host '   What is your username?'
				$SQLpass = Read-Host '   What is your password?' -AsSecureString
			}
		}
		until ($proceed -eq "y")
	}
	else
	{ $answer2 = "y" }
	if ($answer2 -eq "y")
	{
		$SqlConnection.ConnectionString = "Server=$OpsDB_SQLServerOriginal;Database=$OpsDB_SQLDBName;Integrated Security=True"
	}
	elseif ($answer3 -eq "Domain")
	{
		$SqlConnection.ConnectionString = "Server=$OpsDB_SQLServerOriginal;user id=$SQLuser;password=$SQLpass;Database=$OpsDB_SQLDBName;Integrated Security=True"
	}
	elseif ($answer3 -eq "SQL")
	{
		$SqlConnection.ConnectionString = "Server=$OpsDB_SQLServerOriginal;user id=$SQLuser;password=$SQLpass;Database=$OpsDB_SQLDBName"
	}
	$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$SqlCmd.Connection = $SqlConnection
	# Below is how long we will wait before terminating an indivdual query
	$SqlCmd.CommandTimeout = 30
	IF (!(Test-Path $OutputPath))
	{
		Write-Host "Output folder not found.  Creating folder...." -ForegroundColor Gray
		md $OutputPath | out-null
		md $OutputPath\CSV | out-null
	}
	else
	{
		Write-Host "Output folder found. Removing Existing Files...." -ForegroundColor Gray
		rmdir -Path $OutputPath -Recurse | Out-Null
		Write-Host "Creating folder...." -ForegroundColor Gray
		md $OutputPath | out-null
		md $OutputPath\CSV | out-null
	}
	if ($GenerateHTML)
	{
		if (!(Test-Path "$OutputPath\HTML Report"))
		{
			mkdir "$OutputPath\HTML Report" | Out-Null
		}
		else
		{
			rmdir "$OutputPath\HTML Report" -Force | Out-Null
			mkdir "$OutputPath\HTML Report" | Out-Null
		}
	}
	$QueriesPath = "$ScriptPath\queries\OpsDB"
	IF (!(Test-Path $QueriesPath))
	{
		Write-Warning "Path to query files not found ($QueriesPath).  Terminating...."
		break
	}
	Write-Host "`n================================"
	Write-Host "Starting SQL Query Gathering"
	Write-Host "Running SQL Queries against Operations Database"
	Write-Host " Looking for query files in: $QueriesPath" -ForegroundColor DarkGray
	$QueryFiles = Get-ChildItem $QueriesPath | where { $_.Extension -eq ".sql" }
	$QueryFilesCount = $QueryFiles.Count
	Write-Host "  Found ($QueryFilesCount) queries" -ForegroundColor Green
	FOREACH ($QueryFile in $QueryFiles)
	{
		try
		{
			$Error.Clear()
			$QueryFileName = $QueryFile.Name
			Write-Host "    Running query: " -ForegroundColor Cyan -NoNewline
			Write-Host "$QueryFileName" -ForegroundColor Magenta
			$QueryFileName = $QueryFileName.split('.')[0]
			$OutputFileName = $OutputPath + "\" + $QueryFileName + ".csv"
			[string]$SqlQuery = Get-Content $QueriesPath\$QueryFile -Raw
			$SqlCmd.CommandText = $SqlQuery
			$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
			$SqlAdapter.SelectCommand = $SqlCmd
			$ds = New-Object System.Data.DataSet
			$SqlAdapter.Fill($ds) | Out-Null
			#write-output "Writing output file" $OutputFileName
			# Check for errors connecting to SQL
			IF ($Error)
			{
				Write-Host "      Error running SQL query: $QueryFileName
" -ForegroundColor Red
				$Error | Export-Csv $OutputFileName -NoTypeInformation
			}
			ELSE
			{
				$ds.Tables[0] | Export-Csv $OutputFileName -NoTypeInformation
			}
		}
		catch
		{
			Write-Host "      Error running SQL query: $QueryFileName
$_
" -ForegroundColor Red
			$_ | Export-Csv $OutputFileName -NoTypeInformation
		}
		
	}
	$SqlConnection.Close()
	# Query the DW database
	$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
		if (!$AssumeYes)
		{
			Write-Host "Currently Detecting User as: $currentuser"
			do
			{
				$answer4 = Read-Host -Prompt " Does the above user have the correct permissions to perform SQL Queries against $DW_SQLServer`? (Y/N)"
			}
			until ($answer4 -eq "y" -or $answer4 -eq "n")
		}
		else { $answer4 = "y" }
		if ($answer4 -eq "n")
		{
			do
			{
				$answer5 = Read-Host -Prompt "  Are you setup for `'SQL Credentials`' or `'Domain Credentials`' on $DW_SQLServer`? (SQL/Domain)"
			}
			until ($answer5 -eq "SQL" -or $answer5 -eq "Domain")
			$SQLuser2 = Read-Host '    What is your username?'
			$SQLpass2 = Read-Host '    What is your password?' -AsSecureString
			do
			{
				$proceed2 = Read-Host "   Would you like to proceed with $SQLuser2`? (Y/N)"
				if ($proceed2 -eq "n")
				{
					$SQLuser2 = $null
					$SQLuser2 = Read-Host '    What is your username?'
					$SQLpass2 = Read-Host '    What is your password?' -AsSecureString
				}
			}
			until ($proceed2 -eq "y")
		}
	
	if ($answer4 -eq "y")
	{
		$SqlConnection.ConnectionString = "Server=$DW_SQLServerOriginal;Database=$DW_SQLDBName;Integrated Security=True"
	}
	elseif ($answer5 -eq "Domain")
	{
		$SqlConnection.ConnectionString = "Server=$DW_SQLServerOriginal;user id=$SQLuser2;password=$SQLpass2;Database=$DW_SQLDBName;Integrated Security=True"
	}
	elseif ($answer5 -eq "SQL")
	{
		$SqlConnection.ConnectionString = "Server=$DW_SQLServerOriginal;user id=$SQLuser2;password=$SQLpass2;Database=$DW_SQLDBName"
	}
	$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$SqlCmd.Connection = $SqlConnection
	# Below is how long we will wait before terminating an individual query
	$SqlCmd.CommandTimeout = 30
	$QueriesPath = "$ScriptPath\queries\DW"
	IF (!(Test-Path $QueriesPath))
	{
		Write-Error "Path to query files not found ($QueriesPath).  Terminating...."
		break
	}
	Write-Host "`n================================"
	Write-Host "Running SQL Queries against Data Warehouse"
	Write-Host " Gathering query files located here: $QueriesPath" -ForegroundColor DarkGray
	$QueryFiles = Get-ChildItem $QueriesPath | where { $_.Extension -eq ".sql" }
	$QueryFilesCount = $QueryFiles.Count
	Write-Host "  Found ($QueryFilesCount) queries" -ForegroundColor Green
	FOREACH ($QueryFile in $QueryFiles)
	{
		try
		{
			$Error.Clear()
			$QueryFileName = $QueryFile.Name
			Write-Host "    Running query: " -ForegroundColor Cyan -NoNewline
			Write-Host "$QueryFileName" -ForegroundColor Magenta
			$QueryFileName = $QueryFileName.split('.')[0]
			$OutputFileName = $OutputPath + "\" + $QueryFileName + ".csv"
			[string]$SqlQuery = Get-Content $QueriesPath\$QueryFile
			$SqlCmd.CommandText = $SqlQuery
			$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
			$SqlAdapter.SelectCommand = $SqlCmd
			$ds = New-Object System.Data.DataSet
			$SqlAdapter.Fill($ds) | Out-Null
			#write-output "Writing output file" $OutputFileName
			# Check for errors connecting to SQL
			IF ($Error)
			{
				Write-Host "      Error running SQL query: $QueryFileName`n" -ForegroundColor Red
				$Error | Export-Csv $OutputFileName -NoTypeInformation
			}
			ELSE
			{
				$ds.Tables[0] | Export-Csv $OutputFileName -NoTypeInformation
			}
		}
		catch
		{
			Write-Host "      Error running SQL query: $QueryFileName
$_
" -ForegroundColor Red
			$_ | Export-Csv $OutputFileName -NoTypeInformation
		}
	}
	$SqlConnection.Close()
}