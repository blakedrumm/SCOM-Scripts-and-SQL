Select WorkItemName, b.WorkItemStateName, ServerName, StartedDateTimeUtc, CompletedDateTimeUtc, DurationSeconds, ERRORMESSAGE 
from cs.WorkItem a , cs.WorkItemState b 
where a.WorkItemStateId= b.WorkItemStateId 
and WorkItemName like '%Snapshot%'
ORDER by StartedDateTimeUtc DESC