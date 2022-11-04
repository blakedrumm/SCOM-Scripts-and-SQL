-- Get only changes made in the last 7 days to the AvailabilityHistory Table 
select BME.Path,
Case AV.ReasonCode
When 0 then 'Unknown'
When 1 then 'Unavailable - No heartbeat'
When 17 then 'Connector Service Paused'
When 25 then 'Action Account Issue'
When 41 then 'Config Data Handling Issue'
When 42 then 'Config Data Loading Issue'
When 43 then 'System Workflows Unloaded'
When 49 then 'Entity State Collection Stalled'
When 50 then 'Monitor State Collection Stalled'
When 51 then 'Alert Collection Stalled'
When 97 then 'Solution Event Source Not Open'
When 98 then 'Cannot Parse Config'
End as [Reason for Change],
AV.TimeStarted,
AV.TimeFinished from AvailabilityHistory AV WITH (NOLOCK)
join BaseManagedEntity BME WITH (NOLOCK) on AV.BaseManagedEntityId=BME.BaseManagedEntityId
WHERE AV.TimeStarted > DATEADD(day, -7, GETUTCDATE())
order by AV.TimeStarted desc