# This script will export the SCOM User Roles to XML File Format.
# -----------------------------------------------
# Outputs the file to the current users desktop
# Initial Upload: June 20th, 2022
# Edited: May 24th, 2023
# Author: Blake Drumm (blakedrumm@microsoft.com)
# -----------------------------------------------
#region Variables Section
$OutputPath = 'C:\Temp\UserRole_Export.xml'
$UserRoleDisplayNameToExport = 'All' # Enter explicit display name here, or leave the default 'All' if you want all the user roles exported.
#endregion
# -----------------------------------------------
#region functions
function Get-SCOMManagementServerConnection([string]$s)
{
	$data = New-ManagementGroupConnection -ConnectionString:$s
	#cd Monitoring:\$s 
	#$mg = (get-item .).ManagementGroup 
	$mg = $data.ManagementGroup
	return $mg
}
function Import-SCOMModule
{
	try
	{
		# Check if SCOM is installed
		[string]$installDirectory = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\Setup" -ErrorAction Stop).InstallDirectory
		if (Test-Path $installDirectory -ErrorAction Stop)
		{
			$Full_Path = [System.IO.Path]::GetFullPath($installDirectory);
			[string]$PATH1 = [System.IO.Path]::GetFullPath("$Full_Path`Microsoft.Mom.Sdk.SecureStorageManager.dll")
			[System.Reflection.Assembly]::LoadFile($PATH1) | Out-Null
			[string]$PATH2 = [System.IO.Path]::GetFullPath("$Full_Path`Microsoft.EnterpriseManagement.DataAccessLayer.dll")
			[System.Reflection.Assembly]::LoadFile($PATH2) | Out-Null
		}
	}
	catch
	{
		Write-Host "[Critical Error] Unable to find installation directory for System Center Operations Manager - Management Server!" -ForegroundColor Yellow
		break
	}
	
	$snapins = PsSnapIn | select-Object name
	$added = $false
	foreach ($o in $snapins)
	{
		if ($o -like "*Microsoft.EnterpriseManagement.OperationsManager.Client*")
		{
			$added = $true
			break
		}
	}
	if (!$added)
	{
		Add-PSSnapin "Microsoft.EnterpriseManagement.OperationsManager.Client"
		Write-Host "OperationsManager snap-in has been added" -ForegroundColor Gray
	}
	else
	{
		Write-Host "OperationsManager snap-in is already loaded" -ForegroundColor Gray
	}
	
	return
}

