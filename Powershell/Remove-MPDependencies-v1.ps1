<#
	.SYNOPSIS
		Remove-MPDependencies-v1.ps1
	
	.DESCRIPTION
		Programatically / Recursively remove Management Packs from your SCOM Environment.
	
	.PARAMETER ExportPath
		Where to export the Unsealed / Sealed Management Packs (both will be unsealed)
	
	.PARAMETER ManagementPackId
		ex: b02631ec-9672-6309-04cb-9d38ced8e067
	
	.PARAMETER ManagementPackName
		ex: Microsoft.Azure.ManagedInstance.Discovery
	
	.PARAMETER RemoveUnsealedReferenceAndReimport
		This allows you to remove references from unsealed Management Packs.
	
	.EXAMPLE
		Remove Microsoft.SQLServer.Windows.Discovery MP piped from Get-SCOMManagementPack:
		PS C:\> Get-SCOMManagementPack -Name Microsoft.SQLServer.Windows.Discovery | .\Remove-MPDependencies.ps1
		
		Remove Microsoft.SQLServer.Windows.Discovery MP:
		PS C:\> .\Remove-MPDependencies.ps1 -Name Microsoft.SQLServer.Windows.Discovery
		
		Remove 'Microsoft SQL Server on Windows*':
		PS C:\> .\Remove-MPDependencies.ps1 -Name 'Microsoft SQL Server on Windows*'

      .NOTES
	        Author: Blake Drumm (blakedrumm@microsoft.com)
	        Modified: September 14th, 2023
	        Hosted here: https://github.com/blakedrumm/SCOM-Scripts-and-SQL/blob/master/Powershell/Remove-MPDependencies-v1.ps1
