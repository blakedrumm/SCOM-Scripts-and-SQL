SELECT MonitorName,
	mp.MPFriendlyName
	MonitorEnabled,
	CAST(ConfigurationXML AS xml), 
	MonitorCategory, 
	MonitorPriority,
	m.LastModified,
	m.TimeAdded
FROM Monitor m
INNER JOIN ManagementPack mp
ON m.ManagementPackId = mp.ManagementPackId
WHERE m.LastModified > DATEADD(day, -4, GETUTCDATE())
ORDER BY m.LastModified DESC