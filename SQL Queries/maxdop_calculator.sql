/*
==================================================================================================
Script Title: Configuration Script for MaxDOP and Cost Threshold for Parallelism
Author: Blake Drumm
Date: 2023-10-30
Description: 
    This script is designed to review and recommend settings for MaxDOP and Cost Threshold for
    Parallelism for SQL Server in a System Center Operations Manager (SCOM) environment.
    It checks the current configuration, calculates recommended values based on the system's 
    hardware and existing settings, and generates a script for applying the recommended settings.

Usage:
    1. Customize the @RecommendedCostThreshold variable if a value within the range of 40-50 is desired.
    2. Run the script in a SQL Server Management Studio (SSMS) query window connected to the target
       SQL Server instance.
    3. Review the results and execute the generated script if the recommended settings are acceptable.

Revision History:
    2023-10-30: Script created by Blake Drumm
==================================================================================================
*/

SET NOCOUNT ON;
USE MASTER;

-- Declare variables
-- Commenting out the line that captures SQL Server version
-- DECLARE @SQLVersion INT,
DECLARE @NumaNodes INT,
        @NumCPUs INT,
        @MaxDop INT,
        @RecommendedMaxDop INT,
        @CostThreshold INT,
        @RecommendedCostThreshold VARCHAR(5) = '40-50', -- Default range, can be changed
        @ChangeScript NVARCHAR(MAX),
        @ShowAdvancedOptions INT;

-- Getting SQL Server version
-- Commenting out the line that captures SQL Server version
-- SELECT @SQLVersion = CAST(SUBSTRING(CONVERT(VARCHAR, SERVERPROPERTY('ProductVersion')), 1, 2) AS INT);

-- Getting number of NUMA nodes
SELECT @NumaNodes = COUNT(DISTINCT parent_node_id) FROM sys.dm_os_schedulers WHERE status = 'VISIBLE ONLINE';

-- Getting number of CPUs (cores)
SELECT @NumCPUs = cpu_count FROM sys.dm_os_sys_info;

-- Getting current MAXDOP at instance level
SELECT @MaxDop = CAST(value_in_use AS INT) FROM sys.configurations WHERE name = 'max degree of parallelism';

-- Getting current Cost Threshold for Parallelism
SELECT @CostThreshold = CAST(value_in_use AS INT) FROM sys.configurations WHERE name = 'cost threshold for parallelism';

-- Check 'show advanced options' setting
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
    IF (@NumCPUs / @NumaNodes) < 8
        SET @RecommendedMaxDop = (@NumCPUs / @NumaNodes);
    ELSE
        SET @RecommendedMaxDop = 8;
END

-- Initialize ChangeScript
SET @ChangeScript = '';

-- Error handling using TRY...CATCH block
BEGIN TRY
    -- Check and build ChangeScript
    IF @ShowAdvancedOptions <> 1
        SET @ChangeScript = 'EXEC sp_configure ''show advanced options'', 1; RECONFIGURE WITH OVERRIDE; ';

    IF @MaxDop <> @RecommendedMaxDop
        SET @ChangeScript = @ChangeScript + 'EXEC sp_configure ''max degree of parallelism'', ' + CAST(@RecommendedMaxDop AS VARCHAR) + '; RECONFIGURE WITH OVERRIDE; ';

    IF @CostThreshold < 40 OR @CostThreshold > 50
        SET @ChangeScript = @ChangeScript + 'EXEC sp_configure ''cost threshold for parallelism'', 45; RECONFIGURE WITH OVERRIDE; '; -- Setting to mid-range value

    -- Define a table variable to store the results
    DECLARE @Results TABLE (Description NVARCHAR(255), Value NVARCHAR(255));

    -- Insert results into the table variable
    INSERT INTO @Results (Description, Value)
    SELECT 'MAXDOP Configured Value' AS Description, CAST(@MaxDop AS VARCHAR) AS Value
    UNION ALL
    SELECT 'MAXDOP Recommended Value', CAST(@RecommendedMaxDop AS VARCHAR)
    UNION ALL
    SELECT 'Cost Threshold Configured Value', CAST(@CostThreshold AS VARCHAR)
    UNION ALL
    SELECT 'Recommended Cost Threshold', @RecommendedCostThreshold;

    -- Insert the "Change Script" row only if it's not just 'show advanced options', 1
    IF LEN(@ChangeScript) > LEN('EXEC sp_configure ''show advanced options'', 1; RECONFIGURE WITH OVERRIDE; ')
        INSERT INTO @Results (Description, Value)
        VALUES ('Change Script', @ChangeScript);

    -- Display the results
    SELECT * FROM @Results;

END TRY
BEGIN CATCH
    -- Error handling code
    PRINT 'An error occurred: ' + ERROR_MESSAGE();
END CATCH
