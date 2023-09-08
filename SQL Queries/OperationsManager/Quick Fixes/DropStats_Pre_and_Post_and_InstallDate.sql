DECLARE @sql NVARCHAR(MAX) = '';

 

SELECT @sql += 'DROP STATISTICS ' + QUOTENAME(OBJECT_SCHEMA_NAME(s.object_id)) + '.' + QUOTENAME(OBJECT_NAME(s.object_id)) + '.' + QUOTENAME(s.name) + ';' + CHAR(13)
FROM sys.stats s
WHERE s.name LIKE 'PRE\_%' ESCAPE '\' OR s.name LIKE 'POST\_%' ESCAPE '\' OR s.name LIKE 'InstallDate\_%' ESCAPE '\';

 

EXEC sp_executesql @sql;
