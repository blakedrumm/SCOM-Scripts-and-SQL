select InternalJobHistoryId,
Command,
REPLACE(REPLACE(StatusCode,0,'Failed'),1,'Successful') as 'Status',
TimeStarted,
TimeFinished,
CONCAT(DATEDIFF (second,TimeStarted,TimeFinished),' seconds') AS 'DurationSeconds'
from InternalJobHistory WITH (NOLOCK)
order by InternalJobHistoryId DESC
