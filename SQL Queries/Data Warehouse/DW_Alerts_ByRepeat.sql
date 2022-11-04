SELECT TOP 50 RepeatCount, AlertName, AlertDescription, AlertProblemGuid, MonitorSystemName 
FROM Alert.vAlert va INNER JOIN
Monitor mon on mon.MonitorGuid = va.AlertProblemGuid
WHERE RaisedDateTime is not NULL 
GROUP BY AlertName, RepeatCount, AlertDescription, AlertProblemGuid, MonitorSystemName
ORDER BY RepeatCount DESC