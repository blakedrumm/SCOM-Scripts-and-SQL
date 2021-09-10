SELECT MonitorName,
	mp.MPFriendlyName
	MonitorEnabled,
	CAST(ConfigurationXML AS xml) AS ConfigurationXML, 
	MonitorCategory, 
	MonitorPriority,
	m.LastModified,
	m.TimeAdded
FROM Monitor m WITH (NOLOCK)
INNER JOIN ManagementPack mp WITH (NOLOCK)
ON m.ManagementPackId = mp.ManagementPackId
WHERE m.LastModified > DATEADD(day, -4, GETUTCDATE())
ORDER BY m.LastModified DESC