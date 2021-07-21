<#
.AUTHOR
        Blake Drumm (blakedrumm@microsoft.com)
 Examples
  .\Start-SCOMDiscovery.ps1 -AgentServer MS1-2019 -DiscoveryDisplayName *Windows*, *Warehouse* -Wait
  .\Start-SCOMDiscovery.ps1 -AgentServer IIS-2019 -DiscoveryId d7a25f74-a82b-7977-3a8b-19ae527c86fc -Wait
  .\Start-SCOMDiscovery.ps1 -AgentServer SQL-2019 -DiscoveryName Microsoft.SQLServer.Windows.Discovery.DBFilegroup -OutputFile $ENV:USERPROFILE`\Desktop\Output.txt -Wait
  
  Created: January 1st, 2021
  Modified: July 20th, 2021
#>
param
(
	[Parameter(Mandatory = $false,
			   Position = 1)]
	[String]$AgentServer,
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
	[Int]$Wait,
	[Parameter(Mandatory = $false,
			   Position = 6)]
	[String]$OutputFile
)

function Start-SCOMDiscovery
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $false,
				   Position = 1)]
		[String]$AgentServer,
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
		[Int]$Wait = 10,
		[Parameter(Mandatory = $false,
				   Position = 6)]
		[String]$OutputFile
	)
	
	try
	{
		if (!$AgentServer)
		{
			$AgentServer = $env:COMPUTERNAME
		}
		Import-Module OperationsManager
		if ($OutputFile)
		{
			'Gathering Discoveries' | Out-File -FilePath $OutputFile
		}
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
		else
		{
			return Write-Host "Missing the Display Name of the Discovery. (ex. Azure SQL*). Run this script like this:`n.\Start-SCOMDiscovery.ps1 -DisplayName 'Azure SQL*'" -ForegroundColor Red
		}
		if ($OutputFile)
		{
			'Starting Discoveries (Count: ' + $Discoveries.Count + ')' | Out-File -Append -FilePath $OutputFile
		}
		'Starting Discoveries (Count: ' + $Discoveries.Count + ')' | Write-Host
		$i = 0
		foreach ($Discov in $Discoveries)
		{
			$i = $i
			$i++
			if ($OutputFile)
			{
				'(' + $i + '/' + $Discoveries.Count + ') -----------------------------------------------------------------' | Out-File -Append -FilePath $OutputFile
				' ' | Out-File -Append -FilePath $OutputFile
			}
			'(' | Write-Host -NoNewline
			$i | Write-Host -NoNewline -ForegroundColor DarkYellow
			'/' | Write-Host -NoNewline
			$Discoveries.Count | Write-Host -NoNewline -ForegroundColor Gray
			') ' | Write-Host -NoNewline
			'-----------------------------------------------------------------' | Write-Host -ForegroundColor DarkYellow
			' ' | Write-Host
			
			$TargetInstanceId = (Get-SCOMClass -Id $Discov.Target.Id | Get-SCOMClassInstance | ? { $_.DisplayName -like "`*$AgentServer`*" }).Id.Guid
			#Do not edit the below.
			$Instance = Get-SCOMClass -Name $($task.Target.Identifier.Path) | Get-SCOMClassInstance | ? { $_.DisplayName -like "`*$AgentServer`*" }
			
			"Discovery Display Name: $($Discov.DisplayName)"
			"TargetInstanceID: $($TargetInstanceId)"
			"Target: $($Discov.Target.Identifier.Path)"
			"Instance: $($Instance)"
			"Task Target: $($task.Target.Identifier.Path)"
			
			try
			{
				$Override = @{ DiscoveryId = $Discov.Id.ToString(); TargetInstanceId = $TargetInstanceId.ToString() }
				$CurrentTaskOutput = (Start-SCOMTask -Task $Task -Instance $Instance -Override $Override | Select-Object Status, @{ Name = "Discovery Name"; Expression = { $Discov.Name } }, @{ Name = "Discovery Guid"; Expression = { $Discov.Id } }, @{ Name = "TaskGuid"; Expression = { $_.Id } }, TimeScheduled, TimeStarted, TimeFinished, Output)
			}
			catch { continue }
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
			$currentoutput = ($CurrentTaskOutput | Out-String -Width 4096).trim()
			if ($OutputFile)
			{
				$currentoutput | Out-File -Append -FilePath $OutputFile
			}
			$currentoutput
			$taskresult = $null
			$randomnumber = Get-Random -Minimum 1 -Maximum 4
			if ($Wait)
			{
				do { $taskResultOriginal = Get-SCOMTaskResult -Id $CurrentTaskOutput.TaskGuid[0]; Sleep $wait }
				until (($taskResultOriginal.Status -eq 'Succeeded' -or 'Failed') -and ($taskResultOriginal.Status -ne 'Started') -and ($taskResultOriginal.Status -ne 'Scheduled'))
				<# Task Result
				TaskId               : ff34dc4f-2db3-1736-d9f2-6d85b539ff96
				BatchId              : e2689785-a3a0-41b6-a2b2-a66063d65810
				SubmittedBy          : Contoso\Administrator
				RunningAs            :
				TargetObjectId       : 67283979-caa5-86df-e8d1-bfb5876502dc
				TargetClassId        : ab4c891f-3359-3fb6-0704-075fbfe36710
				LocationId           : 67283979-caa5-86df-e8d1-bfb5876502dc
				Status               : Succeeded
				Output               : <DataItem type="System.OnDemandDiscoveryResponse" time="2021-01-05T20:10:36.5610229-05:00" sourceHealthServiceId="67283979-CAA5-86DF-E8D1-BFB5876502DC"><Result>DISCOVERY_NOT_FOUND</Result><Timestamp></Timestamp></DataItem>
				ErrorCode            : 0
				ErrorMessage         :
				TimeScheduled        : 1/6/2021 1:10:36 AM
				TimeStarted          : 1/6/2021 1:10:36 AM
				TimeFinished         : 1/6/2021 1:10:42 AM
				LastModified         : 1/6/2021 1:10:42 AM
				ProgressValue        :
				ProgressMessage      :
				ProgressData         :
				ProgressLastModified :
				StatusLastModified   : 1/6/2021 1:10:42 AM
				Id                   : 9aa63a07-e8e6-42bf-bf20-d5fb7a4d9c8d
				ManagementGroup      : ManagementGroup1
				ManagementGroupId    : e37e57e1-7d7b-79cc-6cdf-95cb3750eaaf
				#>
				$taskResult = $taskResultOriginal | Select-Object Status, @{ Name = "Discovery Display Name"; Expression = { $Discov.DisplayName } }, @{ Name = "Discovery Name"; Expression = { $Discov.Name } }, TimeFinished, Output; Sleep $randomnumber
				' ' | Write-Host
				if ($OutputFile)
				{
					' ' | Out-File -Append -FilePath $OutputFile
				}
				try
				{
					if ($taskResultOriginal.TimeStarted)
					{
						$Timediff = New-TimeSpan -Start $taskResultOriginal.TimeStarted -End $taskResultOriginal.TimeFinished
					}
					else
					{
						$Timediff = New-TimeSpan -Start $taskResultOriginal.TimeScheduled -End $taskResultOriginal.TimeFinished
					}
				}catch{ $Timediff = "Unknown Amount of"}
				if ($OutputFile)
				{
					$Discov.DisplayName + ' took ' + $Timediff.Seconds + ' seconds.' | Out-File -Append -FilePath $OutputFile
					' ' | Out-File -Append -FilePath $OutputFile
				}
				$Discov.DisplayName + ' took ' + $Timediff.Seconds + ' seconds.' | Write-Host -ForegroundColor Yellow
				Write-Host ' '
				$taskresult = ($taskResult | Out-String -Width 4096).trim()
				if ($OutputFile)
				{
					$taskresult | Out-File -Append -FilePath $OutputFile
					' ' | Out-File -Append -FilePath $OutputFile
				}
				$taskResult
				Write-Host ' '
				
			}
			Start-Sleep -Seconds $randomnumber
		}
	}
	catch
	{
		if ($OutputFile)
		{
			$_.Exception | Out-File -Append -FilePath $OutputFile
			"Unable to trigger the discovery" | Out-File -Append -FilePath $OutputFile
		}
		Write-Host $_.Exception
		Write-Host "Unable to trigger the discovery" -ForegroundColor Red
	}
}
if ($AgentServer -or $DiscoveryDisplayName -or $DiscoveryName -or $Wait -or $DiscoveryId -or $OutputFile)
{
	Start-SCOMDiscovery -AgentServer $AgentServer -DiscoveryDisplayName $DiscoveryDisplayName -DiscoveryName $DiscoveryName -DiscoveryId $DiscoveryId -Wait $Wait -OutputFile $OutputFile
}
else
{
	#Enter the Discovery you want to run here.
	# ex. Start-SCOMDiscovery -DiscoveryDisplayName '*Windows*' -AgentServer IIS-2019
	Start-SCOMDiscovery
}
