# SCOM API PowerShell Script
# This script includes functions to interact with SCOM's REST API
# Author: Blake Drumm (blakedrumm@microsoft.com)

# Initialize SCOM API Base URL
$URIBase = 'http://<WebConsoleURL>/OperationsManager'

# Function to initialize HTTP headers and CSRF token for SCOM API
function Initialize-SCOMHeaders {
    $SCOMHeaders = @{
        'Content-Type' = 'application/json; charset=utf-8'
    }

    $CSRFtoken = $WebSession.Cookies.GetCookies($URIBase) | Where-Object { $_.Name -eq 'SCOM-CSRF-TOKEN' }
    $SCOMHeaders['SCOM-CSRF-TOKEN'] = [System.Web.HttpUtility]::UrlDecode($CSRFtoken.Value)
    return $SCOMHeaders
}

# Function to authenticate with the SCOM API
function Authenticate-SCOM {
    param (
        [PSCredential]$Credential = $null
    )

    $bodyRaw = "Windows"
    $encodedText = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($bodyRaw))
    $JSONBody = $encodedText | ConvertTo-Json

    $SCOMHeaders = Initialize-SCOMHeaders

    if ($Credential -ne $null) {
        Invoke-RestMethod -Method Post -Uri "$URIBase/authenticate" -Headers $SCOMHeaders -Body $JSONBody -Credential $Credential -SessionVariable WebSession
    } else {
        Invoke-RestMethod -Method Post -Uri "$URIBase/authenticate" -Headers $SCOMHeaders -Body $JSONBody -UseDefaultCredentials -SessionVariable WebSession
    }
}

# Function to fetch Effective Monitoring Configuration by GUID
function Get-EffectiveMonitoringConfiguration {
    param (
        [string]$guid
    )

    $uri = "$URIBase/effectiveMonitoringConfiguration/$guid`?isRecursive=True"
    $response = Invoke-WebRequest -Uri $uri -Method GET -WebSession $WebSession
    return $response.Content | ConvertFrom-Json
}

# Function to fetch Unsealed Management Packs
function Get-UnsealedManagementPacks {
    $uri = "$URIBase/data/UnsealedManagementPacks"
    $response = Invoke-WebRequest -Uri $uri -Method GET -WebSession $WebSession
    return $response.Content | ConvertFrom-Json
}

# Function to fetch the state of the Management Group
function Get-ManagementGroupState {
    $query = @(@{
        "classId"         = ""
        "criteria"        = "DisplayName = 'Operations Manager Management Group'"
        "displayColumns"  = "displayname", "healthstate", "name", "path"
    })

    $JSONQuery = $query | ConvertTo-Json
    $response = Invoke-RestMethod -Uri "$URIBase/data/state" -Method Post -Body $JSONQuery -ContentType "application/json" -WebSession $WebSession
    return $response.Rows
}

# Function to fetch all Windows Servers
function Get-WindowsServers {
    $criteria = "DisplayName LIKE 'Microsoft Windows Server%'"
    $JSONBody = $criteria | ConvertTo-Json

    $uri = "$URIBase/data/scomObjects"
    $response = Invoke-WebRequest -Uri $uri -Method Post -Body $JSONBody -WebSession $WebSession
    return ($response.Content | ConvertFrom-Json).scopeDatas
}

# ------------------------------------------------------------------------------------------
# Main Execution

# Uncomment the below lines if you want to authenticate using specific credentials
# $cred = Get-Credential
# Authenticate-SCOM -Credential $cred

# Uncomment the below line if you want to authenticate using the current user's credentials
# Authenticate-SCOM

Write-Output "--------------------------------"

# Fetch all Windows Servers
$WindowsServers = Get-WindowsServers
Write-Output "Windows Servers:`n$($WindowsServers | ConvertTo-Json)"

Write-Output "-----------------------------------------"

# Get Unsealed Management Packs
$unsealedMPs = Get-UnsealedManagementPacks
Write-Output "Unsealed MPs:`n$($unsealedMPs | ConvertTo-Json)"

Write-Output "--------------------------------"

# Get Management Group Health Status
$state = Get-ManagementGroupState
Write-Output "Monitored Computer State:`n$($state | ConvertTo-Json)"

Write-Output "--------------------------------"
