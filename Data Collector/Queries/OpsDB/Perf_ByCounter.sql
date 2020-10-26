select top 20 pcv.ObjectName, pcv.CounterName, count (pcv.countername) as Total 
from performancedataallview as pdv, performancecounterview as pcv 
where (pdv.performancesourceinternalid = pcv.performancesourceinternalid) 
group by pcv.objectname, pcv.countername 
order by count (pcv.countername) desc