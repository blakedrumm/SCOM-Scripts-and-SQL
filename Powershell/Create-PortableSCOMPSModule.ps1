# Author: Blake Drumm (blakedrumm@microsoft.com)
# Date created: February 29th, 2024
# Date modified: March 23rd, 2024
# Description: This script will allow you to make the System Center Operations Manager PowerShell module portable. 
#              Run this on a server that is a SCOM Management Server or has the Console installed on it. The script will 
#              zip up the output folder and all you have to do is copy the zip to a remote machine (where you want to install
#              the SCOM PowerShell Module), extract it, and run the Install-SCOMModule.ps1 file (as Administrator). (The Install-SCOMModule.ps1 file is located in the output folder / zip.)

#---------------------------------------------
# Variables to edit
# Define the folder path
$folderPath = "C:\Temp\SCOM-PowerShellModule"
# Define the zip file path for output
$zipFilePath = "C:\Temp\SCOM-PowerShellModule.zip"
#---------------------------------------------

# The path to the Powershell folder in the SCOM installation folder
$powerShellFolder = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2" -Name InstallDirectory
$serverFolder = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Server" -Name InstallDirectory
$consoleFolder = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Console" -Name InstallDirectory
# Uncomment the below to force the path to a specific directory, instead of detecting automatically from the registry.
#$powerShellFolder = "C:\Program Files\Microsoft System Center\Operations Manager\Powershell"
Write-Output "PowerShell folder path: $powerShellFolder"
Write-Output "Server folder path: $serverFolder"
Write-Output "Console folder path: $consoleFolder"

# Check if the folder exists
if (-Not (Test-Path -Path $folderPath))
{
	# Folder does not exist, so create it
	New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
	Write-Output "Output folder '$folderPath' has been created."
}
else
{
	# Folder already exists
	Write-Output "Output folder '$folderPath' already exists."
}

if (-Not (Test-Path -Path $folderPath\Server))
{
	# Folder does not exist, so create it
	New-Item -ItemType Directory -Path $folderPath\Server -Force | Out-Null
	Write-Output "Output folder '$folderPath\Server' has been created."
	
	$langCodes = @(
		'cs',
		'de',
		'en',
		'es',
		'FR',
		'HU',
		'IT',
		'JA',
		'KO',
		'NL',
		'PL',
		'pt-BR',
		'pt-PT',
		'RU',
		'SV',
		'TR',
		'zh-CHS',
		'zh-CHT',
		'zh-HK'
	)
	
	$langCodes | ForEach-Object { New-Item -ItemType Directory -Path $folderPath\Server\$_ -Force | Out-Null }
}
else
{
	# Folder already exists
	Write-Output "Output folder '$folderPath\Server' already exists."
}

if (-Not (Test-Path -Path $folderPath\Console))
{
	# Folder does not exist, so create it
	New-Item -ItemType Directory -Path $folderPath\Console -Force | Out-Null
	Write-Output "Output folder '$folderPath\Console' has been created."
}
else
{
	# Folder already exists
	Write-Output "Output folder '$folderPath\Console' already exists."
}

Get-ChildItem 'C:\Windows\Microsoft.NET\assembly\GAC_MSIL\Microsoft.EnterpriseManagement*' | ForEach-Object {
	Copy-Item -Path $_.FullName -Destination $folderPath -Force -Recurse
}

Write-Output "  - Copied the required GAC_MSIL files."

# PowerShell Folder Path
try
{
	$resolvedPath = (Resolve-Path -Path $powerShellFolder -ErrorAction Stop).Path
	Copy-Item -Path $resolvedPath -Destination $folderPath -Recurse -Force
}
catch
{
	Write-Warning "Unable to locate the path '$powerShellFolder'!"
	break
}

