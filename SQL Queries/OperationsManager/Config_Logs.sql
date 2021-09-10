SELECT WorkItemRowId,
WorkItemName,
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(WorkItemStateId,20,'Successful'),15,'Timed out'),12,'Abandoned'),10,'Failed'),1,'Running') as 'WorkItemState',
ServerName,
InstanceName,
StartedDateTimeUtc,
LastActivityDateTimeUtc,
CompletedDateTimeUtc,
DurationSeconds
FROM CS.workitem WITH (NOLOCK)
ORDER BY WorkItemRowId DESC