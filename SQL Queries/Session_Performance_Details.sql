-- Set the transaction isolation level to READ UNCOMMITTED
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

-- Common Table Expression to calculate the maximum execution count for each plan handle
WITH ExecutionCounts AS (
    SELECT plan_handle, MAX(usecounts) AS execution_count
    FROM sys.dm_exec_cached_plans
    GROUP BY plan_handle
)

-- Retrieve session and performance details
SELECT
    er.session_id AS SPID, -- Session ID
    CASE WHEN EXISTS (
        SELECT 1
        FROM master.dbo.sysprocesses sp
        WHERE sp.blocked = er.session_id
    ) THEN -1 ELSE er.blocking_session_id END AS BlkBy, -- Blocking Session ID (if exists), otherwise Blocking Session ID
    er.total_elapsed_time AS ElapsedMS, -- Total elapsed time
    er.cpu_time AS CPU, -- CPU time
    er.logical_reads + er.reads AS IOReads, -- I/O reads
    er.writes AS IOWrites, -- I/O writes
    ec.execution_count AS Executions, -- Execution count
    er.command AS CommandType, -- Command type
    er.last_wait_type AS LastWaitType, -- Last wait type
    OBJECT_SCHEMA_NAME(qt.objectid, dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid) AS ObjectName, -- Object name
    er.wait_resource AS waitresource, -- Wait resource
    SUBSTRING(qt.text, (er.statement_start_offset + 2) / 2, 
        (CASE WHEN er.statement_end_offset = -1
            THEN LEN(CONVERT(nvarchar(MAX), qt.text)) * 2
            ELSE (er.statement_end_offset - er.statement_start_offset + 2) / 2
        END)) AS SQLStatement, -- SQL statement
    ses.STATUS AS [STATUS], -- Session status
    ses.login_name AS [Login], -- Login name
    ses.host_name AS Host, -- Host name
    DB_Name(er.database_id) AS DBName, -- Database name
    er.start_time AS StartTime, -- Start time
    con.net_transport AS Protocol, -- Network protocol
    CASE ses.transaction_isolation_level
        WHEN 0 THEN 'Unspecified'
        WHEN 1 THEN 'Read Uncommitted'
        WHEN 2 THEN 'Read Committed'
        WHEN 3 THEN 'Repeatable'
        WHEN 4 THEN 'Serializable'
        WHEN 5 THEN 'Snapshot'
    END AS transaction_isolation, -- Transaction isolation level
    con.num_writes AS ConnectionWrites, -- Connection writes
    con.num_reads AS ConnectionReads, -- Connection reads
    con.client_net_address AS ClientAddress, -- Client address
    con.auth_scheme AS Authentication, -- Authentication scheme
    GETDATE() AS DatetimeSnapshot -- Current datetime
FROM sys.dm_exec_requests er
LEFT JOIN sys.dm_exec_sessions ses ON ses.session_id = er.session_id
LEFT JOIN sys.dm_exec_connections con ON con.session_id = ses.session_id
OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) AS qt
OUTER APPLY (
    SELECT MAX(execution_count) AS execution_count
    FROM ExecutionCounts
    WHERE plan_handle = er.plan_handle
) ec
WHERE er.session_id <> @@SPID -- Exclude the current session
AND ses.status = 'running' -- Show only running status
ORDER BY
    er.blocking_session_id DESC, -- Sort by blocking session ID (descending)
    IOReads DESC, -- Sort by I/O reads (descending)
    er.session_id; -- Sort by session ID
