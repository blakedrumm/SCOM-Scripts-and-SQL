-- Get current context DB Owner
select DB_NAME(DB_ID()), suser_sname(owner_sid) AS 'Owner'
from sys.databases sdb
WHERE database_id = DB_ID()