select ManagedEntityTypeSystemName, DiscoverySystemName, count(*) As 'Changes'
from
(select distinct
MP.ManagementPackSystemName,
MET.ManagedEntityTypeSystemName,
PropertySystemName,
D.DiscoverySystemName, D.DiscoveryDefaultName,
MET1.ManagedEntityTypeSystemName As 'TargetTypeSystemName', MET1.ManagedEntityTypeDefaultName 'TargetTypeDefaultName',
ME.Path, ME.Name,
C.OldValue, C.NewValue, C.ChangeDateTime
from dbo.vManagedEntityPropertyChange C
inner join dbo.vManagedEntity ME on ME.ManagedEntityRowId=C.ManagedEntityRowId
inner join dbo.vManagedEntityTypeProperty METP on METP.PropertyGuid=C.PropertyGuid
inner join dbo.vManagedEntityType MET on MET.ManagedEntityTypeRowId=ME.ManagedEntityTypeRowId
inner join dbo.vManagementPack MP on MP.ManagementPackRowId=MET.ManagementPackRowId
inner join dbo.vManagementPackVersion MPV on MPV.ManagementPackRowId=MP.ManagementPackRowId
left join dbo.vDiscoveryManagementPackVersion DMP on DMP.ManagementPackVersionRowId=MPV.ManagementPackVersionRowId
    AND CAST(DefinitionXml.query('data(/Discovery/DiscoveryTypes/DiscoveryClass/@TypeID)') AS nvarchar(max)) like '%'+MET.ManagedEntityTypeSystemName+'%'
left join dbo.vManagedEntityType MET1 on MET1.ManagedEntityTypeRowId=DMP.TargetManagedEntityTypeRowId
left join dbo.vDiscovery D on D.DiscoveryRowId=DMP.DiscoveryRowId
where ChangeDateTime > dateadd(hh,-24,getutcdate())
) As #T
group by ManagedEntityTypeSystemName, DiscoverySystemName
order by count(*) DESC