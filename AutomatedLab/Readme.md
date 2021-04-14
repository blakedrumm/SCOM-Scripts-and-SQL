# Prerequisites
 - AutomatedLab : https://github.com/AutomatedLab/AutomatedLab
 - Windows Server 2019 ISO (https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2019) : \
   `C:\LabSources\ISOs\17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso`
 - System Center Operations Manager 2019 executable located here : \
   `C:\LabSources\SoftwarePackages\SCOM_2019.exe`
 - SQL Server 2019 ISO : \
   `C:\LabSources\ISOs\SQLServer2019-x64-ENU.iso`

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

You will need to edit the lines in the `Global variables definition` region of the script.
