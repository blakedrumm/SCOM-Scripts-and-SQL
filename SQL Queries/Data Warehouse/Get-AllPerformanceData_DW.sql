select
vManagedEntity.Path
 ,Perf.vPerfdaily.DateTime
 ,Perf.vPerfdaily.SampleCount
 ,vPerformanceRule.ObjectName
 ,vPerformanceRule.CounterName
 ,vManagedEntity.Name
 ,Perf.vPerfdaily.Averagevalue
 ,Perf.vPerfdaily.MinValue
 ,Perf.vPerfdaily.MaxValue
 ,vRule.RuleDefaultName
from Perf.vPerfDaily
join vPerformanceRuleInstance on vPerformanceRuleInstance.PerformanceRuleInstanceRowid=Perf.vPerfDaily.PerformanceRuleInstanceRowid
join vPerformanceRule on vPerformanceRule.RuleRowId=vPerformanceRuleInstance.RuleRowId
join vManagedEntity on vManagedEntity.ManagedEntityRowid=Perf.vPerfDaily.ManagedEntityRowId
join vRule on vRule.RuleRowId=vPerformanceRuleInstance.RuleRowId
where vRule.RuleDefaultName like '%Windows Server 2012%' and
Perf.vPerfDaily.Datetime between '2021-07-28' and '2021-08-05'
Order by Path ASC, Perf.vPerfDaily.DateTime DESC, RuleDefaultName ASC
