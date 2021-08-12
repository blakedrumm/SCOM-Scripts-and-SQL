SELECT top 20 LoggingComputer as ComputerName, COUNT(*) AS TotalEvents, Number as EventID 
FROM EventallView with (NOLOCK) 
GROUP BY LoggingComputer, Number 
ORDER BY TotalEvents DESC