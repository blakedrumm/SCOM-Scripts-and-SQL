--Event count by machine and by date (distinuishes between AgentMachine and EventMachine
select convert(varchar(10),CreationTime,102),Count(Id),EventMachine,AgentMachine
from AdtServer.dvHeader
group by convert(varchar(10),CreationTime,102),EventMachine,AgentMachine
order by convert(varchar(10),CreationTime,102) desc ,EventMachine
