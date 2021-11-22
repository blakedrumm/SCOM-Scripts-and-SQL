-- Change the Where line to the correct date range
--Select CollectionTime, EventId, String06 from Adtserver.dvAll
--Where CollectionTime > '2021-11-11 00:01:00:000' and CollectionTime <2021-11-11 23:59:00:000'
--Order by CollectionTime DESC
--
-- Get a count for the last 14 days for the total Event Gathered Per Day
select convert(varchar(10), collectiontime,10),  count(*)
from AdtServer.dvall (nolock)
where CollectionTime > dateadd(day, -14, getutcdate())
group by convert(varchar(10), collectiontime,10)
order by convert(varchar(10), collectiontime,10) desc
