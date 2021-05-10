select TOP 30 PR.CounterName,PR.ObjectName, vR.ruledefaultname As RuleName, COUNT(PR.countername) AS Total
from Perf.vPerfRaw perf
join ManagedEntity ME on perf.ManagedEntityRowId = ME.ManagedEntityRowId
join PerformanceRuleInstance PRI on perf.PerformanceRuleInstanceRowId = PRI.PerformanceRuleInstanceRowId
join PerformanceRule PR on PRI.RuleRowId = PR.RuleRowId
join vRule vR on vR.rulerowid = PR.RuleRowId
where perf.DateTime > GetUTCDate() -48
GROUP BY PR.ObjectName, PR.CounterName, vr.ruledefaultname
ORDER BY COUNT (PR.CounterName) DESC