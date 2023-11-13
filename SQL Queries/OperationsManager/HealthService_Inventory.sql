SELECT 
    Q2.IsAvailable,
    Q2.State AS 'HealthState',
    Q2.ServerName,
    Q1.PrimaryManagementServer,
    Q1.OSVersion,
    Q1.OSBuildNumber,
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
            State.displayname as [State] 
        FROM 
            ManagedEntityGenericView v1
        INNER JOIN 
            ManagedTypeView mv ON v1.MonitoringClassId = mv.Id
        LEFT JOIN 
            DisplayStringView State ON ('OperationalDataTypes.StateType.HealthState.' + CAST(v1.HealthState AS NVARCHAR)) = State.ElementName
        WHERE 
            mv.Name = 'microsoft.systemCenter.agent' 
            AND State.LanguageCode = 'ENU'
    ) AS Q2
ON 
    Q1.DisplayName = Q2.ServerName
ORDER BY 
    Q1.DisplayName, Q1.PrimaryManagementServer;
