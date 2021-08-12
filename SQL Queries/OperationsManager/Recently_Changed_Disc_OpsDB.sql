-- Gather all Discoveries Modified in the last 180 days.
SELECT DiscoveryName,
    mp.MPFriendlyName,
    REPLACE(REPLACE(REPLACE(DiscoveryEnabled, '4', 'True'),'0', 'False'), '3', 'onEssentialMonitoring') as 'DiscoveryEnabled', 
    CASE WHEN bme.DisplayName IS NULL then mt.TypeName else bme.DisplayName END as 'DiscoveryTarget', 
    d.LastModified,
    d.TimeAdded
FROM Discovery d LEFT JOIN
BaseManagedEntity AS bme ON d.DiscoveryTarget = bme.BaseManagedEntityId INNER JOIN
ManagedType AS mt ON d.DiscoveryTarget = mt.ManagedTypeId INNER JOIN
ManagementPack mp 
ON d.ManagementPackId = mp.ManagementPackId
WHERE d.LastModified > DATEADD(day, -180, GETUTCDATE())
ORDER BY d.LastModified DESC