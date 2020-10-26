SELECT WorkItemRowId,
WorkItemName,
WorkItemStateId,
ServerName,
InstanceName,
StartedDateTimeUtc,
LastActivityDateTimeUtc,
CompletedDateTimeUtc,
DurationSeconds
FROM CS.workitem
ORDER BY WorkItemRowId DESC