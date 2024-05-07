-- Selects the top 100 records from the result set
SELECT TOP 100
    evt.EventDisplayNumber,            -- Display number of the event
    evtd.RawDescription,               -- Raw description of the event
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
    evtd.RawDescription,               -- raw event description,
    evtlc.ComputerName                 -- and computer name
ORDER BY 
    TotalEvents DESC                   -- Orders the results by the total number of events, in descending order
