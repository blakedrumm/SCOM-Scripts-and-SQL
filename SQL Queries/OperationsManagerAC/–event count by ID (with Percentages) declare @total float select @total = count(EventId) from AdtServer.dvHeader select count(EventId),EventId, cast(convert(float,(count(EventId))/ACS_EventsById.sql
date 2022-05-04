--event count by ID (with Percentages)
declare @total float
select @total = count(EventId) from AdtServer.dvHeader
select count(EventId),EventId, cast(convert(float,(count(EventId)) / (convert(float,@total)) * 100) as decimal(10,2))
from AdtServer.dvHeader
group by EventId
order by count(EventId) desc
