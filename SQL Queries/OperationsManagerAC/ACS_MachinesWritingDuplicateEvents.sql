--To spot machines that write duplicate events (such as cluster nodes with eventlog replication enabled)
select Count(Id),EventMachine,AgentMachine
from AdtServer.dvHeader
group by EventMachine,AgentMachine
order by EventMachine
