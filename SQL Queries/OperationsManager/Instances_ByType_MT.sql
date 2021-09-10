SELECT st.name AS 'MT_TableName', sdbs.row_count AS 'RowCount' 
FROM sys.tables st WITH (NOLOCK)
JOIN sys.dm_db_partition_stats sdbs WITH (NOLOCK) ON st.object_id = sdbs.object_id
JOIN ManagedType mt WITH (NOLOCK) on mt.ManagedTypeTableName = st.name
WHERE sdbs.index_id < 2
ORDER BY sdbs.row_count DESC