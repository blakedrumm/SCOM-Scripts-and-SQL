# THIS SCRIPT CAN BE DANGEROUS, MAKE BACKUPS OF YOUR OPSDB AND DW! OR RUN WITH THE '-PauseOnEach' AND `-DryRun` PARAMETERS

# PowerShell script to automatically remove an MP and its dependencies.
#
# Original Author(s)    :   Christopher Crammond, Chandra Bose
# Author	        :   Blake Drumm (blakedrumm@microsoft.com)
# Date Created	 	:	April 24th, 2012
# Date Modified		: 	July 19th, 2021
#
# Version		:       3.0.0
#
# Arguments		: 	ManagementPackName.  (Provide the value of the management pack name or id from the management pack properties.  Otherwise, the script will fail.)

<# 
Updated - August 19th, 2021:
	Added ability to remove XML Reference from Unsealed Management Packs

Updated - July 20th, 2022:
	Major Update, my attempt to fix some issues with processing MP Elements
	
Updated - July 26th, 2022:
	Minor Update

#>

# Example:
# .\Remove-MPDependencies -ManagementPackName "*APM*"
#
# .\Remove-MPDependencies.ps1 -ManagementPackName Microsoft.Azure.ManagedInstance.Discovery
#
# Get-SCManagementPack -DisplayName "Microsoft Azure SQL Managed Instance (Discovery)" | .\Remove-MPDependencies.ps1 -DryRun -PauseOnEach
#
# Get-SCManagementPack -DisplayName "Microsoft Azure SQL Managed Instance (Discovery)" | .\Remove-MPDependencies.ps1

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
		Write-Host "Creating directory for export: " -NoNewline -ForegroundColor Green
		Write-Host $ExportPath -ForegroundColor Cyan
		New-Item -ItemType Directory -Path $ExportPath | Out-Null
	}
	if (!$ManagementPackName -and !$ManagementPackId)
	{
		Write-Host "-ManagementPackName or -ManagementPackId is required!" -ForegroundColor Red
		#set-location $cwd
		break
	}
	$ipProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
	$rootMS = "{0}.{1}" -f $ipProperties.HostName, $ipProperties.DomainName
	
	
	#######################################################################
	#
	# Helper method that will remove the list of given Management Packs.
	#
	function Remove-MPsHelper
	{
		param ($mpList)
		$recursiveListOfManagementPacksToRemove = $null
		$mpList = $mpList
		foreach ($mp in $mpList)
		{
			$id = $null
			$recursiveListOfManagementPacksToRemove = Get-SCManagementPack -Name $mp.Name -Recurse
			if ($recursiveListOfManagementPacksToRemove.Count -gt 1)
			{
				Write-Output "`r`n"
				Write-Host "The following dependent management packs have to be edited/deleted, before deleting " -NoNewline
				Write-Host $($mp.Name) -ForegroundColor Cyan
				
				#$recursiveListOfManagementPacksToRemove | format-table name, Sealed
				Remove-MPsHelper $recursiveListOfManagementPacksToRemove
			}
			else
			{
				$mpPresent = Get-SCManagementPack -Name $mp.Name
				$Error.Clear()
				if ($mpPresent -eq $null)
				{
					# If the MP wasn't found, we skip the uninstallation of it.
					Write-Host "    $($mp.Name) has already been uninstalled" -ForegroundColor Cyan
				}
				else
				{
					if ($mpPresent.Sealed -eq $false)
					{
						foreach ($arg in $firstArgName)
						{
							Write-Host "    * Removing " -NoNewline -ForegroundColor Green
							Write-Host $arg -ForegroundColor Cyan -NoNewline
							Write-Host " reference from " -NoNewLine -ForegroundColor Green
							Write-Host $($mp.Name) -ForegroundColor Magenta
							try
							{
								[array]$removed = $null
								[array]$alias = $null
								[array]$AlertMessage = $null
								[array]$id = $null
								Write-Host "      * Exporting MP to: " -ForegroundColor DarkCyan -NoNewline
								Write-Host "$ExportPath`\$($mpPresent.Name).xml" -ForegroundColor Cyan
								$mpPresent | Export-SCManagementPack -Path $ExportPath -PassThru -ErrorAction Stop | Out-Null
								$xmldata = [xml](Get-Content "$ExportPath`\$($mpPresent.Name).xml" -ErrorAction Stop);
								[version]$mpversion = $xmldata.ManagementPack.Manifest.Identity.Version
								Write-Host "      * Backing up to: " -ForegroundColor DarkCyan -NoNewline
								Write-Host "$ExportPath`\$($mpPresent.Name).backup-v$mpversion.xml" -ForegroundColor Cyan
								$xmlData.Save("$ExportPath`\$($mpPresent.Name).backup.xml")
								$xmldata.ManagementPack.Manifest.Identity.Version = [version]::New($mpversion.Major, $mpversion.Minor, $mpversion.Build, $mpversion.Revision + 1).ToString()
								
								$aliases = $null
								$xmlData.ChildNodes.Manifest.References.Reference | Where-Object { $_.ID -eq $arg } | ForEach-Object { $removed += $_.ParentNode.InnerXML; $aliases += $_.Alias; [void]$_.ParentNode.RemoveChild($_); }
								foreach ($alias in $aliases)
								{
									Write-Host "      * Alias found: " -NoNewline -ForegroundColor Green
									Write-Host $alias -ForegroundColor Magenta
									
									# Type Definitions
									$xmlData.ChildNodes.TypeDefinitions.EntityTypes.ClassTypes.ClassType | Where-Object { $($_.Id -split '!')[0] -eq $alias -or ($($_.Base) -split '!')[0] -eq $alias } | ForEach-Object { if ($_.Property) { $id += $_.Id }; $removed += $_.ParentNode.InnerXML; $id += $_.Id; [void]$_.ParentNode.RemoveChild($_) }
									$xmlData.ChildNodes.TypeDefinitions.ModuleTypes.DataSourceModuleType | Where-Object { $($_.RunAs -split '!')[0] -eq $alias -or ($($_.Id) -split '!')[0] -eq $alias } | ForEach-Object { $id += $_.Id; $removed += $_.InnerXML; $id += $_.Id; [void]$_.RemoveChild($_) }
									$xmlData.ChildNodes.TypeDefinitions.ModuleTypes.ProbeActionModuleType.ModuleImplementation.Managed.Assembly | Where-Object { $($_ -split '!')[0] -eq $alias } | ForEach-Object { $removed += ($_.ParentNode).InnerXML; $id += $_.Id; [void]$_.ParentNode.RemoveChild($_) }
									$xmlData.ChildNodes.TypeDefinitions.MonitorTypes.UnitMonitorType | Where-Object { $($_.RunAs -split '!')[0] -eq $alias -or ($($_.Id) -split '!')[0] -eq $alias } | ForEach-Object { $removed += $_.ParentNode.InnerXML; $id += $_.Id; [void]$_.ParentNode.RemoveChild($_) }
									
									# Discoveries
									$xmlData.ChildNodes.Monitoring.Discoveries.Discovery | Where-Object { $($_.Id -split '!')[0] -eq $alias -or ($($_.Target) -split '!')[0] -eq $alias } | ForEach-Object { $removed += $_.ParentNode.InnerXML; $id += $_.Id; [void]$_.ParentNode.RemoveChild($_) }
									
									# Rules
									$xmlData.ChildNodes.Monitoring.Rules.Rule | Where-Object { $($_.Id -split '!')[0] -eq $alias -or ($($_.Target) -split '!')[0] -eq $alias } | ForEach-Object { $removed += $_.ParentNode.InnerXML; $id += $_.Id; [void]$_.ParentNode.RemoveChild($_) }
									
									# Tasks
									$xmlData.ChildNodes.Monitoring.Tasks.Task | Where-Object { $($_.Id -split '!')[0] -eq $alias -or ($($_.Target) -split '!')[0] -eq $alias } | ForEach-Object { $removed += $_.ParentNode.InnerXML; $id += $_.Id; [void]$_.ParentNode.RemoveChild($_) }
									
									# Monitors
									# Aggregate Monitor
									$xmlData.ChildNodes.Monitoring.Monitors.AggregateMonitor | Where-Object { $($_.Id -split '!')[0] -eq $alias -or ($($_.Target) -split '!')[0] -eq $alias } | ForEach-Object { if ($_.AlertSettings) { $AlertMessage += $_.AlertSettings.AlertMessage; $id += $_.AlertSettings.AlertMessage }; $removed += $_.ParentNode.InnerXML; $id += $_.Id; [void]$_.ParentNode.RemoveChild($_) }
									# Dependency Monitor
									$xmlData.ChildNodes.Monitoring.Monitors.DependencyMonitor | Where-Object { $($_.Id -split '!')[0] -eq $alias -or ($($_.Target) -split '!')[0] -eq $alias } | ForEach-Object { if ($_.AlertSettings) { $AlertMessage += $_.AlertSettings.AlertMessage; $id += $_.AlertSettings.AlertMessage }; $removed += $_.ParentNode.InnerXML; $id += $_.Id; [void]$_.ParentNode.RemoveChild($_) }
									# Unit Monitor
									$xmlData.ChildNodes.Monitoring.Monitors.UnitMonitor | Where-Object { $($_.Id -split '!')[0] -eq $alias -or ($($_.Target) -split '!')[0] -eq $alias -or ($($_.ParentMonitorID) -split '!')[0] -eq $alias } | ForEach-Object { $removed += $_.ParentNode.InnerXML; $id += $_.Id; [void]$_.ParentNode.RemoveChild($_) }
									
									# Overrides
									$xmlData.ChildNodes.Monitoring.Overrides.SecureReferenceOverride | Where-Object { $($_.Context -split '!')[0] -eq $alias } | ForEach-Object { $removed += $_.ParentNode.InnerXML; $id += $_.Id; [void]$_.ParentNode.RemoveChild($_) }
									$xmlData.ChildNodes.Monitoring.Overrides.MonitorPropertyOverride | Where-Object { $($_.Context -split '!')[0] -eq $alias -or ($($_.Monitor) -split '!')[0] -eq $alias } | ForEach-Object { $removed += $_.ParentNode.InnerXML; $id += $_.Id; [void]$_.ParentNode.RemoveChild($_) }
									$xmlData.ChildNodes.Monitoring.Overrides.DiscoveryConfigurationOverride | Where-Object { $($_.Context -split '!')[0] -eq $alias } | ForEach-Object { $removed += $_.ParentNode.InnerXML; $id += $_.Id; [void]$_.ParentNode.RemoveChild($_) }
									$xmlData.ChildNodes.Monitoring.Overrides.RulePropertyOverride | Where-Object { $($_.Context -split '!')[0] -eq $alias } | ForEach-Object { $removed += $_.ParentNode.InnerXML; $id += $_.Id; [void]$_.ParentNode.RemoveChild($_) }
								}
								
								# Presentation
								foreach ($alertMsg in $AlertMessage)
								{
									$xmlData.ChildNodes.Presentation.StringResources | Where-Object { $_.StringResource.Id -eq $alertMsg } | ForEach-Object { $removed += $_.ParentNode.InnerXML; $id += $_.Id; [void]$_.ParentNode.RemoveChild($_) }
								}
								
								# Language Packs
								foreach ($identifer in $id)
								{
									$xmlData.ChildNodes.LanguagePacks.LanguagePack.DisplayStrings.DisplayString | Where-Object { $_.ElementID -eq $identifer } | ForEach-Object { $removed += $_.ParentNode.InnerXML; [void]$_.ParentNode.RemoveChild($_) }
								}
								if ($removed)
								{
									Write-Host "        * Current Management Pack Version: " -NoNewline -ForegroundColor DarkCyan
									Write-Host $mpversion -ForegroundColor Cyan
									
									Write-Host "        * Updating Management Pack Version to: " -NoNewline -ForegroundColor DarkCyan
									Write-Host $($xmldata.ManagementPack.Manifest.Identity.Version) -ForegroundColor Cyan
									
									Write-Host "    * Removed the following XML Data from the MP: " -NoNewline -ForegroundColor DarkYellow
									Write-Host $($mp.Name) -ForegroundColor Cyan
									Write-Host "`"$removed`"" -ForegroundColor Gray
									
									Write-Host "      * Saving Updated MP to: " -NoNewline -ForegroundColor DarkCyan
									Write-Host "$ExportPath`\$($mpPresent.Name).xml" -ForegroundColor Green
									$xmlData.Save("$ExportPath`\$($mpPresent.Name).xml")
								}
								else
								{
									Write-Host "    * Unable to locate any XML Nodes to remove" -ForegroundColor Red
								}
								$Error.Clear()
								try
								{
									if ($DryRun)
									{
										Write-Host "    * Dry Run Parameter Present - Skipping Import Step for: " -NoNewLine -ForegroundColor Gray
										Write-Host $($mp.Name) -ForegroundColor Cyan
									}
									else
									{
										if ($removed)
										{
											Write-Host "    * Importing MP: " -NoNewLine -ForegroundColor Green
											Write-Host $($mpPresent.Name) -ForegroundColor Cyan
											Import-SCManagementPack -FullName "$ExportPath`\$($mpPresent.Name).xml" -ErrorAction Stop | Out-Null
											Write-Host "    * Imported modified Management Pack: " -NoNewLine -ForegroundColor Green
											Write-Host $($mpPresent.Name) -ForegroundColor Cyan
										}
									}
								}
								catch
								{
									foreach ($errors in $Error)
									{
										Write-Warning $errors
									}
									pause
								}
							}
							catch
							{ Write-Warning $_ }
						}
						#pause
					}
					else
					{
						Write-Host "	* Backing up Sealed Management Pack: " -NoNewLine -ForegroundColor DarkCyan
						Write-Host "$ExportPath`\$($mp.Name).xml" -ForegroundColor Green
						$mpPresent | Export-SCManagementPack -Path $ExportPath -PassThru -ErrorAction Stop | Out-Null
						
						if ($DryRun)
						{
							Write-Host "    * Dry Run Parameter Present - Skipping Delete Step for: " -NoNewLine -ForegroundColor Gray
							Write-Host $($mp.Name) -ForegroundColor Cyan
						}
						else
						{
							Write-Host "    * Uninstalling Sealed Management Pack: " -NoNewLine -ForegroundColor Red
							Write-Host $($mp.Name) -ForegroundColor Cyan
							Remove-SCManagementPack -managementpack $mp
						}
						
					}
				}
				if ($PauseOnEach)
				{
					pause
				}
				continue
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
	function Remove-MPs
	{
		param ($mpname,
			$mpid)
		if ($mpname)
		{
			$listOfManagementPacksToRemove = Get-SCManagementPack -Name $mpname -Recurse
		}
		elseif ($mpid)
		{
			$listOfManagementPacksToRemove = Get-SCManagementPack -Id $mpid -Recurse
		}
		if (!$listOfManagementPacksToRemove)
		{
			Write-Host "No Management Packs found for: $firstArgName" -ForegroundColor Yellow
			#Set-Location $cwd
			break
		}
		else
		{
			Write-Host "List of Management Packs that will be affected:" -ForegroundColor Green
			$listOfManagementPacksToRemove | Format-Table Name, Sealed, DisplayName | Out-Host
			if (!$DryRun)
			{
				$title = "Uninstall/Edit Management Packs"
				$message = "Do you want to uninstall/edit the above $($listOfManagementPacksToRemove.Count) management packs and its dependent management packs?"
				
				$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Uninstall (Sealed) / Edit (Unsealed) selected Management Packs."
				$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Do not remove Management Packs."
				$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
				
				$result = $host.ui.PromptForChoice($title, $message, $options, 0)
			}
			else
			{
				$result = 0
			}
			
			switch ($result)
			{
				0 { Remove-MPsHelper $listOfManagementPacksToRemove }
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
		#set-location $cwd
		break
	}
	Add-PSSnapin "Microsoft.EnterpriseManagement.OperationsManager.Client";
	#$cwd = get-location
	#set-location "OperationsManagerMonitoring::";
	$mgConnection = new-managementGroupConnection -ConnectionString:$rootMS;
	if ($firstArgName)
	{
		Remove-MPs -mpname $firstArgName
	}
	elseif ($firstArgId)
	{
		Remove-MPs -mpid $firstArgId
	}
	
	
	#Set-Location $cwd
	Remove-PSSnapin "Microsoft.EnterpriseManagement.OperationsManager.Client";
	
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
	#		  or
	#		  Remove-MPDependencies Microsoft.Windows.Server.2016*
	Remove-MPDependencies
}
