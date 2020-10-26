Function MP-Export
{
	if ((Test-Path -Path "$OutputPath\MPUnsealed") -eq $false)
				{
					Write-Host "  Creating Folder: $OutputPath\MPUnsealed" -ForegroundColor Gray
					md $OutputPath\MPUnsealed | Out-Null
				}
				else
				{
					Write-Host "  Existing Folder Found: $OutputPath\MPUnsealed" -ForegroundColor Gray
					Remove-Item $OutputPath\MPUnsealed -Recurse | Out-Null
					Write-Host "   Deleting folder contents" -ForegroundColor Gray
					md $OutputPath\MPUnsealed | out-null
					Write-Host "    Folder Created: $OutputPath\MPUnsealed" -ForegroundColor Gray
				}
				
				try
				{
					Get-SCOMManagementPack | Where{ $_.Sealed -eq $false } | Export-SCOMManagementPack -path $OutputPath\MPUnsealed | out-null
					Write-Host "    Completed Exporting Management Packs" -ForegroundColor Green
				}
				catch
				{
					Write-Warning $_
				}
}