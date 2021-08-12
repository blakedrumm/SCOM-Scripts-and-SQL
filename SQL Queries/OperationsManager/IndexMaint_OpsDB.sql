SELECT dtioh.OptimizationDurationSeconds AS 'DurationSeconds',
dt.TableName,
'Reindex' AS 'OperationType',
dtioh.OptimizationStartDateTime AS 'StartTime'
FROM DomainTableIndexOptimizationHistory dtioh
JOIN DomainTable dt ON dt.DomainTableRowId = dtioh.DomainTableIndexRowId
WHERE dtioh.OptimizationDurationSeconds > 0
UNION ALL
SELECT dtsuh.UpdateDurationSeconds AS 'DurationSeconds',
dt.TableName,
'Statistics' AS 'OperationType',
dtsuh.UpdateStartDateTime AS 'StartTime'
FROM DomainTableStatisticsUpdateHistory dtsuh
JOIN DomainTable dt ON dt.DomainTableRowId = dtsuh.DomainTableRowId
WHERE dtsuh.UpdateDurationSeconds > 0
ORDER BY DurationSeconds DESC, StartTime DESC