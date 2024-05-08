----------------------------------------------------------------------------------------------------------------
-- Name: DW_Events_ByTotalEvents.sql
--
-- Description: 
-- This SQL script retrieves the top 100 most common events from the event logging system, providing 
-- insights into the events that occur most frequently. The query returns the event display number, raw description 
-- of the event, the computer name where the event was logged, and the total number of occurrences of each event. 
-- Additionally, it calculates the span of days over which each event has been logged, helping identify long-running 
-- or persistent issues. This query is designed to assist in identifying patterns or anomalies in event logs, particularly 
-- useful in large-scale environments where understanding event noise and distribution can aid in proactive management and troubleshooting.
--
-- Author: Blake Drumm (blakedrumm@microsoft.com)
-- Date Created: May 7th, 2024
-- Date Modified: May 8th, 2024
-- Original query: https://kevinholman.com/2016/11/11/scom-sql-queries/#:~:text=Events%20Section%20(Warehouse)
----------------------------------------------------------------------------------------------------------------
-- Selects the top 100 records from the result set
SELECT TOP 100
    evt.EventDisplayNumber,            -- Display number of the event
    evtd.RenderedDescription,               -- Raw description of the event
    evtlc.ComputerName,                -- Name of the computer logging the event
    COUNT(*) AS TotalEvents,           -- Total number of events aggregated by display number, description, and computer name
    DATEDIFF(DAY, MIN(evt.DateTime), MAX(evt.DateTime)) + 1 AS DaysOfData  -- Calculates the span of days between the earliest and latest event dates for each group
FROM 
    Event.vEvent AS evt                -- From the main events table
INNER JOIN 
    Event.vEventDetail AS evtd         -- Joined with event details on EventOriginId
    ON evt.EventOriginId = evtd.EventOriginId
INNER JOIN 
    vEventLoggingComputer AS evtlc     -- Joined with the event logging computer table on LoggingComputerRowId
    ON evt.LoggingComputerRowId = evtlc.EventLoggingComputerRowId
GROUP BY 
    evt.EventDisplayNumber,            -- Groups the results by event display number,
    evtd.RenderedDescription,               -- raw event description,
    evtlc.ComputerName                 -- and computer name
ORDER BY 
    TotalEvents DESC                   -- Orders the results by the total number of events, in descending order
