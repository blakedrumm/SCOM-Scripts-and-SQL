# Author: Blake Drumm (blakedrumm@microsoft.com)
# Date created: February 29th, 2024
# Description: This script will allow you to make the System Center Operations Manager PowerShell module portable. It will zip up the output folder and all you have to do is run the Install-SCOMModule.ps1 file 
#              on the remote machine where you want to install the SCOM PowerShell module. (the Install-SCOMModule.ps1 file is located in the output folder / zip.)

#---------------------------------------------
# Variables to edit
# Define the folder path
$folderPath = "C:\Temp\SCOM-PowerShellModule"
# Define the zip file path for output
$zipFilePath = "C:\Temp\SCOM-PowerShellModule.zip"
#---------------------------------------------

# The path to the Powershell folder in the SCOM installation folder
$powerShellFolder = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2" -Name InstallDirectory
# Uncomment the below to force the path to a specific directory, instead of detecting automatically from the registry.
#$powerShellFolder = "C:\Program Files\Microsoft System Center\Operations Manager\Powershell"
Write-Output "PowerShell folder path: $powerShellFolder"

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

Get-ChildItem 'C:\Windows\Microsoft.NET\assembly\GAC_MSIL\Microsoft.EnterpriseManagement*' | ForEach-Object {
	Copy-Item -Path $_.FullName -Destination $folderPath -Force -Recurse
}

Write-Output "  - Copied the required GAC_MSIL files."

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

# Create a text file with the $powerShellFolder path inside the $folderPath
Set-Content -Path "$folderPath\PowerShellFolderInfo.txt" -Value "$powerShellFolder"

Set-Content -Path "$folderPath\Install-SCOMModule.ps1" -Value @"
[CmdletBinding()]
param ()

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
	Write-Warning "This script must be run as an administrator!"
	return
}

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
		Write-Output "  - .NET Framework 4.7.2 is installed."
	}
	elseif (`$versionValue -eq 528040)
	{
		Write-Output "  - .NET Framework 4.8 is installed."
	}
	elseif (`$versionValue -gt 528040)
	{
		Write-Output "  - Higher than .NET Framework 4.8 is installed. Unable to proceed."
		return
	}
	else
	{
		Write-Warning "Neither .NET Framework 4.7.2 nor 4.8 is installed. Unable to proceed."
		return
	}
}
else
{
	Write-Warning "Unable to find .NET Framework 4.x installation. Unable to proceed."
	return
}


`$powerShellFolder = Get-Content .\PowerShellFolderInfo.txt
try
{
	`$gacPath = (Resolve-Path "C:\Windows\Microsoft.NET\assembly\GAC_MSIL" -ErrorAction Stop).Path
}
catch
{
	Write-Warning "Unable to locate the path: 'C:\Windows\Microsoft.NET\assembly\GAC_MSIL'. Unable to proceed."
	return
}
Get-ChildItem ".\Microsoft.EnterpriseManagement*" | % {
	`$resolvePath = Resolve-Path `$gacPath\`$(`$_.Name)
	if (-NOT `$resolvePath)
	{
		Copy-Item -Path `$_.FullName -Destination `$gacPath -Force -Recurse
	}
}
Copy-Item -Path .\Powershell\ -Destination `$powerShellFolder -Force -Recurse

`$p = [Environment]::GetEnvironmentVariable("PSModulePath")
if (-NOT `$p -contains `$powerShellFolder)
{
	`$p += ";`$powerShellFolder"
	[Environment]::SetEnvironmentVariable("PSModulePath", `$p, 'Machine')
	Write-Output "  - Added module to the machine level environmental variable (PSModulePath)"
}
else
{
	Write-Output "  - Module is already in the machine level environmental variable (PSModulePath)"
}
try
{
	Import-Module OperationsManager -Verbose -ErrorAction Stop
}
catch
{
	Write-Warning "Unable to import the SCOM PowerShell Module!`n`$_"
	return
}
Write-Output "Completed importing the SCOM PowerShell Module!
"@

Set-Content -Path "$folderPath\Readme.txt" -Value @"
In order to install the SCOM PowerShell Module on a machine, run the PowerShell script 'Install-SCOMModule.ps1' as Administrator.
"@

# Zip the folder, including the text file
Compress-Archive -Path "$folderPath\*" -DestinationPath $zipFilePath -Force

Write-Output "Output File: '$zipFilePath'"
