/*Top 100 performance insertions by perf object and counter name: */
SELECT        TOP (100) pcv.ObjectName, r.DisplayName AS 'RuleName', pcv.CounterName, MPV.DisplayName AS 'MPDisplayName', pcv.RuleId, MPV.LanguageCode, COUNT(pcv.CounterName) AS Total
FROM            PerformanceDataAllView AS pdv INNER JOIN
                         PerformanceCounterView AS pcv ON pdv.PerformanceSourceInternalId = pcv.PerformanceSourceInternalId INNER JOIN
                         RuleView AS r ON pcv.RuleId = r.Id INNER JOIN
                         ManagementPackView AS MPV ON r.ManagementPackId = MPV.Id

WHERE MPV.LanguageCode = 'ENU'
GROUP BY pcv.ObjectName, pcv.CounterName, MPV.DisplayName, pcv.RuleId, r.DisplayName, MPV.LanguageCode
ORDER BY Total DESC