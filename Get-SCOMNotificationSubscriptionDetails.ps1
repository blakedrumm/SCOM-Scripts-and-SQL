function Get-SCOMNotificationSubscriptionDetails
{
	param
	(
		[Parameter(Mandatory = $false)]
		[string]$Output
	)
    #Originally found here: https://blog.topqore.com/export-scom-subscriptions-using-powershell/
    # Modified by: Blake Drumm (blakedrumm@microsoft.com)
    # Date Modified: 07/16/2021
	$finalstring = $null
	$subs = $null
	$subs = Get-SCOMNotificationSubscription
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
		$property = Select-Xml -Content $templatesub -XPath "//Property" | foreach { $_.node.InnerXML }

		for ($i = 0; $i -lt $property.length; $i++)
		{
			if ($property[$i] -eq "ProblemId")
			{
				$monitor = (Get-SCOMMonitor -Id $val[$i]).DisplayName
				$tempcriteria += "  " + ($i + 1) + ") Raised by Monitor: $monitor" + "`n"
				
			}
			if ($property[$i] -eq "RuleId")
			{
				$rule = (Get-SCOMRule -Id $val[$i]).DisplayName
				$tempcriteria += "  " + ($i + 1) + ") Raised by Rule: $rule" + "`n"
			}
			if ($property[$i] -eq "BaseManagedEntityId")
			{
				$Instance = (Get-SCOMClassInstance -Id $val[$i]).DisplayName
				$tempcriteria += "  " + ($i + 1) + ") Raised by Instance: $Instance" + "`n"
			}
			if ($property[$i] -eq "Severity")
			{
				$verbose_severity = switch ($val[$i])
				{
					'0' { 'Informational' }
					'1' { 'Warning' }
					'2' { 'Critical' }
					Default { $val[$i] }
				}
				$tempcriteria += "  " + ($i + 1) + ") " + $property[$i] + " " + $operators[$i] + " " + $verbose_severity + "`n"
				continue
			}
			if ($property[$i] -eq "Priority")
			{
				$tempcriteria += "  " + ($i + 1) + ") " + $property[$i] + " " + $operators[$i] + " " + $val[$i] + "`n"
				continue
			}
			if ($property[$i] -eq "ResolutionState")
			{
				$tempcriteria += "  " + ($i + 1) + ") " + $property[$i] + " " + $operators[$i] + " " + $val[$i] + "`n"
				continue
			}
			if ($property[$i] -eq "AlertDescription")
			{
				$tempcriteria += "  " + ($i + 1) + ") " + $property[$i] + " " + $operators[$i] + " " + $val[$i] + "`n"
				continue
			}
			if ($property[$i] -eq "AlertName")
			{
				$tempcriteria += "  " + ($i + 1) + ") " + $property[$i] + " " + $operators[$i] + " " + $val[$i] + "`n"
				continue
			}
			
			$tempcriteria += "  " + ($i + 1) + ") " + $property[$i] + " " + $operators[$i] + " " + $val[$i] + "`n"
			
		}
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
			$MainObject | Add-Member -MemberType NoteProperty -Name "Raised by an instance of a specific class      $subcount)" -Value $classStr
		}
		if ($group -and !$class)
		{
			$groupStr = ''
			for ($i = 1; $i -le $Group.Count; $i++)
			{
				$groupStr += "`n `r $i) " + $Group[$i - 1].DisplayName
			}
			$MainObject | Add-Member -MemberType NoteProperty -Name "Raised by an instance of a specific group      $subcount)" -Value $groupStr
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
			$MainObject | Add-Member -MemberType NoteProperty -Name "Raised by an instance of a specific group      $subcount)" -Value $groupStr
			$MainObject | Add-Member -MemberType NoteProperty -Name "Raised by an instance of a specific class      $subcount)" -Value $classStr
		}
		
		$MainObject | Add-Member -MemberType NoteProperty -Name '   ' -Value "`n`n-------- Subscriber Information --------"
		$subscribers = $sub.ToRecipients
		$i = 0
		foreach ($subscriber in $subscribers)
		{
			$i = $i
			$i++
			$MainObject | Add-Member -MemberType NoteProperty -Name "Subscriber Name                 $i---" -Value $subscriber.Name
			$MainObject | Add-Member -MemberType NoteProperty -Name "   Channel Type                 $i--" -Value $subscriber.Devices.Protocol
			$MainObject | Add-Member -MemberType NoteProperty -Name "   Subscriber Address Name      $i-" -Value ($subscriber.Devices.Name + "`n`n-------- Channel Information --------")
		}
		$i = 0
		foreach ($action in $sub.Actions)
		{
			$i = $i
			$MainObject | Add-Member -MemberType NoteProperty -Name ("               Channel Name        " + ($i + 1)) -Value ($action.Displayname)
			$MainObject | Add-Member -MemberType NoteProperty -Name ("               ID                  " + ($i + 1)) -Value ($action.ID)
			$MainObject | Add-Member -MemberType NoteProperty -Name ("               Channel Description " + ($i + 1)) -Value ($action.description)
			if ($action.Endpoint -like "Smtp*")
			{
				$MainObject | Add-Member -MemberType NoteProperty -Name ("               From                " + ($i + 1)) -Value ($action.From)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("               Subject             " + ($i + 1)) -Value ($action.Subject)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("               Endpoint            " + ($i + 1)) -Value ($action.Endpoint)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("               Body Encoding       " + ($i + 1)) -Value ($action.BodyEncoding)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("               Reply To            " + ($i + 1)) -Value ($action.ReplyTo)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("               Headers             " + ($i + 1)) -Value ($action.Headers)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("               Body                " + ($i + 1)) -Value ($action.body)
			}
			elseif ($action.RecipientProtocol -like "Cmd*")
			{
				$MainObject | Add-Member -MemberType NoteProperty -Name ("               Application Name    " + ($i + 1)) -Value ($action.ApplicationName)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("               Working Directory   " + ($i + 1)) -Value ($action.WorkingDirectory)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("               Command Line        " + ($i + 1)) -Value ($action.CommandLine)
				$MainObject | Add-Member -MemberType NoteProperty -Name ("               Timeout             " + ($i + 1)) -Value ($action.Timeout)
			}
			$i++
		}
		$finalstring += $MainObject | Out-String
		
	}
	$finalstring
}
Get-SCOMNotificationSubscriptionDetails
