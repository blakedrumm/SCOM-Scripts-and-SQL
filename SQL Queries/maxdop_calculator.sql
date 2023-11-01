/*
==================================================================================================
Script Title: Configuration Script for MaxDOP and Cost Threshold for Parallelism
Author: Blake Drumm
Date: 2023-10-31
Description: 
    This script is designed to review and recommend settings for MaxDOP and Cost Threshold for
    Parallelism for SQL Server in a System Center Operations Manager (SCOM) environment.
    It checks the current configuration, calculates recommended values based on the system's 
    hardware and existing settings, and generates a script for applying the recommended settings.

Usage:
    1. Run the script in a SQL Server Management Studio (SSMS) query window connected to the target
       SQL Server instance.
    2. Review the results and execute the generated script if the recommended settings are acceptable.

Revision History:
    2023-10-31: Fixed the MaxDOP Calculation - Blake Drumm (blakedrumm@microsoft.com)
    2023-10-30: Script created by Blake Drumm (blakedrumm@microsoft.com)

Note:
    My personal blog: https://blakedrumm.com/
==================================================================================================
*/

SET NOCOUNT ON;
USE MASTER;

-- Declare variables
DECLARE @NumaNodes INT,
        @NumCPUs INT,
        @MaxDop INT,
        @RecommendedMaxDop INT,
        @CostThreshold INT,
        @ChangeScript NVARCHAR(MAX) = '',
        @ShowAdvancedOptions INT;

-- Initialize variables
SELECT @NumaNodes = COUNT(DISTINCT parent_node_id) FROM sys.dm_os_schedulers WHERE status = 'VISIBLE ONLINE';
SELECT @NumCPUs = cpu_count FROM sys.dm_os_sys_info;
SELECT @MaxDop = CAST(value_in_use AS INT) FROM sys.configurations WHERE name = 'max degree of parallelism';
SELECT @CostThreshold = CAST(value_in_use AS INT) FROM sys.configurations WHERE name = 'cost threshold for parallelism';
SELECT @ShowAdvancedOptions = CAST(value_in_use AS INT) FROM sys.configurations WHERE name = 'show advanced options';

-- MAXDOP Calculation
IF @NumaNodes = 1
BEGIN
    IF @NumCPUs < 8
        SET @RecommendedMaxDop = @NumCPUs;
    ELSE
        SET @RecommendedMaxDop = 8;
END
ELSE
BEGIN
    DECLARE @LogicalCPUsPerNumaNode INT = @NumCPUs / @NumaNodes;
    
    IF @LogicalCPUsPerNumaNode <= 16
        SET @RecommendedMaxDop = @LogicalCPUsPerNumaNode;
    ELSE
        SET @RecommendedMaxDop = 16;
END

-- Define a table variable to store the results
DECLARE @Results TABLE (Description NVARCHAR(MAX), Value NVARCHAR(MAX));

-- Insert existing settings and recommendations into @Results
INSERT INTO @Results (Description, Value)
VALUES ('MAXDOP Configured Value', CAST(@MaxDop AS VARCHAR)),
       ('MAXDOP Recommended Value', CAST(@RecommendedMaxDop AS VARCHAR)),
       ('Cost Threshold Configured Value', CAST(@CostThreshold AS VARCHAR)),
       ('Generally Recommended Cost Threshold', '40-50');

-- Check and build ChangeScript for other settings
IF @MaxDop <> @RecommendedMaxDop
    SET @ChangeScript += 'EXEC sp_configure ''max degree of parallelism'', ' + CAST(@RecommendedMaxDop AS VARCHAR) + '; RECONFIGURE WITH OVERRIDE; ';

IF @CostThreshold < 40 OR @CostThreshold > 50
    SET @ChangeScript += 'EXEC sp_configure ''cost threshold for parallelism'', 45; RECONFIGURE WITH OVERRIDE; ';

IF LEN(@ChangeScript) > 0 AND @ShowAdvancedOptions <> 1
    SET @ChangeScript = 'EXEC sp_configure ''show advanced options'', 1; RECONFIGURE WITH OVERRIDE; ' + @ChangeScript;

-- Insert the "Change Script" row only if there are changes to be made
IF LEN(@ChangeScript) > 0
    INSERT INTO @Results (Description, Value)
    VALUES ('Change Script', @ChangeScript);

-- Display the results
SELECT * FROM @Results;
