-- Top 20 noisiest rules
select DisplayName from RuleView where id in (select top 20 pcv.ruleid
from PerformanceDataAllView as pdv, PerformanceCounterView as pcv
where (pdv.performancesourceinternalid = pcv.PerformanceSourceInternalId) 
group by pcv.ObjectName, pcv.CounterName, pcv.ruleid
order by COUNT (pcv.countername) desc)
 
select DisplayName from RuleView where id in (SELECT top 20 RuleId
FROM EventAllView eav with (nolock) 
GROUP BY Number, PublisherName, RuleId
ORDER BY COUNT(*) DESC)
