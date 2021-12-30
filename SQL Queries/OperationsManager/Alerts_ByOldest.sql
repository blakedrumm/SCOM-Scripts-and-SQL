SELECT TOP 20 DATEDIFF(Day,TimeRaised,current_timestamp) AS DaysOpened, Case Severity
When 0 then 'Information'
When 1 then 'Warning'
When 2 then 'Critical'
End as [Severity],RepeatCount, AlertStringName, AlertStringDescription, MonitoringObjectDisplayName, MonitoringRuleId, Name, AlertParams, Case ResolutionState
When 0 then 'Open'
End as [ResolutionState]
FROM Alertview WITH (NOLOCK) 
WHERE Timeraised is not NULL
AND ResolutionState = 0
GROUP BY AlertStringName, RepeatCount, TimeRaised, Severity, MonitoringObjectDisplayName, Lastmodified,AlertStringDescription, AlertParams, MonitoringRuleId, Name, ResolutionState
ORDER BY DaysOpened DESC, RepeatCount DESC
