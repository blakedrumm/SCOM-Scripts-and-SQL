SELECT 'ManagedEntityStage' AS 'TableName',count(*) AS 'Count' FROM ManagedEntityStage WITH (NOLOCK)
UNION ALL
SELECT 'HealthServiceOutageStage' AS 'TableName',count(*) AS 'Count' FROM HealthServiceOutageStage WITH (NOLOCK)
UNION ALL
SELECT 'MaintenanceModeStage' AS 'TableName',count(*) AS 'Count' FROM MaintenanceModeStage WITH (NOLOCK)
UNION ALL
SELECT 'StateProcessedMaintenanceMode' AS 'TableName', count(*) AS 'Count' FROM StateProcessedMaintenanceMode WITH (NOLOCK)
UNION ALL
SELECT 'RelationshipStage' AS 'TableName',count(*) AS 'Count' FROM RelationshipStage WITH (NOLOCK)
UNION ALL
SELECT 'TypedManagedEntityStage' AS 'TableName',count(*) AS 'Count' FROM TypedManagedEntityStage WITH (NOLOCK)
UNION ALL
SELECT 'Alert.AlertStage' AS 'TableName',count(*) AS 'Count' FROM Alert.AlertStage WITH (NOLOCK)
UNION ALL
SELECT 'Alert.AlertStage2Process' AS 'TableName',count(*) AS 'Count' FROM Alert.AlertStage2Process WITH (NOLOCK)
UNION ALL
SELECT 'Event.EventStage' AS 'TableName',count(*) AS 'Count' FROM Event.EventStage WITH (NOLOCK)
UNION ALL
SELECT 'Perf.PerformanceStage' AS 'TableName',count(*) AS 'Count' FROM Perf.PerformanceStage WITH (NOLOCK)
UNION ALL
SELECT 'State.StateStage' AS 'TableName',count(*) AS 'Count' FROM State.StateStage WITH (NOLOCK)
