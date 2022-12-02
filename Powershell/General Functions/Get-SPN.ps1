## Active Directory: PowerShell Function to Get Service Principal Names (SPNs) ##
# Checked on 12/1/2022
## Original Location: https://gallery.technet.microsoft.com/scriptcenter/Get-SPN-Get-Service-3bd5524a
## New Location: https://github.com/blakedrumm/SCOM-Scripts-and-SQL/blob/master/Powershell/General%20Functions/Get-SPN.ps1

<#
	.SYNOPSIS
		This function will retrieve Service Principal Names (SPNs), with filters for computer name, service type, and port/instance
	
	.DESCRIPTION
		Get Service Principal Names
		
		Output includes:
		ComputerName - SPN Host
		Specification - SPN Port (or Instance)
		ServiceClass - SPN Service Class (MSSQLSvc, HTTP, etc.)
		sAMAccountName - sAMAccountName for the AD object with a matching SPN
		SPN - Full SPN string
	
	.PARAMETER ComputerName
		One or more hostnames to filter on.  Default is *
	
	.PARAMETER ServiceClass
		Service class to filter on.
		
		Examples:
		HOST
		MSSQLSvc
		TERMSRV
		RestrictedKrbHost
		HTTP
	
	.PARAMETER Specification
		Filter results to this specific port or instance name.
	
	.PARAMETER SPN
		If specified, filter explicitly and only on this SPN.  Accepts Wildcards.
	
	.PARAMETER Domain
		If specified, search in this domain. Use a fully qualified domain name, e.g. contoso.org
		
		If not specified, we search the current user's domain.
	
	.EXAMPLE
		Get-Spn -ServiceClass MSSQLSvc
		
		#This command gets all MSSQLSvc SPNs for the current domain
	
	.EXAMPLE
		Get-Spn -ComputerName SQLServer54, SQLServer55
		
		#List SPNs associated with SQLServer54, SQLServer55
	
	.EXAMPLE
		Get-SPN -SPN http*
		
		#List SPNs matching http*
	
	.EXAMPLE
		Get-SPN -ComputerName SQLServer54 -Domain Contoso.org
		
		# List SPNs associated with SQLServer54 in contoso.org
	
	.NOTES
		Adapted from
		http://www.itadmintools.com/2011/08/list-spns-in-active-directory-using.html
		http://poshcode.org/3234
		Version History
		v1.0   - Chad Miller - Initial release
		v1.1   - ramblingcookiemonster - added parameters to specify service type, host, and specification
		v1.1.1 - ramblingcookiemonster - added parameterset for explicit SPN lookup, added ServiceClass to results
		v1.2   - blakedrumm - Fixed regular expression for determining the computer to return and other changes
	
	.FUNCTIONALITY
		Active Directory
