<#
	.SYNOPSIS
		Export SCOM SCX Certificates
	
	.DESCRIPTION
		This script will export SCOM SCX Certificates.
	
	.PARAMETER OutputDirectory
		The directory to output the certificate files.
	
	.PARAMETER ComputerName
		The computer names of each server you want to gather SCX Certificates from.
	
	.EXAMPLE
		PS C:\> .\Export-SCXCertificate -OutputDirectory "C:\Temp\SCXCertificates" -ComputerName "MS01-2019", "MS02-2019"
	
	.NOTES
		Author: Blake Drumm (blakedrumm@microsoft.com)

		My personal SCOM Blog: https://blakedrumm.com/
#>
param
(
	[string]$OutputDirectory = "C:\Temp\SCXCertificates",
	[array]$ComputerName = $env:COMPUTERNAME
)


function Export-SCXCertificate
{
	param (
		[string]$OutputDirectory = "C:\Temp\SCXCertificates",
		[array]$ComputerName = $env:COMPUTERNAME
	)
	
	# Ensure the base output directory exists
	if (-not (Test-Path -Path $OutputDirectory))
	{
		New-Item -Path $OutputDirectory -ItemType Directory -Force
	}
	
	# Script block to execute on each machine to export the SCX certificate
	$scriptBlock = {
		Get-ChildItem "Cert:\LocalMachine\Root\" | Where-Object { $_.DnsNameList.Unicode -contains "SCX-Certificate" } | ForEach-Object {
			$CertificateIssuer = if ($_.Issuer -match 'DC=(?<DomainComponent>[^,]+)')
			{
				$matches['DomainComponent']
			}
			else
			{
				'UnknownIssuer'
			}
			$FileName = "$CertificateIssuer.cer"
			# Output the filename and raw data
			[PSCustomObject]@{
				FileName = $FileName
				RawData  = $_.RawData
			}
		}
	}
	
	foreach ($Computer in $ComputerName)
	{
		# Define the output directory for the current computer
		$currentOutputDirectory = Join-Path -Path $OutputDirectory -ChildPath $Computer
		
		# Ensure the output directory for the current computer exists
		if (-not (Test-Path -Path $currentOutputDirectory))
		{
			New-Item -Path $currentOutputDirectory -ItemType Directory -Force
		}
		
		# Collect the certificate data from the remote computer
		$certData = Invoke-Command -ComputerName $Computer -ScriptBlock $scriptBlock
		
		# Write the raw data to certificate files in the local computer's directory
		foreach ($cert in $certData)
		{
			$localFilePath = Join-Path -Path $currentOutputDirectory -ChildPath $cert.FileName
			Set-Content -Path $localFilePath -Value $cert.RawData -Encoding Byte
		}
	}
}
if ($OutputDirectory -or $ComputerName)
{
	Export-SCXCertificate -OutputDirectory $OutputDirectory -ComputerName $ComputerName
}
else
{
	# Example usage:
	#Export-SCXCertificate -OutputDirectory "C:\Temp\SCXCertificates" -ComputerName "MS01-2019", "MS02-2019"
	Export-SCXCertificate
}
	
