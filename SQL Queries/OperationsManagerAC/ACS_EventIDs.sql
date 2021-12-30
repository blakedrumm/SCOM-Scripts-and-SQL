-- Get a count of the total ACS Events Collected / and how much percent the Event is taking up the ACS DB
Declare @total float
Select @total = count(EventId) from AdtServer.dvHeader
Select count(EventId) AS Count,EventId, cast(convert(float,(count(EventId)) / (convert(float,@total)) * 100) as decimal(10,2)) AS PercentOfTotalEvents
From AdtServer.dvHeader
Group by EventId Order by count(EventId) desc
