--All machines that have ever written event 538
select distinct EventMachine, count(EventId) as total
from AdtServer.dvHeader
where EventID = 538
group by EventMachine
