-- Author: Blake Drumm (blakedrumm@microsoft.com)
-- Created: November 13th, 2023

-- The following commented-out lines would select the ManagedTypeId and TypeName from the ManagedType table for a specific ID
--SELECT [ManagedTypeId], [TypeName]
--FROM [dbo].[ManagedType]
--WHERE ManagedTypeId = 'EA99500D-8D52-FC52-B5A5-10DCD1E9D2BD'

-- TypeName: Microsoft.Windows.Computer
-- Setting a specific Managed Type ID to filter the query results
DECLARE @ManagedTypeId uniqueidentifier = 'EA99500D-8D52-FC52-B5A5-10DCD1E9D2BD'

-- Selecting distinct values from the ManagedEntityGenericView
SELECT DISTINCT
    [T].[Id], -- Unique identifier for the entity
    [T].[Name], -- Name of the entity
    [T].[Path], -- Path of the entity
    [T].[FullName], -- Full name of the entity
    [T].[DisplayName], -- Display name of the entity
    [T].[IsManaged], -- Indicates if the entity is managed
    [T].[IsDeleted], -- Indicates if the entity is deleted
    [PXH].[BaseManagedEntityId] AS [ProxyAgentHealthServiceId], -- ID of the proxy agent health service
    [PXH].[DisplayName] AS [ProxyAgentPrincipalName], -- Display name of the proxy agent
    [T].[LastModified], -- Last modified date of the entity
    [T].[TypedMonitoringObjectIsDeleted], -- Indicates if the monitoring object is deleted
    -- Resolving HealthState numeric values to corresponding textual representations
    CASE [T].[HealthState]
        WHEN 1 THEN 'Healthy'
        WHEN 2 THEN 'Warning'
        WHEN 3 THEN 'Critical'
        ELSE 'Unknown (HealthState: ' + CAST([T].[HealthState] AS VARCHAR) + ')'
    END AS ResolvedHealthState,
    [T].[StateLastModified], -- Last modification date of the state
    -- Resolving IsAvailable numeric values to 'True' or 'False'
    CASE [T].[IsAvailable]
        WHEN 1 THEN 'True'
        WHEN 0 THEN 'False'
        ELSE 'Unknown (Availability: ' + CAST([T].[IsAvailable] AS VARCHAR) + ')'
    END AS IsAvailable,
    [T].[AvailabilityLastModified], -- Last modification date of the availability
    [T].[InMaintenanceMode], -- Indicates if the entity is in maintenance mode
    [T].[MaintenanceModeLastModified], -- Last modification date of the maintenance mode
    [T].[TimeAdded], -- Time when the entity was added
    [T].[LastModifiedBy] -- Last modified by user
FROM dbo.ManagedEntityGenericView AS T
    INNER JOIN dbo.BaseManagedEntity AS BME
        ON BME.[BaseManagedEntityId] = T.[Id]
           AND BME.[BaseManagedTypeId] = @ManagedTypeId -- Join condition to filter entities based on ManagedTypeId
    INNER JOIN dbo.Relationship AS R
        ON R.[TargetEntityId] = T.[Id] -- Join condition to establish relationships
    INNER JOIN dbo.BaseManagedEntity AS PXH
        ON PXH.[BaseManagedEntityId] = R.[SourceEntityId] -- Join condition to get the proxy agent details
WHERE (
    (
        T.[IsDeleted] = 0 -- Filtering out deleted entities
        AND T.[TypedMonitoringObjectIsDeleted] = 0 -- Filtering out deleted monitoring objects
        AND R.[IsDeleted] = 0 -- Filtering out deleted relationships
        AND (
                R.[RelationshipTypeId] = dbo.fn_ManagedTypeId_MicrosoftSystemCenterHealthServiceShouldManageEntity()
                OR R.[RelationshipTypeId] = dbo.fn_ManagedTypeId_MicrosoftSystemCenterManagementActionPointShouldManageEntity()
            ) -- Additional filtering based on relationship types
    )
)
