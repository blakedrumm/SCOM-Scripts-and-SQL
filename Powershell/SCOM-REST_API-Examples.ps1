# SCOM API PowerShell Script
# This script includes functions to interact with SCOM's REST API
# Author: Blake Drumm (blakedrumm@microsoft.com)
# Date Created: November 1st, 2023
# Date Updated: January 4th, 2024
# Blog: https://blakedrumm.com/

$MainURL = 'http://MS02-2022.contoso-2022.com/OperationsManager'

function Authenticate-SCOMAPI
{
    param (
        [PSCredential]$Credential = $null
    )
    # Set SCOM Header and the Body
    $SCOMHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $SCOMHeaders.Add('Content-Type', 'application/json; charset=utf-8')
    $BodyRaw = "Windows"
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($BodyRaw)
    $EncodedText = [Convert]::ToBase64String($Bytes)
    $JSONBody = $EncodedText | ConvertTo-Json

    # Authentication
    if ($Credential -ne $null) {
        Invoke-RestMethod -Method Post -Uri "$MainURL/authenticate" -Headers $SCOMHeaders -Body $JSONBody -Credential $Credential -SessionVariable WebSession
    } else {
        Invoke-RestMethod -Method Post -Uri "$MainURL/authenticate" -Headers $SCOMHeaders -Body $JSONBody -UseDefaultCredentials -SessionVariable WebSession
    }
    $script:WebSession = $WebSession
    # Initiate the Cross-Site Request Forgery (CSRF) token, this is to prevent CSRF attacks
    $CSRFtoken = $WebSession.Cookies.GetCookies($MainURL) | ? { $_.Name -eq 'SCOM-CSRF-TOKEN' }
    $SCOMHeaders.Add('SCOM-CSRF-TOKEN', [System.Web.HttpUtility]::UrlDecode($CSRFtoken.Value))
}
Authenticate-SCOMAPI

# Function to fetch all installed SCOM Consoles
function Get-SCOMConsoles
{
    # Criteria: Enter the displayname of the SCOM object
    $Criteria = "DisplayName LIKE '%System Center Operations Manager Console%'"
 
    # Convert our criteria to JSON format
    $JSONBody = $Criteria | ConvertTo-Json
 
    $Response = Invoke-WebRequest -Uri "$MainURL/OperationsManager/data/scomObjects" -Method Post -Body $JSONBody -WebSession $script:WebSession
 
    # Convert our response from JSON format to a custom object or hash table
    $Object = ConvertFrom-Json -InputObject $Response.Content
 
    # Print out the object results
    $Object.scopeDatas
}

# Function to fetch all Windows Servers
function Get-WindowsServers {
    $criteria = "DisplayName LIKE 'Microsoft Windows Server%'"
    $JSONBody = $criteria | ConvertTo-Json

    $response = Invoke-WebRequest -Uri "$MainURL/data/scomObjects" -Method Post -Body $JSONBody -WebSession $script:WebSession
    return ($response.Content | ConvertFrom-Json).scopeDatas
}

# Function to fetch the state of the Management Group
function Get-ManagementGroupState {
    $query = @(@{
        "classId"         = ""
        "criteria"        = "DisplayName = 'Operations Manager Management Group'"
        "displayColumns"  = "displayname", "healthstate", "name", "path"
    })

    $JSONQuery = $query | ConvertTo-Json
    $response = Invoke-RestMethod -Uri "$MainURL/data/state" -Method Post -Body $JSONQuery -ContentType "application/json" -WebSession $script:WebSession
    return $response.Rows
}

# Function to fetch Unsealed Management Packs
function Get-UnsealedManagementPacks {
    $response = Invoke-WebRequest -Uri "$MainURL/data/UnsealedManagementPacks" -Method GET -WebSession $script:WebSession
    return $response.Content | ConvertFrom-Json
}

# Function to fetch Effective Monitoring Configuration by GUID
function Get-EffectiveMonitoringConfiguration {
    param (
        [string]$guid
    )
    $uri = "$MainURL/effectiveMonitoringConfiguration/$guid`?isRecursive=True"
    $response = Invoke-WebRequest -Uri $uri -Method GET -WebSession $script:WebSession
    return $response.Content | ConvertFrom-Json
}

# ------------------------------------------------------------------------------------------
# Main Execution

# ------------------------------------------------------------------------------------------
#region Authentication

# Uncomment the below lines if you want to authenticate using specific credentials
# $cred = Get-Credential
# Authenticate-SCOM -Credential $cred

# Uncomment the below line if you want to authenticate using the current user's credentials
# Authenticate-SCOM

#endregion
# ------------------------------------------------------------------------------------------

#Write-Output "-----------------------------------------"

# Replace 'your-guid-here' with the actual GUID of the monitoring object
#$MonitoringObjectGUID = 'your-guid-here'

# Fetch the effective monitoring configuration for the given GUID
#$EffectiveConfig = Get-EffectiveMonitoringConfiguration -guid $MonitoringObjectGUID

# Output the effective monitoring configuration in JSON format
#Write-Output "Effective Monitoring Configuration:`n$($EffectiveConfig | ConvertTo-Json)"

Write-Output "-----------------------------------------"

# Fetch all Windows Servers
$WindowsServers = Get-WindowsServers
Write-Output "Windows Servers:`n$($WindowsServers | ConvertTo-Json)"

Write-Output "-----------------------------------------"

# Get Unsealed Management Packs
$unsealedMPs = Get-UnsealedManagementPacks
Write-Output "Unsealed MPs:`n$($unsealedMPs | ConvertTo-Json)"

Write-Output "-----------------------------------------"

# Get Management Group Health Status
$state = Get-ManagementGroupState
Write-Output "Monitored Computer State:`n$($state | ConvertTo-Json)"

Write-Output "-----------------------------------------"