# Server Folder Path
try
{
	$resolvedPath = (Resolve-Path -Path $serverFolder -ErrorAction Stop).Path
	Copy-Item -Path "$resolvedPath\Microsoft.Mom.Common.dll" -Destination $folderPath\Server -Force
	Copy-Item -Path "$resolvedPath\Microsoft.EnterpriseManagement.DataAccessLayer.dll" -Destination $folderPath\Server -Force
	Copy-Item -Path "$resolvedPath\Microsoft.EnterpriseManagement.DataAccessService.Core.dll" -Destination $folderPath\Server -Force
	Copy-Item -Path "$resolvedPath\Microsoft.Mom.Sdk.Authorization.dll" -Destination $folderPath\Server -Force
	$langCodes | ForEach-Object { Copy-Item -Path "$resolvedPath\$_" -Destination $folderPath\Server -Force }
	Write-Output "  - Copied the required Management Server DLL files."
}
catch
{
	Write-Warning "Unable to locate the path '$serverFolder'!"
	break
}

# Console Folder Path
try
{
	$resolvedPath = (Resolve-Path -Path $consoleFolder -ErrorAction Stop).Path
	Copy-Item -Path $resolvedPath\Microsoft.Mom.Common.dll -Destination $folderPath\Console -Recurse -Force
	Write-Output "  - Copied the required Operations Manager Console DLL files."
}
catch
{
	Write-Warning "Unable to locate the path '$consoleFolder'!"
	break
}

# Create a text file with the $powerShellFolder path inside the $folderPath
Set-Content -Path "$folderPath\PowerShellFolderInfo.txt" -Value "$powerShellFolder"

Set-Content -Path "$folderPath\ServerFolderInfo.txt" -Value "$serverFolder"

Set-Content -Path "$folderPath\ConsoleFolderInfo.txt" -Value "$consoleFolder"

