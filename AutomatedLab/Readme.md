![SCOM 2019 Automated Lab](/media/git-guidance/automated-lab-scom-2019.png)

# Prerequisites
 - AutomatedLab : https://github.com/AutomatedLab/AutomatedLab
 - Windows Server 2019 ISO (https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2019) : \
   `C:\LabSources\ISOs\17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso`
 - SQL Server 2019 ISO (https://go.microsoft.com/fwlink/?linkid=866664) : \
   `C:\LabSources\ISOs\SQLServer2019-x64-ENU.iso`
 - System Center Operations Manager 2019 executable located here (https://www.microsoft.com/en-US/evalcenter/evaluate-system-center-2019) : \
   `C:\LabSources\SoftwarePackages\SCOM_2019.exe`
 - SQL Server Powershell Nuget Package located here (https://www.powershellgallery.com/packages/SqlServer/21.0.17099) : \
   `C:\LabSources\SoftwarePackages\SqlServer*.nupkg`
 - SQL Server Management Studio (https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms) : \
   `C:\LabSources\SoftwarePackages\SQL2019\SSMS-Setup-ENU.exe`
 - SQL Server 2019 Latest Cumulative Update (https://www.microsoft.com/en-us/download/confirmation.aspx?id=100809) : \
   `C:\LabSources\SoftwarePackages\SQLServer2019-KB5001090-x64.exe`
 - SQL Server Reporting Services (https://www.microsoft.com/en-us/download/details.aspx?id=100122) : \
   `C:\LabSources\SoftwarePackages\SQLServer2019_ReportingServices.exe`
 - *OPTIONAL:* Notepad++ (https://notepad-plus-plus.org/) : \
   `C:\LabSources\SoftwarePackages\npp.*.*.*.Installer.x64.exe`

# Introduction
This will install the following automatically for you in an Hyper-V Environment:
 - Domain Controller
 - SQL Server 2019
   - SQL Server 2019 for Microsoft Windows Latest Cumulative Update
 - IIS Machine
 - System Center Operations Manager 2019
   - Operations Manager Management Server
   - Operations Manager Reporting Services
   - Operations Manager Console
   - Operations Manager Web Console

The script will also deploy the following tool(s):
 - Notepad++

You will need to edit the lines below the `Global variables definition` region of the script.

### Names of the Hyper-V Servers that can be deployed with this script:
Hostname | Role
------------ | -------------
DC01 | Domain Controller
SCOM-2019-MS1 | System Center Operations Manager 2019
&nbsp; | Management Server
&nbsp; | Web Console
SQL-2019 | SQL Server 2019
&nbsp; | Reporting Services
IIS-Agent | IIS Windows
RHEL7-9 | Redhat 7.9
