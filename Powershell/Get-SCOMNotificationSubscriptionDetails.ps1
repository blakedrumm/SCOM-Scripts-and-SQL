<#
	.SYNOPSIS
		SCOM Notification Subscription Details
	
	.DESCRIPTION
		This script will output the current subscriptions setup in System Center Operations Manager.
	
	.PARAMETER OutputFile
		Output the results to a text file. Just provide the location: 'C:\Temp\Output.txt'
	
	.EXAMPLE
		To return the Notification Subscriptions output to the Console:
			PS C:\> .\Get-SCOMNotificationSubscriptionDetails.ps1

		To output the Notification Subscriptions to a text file:
			PS C:\> .\Get-SCOMNotificationSubscriptionDetails.ps1 -OutputFile C:\Temp\Output.txt
	
	.NOTES
		Originally found here: https://blog.topqore.com/export-scom-subscriptions-using-powershell/
		Original Github Page: https://github.com/Sameer-Mhaisekar/scripts/blob/main/export-scomsubscriptions.txt
		Original Author: Sameer Mhaisekar (Sameer-Mhaisekar)
		 Current version (this script) is located here: https://github.com/blakedrumm/SCOM-Scripts-and-SQL/blob/master/Powershell/Get-SCOMNotificationSubscriptionDetails.ps1
		 Modified by: Blake Drumm (blakedrumm@microsoft.com)
		 Date Created: 07/16/2021
		 Date Modified: 01/13/2022
