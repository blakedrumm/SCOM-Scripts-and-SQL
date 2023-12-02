<#
    .SYNOPSIS
        Expand-ZipOrGzip - Extracts ZIP or GZIP files, including TAR within GZIP, using 7-Zip for GZIP files if specified, with an option to hide toast notifications.

    .DESCRIPTION
        This function extracts ZIP or GZIP compressed files. If a GZIP file contains a TAR file, it extracts the TAR file as well. Notifications are shown at various stages of the process unless hidden by a switch. If the -7zip switch is used, GZIP files are extracted using 7-Zip.

    .PARAMETER FilePath
        The path of the ZIP or GZIP file to be extracted.

    .PARAMETER DestinationFolderPath
        The destination folder path where the extracted files will be placed.

    .PARAMETER HideProgressDialog
        Optionally, hides the progress dialog during extraction.

    .PARAMETER OverwriteExistingFiles
        Optionally, overwrites existing files in the destination directory without prompting.

    .PARAMETER Use7zip
        Optionally, use 7-Zip for extracting GZIP files.

    .PARAMETER HideToastNotifications
        Optionally, hides toast notifications during the process.

    .EXAMPLE
        Expand-ZipOrGzip -FilePath "C:\path\to\file.gz" -DestinationFolderPath "C:\extract\here" -7zip
        Extracts a GZIP file using 7-Zip to the specified destination.

    .NOTES
        Author: Blake Drumm (blakedrumm@microsoft.com)
        Created on: December 1st, 2023
        Last Modified: December 2nd, 2023

        Personal Blog: https://blakedrumm.com
#>
param
(
	[string]$FilePath,
	[string]$DestinationFolderPath,
	[switch]$HideProgressDialog,
	[switch]$OverwriteExistingFiles,
	[switch]$Use7zip,
	[switch]$HideToastNotifications
)

