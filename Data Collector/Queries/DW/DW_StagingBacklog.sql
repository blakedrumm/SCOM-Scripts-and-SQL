SELECT 'ManagedEntityStage' AS 'TableName',count(*) AS 'Count' FROM ManagedEntityStage
UNION ALL
SELECT 'HealthServiceOutageStage' AS 'TableName',count(*) AS 'Count' FROM HealthServiceOutageStage
UNION ALL
SELECT 'MaintenanceModeStage' AS 'TableName',count(*) AS 'Count' FROM MaintenanceModeStage
UNION ALL
SELECT 'RelationshipStage' AS 'TableName',count(*) AS 'Count' FROM RelationshipStage
UNION ALL
SELECT 'TypedManagedEntityStage' AS 'TableName',count(*) AS 'Count' FROM TypedManagedEntityStage
UNION ALL
SELECT 'Alert.AlertStage' AS 'TableName',count(*) AS 'Count' FROM Alert.AlertStage
UNION ALL
SELECT 'Alert.AlertStage2Process' AS 'TableName',count(*) AS 'Count' FROM Alert.AlertStage2Process
UNION ALL
SELECT 'Event.EventStage' AS 'TableName',count(*) AS 'Count' FROM Event.EventStage
UNION ALL
SELECT 'Perf.PerformanceStage' AS 'TableName',count(*) AS 'Count' FROM Perf.PerformanceStage
UNION ALL
SELECT 'State.StateStage' AS 'TableName',count(*) AS 'Count' FROM State.StateStage