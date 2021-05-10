/*Top 30 performance insertions by perf object and counter name: */
SELECT        TOP (30) pcv.ObjectName, r.DisplayName, pcv.CounterName, MPV.DisplayName AS 'MPDisplayName', pcv.RuleId, r.DisplayName, COUNT(pcv.CounterName) AS Total
FROM            PerformanceDataAllView AS pdv INNER JOIN
                         PerformanceCounterView AS pcv ON pdv.PerformanceSourceInternalId = pcv.PerformanceSourceInternalId INNER JOIN
                         RuleView AS r ON pcv.RuleId = r.Id INNER JOIN
                         ManagementPackView AS MPV ON r.ManagementPackId = MPV.Id

GROUP BY pcv.ObjectName, pcv.CounterName, MPV.DisplayName, pcv.RuleId, r.DisplayName
ORDER BY Total DESC