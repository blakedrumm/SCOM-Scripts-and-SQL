-- Original Author: Alex Kremenetskiy
-- Modified by: Blake Drumm (blakedrumm@microsoft.com) - https://blakedrumm.com/
-- Date Modified: April 19th, 2022

------------------------------------------------------
-- Change Variables Below
------------------------------------------------------

-- Operations Manager DB Info
DECLARE @OpsMgrSQLInstance nvarchar(50) = '<OpsDB SQL Server Instance>'
DECLARE @OpsMgrSQLDB nvarchar(50) = '<OpsDB SQL Server DB Name>'

-- Operations Manager DW DB Info
DECLARE @DWSQLInstance nvarchar(50) = '<OpsMgr DW SQL Server Instance>'
DECLARE @DWDBName nvarchar(50) = '<OpsMgr DW SQL Server DB Name>'

------------------------------------------------------
-- DO NOT EDIT BELOW THIS LINE
------------------------------------------------------

DECLARE @UseOpsMgrDB nvarchar(50) = QUOTENAME(@OpsMgrSQLDB) + N'.sys.sp_executesql'
DECLARE @UseDWDB nvarchar(50) = QUOTENAME(@DWDBName) + N'.sys.sp_executesql'
DECLARE @tblName varchar(100)
DECLARE @colName varchar(100)
DECLARE @sqlstmt nvarchar(1000)

IF (EXISTS (SELECT * 
                 FROM tempdb.INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                 AND TABLE_NAME LIKE '#tmp_DBMigration%'))
BEGIN
drop table #tmp_DBMigration
END
CREATE TABLE #tmp_DBMigration
(
	TableName varchar(100),
	OldValue varchar(50),
	NewValue varchar(50)
)

--
--Update OperationsManager
--
--USE OperationsManager

SET @tblName = 'MT_Microsoft$SystemCenter$ManagementGroup'
SET @colName = (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @tblName AND COLUMN_NAME LIKE 'SQLServerName_%')

