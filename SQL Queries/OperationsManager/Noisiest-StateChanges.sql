-- Top 50 Noisiest State Changes
select distinct top 50 count(sce.StateId) as NumStateChanges, 
m.DisplayName as MonitorDisplayName, 
m.Name as MonitorIdName, 
mt.typename AS TargetClass,
MP.MPname
from StateChangeEvent sce with (nolock) 
join state s with (nolock) on sce.StateId = s.StateId 
join monitorview m with (nolock) on s.MonitorId = m.Id 
join managedtype mt with (nolock) on m.TargetMonitoringClassId = mt.ManagedTypeId 
join ManagementPack MP with (nolock) on MP.ManagementPackId = M.ManagementPackId
where m.IsUnitMonitor = 1
  --- Scoped to within last 7 days 
AND sce.TimeGenerated > dateadd(dd,-3,getutcdate()) 
group by m.DisplayName, m.Name,mt.typename, MP.MPName
order by NumStateChanges desc
