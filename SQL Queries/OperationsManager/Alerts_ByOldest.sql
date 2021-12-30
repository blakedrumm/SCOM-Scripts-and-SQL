SELECT TOP 20 DATEDIFF(Day,TimeRaised,current_timestamp) AS DaysOpened, RepeatCount, AlertStringName, AlertStringDescription, MonitoringObjectDisplayName, MonitoringRuleId, Name, AlertParams, Case ResolutionState
When 0 then 'Open'
End as [ResolutionState]
FROM Alertview WITH (NOLOCK) 
WHERE Timeraised is not NULL
AND ResolutionState = 0
GROUP BY AlertStringName, RepeatCount, TimeRaised, MonitoringObjectDisplayName, Lastmodified,AlertStringDescription, AlertParams, MonitoringRuleId, Name, ResolutionState
ORDER BY DaysOpened DESC, RepeatCount DESC
