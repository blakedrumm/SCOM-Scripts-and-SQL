  DECLARE
     @DatasetId uniqueidentifier
    ,@AggregationTypeId int
    ,@ServerName sysname
    ,@DatabaseName sysname
    ,@SchemaName sysname
    ,@DatasetName nvarchar(256)
    ,@DatasetDescription nvarchar(max)
    ,@AggregationTypeName nvarchar(50)
    ,@MaxDataAgeDays int
    ,@DataFileGroupName sysname
    ,@IndexFileGroupName sysname
    ,@StandardDatasetTableMapRowId int
    ,@TableGuid uniqueidentifier
    ,@TableNameSuffix varchar(100)
    ,@StartDateTime datetime
    ,@EndDateTime datetime
    ,@StandardDatasetAggregationStorageRowId int
    ,@DependentTableInd tinyint
    ,@BaseTableName nvarchar(90)
    ,@TableName nvarchar(max)
    ,@RowCount bigint
    ,@SizeKb bigint
    ,@RowCountForDailyAvg bigint
    ,@SizeKbForDailyAvg bigint
    ,@MinStartDateTime datetime
    ,@MaxEndDateTime datetime
    ,@TotalHours bigint
    ,@TableCreatedDateTime datetime
    ,@DomainTableRowId int
     
  DECLARE @TableSize TABLE (
       TableName      sysname         NOT NULL
      ,[RowCount]     bigint          NOT NULL
      ,Reserved       varchar(30)     NOT NULL 
      ,Data           varchar(30)     NOT NULL
      ,IndexSize      varchar(30)     NOT NULL 
      ,Unused         varchar(30)     NOT NULL
  )

  DECLARE @Result TABLE (
       DatasetId            uniqueidentifier NOT NULL
      ,ServerName           sysname       NOT NULL
      ,DatabaseName         sysname       NOT NULL
      ,DatasetName          nvarchar(256) NOT NULL
      ,AggregationTypeId    int           NOT NULL
      ,AggregationTypeName  nvarchar(50)  NOT NULL
      ,MaxDataAgeDays       int           NOT NULL
      ,[RowCount]           bigint        NULL
      ,MinStartDateTime     datetime      NULL
      ,SizeKb               bigint        NOT NULL
      ,DailySizeKb          float         NULL
      ,DailyRowCount        bigint        NULL
      ,TotalSizeKb          float         NULL
      ,TotalRowCount        bigint        NULL
      ,DataFileGroupName    sysname       NOT NULL
      ,IndexFileGroupName   sysname       NOT NULL
  )

  SET @DatasetId = '00000000-0000-0000-0000-000000000000'
  
  WHILE EXISTS (SELECT *
                FROM vDataset d
                      JOIN StandardDataset sd ON (d.DatasetId = sd.DatasetId)
                      JOIN vMemberDatabase mdb ON (d.MemberDatabaseRowId = mdb.MemberDatabaseRowId)
                WHERE (d.DatasetId > @DatasetId)
                  AND (d.InstallCompletedInd = 1)
               )
  BEGIN
    SELECT TOP 1
       @DatasetId = d.DatasetId
      ,@SchemaName = sd.SchemaName
      ,@DatasetName = d.DatasetDefaultName
      ,@DatasetDescription = d.DatasetDefaultDescription
      ,@ServerName = mdb.ServerName
      ,@DatabaseName = mdb.DatabaseName
    FROM vDataset d
            JOIN StandardDataset sd ON (d.DatasetId = sd.DatasetId)
            JOIN vMemberDatabase mdb ON (d.MemberDatabaseRowId = mdb.MemberDatabaseRowId)
    WHERE (d.DatasetId > @DatasetId)
      AND (d.InstallCompletedInd = 1)
    ORDER BY d.DatasetId

    SET @AggregationTypeId = -1
    
    WHILE EXISTS (SELECT *
                  FROM StandardDatasetAggregation
                  WHERE (DatasetId = @DatasetId)
                    AND (AggregationTypeId > @AggregationTypeId)
                 )
    BEGIN
      SELECT TOP 1
         @AggregationTypeId = a.AggregationTypeId
        ,@AggregationTypeName = at.AggregationTypeDefaultName
        ,@MaxDataAgeDays = a.MaxDataAgeDays
        ,@DataFileGroupName = a.DataFileGroupName
        ,@IndexFileGroupName = a.IndexFileGroupName
      FROM StandardDatasetAggregation a
              JOIN vAggregationType at ON (a.AggregationTypeId = at.AggregationTypeId)
      WHERE (a.DatasetId = @DatasetId)
        AND (a.AggregationTypeId > @AggregationTypeId)
      ORDER BY a.AggregationTypeId
      
      SET @RowCount = 0
      SET @SizeKb = 0
      SET @TotalHours = 0
      SET @MinStartDateTime = NULL
      SET @RowCountForDailyAvg = 0
      SET @SizeKbForDailyAvg = 0
      
      SET @StandardDatasetTableMapRowId = 0
      
      WHILE EXISTS (SELECT *
                    FROM StandardDatasetTableMap
                    WHERE (DatasetId = @DatasetId)
                      AND (AggregationTypeId = @AggregationTypeId)
                      AND (StandardDatasetTableMapRowId > @StandardDatasetTableMapRowId)
                   )
      BEGIN
        SELECT TOP 1
           @StandardDatasetTableMapRowId = StandardDatasetTableMapRowId
          ,@TableGuid = TableGuid
          ,@TableNameSuffix = TableNameSuffix
          ,@StartDateTime = StartDateTime
          ,@EndDateTime = EndDateTime
        FROM StandardDatasetTableMap
        WHERE (DatasetId = @DatasetId)
          AND (AggregationTypeId = @AggregationTypeId)
          AND (StandardDatasetTableMapRowId > @StandardDatasetTableMapRowId)
        ORDER BY StandardDatasetTableMapRowId
        
        SET @StandardDatasetAggregationStorageRowId = 0
        
        WHILE EXISTS (SELECT *
                      FROM StandardDatasetAggregationStorage
                      WHERE (DatasetId = @DatasetId)
                        AND (AggregationTypeId = @AggregationTypeId)
                        AND (StandardDatasetAggregationStorageRowId > @StandardDatasetAggregationStorageRowId)
                     )
        BEGIN
          SELECT TOP 1
             @StandardDatasetAggregationStorageRowId = StandardDatasetAggregationStorageRowId
            ,@DependentTableInd = DependentTableInd
            ,@BaseTableName = BaseTableName
          FROM StandardDatasetAggregationStorage
          WHERE (DatasetId = @DatasetId)
            AND (AggregationTypeId = @AggregationTypeId)
            AND (StandardDatasetAggregationStorageRowId > @StandardDatasetAggregationStorageRowId)
          ORDER BY StandardDatasetAggregationStorageRowId
          
          SELECT @TableCreatedDateTime = create_date
          FROM sys.objects o
                JOIN sys.schemas s ON (o.schema_id = s.schema_id)
          WHERE (s.name = @SchemaName)
            AND (o.name = @BaseTableName + '_' + @TableNameSuffix)
          
          IF (@StartDateTime < @TableCreatedDateTime)
            SET @StartDateTime = @TableCreatedDateTime
            
          IF (@EndDateTime > GETUTCDATE())
            SET @EndDateTime = GETUTCDATE()
          
          SET @TableName = QUOTENAME(@SchemaName) + '.' + QUOTENAME(@BaseTableName + '_' + @TableNameSuffix)
          
          DELETE @TableSize
          
          INSERT @TableSize (TableName, [RowCount], Reserved, Data, IndexSize, Unused)
          EXEC sp_spaceused @TableName
          
          SELECT 
             @RowCount = @RowCount + CASE WHEN @DependentTableInd = 0 THEN [RowCount] ELSE 0 END
            ,@SizeKb = @SizeKb + CAST(REPLACE(REPLACE(Reserved, 'KB', ''), ' ', '') as bigint)
          FROM @TableSize
          
          IF (@StartDateTime IS NOT NULL) AND (@EndDateTime IS NOT NULL)
          BEGIN
            SET @TotalHours = @TotalHours + ABS(DATEDIFF(hour, @StartDateTime, @EndDateTime))
            
            SELECT 
               @RowCountForDailyAvg = @RowCountForDailyAvg + CASE WHEN @DependentTableInd = 0 THEN [RowCount] ELSE 0 END
              ,@SizeKbForDailyAvg = @SizeKbForDailyAvg + CAST(REPLACE(REPLACE(Reserved, 'KB', ''), ' ', '') as bigint)
            FROM @TableSize
            
            SET @MinStartDateTime = 
                  CASE
                    WHEN @MinStartDateTime IS NULL THEN @StartDateTime
                    WHEN @StartDateTime < @MinStartDateTime THEN @StartDateTime
                    ELSE @MinStartDateTime
                  END

            SET @MaxEndDateTime = 
                  CASE
                    WHEN @MaxEndDateTime IS NULL THEN @EndDateTime
                    WHEN @EndDateTime > @MaxEndDateTime THEN @EndDateTime
                    ELSE @MaxEndDateTime
                  END
          END
        END 
      END 
      
      SET @TotalHours = ABS(DATEDIFF(hour, @MinStartDateTime, @MaxEndDateTime))
      
      INSERT @Result (
         DatasetId
        ,ServerName
        ,DatabaseName
        ,DatasetName
        ,AggregationTypeId
        ,AggregationTypeName
        ,MaxDataAgeDays
        ,[RowCount]
        ,MinStartDateTime
        ,SizeKb
        ,DailyRowCount
        ,DailySizeKb
        ,DataFileGroupName
        ,IndexFileGroupName
      )
      SELECT 
         @DatasetId
        ,@ServerName
        ,@DatabaseName
        ,@DatasetName
        ,@AggregationTypeId
        ,@AggregationTypeName
        ,@MaxDataAgeDays
        ,@RowCount
        ,@MinStartDateTime
        ,@SizeKb
        ,ROUND(CASE WHEN @TotalHours > 0 THEN @RowCountForDailyAvg / CAST(@TotalHours AS float) * 24.0 ELSE NULL END, 0)
        ,CASE WHEN @TotalHours > 0 THEN @SizeKbForDailyAvg / CAST(@TotalHours AS float) * 24.0 ELSE NULL END
        ,ISNULL(@DataFileGroupName, 'default')
        ,ISNULL(@IndexFileGroupName, 'default')
    END 
  END 
  
  IF EXISTS (SELECT * FROM sys.objects WHERE name = 'MaintenanceSetting')
  BEGIN
    DELETE @TableSize

    SET @DomainTableRowId = 0
    
    WHILE EXISTS (SELECT *
                  FROM DomainTable
                  WHERE (DomainTableRowId > @DomainTableRowId)
                 )
    BEGIN
      SELECT TOP 1
         @DomainTableRowId = DomainTableRowId
        ,@TableName = QUOTENAME(SchemaName) + '.' + QUOTENAME(TableName)
      FROM DomainTable
      WHERE (DomainTableRowId > @DomainTableRowId)
      ORDER BY DomainTableRowId

      INSERT @TableSize (TableName, [RowCount], Reserved, Data, IndexSize, Unused)
      EXEC sp_spaceused @TableName
    END

    INSERT @Result (
       DatasetId
      ,ServerName
      ,DatabaseName
      ,DatasetName
      ,AggregationTypeId
      ,AggregationTypeName
      ,MaxDataAgeDays
      ,SizeKb
      ,DataFileGroupName
      ,IndexFileGroupName
    )
    SELECT
       '00000000-0000-0000-0000-000000000000' DatasetId
      ,ServerName
      ,DatabaseName
      ,'Configuration data set' DatasetName
      ,at.AggregationTypeId
      ,at.AggregationTypeDefaultName
      ,CASE
          WHEN ms.InstanceMaxAgeDays > ms.ManagementPackMaxAgeDays THEN ms.ManagementPackMaxAgeDays
          ELSE ms.InstanceMaxAgeDays
       END 'MaxDataAgeDays'
      ,ISNULL((SELECT SUM(CAST(REPLACE(REPLACE(Reserved, 'KB', ''), ' ', '') as bigint)) FROM @TableSize), 0)
      ,'default'
      ,'default'
    FROM vMemberDatabase mdb
          CROSS JOIN vAggregationType at
          CROSS JOIN MaintenanceSetting ms
    WHERE (mdb.MasterDatabaseInd = 1)
      AND (at.AggregationTypeId = 0)
  END
  
  UPDATE @Result
  SET TotalSizeKb = DailySizeKb * MaxDataAgeDays
     ,TotalRowCount = DailyRowCount * MaxDataAgeDays

  SELECT
    result.DatasetName
    ,result.AggregationTypeName
	,CASE
		WHEN sda.AggregationTypeId IS NULL THEN '0'
		ELSE sda.AggregationTypeId
	END AggregationTypeId
	--,sda.AggregationTypeId
    ,result.MaxDataAgeDays as 'MaxDataAgeDays'
	,GroomingIntervalMinutes
    ,SizeGB = ROUND((CAST(result.SizeKb AS float) / 1000000.00),3)
    ,PercentOfDW = CAST(result.SizeKb AS float) / (SELECT SUM(SizeKb) FROM @Result) * 100
	,CASE
		WHEN sda.GroomStoredProcedureName IS NULL THEN 'NoGroomingAvailable'
		ELSE sda.GroomStoredProcedureName
	END GroomStoredProcedureName
    ,CASE
		WHEN sda.DatasetId IS NULL THEN '00000000-0000-0000-0000-000000000000'
		ELSE sda.DatasetId
	END DatasetId
  FROM @Result result
  left outer JOIN
  StandardDatasetAggregation sda ON (sda.DatasetId = result.DatasetId) and sda.AggregationTypeId = result.AggregationTypeId
  ORDER BY SizeGB DESC
