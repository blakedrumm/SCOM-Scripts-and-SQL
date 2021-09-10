SELECT
FullName as [Object in Maintenance],
TimeAdded as [Time Added],
StartTime as [Start Time],
ScheduledEndTime as [Scheduled End Time],
dbo.MaintenanceMode.[User] as [User],
Case ReasonCode
When 0 then 'Other (Planned)'
When 1 then 'Other (Unplanned)'
When 2 then 'Hardware: Maintenance (Planned)'
When 3 then 'Hardware: Maintenance (Unplanned)'
When 4 then 'Hardware: Installation (Planned)'
When 5 then 'Hardware: Installation (Unplanned)'
When 6 then 'Operating System: Reconfiguration (Planned)'
When 7 then 'Operating System: Reconfiguration (Unplanned)'
When 8 then 'Application: Maintenance (Planned)'
When 9 then 'Application: Maintenance (Unplanned)'
When 10 then 'Application: Installation (Planned)'
When 11 then 'Application: Unresponsive'
When 12 then 'Application: Unstable'
When 13 then 'Security issue'
When 14 then 'Loss of network connectivity (Unplanned)'
End as [Reason for Maintenance],
Comments
FROM BaseManagedEntity WITH (NOLOCK) INNER JOIN
MaintenanceMode WITH (NOLOCK) ON BaseManagedEntity.BaseManagedEntityId = MaintenanceMode.BaseManagedEntityId
WHERE IsInMaintenanceMode = 1