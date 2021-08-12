SELECT
   PrincipalName,
   DisplayName,
   MaximumQueueSize,
   IsManagementServer,
   IsGateway,
   HeartbeatEnabled,
   HeartbeatInterval,
   Port 
FROM
   MTV_HealthService 
where
   PrincipalName IS NULL