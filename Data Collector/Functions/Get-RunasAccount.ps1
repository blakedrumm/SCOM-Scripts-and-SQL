	function Get-SCOMRunasAccount
	{
<# 
	.SYNOPSIS
	This function dumps all RunAsAccounts in a SCOM 2012 (R2) and their usage in RunAsProfiles. If an account is not used in any profile, it will be clearly marked.
	
	.DESCRIPTION
	This function creates a custom array of all RunAsAccounts and RunAsProfiles where they are used. If a RunAsAccount is used for multiple targets
	in a profile, this function will create one custom object per account, profile and target id.
	
	.PARAMETER ManagementServer
	Name of the SCOM Management server you want to connect to
	
	.PARAMETER OrderByAccount
	Sorts the output by account name
	
	.PARAMETER OrderByProfile
	Sorts the output by profile name
	
	.PARAMETER OrderByTarget
	Sorts the output by target id
	
	.INPUTS
	N/A

	.OUTPUTS
	Array of custom objects:
	RunAsAccountName:	Displayname or Name of account
	Domain:				Domain (if available)
	Username:			Username (if available)	
	ProfileName:		Displayname or Name of Profile (if available)
	TargetID:			ID of profile target (if available). ID can be an object (classinstance) or a class itself
	TargetName:			Displayname or Name of TargetID
	
	.NOTES
    Author:     Brinkmann, Dirk (dirk.brinkmann@microsoft.com)
    Date        Version   Author    Category (NEW | CHANGE | DELETE | BUGFIX): Description
	19.07.2015	1.0.0     DirkBri - NEW: first release
	
	Credits for processing target other than Healthservice goes to Mihai Sarbulescu!!!

	Disclaimer:
	This sample script is not supported under any Microsoft standard support program or service. This sample
	script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties
	including, without limitation, any implied warranties of merchantability or of fitness for a particular
	purpose. The entire risk arising out of the use or performance of this sample script and documentation
	remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation,
	production, or delivery of this script be liable for any damages whatsoever (including, without limitation,
	damages for loss of business profits, business interruption, loss of business information, or other
	pecuniary loss) arising out of the use of or inability to use this sample script or documentation, even
	if Microsoft has been advised of the possibility of such damages.

	
	.LINK
	http://blogs.technet.com/b/dirkbri/archive/2015/07/19/reporting-runasaccount-usage-information-in-a-scom-2012-r2-management-group.aspx

	.EXAMPLE
	<PS> get-customscomrunasaccounttoprofile  -managementserver "MyMS.mydomain.local" -orderbyaccount
	Retrurns all data ordered by RunAsAccount
#>
		
		[cmdletbinding()]
		param ([Parameter(Mandatory = $true, HelpMessage = "Please enter Management Server Name")]
			$ManagementServer,
			[Parameter(ParameterSetName = 'Account', Mandatory = $true, HelpMessage = "Sort output by Accountname")]
			[Switch]$OrderByAccount,
			[Parameter(ParameterSetName = 'Profile', Mandatory = $true, HelpMessage = "Sort output by Profilename")]
			[Switch]$OrderByProfile,
			[Parameter(ParameterSetName = 'Target', Mandatory = $true, HelpMessage = "Sort output by TargetID")]
			[Switch]$OrderByTargetID
		)
		Write-Host "-" -NoNewline -ForegroundColor Green
		#Some variables
		$colProcessedAccounts = @()
		$strAccountNotAssignedToProfile = "Not assigned to any profile"
		# Load Module
		Import-Module "OperationsManager"
		$MGConnection = New-SCOMManagementGroupConnection -ComputerName $ManagementServer
		$MGModule = Get-SCOMManagementGroup
		#Load Assembly
		$CoreDLL = "Microsoft.EnterpriseManagement.Core"
		[reflection.assembly]::LoadWithPartialName($CoreDLL) | out-null
		$MG = New-Object Microsoft.EnterpriseManagement.EnterpriseManagementGroup($ManagementServer)
		
		#Process HealthService based Accounts
		foreach ($RunAsProfile in (Get-SCOMRunAsProfile))
		{
			if ($RunAsProfile.DisplayName -eq $null)
			{
				$ProfileName = $RunAsProfile.Name
			}
			else
			{
				$ProfileName = $RunAsProfile.DisplayName
			}
			# get Health Service array associated with the profile
			$HSRef = $MGModule.GetMonitoringSecureDataHealthServiceReferenceBySecureReferenceId($RunAsProfile.ID)
			foreach ($HS in $HSRef)
			{
				$TargetName = (Get-SCOMClassInstance -Id $HS.HealthServiceId).Displayname
				$MonitoringData = $HS.GetMonitoringSecureData()
				$tempAccount = New-Object pscustomobject
				$tempAccount | Add-Member -MemberType NoteProperty -Name RunAsAccountName -Value $MonitoringData.name
				$tempAccount | Add-Member -MemberType NoteProperty -Name Domain -Value $MonitoringData.domain
				$tempAccount | Add-Member -MemberType NoteProperty -Name Username -Value $MonitoringData.username
				$tempAccount | Add-Member -MemberType NoteProperty -Name ProfileName -Value $ProfileName
				$tempAccount | Add-Member -MemberType NoteProperty -Name TargetName -Value $TargetName
				$tempAccount | Add-Member -MemberType NoteProperty -Name TargetID -Value $HS.HealthServiceId.Guid.ToString()
				
				$colProcessedAccounts += $tempAccount
			}
		}
		Write-Host "-" -NoNewline -ForegroundColor Green
		#Get all RunAsAccounts 
		$colAccounts = $mg.Security.GetSecureData()
		
		#Process all RunAsAccounts targeted at other targets
		foreach ($account in $colAccounts)
		{
			#All credits for the next 20 lines goes to Mihai
			$secStorId = $account.SecureStorageId
			$stringBuilder = New-Object System.Text.StringBuilder
			foreach ($byte in $secStorId)
			{
				$stringBuilder.Append($byte.ToString("X2")) | Out-Null
			}
			Write-Host "-" -NoNewline -ForegroundColor Green
			$MPCriteria = "Value='{0}'" -f $stringBuilder.ToString()
			$moc = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackOverrideCriteria($MPCriteria)
			$overrides = $mg.Overrides.GetOverrides($moc)
			$colTempProfiles = @()
			foreach ($override in $overrides)
			{
				if ($override.ContextInstance -eq $null)
				{
					$TargetID = $override.Context.id.Guid.ToString()
					$TargetClass = Get-SCOMClass -Id $TargetID
					if ($TargetClass.DisplayName -eq $null)
					{
						$TargetName = $TargetClass.Name
					}
					else
					{
						$TargetName = $TargetClass.DisplayName
					}
				}
				else
				{
					$TargetID = $override.ContextInstance.Guid.ToString()
					$TargetClassInstance = Get-SCOMClassinstance -Id $TargetID
					if ($TargetClassInstance.DisplayName -eq $null)
					{
						$TargetName = $TargetClassInstance.Name
					}
					else
					{
						$TargetName = $TargetClassInstance.DisplayName
					}
				}
				$secRef = $mg.Security.GetSecureReference($override.SecureReference.Id)
				if ($secRef.DisplayName -eq $null)
				{
					$ProfileName = $secRef.Name
				}
				else
				{
					$ProfileName = $secRef.DisplayName
				}
				$colTempProfiles += $ProfileName
			}
			$colTempProfiles = $colTempProfiles | Sort-Object -Unique
			
			if ($colTempProfiles.count -gt 0)
			{
				foreach ($PROFILEName in $colTempProfiles)
				{
					
					$tempAccount = New-Object pscustomobject
					$tempAccount | Add-Member -MemberType NoteProperty -Name RunAsAccountName -Value $account.name
					$tempAccount | Add-Member -MemberType NoteProperty -Name Domain -Value $account.domain
					$tempAccount | Add-Member -MemberType NoteProperty -Name Username -Value $account.username
					$tempAccount | Add-Member -MemberType NoteProperty -Name ProfileName -Value $PROFILEName
					$tempAccount | Add-Member -MemberType NoteProperty -Name TargetName -Value $TargetName
					$tempAccount | Add-Member -MemberType NoteProperty -Name TargetID -Value $TargetID
					$colProcessedAccounts += $tempAccount
				}
			}
			else
			{
				if (@($colProcessedAccounts | ? { $_.RunAsAccountName -eq $account.name }).count -eq 0)
				{
					$tempAccount = New-Object pscustomobject
					$tempAccount | Add-Member -MemberType NoteProperty -Name RunAsAccountName -Value $account.name
					$tempAccount | Add-Member -MemberType NoteProperty -Name Domain -Value $account.domain
					$tempAccount | Add-Member -MemberType NoteProperty -Name Username -Value $account.username
					$tempAccount | Add-Member -MemberType NoteProperty -Name ProfileName -Value $strAccountNotAssignedToProfile
					$tempAccount | Add-Member -MemberType NoteProperty -Name TargetName -Value $null
					$tempAccount | Add-Member -MemberType NoteProperty -Name TargetID -Value $null
					$colProcessedAccounts += $tempAccount
				}
			}
			
			
		}
		Write-Host "> Completed!" -NoNewline -ForegroundColor Green
		
		
		switch ($PsCmdlet.ParameterSetName)
		{
			"Account"  { $colProcessedAccounts | Sort-Object RunAsAccountName; break }
			"Profile"  { $colProcessedAccounts | Sort-Object ProfileName; break }
			"Target"  { $colProcessedAccounts | Sort-Object TargetID; break }
			default { $colProcessedAccounts }
		}
		
		
	}