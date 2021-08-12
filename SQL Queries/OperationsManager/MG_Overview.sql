SELECT MG_Name, MOMAdminGroup, REPLACE(REPLACE(EnableErrorReports,1,'True'),0,'False') AS EnableErrorReports, LanguageCode, MS_Count, GW_Count, Agent_Count, Agent_Pending, Unix_Count, NetworkDevice_Count
FROM (SELECT ManagementGroupName AS 'MG_Name' FROM __MOMManagementGroupInfo__) AS MG_Name, 
(SELECT MOMAdminGroup FROM __MOMManagementGroupInfo__) AS MOMAdminGroup,
(SELECT LanguageCode FROM __MOMManagementGroupInfo__) AS LanguageCode,
(SELECT EnableErrorReports FROM __MOMManagementGroupInfo__) AS EnableErrorReports,
(SELECT COUNT(*) AS 'MS_Count' FROM MTV_HealthService WHERE IsManagementServer = 1 AND IsGateway = 0) AS MS_Count,
(SELECT COUNT(*) AS 'GW_Count' FROM MTV_HealthService WHERE IsManagementServer = 1 AND IsGateway = 1) AS GW_Count,
(SELECT COUNT(*) AS 'Agent_Count' FROM MTV_HealthService WHERE IsManagementServer = 0 AND IsGateway = 0) AS Agent_Count,
(SELECT COUNT(*) AS 'Agent_Pending' FROM AgentPendingAction) AS Agent_Pending,
(SELECT COUNT(*) AS 'Unix_Count' FROM MTV_Microsoft$Unix$Computer) AS Unix_Count,
(SELECT Count(*) AS 'NetworkDevice_Count' FROM MTV_System$NetworkManagement$Node) AS NetworkDevice_Count