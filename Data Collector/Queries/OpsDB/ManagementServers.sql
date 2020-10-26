SELECT DisplayName, 
  IsManagementServer, 
  IsGateway, 
  IsRHS, 
  Version,
  ActionAccountIdentity,
  HeartbeatInterval
FROM MTV_HealthService
WHERE IsManagementServer = 1
OR IsGateway = 1
ORDER BY DisplayName