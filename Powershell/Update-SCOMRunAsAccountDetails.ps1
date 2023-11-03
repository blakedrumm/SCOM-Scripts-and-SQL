<#
.SYNOPSIS
    This script updates SCOM Run As accounts with new credentials.

.DESCRIPTION
    The Update-SCOMRunAsAccountDetails script connects to a SCOM Management Server,
    locates Run As accounts by UserName or DisplayName, and updates the credentials
    with the provided new username and/or password.

.PARAMETER ManagementServer
    The name of the SCOM Management Server to connect to.

.PARAMETER UserName
    The UserName of the Run As account to be updated.
    This is the existing username that the account is currently using.

.PARAMETER DisplayName
    The DisplayName of the Run As account to be updated.
    This is the friendly name for the account as seen in SCOM.

.PARAMETER NewUserName
    The new UserName for the Run As account.
    This will replace the current username in the account.

.PARAMETER NewPassword
    The new Password for the Run As account as a SecureString.
    If provided, it will update the account's password.

.PARAMETER NewDisplayName
    The new DisplayName for the Run As account.
    If provided, it will replace the current display name of the account.

.EXAMPLE
    $securePassword = ConvertTo-SecureString 'MyNewPassword!' -AsPlainText -Force
    Update-SCOMRunAsAccountDetails -ManagementServer 'SCOMServer01' -UserName 'olduser' -NewUserName 'newuser' -NewPassword $securePassword

    This example updates the Run As account with the username 'olduser' to have a new username 'newuser',
    a new password 'MyNewPassword!', and a new display name 'New Display Name'.

.NOTES
    Author: Blake Drumm (blakedrumm@microsoft.com)
    Last Updated: November 3rd, 2023
    Version: 1.0

    Make sure to run this script as a user with enough permissions to update Run As accounts in SCOM.

.LINK
    My personal SCOM Blog: https://blakedrumm.com/
#>

# Script parameters
param (
	[string]$ManagementServer,
	[string]$UserName,
	[string]$DisplayName,
	[string]$NewUserName,
	[SecureString]$NewPassword,
	[string]$NewDisplayName,
	[string]$SDKBinariesDirectory
)

