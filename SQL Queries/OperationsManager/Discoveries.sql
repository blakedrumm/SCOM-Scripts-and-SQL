SELECT 
d.DiscoveryId,
d.DiscoveryName, 
mpv.FriendlyName as 'MPDisplayName',
d.DiscoveryAccessibility,
REPLACE(REPLACE(REPLACE(d.DiscoveryEnabled, '4', 'True'),'0', 'False'), '3', 'onEssentialMonitoring') as 'DiscoveryEnabled', 
CASE WHEN bme.DisplayName IS NULL then mt.TypeName else bme.DisplayName END as 'DiscoveryTarget',
REPLACE(REPLACE(d.DiscoveryConfirmDelivery, 0, 'False'), '1', 'True') as 'DiscoveryConfirmDelivery',
REPLACE(REPLACE(d.DiscoveryRemotable, 0, 'False'),'1', 'True') as 'DiscoveryRemotable',
d.TimeAdded
FROM Discovery AS d WITH (NOLOCK) LEFT JOIN
ManagementPackView AS mpv ON d.ManagementPackId = mpv.Id LEFT JOIN
BaseManagedEntity AS bme WITH (NOLOCK) ON d.DiscoveryTarget = bme.BaseManagedEntityId LEFT JOIN
ManagedType AS mt WITH (NOLOCK) ON d.DiscoveryTarget = mt.ManagedTypeId