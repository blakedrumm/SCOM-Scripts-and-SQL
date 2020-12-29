<#
.SYNOPSIS
    Performs a SQL query and returns an array of PSObjects.
.NOTES
    Author: Jourdan Templeton - hello@jourdant.me
.LINK 
    https://blog.jourdant.me/post/simple-sql-in-powershell
#>
function Invoke-SqlCommand() {
    [cmdletbinding(DefaultParameterSetName="integrated")]Param (
        [Parameter(Mandatory=$true)][Alias("Serverinstance")][string]$Server,
        [Parameter(Mandatory=$true)][string]$Database,
        [Parameter(Mandatory=$true, ParameterSetName="not_integrated")][string]$Username,
        [Parameter(Mandatory=$true, ParameterSetName="not_integrated")][string]$Password,
        [Parameter(Mandatory=$false, ParameterSetName="integrated")][switch]$UseWindowsAuthentication = $true,
        [Parameter(Mandatory=$true)][string]$Query,
        [Parameter(Mandatory=$false)][int]$CommandTimeout=0
    )
    
    #build connection string
    $connstring = "Server=$Server; Database=$Database; "
    If ($PSCmdlet.ParameterSetName -eq "not_integrated") { $connstring += "User ID=$username; Password=$password;" }
    ElseIf ($PSCmdlet.ParameterSetName -eq "integrated") { $connstring += "Trusted_Connection=Yes; Integrated Security=SSPI;" }
    
    #connect to database
    $connection = New-Object System.Data.SqlClient.SqlConnection($connstring)
    $connection.Open()
    
    #build query object
    $command = $connection.CreateCommand()
    $command.CommandText = $Query
    $command.CommandTimeout = $CommandTimeout
    
    #run query
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataset) | out-null
    
    #return the first collection of results or an empty array
    If ($dataset.Tables[0] -ne $null) {$table = $dataset.Tables[0]}
    ElseIf ($table.Rows.Count -eq 0) { $table = New-Object System.Collections.ArrayList }
    
    $connection.Close()
    return $table
}
$ServerName = 'SQL1,10433'
$DBName = 'OperationsManager'
$ResourcePoolName = 'Linux' # This can contain part of the string for the Resource Pool Name.
$query = "select BaseManagedEntity.DisplayName ,cs.agent.AgentGuid ,cs.WorkFlowExecutionLocationAgent.AgentRowId ,cs.workflowexecutionlocation.WorkflowExecutionLocationRowId ,cs.workflowexecutionlocation.DisplayName from cs.WorkFlowExecutionLocationAgent inner join cs.workflowexecutionlocation ON cs.WorkFlowExecutionLocationAgent.WorkFlowExecutionLocationAgentRowId = cs.workflowexecutionlocation.WorkflowExecutionLocationRowId inner join CS.agent ON CS.agent.AgentRowId=cs.WorkFlowExecutionLocationAgent.AgentRowId inner join BaseManagedEntity ON BaseManagedEntity.BaseManagedEntityId = CS.agent.AGentGuid where cs.workflowexecutionlocation.DisplayName like '%$ResourcePoolName%'"
Invoke-SqlCommand -UseWindowsAuthentication -Server "SQL1,10433" -Database $DBName -Query $query