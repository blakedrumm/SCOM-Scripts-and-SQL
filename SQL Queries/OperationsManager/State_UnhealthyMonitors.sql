SELECT 
 count(*) as 'UnhealthyMonitorInstances',
mv.DisplayName AS 'MonitorDisplayName',
mv.Name AS 'MonitorName',
MonitorState = CASE 
  WHEN s.HealthState = 3 THEN 'Critical'
  WHEN s.HealthState = 2 THEN 'Warning'
  END
FROM State s
JOIN MonitorView mv ON mv.Id = s.MonitorId
WHERE s.HealthState IN (2,3)
AND mv.IsUnitMonitor = 1
GROUP BY mv.Name,mv.DisplayName,s.HealthState
ORDER by count(*) DESC