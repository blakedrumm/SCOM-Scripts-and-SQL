# THIS SCRIPT CAN BE DANGEROUS, MAKE BACKUPS OF YOUR OPSDB AND DW! OR RUN WITH THE '-PauseOnEach' PARAMETER TO BE SAFE

# PowerShell script to automatically remove an MP and its dependencies.
#
# Original Author	:     	Christopher Crammond, Chandra Bose
# Modified By	 	:     	Blake Drumm (blakedrumm@microsoft.com)
# Date Created	 	:	April 24th, 2012
# Date Modified		: 	July 19th, 2021
#
# Version		:       2.0.7
#
# Arguments		: 	ManagementPackName.  (Provide the value of the management pack name or id from the management pack properties.  Otherwise, the script will fail.)

<# 
Change Log
----------
August 19th, 2021:
	Added ability to remove XML Reference from Unsealed Management Packs
	
July 19th, 2022:
	Attempted to fix some issues with processing MP Elements
#>

# Example:
# .\Remove-MPDependencies -ManagementPackName "*APM*"
#
# .\Remove-MPDependencies.ps1 -ManagementPackName Microsoft.Azure.ManagedInstance.Discovery
#
# Get-SCOMManagementPack -DisplayName "Microsoft Azure SQL Managed Instance (Discovery)" | .\Remove-MPDependencies.ps1 -DryRun -PauseOnEach
#
# Get-SCOMManagementPack -DisplayName "Microsoft Azure SQL Managed Instance (Discovery)" | .\Remove-MPDependencies.ps1

# Needed for SCOM SDK
param
(
	[Parameter(ValueFromPipeline = $true,
			   Position = 0,
			   HelpMessage = 'ex: Microsoft.Azure.ManagedInstance.Discovery')]
	[string]$ManagementPackName,
	[Parameter(Position = 1)]
	[string]$ManagementPackId,
	[Parameter(Position = 2,
			   HelpMessage = 'This will allow you to pause between each Mangement Pack Dependency removal.')]
	[switch]$PauseOnEach,
	[Parameter(Position = 3,
			   HelpMessage = 'This will let you see how it would execute, without making any changes to your environment.')]
	[switch]$DryRun,
	[Parameter(Position = 4)]
	[string]$ExportPath
)

