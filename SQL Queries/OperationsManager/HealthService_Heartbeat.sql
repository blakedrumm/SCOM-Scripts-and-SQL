SELECT bme.DisplayName AS 'AgentName',
s.LastModified as 'LastModifiedUTC'
FROM state AS s, BaseManagedEntity AS bme WITH (NOLOCK)
WHERE s.basemanagedentityid = bme.basemanagedentityid 
AND s.monitorid 
IN (SELECT MonitorId FROM Monitor WITH (NOLOCK) WHERE MonitorName = 'Microsoft.SystemCenter.HealthService.Heartbeat') 
AND s.Healthstate = '3' AND bme.IsDeleted = '0' 
ORDER BY s.Lastmodified DESC