select distinct top 50 count(sce.StateId) as NumStateChanges, 
m.DisplayName as MonitorDisplayName, 
m.Name as MonitorIdName, 
mt.typename AS TargetClass 
from StateChangeEvent sce with (nolock) 
join state s with (nolock) on sce.StateId = s.StateId 
join monitorview m with (nolock) on s.MonitorId = m.Id 
join managedtype mt with (nolock) on m.TargetMonitoringClassId = mt.ManagedTypeId 
where m.IsUnitMonitor = 1 
group by m.DisplayName, m.Name,mt.typename 
order by NumStateChanges desc