#>
param
(
	[Parameter(ValueFromPipeline = $true,
			   ValueFromPipelineByPropertyName = $true,
			   Position = 0,
			   HelpMessage = 'One or more hostnames to filter on.  Default is *')]
	[Alias('Servers')]
	[string[]]$ComputerName = "*",
	[Parameter(HelpMessage = 'Service class to filter on.')]
	[string]$ServiceClass = "*",
	[Parameter(HelpMessage = 'Filter results to this specific port or instance name.')]
	[string]$Specification = "*",
	[Parameter(HelpMessage = 'If specified, filter explicitly and only on this SPN.  Accepts Wildcards.')]
	[string]$SPN,
	[Parameter(HelpMessage = "If specified, search in this domain. Use a fully qualified domain name, e.g. contoso.org. If not specified, we search the current user's domain.")]
	[string]$Domain
)
function Invoke-GetSPN
{
	param
	(
		[Parameter(ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 0,
				   HelpMessage = 'One or more hostnames to filter on.  Default is *')]
		[Alias('Servers')]
		[string[]]$ComputerName = "*",
		[Parameter(HelpMessage = 'Service class to filter on.')]
		[string]$ServiceClass = "*",
		[Parameter(HelpMessage = 'Filter results to this specific port or instance name.')]
		[string]$Specification = "*",
		[Parameter(HelpMessage = 'If specified, filter explicitly and only on this SPN.  Accepts Wildcards.')]
		[string]$SPN,
		[Parameter(HelpMessage = "If specified, search in this domain. Use a fully qualified domain name, e.g. contoso.org. If not specified, we search the current user's domain.")]
		[string]$Domain
	)
	BEGIN
	{
		#Set up domain specification, borrowed from PyroTek3
		#https://github.com/PyroTek3/PowerShell-AD-Recon/blob/master/Find-PSServiceAccounts
		if (-not $Domain)
		{
			$ADDomainInfo = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
			$Domain = $ADDomainInfo.Name
		}
		$DomainDN = "DC=" + $Domain -Replace ("\.", ',DC=')
		$DomainLDAP = "LDAP://$DomainDN"
		Write-Verbose "Search root: $DomainLDAP"
		
		#Filter based on service type and specification.  For regexes, convert * to .*
		if (-NOT $SPN)
		{
			$ServiceFilter = If ($ServiceClass -eq "*") { ".*" }
			else { $ServiceClass }
			$SpecificationFilter = if ($Specification -ne "*") { ".$Domain`:$specification" }
			else { "*" }
		}
		else
		{
			#To use same logic as 'parse' parameterset, set these variables up...
			#$ComputerName = @("*")
			$Specification = "*"
			$ServiceFilter = $SPN.Replace('/', '\/')
		}
		
		#Set up objects for searching
		$SearchRoot = [ADSI]$DomainLDAP
		$searcher = New-Object System.DirectoryServices.DirectorySearcher
		$searcher.SearchRoot = $SearchRoot
		$searcher.PageSize = 1000
	}
	PROCESS
	{
		#Loop through all the computers and search!
		foreach ($computer in $ComputerName)
		{
			if ($computer -eq '*' -and $SpecificationFilter -eq '*')
			{
				$endQuery = '*'
			}
			else
			{
				$endQuery = "$computer$SpecificationFilter"
			}
			#Set filter - Parse SPN
			if ($SPN)
			{
				if (-NOT $computer)
				{
					$filter = "(servicePrincipalName=$SPN)"
				}
				else
				{
					if ($SPN -match "/*")
					{
						$filter = "(servicePrincipalName=$($SPN.Replace("/*", "/"))/$computer*)"
					}
					else
					{
						$filter = "(servicePrincipalName=$SPN/$computer*)"
					}
					
				}
			}
			else
			{
				$filter = "(servicePrincipalName=$ServiceClass/$endQuery)"
			}
			
			
			$filter = $filter.Replace("/*/*", "/*").Replace("//", "/").Replace("**", "*")
			$searcher.Filter = $filter
			$output = @()
			Write-Verbose "Searching for SPNs with filter $filter"
			foreach ($result in $searcher.FindAll())
			{
				$account = $result.GetDirectoryEntry()
				foreach ($servicePrincipalName in $account.servicePrincipalName)
				{
					Write-Verbose "`t`t$servicePrincipalName"
					#Regex will capture computername and port/instance
					if ($servicePrincipalName -match "^(?<ServiceClass>$ServiceFilter)(\/)(?<computer>$($Computer.Replace('*', '.*')))[^:]*(:{1}(?<port>\w+))?$")
					{
						#Build up an object, get properties in the right order, filter on computername
						$output += New-Object psobject -property @{
							ComputerName = $matches.computer
							ServiceClass = $matches.ServiceClass
							sAMAccountName = $($account.sAMAccountName)
							distinguishedName = $($account.distinguishedName)
							whenChanged  = $($account.whenChanged)
							SPN		     = $servicePrincipalName
						} #|
						#To get results that match parameters, filter on comp and spec
						#Where-Object { $_.ComputerName -like $computer -and $_.Specification -like $Specification }
					}
				}
			}
			return $output | Select-Object ComputerName, ServiceClass, sAMAccountName, distinguishedName, whenChanged, SPN | Sort-Object ComputerName, ServiceClass, sAMAccountName, whenChanged
		}
	}
	END
	{
		$searcher.Dispose()
	}
}
if (($ComputerName -ne '*') -or ($ServiceClass -ne '*') -or ($Specification -ne '*') -or $SPN -or $Domain)
{
	Invoke-GetSPN -ComputerName $ComputerName -ServiceClass $ServiceClass -Specification $Specification -SPN $SPN -Domain $Domain
}
else
{
    	# Edit the below line to change what happens when you run this script without any parameters. Or if you run the script from Powershell ISE.
	Invoke-GetSPN
}
