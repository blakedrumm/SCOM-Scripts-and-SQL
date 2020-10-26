select rv.DisplayName as WorkFlowName, OverrideName, op.OverrideableParameterName, mo.Value as OverrideValue,
mt.TypeName as OverrideScope, bme.DisplayName as InstanceName, bme.Path as InstancePath,
mpv.DisplayName as ORMPName, mo.LastModified as LastModified, 'Rule' AS 'WorkflowType'
from ModuleOverride mo
inner join ManagementPackView mpv on mpv.Id = mo.ManagementPackId
inner join RuleView rv on rv.Id = mo.ParentId
inner join ManagedType mt on mt.ManagedTypeId = mo.TypeContext
left join BaseManagedEntity bme on bme.BaseManagedEntityId = mo.InstanceContext
left join OverrideableParameter op on mo.OverrideableParameterId = op.OverrideableParameterId
Where mpv.Sealed = 0
UNION ALL
select mv.DisplayName as WorkFlowName, OverrideName, op.OverrideableParameterName, mto.Value as OverrideValue,
mt.TypeName as OverrideScope, bme.DisplayName as InstanceName, bme.Path as InstancePath,
mpv.DisplayName as ORMPName, mto.LastModified as LastModified, 'Monitor' AS 'WorkflowType'
from MonitorOverride mto
inner join Managementpackview mpv on mpv.Id = mto.ManagementPackId
inner join MonitorView mv on mv.Id = mto.MonitorId
inner join ManagedType mt on mt.ManagedTypeId = mto.TypeContext
left join BaseManagedEntity bme on bme.BaseManagedEntityId = mto.InstanceContext
left join OverrideableParameter op on mto.OverrideableParameterId = op.OverrideableParameterId
Where mpv.Sealed = 0
UNION ALL
select dv.DisplayName as WorkFlowName, OverrideName, op.OverrideableParameterName, mo.Value as OverrideValue,
mt.TypeName as OverrideScope, bme.DisplayName as InstanceName, bme.Path as InstancePath,
mpv.DisplayName as ORMPName, mo.LastModified as LastModified, 'Discovery' AS 'WorkflowType'
from ModuleOverride mo
inner join ManagementPackView mpv on mpv.Id = mo.ManagementPackId
inner join DiscoveryView dv on dv.Id = mo.ParentId
inner join ManagedType mt on mt.ManagedTypeId = mo.TypeContext
left join BaseManagedEntity bme on bme.BaseManagedEntityId = mo.InstanceContext
left join OverrideableParameter op on mo.OverrideableParameterId = op.OverrideableParameterId
Where mpv.Sealed = 0
Order By mpv.DisplayName