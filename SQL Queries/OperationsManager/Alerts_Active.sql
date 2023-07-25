SELECT 
    SUM(1) As AlertCount, 
    AV.AlertStringName, 
    AV.AlertStringDescription, 
    AV.Name, 
	AV.MonitoringRuleId, 
    MAX(AV.LastModified) AS LastModified
FROM 
    Alertview AS AV WITH (NOLOCK) 
WHERE 
    AV.TimeRaised is not NULL and AV.ResolutionState <> 255
GROUP BY 
    AV.AlertStringName, 
    AV.AlertStringDescription, 
    AV.MonitoringRuleId, 
    AV.Name
ORDER BY 
    AlertCount, LastModified DESC