function Expand-ZipOrGzip (
	[ValidateNotNullOrEmpty()]
	[string]$FilePath,
	[ValidateNotNullOrEmpty()]
	[string]$DestinationFolderPath,
	[switch]$HideProgressDialog,
	[switch]$OverwriteExistingFiles,
	[switch]$Use7zip,
	[switch]$HideToastNotifications
)
{
	
	# Global variable for NotifyIcon
	$Global:notifyIcon = $null
	
	# Function to show toast notification
	function Show-ToastNotification
	{
		param (
			[string]$Title,
			[string]$Text,
			[int]$Duration = 5000,
			# Duration in milliseconds
			[string]$IconType = 'Info'
		)
		
		if (-not $HideToastNotifications)
		{
			Add-Type -AssemblyName System.Windows.Forms
			
			# Reuse the existing NotifyIcon or create a new one
			if ($null -eq $Global:notifyIcon)
			{
				$Global:notifyIcon = New-Object System.Windows.Forms.NotifyIcon
				$Global:notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
			}
			
			$Global:notifyIcon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::$IconType
			$Global:notifyIcon.BalloonTipTitle = $Title
			$Global:notifyIcon.BalloonTipText = $Text
			$Global:notifyIcon.Visible = $true
			$Global:notifyIcon.ShowBalloonTip($Duration)
			
			# Schedule disposal of the NotifyIcon
			Start-Sleep -Milliseconds ($Duration + 100)
			$Global:notifyIcon.Visible = $false
			$Global:notifyIcon.Dispose()
			$Global:notifyIcon = $null
		}
	}
	
	# Resolve file paths with wildcard characters
	$resolvedFilePaths = Resolve-Path $FilePath
	foreach ($resolvedFilePath in $resolvedFilePaths)
	{
		Show-ToastNotification -Title "Extraction Started" -Text "Starting extraction of: `n$resolvedFilePath"
		
		if ((Test-Path $resolvedFilePath) -and (Test-Path $DestinationFolderPath) -and ((Get-Item $DestinationFolderPath).PSIsContainer))
		{
			try
			{
				$fileExtension = [System.IO.Path]::GetExtension($resolvedFilePath).ToLower()
				if ($fileExtension -eq ".gz" -and $Use7zip)
				{
					# Using 7zip for extraction
					$outputFolderPath = [System.IO.Path]::GetDirectoryName($DestinationFolderPath)
					$outputFileName = [System.IO.Path]::GetFileNameWithoutExtension($resolvedFilePath)
					$7zipPath = "C:\Program Files\7-Zip\7z.exe" # Adjust this path as needed
					
					Show-ToastNotification -Title "7-Zip Extraction Started" -Text "Starting 7-Zip extraction of: `n$resolvedFilePath"
					
					Start-Process -FilePath $7zipPath -ArgumentList "e `"$resolvedFilePath`" -o`"$outputFolderPath`" -y" -NoNewWindow -Wait
					
					Show-ToastNotification -Title "7-Zip Extraction Complete" -Text "7-Zip extraction complete for: `n$resolvedFilePath"
				}
				elseif ($fileExtension -eq ".gz")
				{
					$outputFilePath = [System.IO.Path]::Combine($DestinationFolderPath, [System.IO.Path]::GetFileNameWithoutExtension($resolvedFilePath))
					$error.Clear()
					try
					{
						$gzipStream = New-Object System.IO.FileStream($resolvedFilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read) -ErrorAction Stop
						$decompressionStream = New-Object System.IO.Compression.GzipStream($gzipStream, [System.IO.Compression.CompressionMode]::Decompress)
						$outputFileStream = New-Object System.IO.FileStream($outputFilePath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
						
						$buffer = New-Object byte[](1024 * 10)
						$totalBytesRead = 0
						$totalLength = $gzipStream.Length
						while ($true)
						{
							$readBytes = $decompressionStream.Read($buffer, 0, $buffer.Length)
							if ($readBytes -eq 0) { break }
							$outputFileStream.Write($buffer, 0, $readBytes)
							$totalBytesRead += $readBytes
							$progress = [math]::Min([math]::Round(($totalBytesRead / $totalLength) * 100, 2), 99.99)
							$formattedProgress = "{0:F2}" -f $progress # Format as double digit
							Write-Progress -Activity "Extracting GZIP ($resolvedFilePath)" -Status "$formattedProgress% Complete." -PercentComplete $progress
						}
					}
					catch
					{
						Show-ToastNotification -Title "Error occurred" -Text "$error" -IconType Error
						break
					}
					finally
					{
						# Ensure streams are properly closed and disposed
						try
						{
							$decompressionStream.Dispose()
						}
						catch
						{
							Out-Null
						}
						try
						{
							$gzipStream.Dispose()
						}
						catch
						{
							Out-Null
						}
						try
						{
							$outputFileStream.Dispose()
						}
						catch
						{
							Out-Null
						}
					}
					$decompressionStream.Close()
					$gzipStream.Close()
					$outputFileStream.Close()
					
					Write-Progress -Activity "Extracting GZIP ($resolvedFilePath)" -Status "100% Complete." -PercentComplete 100
					Show-ToastNotification -Title "GZIP Extraction Complete" -Text "GZIP extraction complete for: `n$resolvedFilePath"
					
					if ([System.IO.Path]::GetExtension($outputFilePath).ToLower() -eq ".tar")
					{
						Show-ToastNotification -Title "TAR Extraction Starting" -Text "TAR extraction starting for: `n$resolvedFilePath"
						Start-Process -FilePath "tar" -ArgumentList "-xvf", "`"$outputFilePath`"", "-C", "`"$DestinationFolderPath`"" -NoNewWindow -Wait
						Remove-Item -Path $outputFilePath
						Show-ToastNotification -Title "TAR Extraction Complete" -Text "TAR extraction complete for: `n$resolvedFilePath"
					}
				}
				elseif ($fileExtension -eq ".zip")
				{
					$copyFlags = 0x00
					if ($HideProgressDialog)
					{
						$copyFlags += 0x04
					}
					if ($OverwriteExistingFiles)
					{
						$copyFlags += 0x10
					}
					Show-ToastNotification -Title "ZIP Extraction Starting" -Text "ZIP extraction starting for: `n$resolvedFilePath"
					$shell = New-Object -ComObject Shell.Application
					$zipFile = $shell.NameSpace($resolvedFilePath)
					$destinationFolder = $shell.NameSpace($DestinationFolderPath)
					
					$destinationFolder.CopyHere($zipFile.Items(), $copyFlags)
					Show-ToastNotification -Title "ZIP Extraction Complete" -Text "ZIP extracted to: `n$destinationFolder"
				}
				else
				{
					throw "Unsupported file format. Only .zip, .gz, and .tar.gz extensions are supported."
				}
			}
			finally
			{
				if ($zipFile -ne $null)
				{
					[void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($zipFile)
				}
				if ($destinationFolder -ne $null)
				{
					[void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($destinationFolder)
				}
				if ($shell -ne $null)
				{
					[void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell)
				}
			}
		}
	}
	Show-ToastNotification -Title "Extraction Complete" -Text "Extraction complete, file located: `n$DestinationFolderPath"
}
if ($FilePath -or $DestinationFolderPath)
{
	Expand-ZipOrGzip -FilePath $FilePath -DestinationFolderPath $DestinationFolderPath -HideProgressDialog:$HideProgressDialog -OverwriteExistingFiles:$OverwriteExistingFiles -Use7zip:$Use7zip
}
else
{
	# --------------------------------------------------------------------------
	# Example 1:
	# Expand-ZipOrGzip -FilePath "G:\*.tar.gz" -DestinationFolderPath "C:\Output" -OverwriteExistingFiles -Use7zip
	# --------------------------------------------------------------------------
	# Example 2:
	# Expand-ZipOrGzip -FilePath "G:\File.zip" -DestinationFolderPath "C:\Output" -OverwriteExistingFiles
	# --------------------------------------------------------------------------
	# Modify the line below to change what happens when you run this script from PowerShell ISE
	Expand-ZipOrGzip
}