function Update-SCOMRunAsAccountDetails
{
	param (
		[string]$ManagementServer,
		[string]$UserName,
		[string]$DisplayName,
		[string]$NewUserName,
		[SecureString]$NewPassword,
		[string]$NewDisplayName,
		[string]$SDKBinariesDirectory
	)
	
	# Add the SCOM SDK Assemblies
	if (-not $SDKBinariesDirectory)
	{
		$SDKBinariesDirectory = (Resolve-Path "C:\Program Files\Microsoft System Center\Operations Manager\Server\SDK Binaries").Path
	}
	
	Get-ChildItem $SDKBinariesDirectory -Filter "*.dll" | ForEach-Object { Add-Type -Path $_.FullName }
	if ($ManagementServer)
	{
	# Connect to the Management Group
	$managementGroup = New-Object Microsoft.EnterpriseManagement.ManagementGroup($ManagementServer)
	}
	else
	{
		Write-Warning "Please provide the '-ManagementServer' parameter and try again."
		break
	}
	
	# Get all Secure Data
	$secureData = $managementGroup.Security.GetSecureData()
	
	$Accounts = $secureData | Where-Object {
		$displayNameMatch = -not [string]::IsNullOrWhiteSpace($DisplayName) -and $_.Name -eq $DisplayName -and -not $_.IsSystem
		
		# This will be our flag to check if the username matches
		$userNameMatch = $false
		
		# Check if the username field is not empty or whitespace
		if (-not [string]::IsNullOrWhiteSpace($UserName))
		{
			# Try to parse the UserName as XML if it looks like XML
			if ($_.UserName -match "^<SCXUser><UserId>.+</UserId><Elev>.+</Elev></SCXUser>$")
			{
				try
				{
					# Create an XML object from the UserName
					$xml = [xml]$_.UserName
					# Compare the UserId text with the UserName parameter
					$userNameMatch = $xml.SCXUser.UserId -eq $UserName
				}
				catch
				{
					# If XML parsing failed, log and continue
					Write-Warning "Failed to parse XML for user name comparison."
				}
			}
			else
			{
				# If it's not XML, compare directly
				$userNameMatch = $_.UserName -eq $UserName
			}
		}
		
		# Return true if either display name or username matches
		$displayNameMatch -or $userNameMatch
	}
	
	if ($NewUserName -or $NewDisplayName -or $NewPassword)
	{
		if ($Accounts)
		{
			foreach ($account in $Accounts)
			{
				Write-Host "Account (Before Update):"
				# -----------------------------------------------------
				# Was Display Name Updated?
				Write-Host "                        Name = " -NoNewline
				if ($NewDisplayName)
				{
					Write-Host $($account.Name) -ForegroundColor Yellow
				}
				else
				{
					Write-Host $($account.Name) -ForegroundColor Gray
				}
				# -----------------------------------------------------
				# Was UserName Updated?
				Write-Host "                        UserName = " -NoNewline
				if ($NewUserName)
				{
					Write-Host $($account.UserName) -ForegroundColor Yellow
				}
				else
				{
					Write-Host $($account.UserName) -ForegroundColor Gray
				}
				Write-Host "                        Last Modified = " -NoNewline
				Write-Host $($account.LastModified) -ForegroundColor Cyan
				
				# Update DisplayName if a new one is provided
				if (![string]::IsNullOrWhiteSpace($NewDisplayName))
				{
					$account.Name = $NewDisplayName
				}
				
				# Update UserName if NewUserName is provided
				if (![string]::IsNullOrWhiteSpace($NewUserName))
				{
					# Check if the account UserName contains XML structure for SCXUser
					if ($account.UserName -match "<SCXUser><UserId>(.*?)</UserId>")
					{
						# Extract the actual UserName from the XML using the $matches automatic variable
						$actualUserName = $matches[1]
						
						# Check if the actual UserName matches the provided UserName parameter
						if ($actualUserName -eq $UserName)
						{
							# Escape the UserName to be used in the regex pattern
							$escapedUserName = [regex]::Escape($UserName)
							
							# Replace only the exact UserName in the XML structure
							$newXml = $account.UserName -replace "<UserId>$escapedUserName</UserId>", "<UserId>$NewUserName</UserId>"
							$account.UserName = $newXml
						}
					}
					
					elseif (-not [string]::IsNullOrWhiteSpace($UserName) -and $account.UserName -eq $UserName)
					{
						$account.UserName = $NewUserName
					}
				}
				
				# Update the password if a new one is provided
				if (![string]::IsNullOrWhiteSpace($NewPassword))
				{
					$account.Data = $NewPassword
				}
				
				# Commit the changes
				$account.Update()
				
				Write-Host "Account (After Update):"
				# -----------------------------------------------------
				# Was Display Name Updated?
				Write-Host "                        Name = " -NoNewline
				if ($NewDisplayName)
				{
					Write-Host $($account.Name) -ForegroundColor Green
				}
				else
				{
					Write-Host $($account.Name) -ForegroundColor Gray
				}
				# -----------------------------------------------------
				# Was UserName Updated?
				Write-Host "                        UserName = " -NoNewline
				if ($NewUserName)
				{
					Write-Host $($account.UserName) -ForegroundColor Green
				}
				else
				{
					Write-Host $($account.UserName) -ForegroundColor Gray
				}
				# -----------------------------------------------------
				# Was Password Updated?
				if ($NewPassword)
				{
					Write-Host "                        Password = " -NoNewline
					Write-Host '{Updated Password}' -ForegroundColor Green
				}
				Write-Host "                        Last Modified = " -NoNewline
				Write-Host $($account.LastModified) -ForegroundColor Cyan
			}
		}
		else
		{
			Write-Host "`n-------------------------------------------------------------------------" -ForegroundColor Gray
			Write-Host "No RunAs accounts found with the specified criteria."
			Write-Host "`n-------------------------------------------------------------------------" -ForegroundColor Gray
		}
	}
	else
	{
		foreach ($account in $Accounts)
		{
			Write-Host "-----------------------------------------------------" -ForegroundColor DarkYellow
			Write-Host "Account Information:"
			# -----------------------------------------------------
			# Was Display Name Updated?
			Write-Host "                        Name = " -NoNewline
			Write-Host $($account.Name) -ForegroundColor Gray
			# -----------------------------------------------------
			# Was UserName Updated?
			Write-Host "                        UserName = " -NoNewline
			Write-Host $($account.UserName) -ForegroundColor Gray
			# --
			Write-Host "                        Last Modified = " -NoNewline
			Write-Host $($account.LastModified) -ForegroundColor Cyan
			
		}
		
		Write-Host "`n-------------------------------------------------------------------------" -ForegroundColor Gray
		Write-Host "No updates were performed." -ForegroundColor Yellow
		Write-Host "-------------------------------------------------------------------------" -ForegroundColor Gray
		
	}
}

if ($ManagementServer -or $UserName -or $DisplayName -or $NewUserName -or $NewPassword -or $NewDisplayName -or $SDKBinariesDirectory)
{
	Update-SCOMRunAsAccountDetails -ManagementServer $ManagementServer -UserName $UserName -DisplayName $DisplayName -NewUserName $NewUserName -NewPassword $NewPassword -NewDisplayName $NewDisplayName -SDKBinariesDirectory $SDKBinariesDirectory
}
else
{
	#The password we can to start using is Password1
	#$securePassword = ConvertTo-SecureString 'Password1' -AsPlainText -Force
	
	# Usage example:
	#Update-SCOMRunAsAccountDetails -ManagementServer 'MS01-2019.contoso-2019.com' -UserName 'CONTOSO-2019\test' -NewUserName 'CONTOSO-2019\test2'
	
	Update-SCOMRunAsAccountDetails
}
