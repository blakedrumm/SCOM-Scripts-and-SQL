param
(
	[Parameter(Mandatory = $false,
			   Position = 1)]
	[String]$ManagementServer,
	[Parameter(Mandatory = $false,
			   Position = 2)]
	[String]$DiscoveryDisplayName,
	[Parameter(Mandatory = $false,
			   Position = 3)]
	[String[]]$DiscoveryName,
	[Parameter(Mandatory = $false,
			   Position = 4)]
	[String]$DiscoveryId,
	[Parameter(Mandatory = $false,
			   Position = 5)]
	[Switch]$Wait
)
function Start-SCOMDiscovery
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $false,
				   Position = 1)]
		[String]$ManagementServer,
		[Parameter(Mandatory = $false,
				   Position = 2)]
		[String]$DiscoveryDisplayName,
		[Parameter(Mandatory = $false,
				   Position = 3)]
		[String[]]$DiscoveryName,
		[Parameter(Mandatory = $false,
				   Position = 4)]
		[String]$DiscoveryId,
		[Parameter(Mandatory = $false,
				   Position = 5)]
		[Switch]$Wait
	)
	try
	{
		if (!$ManagementServer)
		{
			$ManagementServer = $env:COMPUTERNAME
		}
<#
		if ((!$DiscoveryDisplayName) -or (!$DiscoveryName) -or (!$DiscoveryId))
		{
			return Write-Host "Missing the Display Name of the Discovery. (ex. Azure SQL*). Run this script like this:`n.\Start-SCOMDiscovery.ps1 -Discovery 'Azure SQL*'" -ForegroundColor Red
		}
#>
		$requestParams = @{ header = 'value' }
		
		$PSBoundParameters.GetEnumerator() | ForEach-Object {
			$value = $_.Value
			if ($value -is [switch])
			{
				$value = $value.IsPresent
			}
			
			$requestParams[$_.Key] = $value
		}
		Import-Module OperationsManager
		'Gathering Discoveries' | Write-Host
		$Task = Get-SCOMTask -Name Microsoft.SystemCenter.TriggerOnDemandDiscovery
		if ($DiscoveryDisplayName)
		{
			$Discoveries = Get-SCOMDiscovery -DisplayName $DiscoveryDisplayName
		}
		elseif ($DiscoveryName)
		{
			$Discoveries = Get-SCOMDiscovery -Name $DiscoveryName
		}
		elseif ($DiscoveryId)
		{
			$Discoveries = Get-SCOMDiscovery -Id $DiscoveryId
		}
		'Starting Discoveries (Count: ' + $Discoveries.Count + ')' | Write-Host
		$i = 0
		foreach ($Discov in $Discoveries)
		{
			$i = $i
			$i++
			'(' + $i + '/' + $Discoveries.Count + ') ---------------------------------------' | Write-Host
			$output = @()
			$Override = @{ DiscoveryId = $Discov.Id.ToString(); TargetInstanceId = $Discov.Target.Id.ToString() }
			$Instance = Get-SCOMClass -Name Microsoft.SystemCenter.ManagementServer | Get-SCOMClassInstance | where { $_.Displayname -like "$ManagementServer`*" }
			$CurrentTaskOutput = (Start-SCOMTask -Task $Task -Instance $Instance -Override $Override | Select-Object Status, @{ Name = "Discovery Display Name"; Expression = { $Discov.DisplayName } }, @{ Name = "Discovery Name"; Expression = { $Discov.Name } }, @{ Name = "Discovery Guid"; Expression = { $Discov.Id } }, @{ Name = "Guid"; Expression = { $_.Id } }, TimeScheduled, TimeStarted, TimeFinished, Output)
			
            <#
TaskId               : ff34dc4f-2db3-1736-d9f2-6d85b539ff96
BatchId              : 3a33f6f7-d2df-4fcb-9fed-736b92230d6a
SubmittedBy          : Contoso\Administrator
RunningAs            : 
TargetObjectId       : 67283979-caa5-86df-e8d1-bfb5876502dc
TargetClassId        : ab4c891f-3359-3fb6-0704-075fbfe36710
LocationId           : 67283979-caa5-86df-e8d1-bfb5876502dc
Status               : Started
Output               : 
ErrorCode            : 
ErrorMessage         : 
TimeScheduled        : 1/2/2021 5:18:34 AM
TimeStarted          : 1/2/2021 5:18:35 AM
TimeFinished         : 
LastModified         : 1/2/2021 5:18:35 AM
ProgressValue        : 
ProgressMessage      : 
ProgressData         : 
ProgressLastModified : 
StatusLastModified   : 1/2/2021 5:18:35 AM
Id                   : 9f49609c-2152-43ae-acde-97f1c9f9e4e0
ManagementGroup      : ManagementGroup1
ManagementGroupId    : e37e57e1-7d7b-79cc-6cdf-95cb3750eaaf

#>
			$output += $CurrentTaskOutput | Out-String -Width 4096
			$output
			$taskresult = $null
			$randomnumber = Get-Random -Minimum 1 -Maximum 4
			if ($Wait)
			{
				do { $taskResult = Get-SCOMTaskResult -Id $CurrentTaskOutput.Guid | Select-Object Status, @{ Name = "Discovery Display Name"; Expression = { $Discov.DisplayName } }, @{ Name = "Discovery Name"; Expression = { $Discov.Name } }, TimeFinished, Output; Sleep $randomnumber }
				until (($taskResult.Status -eq 'Succeeded' -or 'Failed') -and ($taskResult.Status -ne 'Started'))
				$taskResult
				$Timediff = New-TimeSpan -Start $CurrentTaskOutput.TimeStarted -End $taskResult.TimeFinished
				
				$Discov.DisplayName + ' took ' + $Timediff.Seconds + ' seconds.' | Write-Host -ForegroundColor Yellow
				Write-Host ' '
			}
			Start-Sleep -Seconds $randomnumber
		}
	}
	catch
	{
		Write-Host $_.Exception
		Write-Host "Unable to trigger the discovery" -ForegroundColor Red
	}
}
if ($ManagementServer -or $DiscoveryDisplayName -or $DiscoveryName -or $Wait -or $DiscoveryId)
{
	Start-SCOMDiscovery -ManagementServer $ManagementServer -DiscoveryDisplayName $DiscoveryDisplayName -DiscoveryName $DiscoveryName -DiscoveryId $DiscoveryId -Wait:$Wait
}
else
{
	#Enter the Discovery you want to run here.
	# ex. Start-SCOMDiscovery -Discovery 'Azure SQL*'
	Start-SCOMDiscovery
}
