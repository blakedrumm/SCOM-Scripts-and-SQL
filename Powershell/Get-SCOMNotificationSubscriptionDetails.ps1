function Get-SCOMNotificationSubscriptionDetails
{
	param
	(
		[Parameter(Mandatory = $false)]
		[string]$Output
	)
	#Originally found here: https://blog.topqore.com/export-scom-subscriptions-using-powershell/
	# Modified by: Blake Drumm (blakedrumm@microsoft.com)
	# Date Modified: 08/02/2021
	$finalstring = $null
	$subs = $null
	$subs = Get-SCOMNotificationSubscription | Sort-Object
	$subcount = 0
	foreach ($sub in $subs)
	{
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
		$expression = $templatesub | Select-Xml -XPath "//SimpleExpression" | foreach { $_.node.InnerXML }
		$val = Select-Xml -Content $templatesub -XPath "//Value" | foreach { $_.node.InnerXML }
		$operators = Select-Xml -Content $templatesub -XPath "//Operator" | foreach { $_.node.InnerXML }
		$properties = Select-Xml -Content $templatesub -XPath "//Property" | foreach { $_.node.InnerXML }
		$i = 0
		do
		{
			foreach ($property in $properties)
			{
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
		}
		if ($group -and !$class)
		{
			$groupStr = ''
			for ($i = 1; $i -le $Group.Count; $i++)
			{
				$groupStr += "`n `r $i) " + $Group[$i - 1].DisplayName
			}
			$MainObject | Add-Member -MemberType NoteProperty -Name "Raised by an instance of a specific group" -Value $groupStr
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
		}
		
		$MainObject | Add-Member -MemberType NoteProperty -Name '   ' -Value "`n`n-------- Subscriber Information --------"
		$subscribers = $sub.ToRecipients
		$i = 0
		foreach ($subscriber in $subscribers)
		{
			$i = $i
			$i++
			$MainObject | Add-Member -MemberType NoteProperty -Name "Subscriber Name $i" -Value $subscriber.Name
			$MainObject | Add-Member -MemberType NoteProperty -Name "   Channel Type $i" -Value $subscriber.Devices.Protocol
			$MainObject | Add-Member -MemberType NoteProperty -Name "   Subscriber Address Name $i     " -Value $subscriber.Devices.Name
			$MainObject | Add-Member -MemberType NoteProperty -Name "   Subscriber Address Destination $i     " -Value $subscriber.Devices.Address
		}
		$i = 0
		$MainObject | Add-Member -MemberType NoteProperty -Name '     ' -Value "`n`n-------- Channel Information --------"
		foreach ($action in $sub.Actions)
		{
			$i = $i
			$MainObject | Add-Member -MemberType NoteProperty -Name ("       Channel Name ") -Value ($action.Displayname)
			$MainObject | Add-Member -MemberType NoteProperty -Name ("       ID   ") -Value ($action.ID)
			$MainObject | Add-Member -MemberType NoteProperty -Name ("       Channel Description  ") -Value ($action.description)
			if ($action.Endpoint -like "Smtp*")
			{
				#Get the SMTP channel endpoint
				$MainObject | Add-Member -MemberType NoteProperty -Name ("       Primary SMTP Server  ") -Value ($action.Endpoint.PrimaryServer.Address)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("       Primary SMTP Port    ") -Value ($action.Endpoint.PrimaryServer.PortNumber)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("       Primary SMTP Authentication Type     ") -Value ($action.Endpoint.PrimaryServer.AuthenticationType)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("       Primary SMTP ExternalEmailProfile    ") -Value ($action.Endpoint.PrimaryServer.ExternalEmailProfile)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("       Secondary SMTP Server") -Value ($action.Endpoint.SecondaryServers.Address)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("       Secondary SMTP Port  ") -Value ($action.Endpoint.SecondaryServers.PortNumber)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("       Secondary SMTP Authentication Type   ") -Value ($action.Endpoint.SecondaryServers.AuthenticationType)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("       Secondary SMTP ExternalEmailProfile  ") -Value ($action.Endpoint.SecondaryServers.ExternalEmailProfile)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("       From ") -Value ($action.From)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("       Subject      ") -Value ($action.Subject)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("       Endpoint     ") -Value ($action.Endpoint)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("       Body Encoding") -Value ($action.BodyEncoding)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("       Reply To     ") -Value ($action.ReplyTo)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("       Headers      ") -Value ($action.Headers)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("       Body ") -Value ($action.body)
			}
			elseif ($action.RecipientProtocol -like "Cmd*")
			{
				$MainObject | Add-Member -MemberType NoteProperty -Name ("       Application Name") -Value ($action.ApplicationName)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("       Working Directory       ") -Value ($action.WorkingDirectory)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("       Command Line    ") -Value ($action.CommandLine)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("       Timeout ") -Value ($action.Timeout)
			}
			$i++
		}
		$finalstring += $MainObject | Out-String
		
	}
	if ($Output)
	{
		$finalstring | Out-File $Output
	}
	else
	{
		$finalstring
	}
}
