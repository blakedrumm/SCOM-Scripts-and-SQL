SELECT top 50 Number as EventID, 
 COUNT(*) AS TotalEvents,
 Publishername as EventSource 
FROM EventAllView WITH (NOLOCK) 
GROUP BY Number, Publishername 
ORDER BY TotalEvents DESC