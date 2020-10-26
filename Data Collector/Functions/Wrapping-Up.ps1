Function Wrap-Up
{
	try
	{
		Move-Item $OutputPath\*.csv $OutputPath\csv
		$FolderNames = (Get-ChildItem "$OutputPath`\*.evtx" | Select-Object Name -ExpandProperty Name) | % { $_.split(".")[0] } | Select -Unique
		$FolderNames | % {
			$currentServer = $_
			mkdir "$OutputPath`\Event Logs\$_" | Out-Null;
			mkdir "$OutputPath`\Event Logs\$_`\localemetadata\" | Out-Null;
			Get-ChildItem "$OutputPath`\$_*.evtx" | % { Move-Item $_ -Destination "$OutputPath`\Event Logs\$currentServer" | Out-Null }
			Get-ChildItem "$OutputPath`\$_*.mta" | % { Move-Item $_ -Destination "$OutputPath`\Event Logs\$currentServer`\localemetadata\" | Out-Null }
		}
	}
	catch
	{
		Write-Warning $_
	}
	#Move-Item $OutputPath\*.mta $OutputPath\eventlogs\localemetadata
	
	#Zip output
	$Error.Clear()
	Write-Host "`nCreating zip file of all CSV files." -ForegroundColor DarkCyan
	[Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
	[System.AppDomain]::CurrentDomain.GetAssemblies() | Out-Null
	$SourcePath = Resolve-Path $OutputPath
	[string]$filedate = (Get-Date).tostring("MM_dd_yyyy")
	
	if ($CaseNumber)
	{
		[string]$destfilename = "SDC_Results_" + "$CaseNumber" + "_" + $filedate + ".zip"
	}
	else
	{
		[string]$destfilename = "SDC_Results_" + $filedate + ".zip"
	}
	
	[string]$global:destfile = "$ScriptPath" + "\" + "$destfilename"
	IF (Test-Path $destfile)
	{
		#File exists from a previous run on the same day - delete it
		Write-Host `n"-Found existing zip file: $destfile.`n Deleting existing file." -ForegroundColor DarkGreen
		Remove-Item $destfile -Force
	}
	$compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
	$includebasedir = $false
	[System.IO.Compression.ZipFile]::CreateFromDirectory($SourcePath, $destfile, $compressionLevel, $includebasedir) | Out-Null
	IF ($Error)
	{
		Write-Error "Error creating zip file."
	}
	ELSE
	{
		Write-Host "`n-Cleaning up output directory." -ForegroundColor DarkCyan
		Remove-Item $OutputPath -Recurse
		Write-Host "`n--Saved zip file to: $destfile." -ForegroundColor Cyan
	}
}