-- Author: Alex Kremenetskiy
-- Author: Blake Drumm

------------------------------------------------------
-- Change Variables Below
------------------------------------------------------

DECLARE @OpsMgrSQLInstance nvarchar(50) = '<OpsMgr DB Instance>'
DECLARE @DWSQLInstance nvarchar(50) = '<DW DB Instance>'
DECLARE @OpsMgrSQLDB nvarchar(50) = '<OpsMgr DB Name>'
DECLARE @DWDBName nvarchar(50) = '<OpsMgr DW DB Name>'

------------------------------------------------------

DECLARE @tblName varchar(100)
DECLARE @colName varchar(100)
DECLARE @sqlstmt nvarchar(1000)

CREATE TABLE #tmp
(
	TableName varchar(100),
	OldValue varchar(50),
	NewValue varchar(50)
)

--
--Update OperationsManager
--
USE @OpsMgrSQLDB

SET @tblName = 'MT_Microsoft$SystemCenter$ManagementGroup'
SET @colName = (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @tblName AND COLUMN_NAME LIKE 'SQLServerName_%')

SET @sqlstmt = N'INSERT INTO #tmp SELECT TOP(1) ''' + @tblName + ''' AS TableName, ' + @colName + ' AS OldValue, NULL AS NewValue FROM ' + @tblName
exec (@sqlstmt)

SET @sqlstmt = N'UPDATE TOP(1) ' + @tblName + ' SET ' + @colName + ' = ''' + @OpsMgrSQLInstance + ''''
--select @sqlstmt
exec (@sqlstmt)

SET @sqlstmt = N'UPDATE #tmp SET NewValue = (SELECT TOP(1) ' + @colName + ' FROM ' + @tblName + ') WHERE TableName = ''' + @tblName + ''''
exec (@sqlstmt)


SET @tblName = 'MT_Microsoft$SystemCenter$OpsMgrDB$AppMonitoring'
SET @colName = (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @tblName AND COLUMN_NAME LIKE 'MainDatabaseServerName_%')

SET @sqlstmt = N'INSERT INTO #tmp SELECT TOP(1) ''' + @tblName + ''' AS TableName, ' + @colName + ' AS OldValue, NULL AS NewValue FROM ' + @tblName
exec (@sqlstmt)

SET @sqlstmt = N'UPDATE TOP(1) ' + @tblName + ' SET ' + @colName + ' = ''' + @OpsMgrSQLInstance + ''''
--select @sqlstmt
exec (@sqlstmt)

SET @sqlstmt = N'UPDATE #tmp SET NewValue = (SELECT TOP(1) ' + @colName + ' FROM ' + @tblName + ') WHERE TableName = ''' + @tblName + ''''
exec (@sqlstmt)

--
--End update OperationsManager
--

--
--Update DW
--
USE @OpsMgrSQLDB

SET @tblName = 'MT_Microsoft$SystemCenter$DataWarehouse'
SET @colName = (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @tblName AND COLUMN_NAME LIKE 'MainDatabaseServerName_%')

SET @sqlstmt = N'INSERT INTO #tmp SELECT TOP(1) ''' + @tblName + ''' AS TableName, ' + @colName + ' AS OldValue, NULL AS NewValue FROM ' + @tblName
exec (@sqlstmt)

SET @sqlstmt = N'UPDATE TOP(1) ' + @tblName + ' SET ' + @colName + ' = ''' + @DWSQLInstance + ''''
--select @sqlstmt
exec (@sqlstmt)

SET @sqlstmt = N'UPDATE #tmp SET NewValue = (SELECT TOP(1) ' + @colName + ' FROM ' + @tblName + ') WHERE TableName = ''' + @tblName + ''''
exec (@sqlstmt)


SET @tblName = 'MT_Microsoft$SystemCenter$DataWarehouse$AppMonitoring'
SET @colName = (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @tblName AND COLUMN_NAME LIKE 'MainDatabaseServerName_%')

SET @sqlstmt = N'INSERT INTO #tmp SELECT TOP(1) ''' + @tblName + ''' AS TableName, ' + @colName + ' AS OldValue, NULL AS NewValue FROM ' + @tblName
exec (@sqlstmt)

SET @sqlstmt = N'UPDATE TOP(1) ' + @tblName + ' SET ' + @colName + ' = ''' + @DWSQLInstance + ''''
--select @sqlstmt
exec (@sqlstmt)

SET @sqlstmt = N'UPDATE #tmp SET NewValue = (SELECT TOP(1) ' + @colName + ' FROM ' + @tblName + ') WHERE TableName = ''' + @tblName + ''''
exec (@sqlstmt)


SET @tblName = 'MT_Microsoft$SystemCenter$DataWarehouse$AppMonitoring_Log'
SET @colName = (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @tblName AND COLUMN_NAME LIKE 'Post_MainDatabaseServerName_%')

SET @sqlstmt = N'INSERT INTO #tmp SELECT TOP(1) ''' + @tblName + ''' AS TableName, ' + @colName + ' AS OldValue, NULL AS NewValue FROM ' + @tblName
exec (@sqlstmt)

SET @sqlstmt = N'UPDATE TOP(1) ' + @tblName + ' SET ' + @colName + ' = ''' + @DWSQLInstance + ''''
--select @sqlstmt
exec (@sqlstmt)

SET @sqlstmt = N'UPDATE TOP(1) #tmp SET NewValue = (SELECT ' + @colName + ' FROM ' + @tblName + ') WHERE TableName = ''' + @tblName + ''''
exec (@sqlstmt)


SET @tblName = 'MT_Microsoft$SystemCenter$DataWarehouse_Log'
SET @colName = (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @tblName AND COLUMN_NAME LIKE 'Post_MainDatabaseServerName_%')

SET @sqlstmt = N'INSERT INTO #tmp SELECT TOP(1) ''' + @tblName + ''' AS TableName, ' + @colName + ' AS OldValue, NULL AS NewValue FROM ' + @tblName
exec (@sqlstmt)

SET @sqlstmt = N'UPDATE TOP(1) ' + @tblName + ' SET ' + @colName + ' = ''' + @DWSQLInstance + ''''
--select @sqlstmt
exec (@sqlstmt)

SET @sqlstmt = N'UPDATE #tmp SET NewValue = (SELECT TOP(1) ' + @colName + ' FROM ' + @tblName + ') WHERE TableName = ''' + @tblName + ''''
exec (@sqlstmt)


SET @tblName = 'MT_Microsoft$SystemCenter$OpsMgrDWWatcher'
SET @colName = (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @tblName AND COLUMN_NAME LIKE 'DatabaseServerName_%')

SET @sqlstmt = N'INSERT INTO #tmp SELECT TOP(1) ''' + @tblName + ''' AS TableName, ' + @colName + ' AS OldValue, NULL AS NewValue FROM ' + @tblName
exec (@sqlstmt)

SET @sqlstmt = N'UPDATE TOP(1) ' + @tblName + ' SET ' + @colName + ' = ''' + @DWSQLInstance + ''''
--select @sqlstmt
exec (@sqlstmt)

SET @sqlstmt = N'UPDATE #tmp SET NewValue = (SELECT TOP(1) ' + @colName + ' FROM ' + @tblName + ') WHERE TableName = ''' + @tblName + ''''
exec (@sqlstmt)

SET @tblName = 'MT_Microsoft$SystemCenter$OpsMgrDWWatcher_Log'
SET @colName = (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @tblName AND COLUMN_NAME LIKE 'Post_DatabaseServerName_%')

SET @sqlstmt = N'INSERT INTO #tmp SELECT TOP(1) ''' + @tblName + ''' AS TableName, ' + @colName + ' AS OldValue, NULL AS NewValue FROM ' + @tblName
exec (@sqlstmt)

SET @sqlstmt = N'UPDATE TOP(1) ' + @tblName + ' SET ' + @colName + ' = ''' + @DWSQLInstance + ''''
--select @sqlstmt
exec (@sqlstmt)

SET @sqlstmt = N'UPDATE #tmp SET NewValue = (SELECT TOP(1) ' + @colName + ' FROM ' + @tblName + ') WHERE TableName = ''' + @tblName + ''''
exec (@sqlstmt)


USE @DWDBName

INSERT INTO #tmp SELECT TOP(1) 'MemberDatabase' AS TableName, ServerName AS OldValue, NULL AS NewValue FROM MemberDatabase
UPDATE TOP(1) dbo.MemberDatabase SET ServerName = @DWSQLInstance
UPDATE #tmp SET NewValue = (SELECT TOP(1) ServerName FROM MemberDatabase) WHERE TableName = 'MemberDatabase'

USE @OpsMgrSQLDB

INSERT INTO #tmp SELECT TOP(1) 'GlobalSettings' AS TableName, SettingValue AS OldValue, NULL AS NewValue FROM GlobalSettings WHERE ManagedTypePropertyId IN (select ManagedTypePropertyId from [dbo].[ManagedTypeProperty] where [ManagedTypePropertyName] like 'MainDatabaseServerName')
UPDATE TOP(1) GlobalSettings SET SettingValue = @OpsMgrSQLInstance WHERE ManagedTypePropertyId IN (select ManagedTypePropertyId from [dbo].[ManagedTypeProperty] where [ManagedTypePropertyName] like 'MainDatabaseServerName')
UPDATE #tmp SET NewValue = (SELECT TOP(1) SettingValue FROM GlobalSettings WHERE ManagedTypePropertyId IN (select ManagedTypePropertyId from [dbo].[ManagedTypeProperty] where [ManagedTypePropertyName] like 'MainDatabaseServerName')) WHERE TableName = 'GlobalSettings'

--
--End Update DW
--

select * from #tmp
drop table #tmp