function Remove-MPDependencies
{
	param
	(
		[Parameter(ValueFromPipeline = $true,
				   Position = 0,
				   HelpMessage = 'ex: Microsoft.Azure.ManagedInstance.Discovery')]
		[string]$ManagementPackName,
		[Parameter(Position = 1)]
		[string]$ManagementPackId,
		[Parameter(Position = 2,
				   HelpMessage = 'This will allow you to pause between each Mangement Pack Dependency removal.')]
		[switch]$PauseOnEach,
		[Parameter(Position = 3,
				   HelpMessage = 'This will let you see how it would execute, without making any changes to your environment.')]
		[switch]$DryRun,
		[Parameter(Position = 4)]
		[string]$ExportPath
	)
	$firstArgName = $null
	if (!$ExportPath)
	{
		$ExportPath = $env:TEMP
	}
	if (!(Test-Path $ExportPath))
	{
		New-Item -ItemType Directory -Path $ExportPath | Out-Null
	}
	if (!$ManagementPackName -and !$ManagementPackId)
	{
		Write-Host "-ManagementPackName or -ManagementPackId is required!" -ForegroundColor Red
		set-location $cwd
		break
	}
	if ($ManagementPackName -contains "*")
	{
		$ManagementPackName = Get-SCManagementPack -Name $ManagementPackName | Select-First 1
	}
	$ipProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
	$rootMS = "{0}.{1}" -f $ipProperties.HostName, $ipProperties.DomainName
	
	
	#######################################################################
	#
	# Helper method that will remove the list of given Management Packs.
	#
	function RemoveMPsHelper
	{
		param ($mpList)
		foreach ($mp in $mpList)
		{
			$id = $null
			$recursiveListOfManagementPacksToRemove = Get-SCOMManagementPack -Name $mp.Name -Recurse
			if ($recursiveListOfManagementPacksToRemove.Count -gt 1)
			{
				Write-Output "`r`n"
				Write-Host "The following dependent management packs have to be deleted, before deleting " -NoNewline
				Write-Host $($mp.Name) -ForegroundColor Cyan
				
				#$recursiveListOfManagementPacksToRemove | format-table name, Sealed
				RemoveMPsHelper $recursiveListOfManagementPacksToRemove
			}
			else
			{
				$mpPresent = Get-ManagementPack -Name $mp.Name
				$Error.Clear()
				if ($mpPresent -eq $null)
				{
					# If the MP wasn't found, we skip the uninstallation of it.
					Write-Host "    $mp has already been uninstalled"
				}
				else
				{
					if ($DryRun)
					{
						Write-Host "    * NOT Uninstalling " -NoNewLine -ForegroundColor Gray
						Write-Host $($mp.Name) -ForegroundColor Cyan
						Write-Host "         Cannot continue, as this script relies on realtime data to go through each Management Pack." -ForegroundColor Gray
						break
					}
					elseif ($mpPresent.Sealed -eq $false)
					{
						foreach ($arg in $firstArgName)
						{
							Write-Host "    * Removing " -NoNewline
							Write-Host $arg -ForegroundColor Green -NoNewline
							Write-Host " reference from " -NoNewLine
							Write-Host $($mp.Name) -ForegroundColor Cyan
							try
							{
								[array]$removed = $null
								[array]$alias = $null
								$mpPresent | Export-SCOMManagementPack -Path $ExportPath -PassThru -ErrorAction Stop | Out-Null
								$xmldata = [xml](Get-Content "$ExportPath`\$($mpPresent.Name).xml" -ErrorAction Stop);
								Write-Host "      * Backing up to:" -ForegroundColor Green -NoNewline
								Write-Host "$ExportPath`\$($mpPresent.Name).backup.xml" -ForegroundColor Cyan
								$xmlData.Save("$ExportPath`\$($mpPresent.Name).backup.xml")
								[version]$mpversion = $xmldata.ManagementPack.Manifest.Identity.Version
								$xmldata.ManagementPack.Manifest.Identity.Version = [version]::New($mpversion.Major, $mpversion.Minor, $mpversion.Build, $mpversion.Revision + 1).ToString()
								$aliases = $null
								$xmlData.ChildNodes.Manifest.References.Reference | Where-Object { $_.ID -eq $arg } | ForEach-Object { $removed += $_.ParentNode.InnerXML; $aliases += $_.Alias; [void]$_.ParentNode.RemoveChild($_); }
								foreach ($alias in $aliases)
								{
									Write-Host "    * Alias found: $alias"
									$xmlData.ChildNodes.Monitoring.Overrides.SecureReferenceOverride | Where-Object { $($_.Context -split '!')[0] -eq $alias } | ForEach-Object { $removed += $_.ParentNode.InnerXML; $id = $_.Id; [void]$_.ParentNode.RemoveChild($_) }
									$xmlData.ChildNodes.Monitoring.Overrides.MonitorPropertyOverride | Where-Object { $($_.Context -split '!')[0] -eq $alias -or ($($_.Monitor) -split '!')[0] -eq $alias } | ForEach-Object { $removed += $_.ParentNode.InnerXML; $id = $_.Id; [void]$_.ParentNode.RemoveChild($_) }
									$xmlData.ChildNodes.Monitoring.Overrides.DiscoveryConfigurationOverride | Where-Object { $($_.Context -split '!')[0] -eq $alias } | ForEach-Object { $removed += $_.ParentNode.InnerXML; $id += $_.Id; [void]$_.ParentNode.RemoveChild($_) }
									$xmlData.ChildNodes.Monitoring.Overrides.RulePropertyOverride | Where-Object { $($_.Context -split '!')[0] -eq $alias } | ForEach-Object { $removed += $_.ParentNode.InnerXML; $id += $_.Id; [void]$_.ParentNode.RemoveChild($_) }
								}
								
								foreach ($identifer in $id)
								{
									$xmlData.ChildNodes.LanguagePacks.LanguagePack.DisplayStrings.DisplayString | Where-Object { $_.ElementID -eq $identifer } | ForEach-Object { $removed += $_.ParentNode.InnerXML; [void]$_.ParentNode.RemoveChild($_) }
								}
								Write-Host "    * Removed the following XML Data from the MP: " -NoNewline
								Write-Host $($mp.Name) -ForegroundColor Cyan
								$removed
								
								Write-Host "      * Saving copy to: " -NoNewline -ForegroundColor Green
								Write-Host "$ExportPath`\$($mpPresent.Name).xml" -ForegroundColor Cyan
								$xmlData.Save("$ExportPath`\$($mpPresent.Name).xml")
								Write-Host "    * Importing MP: " -NoNewLine
								Write-Host $($mpPresent.Name) -ForegroundColor Cyan
								Import-SCOMManagementPack -FullName "$ExportPath`\$($mpPresent.Name).xml" | Out-Null
								Write-Host "    * Imported modified Management Pack: " -NoNewLine
								Write-Host $($mpPresent.Name) -ForegroundColor Cyan
							}
							catch
							{ Write-Warning $_ }
						}
						#pause
					}
					else
					{
						Write-Host "	* Backing up Sealed Management Pack: " -NoNewLine -ForegroundColor Green
						Write-Host "$ExportPath`\$($mp.Name).xml" -ForegroundColor Cyan
						$mpPresent | Export-SCOMManagementPack -Path $ExportPath -PassThru -ErrorAction Stop | Out-Null
						Write-Host "    * Uninstalling Sealed Management Pack: " -NoNewLine -ForegroundColor Red
						Write-Host $($mp.Name) -ForegroundColor Cyan
						Uninstall-ManagementPack -managementpack $mp
					}
				}
				if ($PauseOnEach)
				{
					pause
				}
			}
		}
	}
	
	#######################################################################
	#
	# Remove 'all' of the MPs as well as MPs that are dependent on them.
	# The remove is done by finding the base MP and finding
	# all MPs that depend on it.  This list will be presented to the user prompting
	# if the user wants to continue and removing the list of presented MPs
	#
	function RemoveMPs
	{
		param ($mpname,
			$mpid)
		if ($mpname)
		{
			$listOfManagementPacksToRemove = Get-SCOMManagementPack -Name $mpname -Recurse
		}
		elseif ($mpid)
		{
			$listOfManagementPacksToRemove = Get-SCOMManagementPack -Id $mpid -Recurse
		}
		if (!$listOfManagementPacksToRemove)
		{
			Write-Host "No Management Packs found for: $firstArgName" -ForegroundColor Yellow
			Set-Location $cwd
			break
		}
		else
		{
			$listOfManagementPacksToRemove | Format-Table Name, Sealed, DisplayName | Out-Host
			
			$title = "Uninstall/Edit Management Packs"
			$message = "Do you want to uninstall/edit the above $($listOfManagementPacksToRemove.Count) management packs and its dependent management packs?"
			
			$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Uninstall (Sealed) / Edit (Unsealed) selected Management Packs."
			$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Do not remove Management Packs."
			$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
			
			$result = $host.ui.PromptForChoice($title, $message, $options, 0)
			
			switch ($result)
			{
				0 { RemoveMPsHelper $listOfManagementPacksToRemove }
				1 { Write-Host "`nExiting without removing any management packs" -ForegroundColor DarkCyan }
			}
		}
	}
	
	#######################################################################
	# Begin Script functionality
	#
	if ($ManagementPackName -like "*")
	{
		$firstArgName = (Get-SCManagementPack -Name $ManagementPackName).Name
	}
	elseif ($ManagementPackName -like "*,*")
	{
		$firstArgName = ($ManagementPackName.Split(",").Split("["))[1]
	}
	elseif ($ManagementPackName)
	{
		$firstArgName = $ManagementPackName
	}
	elseif ($ManagementPackId -like "*,*")
	{
		$firstArgId = ($ManagementPackId.Split(",").Split("["))[1]
	}
	elseif ($ManagementPackId)
	{
		$firstArgId = $ManagementPackId
	}
	else
	{
		Write-Warning "Missing or Improper Arguments..`n`nSpecify the ID of the management pack you wish to delete (usually like: Microsoft.Azure.ManagedInstance.Discovery)."
		set-location $cwd
		break
	}
	add-pssnapin "Microsoft.EnterpriseManagement.OperationsManager.Client";
	$cwd = get-location
	set-location "OperationsManagerMonitoring::";
	$mgConnection = new-managementGroupConnection -ConnectionString:$rootMS;
	if ($firstArgName)
	{
		RemoveMPs -mpname $firstArgName
	}
	elseif ($firstArgId)
	{
		RemoveMPs -mpid $firstArgId
	}
	
	
	set-location $cwd
	remove-pssnapin "Microsoft.EnterpriseManagement.OperationsManager.Client";
	
	Write-Host 'Script Completed!' -ForegroundColor Green
}
if ($ManagementPackName -or $ManagementPackId -or $PauseOnEach -or $DryRun -or $ExportPath)
{
	Remove-MPDependencies -ManagementPackId $ManagementPackId -ManagementPackName $ManagementPackName -PauseOnEach:$PauseOnEach -DryRun:$DryRun -ExportPath $ExportPath
}
else
{
	# Example:
	#         Remove-MPDependencies -ManagementPackName "*APM*" -ExportPath C:\MPBackups
	#		  or
	#		  Remove-MPDependencies -ManagementPackName "*APM*"
	#		  or
	#		  Remove-MPDependencies -ManagementPackName Microsoft.Azure.ManagedInstance.Discovery
	Remove-MPDependencies
}
