# Jeremy D Pavleck <jpavleck@microsoft.com>
# Working with the SCOM REST API through PowerShell Examples



# The most important part is the construct used to initially authenticate. After that, everything else is fairly easy and uses SQL-like queries
# --- BEGIN AUTHENTICATION ENVELOPE
# We'll need to authenticate once per session
#       Set the Header and the Body
$SCOMHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$SCOMHeaders.Add('Content-Type', 'application/json; charset=utf-8')
$BodyRaw = "Windows"
$Bytes = [System.Text.Encoding]::UTF8.GetBytes($BodyRaw)
$EncodedText = [Convert]::ToBase64String($Bytes)
$JSONBody = $EncodedText | ConvertTo-Json


#       The SCOM REST API authentication URL
$URIBase = 'http://<Your SCOM MS>/OperationsManager/authenticate'

#       Initiate the Cross-Site Request Forgery (CSRF) token, this is to prevent CSRF attacks
$CSRFtoken = $WebSession.Cookies.GetCookies($UriBase) | ? { $_.Name -eq 'SCOM-CSRF-TOKEN' }
$SCOMHeaders.Add('SCOM-CSRF-TOKEN', [System.Web.HttpUtility]::UrlDecode($CSRFtoken.Value))


# --- END AUTHENTICATION ENVELOPE


# Request authentication and get the session variable we'll need to refer to with each call.
$Authentication = Invoke-RestMethod -Method Post -Uri $URIBase -Headers $SCOMHeaders -body $JSONBody -UseDefaultCredentials -SessionVariable WebSession


# Now we ask for the information we want


####################################
# To retrieve the effective monitoring configuration for an object, we need to perform this GET
$Response = Invoke-WebRequest -Uri 'http://<Your SCOM MS>/OperationsManager/effectiveMonitoringConfiguration/<MONITORING OBJECT GUID>?isRecursive=True' -Method GET -WebSession $WebSession
# If we have a server that has a GUID of dea8caf0-67bc-4fd2-ace8-39121499ddbf this how the request would look:
$Response = Invoke-WebRequest -Uri 'http://<Your SCOM MS>/OperationsManager/effectiveMonitoringConfiguration/dea8caf0-67bc-4fd2-ace8-39121499ddbf?isRecursive=True' -Method GET -WebSession $WebSession


# $Response will be a JSON/XML data table with the results of the query. To work with it more easily in PowerShell you can conver it into a hash table with
# $EffectiveMonitoring = ConvertFrom-JSON -InputObject $Response.Content - then you treat it like any other hash table in a script
# See https://learn.microsoft.com/en-us/rest/api/operationsmanager/effective-monitoring-configuration/effective-monitoring-configuration-data?tabs=HTTP for more information on this method as well as to
# view sample data


## A few more examples


# To return all Unsealed MPs:
$Response = Invoke-WebRequest -Uri 'http://<Your SCOM MS>/OperationsManager/data/UnsealedManagementPacks' -Method Get -WebSession $WebSession
# Then $UnsealedMPs = ConvertFrom-JSON -InputObject $Response.Content


######################
# Return the health state of a monitored computer in SCOM
# This uses a POST method.


# Construct our criteria
$Query = @(@{ "classId" = ""  
    # Criteria: Enter the name of the monitored computer (do not use the FQDN)
    "criteria" = "DisplayName = 'Operations Manager Management Group'"
    "displayColumns"    = "displayname", "healthstate", "name", "path"})


# Now convert it to JSON
$JSONQuery = $Query | ConvertTo-JSON


# Make the request
$Response = Invoke-RestMethod -Uri 'http://<Your SCOM MS>/OperationsManager/data/state' -Method Post -Body $JSONQuery -ContentType "application/json" -WebSession $WebSession


# Print it our
$State = $Response.Rows
$State




##############
# Return all of the SCOM consoles installed


# Criteria: Enter the displayname of the SCOM object
$Criteria = "DisplayName LIKE '%System Center Operations Manager Console%'"


# Convert our criteria to JSON format
$JSONBody = $Criteria | ConvertTo-Json


# Make the request
$Response = Invoke-WebRequest -Uri 'http://<Your SCOM MS>/OperationsManager/data/scomObjects' -Method Post -Body $JSONBody -WebSession $WebSession


# Convert our response from JSON format to a custom object or hash table
$Object = ConvertFrom-Json -InputObject $Response.Content


# Print out the object results
$Object.scopeDatas
