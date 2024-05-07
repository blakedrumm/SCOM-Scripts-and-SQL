--Most common events by event number and raw event description and computer name (this will take a very long time to run but it shows us not only event ID – but a description of the event to help understand which MP is the generating the noise)
SELECT top 100 evt.EventDisplayNumber, evtd.RawDescription, evtlc.ComputerName, COUNT(*) AS TotalEvents
FROM Event.vEvent evt 
inner join Event.vEventDetail evtd on evt.eventoriginid = evtd.eventoriginid 
inner join vEventLoggingComputer evtlc on evt.LoggingComputerRowId = evtlc.EventLoggingComputerRowId
GROUP BY evt.EventDisplayNumber, evtd.RawDescription, evtlc.ComputerName
ORDER BY TotalEvents DESC
