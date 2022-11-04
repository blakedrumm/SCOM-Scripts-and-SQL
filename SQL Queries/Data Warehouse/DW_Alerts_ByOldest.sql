SELECT TOP 50 DATEDIFF(Day,RaisedDateTime,current_timestamp) AS DaysOpened, Case Severity
When 0 then 'Information'
When 1 then 'Warning'
When 2 then 'Critical'
End as [Severity],RepeatCount, AlertName, AlertDescription, MonitorSystemName, MonitorGuid, ParameterValue, Case ResolutionState
When 0 then 'Open'
End as [ResolutionState]
FROM Alert.vAlert va INNER JOIN
Monitor mon on mon.MonitorGuid = va.AlertProblemGuid INNER JOIN
Alert.vAlertParameter vap on va.AlertGuid = vap.AlertGuid INNER JOIN
Alert.vAlertResolutionState vars on va.AlertGuid = vars.AlertGuid
WHERE RaisedDateTime is not NULL
AND ResolutionState = 0
GROUP BY AlertName, RepeatCount, RaisedDateTime, Severity, MonitorSystemName, DWLastModifiedDateTime, AlertDescription, ParameterValue, MonitorGuid, ResolutionState
ORDER BY DaysOpened DESC, RepeatCount DESC