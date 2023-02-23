# This script will export the SCOM User Roles to CSV or Text File Format.
# -----------------------------------------------
# Outputs the file to the current users desktop
# Initial Upload: June 20th, 2022
# Author: Blake Drumm (blakedrumm@microsoft.com)
# -----------------------------------------------
$UserRoles = @()
$UserRoleList = Get-SCOMUserRole
Write-Host "  Processing User Role:  " -ForegroundColor Cyan
foreach ($UserRole in $UserRoleList)
{
  Write-Host "    $UserRole" -ForegroundColor Magenta
  $UserRoles += New-Object -TypeName psobject -Property @{
    Name = $UserRole.Name;
    DisplayName = $UserRole.DisplayName;
    Description = $UserRole.Description;
    Users = ($UserRole.Users -join "; ");
  }
}
$UserRolesOutput = $UserRoles | Select-Object Name, DisplayName, Description, Users
$UserRolesOutput | Out-File "$env:USERPROFILE`\Desktop\UserRoles.txt" -Width 4096
$UserRolesOutput | Export-CSV -Path "$env:USERPROFILE`\Desktop\UserRoles.csv" -NoTypeInformation
