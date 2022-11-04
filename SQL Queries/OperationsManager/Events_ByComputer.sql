SELECT top 20 LoggingComputer as ComputerName, COUNT(*) AS TotalEvents, Number as EventID, Name as RuleName, DisplayName as RuleDisplayName
FROM EventallView eav with (NOLOCK)
LEFT JOIN RuleView rv with (NOLOCK) on rv.Id = eav.RuleId
GROUP BY LoggingComputer, Number, Name, DisplayName
ORDER BY TotalEvents DESC