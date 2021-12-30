SELECT TOP 20 RepeatCount, AlertStringName, AlertStringDescription, MonitoringRuleId, Name 
FROM Alertview WITH (NOLOCK) 
WHERE Timeraised is not NULL 
GROUP BY AlertStringName, RepeatCount, AlertStringDescription, MonitoringRuleId, Name 
ORDER BY RepeatCount DESC
