function Get-SCOMRunasAccount
{
#=======================================================
# Get all SCOM RunAs Accounts and their Profiles Script
# v 1.1
#=======================================================

# Constants section - make changes here
#=======================================================
$ManagementServer = "localhost"
$OutPath = "$OutputPath\RunAsAccountInfo.txt"
#=======================================================

#Set Empty Profile Associated Text
$strAccountNotAssignedToProfile = "No Profile Associated"

#Set Variable to empty
$AccountDataArray = @()

# Load Modules and Connect to SCOM
Import-Module "OperationsManager"
$MGConnection = New-SCOMManagementGroupConnection -ComputerName $ManagementServer
$MGModule = Get-SCOMManagementGroup

# Load Assembly and define ManagementGroup Object
$CoreDLL = "Microsoft.EnterpriseManagement.Core" 
[reflection.assembly]::LoadWithPartialName($CoreDLL) | out-null 
$MG = New-Object Microsoft.EnterpriseManagement.EnterpriseManagementGroup($ManagementServer)

	
#Process HealthService based Action Accounts Section
#=======================================================
FOREACH ($RunAsProfile in (Get-SCOMRunAsProfile))
{		
	IF ($RunAsProfile.DisplayName -eq $null) 
	{
        $ProfileName = $RunAsProfile.Name
    } 
    ELSE
    {
        $ProfileName = $RunAsProfile.DisplayName
	}
	# get Health Service array associated with the profile
	$HSRef = $MGModule.GetMonitoringSecureDataHealthServiceReferenceBySecureReferenceId($RunAsProfile.ID)
	FOREACH ($HS in $HSRef)
	{
		$TargetName = (Get-SCOMClassInstance -Id $HS.HealthServiceId).Displayname
		$MonitoringData = $HS.GetMonitoringSecureData()
		$tempAccount = New-Object pscustomobject
		$tempAccount | Add-Member -MemberType NoteProperty -Name RunAsAccountName -Value $MonitoringData.name
		$tempAccount | Add-Member -MemberType NoteProperty -Name Domain -Value $MonitoringData.domain
		$tempAccount | Add-Member -MemberType NoteProperty -Name Username -Value $MonitoringData.username
        $tempAccount | Add-Member -MemberType NoteProperty -Name AccountType -Value $MonitoringData.SecureDataType
		$tempAccount | Add-Member -MemberType NoteProperty -Name ProfileName -Value $ProfileName
		$tempAccount | Add-Member -MemberType NoteProperty -Name TargetID -Value $HS.HealthServiceId.Guid.ToString()
		$tempAccount | Add-Member -MemberType NoteProperty -Name TargetName -Value $TargetName
		$AccountDataArray += $tempAccount
	}
}
#=======================================================
# End Process HealthService based Action Accounts Section



#Process all RunAsAccounts targeted at other targets
#=======================================================
#Get all RunAsAccounts 
$colAccounts = $mg.Security.GetSecureData() | sort-object Name

#Loop through each RunAs account
FOREACH ($account in $colAccounts)
{
	#All credits for the next 20 lines goes to Mihai
	$secStorId = $account.SecureStorageId
	$stringBuilder = New-Object System.Text.StringBuilder
	FOREACH ($byte in $secStorId) 
	{ 
		$stringBuilder.Append($byte.ToString("X2")) | Out-Null 
	}
	$MPCriteria = "Value='{0}'" -f $stringBuilder.ToString()
	$moc = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackOverrideCriteria($MPCriteria)
	$overrides = $mg.Overrides.GetOverrides($moc)

    IF ($overrides.Count -eq 0)
    {
        $ProfileName = "No Profile Assigned"
        $tempAccount = New-Object pscustomobject
		$tempAccount | Add-Member -MemberType NoteProperty -Name RunAsAccountName -Value $account.name
		$tempAccount | Add-Member -MemberType NoteProperty -Name Domain -Value $account.domain
		$tempAccount | Add-Member -MemberType NoteProperty -Name Username -Value $account.username
        $tempAccount | Add-Member -MemberType NoteProperty -Name AccountType -Value $account.SecureDataType
		$tempAccount | Add-Member -MemberType NoteProperty -Name ProfileName -Value $ProfileName
		$tempAccount | Add-Member -MemberType NoteProperty -Name TargetID -Value "NULL"
		$tempAccount | Add-Member -MemberType NoteProperty -Name TargetName -Value "NULL"
        $AccountDataArray += $tempAccount
    }
    ELSE
    {
    	FOREACH ($override in $overrides) 
	    {
		    IF ($override.ContextInstance -eq $null)
		    {
			    $TargetID = $override.Context.id.Guid.ToString()
			    $TargetClass = Get-SCOMClass -Id $TargetID
			    IF ($TargetClass.DisplayName -eq $null) 
			    {
		            $TargetName = $TargetClass.Name
		        } 
                ELSE 
			    {
		            $TargetName = $TargetClass.DisplayName
		        }
		    }
		    ELSE
		    {
			    $TargetID = $override.ContextInstance.Guid.ToString()
			    $TargetClassInstance = Get-SCOMClassinstance -Id $TargetID
			    IF ($TargetClassInstance.DisplayName -eq $null) 
			    {
		            $TargetName = $TargetClassInstance.Name
		        }
                ELSE 
			    {
			        $TargetName = $TargetClassInstance.DisplayName
			    }
		    }
		    $secRef = $mg.Security.GetSecureReference($override.SecureReference.Id)
		    IF ($secRef.DisplayName -eq $null) 
		    {
		        $ProfileName = $secRef.Name
		    }
            ELSE
            {
		        $ProfileName = $secRef.DisplayName
		    }
		
		    $tempAccount = New-Object pscustomobject
		    $tempAccount | Add-Member -MemberType NoteProperty -Name RunAsAccountName -Value $account.name
		    $tempAccount | Add-Member -MemberType NoteProperty -Name Domain -Value $account.domain
		    $tempAccount | Add-Member -MemberType NoteProperty -Name Username -Value $account.username
		    $tempAccount | Add-Member -MemberType NoteProperty -Name AccountType -Value $account.SecureDataType
		    $tempAccount | Add-Member -MemberType NoteProperty -Name ProfileName -Value $ProfileName
		    $tempAccount | Add-Member -MemberType NoteProperty -Name TargetID -Value $TargetID
		    $tempAccount | Add-Member -MemberType NoteProperty -Name TargetName -Value $TargetName
            $AccountDataArray += $tempAccount
        }
	} #This ends the for each override loop
}
#=======================================================
# End Process all RunAsAccounts targeted at other targets

# Sort by RunAsAccountName
$AccountData = $AccountDataArray | Sort-Object RunAsAccountName | ft * -AutoSize | Out-String -Width 4096
	
# Output to the console for testing
# $AccountDataArray | FT

# Output to CSV
$AccountData | Out-File $OutPath
$AccountDataArray | Sort-Object RunAsAccountName | Export-CSV $OutputPath\CSV\RunAsAccountInfo.csv -NoTypeInformation
}