#>
[CmdletBinding()]
[OutputType([string])]
param
(
	[Parameter(Mandatory = $false,
			   Position = 0,
			   HelpMessage = "Output the results to a text file. Just provide the location: 'C:\Temp\Output.txt'")]
	[string]$OutputFile
)
BEGIN
{
	Function Time-Stamp
	{
		
		$TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
		
		return "$TimeStamp - "
		
	}
	Write-Verbose "$(Time-Stamp)Start of Script!"
}
PROCESS
{
	function Get-SCOMNotificationSubscriptionDetails
	{
		param
		(
			[Parameter(Mandatory = $false)]
			[string]$OutputFile
		)
		$finalstring = $null
		$subs = $null
		$subs = Get-SCOMNotificationSubscription | Sort-Object
		$subcount = 0
		foreach ($sub in $subs)
		{
			Write-Verbose "$(Time-Stamp)Working on Subscription: $sub"
			$subcount = $subcount
			$subcount++
			#empty all the variables
			$monitor = $null
			$rule = $null
			$Instance = $null
			$Desc = $null
			$classid = $null
			$groupid = $null
			$class = $null
			$Group = $null
			$Name = $sub.DisplayName
			$finalstring += "`n`n==========================================================`n"
			$MainObject = New-Object PSObject
			$MainObject | Add-Member -MemberType NoteProperty -Name 'Subscription Name' -Value $Name
			$MainObject | Add-Member -MemberType NoteProperty -Name 'Subscription Enabled' -Value $sub.Enabled
			$MainObject | Add-Member -MemberType NoteProperty -Name 'Subscription Description' -Value $sub.Description
			$MainObject | Add-Member -MemberType NoteProperty -Name ' ' -Value "`n-------- Subscription Criteria --------"
			$tempcriteria = $null
			$templatesub = $sub.Configuration.Criteria
			if ($templatesub)
			{
				Write-Verbose "$(Time-Stamp)Found Configuration Criteria: $templatesub"
				$expression = $templatesub | Select-Xml -XPath "//SimpleExpression" -ErrorAction SilentlyContinue | foreach { $_.node.InnerXML }
				$val = Select-Xml -Content $templatesub -XPath "//Value" -ErrorAction SilentlyContinue | foreach { $_.node.InnerXML }
				$operators = Select-Xml -Content $templatesub -XPath "//Operator" -ErrorAction SilentlyContinue | foreach { $_.node.InnerXML }
				$properties = Select-Xml -Content $templatesub -XPath "//Property" -ErrorAction SilentlyContinue | foreach { $_.node.InnerXML }
			}
			else
			{
				$expression = $null
				$val = $null
				$operators = $null
				$properties = $null
			}
			$i = 0
			do
			{
				foreach ($property in $properties)
				{
					Write-Verbose "$(Time-Stamp)Working on Property: $property"
					if ($property -eq "ProblemId")
					{
						$monitor = (Get-SCOMMonitor -Id $($val | Select-Object -Index $i)).DisplayName
						$tempcriteria += "  " + ($i + 1) + ") Raised by Monitor: $monitor" + "`n"
					}
					elseif ($property -eq "RuleId")
					{
						$rule = (Get-SCOMRule -Id $($val | Select-Object -Index $i)).DisplayName
						$tempcriteria += "  " + ($i + 1) + ") Raised by Rule: $rule" + "`n"
					}
					elseif ($property -eq "BaseManagedEntityId")
					{
						$Instance = (Get-SCOMClassInstance -Id $($val | Select-Object -Index $i)).DisplayName
						$tempcriteria += "  " + ($i + 1) + ") Raised by Instance: $Instance" + "`n"
					}
					elseif ($property -eq "Severity")
					{
						$verbose_severity = switch ($($val | Select-Object -Index $i))
						{
							'0' { 'Informational' }
							'1' { 'Warning' }
							'2' { 'Critical' }
							Default { $($val | Select-Object -Index $i) }
						}
						$tempcriteria += "  " + ($i + 1) + ") " + $property + " " + $($operators | Select-Object -Index $i) + " " + $verbose_severity + "`n"
					}
					elseif ($property -eq "Priority")
					{
						$tempcriteria += "  " + ($i + 1) + ") $property $($operators | Select-Object -Index $i) $($val | Select-Object -Index $i) `n"
					}
					elseif ($property -eq "ResolutionState")
					{
						$tempcriteria += "  " + ($i + 1) + ") $property $($operators | Select-Object -Index $i) $($val | Select-Object -Index $i) `n"
					}
					elseif ($property -eq "AlertDescription")
					{
						$tempcriteria += "  " + ($i + 1) + ") $property $($operators | Select-Object -Index $i) $($val | Select-Object -Index $i) `n"
					}
					elseif ($property -eq "AlertName")
					{
						$tempcriteria += "  " + ($i + 1) + ") $property $($operators | Select-Object -Index $i) $($val | Select-Object -Index $i) `n"
					}
					else
					{
						$tempcriteria += "  " + ($i + 1) + ") $property $($operators | Select-Object -Index $i) $($val | Select-Object -Index $i) `n"
					}
					$i++
					continue
				}
			}
			until ($i -eq $val.Count)
			#$MainObject | Add-Member -MemberType NoteProperty -Name ("Criteria ") -Value 
			$MainObject | Add-Member -MemberType NoteProperty -Name 'Criteria' -Value ($tempcriteria + "`n-------- Subscription Scope --------")
			
			#Check for class/group
			$i = 0
			$classid = $sub.Configuration.MonitoringClassIds
			$groupid = $sub.Configuration.MonitoringObjectGroupIds
			if ($classid -ne $null)
			{
				$class = Get-SCOMClass -Id $classid
			}
			if ($groupid -ne $null)
			{
				$Group = Get-SCOMGroup -Id $groupid
			}
			if ($class -and !$Group)
			{
				$classStr = ''
				for ($i = 1; $i -le $class.Count; $i++)
				{
					$classStr += "`n `r $i) " + $class[$i - 1].DisplayName
				}
				$MainObject | Add-Member -MemberType NoteProperty -Name "Raised by an instance of a specific class" -Value $classStr
				Write-Verbose "$(Time-Stamp)Raised by an instance of a specific class: $classStr"
			}
			if ($group -and !$class)
			{
				$groupStr = ''
				for ($i = 1; $i -le $Group.Count; $i++)
				{
					$groupStr += "`n `r $i) " + $Group[$i - 1].DisplayName
				}
				$MainObject | Add-Member -MemberType NoteProperty -Name "Raised by an instance of a specific group" -Value $groupStr
				Write-Verbose "$(Time-Stamp)Raised by an instance of a specific group: $groupStr"
			}
			if ($class -and $Group)
			{
				$groupStr = ''
				Foreach ($targetgroup in $Group)
				{
					$groupStr += $targetgroup.DisplayName.Split(", ")
				}
				
				$classStr = ''
				
				Foreach ($targetclass in $Class)
				{
					$classStr += $targetclass.DisplayName.Split(", ")
				}
				$MainObject | Add-Member -MemberType NoteProperty -Name "Raised by an instance of a specific group" -Value $groupStr
				$MainObject | Add-Member -MemberType NoteProperty -Name "Raised by an instance of a specific class" -Value $classStr
				Write-Verbose "$(Time-Stamp)Raised by an instance of a specific group: $groupStr"
				Write-Verbose "$(Time-Stamp)Raised by an instance of a specific class: $classStr"
			}
			
			$MainObject | Add-Member -MemberType NoteProperty -Name '   ' -Value "`n`n-------- Subscriber Information --------"
			$subscribers = $sub.ToRecipients
			$i = 0
			foreach ($subscriber in $subscribers)
			{
				Write-Verbose "$(Time-Stamp)Gathering information for: $($subscriber.Name)"
				$i = $i
				$i++
				$MainObject | Add-Member -MemberType NoteProperty -Name "Subscriber Name | $i" -Value $subscriber.Name
				(97 .. (97 + 25)).ForEach({ [array]$abc += [char]$_ })
				$number = 0
				foreach ($protocol in $subscriber.Devices.Protocol)
				{
					Write-Verbose "$(Time-Stamp)Found Protocol: $protocol"
					$protocoltype = switch ($protocol)
					{
						'SIP' { 'Instant Message (IM)' }
						{ $_ -like 'Cmd*' } { 'Command' }
						'SMTP' { 'E-Mail (SMTP)' }
						'SMS' { 'Text Message (SMS)' }
						Default { $protocol }
					}
					$number++
					$MainObject | Add-Member -MemberType NoteProperty -Name "   Channel Type | $i$($abc | Select-Object -Index $($number))" -Value $protocoltype
					$MainObject | Add-Member -MemberType NoteProperty -Name "   Subscriber Address Name | $i$($abc[$number])" -Value $($subscriber.Devices.Name | Select-Object -Index $($number - 1))
					$MainObject | Add-Member -MemberType NoteProperty -Name "   Subscriber Address Destination | $i$($abc[$number])" -Value $($subscriber.Devices.Address | Select-Object -Index $($number - 1))
				}
			}
			$i = 0
			$MainObject | Add-Member -MemberType NoteProperty -Name '     ' -Value "`n`n-------- Channel Information --------"
			foreach ($action in $sub.Actions)
			{
				Write-Verbose "$(Time-Stamp)Found Action: $action"
				$i = $i
				$i++
				$MainObject | Add-Member -MemberType NoteProperty -Name ("       Channel Name | $i") -Value ($action.Displayname)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("       ID | $i") -Value ($action.ID)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("       Channel Description | $i") -Value ($action.description)
				if ($action.Endpoint -like "Smtp*")
				{
					#Get the SMTP channel endpoint
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Primary SMTP Server | $i") -Value ($action.Endpoint.PrimaryServer.Address)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Primary SMTP Port | $i") -Value ($action.Endpoint.PrimaryServer.PortNumber)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Primary SMTP Authentication Type | $i") -Value ($action.Endpoint.PrimaryServer.AuthenticationType)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Primary SMTP ExternalEmailProfile | $i") -Value ($action.Endpoint.PrimaryServer.ExternalEmailProfile)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Secondary SMTP Server | $i") -Value ($action.Endpoint.SecondaryServers.Address)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Secondary SMTP Port | $i") -Value ($action.Endpoint.SecondaryServers.PortNumber)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Secondary SMTP Authentication Type | $i") -Value ($action.Endpoint.SecondaryServers.AuthenticationType)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Secondary SMTP ExternalEmailProfile | $i") -Value ($action.Endpoint.SecondaryServers.ExternalEmailProfile)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       From | $i") -Value ($action.From)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Subject | $i") -Value ($action.Subject)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Endpoint | $i") -Value ($action.Endpoint)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Body Encoding | $i") -Value ($action.BodyEncoding)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Reply To | $i") -Value ($action.ReplyTo)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Headers | $i") -Value ($action.Headers)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Is Body HTML? | $i") -Value ($action.IsBodyHtml)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Body | $i") -Value ($action.body)
				}
				elseif ($action.RecipientProtocol -like "Cmd*")
				{
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Application Name | $i") -Value ($action.ApplicationName)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Working Directory | $i") -Value ($action.WorkingDirectory)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Command Line | $i") -Value ($action.CommandLine)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Timeout | $i") -Value ($action.Timeout)
				}
				elseif ($action.Endpoint -like "Im*")
				{
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Name | $i") -Value ($action.Name)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Encoding | $i") -Value ($action.Encoding)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Body | $i") -Value ($action.WorkingDirectory)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Content Type | $i") -Value ($action.ContentType)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Endpoint Primary Server | $i") -Value ($action.Endpoint.PrimaryServer.Address)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Endpoint Return Address | $i") -Value ($action.Endpoint.PrimaryServer.UserUri)
				}
				elseif ($action.Endpoint -like "Sms*")
				{
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Name | $i") -Value ($action.Name)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Encoding | $i") -Value ($action.Encoding)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Body | $i") -Value ($action.WorkingDirectory)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Content Type | $i") -Value ($action.ContentType)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Endpoint Primary Device | $i") -Value ($action.Endpoint.PrimaryDevice)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Endpoint Secondary Device | $i") -Value ($action.Endpoint.SecondaryDevices | Out-String -Width 2048)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Endpoint Device Enumeration Interval Seconds | $i") -Value ($action.Endpoint.DeviceEnumerationIntervalSeconds)
					$MainObject | Add-Member -MemberType NoteProperty -Name ("       Endpoint Primary Device Switch Back Interval Seconds | $i") -Value ($action.Endpoint.PrimaryDeviceSwitchBackIntervalSeconds)
				}
			}
			$finalstring += $MainObject | Out-String
			
		}
		if ($OutputFile)
		{
			$finalstring | Out-File $OutputFile
		}
		else
		{
			return $finalstring
		}
	}
	if ($OutputFile)
	{
		Write-Verbose "$(Time-Stamp)Running with parameters being passed to a script."
		Get-SCOMNotificationSubscriptionDetails -OutputFile $OutputFile
	}
	else
	{
		Write-Verbose "$(Time-Stamp)Running without parameters being passed to script. We may be running from Powershell ISE or you are running the script normally."
<# Edit line 323 to modify the default command run when this script is executed without any arguments. This is helpful when running from Powershell ISE.
   Example: 
   Get-SCOMNotificationSubscriptionDetails -OutputFile C:\Temp
   or
   Get-SCOMNotificationSubscriptionDetails
   #>
		Get-SCOMNotificationSubscriptionDetails
	}
}
END
{
	Write-Verbose "$(Time-Stamp)End of Script!"
}
