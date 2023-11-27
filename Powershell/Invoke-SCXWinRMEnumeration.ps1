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
	
	.PARAMETER OutputType
		Output type for the results. Valid values are CSV and Text.
	
	.PARAMETER OutputFile
		Output file path for the results.
	
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
		Version: 1.2
		Created: November 17th, 2023
		Modified: November 26th, 2023
#>
[CmdletBinding(HelpUri = 'https://blakedrumm.com/')]
param
(
	[ValidateSet('Basic', 'Kerberos')]
	[string]$AuthenticationMethod = 'Basic',
	[Parameter(HelpMessage = 'Server names or IP addresses for SCX class enumeration.')]
	[Alias('Servers')]
	[string[]]$ComputerName,
	[string[]]$Classes,
	[switch]$EnumerateAllClasses,
	[string]$UserName,
	[System.Security.SecureString]$Password,
	[Parameter(HelpMessage = 'You can provide the credentials to utilize for the WinRM commands.')]
	[PSCredential]$Credential,
	[Parameter(HelpMessage = 'Output type for the results. Valid values are CSV and Text.')]
	[ValidateSet('CSV', 'Text', 'None')]
	[string[]]$OutputType = 'None',
	[Parameter(HelpMessage = 'Output file path for the results.')]
	[string]$OutputFile,
	[Parameter(HelpMessage = 'Do not Write-Host and pass through the Object data.')]
	[switch]$PassThru
)

function Invoke-SCXWinRMEnumeration
{
	[CmdletBinding(HelpUri = 'https://blakedrumm.com/')]
	param
	(
		[ValidateSet('Basic', 'Kerberos')]
		[string]$AuthenticationMethod = 'Basic',
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
		[Parameter(HelpMessage = 'Output type for the results. Valid values are CSV and Text.')]
		[ValidateSet('CSV', 'Text', 'None')]
		[string[]]$OutputType = 'None',
		[Parameter(HelpMessage = 'Output file path for the results.')]
		[string]$OutputFile,
		[Parameter(HelpMessage = 'Do not Write-Host and pass through the Object data.')]
		[switch]$PassThru
	)
	
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
						Get-WSManInstance -ComputerName $ServerName -Authentication $AuthenticationMethod -Credential:$Credential -Port 1270 -UseSSL -Enumerate "http://schemas.microsoft.com/wbem/wscim/1/cim-schema/2/$class`?__cimnamespace=root/scx"
					}
					else
					{
						Get-WSManInstance -ComputerName $ServerName -Authentication $AuthenticationMethod -Port 1270 -UseSSL -Enumerate "http://schemas.microsoft.com/wbem/wscim/1/cim-schema/2/$class`?__cimnamespace=root/scx"
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
							Get-WSManInstance -ComputerName $ServerName -Authentication $AuthenticationMethod -Credential:$Credential -Port 1270 -UseSSL -Enumerate "http://schemas.microsoft.com/wbem/wscim/1/cim-schema/2/$c`?__cimnamespace=root/scx"
						}
						else
						{
							Get-WSManInstance -ComputerName $ServerName -Authentication $AuthenticationMethod -Port 1270 -UseSSL -Enumerate "http://schemas.microsoft.com/wbem/wscim/1/cim-schema/2/$c`?__cimnamespace=root/scx"
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
			Write-Warning "An error occurred on $ServerName - $error"
			$results += "Error on $ServerName`: $_"
		}
	}
	
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
		$results | Export-Csv -Path $OutputPath -NoTypeInformation
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
		$results | Out-File -FilePath $OutputPath
		if (-NOT $PassThru)
		{
			Write-Host "Text file output located here: " -ForegroundColor Green -NoNewline
			Write-Host "$OutputPath" -ForegroundColor Yellow
		}
	}
	if ($OutputType -ne 'Text' -and $OutputType -ne 'CSV')
	{
		$results
	}
	return
}
if ($Servers -or $ComputerName -or $Password)
{
	Invoke-SCXWinRMEnumeration -ComputerName $ComputerName -Credential:$Credential -UserName $UserName -Password $Password -AuthenticationMethod $AuthenticationMethod -Classes $Classes -EnumerateAllClasses:$EnumerateAllClasses -OutputType:$OutputType -OutputFile $OutputFile -PassThru:$PassThru
}
else
{
	# Example usage
	#$Credentials = (Get-Credential)
	#Invoke-SCXWinRMEnumeration -ComputerName 'rhel7-9.contoso-2019.com' -AuthenticationMethod 'Basic' -Credential $Credentials -EnumerateAllClasses
	Invoke-SCXWinRMEnumeration
}
