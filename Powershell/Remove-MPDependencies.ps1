# PowerShell script to automagically remove an MP and its dependencies.
#
# Original Author	:     	Christopher Crammond, Chandra Bose
# Modified By	 	:     	Blake Drumm
# Date Created	 	:	April 24th, 2012
# Date Modified		: 	February 15th, 2021
#
# Version		:       1.0.0
#
# Arguments		: 	ManagementPackId.  (Provide the value of the management pack ID from the management pack properties, not the value of the Name property.  Otherwise, the script will fail.)

# Example:
# Get-SCOMManagementPack -DisplayName "Microsoft Azure SQL Managed Instance (Discovery)" | .\RecursiveRemove.ps1 -DryRun -PauseOnEach
#
# Get-SCOMManagementPack -DisplayName "Microsoft Azure SQL Managed Instance (Discovery)" | .\RecursiveRemove.ps1
# 
# .\RecursiveRemove.ps1 -ManagementPackId Microsoft.Azure.ManagedInstance.Discovery

# Needed for SCOM SDK
param
(
	[Parameter(Mandatory = $true,
			   ValueFromPipeline = $true,
			   Position = 0,
			   HelpMessage = 'ex: Microsoft.Azure.ManagedInstance.Discovery')]
	[String]$ManagementPackId,
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
		$recursiveListOfManagementPacksToRemove = Get-SCOMManagementPack -Name $mp.Name -Recurse
		if ($recursiveListOfManagementPacksToRemove.Count -gt 1)
		{
			Echo "`r`n"
			Echo "Following dependent management packs has to be deleted before deleting $($mp.Name)"
			
			$recursiveListOfManagementPacksToRemove | format-table name
			RemoveMPsHelper $recursiveListOfManagementPacksToRemove
		}
		else
		{
			$mpPresent = Get-ManagementPack -Name $mp.Name
			$Error.Clear()
			if ($mpPresent -eq $null)
			{
				# If the MP wasn't found, we skip the uninstallation of it.
				Echo "    $mp has already been uninstalled"
			}
			else
			{
				Echo "    * Uninstalling $mp "
				if ($DryRun)
				{
					break
				}
				else
				{
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
	$listOfManagementPacksToRemove | format-table name
	
	$title = "Uninstall Management Packs"
	$message = "Do you want to uninstall the above $($listOfManagementPacksToRemove.Count) management packs and its dependent management packs?"
	
	$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Uninstall selected Management Packs."
	$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Do not remove Management Packs."
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
	
	$result = $host.ui.PromptForChoice($title, $message, $options, 0)
	
	switch ($result)
	{
		0 { RemoveMPsHelper $listOfManagementPacksToRemove }
		1 { "Exiting without removing any management packs" }
	}
}

#######################################################################
# Begin Script functionality
#
if ($ManagementPackId -like "*,*")
{
	
	$firstArg = ($ManagementPackId.Split(",").Split("["))[1]
}
elseif ($ManagementPackId)
{
	$firstArg = $ManagementPackId
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
