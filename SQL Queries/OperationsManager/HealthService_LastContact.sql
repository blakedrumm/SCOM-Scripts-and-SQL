-- This script queries the database for any agents missing a heartbeat, and letting us know their last contact date/time
-- Original Script found here: https://docs.microsoft.com/en-us/archive/blogs/mariussutara/last-contacted-better-sql-query

declare @substract float
declare @numberOfMissing float
declare @interval float

-- Get the number of missing heartbeats
select @numberOfMissing = SettingValue from GlobalSettings GS
join ManagedTypeProperty MTP with(nolock) on GS.ManagedTypePropertyId = MTP.ManagedTypePropertyId
where MTP.ManagedTypePropertyName = 'NumberOfMissingHeartBeatsToMarkMachineDown'

-- Get the heartbeat interval
select @interval = SettingValue from GlobalSettings GS
join ManagedTypeProperty MTP with(nolock) on GS.ManagedTypePropertyId = MTP.ManagedTypePropertyId
where MTP.ManagedTypePropertyName = 'HeartbeatInterval'

-- Calculate the amount of lapsed time before a system is marked as non contactable
select @substract = (@numberOfMissing * @interval)/100000
select B.DisplayName, AH.TimeStarted, (cast((cast(tmp.MaxTimeStarted as float)- @substract) as datetime)) as [ApproxLastContactedTime (UTC)],
dateadd ( hh, +9, (cast((cast(tmp.MaxTimeStarted as float)- @substract) as datetime))) as 'ApproxLastContactedTime (Pacific)' from Availability A
join BaseManagedEntity B with(nolock) on B.BaseManagedEntityId = A.BaseManagedEntityId
join AvailabilityHistory AH with(nolock) on AH.BaseManagedEntityId = A.BaseManagedEntityId
join
(
	select MAX(AHTMP.TimeStarted) AS MaxTimeStarted, BME.BaseManagedEntityId from AvailabilityHistory AHTMP
	join BaseManagedEntity BME with(nolock) on BME.BaseManagedEntityId = AHTMP.BaseManagedEntityId
	where BME.IsDeleted = 0
	group by BME.BaseManagedEntityId
)
TMP on AH.TimeStarted = MaxTimeStarted
where A.IsAvailable = 0 and B.IsDeleted = 0