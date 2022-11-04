SELECT TOP 50 SUM(1) AS AlertCount, AlertName, AlertDescription, AlertProblemGuid, MonitorSystemName 
FROM Alert.vAlert va INNER JOIN
Monitor mon on mon.MonitorGuid = va.AlertProblemGuid
WHERE RaisedDateTime is not NULL 
GROUP BY AlertName, AlertDescription, AlertProblemGuid, MonitorSystemName 
ORDER BY AlertCount DESC