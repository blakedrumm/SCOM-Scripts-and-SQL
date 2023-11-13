-- Author: Blake Drumm (blakedrumm@microsoft.com)

--SELECT [ManagedTypeId], [TypeName]
--FROM [dbo].[ManagedType]
--WHERE ManagedTypeId = 'EA99500D-8D52-FC52-B5A5-10DCD1E9D2BD'

--TypeName: Microsoft.Windows.Computer
DECLARE @ManagedTypeId uniqueidentifier = 'EA99500D-8D52-FC52-B5A5-10DCD1E9D2BD'

SELECT DISTINCT
    [T].[Id],
    [T].[Name],
    [T].[Path],
    [T].[FullName],
    [T].[DisplayName],
    [T].[IsManaged],
    [T].[IsDeleted],
    [PXH].[BaseManagedEntityId] AS [ProxyAgentHealthServiceId],
    [PXH].[DisplayName] AS [ProxyAgentPrincipalName],
    [T].[LastModified],
    [T].[TypedMonitoringObjectIsDeleted],
    CASE [T].[HealthState]
        WHEN 1 THEN
            'Healthy'
        WHEN 2 THEN
            'Warning'
        WHEN 3 THEN
            'Critical'
        ELSE
            'Unknown (HealthState: ' + CAST([T].[HealthState] AS VARCHAR) + ')' -- Optional: for values other than 1, 2, or 3
    END AS ResolvedHealthState,
    [T].[StateLastModified],
    CASE [T].[IsAvailable]
        WHEN 1 THEN
            'True'
        WHEN 0 THEN
            'False'
        ELSE
            'Unknown (Availability: ' + CAST([T].[IsAvailable] AS VARCHAR) + ')' -- Optional: for values other than 1 or 0
    END AS IsAvailable,
    [T].[AvailabilityLastModified],
    [T].[InMaintenanceMode],
    [T].[MaintenanceModeLastModified],
    [T].[TimeAdded],
    [T].[LastModifiedBy]
FROM dbo.ManagedEntityGenericView AS T
    INNER JOIN dbo.BaseManagedEntity AS BME
        ON BME.[BaseManagedEntityId] = T.[Id]
           AND BME.[BaseManagedTypeId] = @ManagedTypeId
    INNER JOIN dbo.Relationship AS R
        ON R.[TargetEntityId] = T.[Id]
    INNER JOIN dbo.BaseManagedEntity AS PXH
        ON PXH.[BaseManagedEntityId] = R.[SourceEntityId]
WHERE (
    (
        T.[IsDeleted] = 0
        AND T.[TypedMonitoringObjectIsDeleted] = 0
        AND R.[IsDeleted] = 0
        AND (
                R.[RelationshipTypeId] = dbo.fn_ManagedTypeId_MicrosoftSystemCenterHealthServiceShouldManageEntity()
                OR R.[RelationshipTypeId] = dbo.fn_ManagedTypeId_MicrosoftSystemCenterManagementActionPointShouldManageEntity()
            )
    )
      )
