--find orphans
-- if anything found run this query: https://github.com/blakedrumm/SCOM-Scripts-and-SQL/blob/master/SQL%20Queries/OperationsManager/Orphaned_Purge.sql
declare @DiscoverySourceId uniqueidentifier;
declare @TimeGenerated datetime;
set @TimeGenerated = GETUTCDATE();
set @DiscoverySourceId = dbo.fn_DiscoverySourceId_User();
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
