--Most common events by event number and raw event description (this will take a very long time to run but it shows us not only event ID – but a description of the event to help understand which MP is the generating the noise)
SELECT top 100 EventDisplayNumber, Rawdescription, COUNT(*) AS TotalEvents 
FROM Event.vEvent evt 
inner join Event.vEventDetail evtd on evt.eventoriginid = evtd.eventoriginid 
GROUP BY EventDisplayNumber, Rawdescription 
ORDER BY TotalEvents DESC
