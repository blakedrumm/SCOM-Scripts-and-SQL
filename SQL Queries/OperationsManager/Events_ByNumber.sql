SELECT top 50 Number as EventID, 
 COUNT(*) AS TotalEvents,
 Publishername as EventSource,
 Name as RuleName, DisplayName as RuleDisplayName
FROM EventAllView eav WITH (NOLOCK)
LEFT JOIN RuleView rv with (NOLOCK) on rv.Id = eav.RuleId
GROUP BY Number, Publishername, Name, DisplayName
ORDER BY TotalEvents DESC