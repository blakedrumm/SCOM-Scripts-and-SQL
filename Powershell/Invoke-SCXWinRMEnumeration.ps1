<#
	.SYNOPSIS
		Invoke-SCXWinRMEnumeration - Enumerates various SCX classes on specified ComputerName using WinRM.
	
	.DESCRIPTION
		This script enumerates SCX classes using WinRM with Basic or Kerberos authentication.
	
	.PARAMETER AuthenticationMethod
		Authentication method: "Basic" or "Kerberos".
	
	.PARAMETER ComputerName
		Server names or IP addresses for SCX class enumeration.
	
	.PARAMETER Classes
		One or more classes to gather from the UNIX/Linux Agent.
	
	.PARAMETER EnumerateAllClasses
		Enumerate all classes for the UNIX/Linux Agent.
	
	.PARAMETER UserName
		UserName for authentication on target servers.
	
	.PARAMETER Password
		Secure password for the provided username.
	
	.PARAMETER Credential
		You can provide the credentials to utilize for the WinRM commands.
	
	.PARAMETER OriginServer
		The origin server for where you want the queries to originate from.
	
	.PARAMETER OutputFile
		Output file path for the results.
	
	.PARAMETER OutputType
		Output type for the results. Valid values are CSV and Text.
	
	.PARAMETER PassThru
		Do not Write-Host and pass through the Object data.
	
	.EXAMPLE
		$securePassword = ConvertTo-SecureString 'Password1' -AsPlainText -Force
		Invoke-SCXWinRMEnumeration -ComputerName "Server1", "Server2" -UserName "admin" -Password $securePassword -AuthenticationMethod "Basic" -Classes SCX_Agent, SCX_OperatingSystem
	
	.EXAMPLE
		$Credentials = (Get-Credential)
		Invoke-SCXWinRMEnumeration -ComputerName 'rhel7-9.contoso-2019.com' -AuthenticationMethod 'Basic' -Credential $Credentials -EnumerateAllClasses
	
	.NOTES
		Author: Blake Drumm
		Version: 1.3
		Created: November 17th, 2023
		Modified: March 18th, 2024
#>
[CmdletBinding(HelpUri = 'https://blakedrumm.com/')]
param
(
	[ValidateSet('Basic', 'Kerberos')]
	[string]$AuthenticationMethod,
	[Parameter(HelpMessage = 'Server names or IP addresses for SCX class enumeration.')]
	[Alias('Servers')]
	[string[]]$ComputerName,
	[string[]]$Classes,
	[switch]$EnumerateAllClasses,
	[string]$UserName,
	[System.Security.SecureString]$Password,
	[Parameter(HelpMessage = 'You can provide the credentials to utilize for the WinRM commands.')]
	[PSCredential]$Credential,
	[Parameter(HelpMessage = 'The origin server for where you want the queries to originate from.')]
	[string[]]$OriginServer,
	[Parameter(HelpMessage = 'Output file path for the results.')]
	[string]$OutputFile,
	[Parameter(HelpMessage = 'Output type for the results. Valid values are CSV and Text.')]
	[ValidateSet('CSV', 'Text', 'None')]
	[string[]]$OutputType = 'None',
	[Parameter(HelpMessage = 'Do not Write-Host and pass through the Object data.')]
	[switch]$PassThru
)

