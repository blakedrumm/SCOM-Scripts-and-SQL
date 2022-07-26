cd 'C:\Program Files\Microsoft System Center\Operations Manager'
$output = $null
$output = @()

$files = Get-ChildItem .\* -Recurse
foreach ($file in $files)
{
	$fileversion = (Get-Item $file).VersionInfo.FileVersion
	$productversion = (Get-Item $file).VersionInfo.ProductVersion
	if ($fileversion -or $productversion)
	{
		$fileData = Get-Item $file
		$output += @{ FilePath = $fileData.FullName; FileVersion = $fileversion; ProductVersion = $productversion; DateModified = ($fileData.LastWriteTimeUtc.ToLocalTime()) }
	}
}
cls
$output | % { new-object PSObject -Property $_ } | Sort-Object -Property FileVersion, FilePath | Select-Object FilePath, FileVersion, ProductVersion, DateModified
