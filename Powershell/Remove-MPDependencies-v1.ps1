param
(
	[Parameter(ValueFromPipeline = $true,
			   Position = 0,
			   HelpMessage = 'ex: Microsoft.Azure.ManagedInstance.Discovery')]
	[string]$ManagementPackName,
	[Parameter(ValueFromPipeline = $true,
			   Position = 1,
			   HelpMessage = 'ex: b02631ec-9672-6309-04cb-9d38ced8e067')]
	[string]$ManagementPackId,
	[Parameter(Position = 2)]
	[string]$ExportPath = "$env:USERPROFILE\Desktop"
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
			[Parameter(ValueFromPipeline = $true,
					   Position = 0,
					   HelpMessage = 'ex: Microsoft.Azure.ManagedInstance.Discovery')]
			[string]$ManagementPackName,
			[Parameter(ValueFromPipeline = $true,
					   Position = 1,
					   HelpMessage = 'ex: b02631ec-9672-6309-04cb-9d38ced8e067')]
			[string]$ManagementPackId,
			[Parameter(Position = 2)]
			[string]$ExportPath = "$env:USERPROFILE\Desktop"
		)
		
		Write-Output "$(Time-Stamp)Gathering Management Pack Recursive Dependencies for $($ManagementPackName, $ManagementPackId)"
		try
		{
			if ($ManagementPackId)
			{
				$recurseMPList = Get-SCManagementPack -Id $ManagementPackId -Recurse
			}
			elseif ($ManagementPackName)
			{
				$recurseMPList = Get-SCManagementPack -Name $ManagementPackName -Recurse
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
		$title = "Uninstall/Edit Management Packs"
		$message = "Do you want to uninstall/edit the $($recurseMPList.Count) management packs and its dependent management packs?"
		
		$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Uninstall (Sealed) / Edit (Unsealed) selected Management Packs."
		$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Do not remove Management Packs and stop script."
		$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
		
		$result = $host.ui.PromptForChoice($title, $message, $options, 0)
		
		function Inner-RemoveMP
		{
			param
			(
				[Parameter(Mandatory = $true,
						   ValueFromPipeline = $true,
						   Position = 0)]
				$ManagementPack,
				[Parameter(Mandatory = $false,
						   Position = 1)]
				[switch]$Sealed,
				[Parameter(Mandatory = $false,
						   Position = 2)]
				[switch]$Unsealed,
				[Parameter(Mandatory = $false,
						   Position = 3)]
				[string]$ReferenceToRemove,
				[Parameter(Mandatory = $true,
						   Position = 4)]
				[string]$ExportPath
			)
			
			trap
			{
				Write-Warning "$($PSItem.Exception) `nFunction: Inner-RemoveMP"
			}
			Write-Output "$(Time-Stamp)Backing Up the following: $($ManagementPack.DisplayName)"
			$ManagementPack | Export-SCOMManagementPack -Path $ExportPath -ErrorAction Stop | Out-Null
			Write-Output "$(Time-Stamp)Saved to: $ExportPath\$($ManagementPack.Name).backup.xml"
			if ($Unsealed)
			{
				Write-Output "$(Time-Stamp)Attempting to remove related data in the Unsealed Management Pack: $ExportPath\$($ManagementPack.Name).xml"
				$xmldata = [xml](Get-Content "$ExportPath\$($ManagementPack.Name).xml" -ErrorAction Stop);
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
						$aliasFound = $node.ChildNodes.Where{ $_.Context -match "$($reference.Alias)" }
						
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
					#Remove from master list
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
					#Remove from master list
					$sealedMPs.Remove($ManagementPack.Name)
				}
			}
			sleep 10
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
						Inner-RemoveMP -ManagementPack $MP -Unsealed -ReferenceToRemove $($ManagementPack.Name) -ExportPath $ExportPath
					}
					else
					{
						Inner-RemoveMP -ManagementPack $MP -Sealed -ExportPath $ExportPath
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
		Remove-SCOMManagementPackDependencies -ManagementPackId $ManagementPackId -ManagementPackName $ManagementPackName -ExportPath $ExportPath
	}
	else
	{
		Remove-SCOMManagementPackDependencies -ManagementPackName Microsoft.SQLServer.Windows.Discovery
	}
	
	Write-Output "$(Time-Stamp)Completed Script!"
}