function Export-SCOMUserRoles($UserRoles)
{
	#Make sure some custom user roles exist 
	if ($UserRoles.count -eq 0) { throw ("    No custom user roles found with name: '$UserRoleDisplayNameToExport'") }
	#Create the XML object 
	$doc = New-Object "System.Xml.XmlDocument"
	$doc.LoadXml("<?xml version='1.0' encoding='utf-8'?><UserRoles xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema'></UserRoles>")
	
	$views = $ms.GetMonitoringViews()
	$dashboardReferences = $ms.Dashboard.GetScopedDashboardComponentReferences()
	$consoleTasks = $ms.TaskConfiguration.GetConsoleTasks()
	$templates = $ms.Templates.GetTemplates()
	$tasks = $ms.TaskConfiguration.GetTasks()
	$SCOMGroups = $ms.GetRootMonitoringObjectGroups()
	$managementPacks = $ms.GetManagementPacks() | Select-Object DisplayName, Name, Version
	
	#Loop through each user role instance 
	foreach ($mo in $UserRoles)
	{
		#Add single instance data to XML 
		$elem = $doc.CreateElement("UserRole")
		$elem.SetAttribute("Name", $mo.Name)
		$elem.SetAttribute("DisplayName", $mo.DisplayName)
		$elem.SetAttribute("Description", $mo.Description)
		$elem.SetAttribute("Profile", $mo.Profile)
		
		#Add users to XML if any are defined 
		if ($mo.Users.count -ne 0)
		{
			foreach ($u in $mo.Users)
			{
				$elem2 = $doc.CreateElement("User")
				$elem2.SetAttribute("UserName", $u.ToString())
				$temp = $elem.AppendChild($elem2)
			}
		}
		
		#Loop through the groups if the user has explicitly defined group scopes 
		if ($mo.scope.Objects.count -gt 0)
		{
			foreach ($grp in $mo.scope.Objects)
			{
				$elem2 = $doc.CreateElement("GroupScope")
				$elem2.SetAttribute("DisplayName", ($SCOMGroups | Where-Object { $_.Id -eq $grp.ToString() }).DisplayName)
				$elem2.SetAttribute("Name", ($SCOMGroups | Where-Object { $_.Id -eq $grp.ToString() }).FullName)
				$elem2.SetAttribute("Id", $grp.ToString())
				$temp = $elem.AppendChild($elem2)
			}
		}
		#Loop through the views if the user has explicitly defined views 
		if ($mo.scope.Views.count -gt 0)
		{
			foreach ($view in $mo.scope.Views)
			{
				$viewsResult = $views | Where-Object { $_.Id -eq "$($view.First.ToString())" }
				
				$elem2 = $doc.CreateElement("MonitoringView")
				$elem2.SetAttribute("DisplayName", $viewsResult.DisplayName)
				$elem2.SetAttribute("Name", $viewsResult.Name)
				$elem2.SetAttribute("Id", $view.First.ToString())
				$elem2.SetAttribute("Bool", $view.Second.ToString())
				$elem2.SetAttribute("ManagementPack", $viewsResult.ManagementPackName)
				#$elem2.SetAttribute("ManagementPackVersion", $viewsResult.Version)
				$temp = $elem.AppendChild($elem2)
			}
		}
		#Loop through the Dashboard References if the user has explicitly defined Dashboard References 
		if ($mo.scope.DashboardReferences.count -gt 0)
		{
			foreach ($DashboardReference in $mo.scope.DashboardReferences)
			{
				$dashboardReferenceResult = $dashboardReferences | Where-Object { ($_.Id -eq "$($DashboardReference.ToString())") }
				$dashboardReferenceMPResult = $dashboardReferenceResult.Identifier.Domain | Select-Object -Index 0
				$MPVersion = ($managementPacks | Where-Object { $_.ManagementPackName -eq $dashboardReferenceMPResult }).Version
				$elem2 = $doc.CreateElement("DashboardReference")
				$elem2.SetAttribute("DisplayName", $dashboardReferenceResult.DisplayName)
				$elem2.SetAttribute("Name", $dashboardReferenceResult.Name)
				$elem2.SetAttribute("Id", $DashboardReference.ToString())
				$elem2.SetAttribute("ManagementPack", "$dashboardReferenceMPResult")
				#$elem2.SetAttribute("ManagementPackVersion", ($MPVersion | Select-Object -Index 0))
				$temp = $elem.AppendChild($elem2)
			}
		}
		#Loop through the Console Tasks if the user has explicitly defined Console Tasks 
		if ($mo.scope.ConsoleTasks.count -gt 0)
		{
			foreach ($ConsoleTask in $mo.scope.ConsoleTasks)
			{
				$consoleTaskResult = $consoleTasks | Where-Object { ($_.Id -eq "$($ConsoleTask.ToString())") }
				$consoleTaskMPResult = $consoleTaskResult.Identifier.Domain | Select-Object -Index 0
				$elem2 = $doc.CreateElement("ConsoleTask")
				$elem2.SetAttribute("DisplayName", $consoleTaskResult.DisplayName)
				$elem2.SetAttribute("Name", $consoleTaskResult.Name)
				$elem2.SetAttribute("Id", $ConsoleTask.ToString())
				$elem2.SetAttribute("ManagementPack", "$consoleTaskMPResult")
				#$elem2.SetAttribute("ManagementPackVersion", $(($managementPacks | Where-Object { $_.ManagementPackName -eq $consoleTaskMPResult }).Version))
				$temp = $elem.AppendChild($elem2)
			}
		}
		#Loop through the Templates if the user has explicitly defined Templates 
		if ($mo.scope.Templates.count -gt 0)
		{
			foreach ($Template in $mo.scope.Templates)
			{
				$templateResult = $templates | Where-Object { ($_.Id -eq "$($Template.ToString())") }
				$templateMPResult = $templateResult.Identifier.Domain | Select-Object -Index 0
				$elem2 = $doc.CreateElement("Template")
				$elem2.SetAttribute("DisplayName", $templateResult.DisplayName)
				$elem2.SetAttribute("Name", $templateResult.Name)
				$elem2.SetAttribute("Id", $Template.ToString())
				$elem2.SetAttribute("ManagementPack", "$templateMPResult")
				#$elem2.SetAttribute("ManagementPackVersion", $(($managementPacks | Where-Object { $_.ManagementPackName -eq $templateMPResult }).Version))
				$temp = $elem.AppendChild($elem2)
			}
		}
		#Loop through the non-credential tasks if the user has explicitly defined tasks 
		if ($mo.scope.NonCredentialTasks.count -gt 0)
		{
			foreach ($task in $mo.scope.NonCredentialTasks)
			{
				$taskResult = $tasks | Where-Object { ($_.Id -eq "$($task.First.ToString())") }
				$taskMPResult = $taskResult.Identifier.Domain | Select-Object -Index 0
				$elem2 = $doc.CreateElement("NonCredentialMonitoringTask")
				$elem2.SetAttribute("DisplayName", $taskResult.DisplayName)
				$elem2.SetAttribute("Name", $taskResult.Name)
				$elem2.SetAttribute("Id", $task.First.ToString())
				$elem2.SetAttribute("Bool", $task.Second.ToString())
				$elem2.SetAttribute("ManagementPack", "$taskMPResult")
				#$elem2.SetAttribute("ManagementPackVersion", $(($managementPacks | Where-Object { $_.ManagementPackName -eq $taskMPResult }).Version))
				$temp = $elem.AppendChild($elem2)
			}
		}
		#Loop through the credential tasks if the user has explicitly defined tasks 
		if ($mo.scope.CredentialTasks.count -gt 0)
		{
			foreach ($task in $mo.scope.CredentialTasks)
			{
				$credentialTaskResult = $tasks | Where-Object { ($_.Id -eq "$($task.First.ToString())") }
				$credentialTaskMPResult = $credentialTaskResult.Identifier.Domain | Select-Object -Index 0
				$elem2 = $doc.CreateElement("CredentialMonitoringTask")
				$elem2.SetAttribute("DisplayName", $credentialTaskResult.DisplayName)
				$elem2.SetAttribute("Name", $credentialTaskResult.Name)
				$elem2.SetAttribute("Id", $task.First.ToString())
				$elem2.SetAttribute("Bool", $task.Second.ToString())
				$elem2.SetAttribute("ManagementPack", "$credentialTaskMPResult")
				#$elem2.SetAttribute("ManagementPackVersion", $(($managementPacks | Where-Object { $_.ManagementPackName -eq $credentialTaskMPResult }).Version))
				$temp = $elem.AppendChild($elem2)
			}
		}
		#Write this new element to the XML document        
		$temp = $doc.get_ChildNodes().Item(1).AppendChild($elem)
		
	}
	Write-Host "    Exported XML file: $OutputPath" -ForegroundColor Green
	
	#Save XML to a file 
	$doc.save($OutputPath)
}
#endregion
# -----------------------------------------------

$UserRoleList = @()
Import-SCOMModule

$ms = Get-SCOMManagementServerConnection $env:COMPUTERNAME
if (-NOT $ms) { throw ("Error connecting to Management Server") }

if ($UserRoleDisplayNameToExport -eq 'All')
{
	$UserRoleList = Get-SCOMUserRole
}
else
{
	$UserRoleList = Get-SCOMUserRole | Where-Object { $_.DisplayName -eq $UserRoleDisplayNameToExport }
}

Write-Host "  Processing User Role:" -ForegroundColor Cyan
foreach ($UserRole in $UserRoleList)
{
	Write-Host "    $UserRole" -ForegroundColor Magenta
}
Export-SCOMUserRoles $UserRoleList
Write-Host "Completed!" -ForegroundColor Green
