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
        if($recurseMPList.Count -eq 0)
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
				$ManagementPack
			)
			trap
			{
				Write-Warning "$($PSItem.Exception) `nFunction: Inner-RemoveMP"
			}
			Write-Output "$(Time-Stamp)Backing Up the following: $($ManagementPack.DisplayName)"
			$ManagementPack | Export-SCOMManagementPack -Path $ExportPath -ErrorAction Stop | Out-Null
			Write-Output "$(Time-Stamp)Saved to: $ExportPath\$($ManagementPack.Name).xml"
			#Start of Inner Remove MP Function
			Write-Output "$(Time-Stamp)Removing the Management Pack: $($ManagementPack.DisplayName)"
			Remove-SCManagementPack -ManagementPack $ManagementPack -Confirm:$false -ErrorAction Stop
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
					Inner-RemoveMP -ManagementPack $MP
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
					
					foreach ($MP in $sealedMPs)
					{
						Write-Output @"
       ===========================================================================================
            $MP
       ===========================================================================================
"@
						Inner-GetMPRecurse -ManagementPack $MP
                        <#
						Write-Output "$(Time-Stamp)Removing the following Sealed Management Pack: $($MP.DisplayName)"
						Remove-SCManagementPack -ManagementPack $MP -ErrorAction Stop
						Write-Output "$(Time-Stamp)Removed the following Sealed Management Pack: $($MP.DisplayName)"
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
