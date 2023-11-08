DECLARE @GetManagedTypeIDSystemGroup UNIQUEIDENTIFIER = dbo.fn_ManagedTypeID_Group()

EXEC sp_executesql N'
SELECT 
    MEV.[Id] AS EntityId,
    MP.[MPName] AS ManagementPackName,
    MP.[MPFriendlyName] AS ManagementPackFriendlyName,
    MEV.[DisplayName],
    MEV.[Path],
    MEV.[FullName],
	COUNT(R.[TargetEntityId]) AS MembershipCount,
    MEV.[IsManaged],
    MEV.[IsDeleted],
    MEV.[LastModified],
    MEV.[TypedManagedEntityId],
    MEV.[MonitoringClassId],
    MEV.[TypedMonitoringObjectIsDeleted],
    MEV.[HealthState],
    MEV.[OperationalState],
    MEV.[StateLastModified],
    MEV.[IsAvailable],
    MEV.[AvailabilityLastModified],
    MEV.[InMaintenanceMode],
    MEV.[MaintenanceModeLastModified],
    MEV.[TimeAdded],
    MEV.[LastModifiedBy]
FROM 
    dbo.ManagedEntityGenericView MEV
INNER JOIN 
    dbo.TypedManagedEntity TME ON MEV.[BaseManagedEntityId] = TME.[BaseManagedEntityId]
INNER JOIN 
    dbo.ManagedType MT ON TME.[ManagedTypeId] = MT.[ManagedTypeId]
INNER JOIN 
    dbo.ManagementPack MP ON MT.[ManagementPackId] = MP.[ManagementPackId]
LEFT JOIN 
    dbo.[Relationship] R ON MEV.[BaseManagedEntityId] = R.[SourceEntityId]
    AND R.[IsDeleted] = 0
    AND R.[RelationshipTypeId] IN (
        SELECT [RelationshipTypeId]
        FROM dbo.fn_ContainmentRelationshipTypes()
    )
WHERE 
    TME.[ManagedTypeId] IN (
        SELECT [DerivedManagedTypeId]
        FROM dbo.fn_DerivedManagedTypes(@GetManagedTypeIDSystemGroup)
    )
AND
    MEV.[BaseManagedEntityId] NOT IN (
        SELECT R2.[TargetEntityId]
        FROM dbo.[Relationship] R2
        JOIN dbo.fn_ContainmentRelationshipTypes() CRT ON R2.[RelationshipTypeId] = CRT.[RelationshipTypeId]
        WHERE R2.[IsDeleted] = 0
        AND R2.SourceEntityId IN (
            SELECT DISTINCT TME2.[BaseManagedEntityId]
            FROM dbo.[TypedManagedEntity] TME2
            WHERE TME2.[ManagedTypeId] IN (
                SELECT [DerivedManagedTypeId]
                FROM dbo.fn_DerivedManagedTypes(@GetManagedTypeIDSystemGroup)
            )
        )
    )
GROUP BY
    MEV.[Id],
    MP.[MPName],
    MP.[MPFriendlyName],
    MEV.[DisplayName],
    MEV.[Path],
    MEV.[FullName],
    MEV.[IsManaged],
    MEV.[IsDeleted],
    MEV.[LastModified],
    MEV.[TypedManagedEntityId],
    MEV.[MonitoringClassId],
    MEV.[TypedMonitoringObjectIsDeleted],
    MEV.[HealthState],
    MEV.[OperationalState],
    MEV.[StateLastModified],
    MEV.[IsAvailable],
    MEV.[AvailabilityLastModified],
    MEV.[InMaintenanceMode],
    MEV.[MaintenanceModeLastModified],
    MEV.[TimeAdded],
    MEV.[LastModifiedBy]
OPTION (RECOMPILE)
', N'@GetManagedTypeIDSystemGroup UNIQUEIDENTIFIER',
@GetManagedTypeIDSystemGroup = @GetManagedTypeIDSystemGroup
