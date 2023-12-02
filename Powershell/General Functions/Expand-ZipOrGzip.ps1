<#
    .SYNOPSIS
        Expand-ZipOrGzip - Extracts ZIP or GZIP files, including TAR within GZIP.

    .DESCRIPTION
        This function extracts ZIP or GZIP compressed files. If a GZIP file contains a TAR file, it extracts the TAR file as well. Notifications are shown at various stages of the process.

    .PARAMETER FilePath
        The path of the ZIP or GZIP file to be extracted.

    .PARAMETER DestinationFolderPath
        The destination folder path where the extracted files will be placed.

    .PARAMETER HideProgressDialog
        Optionally, hides the progress dialog during extraction.

    .PARAMETER OverwriteExistingFiles
        Optionally, overwrites existing files in the destination directory without prompting.

    .EXAMPLE
        Expand-ZipOrGzip -FilePath "C:\path\to\file.gz" -DestinationFolderPath "C:\extract\here" -OverwriteExistingFiles
        Extracts a GZIP file to the specified destination, overwriting any existing files.

    .EXAMPLE
        Expand-ZipOrGzip -FilePath "C:\*.gz" -DestinationFolderPath "C:\extract\here" -OverwriteExistingFiles
        Extracts a GZIP file of wildcard to the specified destination, overwriting any existing files.

    .EXAMPLE
        Expand-ZipOrGzip -FilePath "C:\path\to\archive.zip" -DestinationFolderPath "C:\extract\zip"
        Extracts a ZIP file to the specified destination folder.

    .NOTES
        Author: Blake Drumm (blakedrumm@microsoft.com)
        Created on: December 1st, 2023
        Last Modified: December 2nd, 2023

        Personal Blog: https://blakedrumm.com
#>
param
(
	[ValidateNotNullOrEmpty()]
	[string]$FilePath,
	[ValidateNotNullOrEmpty()]
	[string]$DestinationFolderPath,
	[switch]$HideProgressDialog,
	[switch]$OverwriteExistingFiles
)

# Function to show toast notification
function Show-ToastNotification
{
	param (
		[string]$Title,
		[string]$Text,
		[int]$Duration = 500,
		[string]$IconType = 'Info'
	)
	
	Add-Type -AssemblyName System.Windows.Forms
	$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
	
	$notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
	$notifyIcon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::$IconType
	$notifyIcon.BalloonTipTitle = $Title
	$notifyIcon.BalloonTipText = $Text
	$notifyIcon.Visible = $true
	$notifyIcon.ShowBalloonTip($Duration)
}

function Expand-ZipOrGzip (
	[ValidateNotNullOrEmpty()][string]$FilePath,
	[ValidateNotNullOrEmpty()][string]$DestinationFolderPath,
	[switch]$HideProgressDialog,
	[switch]$OverwriteExistingFiles
)
{
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
				
				if ($fileExtension -eq ".gz")
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
	Expand-ZipOrGzip -FilePath $FilePath -DestinationFolderPath $DestinationFolderPath -HideProgressDialog:$HideProgressDialog -OverwriteExistingFiles:$OverwriteExistingFiles
}
else
{
	# Example usage
	Expand-ZipOrGzip
}
