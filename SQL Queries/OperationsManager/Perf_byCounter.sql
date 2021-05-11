/*Top 30 performance insertions by perf object and counter name: */
SELECT        TOP (30) pcv.ObjectName, r.DisplayName AS 'RuleName', pcv.CounterName, pcv.RuleId, COUNT(pcv.CounterName) AS Total
FROM            PerformanceDataAllView AS pdv INNER JOIN
                         PerformanceCounterView AS pcv ON pdv.PerformanceSourceInternalId = pcv.PerformanceSourceInternalId INNER JOIN
                         RuleView AS r ON pcv.RuleId = r.Id INNER JOIN

GROUP BY pcv.ObjectName, pcv.CounterName, pcv.RuleId, r.DisplayName
ORDER BY Total DESC