Set-Content -Path "$folderPath\Install-SCOMModule.ps1" -Value @"
[CmdletBinding()]
param
(
	[Parameter(Mandatory = `$false)]
	[ValidateSet('Install', 'Uninstall')]
	`$Action = 'Install'
)
function Time-Stamp
{
	`$todaysDate = (Get-Date)
	return "`$(`$todaysDate.ToLocalTime().ToShortDateString()) @ `$(`$todaysDate.ToLocalTime().ToLongTimeString()) - "
}
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
	Write-Warning "`$(Time-Stamp)This script must be run as an administrator!"
	return
}

if (-NOT `$PSScriptRoot)
{
	`$Path = `$PWD.Path
}
else
{
	`$Path = `$PSScriptRoot
}

[System.Reflection.Assembly]::Load("System.EnterpriseServices, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
`$publish = New-Object System.EnterpriseServices.Internal.Publish

<#
# Define the registry path where .NET Framework versions are stored
`$regPath = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\"

# Check if the registry path exists
if (Test-Path `$regPath)
{
	# Get the version value from the registry
	`$versionValue = Get-ItemProperty -Path `$regPath -Name "Release" | Select-Object -ExpandProperty "Release"
	
	# Check the version value for .NET Framework 4.7.2 or 4.8
	# .NET Framework 4.7.2 release key: 461808
	# .NET Framework 4.8 release key: 528040
	if (`$versionValue -ge 461808 -and `$versionValue -lt 528040)
	{
		Write-Output "`$(Time-Stamp)  - .NET Framework 4.7.2 is installed."
	}
	elseif (`$versionValue -eq 528040)
	{
		Write-Output "`$(Time-Stamp)  - .NET Framework 4.8 is installed."
	}
	elseif (`$versionValue -gt 528040)
	{
		Write-Output "`$(Time-Stamp)  - Higher than .NET Framework 4.8 is installed. Unable to proceed."
		return
	}
	else
	{
		Write-Warning "`$(Time-Stamp)Neither .NET Framework 4.7.2 nor 4.8 is installed. Unable to proceed."
		return
	}
}
else
{
	Write-Warning "`$(Time-Stamp)Unable to find .NET Framework 4.x installation. Unable to proceed."
	return
}
#>

`$powerShellFolder = Get-Content `$Path\PowerShellFolderInfo.txt
`$serverFolder = Get-Content `$Path\ServerFolderInfo.txt
`$consoleFolder = Get-Content `$Path\ConsoleFolderInfo.txt

try
{
	`$gacPath = (Resolve-Path "C:\Windows\Microsoft.NET\assembly\GAC_MSIL" -ErrorAction Stop).Path
}
catch
{
	Write-Warning "`$(Time-Stamp)Unable to locate the path: 'C:\Windows\Microsoft.NET\assembly\GAC_MSIL'. Unable to proceed."
	return
}
if (`$Action -eq 'Install')
{
	Get-ChildItem "`$Path\Microsoft.EnterpriseManagement*" | % {
		`$resolvePath = Resolve-Path `$gacPath\`$(`$_.Name) -ErrorAction SilentlyContinue
		if (-NOT `$resolvePath)
		{
			`$publish.GacInstall("`$(`$_.FullName)")
			#Copy-Item -Path `$_.FullName -Destination `$gacPath -Force -Recurse
		}
	}
	New-Item -Path `$powerShellFolder -ItemType Directory -Force | Out-Null
	Copy-Item -Path "`$Path\Powershell\*" -Destination `$powerShellFolder -Force -Recurse
	
	New-Item -Path `$serverFolder -ItemType Directory -Force | Out-Null
	Copy-Item -Path "`$Path\Server\*" -Destination `$serverFolder -Force -Recurse
	
	New-Item -Path `$consoleFolder -ItemType Directory -Force | Out-Null
	Copy-Item -Path "`$Path\Console\*" -Destination `$consoleFolder -Force -Recurse
	
	# Get current PSModulePath and split into an array
	`$envVariableArray = [Environment]::GetEnvironmentVariable("PSModulePath", "Machine") -split ';'
	
	# Check if `$powerShellFolder is already in the array
	if (`$envVariableArray -notcontains `$powerShellFolder)
	{
		# If not, add it to the array
		`$envVariableArray += `$powerShellFolder
		
		# Rejoin the array into a string with ";" and set the environment variable
		`$newEnvVariable = `$envVariableArray -join ';'
		[Environment]::SetEnvironmentVariable("PSModulePath", `$newEnvVariable, "Machine")
		
		Write-Output "`$(Time-Stamp) - Added module to the machine level environmental variable (PSModulePath)"
	}
	else
	{
		Write-Output "`$(Time-Stamp) - Module is already in the machine level environmental variable (PSModulePath)"
	}
<#
try
{
	Import-Module OperationsManager -Verbose -ErrorAction Stop
}
catch
{
	Write-Warning "`$(Time-Stamp)Unable to import the SCOM PowerShell Module!`n`$_"
	return
}
Write-Output "`$(Time-Stamp)Completed importing the SCOM PowerShell Module!"
#>
	Write-Output "`$(Time-Stamp)Close this window and reopen a new PowerShell window. Run the following command to import the Operations Manager PowerShell module: Import-Module OperationsManager"
}
elseif (`$Action -eq 'Uninstall')
{
	Get-ChildItem "`$Path\Microsoft.EnterpriseManagement*" | % {
		`$resolvedPath = (Resolve-Path `$gacPath\`$(`$_.Name) -ErrorAction SilentlyContinue)
		if (`$resolvedPath)
		{
			`$publish.GacRemove("`$resolvedPath")
			`$publish.UnRegisterAssembly()
		}
	}
	
	`$resolvedPath = Resolve-Path `$serverFolder -ErrorAction SilentlyContinue
	if (`$resolvedPath)
	{
		Remove-Item -Path `$resolvedPath -Force -Recurse
	}
	
	`$resolvedPath = Resolve-Path `$consoleFolder -ErrorAction SilentlyContinue
	if (`$resolvedPath)
	{
		Remove-Item -Path `$resolvedPath -Force -Recurse
	}
	
	`$resolvedPath = Resolve-Path `$powerShellFolder -ErrorAction SilentlyContinue
	if (`$resolvedPath)
	{
		Remove-Item -Path `$resolvedPath -Force -Recurse
	}
	Write-Output "`$(Time-Stamp)Completed removing the SCOM PowerShell Module!"
}
"@

Set-Content -Path "$folderPath\Readme.txt" -Value @"
In order to install the SCOM PowerShell Module on a machine, run the PowerShell script 'Install-SCOMModule.ps1' as Administrator.
"@

# Zip the folder, including the text file
Compress-Archive -Path "$folderPath\*" -DestinationPath $zipFilePath -Force

Write-Output "Output File: '$zipFilePath'"
