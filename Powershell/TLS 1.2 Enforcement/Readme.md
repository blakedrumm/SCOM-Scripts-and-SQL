![Enforce TLS 1.2](/media/git-guidance/projects/enforce-tls-1-2-scom.png)

## Introduction
This PowerShell script will allow you to enforce TLS 1.2 in your SCOM Environment to help you to secure your environment. It will attempt to auto download the prerequisites if they are not present in the local directory (or if you set the parameter **DirectoryForPrerequisites** to another path it will check there). The script from a high level will do the following:
1. Creates a log file to Program Data (`C:\ProgramData\SCOM_TLS_1.2_-_<Month>-<Day>-<Year>.log`).
2. Locate or Download the prerequisites for TLS 1.2 Enforcement.
3. Checks the SCOM Role (*Management Server, Web Console, ACS Collector*).
4. Checks the version of System Center Operations Manager to confirm supportability of TLS enforcement.
5. Checks the .NET version to confirm you are on a valid version.
6. Checks the SQL version (on both the Operations Manager and Data Warehouse Database Instances) to confirm your version of SQL supports TLS enforcement.
7. Checks and/or installs the *(prerequisite software)* MSOLEDB driver (or SQL Client).
8. Checks and/or installs the *(prerequisite software)* ODBC driver.
9. Checks and/or modifies the registry to enforce TLS 1.2 (If your using Window Server 2022 (or newer) or Windows 11 (or newer) it will attempt to enforce TLS 1.2 **and** TLS 1.3).
10. Ask to reboot the machine to finalize the configuration.

## Argument List

| Parameter                    | Alias | ValueFromPipeline | Type   | Description                                                                               |
|------------------------------|-------|-------------------|--------|-------------------------------------------------------------------------------------------|
| AssumeYes                    | yes   |                   | Switch | The script will not ask any questions. Good for unattended runs.                          |
| DirectoryForPrerequisites    | dfp   |                   | String | The directory to save / load the prerequisites from. Default is the current directory.    |
| ForceDownloadPrerequisites   | fdp   |                   | Switch | Force download the prerequisites to the directory specified in DirectoryForPrerequisites. |
| SkipDotNetCheck              | sdnc  |                   | Switch | Skip the .NET Check step.                                                                 |
| SkipDownloadPrerequisites    | sdp   |                   | Switch | Skip downloading the prerequisite files to current directory.                             |
| SkipModifyRegistry           | smr   |                   | String | Skip any registry modifications.                                                          |
| SkipRoleCheck                | src   |                   | Switch | Skip the SCOM Role Check step.                                                            |
| SkipSQLQueries               | ssq   |                   | Switch | Skip any check for SQL version compatibility.                                             |
| SkipSQLSoftwarePrerequisites | sssp  |                   | Switch | Skip the ODBC, MSOLEDBSQL, and/or Microsoft SQL Server 2012 Native Client.                |
| SkipVersionCheck             | svc   |                   | Switch | Skip SCOM Version Check step.                                                             |