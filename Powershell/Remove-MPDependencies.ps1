# PowerShell script to automagically remove an MP and its dependencies.
#
# Original Author	:     	Christopher Crammond, Chandra Bose
# Modified By	 	:     	Blake Drumm (blakedrumm@microsoft.com)
# Date Created	 	:	April 24th, 2012
# Date Modified		: 	August 19th, 2021
#
# Version		:       2.0.0
#
# Arguments		: 	ManagementPackName.  (Provide the value of the management pack ID from the management pack properties, not the value of the Name property.  Otherwise, the script will fail.)

<# NOTE:

Added ability to remove XML Reference from Unsealed Management Packs - August 19th, 2021

#>

# Example:
# Get-SCOMManagementPack -DisplayName "Microsoft Azure SQL Managed Instance (Discovery)" | .\RecursiveRemove.ps1 -DryRun -PauseOnEach
#
# Get-SCOMManagementPack -DisplayName "Microsoft Azure SQL Managed Instance (Discovery)" | .\RecursiveRemove.ps1
# 
# .\RecursiveRemove.ps1 -ManagementPackName Microsoft.Azure.ManagedInstance.Discovery

# Needed for SCOM SDK
param
(
	[Parameter(ValueFromPipeline = $true,
			   Position = 0,
			   HelpMessage = 'ex: Microsoft.Azure.ManagedInstance.Discovery')]
	[string]$ManagementPackName,
	[Parameter(Position = 1,
			   HelpMessage = 'This will allow you to pause between each Mangement Pack Dependency removal.')]
	[switch]$PauseOnEach,
	[Parameter(Position = 2,
			   HelpMessage = 'This will let you see how it would execute, without making any changes to your environment.')]
	[switch]$DryRun
)

function Remove-MPDependencies
{
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0,
				   HelpMessage = 'ex: Microsoft.Azure.ManagedInstance.Discovery')]
		[String]$ManagementPackName,
		[Parameter(Position = 1,
				   HelpMessage = 'This will allow you to pause between each Mangement Pack Dependency removal.')]
		[switch]$PauseOnEach,
		[Parameter(Position = 2,
				   HelpMessage = 'This will let you see how it would execute, without making any changes to your environment.')]
		[switch]$DryRun
	)
	$firstArg = $null
	
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
				Echo "`r`n"
				Echo "The following dependent management packs have to be deleted, before deleting "
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
						exit
					}
					elseif ($mpPresent.Sealed -eq $false)
					{
						Write-Host "    * Removing reference from " -NoNewLine
						Write-Host $($mp.Name) -ForegroundColor Cyan
						try
						{
							$mpPresent | Export-SCOMManagementPack -Path "C:\Users\Administrator.contoso\Desktop\" -PassThru -ErrorAction Stop
							$xmldata = [xml](Get-Content "C:\Users\Administrator.contoso\Desktop\$($mpPresent.Name).xml" -ErrorAction Stop);
							$xmlData.Save("C:\Users\Administrator.contoso\Desktop\$($mpPresent.Name).backup.xml")
							[version]$mpversion = $xmldata.ManagementPack.Manifest.Identity.Version
							$xmldata.ManagementPack.Manifest.Identity.Version = [version]::New($mpversion.Major, $mpversion.Minor, $mpversion.Build, $mpversion.Revision + 1).ToString()
							$xmlData.ChildNodes.Manifest.References.Reference | Where { $_.ID -eq $firstArg } | ForEach-Object { $alias = $_.Alias; [void]$_.ParentNode.RemoveChild($_); }
							$xmlData.ChildNodes.Monitoring.Overrides.MonitorPropertyOverride | Where { $($_.Context -split '!')[0] -eq $alias } | ForEach-Object { $id += $_.Id; [void]$_.ParentNode.RemoveChild($_) }
							$xmlData.ChildNodes.Monitoring.Overrides.DiscoveryConfigurationOverride | Where { $($_.Context -split '!')[0] -eq $alias } | ForEach-Object { $id += $_.Id; [void]$_.ParentNode.RemoveChild($_) }
							$xmlData.ChildNodes.Monitoring.Overrides.RulePropertyOverride | Where { $($_.Context -split '!')[0] -eq $alias } | ForEach-Object { $id += $_.Id; [void]$_.ParentNode.RemoveChild($_) }
							foreach ($identifer in $id)
							{
								$xmlData.ChildNodes.LanguagePacks.LanguagePack.DisplayStrings.DisplayString | Where { $_.ElementID -eq $identifer } | ForEach-Object { [void]$_.ParentNode.RemoveChild($_) }
							}
							$xmlData.Save("C:\Users\Administrator.contoso\Desktop\$($mpPresent.Name).xml")
							Import-SCOMManagementPack -FullName "C:\Users\Administrator.contoso\Desktop\$($mpPresent.Name).xml" | Out-Null
						}
						catch
						{ Write-Warning $_ }
						Write-Host "    * Imported modified Management Pack: " -NoNewLine
						Write-Host $($mp.Name) -ForegroundColor Cyan
						#pause
					}
					else
					{
						Write-Host "    * Uninstalling Management Pack: " -NoNewLine -ForegroundColor Red
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
		param ($mp)
		
		$listOfManagementPacksToRemove = Get-SCOMManagementPack -Name $mp -Recurse
		$listOfManagementPacksToRemove | Format-Table Name, Sealed, DisplayName
		
		$title = "Uninstall Management Packs"
		$message = "Do you want to uninstall the above $($listOfManagementPacksToRemove.Count) management packs and its dependent management packs?"
		
		$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Uninstall selected Management Packs."
		$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Do not remove Management Packs."
		$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
		
		$result = $host.ui.PromptForChoice($title, $message, $options, 0)
		
		switch ($result)
		{
			0 { RemoveMPsHelper $listOfManagementPacksToRemove }
			1 { Write-Host "`nExiting without removing any management packs" -ForegroundColor DarkCyan }
		}
	}
	
	#######################################################################
	# Begin Script functionality
	#
	if ($ManagementPackName -like "*,*")
	{
		$firstArg = ($ManagementPackName.Split(",").Split("["))[1]
	}
	elseif ($ManagementPackName)
	{
		$firstArg = $ManagementPackName
	}
	else
	{
		Write-Warning "Missing or Improper Arguments..`n`nSpecify the ID of the management pack you wish to delete (usually like: Microsoft.Azure.ManagedInstance.Discovery)."
		break
	}
	add-pssnapin "Microsoft.EnterpriseManagement.OperationsManager.Client";
	$cwd = get-location
	set-location "OperationsManagerMonitoring::";
	$mgConnection = new-managementGroupConnection -ConnectionString:$rootMS;
	
	RemoveMPs -mp $firstArg
	
	set-location $cwd
	remove-pssnapin "Microsoft.EnterpriseManagement.OperationsManager.Client";
	
	Write-Host 'Script Completed!' -ForegroundColor Green
}
if ($ManagementPackName -or $PauseOnEach -or $DryRun)
{
	Remove-MPDependencies -ManagementPackName $ManagementPackName -PauseOnEach:$PauseOnEach -DryRun:$DryRun
}
else
{
	# Example:
	#         Remove-MPDependencies -ManagementPackName Microsoft.SQLServer.Windows.Discovery
	Remove-MPDependencies
}
