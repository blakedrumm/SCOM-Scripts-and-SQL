SELECT CASE
                  (SELECT is_broker_enabled
                   FROM sys.databases
                   WHERE name=db_name())
           WHEN 0 THEN 'False'
           WHEN 1 THEN 'True'
       END AS [Is_Broker_Enabled],
       CASE
                  (SELECT SERVERPROPERTY ('IsHadrEnabled'))
           WHEN 0 THEN 'False'
           WHEN 1 THEN 'True'
       END AS [Is_AlwaysOn_Enabled],
       CASE
                  (SELECT value
                   FROM sys.configurations
                   WHERE name = 'clr enabled')
           WHEN 0 THEN 'False'
           WHEN 1 THEN 'True'
       END AS [Is_CLR_Enabled],
       serverproperty('machinename') AS ServerName,
       CASE
           WHEN CONVERT(sysname, SERVERPROPERTY('ProductVersion')) like '8.0%' THEN 'SQL Server 2000'
           WHEN CONVERT(sysname, SERVERPROPERTY('ProductVersion')) like '9.0%' THEN 'SQL Server 2005'
           WHEN CONVERT(sysname, SERVERPROPERTY('ProductVersion')) like '10.0%' THEN 'SQL Server 2008'
           WHEN CONVERT(sysname, SERVERPROPERTY('ProductVersion')) like '10.5%' THEN 'SQL Server 2008 R2'
           WHEN CONVERT(sysname, SERVERPROPERTY('ProductVersion')) like '11.0%' THEN 'SQL Server 2012'
           WHEN CONVERT(sysname, SERVERPROPERTY('ProductVersion')) like '12.0%' THEN 'SQL Server 2014'
           WHEN CONVERT(sysname, SERVERPROPERTY('ProductVersion')) like '13.0%' THEN 'SQL Server 2016'
           WHEN CONVERT(sysname, SERVERPROPERTY('ProductVersion')) like '14.0%' THEN 'SQL Server 2017'
           WHEN CONVERT(sysname, SERVERPROPERTY('ProductVersion')) = '15.0.4123.1' THEN 'SQL Server 2019 CU10'
           WHEN CONVERT(sysname, SERVERPROPERTY('ProductVersion')) = '15.0.4138.2' THEN 'SQL Server 2019 CU11'
           WHEN CONVERT(sysname, SERVERPROPERTY('ProductVersion')) = '15.0.4153.1' THEN 'SQL Server 2019 CU12'
           WHEN CONVERT(sysname, SERVERPROPERTY('ProductVersion')) = '15.0.4178.1' THEN 'SQL Server 2019 CU13'
           WHEN CONVERT(sysname, SERVERPROPERTY('ProductVersion')) = '15.0.4188.2' THEN 'SQL Server 2019 CU14'
           WHEN CONVERT(sysname, SERVERPROPERTY('ProductVersion')) > '15.0.4188.2' THEN 'newer than SQL Server 2019 CU14'
           WHEN CONVERT(sysname, SERVERPROPERTY('ProductVersion')) like '15.0%' THEN 'SQL Server 2019'
           ELSE 'unknown'
       END AS [Version],
       CONVERT(nvarchar(50), serverproperty('Edition')) AS Edition,
       CONVERT(nvarchar(50), serverproperty('ProductVersion')) AS ProductVersion,
       CONVERT(nvarchar(50), serverproperty('ProductLevel')) AS ProductLevel,
       CASE (CONVERT(nvarchar(50), serverproperty('IsClustered')))
           WHEN 0 THEN 'False'
           WHEN 1 THEN 'True'
       END AS [IsClustered],
       CASE (CONVERT(nvarchar(50), serverproperty('IsFullTextInstalled')))
           WHEN 0 THEN 'False'
           WHEN 1 THEN 'True'
       END AS [IsFullTextInstalled],
       CONVERT(nvarchar(50), serverproperty('Collation')) AS COLLATION,
       CONVERT(nvarchar(50), serverproperty('ComputerNamePhysicalNetBIOS')) AS ComputerNamePhysicalNetBIOS,
       CONVERT(nvarchar(50), serverproperty('ComputerNamePhysicalNetBIOS')) AS 'SqlHost'
