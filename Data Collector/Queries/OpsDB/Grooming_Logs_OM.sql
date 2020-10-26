select InternalJobHistoryId,
Command,
StatusCode,
TimeStarted,
TimeFinished
from InternalJobHistory
order by InternalJobHistoryId DESC