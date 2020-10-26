SELECT 
(SELECT is_broker_enabled
FROM sys.databases 
WHERE name='OperationsManager') AS 'Is_Broker_Enabled',
(SELECT value
FROM sys.configurations 
WHERE name = 'clr enabled') AS 'Is_CLR_Enabled',
serverproperty('machinename') AS ServerName, 
CONVERT(nvarchar(50), serverproperty('Edition')) AS Edition, 
CONVERT(nvarchar(50), serverproperty('ProductVersion'))	AS ProductVersion, 
CONVERT(nvarchar(50), serverproperty('ProductLevel')) AS ProductLevel, 
CONVERT(nvarchar(50), serverproperty('IsClustered')) AS IsClustered, 
CONVERT(nvarchar(50), serverproperty('IsFullTextInstalled')) AS IsFullTextInstalled, 
CONVERT(nvarchar(50), serverproperty('Collation')) AS Collation, 
CONVERT(nvarchar(50), serverproperty('ComputerNamePhysicalNetBIOS')) AS ComputerNamePhysicalNetBIOS, 
CONVERT(nvarchar(50), serverproperty('ComputerNamePhysicalNetBIOS')) AS 'SqlHost'