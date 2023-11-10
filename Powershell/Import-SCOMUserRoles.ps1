# This script will import the SCOM User Roles from an XML File Format.
# -----------------------------------------------
# Initial Upload: May 19th, 2023
# Author: Blake Drumm (blakedrumm@microsoft.com)
# -----------------------------------------------
#region Configurable Variables
$ImportPath = 'C:\Temp\UserRole_Export.xml'
$UserRoleDisplayNameToImport = 'All' # Enter explicit display name here, or leave the default 'All' if you want all the user roles imported.
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
	
	$snapins = PsSnapIn | Select-Object name
	$added = $false
	foreach ($o in $snapins)
	{
		if ($o -like "*Microsoft.EnterpriseManagement.OperationsManager.Client*")
		{
			$added = $true
			break
		}
	}
	if (-NOT $added)
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
#Add new rights to User Roles
function Invoke-ReplicateUserRoleRights([System.Object]$xml)
{
	#Get the user 
	$obj = $ms.GetMonitoringUserRoles() | Where-Object { $_.Name -eq $xml.Name }
	Write-Verbose "        $($obj.Name) - Checking/Adding rights"
	
	$scomGroups = $ms.GetRootMonitoringObjectGroups()
	#Now Add Group Scopes
	if ($xml.GroupScope)
	{
		foreach ($xmlGroupScope in $xml.GroupScope)
		{
			$bFound = $false
			foreach ($consoleScope in $obj.Scope.Objects)
			{
				if ($xmlGroupScope.Id -eq $consoleScope.ToString())
				{
					$bFound = $true
				}
			}
			if (-NOT $bFound)
			{
				$ret = $true
				[string]$sGuid = $xmlGroupScope.Id
				if ($sGuid.length -ne 0)
				{
					$obj.Scope.Objects.Add($sGuid)
					$ret = try { $obj.Update() }
					catch { Write-Warning $_ }
					if (-NOT $ret)
					{
						$Id = $($scomGroups | Where-Object { $_.Id -eq $xmlGroupScope.Id })
						Write-Host "         Adding Group Scope: $Id" -ForegroundColor Green
					}
					else
					{
						Write-Host "         No matching group found in Group Scope: $($xmlGroupScope.Id)" -ForegroundColor Red
					}
				}
			}
			else
			{
				$groupFound = $scomGroups | Where-Object { $_.Id -eq $xmlGroupScope.Id }
				if ($groupFound)
				{
					Write-Host "         Group already exists in Group Scope: $groupFound" -ForegroundColor Gray
				}
			}
		}
	}
	$dashboardReferences = $ms.Dashboard.GetScopedDashboardComponentReferences()
	#Now Add Dashboard References
	if ($xml.DashboardReference)
	{
		foreach ($xmlDashboardReference in $xml.DashboardReference)
		{
			$failureOccurred = $false
			$bFound = $false
			foreach ($consoleScope in $obj.Scope.DashboardReferences)
			{
				if ($xmlDashboardReference.Id -eq $consoleScope.ToString())
				{
					$bFound = $true
				}
			}
			if (-NOT $bFound)
			{
				if ($dashboardReferences.Name -notcontains $xmlDashboardReference.Name -or $dashboardReferences.Id -notcontains $xmlDashboardReference.Id)
				{
					Write-Warning "Unable to locate Dashboard Reference in current environment: $($xmlDashboardReference.Name) (Id: $($xmlDashboardReference.Id))"
					$failureOccurred = $true
				}
				if (-NOT $failureOccurred)
				{
					$ret = $true
					[string]$sGuid = $xmlDashboardReference.Id
					if ($sGuid.length -ne 0)
					{
						$obj.Scope.DashboardReferences.Add($sGuid)
						$ret = try { $obj.Update() }
						catch { Write-Warning $_ }
						trap [Exception]{ continue }
						if (-NOT $ret)
						{
							$dashboardReferenceResult = $dashboardReferences | Where-Object { $_.Id -eq $xmlDashboardReference.Id -or $_.Name -eq $xmlDashboardReference.Name }
							Write-Host "         Adding Dashboard Reference: $($dashboardReferenceResult.Name) (Id: $($dashboardReferenceResult.Id))" -ForegroundColor Green
						}
						else
						{
							Write-Host "         No matching item found in Dashboard References: $($xmlDashboardReference.Name) (Id: $($xmlDashboardReference.Id))" -ForegroundColor Red
						}
					}
				}
				
			}
			else
			{
				$groupFound = $groups | Where-Object { $_.Id -eq $xmlDashboardReference.Id }
				if ($groupFound)
				{
					Write-Host "         Dashboard References already exists: $($groupFound.Name) (Id: $($groupFound.Id))" -ForegroundColor Gray
				}
			}
		}
	}
	$consoleTasks = $ms.TaskConfiguration.GetConsoleTasks()
	#Now Add Console Tasks
	if ($xml.ConsoleTask)
	{
		foreach ($xmlConsoleTasks in $xml.ConsoleTask)
		{
			$failureOccurred = $false
			$bFound = $false
			foreach ($consoleScope in $obj.Scope.ConsoleTask)
			{
				if ($xmlConsoleTasks.Id -eq $consoleScope.ToString())
				{
					$bFound = $true
				}
			}
			if (-NOT $bFound)
			{
				if ($consoleTasks.Name -notcontains $xmlConsoleTasks.Name -or $consoleTasks.Id -notcontains $xmlConsoleTasks.Id)
				{
					Write-Warning "Unable to locate Console Task in current environment: $($xmlDashboardReference.Name) (Id: $($xmlDashboardReference.Id))"
					$failureOccurred = $true
				}
				
				if (-NOT $failureOccurred)
				{
					$ret = $true
					[string]$sGuid = $xmlConsoleTasks.Id
					if ($sGuid.length -ne 0)
					{
						$obj.Scope.ConsoleTasks.Add($sGuid)
						$ret = try { $obj.Update() }
						catch { Write-Warning $_ }
						$consoleTaskResult = $consoleTasks | Where-Object { $_.Id -eq $xmlConsoleTasks.Id }
						if (-NOT $ret)
						{
							Write-Host "         Adding Console Tasks: $($consoleTaskResult.Name) (Id: $($consoleTaskResult.Id))" -ForegroundColor Green
						}
						else
						{
							Write-Host "         No matching item found in Console Tasks: $($consoleTaskResult.Name) (Id: $($consoleTaskResult.Id))" -ForegroundColor Red
						}
					}
				}
			}
			else
			{
				$consoleTasksFound = $consoleTasks | Where-Object { $_.Id -eq $xmlConsoleTasks.Id }
				if ($consoleTasksFound)
				{
					Write-Host "         Console Tasks already exists: $($consoleTasksFound.Name) (Id: $($consoleTasksFound.Id))" -ForegroundColor Gray
				}
			}
		}
	}
	$views = $ms.GetMonitoringViews()
	#Create generic type (used for views and tasks if there are any) 
	$genericType = [Type] "Microsoft.EnterpriseManagement.Common.Pair``2"
	$typeParameters = "System.Guid", "System.Boolean"
	[type[]]$typedParameters = $typeParameters
	$closedType = $genericType.MakeGenericType($typedParameters)
	#Now Add Views 
	if ($xml.MonitoringView)
	{
		foreach ($xmlView in $xml.MonitoringView)
		{
			$failureOccurred = $false
			$bFound = $false
			foreach ($consoleView in $obj.Scope.Views)
			{
				if ($xmlView.Id.ToString() -eq $consoleView.First.ToString())
				{
					$bFound = $true
				}
			}
			if (-NOT $bFound)
			{
				if ($views.Name -notcontains $xmlView.Name -or $views.Id -notcontains $xmlView.Id)
				{
					Write-Warning "Unable to locate Monitoring View in current environment: $($xmlConsoleTasks.Name) (Id: $($xmlConsoleTasks.Id))"
					$failureOccurred = $true
				}
				
				if (-NOT $failureOccurred)
				{
					$ret = $true
					if ($xmlView.Id.length -gt 1)
					{
						if (-NOT $xmlView.bool)
						{
							$second = $false
						}
						else
						{
							$second = $true
						}
						$params = [guid]$xmlView.Id, [boolean]$second
						$pair = [Activator]::CreateInstance($closedType, $params)
						$obj.Scope.Views.Add($pair)
						$ErrorActionPreference = 'Stop'
						$Error.Clear()
						$ret = try { $obj.Update() }
						catch { Write-Warning "$Error" }
						$ErrorActionPreference = 'Continue'
						
						$viewsResult = $views | Where-Object { $_.Id -eq $xmlView.Id }
						if (-NOT $ret)
						{
							Write-Host "         Adding View: $($viewsResult.DisplayName) (Name: $($viewsResult.Name), Id: $($viewsResult.Id))" -ForegroundColor Green
						}
						else
						{
							Write-Host "         No matching group found for View: $($xmlView.DisplayName)" -ForegroundColor Red
						}
					}
				}
				
			}
			else
			{
				$viewExists = $views | Where-Object { $_.Id -eq $xmlView.Id }
				if ($viewExists)
				{
					Write-Host "         Already exists in View: $($viewExists.Name) (Id: $($viewExists.Id))" -ForegroundColor Gray
				}
			}
		}
	}
	
	$SCOMTasks = $ms.TaskConfiguration.GetTasks()
	#Now Add NonCredentialTasks 
	if ($xml.NonCredentialMonitoringTask)
	{
		foreach ($xmlNonCred in $xml.NonCredentialMonitoringTask)
		{
			$ActualTaskName = $SCOMTasks | Where-Object { $_.Id -eq $xmlNonCred.Id }
			$bFound = $false
			foreach ($consoleNonCred in $obj.Scope.NonCredentialTasks)
			{
				if ($xmlNonCred.Id.ToString() -eq $consoleNonCred.First.ToString())
				{
					$bFound = $true
				}
			}
			if (-NOT $bFound)
			{
				$ret = $true
				if ($xmlNonCred.Id.length -gt 1)
				{
					if ($xmlNonCred.bool -eq $false)
					{
						$second = $false
					}
					$params = [guid]$xmlNonCred.Id, [boolean]$second
					$pair = [Activator]::CreateInstance($closedType, $params)
					$obj.Scope.NonCredentialTasks.Add($pair)
					$ret = try { $obj.Update() }
					catch { Write-Warning $_ }
					trap [Exception]{ continue }
					if (-NOT $ret)
					{
						Write-Host "         Adding NonCredTask: $($ActualTaskName.DisplayName)" -ForegroundColor Green
					}
					else
					{
						Write-Host "         No matching group NonCredTask: $($ActualTaskName.DisplayName)" -ForegroundColor Red
					}
				}
			}
			else
			{
				$actualNonCredTaskName = $ActualTaskName.DisplayName
				if ($actualNonCredTaskName)
				{
					Write-Host "         Already exists NonCredTask: $actualNonCredTaskName" -ForegroundColor Gray
				}
			}
		}
	}
	
	#Now Add CredentialTasks 
	if ($xml.CredentialMonitoringTask)
	{
		foreach ($xmlCred in $xml.CredentialMonitoringTask)
		{
			$ActualTaskName = $SCOMTasks | Where-Object { $_.Id -eq $xmlCred.Id }
			$bFound = $false
			foreach ($consoleCred in $obj.Scope.CredentialTasks)
			{
				if ($xmlCred.Id.ToString() -eq $consoleCred.First.ToString())
				{
					$bFound = $true
				}
			}
			if (-NOT $bFound)
			{
				$ret = $true
				if ($xmlCred.Task.length -gt 1)
				{
					if ($xmlCred.bool -eq $false)
					{
						$second = $false
					}
					$params = [guid]$xmlCred.Task, [boolean]$second
					$pair = [Activator]::CreateInstance($closedType, $params)
					$obj.Scope.CredentialTasks.Add($pair)
					$ret = $obj.Update()
					trap [Exception]{ continue }
					if (-NOT $ret)
					{
						Write-Host "         Adding new CredTask: $($ActualTaskName.DisplayName)" -ForegroundColor Green
					}
					else
					{
						Write-Host "         No matching group found for CredTask: $($ActualTaskName.DisplayName)"
					}
				}
			}
			else
			{
				Write-Host "         Already exists CredTask: $($ActualTaskName.DisplayName)"
			}
		}
	}
	$ErrorActionPreference = 'Stop'
	$Error.Clear()
	try
	{
		#First add users 
		foreach ($xmlConsoleUser in $xml.User)
		{
			$bFound = $false
			foreach ($consoleUser in $obj.Users)
			{
				if ($xmlConsoleUser.UserName -eq $consoleUser)
				{
					$bFound = $true
				}
			}
			if (-NOT $bFound)
			{
				if ($xmlConsoleUser.UserName.length -gt 1)
				{
					Write-Host "         Adding User: $($xmlConsoleUser.UserName)" -ForegroundColor Green
					$obj.Users.Add($xmlConsoleUser.UserName)
					
					$obj.Update()
				}
			}
			else
			{
				Write-Host "         User already in User Role: $($xmlConsoleUser.UserName)" -ForegroundColor Gray
			}
		}
	}
	catch
	{
		Write-Host "         Unable to add User to User Role: $($xmlConsoleUser.UserName)" -ForegroundColor Red
		Write-Warning "$_"
	}
	$ErrorActionPreference = 'Continue'
}
function Create-SCOMUserRole([System.Object]$xml)
{
	#Create a new User Role Object 
	$obj = new-object Microsoft.EnterpriseManagement.Monitoring.Security.MonitoringUserRole
	#Populate the common fields for the UserRole 
	$obj.Name = $xml.Name
	$obj.DisplayName = $xml.DisplayName
	$obj.Description = $xml.Description
	$xml.DashboardReference.Id | Foreach-Object { if ($_) { $obj.Scope.DashboardReferences.Add("$_") } }
	$xml.ConsoleTask.Id | Foreach-Object { if ($_) { $obj.Scope.ConsoleTasks.Add("$_") } }
	$xml.Template.Id | Foreach-Object { if ($_) { $obj.Scope.Templates.Add("$_") } }
	$xml.MonitoringView.Id | Foreach-Object { if ($_) { $obj.Scope.Views.Add("$_") } }
	
	$profile = $ms.GetMonitoringProfiles() | Where-Object { $_.Name -eq $xml.Profile }
	$obj.Profile = $profile
	try
	{
		$ms.InsertMonitoringUserRole($obj)
	}
	catch { Write-Warning "$_" }
	#Now Replicate the rights associated with this role 
	Write-Host "          $($xml.Name) - New user role created!" -ForegroundColor Green
	Invoke-ReplicateUserRoleRights $xml
}
#Imports Roles from XML in Management Group 
function Import-SCOMUserRoles($UserRoles)
{
	#Get existing User Roles 
	$existingUserRoles = $ms.GetMonitoringUserRoles()
	#Loop through each user role 
	$UserRoles = $UserRoles.SelectNodes("UserRoles/UserRole")
	foreach ($UserRole in $UserRoles)
	{
		#Check to see if user already exists 
		$bFound = $false
		foreach ($eu in $existingUserRoles)
		{
			if ($UserRole.Name -eq $eu.Name)
			{
				Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkCyan
				Write-Host "        $($UserRole.DisplayName) - User role already exists" -ForegroundColor Cyan
				$bFound = $true
				Invoke-ReplicateUserRoleRights $UserRole
			}
		}
		if (-NOT $bFound)
		{
			#Create new role 
			Write-Host "        $($UserRole.DisplayName) - Creating new user role" -ForegroundColor Green
			Create-SCOMUserRole $UserRole
		}
	}
}
#endregion
# -----------------------------------------------

Import-SCOMModule

$ms = Get-SCOMManagementServerConnection $env:COMPUTERNAME

if (-NOT $ms) { throw ("Error connecting to Management Server") }
Write-Host "Importing XML from here: $ImportPath" -ForegroundColor Gray
#Open XML file 
$UserRoleData = New-Object "System.Xml.XmlDocument"
$UserRoleData.load($ImportPath)

if ($UserRoleDisplayNameToImport -eq 'All')
{
	# Import All User Roles
	Write-Host "  Processing the User Roles for Import" -ForegroundColor Cyan
	$UserRoleData | ForEach-Object {
		Write-Host "      $($_.DisplayName)" -ForegroundColor Magenta
	}
	Import-SCOMUserRoles $UserRoleData
}
else
{
	# Import only specific User Roles
	Write-Host "Processing the User Role for Import"
	foreach ($UserRoleName in $UserRoleDisplayNameToImport)
	{
		$UserRoleData | Where-Object { $_.DisplayName -eq $UserRoleName } | ForEach-Object {
			Write-Host "      $($_.DisplayName)" -ForegroundColor Magenta
			Import-SCOMUserRoles $_
		}
	}
}
