/*
-- +----------------------------------------------------------------------------+
-- |                  			DBA Mastery		                                |
-- |                        dbamastery@outlook.com                              |
-- |                      http://www.dbamastery.com                             |
-- |----------------------------------------------------------------------------|
-- |                                                                            |
-- |----------------------------------------------------------------------------|
-- | DATABASE : SQL Server                                                      |
-- | FILE     : maxdop_calculator.sql                                        	|
-- | CLASS    : Performance tuning                                              |
-- | PURPOSE  :	Calculates the optimal value for MAXDOP (> SQL 2016 )		    |
-- |																			|
-- | NOTE     : As with any code, ensure to test this script in a development   |
-- |            environment before attempting to run it in production.          |
-- |                                                                            |
-- |            Based on Microsoft KB# 2806535: https://goo.gl/4FD9BH and       |
-- |            MSDN MaxDOP calculator: https://goo.gl/hzyxY1                   |
-- +----------------------------------------------------------------------------+
Copyright (c) 2019 DBA Mastery

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

SET NOEXEC OFF;
:SETVAR IsSqlCmdEnabled "True"
:OUT STDOUT
GO

IF ('$(IsSqlCmdEnabled)' = '$' + '(IsSqlCmdEnabled)')
	BEGIN
		-- Disabling script execution in case SQLCMD mode is not enabled in SSMS
        PRINT N'SQLCMD mode must be enabled to successfully execute this script.';
		PRINT N'For instructions on how to use SQLCMD mode in SSMS, please visit this post from my blog:';
		PRINT N'http://www.dbamastery.com/tips/SQLCMD-mode-SSMS'
	    SET NOEXEC ON;
	END;
ELSE
	BEGIN
		SET NOCOUNT ON;
		USE MASTER;

		-- Dropping tem table in case it exists
		IF EXISTS (SELECT  * FROM tempdb.dbo.sysobjects o WHERE o.XTYPE IN ('U') and o.id = object_id(N'tempdb..#MaxDOPDB') ) DROP TABLE #MaxDOPDB;

		DECLARE
			@SQLVersion			INT
			,@NumaNodes 		INT
			,@NumCPUs			INT
			,@MaxDop			SQL_VARIANT
			,@RecommendedMaxDop	INT

		-- Getting SQL Server version
		SELECT @SQLVersion = SUBSTRING(CONVERT(VARCHAR,SERVERPROPERTY('ProductVersion')),1,2);

		-- Getting number of NUMA nodes
		SELECT @NumaNodes = COUNT(DISTINCT memory_node_id) FROM sys.dm_os_memory_clerks WHERE memory_node_id!=64

		-- Getting number of CPUs (cores)
		SELECT @NumCPUs = COUNT(scheduler_id) FROM sys.dm_os_schedulers WHERE status = 'VISIBLE ONLINE'

		-- Getting current MAXDOP at instance level
		SELECT @MaxDop = value_in_use from sys.configurations where name ='max degree of parallelism'

		-- MAXDOP calculation (Instance level)
		-- If SQL Server has single NUMA node

		IF @NumaNodes = 1
			IF @NumCPUs < 8 
				-- If number of logical processors is less than 8, MAXDOP equals number of logical processors
				SET @RecommendedMaxDop = @NumCPUs; 
			ELSE
				-- Keep MAXDOP at 8
				SET @RecommendedMaxDop = 8;
		ELSE

		-- If SQL Server has multiple NUMA nodes
			IF (@NumCPUs / @NumaNodes) < 8
				-- IF number of logical processors per NUMA node is less than 8, MAXDOP equals or below logical processors per NUMA node
				SET @RecommendedMaxDop = (@NumCPUs / @NumaNodes);
			ELSE
				--If greater than 8 logical processors per NUMA node - Keep MAXDOP at 8
				SET @RecommendedMaxDop = 8;

		-- If SQL Server is > 2016
		IF CONVERT(INT,@SQLVersion) > 12
			BEGIN
				-- Getting current MAXDOP at database level

				-- Creating temp table
				CREATE TABLE #MaxDOPDB
				(DBName	sysname, configuration_id int, name nvarchar (120), value_for_primary sql_variant, value_for_secondary sql_variant)

				INSERT INTO #MaxDOPDB
				EXEC sp_msforeachdb 'USE [?]; SELECT DB_NAME(), configuration_id, name, value, value_for_secondary FROM sys.database_scoped_configurations WHERE name =''MAXDOP'''
		
				-- Displaying database MAXDOP configuration
				PRINT '------------------------------------------------------------------------';
				PRINT 'MAXDOP at Database level:';
				PRINT '------------------------------------------------------------------------';
				SELECT CONVERT(VARCHAR(30),dbname) as DatabaseName, CONVERT(VARCHAR(10),name) as ConfigurationName, CONVERT(INT,value_for_primary) as "MAXDOP Configured Value" FROM #MaxDOPDB
				WHERE dbname NOT IN ('master','msdb','tempdb','model');
				PRINT '';

				-- Displaying current and recommeded MAXDOP
				PRINT '--------------------------------------------------------------';
				PRINT 'MAXDOP at Instance level:';
				PRINT '--------------------------------------------------------------';
				PRINT 'MAXDOP configured value: ' + CHAR(9) + CAST(@MaxDop AS CHAR);
				PRINT 'MAXDOP recommended value: ' + CHAR(9) + CAST(@RecommendedMaxDop AS CHAR);
				PRINT '--------------------------------------------------------------';
				PRINT '';

				IF (@MaxDop <> @RecommendedMaxDop)
					BEGIN
						PRINT 'In case you want to change MAXDOP to the recommeded value, please use this script:';
						PRINT '';
						PRINT 'EXEC sp_configure ''max degree of parallelism'',' + CAST(@RecommendedMaxDop AS CHAR);
						PRINT 'GO';
						PRINT 'RECONFIGURE WITH OVERRIDE;';
					END
			END;
		ELSE
			BEGIN
				-- Displaying current and recommeded MAXDOP
				PRINT '--------------------------------------------------------------';
				PRINT 'MAXDOP at Instance level:';
				PRINT '--------------------------------------------------------------';
				PRINT 'MAXDOP configured value: ' + CHAR(9) + CAST(@MaxDop AS CHAR);
				PRINT 'MAXDOP recommended value: ' + CHAR(9) + CAST(@RecommendedMaxDop AS CHAR);
				PRINT '--------------------------------------------------------------';
				PRINT '';

				IF (@MaxDop <> @RecommendedMaxDop)
					BEGIN
						PRINT 'In case you want to change MAXDOP to the recommeded value, please use this script:';
						PRINT '';
						PRINT 'EXEC sp_configure ''max degree of parallelism'',' + CAST(@RecommendedMaxDop AS CHAR);
						PRINT 'GO';
						PRINT 'RECONFIGURE WITH OVERRIDE;';
					END
			END;
	END;
SET NOEXEC OFF;
