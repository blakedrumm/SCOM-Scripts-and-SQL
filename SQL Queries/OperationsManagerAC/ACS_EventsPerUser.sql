--event count by User (with Percentages)
declare @total float
select @total = count(HeaderUser) from AdtServer.dvHeader
select count(HeaderUser),HeaderUser, cast(convert(float,(count(HeaderUser)) / (convert(float,@total)) * 100) as decimal(10,2))
from AdtServer.dvHeader
group by HeaderUser
order by count(HeaderUser) desc
