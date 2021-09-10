Select WorkItemName, b.WorkItemStateName, ServerName, StartedDateTimeUtc, CompletedDateTimeUtc, DurationSeconds, ERRORMESSAGE 
from cs.WorkItem a WITH (NOLOCK), cs.WorkItemState b WITH (NOLOCK)
where a.WorkItemStateId= b.WorkItemStateId 
and WorkItemName like '%Snapshot%'
ORDER by StartedDateTimeUtc DESC