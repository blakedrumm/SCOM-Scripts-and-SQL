![Data Collector](/media/git-guidance/scom-data-collector.png)

# Download Link
https://aka.ms/SCOM-DataCollector

# Github Link
https://github.com/v-bldrum/SCOM-Scripts-and-SQL/releases/latest

# Requirements
System Center Operations Manager - Management Server

Administrator Privileges

Powershell 4+ (will still run on Powershell 3)

#Instructions

Download Zip file (More Actions - Download Zip File) and extract tool to a directory (ex. C:\Data Collector)

You need to change to the directory in PowerShell to the script location, such as “cd C:\Data Collector”
 
If run on a SCOM management server (preferred) we will gather their SQL server names and DB names from the local registry.  Otherwise user will need to input names.

The script will attempt to query the SQL server remotely, and create CSV files in the local folder .\Output.

We will query both OperationsManager DB and Master DB, so having a high level of rights to SQL is preferred.

A zip file will be created in the directory where you are running the script, SDC_Results_04_04_1975.zip. This will cleanup the .\Output folder in the process.

This script has the ability to gather the following information:

 - SCOM Version Installed
 - Database Information / DB Version
 - SCOM RunAs Account Information
 - Check TLS 1.2 Readiness
 - Certificates
 - Event Logs
 - MSInfo32
 - Unsealed MP's
 - Clock Synchronization
 - Latency Check (Ping Test)
 - this list is not complete..

----

# Examples

##### Note: If you know you have Query rights against the DB(s) run any Switch (-Command) with -AssumeYes
 

## Available Switches
Every Switch Available:

    .\DataCollector.ps1 -Servers -GetRunasAccounts -GetEventLogs -CheckCertificates -CheckTLS -ExportMPs -GPResult -MSInfo32 -SQLLogs -SQLOnly -CaseNumber -AssumeYes -GenerateHTML -All -PingAll


## Built in menu

To see the built in menu, run the script with no arguments or switches:

    .\DataCollector.ps1

You can also right click the `.ps1` file and Run with Powershell.



## Certificates

To Check the Certificate(s) Installed on the Management Server(s) in the Management Group, and an Server:

    .\DataCollector.ps1 -CheckCertificates -Servers AppServer1.contoso.com

To Check the Certificate(s) Installed on the Management Server(s) in the Management Group:

    .\DataCollector.ps1 -CheckCertificates


## Gather only SQL Queries

To gather only the SQL Queries run the following:

    .\DataCollector.ps1 -SQLOnly

If you know the account running the Data Collector has permissions against the SCOM Databases, run this:

    .\DataCollector.ps1 -SQLOnly -Yes




## Event Logs

To gather Event Logs from 3 Agents and the Management Server(s) in the Current Management Group:

    .\DataCollector.ps1 -GetEventLogs -Servers Agent1.contoso.com, Agent2.contoso.com, Agent3.contoso.com

To just gather the Event Logs from the Management Server(s) in the Management Group:

    .\DataCollector.ps1 -GetEventLogs





## Management Packs

To Export Installed Management Packs:

    .\DataCollector.ps1 -ExportMPs





## RunAs Accounts

To Export RunAs Accounts from the Management Server:

    .\DataCollector.ps1 -GetRunAsAccounts





## Check TLS 1.2 Readiness

To Run the TLS 1.2 Hardening Readiness Checks on every Management Server and SQL SCOM DB Server(s) in the Management Group:

    .\DataCollector.ps1 -CheckTLS





## All Switches
This will allow you to run every switch available currently, this supports the -Servers Switch:

    .\DataCollector.ps1 -All
    .\DataCollector.ps1 -All -Servers Agent1
    .\DataCollector.ps1 -All -Yes

<!--
## Welcome to GitHub Pages

You can use the [editor on GitHub](https://github.com/v-bldrum/SCOM-Scripts-and-SQL/edit/master/docs/index.md) to maintain and preview the content for your website in Markdown files.

Whenever you commit to this repository, GitHub Pages will run [Jekyll](https://jekyllrb.com/) to rebuild the pages in your site, from the content in your Markdown files.

### Markdown

Markdown is a lightweight and easy-to-use syntax for styling your writing. It includes conventions for

```markdown
Syntax highlighted code block

# Header 1
## Header 2
### Header 3

- Bulleted
- List

1. Numbered
2. List

**Bold** and _Italic_ and `Code` text

[Link](url) and ![Image](src)
```

For more details see [GitHub Flavored Markdown](https://guides.github.com/features/mastering-markdown/).

### Jekyll Themes

Your Pages site will use the layout and styles from the Jekyll theme you have selected in your [repository settings](https://github.com/v-bldrum/SCOM-Scripts-and-SQL/settings/pages). The name of this theme is saved in the Jekyll `_config.yml` configuration file.

### Support or Contact

Having trouble with Pages? Check out our [documentation](https://docs.github.com/categories/github-pages-basics/) or [contact support](https://support.github.com/contact) and we’ll help you sort it out.
-->