function Invoke-SCXWinRMEnumeration
{
	[CmdletBinding(HelpUri = 'https://blakedrumm.com/')]
	param
	(
		[ValidateSet('Basic', 'Kerberos')]
		[string]$AuthenticationMethod,
		[Parameter(Mandatory = $true,
				   HelpMessage = 'Server names or IP addresses for SCX class enumeration.')]
		[Alias('Servers')]
		[string[]]$ComputerName,
		[string[]]$Classes,
		[switch]$EnumerateAllClasses,
		[string]$UserName,
		[System.Security.SecureString]$Password,
		[Parameter(HelpMessage = 'You can provide the credentials to utilize for the WinRM commands.')]
		[PSCredential]$Credential,
		[Parameter(HelpMessage = 'The origin server for where you want the queries to originate from.')]
		[string[]]$OriginServer,
		[Parameter(HelpMessage = 'Output file path for the results.')]
		[string]$OutputFile,
		[Parameter(HelpMessage = 'Output type for the results. Valid values are CSV and Text.')]
		[ValidateSet('CSV', 'Text', 'None')]
		[string[]]$OutputType = 'None',
		[Parameter(HelpMessage = 'Do not Write-Host and pass through the Object data.')]
		[switch]$PassThru
	)
	
	trap
	{
		Write-Warning "Error encountered: $error"
		break
	}
	
	$locallyResolvedName = (Resolve-DnsName $env:COMPUTERNAME).Name | Select-Object -Unique -Index 0
	
	if ($AuthenticationMethod -eq '' -or -NOT $AuthenticationMethod)
	{
		try
		{
			$AuthenticationMethod = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup\Linux Auth' -ErrorAction Stop).Authentication
		}
		catch
		{
			$AuthenticationMethod = 'Basic'
		}
	}
	
	if ($UserName -and $AuthenticationMethod -eq 'Basic' -and -not $Password -and -NOT $Credential)
	{
		Write-Warning "Missing the -Password parameter for Basic authentication."
		return
	}
	elseif (-NOT $UserName -and -NOT $Password -and -NOT $Credential -and $AuthenticationMethod -eq 'Basic')
	{
		$Credential = Get-Credential
	}
	
	$scxClasses = @(
		"SCX_Agent",
		"SCX_DiskDrive",
		"SCX_FileSystem",
		"SCX_UnixProcess",
		"SCX_IPProtocolEndpoint",
		"SCX_OperatingSystem",
		"SCX_StatisticalInformation",
		"SCX_ProcessorStatisticalInformation",
		"SCX_MemoryStatisticalInformation",
		"SCX_EthernetPortStatistics",
		"SCX_DiskDriveStatisticalInformation",
		"SCX_FileSystemStatisticalInformation",
		"SCX_UnixProcessStatisticalInformation",
		"SCX_LANEndpoint"
	)
	
	if (-NOT $Classes -and -NOT $EnumerateAllClasses)
	{
		$EnumerateAllClasses = $true
	}
	
	$results = @()
	
	foreach ($ServerName in $ComputerName)
	{
		if (-NOT $PassThru)
		{
			Write-Host "===================================================="
			Write-Host "Current Server: $ServerName"
			Write-Host "Authentication Method: " -NoNewline
			Write-Host "$AuthenticationMethod" -ForegroundColor DarkCyan
		}
		
		$error.Clear()
		try
		{
			if ($UserName -and $Password)
			{
				$Credential = New-Object System.Management.Automation.PSCredential($Username, $Password)
			}
			
			if ($EnumerateAllClasses)
			{
				foreach ($class in $scxClasses)
				{
					if (-NOT $PassThru)
					{
						Write-Host "   Enumerating: $class" -ForegroundColor Cyan
					}
					$result = if ($Credential)
					{
						foreach ($origin in $OriginServer)
						{
							$resolvedName = (Resolve-DnsName $origin).Name | Select-Object -Unique -Index 0
							if ($resolvedName -eq "$locallyResolvedName")
							{
								$out = Get-WSManInstance -ComputerName $ServerName -Authentication $AuthenticationMethod -Credential:$Credential -Port 1270 -UseSSL -Enumerate "http://schemas.microsoft.com/wbem/wscim/1/cim-schema/2/$class`?__cimnamespace=root/scx" -ErrorAction Stop
								# Define properties to exclude
								$propertiesToExclude = @('ChildNodes', 'LastChild', 'OuterXml', 'IsReadOnly', 'SchemaInfo', 'NodeType', 'ParentNode', 'OwnerDocument', 'IsEmpty', 'Attributes', 'HasAttributes', 'InnerText', 'InnerXml', 'BaseURI', 'PreviousText', 'FirstChild', 'Value', 'NextSibling', 'PreviousSibling', 'HasChildNodes', 'RunspaceId', 'xsi')
								
								# Get all properties excluding the ones specified
								$propertyInfos = $out | Get-Member -MemberType Property | Where-Object { $_.Name -notin $propertiesToExclude }
								
								# Create a custom PSObject with only the desired properties
								$customObject = New-Object PSObject
								foreach ($propInfo in $propertyInfos)
								{
									$propName = $propInfo.Name
									# Use dot notation to access property values directly
									$propValue = $out.$propName
									# Check if the custom object already has this property to avoid duplicates
									if (-not $customObject.PSObject.Properties.Match($propName).Count)
									{
										
										if ($propValue.ChildNodes)
										{
											$customObject | Add-Member -MemberType NoteProperty -Name $propName -Value $propValue.InnerText
										}
										else
										{
											$customObject | Add-Member -MemberType NoteProperty -Name $propName -Value $propValue
										}
									}
								}
								
								return $customObject
							}
							else
							{
								Invoke-Command -ComputerName $resolvedName -ScriptBlock {
									$out = Get-WSManInstance -ComputerName $using:ServerName -Authentication $using:AuthenticationMethod -Credential:$using:Credential -Port 1270 -UseSSL -Enumerate "http://schemas.microsoft.com/wbem/wscim/1/cim-schema/2/$using:class`?__cimnamespace=root/scx" -ErrorAction Stop
									# Define properties to exclude
									$propertiesToExclude = @('ChildNodes', 'LastChild', 'OuterXml', 'IsReadOnly', 'SchemaInfo', 'NodeType', 'ParentNode', 'OwnerDocument', 'IsEmpty', 'Attributes', 'HasAttributes', 'InnerText', 'InnerXml', 'BaseURI', 'PreviousText', 'FirstChild', 'Value', 'NextSibling', 'PreviousSibling', 'HasChildNodes', 'RunspaceId', 'xsi')
									
									# Get all properties excluding the ones specified
									$propertyInfos = $out | Get-Member -MemberType Property | Where-Object { $_.Name -notin $propertiesToExclude }
									
									# Create a custom PSObject with only the desired properties
									$customObject = New-Object PSObject
									foreach ($propInfo in $propertyInfos)
									{
										$propName = $propInfo.Name
										# Use dot notation to access property values directly
										$propValue = $out.$propName
										# Check if the custom object already has this property to avoid duplicates
										if (-not $customObject.PSObject.Properties.Match($propName).Count)
										{
											
											if ($propValue.ChildNodes)
											{
												$customObject | Add-Member -MemberType NoteProperty -Name $propName -Value $propValue.InnerText
											}
											else
											{
												$customObject | Add-Member -MemberType NoteProperty -Name $propName -Value $propValue
											}
										}
									}
									
									return $customObject
								}
							}
						}
					}
					else
					{
						foreach ($origin in $OriginServer)
						{
							$resolvedName = (Resolve-DnsName $origin).Name | Select-Object -Unique -Index 0
							if ($resolvedName -eq "$locallyResolvedName")
							{
								$out = Get-WSManInstance -ComputerName $ServerName -Authentication $AuthenticationMethod -Port 1270 -UseSSL -Enumerate "http://schemas.microsoft.com/wbem/wscim/1/cim-schema/2/$class`?__cimnamespace=root/scx" -ErrorAction Stop
								# Define properties to exclude
								$propertiesToExclude = @('ChildNodes', 'LastChild', 'OuterXml', 'IsReadOnly', 'SchemaInfo', 'NodeType', 'ParentNode', 'OwnerDocument', 'IsEmpty', 'Attributes', 'HasAttributes', 'InnerText', 'InnerXml', 'BaseURI', 'PreviousText', 'FirstChild', 'Value', 'NextSibling', 'PreviousSibling', 'HasChildNodes', 'RunspaceId', 'xsi')
								
								# Get all properties excluding the ones specified
								$propertyInfos = $out | Get-Member -MemberType Property | Where-Object { $_.Name -notin $propertiesToExclude }
								
								# Create a custom PSObject with only the desired properties
								$customObject = New-Object PSObject
								foreach ($propInfo in $propertyInfos)
								{
									$propName = $propInfo.Name
									# Use dot notation to access property values directly
									$propValue = $out.$propName
									# Check if the custom object already has this property to avoid duplicates
									if (-not $customObject.PSObject.Properties.Match($propName).Count)
									{
										
										if ($propValue.ChildNodes)
										{
											$customObject | Add-Member -MemberType NoteProperty -Name $propName -Value $propValue.InnerText
										}
										else
										{
											$customObject | Add-Member -MemberType NoteProperty -Name $propName -Value $propValue
										}
									}
								}
								
								return $customObject
							}
							else
							{
								Invoke-Command -ComputerName $resolvedName -ScriptBlock {
									$out = Get-WSManInstance -ComputerName $using:ServerName -Authentication $using:AuthenticationMethod -Port 1270 -UseSSL -Enumerate "http://schemas.microsoft.com/wbem/wscim/1/cim-schema/2/$using:class`?__cimnamespace=root/scx" -ErrorAction Stop
									# Define properties to exclude
									$propertiesToExclude = @('ChildNodes', 'LastChild', 'OuterXml', 'IsReadOnly', 'SchemaInfo', 'NodeType', 'ParentNode', 'OwnerDocument', 'IsEmpty', 'Attributes', 'HasAttributes', 'InnerText', 'InnerXml', 'BaseURI', 'PreviousText', 'FirstChild', 'Value', 'NextSibling', 'PreviousSibling', 'HasChildNodes', 'RunspaceId', 'xsi')
									
									# Get all properties excluding the ones specified
									$propertyInfos = $out | Get-Member -MemberType Property | Where-Object { $_.Name -notin $propertiesToExclude }
									
									# Create a custom PSObject with only the desired properties
									$customObject = New-Object PSObject
									foreach ($propInfo in $propertyInfos)
									{
										$propName = $propInfo.Name
										# Use dot notation to access property values directly
										$propValue = $out.$propName
										# Check if the custom object already has this property to avoid duplicates
										if (-not $customObject.PSObject.Properties.Match($propName).Count)
										{
											
											if ($propValue.ChildNodes)
											{
												$customObject | Add-Member -MemberType NoteProperty -Name $propName -Value $propValue.InnerText
											}
											else
											{
												$customObject | Add-Member -MemberType NoteProperty -Name $propName -Value $propValue
											}
										}
									}
									
									return $customObject
								}
							}
						}
					}
					
					$results += $result
				}
			}
			else
			{
				if ($Classes)
				{
					foreach ($c in $Classes)
					{
						if (-NOT $PassThru)
						{
							Write-Host "   Enumerating: $c" -ForegroundColor Cyan
						}
						$result = if ($Credential)
						{
							foreach ($origin in $OriginServer)
							{
								$resolvedName = (Resolve-DnsName $origin).Name | Select-Object -Unique -Index 0
								if ($resolvedName -eq "$locallyResolvedName")
								{
									$out = Get-WSManInstance -ComputerName $ServerName -Authentication $AuthenticationMethod -Credential:$Credential -Port 1270 -UseSSL -Enumerate "http://schemas.microsoft.com/wbem/wscim/1/cim-schema/2/$c`?__cimnamespace=root/scx" -ErrorAction Stop
									# Define properties to exclude
									$propertiesToExclude = @('ChildNodes', 'LastChild', 'OuterXml', 'IsReadOnly', 'SchemaInfo', 'NodeType', 'ParentNode', 'OwnerDocument', 'IsEmpty', 'Attributes', 'HasAttributes', 'InnerText', 'InnerXml', 'BaseURI', 'PreviousText', 'FirstChild', 'Value', 'NextSibling', 'PreviousSibling', 'HasChildNodes', 'RunspaceId', 'xsi')
									
									# Get all properties excluding the ones specified
									$propertyInfos = $out | Get-Member -MemberType Property | Where-Object { $_.Name -notin $propertiesToExclude }
									
									# Create a custom PSObject with only the desired properties
									$customObject = New-Object PSObject
									foreach ($propInfo in $propertyInfos)
									{
										$propName = $propInfo.Name
										# Use dot notation to access property values directly
										$propValue = $out.$propName
										# Check if the custom object already has this property to avoid duplicates
										if (-not $customObject.PSObject.Properties.Match($propName).Count)
										{
											
											if ($propValue.ChildNodes)
											{
												$customObject | Add-Member -MemberType NoteProperty -Name $propName -Value $propValue.InnerText
											}
											else
											{
												$customObject | Add-Member -MemberType NoteProperty -Name $propName -Value $propValue
											}
										}
									}
									
									return $customObject
								}
								else
								{
									Invoke-Command -ComputerName $resolvedName -ScriptBlock {
										Write-Host "Origin Server = $env:COMPUTERNAME`nServerName = $using:ServerName`nAuthenticationMethod = $using:AuthenticationMethod`nCredential = $using:Credential`nClass = $using:class"
										$out = Get-WSManInstance -ComputerName $using:ServerName -Authentication $using:AuthenticationMethod -Credential:$using:Credential -Port 1270 -UseSSL -Enumerate "http://schemas.microsoft.com/wbem/wscim/1/cim-schema/2/$using:c`?__cimnamespace=root/scx" -ErrorAction Stop
										# Define properties to exclude
										$propertiesToExclude = @('ChildNodes', 'LastChild', 'OuterXml', 'IsReadOnly', 'SchemaInfo', 'NodeType', 'ParentNode', 'OwnerDocument', 'IsEmpty', 'Attributes', 'HasAttributes', 'InnerText', 'InnerXml', 'BaseURI', 'PreviousText', 'FirstChild', 'Value', 'NextSibling', 'PreviousSibling', 'HasChildNodes', 'RunspaceId', 'xsi')
										
										# Get all properties excluding the ones specified
										$propertyInfos = $out | Get-Member -MemberType Property | Where-Object { $_.Name -notin $propertiesToExclude }
										
										# Create a custom PSObject with only the desired properties
										$customObject = New-Object PSObject
										foreach ($propInfo in $propertyInfos)
										{
											$propName = $propInfo.Name
											# Use dot notation to access property values directly
											$propValue = $out.$propName
											# Check if the custom object already has this property to avoid duplicates
											if (-not $customObject.PSObject.Properties.Match($propName).Count)
											{
												
												if ($propValue.ChildNodes)
												{
													$customObject | Add-Member -MemberType NoteProperty -Name $propName -Value $propValue.InnerText
												}
												else
												{
													$customObject | Add-Member -MemberType NoteProperty -Name $propName -Value $propValue
												}
											}
										}
										
										return $customObject
									}
								}
							}
						}
						else
						{
							foreach ($origin in $OriginServer)
							{
								$resolvedName = (Resolve-DnsName $origin).Name | Select-Object -Unique -Index 0
								if ($resolvedName -eq "$locallyResolvedName")
								{
									$out = Get-WSManInstance -ComputerName $ServerName -Authentication $AuthenticationMethod -Port 1270 -UseSSL -Enumerate "http://schemas.microsoft.com/wbem/wscim/1/cim-schema/2/$c`?__cimnamespace=root/scx" -ErrorAction Stop
									# Define properties to exclude
									$propertiesToExclude = @('ChildNodes', 'LastChild', 'OuterXml', 'IsReadOnly', 'SchemaInfo', 'NodeType', 'ParentNode', 'OwnerDocument', 'IsEmpty', 'Attributes', 'HasAttributes', 'InnerText', 'InnerXml', 'BaseURI', 'PreviousText', 'FirstChild', 'Value', 'NextSibling', 'PreviousSibling', 'HasChildNodes', 'RunspaceId', 'xsi')
									
									# Get all properties excluding the ones specified
									$propertyInfos = $out | Get-Member -MemberType Property | Where-Object { $_.Name -notin $propertiesToExclude }
									
									# Create a custom PSObject with only the desired properties
									$customObject = New-Object PSObject
									foreach ($propInfo in $propertyInfos)
									{
										$propName = $propInfo.Name
										# Use dot notation to access property values directly
										$propValue = $out.$propName
										# Check if the custom object already has this property to avoid duplicates
										if (-not $customObject.PSObject.Properties.Match($propName).Count)
										{
											
											if ($propValue.ChildNodes)
											{
												$customObject | Add-Member -MemberType NoteProperty -Name $propName -Value $propValue.InnerText
											}
											else
											{
												$customObject | Add-Member -MemberType NoteProperty -Name $propName -Value $propValue
											}
										}
									}
									
									return $customObject
								}
								else
								{
									Invoke-Command -ComputerName $resolvedName -ScriptBlock {
										Write-Host "Origin Server = $env:COMPUTERNAME`nServerName = $using:ServerName`nAuthenticationMethod = $using:AuthenticationMethod`nCredential = $using:Credential`nClass = $using:class"
										$out = Get-WSManInstance -ComputerName $using:ServerName -Authentication $using:AuthenticationMethod -Port 1270 -UseSSL -Enumerate "http://schemas.microsoft.com/wbem/wscim/1/cim-schema/2/$using:c`?__cimnamespace=root/scx" -ErrorAction Stop
										# Define properties to exclude
										$propertiesToExclude = @('ChildNodes', 'LastChild', 'OuterXml', 'IsReadOnly', 'SchemaInfo', 'NodeType', 'ParentNode', 'OwnerDocument', 'IsEmpty', 'Attributes', 'HasAttributes', 'InnerText', 'InnerXml', 'BaseURI', 'PreviousText', 'FirstChild', 'Value', 'NextSibling', 'PreviousSibling', 'HasChildNodes', 'RunspaceId', 'xsi')
										
										# Get all properties excluding the ones specified
										$propertyInfos = $out | Get-Member -MemberType Property | Where-Object { $_.Name -notin $propertiesToExclude }
										
										# Create a custom PSObject with only the desired properties
										$customObject = New-Object PSObject
										foreach ($propInfo in $propertyInfos)
										{
											$propName = $propInfo.Name
											# Use dot notation to access property values directly
											$propValue = $out.$propName
											# Check if the custom object already has this property to avoid duplicates
											if (-not $customObject.PSObject.Properties.Match($propName).Count)
											{
												
												if ($propValue.ChildNodes)
												{
													$customObject | Add-Member -MemberType NoteProperty -Name $propName -Value $propValue.InnerText
												}
												else
												{
													$customObject | Add-Member -MemberType NoteProperty -Name $propName -Value $propValue
												}
											}
										}
										
										return $customObject
									}
								}
							}
						}
						
						$results += $result
					}
				}
				else
				{
					Write-Warning "Please provide one or more classes to the '-Classes' parameter. Or you can use the '-EnumerateAllClasses' parameter to list all available data for the Linux Agent."
					break
				}
			}
		}
		catch
		{
			$errorText = "Error for $ServerName`: $error (Authentication Username: $($Credential.UserName))"
			if (-NOT $PassThru)
			{
				Write-Warning $errorText
			}
			$results += $errorText
		}
	}
	try
	{
		# Output handling
		if ($OutputType -eq 'CSV')
		{
			if ($OutputType -match 'Text')
			{
				$ParentDirectory = Split-Path $OutputFile
				$OutputPath = "$ParentDirectory\$([System.IO.Path]::GetFileNameWithoutExtension($OutputFile)).csv"
			}
			else
			{
				$OutputPath = $OutputFile
			}
			if ($results -match "Error for")
			{
				$results | Out-File -FilePath $OutputPath -ErrorAction Stop
			}
			else
			{
				$results | Export-Csv -Path $OutputPath -NoTypeInformation -ErrorAction Stop
			}
			if (-NOT $PassThru)
			{
				Write-Host "CSV file output located here: " -ForegroundColor Green -NoNewline
				Write-Host "$OutputPath" -ForegroundColor Yellow
			}
		}
		if ($OutputType -eq 'Text')
		{
			if ($OutputType -match 'CSV')
			{
				$ParentDirectory = Split-Path $OutputFile
				$OutputPath = "$ParentDirectory\$([System.IO.Path]::GetFileNameWithoutExtension($OutputFile)).txt"
			}
			else
			{
				$OutputPath = $OutputFile
			}
			$results | Out-File -FilePath $OutputPath -ErrorAction Stop
			if (-NOT $PassThru)
			{
				Write-Host "Text file output located here: " -ForegroundColor Green -NoNewline
				Write-Host "$OutputPath" -ForegroundColor Yellow
			}
		}
	}
	catch
	{
		Write-Error "Error encountered: $error"
	}
	if ($OutputType -ne 'Text' -and $OutputType -ne 'CSV')
	{
		$results
	}
	return
}
if ($Servers -or $ComputerName -or $Password -or $OriginServer)
{
	Invoke-SCXWinRMEnumeration -ComputerName $ComputerName -Credential:$Credential -UserName $UserName -Password $Password -AuthenticationMethod $AuthenticationMethod -Classes $Classes -EnumerateAllClasses:$EnumerateAllClasses -OutputType:$OutputType -OutputFile $OutputFile -OriginServer $OriginServer -PassThru:$PassThru
}
else
{
	# Example usage
	#$Credentials = (Get-Credential)
	#Invoke-SCXWinRMEnumeration -ComputerName 'rhel7-9.contoso-2019.com' -AuthenticationMethod 'Basic' -Credential $Credentials -EnumerateAllClasses
	Invoke-SCXWinRMEnumeration
}
