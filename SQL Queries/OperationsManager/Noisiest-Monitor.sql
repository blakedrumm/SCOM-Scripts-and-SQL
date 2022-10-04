-- Top 50 noisiest monitor
select distinct top 50 count(sce.StateId) as NumStateChanges, 
bme.DisplayName AS ObjectName, 
bme.Path, 
m.DisplayName as MonitorDisplayName, 
m.Name as MonitorIdName, 
mt.typename AS TargetClass,
MP.MPName
from StateChangeEvent sce with (nolock) 
join state s with (nolock) on sce.StateId = s.StateId 
join BaseManagedEntity bme with (nolock) on s.BasemanagedEntityId = bme.BasemanagedEntityId 
join MonitorView m with (nolock) on s.MonitorId = m.Id 
join managedtype mt with (nolock) on m.TargetMonitoringClassId = mt.ManagedTypeId 
join ManagementPack MP with (nolock) on MP.ManagementPackId = M.ManagementPackId
where m.IsUnitMonitor = 1
   -- Scoped to specific Monitor (remove the "–" below): 
   -- AND m.MonitorName like (‘%HealthService%’) 
   -- Scoped to specific Computer (remove the "–" below): sql
   -- AND bme.Path like (‘%sql%’) 
   -- Scoped to within last 7 days 
AND sce.TimeGenerated > dateadd(dd,-3,getutcdate()) 
group by s.BasemanagedEntityId,bme.DisplayName,bme.Path,m.DisplayName,m.Name,mt.typename, MP.MPName
order by NumStateChanges desc
