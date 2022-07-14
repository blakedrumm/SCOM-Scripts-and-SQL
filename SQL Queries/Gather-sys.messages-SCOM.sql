-- Original Author: Benign Sage
-- Original Location: https://github.com/benignsage/sqlserver-sys.messages-scom/blob/master/script1.sql
-- Original Post: https://www.sqlalliance.com/viewtopic.php?f=8&t=3
SELECT
m.message_id,
m.language_id,
l.name,
m.severity,
m.is_event_logged,
m.text,
'EXEC sp_addmessage @msgnum = ' + CONVERT(VARCHAR, m.message_id) + ', @msgtext = N''' + REPLACE(m.text, '''', '''''')
+ ''', @severity = ' + CONVERT(VARCHAR, m.severity) + ', @lang = ''' + l.name + ''', @with_log = ' +
(
	SELECT
	CASE is_event_logged
		WHEN 1 THEN
			'True'
		ELSE
			'False'
	END
	FROM
	sys.syslanguages
	WHERE
	lcid = m.language_id
) + ', @replace = ''REPLACE''' AS SQLCommand
FROM
sys.messages AS m
INNER JOIN sys.syslanguages AS l
ON m.language_id = l.lcid
WHERE
message_id >= 777000000
