--List of all monitors in a critical state

SELECT 
mv.DisplayName AS 'MonitorDisplayName',
mv.Name AS 'MonitorName',
bme.Path,
bme.DisplayName,
bme.FullName AS 'Target',
s.LastModified AS 'StateLastModified'
FROM State s
JOIN BaseManagedEntity bme WITH (NOLOCK) ON s.BaseManagedEntityId = bme.BaseManagedEntityId
JOIN MonitorView mv ON mv.Id = s.MonitorId
WHERE s.HealthState = 3
AND mv.IsUnitMonitor = 1
ORDER BY mv.DisplayName