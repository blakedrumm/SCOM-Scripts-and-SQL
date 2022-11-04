select r.RuleDefaultName, pr.ObjectName, pr.CounterName, mp.ManagementPackDefaultName as MPName, COUNT(me.ManagedEntityDefaultName) AS Total
from Perf.vPerfRaw perf
join vPerformanceRuleInstance PRI on perf.PerformanceRuleInstanceRowId = PRI.PerformanceRuleInstanceRowId
join vPerformanceRule pr on PRI.RuleRowId = PR.RuleRowId
join vManagedEntity me on perf.ManagedEntityRowId = ME.ManagedEntityRowId
join [dbo].[vRule] r on r.RuleRowId = PR.RuleRowId
join vManagementPack mp on r.ManagementPackRowId = mp.ManagementPackRowId
where perf.DateTime > GetUTCDate() -48
GROUP BY PR.ObjectName, PR.CounterName, r.ruledefaultname, mp.ManagementPackDefaultName
ORDER BY COUNT (me.ManagedEntityDefaultName) DESC