SET @sqlstmt = N'INSERT INTO #tmp_DBMigration SELECT TOP(1) ''' + @tblName + ''' AS TableName, ' + @colName + ' AS OldValue, NULL AS NewValue FROM ' + @tblName
exec @UseOpsMgrDB @sqlstmt

SET @sqlstmt = N'UPDATE TOP(1) ' + @tblName + ' SET ' + @colName + ' = ''' + @OpsMgrSQLInstance + ''''
--select @sqlstmt
exec @UseOpsMgrDB @sqlstmt

SET @sqlstmt = N'UPDATE #tmp_DBMigration SET NewValue = (SELECT TOP(1) ' + @colName + ' FROM ' + @tblName + ') WHERE TableName = ''' + @tblName + ''''
exec @UseOpsMgrDB @sqlstmt


SET @tblName = 'MT_Microsoft$SystemCenter$OpsMgrDB$AppMonitoring'
SET @colName = (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @tblName AND COLUMN_NAME LIKE 'MainDatabaseServerName_%')

SET @sqlstmt = N'INSERT INTO #tmp_DBMigration SELECT TOP(1) ''' + @tblName + ''' AS TableName, ' + @colName + ' AS OldValue, NULL AS NewValue FROM ' + @tblName
exec @UseOpsMgrDB @sqlstmt

SET @sqlstmt = N'UPDATE TOP(1) ' + @tblName + ' SET ' + @colName + ' = ''' + @OpsMgrSQLInstance + ''''
--select @sqlstmt
exec @UseOpsMgrDB @sqlstmt

SET @sqlstmt = N'UPDATE #tmp_DBMigration SET NewValue = (SELECT TOP(1) ' + @colName + ' FROM ' + @tblName + ') WHERE TableName = ''' + @tblName + ''''
exec @UseOpsMgrDB @sqlstmt

--
--End update OperationsManager
--

--
--Update DW
--
--USE OperationsManager

SET @tblName = 'MT_Microsoft$SystemCenter$DataWarehouse'
SET @colName = (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @tblName AND COLUMN_NAME LIKE 'MainDatabaseServerName_%')

SET @sqlstmt = N'INSERT INTO #tmp_DBMigration SELECT TOP(1) ''' + @tblName + ''' AS TableName, ' + @colName + ' AS OldValue, NULL AS NewValue FROM ' + @tblName
exec @UseOpsMgrDB @sqlstmt

SET @sqlstmt = N'UPDATE TOP(1) ' + @tblName + ' SET ' + @colName + ' = ''' + @DWSQLInstance + ''''
--select @sqlstmt
exec @UseOpsMgrDB @sqlstmt

SET @sqlstmt = N'UPDATE #tmp_DBMigration SET NewValue = (SELECT TOP(1) ' + @colName + ' FROM ' + @tblName + ') WHERE TableName = ''' + @tblName + ''''
exec @UseOpsMgrDB @sqlstmt


SET @tblName = 'MT_Microsoft$SystemCenter$DataWarehouse$AppMonitoring'
SET @colName = (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @tblName AND COLUMN_NAME LIKE 'MainDatabaseServerName_%')

SET @sqlstmt = N'INSERT INTO #tmp_DBMigration SELECT TOP(1) ''' + @tblName + ''' AS TableName, ' + @colName + ' AS OldValue, NULL AS NewValue FROM ' + @tblName
exec @UseOpsMgrDB @sqlstmt

SET @sqlstmt = N'UPDATE TOP(1) ' + @tblName + ' SET ' + @colName + ' = ''' + @DWSQLInstance + ''''
--select @sqlstmt
exec @UseOpsMgrDB @sqlstmt

SET @sqlstmt = N'UPDATE #tmp_DBMigration SET NewValue = (SELECT TOP(1) ' + @colName + ' FROM ' + @tblName + ') WHERE TableName = ''' + @tblName + ''''
exec @UseOpsMgrDB @sqlstmt


SET @tblName = 'MT_Microsoft$SystemCenter$DataWarehouse$AppMonitoring_Log'
SET @colName = (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @tblName AND COLUMN_NAME LIKE 'Post_MainDatabaseServerName_%')

SET @sqlstmt = N'INSERT INTO #tmp_DBMigration SELECT TOP(1) ''' + @tblName + ''' AS TableName, ' + @colName + ' AS OldValue, NULL AS NewValue FROM ' + @tblName
exec @UseOpsMgrDB @sqlstmt

SET @sqlstmt = N'UPDATE TOP(1) ' + @tblName + ' SET ' + @colName + ' = ''' + @DWSQLInstance + ''''
--select @sqlstmt
exec @UseOpsMgrDB @sqlstmt

SET @sqlstmt = N'UPDATE TOP(1) #tmp_DBMigration SET NewValue = (SELECT ' + @colName + ' FROM ' + @tblName + ') WHERE TableName = ''' + @tblName + ''''
exec @UseOpsMgrDB @sqlstmt


SET @tblName = 'MT_Microsoft$SystemCenter$DataWarehouse_Log'
SET @colName = (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @tblName AND COLUMN_NAME LIKE 'Post_MainDatabaseServerName_%')

SET @sqlstmt = N'INSERT INTO #tmp_DBMigration SELECT TOP(1) ''' + @tblName + ''' AS TableName, ' + @colName + ' AS OldValue, NULL AS NewValue FROM ' + @tblName
exec @UseOpsMgrDB @sqlstmt

SET @sqlstmt = N'UPDATE TOP(1) ' + @tblName + ' SET ' + @colName + ' = ''' + @DWSQLInstance + ''''
--select @sqlstmt
exec @UseOpsMgrDB @sqlstmt

SET @sqlstmt = N'UPDATE #tmp_DBMigration SET NewValue = (SELECT TOP(1) ' + @colName + ' FROM ' + @tblName + ') WHERE TableName = ''' + @tblName + ''''
exec @UseOpsMgrDB @sqlstmt


SET @tblName = 'MT_Microsoft$SystemCenter$OpsMgrDWWatcher'
SET @colName = (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @tblName AND COLUMN_NAME LIKE 'DatabaseServerName_%')

SET @sqlstmt = N'INSERT INTO #tmp_DBMigration SELECT TOP(1) ''' + @tblName + ''' AS TableName, ' + @colName + ' AS OldValue, NULL AS NewValue FROM ' + @tblName
exec @UseOpsMgrDB @sqlstmt

SET @sqlstmt = N'UPDATE TOP(1) ' + @tblName + ' SET ' + @colName + ' = ''' + @DWSQLInstance + ''''
--select @sqlstmt
exec @UseOpsMgrDB @sqlstmt

SET @sqlstmt = N'UPDATE #tmp_DBMigration SET NewValue = (SELECT TOP(1) ' + @colName + ' FROM ' + @tblName + ') WHERE TableName = ''' + @tblName + ''''
exec @UseOpsMgrDB @sqlstmt

SET @tblName = 'MT_Microsoft$SystemCenter$OpsMgrDWWatcher_Log'
SET @colName = (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @tblName AND COLUMN_NAME LIKE 'Post_DatabaseServerName_%')

SET @sqlstmt = N'INSERT INTO #tmp_DBMigration SELECT TOP(1) ''' + @tblName + ''' AS TableName, ' + @colName + ' AS OldValue, NULL AS NewValue FROM ' + @tblName
exec @UseOpsMgrDB @sqlstmt

SET @sqlstmt = N'UPDATE TOP(1) ' + @tblName + ' SET ' + @colName + ' = ''' + @DWSQLInstance + ''''
--select @sqlstmt
exec @UseOpsMgrDB @sqlstmt

SET @sqlstmt = N'UPDATE #tmp_DBMigration SET NewValue = (SELECT TOP(1) ' + @colName + ' FROM ' + @tblName + ') WHERE TableName = ''' + @tblName + ''''
exec @UseOpsMgrDB @sqlstmt


--USE OperationsManagerDW

SET @sqlstmt = N'INSERT INTO #tmp_DBMigration SELECT TOP(1) ''MemberDatabase'' AS TableName, ServerName AS OldValue, NULL AS NewValue FROM MemberDatabase;
UPDATE TOP(1) dbo.MemberDatabase SET ServerName = ''' + @DWSQLInstance + '''; UPDATE #tmp_DBMigration SET NewValue = (SELECT TOP(1) ServerName FROM MemberDatabase) WHERE TableName = ''MemberDatabase'''

