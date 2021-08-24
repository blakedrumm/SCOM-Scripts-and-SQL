--Start Delete Orphan Agents
BEGIN TRAN
declare @TypedManagedEntityId uniqueidentifier;
declare @DiscoverySourceId uniqueidentifier;
declare @LastErr int;
declare @TimeGenerated datetime;

set @TimeGenerated = GETUTCDATE();
set @DiscoverySourceId = dbo.fn_DiscoverySourceId_User();

DECLARE EntitiesToBeRemovedCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR 
SELECT TME.[TypedManagedEntityid]
FROM MTV_HealthService HS
INNER JOIN dbo.[BaseManagedEntity] BHS
    ON BHS.[BaseManagedEntityId] = HS.[BaseManagedEntityId]
-- get host managed computer instances
INNER JOIN dbo.[TypedManagedEntity] TME
    ON TME.[BaseManagedEntityId] = BHS.[TopLevelHostEntityId]
    AND TME.[IsDeleted] = 0
INNER JOIN dbo.[DerivedManagedTypes] DMT
    ON DMT.[DerivedTypeId] = TME.[ManagedTypeId]
INNER JOIN dbo.[ManagedType] BT
    ON DMT.[BaseTypeId] = BT.[ManagedTypeId]
    AND BT.[TypeName] = N'Microsoft.Windows.Computer'
-- only with missing primary
LEFT OUTER JOIN dbo.Relationship HSC
    ON HSC.[SourceEntityId] = HS.[BaseManagedEntityId]
    AND HSC.[RelationshipTypeId] = dbo.fn_RelationshipTypeId_HealthServiceCommunication()
    AND HSC.[IsDeleted] = 0
INNER JOIN DiscoverySourceToTypedManagedEntity DSTME
    ON DSTME.[TypedManagedEntityId] = TME.[TypedManagedEntityId]
    AND DSTME.[DiscoverySourceId] = @DiscoverySourceId
WHERE HS.[IsAgent] = 1
AND HSC.[RelationshipId] IS NULL;

OPEN EntitiesToBeRemovedCursor

FETCH NEXT FROM EntitiesToBeRemovedCursor 
INTO @TypedManagedEntityId

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRAN

    -- Delete entity
	Print @TypedManagedEntityId
    EXEC @LastErr = [p_RemoveEntityFromDiscoverySourceScope] @TypedManagedEntityId, @DiscoverySourceId, @TimeGenerated;
    IF @LastErr <> 0 
        GOTO Err

    COMMIT TRAN

    -- Get the next typedmanagedentity to delete.
    FETCH NEXT FROM EntitiesToBeRemovedCursor 
    INTO @TypedManagedEntityId
END

CLOSE EntitiesToBeRemovedCursor
DEALLOCATE EntitiesToBeRemovedCursor

GOTO Done

Err:
ROLLBACK TRAN
GOTO Done

Done:
COMMIT TRAN
