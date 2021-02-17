# This function copies an entire subscription from a source management group to a target one. If the subscription or one of its referenced subscribers and channels already exist in the target MG, they are re-used, else they are created.
# The function currently only supports a single mail or command channel notification-action!
# You need to run this function with an account that has admin rights in both environments!
# Copy-cSCOMSubscription -subscription "mysubscription" -source scom-dev-server -target scom-prod-server
# Original Script: https://github.com/JeanCloudDev/SCOMRunbooks/blob/master/SCOMRunbooks/Functions/Copy-cSCOMSubscription.ps1
<#
	.Modified By
	Blake Drumm (v-bldrum@microsoft.com)
#>

function Copy-SCOMSubscription
{
	
	param (
		[Parameter(Mandatory = $false)]
		# the display-name of the subscription to copy
		$subscription,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		# The hostname of a SCOM management server belonging to the source Management Group
		$source,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		# The hostname of a SCOM management server belonging to the target Management Group
		$target
	)
	try
	{
		$ErrorActionPreference = "stop"
		
		# import the SCOM module to obtain the standard cmdlets
		if ($root = Get-ItemPropertyValue -Path "HKLM:SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Server" -Name InstallDirectory -ErrorAction SilentlyContinue)
		{
			if (!(get-module -name operationsmanager))
			{
				import-module "$root\..\Powershell\OperationsManager\OperationsManager.psm1"
			}
		}
		elseif ($root = Get-ItemPropertyValue -Path "HKLM:SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Console" -Name InstallDirectory -ErrorAction SilentlyContinue)
		{
			if (!(get-module -name operationsmanager))
			{
				import-module "$root\..\Powershell\OperationsManager\OperationsManager.psm1"
			}
		}
		else
		{
			throw "OperationsManager Powershell module not found."
		}
		
		# create empty subscription, subscriber and channel vars
		$ch = @()
		$ss = @()
		$sub = $null
		
		# get the source subscription
		if ($subscription)
		{
			$sourcesub = Get-SCOMNotificationSubscription -DisplayName "$($subscription)" -computername $source
		}
		else
		{
			$sourcesub = Get-SCOMNotificationSubscription -computername $source
		}
		foreach ($subscript in $sourcesub)
		{
			
			foreach ($notification in $subscript.Actions)
			{
				# check if the first defined channel used in the source subscription already exists in the target MG (based on displayname).
				# If it does, it is reused, else a new one is created using the same parameters as the source one. Only supports mail or command channels currently.
				if (($ch = Get-SCOMNotificationChannel -DisplayName $notification.DisplayName -ErrorAction SilentlyContinue -computername $target) -ne $null)
				{
					
				}
				else
				{
					if ($notification.GetType().Name -eq 'CommandNotificationAction') # Command Channel
					{
						$ch += Add-SCOMNotificationChannel -computername $target -Name $notification.Name -DisplayName $notification.DisplayName -Argument $notification.CommandLine -ApplicationPath $notification.ApplicationName -WorkingDirectory $notification.WorkingDirectory -ErrorAction $ErrorActionPreference
					}
					if ($notification.GetType().Name -eq 'SmtpNotificationAction') # SMTP Email
					{
						$ch += Add-SCOMNotificationChannel -computername $target -Name $notification.Name -DisplayName $notification.DisplayName -Subject $notification.Subject -Body $notification.Body -From $notification.From -Server $notification.Endpoint.PrimaryServer.Address -ReplyTo $notification.From -ErrorAction $ErrorActionPreference
					}
					if ($notification.GetType().Name -eq 'SmsNotificationAction') # SMS Text Message
					{
						$ch += Add-SCOMNotificationChannel -Sms -computername $target -Name $notification.Name -DisplayName $notification.DisplayName -Body $notification.Body -Encoding $notification.Encoding -ErrorAction $ErrorActionPreference
					}
					if ($notification.GetType().Name -eq 'SipNotificationAction') # Instant Message
					{
						$ch += Add-SCOMNotificationChannel -computername $target -Name $notification.Name -DisplayName $notification.DisplayName -UserName $notification.Endpoint.UserUri.OriginalString -Body $notification.Body -Server $notification.Endpoint.PrimaryServer.Address -ErrorAction $ErrorActionPreference
					}
					
				}
				# parse through all the subscription receipients aka subscribers. Add existing ones to the empty array $ss. If a source subscriber does not exist, it is created with the correct
				foreach ($i in $subscript.ToRecipients)
				{
					
					if (($j = Get-SCOMNotificationSubscriber -computername $target -Name $i.Name -ErrorAction SilentlyContinue) -ne $null)
					{
						$ss += $j
					}
					else
					{
						# to simplify the subscriber creation code, we add a dummy value which we replace later by the real subscriber device (mail, command).
						
						$j = Add-SCOMNotificationSubscriber -DeviceList "dummy@dummy.dummy" -Name $i.Name -computername $target
						$j.devices.clear()
						
						$action += New-Object -TypeName Microsoft.EnterpriseManagement.Administration.NotificationRecipientDevice -ArgumentList $($i.devices[0].Protocol), $($i.devices[0].Address)
						$action.name = $i.devices[0].name
						$j.devices.add($action)
						$j.update()
						$ss += $j
					}
				}
				# finally, we bring it all together in the subscription code.
				# First we check if the subscription already exist (displayname)
				# If it does, we only copy the subscription configuration (which alerts are forwarded) without touching subscribers and channels
				# Else we create a new subscription using the channel and subscriber-array variables we populated, and fill in the gaps with values from the source subscription
				# the alert criteria is always copied over as mentioned before
				# the subscription is created in a disabled state, you should enable it manually with PS after optional validations
				if (($sub = Get-SCOMNotificationSubscription -DisplayName $subscript.DisplayName -computername $target -ErrorAction SilentlyContinue) -ne $null)
				{
					$sub.configuration = $subscript.configuration
					$sub.update()
				}
				else
				{
					$sub = Add-SCOMNotificationSubscription -computername $target -Name $subscript.Name -Channel $ch -Disabled -Subscriber $ss -DisplayName $subscript.DisplayName -Delay 10 -Description $subscript.description -Criteria $subscript.configuration.criteria
					$sub.configuration = $subscript.configuration
					$sub.update()
				}
			}
		}
	}
	catch { $error[0]; Write-Warning $_ }
	
}

Copy-SCOMSubscription -source 'MS2' -target 'SCOM-1807'
