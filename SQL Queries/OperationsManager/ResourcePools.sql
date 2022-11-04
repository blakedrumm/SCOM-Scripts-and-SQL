-- Modified by Alex Kremenetskiy
SET NOCOUNT ON
DECLARE 
       @Statement nvarchar(max)
      ,@MicrosoftSystemCenterManagementService nvarchar(255)
      ,@BaseManagedEntityDisplayName nvarchar(255)
      ,@ManagedTypeView INT
      ,@IsDynamicColumnName nvarchar(255)
      ,@ManagedTypeViewName nvarchar(255)
SELECT @MicrosoftSystemCenterManagementService = ManagedTypeViewName
FROM dbo.ManagedType
WHERE (ManagedTypeId = dbo.fn_ManagedTypeId_MicrosoftSystemCenterManagementService())
PRINT @MicrosoftSystemCenterManagementService
SELECT @BaseManagedEntityDisplayName = S.COLUMN_NAME 
FROM INFORMATION_SCHEMA.COLUMNS AS S
WHERE S.TABLE_NAME COLLATE DATABASE_DEFAULT IN (SELECT ManagedTypeViewName AS [TABLE_NAME] FROM dbo.ManagedType) 
    AND  S.TABLE_NAME = @MicrosoftSystemCenterManagementService
    AND S.COLUMN_NAME like 'DisplayName%'
PRINT @BaseManagedEntityDisplayName 
SELECT @IsDynamicColumnName = ColumnName
FROM ManagedTypeProperty
WHERE ManagedTypePropertyName = 'IsDynamic' And DefaultValue = 'true'
PRINT @IsDynamicColumnName
IF (OBJECT_ID('tempdb..#IsDynamic') IS NOT NULL)
DROP TABLE #IsDynamic
CREATE TABLE #IsDynamic (
    BaseManagedEntityId uniqueidentifier,
    IsDynamic INT
)
DECLARE ManagedTypeViews CURSOR FAST_FORWARD FOR
    SELECT 
        ManagedTypeViewName 
    FROM ManagedType 
    WHERE BaseManagedTypeId = (SELECT SourceManagedTypeId FROM RelationshipType WHERE RelationshipTypeId = dbo.fn_ManagedTypeId_MicrosoftSystemCenterManagementServicePoolContainsManagementService()) --all pools
OPEN ManagedTypeViews
FETCH NEXT FROM ManagedTypeViews INTO @ManagedTypeViewName
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @Statement = '
    INSERT INTO #IsDynamic (
        BaseManagedEntityId,
        IsDynamic
    )
    SELECT BaseManagedEntityId, ' + QUOTENAME(@IsDynamicColumnName) + 
    ' FROM ' + @ManagedTypeViewName
    exec(@Statement)
    FETCH NEXT FROM ManagedTypeViews INTO @ManagedTypeViewName
END
CLOSE ManagedTypeViews
DEALLOCATE ManagedTypeViews
set  @Statement = '
    SELECT 
    BME.DisplayName AS ResourcePool
    ,[MS].' + QUOTENAME(@BaseManagedEntityDisplayName) + ' AS Member
    ,REPLACE(REPLACE(D.IsDynamic,0,''Manual''),1,''Automatic'') AS Membership
    FROM dbo.Relationship R
        JOIN ' + QUOTENAME(@MicrosoftSystemCenterManagementService) + ' MS ON (R.TargetEntityId = MS.BaseManagedEntityId)
        JOIN BaseManagedEntity BME ON BME.BaseManagedEntityId = R.SourceEntityId 
        JOIN #IsDynamic D ON D.BaseManagedEntityId = BME.BaseManagedEntityId
    WHERE (RelationshipTypeId = dbo.fn_ManagedTypeId_MicrosoftSystemCenterManagementServicePoolContainsManagementService())
    AND (R.IsDeleted = 0) AND (BME.IsDeleted = 0)
    ORDER BY ResourcePool, Member'
  Print @Statement
  Exec (@Statement)
  DROP TABLE #IsDynamic