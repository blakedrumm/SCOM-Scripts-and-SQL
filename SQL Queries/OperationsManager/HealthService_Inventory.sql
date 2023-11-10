SELECT 
    TargetBME.DisplayName AS PrimaryManagementServer,
    OS.DisplayName AS OSVersion,
	OS.OSVersion_53D6DEB6_BE2E_D1B6_D49E_A623518BD867 AS OSBuildNumber,
    HS.*
FROM 
    MTV_HealthService HS WITH (NOLOCK)
LEFT JOIN 
    Relationship R WITH (NOLOCK) ON R.SourceEntityId = HS.BaseManagedEntityId
LEFT JOIN 
    BaseManagedEntity TargetBME WITH (NOLOCK) ON R.TargetEntityId = TargetBME.BaseManagedEntityId
LEFT JOIN 
    MTV_Microsoft$Windows$OperatingSystem OS WITH (NOLOCK) ON HS.DisplayName = OS.PrincipalName -- Join with the OS version table
WHERE 
    R.IsDeleted = 0 
    AND R.RelationshipTypeId = dbo.fn_ManagedTypeId_MicrosoftSystemCenterHealthServiceCommunication()
ORDER BY 
    [DisplayName], [PrimaryManagementServer];
