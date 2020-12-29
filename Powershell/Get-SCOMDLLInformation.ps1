function Invoke-SQL
{
       param (
              [string]$SQLServer = "SQL",
              #Default SQL Server name\instance

              [string]$DatabaseName = "OperationsManager",
              #Default OperationsManager DB name
              
              [string]$TSQLquery = $(throw "Please specify a query."),
              #Default SQL Command

              [string]$OutputPath = 'C:\Windows\Temp\'
              #Default Output Path
       )
       
       $connectionString = "Data Source=$SQLServer; " +
       "Integrated Security=SSPI; " +
       "Initial Catalog=$DatabaseName"
       
       $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
       $command = new-object system.data.sqlclient.sqlcommand($TSQLquery, $connection)
       $connection.Open()
       
       $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
       $dataset = New-Object System.Data.DataSet
       $adapter.Fill($dataSet) | Out-Null
       
       $connection.Close()
       $dataSet.Tables
       
       $filename = $dataSet.Tables.Rows.FileName
       $binData = $dataSet.Tables.Rows.ResourceValue
       #sleep -Seconds 60 #wait for the reader to get all the data      
       [io.file]::WriteAllBytes($OutputPath + $FileName, $binData)
}
#The Below Expects a single result, take this into account 
#Invoke-SQL -sqlCommand "select ResourceValue, FileName from Resource where ResourceId ='B456473C-DA04-E8A0-A5F6-1D54DF95557A'" #By ResourceID 
#Invoke-SQL -SQLServer SQL -DatabaseName OperationsManager -OutputPath "C:\Windows\Temp\" -TSQLquery "select ResourceValue, FileName from Resource where resourcename like '%OperationsManager.APM%Common%'" #By ResourceName 