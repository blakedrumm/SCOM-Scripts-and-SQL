SELECT TOP 20 SUM(RepeatCount+1) AS RepeatCount, AlertStringName, AlertStringDescription, MonitoringRuleId, Name 
FROM Alertview WITH (NOLOCK) 
WHERE Timeraised is not NULL 
GROUP BY AlertStringName, AlertStringDescription, MonitoringRuleId, Name 
ORDER BY RepeatCount DESC