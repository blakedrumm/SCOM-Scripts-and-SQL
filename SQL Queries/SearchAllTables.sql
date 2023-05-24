/****** Object:  StoredProcedure [dbo].[SearchAllTables]    Script Date: 04/06/2009 22:59:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC SearchAllTables '8510EC59-EB20-4310-988B-3876B4F7CD39'
--GO 

--Here is the complete stored procedure code: 


IF OBJECT_ID('[dbo].[SearchAllTables]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[SearchAllTables]
GO

-- Create a stored procedure called [dbo].[SearchAllTables]
CREATE PROCEDURE [dbo].[SearchAllTables]
(
    @SearchStr NVARCHAR(100) -- Input parameter to search for a specific string
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Create a temporary table to store the search results
    CREATE TABLE #Results (TableName NVARCHAR(256), ColumnName NVARCHAR(128), ColumnValue NVARCHAR(MAX), RowNumber INT);

    -- Declare variables to store table and column names, and construct the search string
    DECLARE @TableName NVARCHAR(256), @ColumnName NVARCHAR(128), @SearchStr2 NVARCHAR(110);
    SET @SearchStr2 = '%' + @SearchStr + '%'; -- Add wildcard characters to search string

    -- Declare a dynamic SQL variable to build the dynamic SQL statement
    DECLARE @DynamicSQL NVARCHAR(MAX) = N'';

    -- Build the dynamic SQL statement to search for the specified string in all tables and columns
    SELECT @DynamicSQL += 
        N'INSERT INTO #Results (TableName, ColumnName, ColumnValue, RowNumber) ' +
        N'SELECT ''' + QUOTENAME(t.TABLE_SCHEMA) + '.' + QUOTENAME(t.TABLE_NAME) + ''', ' +
        N'''' + QUOTENAME(c.COLUMN_NAME) + ''', ' +
        N'CAST(' + QUOTENAME(c.COLUMN_NAME) + ' AS NVARCHAR(MAX)), ' +
        N'ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) ' +
        N'FROM ' + QUOTENAME(t.TABLE_SCHEMA) + '.' + QUOTENAME(t.TABLE_NAME) + ' (NOLOCK) ' +
        N'WHERE ' + QUOTENAME(c.COLUMN_NAME) + ' LIKE @SearchStr2; '
    FROM INFORMATION_SCHEMA.TABLES t
    INNER JOIN INFORMATION_SCHEMA.COLUMNS c ON t.TABLE_NAME = c.TABLE_NAME AND t.TABLE_SCHEMA = c.TABLE_SCHEMA
    WHERE t.TABLE_TYPE = 'BASE TABLE'
        AND c.DATA_TYPE IN ('char', 'varchar', 'nchar', 'nvarchar', 'uniqueidentifier')
        AND OBJECTPROPERTY(OBJECT_ID(QUOTENAME(t.TABLE_SCHEMA) + '.' + QUOTENAME(t.TABLE_NAME)), 'IsMSShipped') = 0;

    -- Get the total number of tables
    DECLARE @TotalTables INT = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE');

    -- Initialize the counter variables
    DECLARE @Counter INT = 0, @Progress INT = 0;

    -- Execute the dynamic SQL statement using sp_executesql with the search string parameter
    EXEC sp_executesql @DynamicSQL, N'@SearchStr2 NVARCHAR(110)', @SearchStr2 = @SearchStr2;

    -- Select the search results from the temporary table
    SELECT TableName, ColumnName, ColumnValue, RowNumber FROM #Results;

    -- Drop the temporary table
    DROP TABLE #Results;
END
