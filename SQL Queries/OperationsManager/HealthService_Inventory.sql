SELECT 
    Q2.IsAvailable,
    CASE Q2.HealthState
        WHEN 0 THEN 'Uninitialized'
        WHEN 1 THEN 'Healthy'
        WHEN 2 THEN 'Warning'
        WHEN 3 THEN 'Critical'
        WHEN 4 THEN 'Unmonitored'
        WHEN 255 THEN 'Not Applicable'
        ELSE 'Unknown State'
    END AS HealthStateDescription,
    Q2.ServerName,
    -- Select specific columns from HS. Replace '*' with actual column names if needed.
    Q1.*
FROM 
    (
        SELECT 
            TargetBME.DisplayName AS PrimaryManagementServer,
            OS.DisplayName AS OSVersion,
            OS.OSVersion_53D6DEB6_BE2E_D1B6_D49E_A623518BD867 AS OSBuildNumber,
            HS.* -- Replace with specific columns from HS if needed
        FROM 
            MTV_HealthService HS WITH (NOLOCK)
        LEFT JOIN 
            Relationship R WITH (NOLOCK) ON R.SourceEntityId = HS.BaseManagedEntityId
        LEFT JOIN 
            BaseManagedEntity TargetBME WITH (NOLOCK) ON R.TargetEntityId = TargetBME.BaseManagedEntityId
        LEFT JOIN 
            MTV_Microsoft$Windows$OperatingSystem OS WITH (NOLOCK) ON HS.DisplayName = OS.PrincipalName
        WHERE 
            R.IsDeleted = 0 
            AND R.RelationshipTypeId = dbo.fn_ManagedTypeId_MicrosoftSystemCenterHealthServiceCommunication()
    ) AS Q1
LEFT JOIN 
    (
        SELECT 
            v1.path as [ServerName],
            replace(replace(v1.isavailable,0,'False'),1,'True') as [IsAvailable],
			v1.HealthState
        FROM 
            ManagedEntityGenericView v1
        INNER JOIN 
            ManagedTypeView mv ON v1.MonitoringClassId = mv.Id
        WHERE 
            mv.Name = 'microsoft.systemCenter.agent' OR
			mv.Name = 'Microsoft.SystemCenter.GatewayManagementServer'
    ) AS Q2
ON 
    Q1.DisplayName = Q2.ServerName
ORDER BY 
    Q1.DisplayName, Q1.PrimaryManagementServer;
