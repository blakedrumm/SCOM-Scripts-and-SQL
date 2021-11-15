-- Change the Where line to the correct date range
Select CollectionTime, EventId, String06 from Adtserver.dvAll
Where CollectionTime > '2021-11-11 00:01:00:000' and CollectionTime <2021-11-11 23:59:00:000'
Order by CollectionTime DESC