#>
param
(
	[Parameter(Position = 1)]
	[string]$ExportPath = "$env:USERPROFILE\Desktop",
	[Parameter(ValueFromPipeline = $true,
			   Position = 2,
			   HelpMessage = 'ex: b02631ec-9672-6309-04cb-9d38ced8e067')]
	[Alias('Id')]
	$ManagementPackId,
	[Parameter(ValueFromPipeline = $true,
			   Position = 3,
			   HelpMessage = 'ex: Microsoft.Azure.ManagedInstance.Discovery')]
	[Alias('Name')]
	$ManagementPackName,
	[Parameter(Position = 4,
			   HelpMessage = 'This allows you to remove and references from unsealed Management Packs.')]
	$RemoveUnsealedReferenceAndReimport
)
begin
{
	Function Time-Stamp
	{
		$TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
		return "$TimeStamp - "
	}
	Write-Output "$(Time-Stamp)Starting Script"
}
PROCESS
{
	function Remove-SCOMManagementPackDependencies
	{
		param
		(
			[Parameter(Position = 1)]
			[string]$ExportPath = "$env:USERPROFILE\Desktop",
			[Parameter(ValueFromPipeline = $true,
					   Position = 2,
					   HelpMessage = 'ex: b02631ec-9672-6309-04cb-9d38ced8e067')]
			[Alias('Id')]
			$ManagementPackId,
			[Parameter(ValueFromPipeline = $true,
					   Position = 3,
					   HelpMessage = 'ex: Microsoft.Azure.ManagedInstance.Discovery')]
			[Alias('Name')]
			$ManagementPackName,
			[Parameter(Position = 4)]
			$RemoveUnsealedReferenceAndReimport
		)
		
		Write-Output "$(Time-Stamp)Gathering Management Pack Recursive Dependencies for '$(if ($ManagementPackName) { $ManagementPackName }
			elseif ($ManagementPackId) { $ManagementPackId })'"
		try
		{
			if ($ManagementPackName)
			{
				if ($ManagementPackName.Name)
				{
					$recurseMPList = Get-SCManagementPack -Name $ManagementPackName.Name -Recurse
				}
				else
				{
					if ($ManagementPackName -match "\s")
					{
						$recurseMPList = Get-SCManagementPack -DisplayName $ManagementPackName -Recurse
					}
					else
					{
						$recurseMPList = Get-SCManagementPack -Name $ManagementPackName -Recurse
					}
					
				}
				
			}
			elseif ($ManagementPackId)
			{
				if ($ManagementPackId.Id)
				{
					$recurseMPList = Get-SCManagementPack -Id $ManagementPackId.Id -Recurse
				}
				else
				{
					$recurseMPList = Get-SCManagementPack -Id $ManagementPackId -Recurse
				}
			}
		}
		catch
		{
			Write-Warning "$(Time-Stamp)Unable to run `'Get-SCOMManagementPack`', stopping script:`n$($error[0])"
			break
		}
		if ($recurseMPList.Count -eq 0)
		{
			Write-Output "$(Time-Stamp)Did not find any Management Packs!"
			return
		}
		$sealedMPs = $recurseMPList.Where({ $_.Sealed })
		$unsealedMPs = $recurseMPList.Where({ !$_.Sealed })
		Write-Output "$(Time-Stamp)Sealed MPs: (Count: $($sealedMPs.Count)):"
		$sealedMPs | Select-Object -Property Name, Id, Version | Format-Table * -AutoSize
		Write-Output "$(Time-Stamp)Unsealed MPs (Count: $($unsealedMPs.Count)):"
		$unsealedMPs | Select-Object -Property Name, Id, Version | Format-Table * -AutoSize
		$(if ($RemoveUnsealedReferenceAndReimport) { $Action = 'Edit' }
			else { $Action = 'Remove' })
		
		$title = "Uninstall/$Action Management Packs"
		$message = "Do you want to uninstall/$($Action.ToLower()) the $($recurseMPList.Count) management packs?"
		
		$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Uninstall (Sealed) / $Action (Unsealed) selected Management Packs."
		$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Do not remove Management Packs and stop script."
		$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
		
		$result = $host.ui.PromptForChoice($title, $message, $options, 0)
		
		function Inner-RemoveMP
		{
			param
			(
				[Parameter(Mandatory = $true,
						   Position = 1)]
				[string]$ExportPath,
				[Parameter(Mandatory = $true,
						   ValueFromPipeline = $true,
						   Position = 2)]
				$ManagementPack,
				[Parameter(Mandatory = $false,
						   Position = 3)]
				[string]$ReferenceToRemove,
				[Parameter(Position = 4)]
				[switch]$RemoveUnsealedReferenceAndReimport,
				[Parameter(Mandatory = $false,
						   Position = 5)]
				[switch]$Sealed,
				[Parameter(Mandatory = $false,
						   Position = 6)]
				[switch]$Unsealed
			)
			PROCESS
			{
				
				trap
				{
					Write-Warning "$($PSItem.Exception) `nFunction: Inner-RemoveMP"
				}
				Write-Output "$(Time-Stamp)Backing up the following: $($ManagementPack.DisplayName)"
				$ManagementPack | Export-SCOMManagementPack -Path $ExportPath -ErrorAction Stop | Out-Null
				Write-Output "$(Time-Stamp)Saved to: $ExportPath\$($ManagementPack.Name).backup.xml"
				if ($Unsealed -and $RemoveUnsealedReferenceAndReimport)
				{
					Write-Output "$(Time-Stamp)Attempting to remove related data in the Unsealed Management Pack: $ExportPath\$($ManagementPack.Name).xml"
					$xmldata = [xml]::new()
					$xmldata.Load("$ExportPath\$($ManagementPack.Name).xml")
					#Save a backup of the MP
					$xmlData.Save("$ExportPath\$($ManagementPack.Name).backup.xml")
					#Get the version of the MP
					[version]$mpversion = $xmldata.ManagementPack.Manifest.Identity.Version
					#Increment the version of the MP
					$xmldata.ManagementPack.Manifest.Identity.Version = [version]::New($mpversion.Major, $mpversion.Minor, $mpversion.Build, $mpversion.Revision + 1).ToString()
					#Grab all the references
					$references = $xmlData.ChildNodes.Manifest.References.Reference | Where { $_.ID -eq $ReferenceToRemove } #| ForEach-Object { $removed += $_.ParentNode.InnerXML; $aliases += $_.Alias; [void]$_.ParentNode.RemoveChild($_); }
					[array]$referencingId = @()
					[array]$nodes = @()
					#Go through each reference
					foreach ($reference in $references)
					{
						#Find all overrides
						$Overrides = $xmlData.ChildNodes | Select-Xml -Xpath "//Overrides"
						foreach ($Override in $Overrides)
						{
							$nodes += $Override | Select-Object -ExpandProperty Node
						}
						
						#Find all unitmonitors
						$Monitors = $xmlData.ChildNodes | Select-Xml -Xpath "//Monitors"
						foreach ($Monitor in $Monitors)
						{
							$nodes += $Monitor | Select-Object -ExpandProperty Node
						}
						
						#Find all assemblies
						$Managed = $xmlData.ChildNodes | Select-Xml -Xpath "//Managed"
						foreach ($Item in $Managed)
						{
							$nodes += $Item | Select-Object -ExpandProperty Node
						}
						
						foreach ($node in $nodes)
						{
							$aliasFound = $node.ChildNodes.Where{ $_.Context -match "$($reference.Alias)!" }
							
							foreach ($context in $aliasFound)
							{
								$referencingId += $context.Id
								[void]$context.ParentNode.RemoveChild($context)
							}
						}
						[void]$reference.ParentNode.RemoveChild($reference)
						$languagePacks = $xmlData.ManagementPack.LanguagePacks.LanguagePack.DisplayStrings.DisplayString | Where{ $_.ElementID -like $referencingId }
						try { [void]$languagePacks.ParentNode.RemoveChild($languagePacks) }
						catch { Write-Verbose "Nothing found in Language Packs inside XML." }
						
					}
					$xmlData.Save("$ExportPath\$($ManagementPack.Name).xml")
					Write-Output "$(Time-Stamp)Importing the modified Unsealed Management Pack: $ExportPath\$($ManagementPack.Name).xml"
					Import-SCManagementPack -FullName "$ExportPath\$($ManagementPack.Name).xml" -ErrorAction SilentlyContinue
					if ($ManagementPack.Name -in $unsealedMPs)
					{
						#Remove from master list (not working yet)
						$unsealedMPs.Remove($ManagementPack.Name)
					}
				}
				elseif ($Unsealed)
				{
					Write-Output "$(Time-Stamp)Removing the Unsealed Management Pack: $($ManagementPack.DisplayName)"
					Remove-SCManagementPack -ManagementPack $ManagementPack -Confirm:$false -ErrorAction Stop
					if ($ManagementPack.Name -in $unsealedMPs)
					{
						#Remove from master list (not working yet)
						$unsealedMPs.Remove($ManagementPack.Name)
					}
				}
				if ($Sealed)
				{
					#Start of Inner Remove MP Function
					Write-Output "$(Time-Stamp)Removing the Sealed Management Pack: $($ManagementPack.DisplayName)"
					Remove-SCManagementPack -ManagementPack $ManagementPack -Confirm:$false -ErrorAction Stop
					if ($ManagementPack.Name -in $sealedMPs)
					{
						#Remove from master list (not working yet)
						$sealedMPs.Remove($ManagementPack.Name)
					}
				}
				# this is required to give SCOM time to process that the MP reference has been removed.
				sleep 10
			}
			
		}
		function Inner-GetMPRecurse
		{
			param
			(
				[Parameter(Mandatory = $true,
						   ValueFromPipeline = $true,
						   Position = 0)]
				$ManagementPack
			)
			trap
			{
				Write-Warning "$($PSItem.Exception) `nFunction: Inner-GetMPRecurse"
			}
			Write-Output "$(Time-Stamp)- Grabbing all related Management Pack(s) for: $($ManagementPack.DisplayName)"
			$recurseMP = Get-SCManagementPack -Id $ManagementPack.Id -Recurse -ErrorAction Stop
			if ($recurseMP.Count -ge 1)
			{
				foreach ($MP in $recurseMP)
				{
					if ($MP.Sealed -eq $false)
					{
						Inner-RemoveMP -ManagementPack $MP -Unsealed -ReferenceToRemove $($ManagementPack.Name) -ExportPath $ExportPath -RemoveUnsealedReferenceAndReimport:$RemoveUnsealedReferenceAndReimport
					}
					else
					{
						Inner-RemoveMP -ManagementPack $MP -Sealed -ExportPath $ExportPath -RemoveUnsealedReferenceAndReimport:$RemoveUnsealedReferenceAndReimport
					}
					$recurseMP = Get-SCManagementPack -Id $ManagementPack.Id -Recurse -ErrorAction Stop
					if ($recurseMP.Count -gt 1)
					{
						Write-Output "$(Time-Stamp)- - More than one recursive Management Packs are still detected (Count: $($recurseMP.Count))"
						Inner-GetMPRecurse -ManagementPack $recurseMP
					}
				}
			}
			Write-Output "$(Time-Stamp)No more Management Packs associated with: $($ManagementPack.DisplayName)"
			return
		}
		
		
		switch ($result)
		{
			0 {
				
				try
				{
					
					foreach ($sealedMP in $sealedMPs)
					{
						Write-Output @"
       ===========================================================================================
            $sealedMP
       ===========================================================================================
"@
						Inner-GetMPRecurse -ManagementPack $sealedMP
                        <#
						Write-Output "$(Time-Stamp)Removing the following Sealed Management Pack: $($sealedMP.DisplayName)"
						Remove-SCManagementPack -ManagementPack $sealedMP -ErrorAction Stop
						Write-Output "$(Time-Stamp)Removed the following Sealed Management Pack: $($sealedMP.DisplayName)"
#>
					}
					foreach ($unsealedMP in $unsealedMPs)
					{
						Write-Output @"
       ===========================================================================================
            $unsealedMP
       ===========================================================================================
"@
						Inner-GetMPRecurse -ManagementPack $unsealedMP
                        <#
						Write-Output "$(Time-Stamp)Removing the following Sealed Management Pack: $($unsealedMP.DisplayName)"
						Remove-SCManagementPack -ManagementPack $unsealedMP -ErrorAction Stop
						Write-Output "$(Time-Stamp)Removed the following Sealed Management Pack: $($unsealedMP.DisplayName)"
#>
					}
				}
				catch
				{
					Write-Warning @"
$(Time-Stamp)$($PSItem.Exception)

Exception Message $($PSItem.Exception.InnerException)
"@
				}
			}
			
			1 { Write-Output "$(Time-Stamp)Exiting without removing any management packs." }
		}
	}
}
END
{
	if ($ManagementPackName -or $ManagementPackId)
	{
		Remove-SCOMManagementPackDependencies -ManagementPackId $ManagementPackId -ManagementPackName $ManagementPackName -ExportPath $ExportPath -RemoveUnsealedReferenceAndReimport:$RemoveUnsealedReferenceAndReimport
	}
	else
	{
		#Edit line 377 to change what happens when this script is run from Powershell ISE.
		# Example 1:
		# Get-SCOMManagementPack -Name Microsoft.SQLServer.Windows.Discovery | Remove-SCOMManagementPackDependencies
		#
		# Example 2:
		# Remove-SCOMManagementPackDependencies -Name Microsoft.SQLServer.Windows.Discovery
		#
		# Example 3:
		# Remove-SCOMManagementPackDependencies -Name 'Microsoft SQL Server on Windows (Discovery)'
		#
		# Example 4:
		# Remove-SCOMManagementPackDependencies -Name 'Microsoft SQL Server on Windows*'
		#
		Remove-SCOMManagementPackDependencies
	}
	
	Write-Output "$(Time-Stamp)Completed Script!"
}
