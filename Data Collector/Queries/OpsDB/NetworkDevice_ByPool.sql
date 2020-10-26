select BME.DisplayName as 'ResourcePool' ,Count(R.RelationshipId) as 'DeviceCount' from BaseManagedEntity BME WITH(NOLOCK)
join ManagedType MT WITH(NOLOCK) on BME.BaseManagedTypeId = MT.ManagedTypeId
join Relationship R WITH(NOLOCK) on BME.BaseManagedEntityId = R.SourceEntityId
join BaseManagedEntity BME2 WITH(NOLOCK) on R.TargetEntityId = BME2.BaseManagedEntityId
where MT.BaseManagedTypeId IN (SELECT ManagedTypeId FROM ManagedType WHERE TypeName LIKE '%pool')
and BME2.BaseManagedTypeId = (SELECT ManagedTypeId FROM ManagedType WHERE TypeName = 'System.NetworkManagement.Node')
and R.RelationshipTypeId =  (SELECT RelationshipTypeId FROM RelationshipType WHERE RelationshipTypeName = 'Microsoft.SystemCenter.ManagementActionPointManagesEntity')
group by BME.DisplayName