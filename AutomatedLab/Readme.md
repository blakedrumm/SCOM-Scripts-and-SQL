# Prerequisites
 - AutomatedLab : https://github.com/AutomatedLab/AutomatedLab
 - Windows Server 2019 DataCenter Evaluation ISO : `C:\LabSources\ISOs\17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso` (https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2019)
 - System Center Operations Manager 2019 executable located here : `C:\LabSources\SoftwarePackages\SCOM_2019.exe`

# Introduction
This will install the following automatically for you in an Hyper-V Environment:
 - Domain Controller
 - SQL Server 2019
 - IIS Machine
 - System Center Operations Manager 2019
   - Reporting Services
   - Operations Manager Console

You will need to edit the lines in the `Global variables definition` region of the script.
