Declare @total float
Select @total = count(EventId) from AdtServer.dvHeader
Select count(EventId),EventId, cast(convert(float,(count(EventId)) / (convert(float,@total)) * 100) as decimal(10,2))
From AdtServer.dvHeader
Group by EventId Order by count(EventId) desc
