SELECT HS.BaseManagedEntityId,
HS.DisplayName AS HealthService,
TargetBME.DisplayName AS PrimaryManagementServer,
Version, 
ActionAccountIdentity, 
ActiveDirectoryManaged,
CreateListener,
ProxyingEnabled, 
HeartbeatEnabled,
HeartbeatInterval, 
IsManuallyInstalled, 
InstallTime,
Port,
ProxyingEnabled,
IsAgent, 
IsGateway, 
IsManagementServer,
IsRHS,
PatchList,
MaximumQueueSize
FROM MTV_HealthService HS WITH (NOLOCK)
JOIN Relationship R WITH (NOLOCK) ON R.SourceEntityId = HS.BaseManagedEntityId
JOIN BaseManagedEntity TargetBME WITH (NOLOCK) ON R.TargetEntityId = TargetBME.BaseManagedEntityId
WHERE R.IsDeleted = 0 AND R.RelationshipTypeId  = dbo.fn_ManagedTypeId_MicrosoftSystemCenterHealthServiceCommunication()
ORDER BY [HealthService],[PrimaryManagementServer]
