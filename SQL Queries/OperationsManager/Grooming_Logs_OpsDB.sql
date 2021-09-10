select InternalJobHistoryId,
Command,
REPLACE(REPLACE(StatusCode,0,'Failed'),1,'Successful') as 'Status',
TimeStarted,
TimeFinished
from InternalJobHistory WITH (NOLOCK)
order by InternalJobHistoryId DESC