exec @UseDWDB @sqlstmt

--USE OperationsManager

SET @sqlstmt = N'INSERT INTO #tmp_DBMigration SELECT TOP(1) ''GlobalSettings'' AS TableName, SettingValue AS OldValue, NULL AS NewValue FROM GlobalSettings WHERE ManagedTypePropertyId IN (select ManagedTypePropertyId from [dbo].[ManagedTypeProperty] where [ManagedTypePropertyName] like ''MainDatabaseServerName'')
UPDATE TOP(1) GlobalSettings SET SettingValue = ''' + @OpsMgrSQLInstance + ''' WHERE ManagedTypePropertyId IN (select ManagedTypePropertyId from [dbo].[ManagedTypeProperty] where [ManagedTypePropertyName] like ''MainDatabaseServerName'')
UPDATE #tmp_DBMigration SET NewValue = (SELECT TOP(1) SettingValue FROM GlobalSettings WHERE ManagedTypePropertyId IN (select ManagedTypePropertyId from [dbo].[ManagedTypeProperty] where [ManagedTypePropertyName] like ''MainDatabaseServerName'')) WHERE TableName = ''GlobalSettings'''

exec @UseOpsMgrDB @sqlstmt
INSERT INTO #tmp_DBMigration (NewValue) Values ('Completed: ' + convert(varchar, getdate(), 100))
--
--End Update DW
--

select * from #tmp_DBMigration
drop table #tmp_DBMigration
