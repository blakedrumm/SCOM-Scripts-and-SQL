-- PLEASE ONLY USE AFTER BACKUPS PERFORMED (DW THEN OPSDB)
--Get the Management pack ID and replace the ManagementPackId in the below query and need to follow all the steps mentioned below :-
--Example to get the IDs
select * from managementpack where MPName = 'Darden.DataCore.Management.Pack'
 
--Step #1
 
declare @ManagementPackId uniqueidentifier
set @ManagementPackId = '99276100-85F6-2F6B-D631-5887C13D60CB'
 
 
INSERT INTO dbo.MPRemovalLog SELECT ManagementPackId, MPName, MPVersion, MPKeyToken, GETUTCDATE() FROM
dbo.[ManagementPack] WHERE ManagementPackId = @ManagementPackId
 
 
 
--Step #2
 
declare @ManagementPackId uniqueidentifier
set @ManagementPackId = '99276100-85F6-2F6B-D631-5887C13D60CB'
 
DELETE FROM dbo.AlertHistory
WHERE AlertId IN 
(SELECT AlertId 
 FROM dbo.Alert WHERE IsMonitorAlert = 1 AND ProblemId IN
    (SELECT MonitorId FROM Monitor
  WHERE ManagementPackId = @ManagementPackId)
)
 
DELETE FROM dbo.Alert WHERE IsMonitorAlert = 1 AND ProblemId IN
    (SELECT MonitorId FROM Monitor
  WHERE ManagementPackId = @ManagementPackId)        
        
DELETE FROM dbo.StateChangeEvent WHERE StateId IN
(SELECT StateId FROM dbo.State S
  JOIN dbo.Monitor M ON M.MonitorId = S.MonitorId
  WHERE M.ManagementPackId = @ManagementPackId)
 
DELETE FROM dbo.State WHERE MonitorId IN
(SELECT MonitorId FROM dbo.Monitor WHERE ManagementPackId = @ManagementPackId)
 
DELETE FROM dbo.Monitor WHERE  ManagementPackId = @ManagementPackId
 
 
--Step #3
 
declare @ManagementPackId uniqueidentifier
set @ManagementPackId = '99276100-85F6-2F6B-D631-5887C13D60CB'
 
DECLARE @ManagedTypeId uniqueidentifier
 
SELECT @ManagedTypeId = ManagedTypeId FROM dbo.[ManagedType] WHERE ManagementPackId = @ManagementPackId
WHILE @ManagedTypeId IS NOT NULL
BEGIN
EXEC p_TypeDeletePermanent @ManagedTypeId
SET @ManagedTypeId = NULL
SELECT @ManagedTypeId = ManagedTypeId FROM dbo.[ManagedType] WHERE ManagementPackId = @ManagementPackId
END
 
 
--Step #4
 
declare @ManagementPackId uniqueidentifier
set @ManagementPackId = '99276100-85F6-2F6B-D631-5887C13D60CB'
 
DELETE FROM [dbo].[SecureStorageSecureReference] WHERE SecureReferenceId IN
(SELECT SecureReferenceId FROM [dbo].[SecureReference] WHERE ManagementPackId = @ManagementPackId)
 
DELETE FROM dbo.PerformanceSource WHERE RuleId IN (SELECT RuleId FROM dbo.Rules WHERE ManagementPackId = @ManagementPackId)
 
DELETE FROM dbo.PerformanceSignature WHERE LearningRuleId IN  (SELECT RuleId FROM dbo.Rules WHERE ManagementPackId = @ManagementPackId)
 
DELETE FROM dbo.OverrideableParameter WHERE MonitorTypeId IN
(SELECT MonitorTypeId FROM [dbo].[MonitorType] WHERE ManagementPackId = @ManagementPackId)
 
DELETE FROM dbo.DataWarehouseDatasetSchemaReference WHERE DataWarehouseDatasetId IN
(SELECT DataWarehouseDatasetId FROM [dbo].[DataWarehouseDataset] WHERE ManagementPackId = @ManagementPackId)
 
DELETE FROM dbo.MonitorTypeSchemaReference WHERE MonitorTypeId IN
(SELECT MonitorTypeId FROM [dbo].[MonitorType] WHERE ManagementPackId = @ManagementPackId)
 
DELETE FROM dbo.OverrideableParameter WHERE ModuleTypeId IN
(SELECT ModuleTypeId FROM [dbo].[ModuleType] WHERE ManagementPackId = @ManagementPackId)
 
DELETE FROM [dbo].[ModuleTypeSchemaReference] WHERE ModuleTypeId IN
(SELECT ModuleTypeId FROM [dbo].[ModuleType] WHERE ManagementPackId = @ManagementPackId)
 
DELETE FROM [dbo].[ViewTypeSchemaReference] WHERE ViewTypeId IN
(SELECT ViewTypeId FROM [dbo].[ViewType] WHERE ManagementPackId = @ManagementPackId)
 
DELETE FROM [dbo].[TemplateSchemaReference] WHERE TemplateId IN
(SELECT TemplateId FROM [dbo].[Template] WHERE ManagementPackId = @ManagementPackId)
 
DELETE FROM [dbo].[DiscoveryRelationshipProperty] WHERE ManagementPackId = @ManagementPackId
 
DELETE FROM [dbo].[DiscoveryRelationship] WHERE ManagementPackId = @ManagementPackId
 
DELETE FROM [dbo].[DiscoveryClassProperty] WHERE ManagementPackId = @ManagementPackId
 
DELETE FROM [dbo].[DiscoveryClass] WHERE ManagementPackId = @ManagementPackId
 
 
--Step #5
 
declare @ManagementPackId uniqueidentifier
set @ManagementPackId = '99276100-85F6-2F6B-D631-5887C13D60CB'
 
EXEC dbo.p_PreDiscoveryDeleteViaMPDelete @ManagementPackId
 
DELETE FROM [dbo].[Discovery] WHERE ManagementPackId = @ManagementPackId
 
DELETE FROM [dbo].[Diagnostic] WHERE ManagementPackId = @ManagementPackId
 
DELETE FROM [dbo].[Recovery] WHERE ManagementPackId = @ManagementPackId
 
 
--Step #6
 
declare @ManagementPackId uniqueidentifier
set @ManagementPackId = '99276100-85F6-2F6B-D631-5887C13D60CB'
 
DECLARE @RelationshipTypeId uniqueidentifier
 
SELECT @RelationshipTypeId = RelationshipTypeId FROM dbo.RelationshipType 
 WHERE ManagementPackId = @ManagementPackId AND RelationshipTypeId NOT IN
   (SELECT BaseRelationshipTypeId FROM dbo.RelationshipType WHERE BaseRelationshipTypeId IS NOT NULL)
WHILE @RelationshipTypeId IS NOT NULL
BEGIN
EXEC p_RelationshipTypeDeletePermanent @RelationshipTypeId
 
SET @RelationshipTypeId = NULL
SELECT @RelationshipTypeId = RelationshipTypeId FROM dbo.RelationshipType 
  WHERE ManagementPackId = @ManagementPackId AND RelationshipTypeId NOT IN
   (SELECT BaseRelationshipTypeId FROM dbo.RelationshipType WHERE BaseRelationshipTypeId IS NOT NULL)
END
 
DELETE FROM [dbo].[Datatype]  WHERE ManagementPackId = @ManagementPackId
 
 
--Step #7
 
exec p_ManagementPackRemove '99276100-85F6-2F6B-D631-5887C13D60CB'


--Done!
