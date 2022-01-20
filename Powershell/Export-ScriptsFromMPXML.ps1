<#
	.SYNOPSIS
		Dump Scripts from inside of XML Management Packs for System Center Operations Manager
	
	.DESCRIPTION
		Export Scripts from inside of XML Management Packs. This will make it easier to troubleshoot issues with scripts in Discoveries, Monitors, 
	
	.PARAMETER SourceXML
		The location of the XML Management Pack file that contains scripts you would like to export.
	
	.PARAMETER ExportLocation
		The location of Folder you would like to exports scripts contained inside the Management Pack XML file.
	
	.EXAMPLE
			PS C:\> .\Export-ScriptsFromMPXML.ps1 -SourceXML C:\Temp\ManagementPack.xml -ExportLocation C:\Temp\MPScripts
	
	.NOTES
		Original Author: Udish Mudiar
		Original Location: https://github.com/Udish17/SCOM-PowerShell-Scripts/blob/SCOM-PowerShell-Scripts/master/DumpScriptsfromSCOMMP.ps1
#>
[CmdletBinding()]
[OutputType([string])]
param
(
	[Parameter(Mandatory = $true,
			   Position = 0,
			   HelpMessage = 'The location of the XML Management Pack file that contains scripts you would like to export.')]
	[Alias('input')]
	[String[]]$SourceXML,
	[Parameter(Mandatory = $true,
			   Position = 1,
			   HelpMessage = 'The location you would like to exports scripts contained inside the Management Pack XML file.')]
	[Alias('outputdirectory')]
	[String[]]$ExportLocation
)

[xml]$xmlcontent = Get-Content $SourceXML

#region Dump-DS-ProbeAction
#This will dump only the scripts which are defined inside Data Source ProbeAction
$probeactions = $xmlcontent.selectnodes('//ManagementPack/TypeDefinitions/ModuleTypes/DataSourceModuleType/ModuleImplementation/Composite/MemberModules/ProbeAction')
if ($probeactions)
{
	foreach ($probeaction in $probeactions)
	{
		
		if ($probeaction.TypeID -match "PowerShell")
		{
			$scriptname = $probeaction.ScriptName
			Write-Host "Script found. Dumping Script....    " $scriptname -ForegroundColor Green
			#write this condition because in some case the developers has added the script extension in the script name itself
			
			if ($scriptname -match ".ps1")
			{
				
				$probeaction.scriptbody | Out-File $ExportLocation\$scriptname
			}
			elseif ($scriptname -match ".vbs")
			{
				$probeaction.scriptbody | Out-File $ExportLocation\$scriptname
			}
			elseif ($scriptname -match ".js")
			{
				$probeaction.scriptbody | Out-File $ExportLocation\$scriptname
			}
			else
			{
				$scripttype = $probeaction.ID + "1"
				$probeaction.scriptbody | Out-File $ExportLocation\$scriptname.$scripttype
			}
		}
		
	}
}
#endregion Dump-DS-ProbeAction

#region Dump-DS-Files
#This script will dump only the scripts which are defined inside Data Source Files/File
$files = $xmlcontent.selectnodes('//ManagementPack/TypeDefinitions/ModuleTypes/DataSourceModuleType/ModuleImplementation/Composite/MemberModules/DataSource/Files/File')

if ($files)
{
	foreach ($file in $files)
	{
		$scriptname = $file.name
		if ($scriptname -match "ps1")
		{
			Write-Host "Script found. Dumping Script....    " $scriptname -ForegroundColor Green
			$file.Contents | Out-File $ExportLocation\$scriptname
		}
		if ($scriptname -match "cmd")
		{
			Write-Host "Script found. Dumping Script....    " $scriptname -ForegroundColor Green
			$file.Contents | Out-File $ExportLocation\$scriptname
		}
		if ($scriptname -match "vbs")
		{
			Write-Host "Script found. Dumping Script....    " $scriptname -ForegroundColor Green
			$file.Contents | Out-File $ExportLocation\$scriptname
		}
	}
}
#endregion Dump-DS-Files

#region Dump-DS-WriteAction
#This script will dump only the scripts which are defined inside WriteAction 
$writeactions = $xmlcontent.selectnodes('//ManagementPack/TypeDefinitions/ModuleTypes/WriteActionModuleType/ModuleImplementation/Composite/MemberModules/WriteAction')
if ($writeactions)
{
	foreach ($writeaction in $writeactions)
	{
		$scriptname = $writeaction.ScriptName
		if ($writeaction.TypeID -match "script")
		{
			Write-Host "Script found. Dumping Script....    " $scriptname -ForegroundColor Green
			$writeaction.scriptbody | Out-File $ExportLocation\$scriptname
		}
		
		
	}
}
#endregion Dump-DS-WriteAction

