SELECT
(SELECT is_broker_enabled
FROM sys.databases
WHERE name=db_name()) AS 'Is_Broker_Enabled',
(SELECT value
FROM sys.configurations
WHERE name = 'clr enabled') AS 'Is_CLR_Enabled',
serverproperty('machinename') AS ServerName,
case when CONVERT(sysname, SERVERPROPERTY('ProductVersion')) like '8.0%' then 'SQL Server 2000'
when CONVERT(sysname, SERVERPROPERTY('ProductVersion')) like '9.0%' then 'SQL Server 2005'
when CONVERT(sysname, SERVERPROPERTY('ProductVersion')) like '10.0%' then 'SQL Server 2008'
when CONVERT(sysname, SERVERPROPERTY('ProductVersion')) like '10.5%' then 'SQL Server 2008 R2'
when CONVERT(sysname, SERVERPROPERTY('ProductVersion')) like '11.0%' then 'SQL Server 2012'
when CONVERT(sysname, SERVERPROPERTY('ProductVersion')) like '12.0%' then 'SQL Server 2014'
when CONVERT(sysname, SERVERPROPERTY('ProductVersion')) like '13.0%' then 'SQL Server 2016'
when CONVERT(sysname, SERVERPROPERTY('ProductVersion')) like '14.0%' then 'SQL Server 2017'
when CONVERT(sysname, SERVERPROPERTY('ProductVersion')) = '15.0.4123.1' then 'SQL Server 2019 CU10'
when CONVERT(sysname, SERVERPROPERTY('ProductVersion')) like '15.0%' then 'SQL Server 2019'
when CONVERT(sysname, SERVERPROPERTY('ProductVersion')) > '15.0.4123.1' then 'newer than SQL Server 2019 CU10'
else 'unknown' end as [Version],
CONVERT(nvarchar(50), serverproperty('Edition')) AS Edition,
CONVERT(nvarchar(50), serverproperty('ProductVersion')) AS ProductVersion,
CONVERT(nvarchar(50), serverproperty('ProductLevel')) AS ProductLevel,
CONVERT(nvarchar(50), serverproperty('IsClustered')) AS IsClustered,
CONVERT(nvarchar(50), serverproperty('IsFullTextInstalled')) AS IsFullTextInstalled,
CONVERT(nvarchar(50), serverproperty('Collation')) AS Collation,
CONVERT(nvarchar(50), serverproperty('ComputerNamePhysicalNetBIOS')) AS ComputerNamePhysicalNetBIOS,
CONVERT(nvarchar(50), serverproperty('ComputerNamePhysicalNetBIOS')) AS 'SqlHost'