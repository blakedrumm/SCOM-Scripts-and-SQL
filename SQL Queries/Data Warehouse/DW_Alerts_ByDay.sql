SELECT CONVERT(VARCHAR(20), DBCreatedDateTime, 102) AS DayAdded, COUNT(*) AS NumAlertsPerDay 
FROM Alert.vAlert
WHERE RaisedDateTime is not NULL 
GROUP BY CONVERT(VARCHAR(20), DBCreatedDateTime, 102) 
ORDER BY DayAdded DESC