#region Dump-DS-DataSource
#This script will dump only the scripts which are defined inside Data Source Files/File
$datasources = $xmlcontent.selectnodes('//ManagementPack/TypeDefinitions/ModuleTypes/DataSourceModuleType/ModuleImplementation/Composite/MemberModules/DataSource')

if ($datasources)
{
	foreach ($datasource in $datasources)
	{
		if ($datasource.TypeID -match "Script" -and $datasource.ScriptName -ne $null)
		{
			$scriptname = $datasource.ScriptName
			Write-Host "Script found. Dumping Script....    " $scriptname -ForegroundColor Green
			$writeaction.scriptbody | Out-File $ExportLocation\$scriptname
		}
	}
}



#endregion Dump-DS-DataSource

#region Dump-DS-ProbeAction-Files
#This will dump only the scripts which are defined inside Data Source ProbeAction
$probeactionfiles = $xmlcontent.selectnodes('//ManagementPack/TypeDefinitions/ModuleTypes/DataSourceModuleType/ModuleImplementation/Composite/MemberModules/ProbeAction/Files/File')
if ($probeactionfiles)
{
	foreach ($probeactionfile in $probeactionfiles)
	{
		$scriptname = $probeactionfile.name
		if ($scriptname -match "ps1")
		{
			Write-Host "Script found. Dumping Script....    " $scriptname -ForegroundColor Green
			$probeactionfile.Contents | Out-File $ExportLocation\$scriptname
		}
		elseif ($scriptname -match "cmd")
		{
			Write-Host "Script found. Dumping Script....    " $scriptname -ForegroundColor Green
			$probeactionfile.Contents | Out-File $ExportLocation\$scriptname
		}
		elseif ($scriptname -match "vbs")
		{
			Write-Host "Script found. Dumping Script....    " $scriptname -ForegroundColor Green
			$probeactionfile.Contents | Out-File $ExportLocation\$scriptname
		}
	}
}

#endregion Dump-DS-ProbeAction-Files

#region Dump-PA-ProbeAction
#This will dump only the scripts which are defined inside Probe Action Module Type
$probeactionmodules = $xmlcontent.selectnodes('//ManagementPack/TypeDefinitions/ModuleTypes/ProbeActionModuleType/ModuleImplementation/Composite/MemberModules/ProbeAction')
if ($probeactionmodules)
{
	foreach ($probeactionmodule in $probeactionmodules)
	{
		if ($probeactionmodule.TypeID -match "Script")
		{
			$scriptname = $probeactionmodule.ScriptName
			if ($scriptname -match "/")
			{
				Write-Host "Script found. But not dumping script as the script name is passed as a config item....    " -ForegroundColor Cyan
				
			}
			else
			{
				Write-Host "Script found. Dumping Script....    " $scriptname -ForegroundColor Green
				$probeactionmodule.scriptbody | Out-File $ExportLocation\$scriptname
			}
		}
	}
}
#endregion Dump-PA-ProbeAction

#region Dump-Discovery-DS-Files
#This will dump only the scripts which are defined inside Discovery Data Source Files
$discoverydatasourcefiles = $xmlcontent.selectnodes('//ManagementPack/Monitoring/Discoveries/Discovery/DataSource/Files/File')
if ($discoverydatasourcefiles)
{
	foreach ($discoverydatasourcefile in $discoverydatasourcefiles)
	{
		$scriptname = $discoverydatasourcefile.name
		if ($scriptname -match "ps1")
		{
			Write-Host "Script found. Dumping Script....    " $scriptname -ForegroundColor Green
			$discoverydatasourcefile.Contents | Out-File $ExportLocation\$scriptname
		}
		elseif ($scriptname -match "cmd")
		{
			Write-Host "Script found. Dumping Script....    " $scriptname -ForegroundColor Green
			$discoverydatasourcefile.Contents | Out-File $ExportLocation\$scriptname
		}
		if ($scriptname -match "vbs")
		{
			Write-Host "Script found. Dumping Script....    " $scriptname -ForegroundColor Green
			$discoverydatasourcefile.Contents | Out-File $ExportLocation\$scriptname
		}
	}
}
#endregion Dump-Discovery-DS-Files

#region Dump-Monitor-Script
$unitmonitorconfigurations = $xmlcontent.selectnodes('//ManagementPack/Monitoring/Monitors/UnitMonitor/Configuration')
if ($unitmonitorconfigurations)
{
	foreach ($unitmonitorconfiguration in $unitmonitorconfigurations)
	{
		$scriptname = $unitmonitorconfiguration.scriptname
		if ($scriptname)
		{
			Write-Host "Script found. Dumping Script....    " $scriptname -ForegroundColor Green
			$unitmonitorconfiguration.scriptbody | Out-File $ExportLocation\$scriptname
		}
	}
}
#endregion Dump-Monitor-Script

#region NoDump
$content = Get-ChildItem $ExportLocation
if (!$content)
{
	Write-Host "No scripts are dumped for the Management Pack" -ForegroundColor Cyan
}
#endregion NoDump
