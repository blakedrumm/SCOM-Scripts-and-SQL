<#
	.SYNOPSIS
		Get-LatencyReport
	
	.DESCRIPTION
		This script pings a list of servers to check network latency. It outputs the results as a custom PowerShell object, including each server's response status and average response time in milliseconds. This can be used to monitor the network connectivity and performance between the host machine and specified servers.
	
	.PARAMETER Servers
		A list of server DNS names or IP addresses to ping.
	
	.PARAMETER PingCount
		How many pings to the remote computer in order to gain the average.
	
	.EXAMPLE
		PS C:\> .\Get-LatencyReport.ps1
		
		This example uses the predefined list of servers in the script and outputs their latency report.
	
	.NOTES
		Modify the `$servers` variable to include the servers you wish to test. The script currently pings each server four times to calculate the average latency.
		
		Date Created: April 4th, 2024
		
		.AUTHOR
		Blake Drumm (blakedrumm@microsoft.com)
#>
[CmdletBinding()]
param
(
	[string[]]$Servers,
	[int]$PingCount = 4
)

if (-NOT $Servers)
{
	# Define a list of servers to ping
	$Servers = @"
google.com
microsoft.com
server3.contoso.com
"@ -split [Environment]::NewLine
}

# Loop through each server in the list
foreach ($server in $Servers)
{
	# Skip empty lines
	if (-not [string]::IsNullOrWhiteSpace($server))
	{
		try
		{
			# Ping the server with 4 echo requests
			$pingResults = Test-Connection -ComputerName $server -Count $PingCount -ErrorAction Stop
			
			# Calculate the average response time
			$averageResponseTime = ($pingResults | Measure-Object ResponseTime -Average).Average
			
			# Output the result as a custom object
			[PSCustomObject]@{
				Server			    = $server
				Status			    = "Success"
				AverageResponseTime = "$averageResponseTime ms"
			}
		}
		catch
		{
			# If the ping fails, output the server with a failure status and no response time
			[PSCustomObject]@{
				Server			    = $server
				Status			    = "Failed"
				AverageResponseTime = "N/A"
			}
		}
	}
}
