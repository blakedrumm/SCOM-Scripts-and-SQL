# Instructions

Extract tool to a directory (ex. C:\Data Collector)

You need to change to the directory in PowerShell to the script location, such as “cd C:\Data Collector”
 
If run on a SCOM management server (preferred) we will gather their SQL server names and DB names from the local registry.  Otherwise user will need to input names.

The script will attempt to query the SQL server remotely, and create CSV files in the local folder .\Output.

We will query both OperationsManager DB and Master DB in some cases, so having a high level of rights to SQL is preferred.

A zip file will be created in the directory where you are running the script, SDC_Results_04_04_1975.zip. This will cleanup the .\Output folder in the process.

This script has the ability to gather the following information:

 - SCOM Version Installed
 - Database Information / DB Version
 - SCOM RunAs Account Information
 - Registry TLS Configuration
 - Certificates
 - Event Logs
 - MSInfo32
 - Unsealed MP's

----

# Examples

##### Note: If you know you have Query rights against the DB(s) run any Switch (-Command) with -AssumeYes
###### Note #2: If you would like to run without setting the switches manually at Runtime, you can edit the switches right below the line that says '# Enter Switches here that you want to run if no switches are specified during runtime.'
 




## Certificates

To Check the Certificate(s) Installed on the Management Server(s) in the Management Group, and an Server:

    .\DataCollector.ps1 -CheckCertificates -Servers AppServer1.contoso.com

To Check the Certificate(s) Installed on the Management Server(s) in the Management Group:

    .\DataCollector.ps1 -CheckCertificates





## Event Logs

To gather Event Logs from 3 Agents and the Management Server(s) in the Current Management Group:

    .\DataCollector.ps1 -GetEventLogs -Servers Agent1.contoso.com, Agent2.contoso.com, Agent3.contoso.com

To just gather the Event Logs from the Management Server(s) in the Management Group:

    .\DataCollector.ps1 -GetEventLogs





## Management Packs

To Export Installed Management Packs:

    .\DataCollector.ps1 -ExportMPs





## RunAs Accounts

To Export RunAs Accounts from the Management Server(s) in the Management Group:

    .\DataCollector.ps1 -GetRunAsAccounts


## Check TLS Settings

To Check the TLS Settings on every Management Server in the Management Group:

    .\DataCollector.ps1 -CheckTLSRegKeys
