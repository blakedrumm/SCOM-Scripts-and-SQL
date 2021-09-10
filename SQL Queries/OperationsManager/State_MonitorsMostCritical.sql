SELECT count(*) as 'MonitorCount',
mv.DisplayName AS 'MonitorDisplayName',
mv.Name AS 'MonitorName'
FROM State s WITH (NOLOCK)
JOIN MonitorView mv ON mv.Id = s.MonitorId
WHERE s.HealthState = 3
AND mv.IsUnitMonitor = 1
GROUP BY mv.Name,mv.DisplayName
ORDER by count(*) DESC