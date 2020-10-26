select 
CONVERT(varchar(20),timegenerated,102) as Day, MonitorName, count(*) AS TotalStateChanges 
from statechangeevent with(nolock) 
inner join state with(nolock) on statechangeevent.stateid = state.stateid 
inner join basemanagedentity with(nolock) on state.basemanagedentityid = basemanagedentity.basemanagedentityid 
inner join managedtype with(nolock) on basemanagedentity.basemanagedtypeid = managedtype.managedtypeid 
inner join monitor with(nolock) 
on monitor.monitorid = state.monitorid and monitor.IsUnitMonitor = '1' 
group by CONVERT(varchar(20),timegenerated,102), monitorname 
order by CONVERT(varchar(20),timegenerated,102) DESC 