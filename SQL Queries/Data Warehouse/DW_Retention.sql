SELECT ds.datasetDefaultName AS 'Dataset Name',
 sda.AggregationTypeId AS 'Agg Type 0=raw, 20=Hourly, 30=Daily',
 sda.MaxDataAgeDays AS 'Retention Time in Days',
 sda.LastGroomingDateTime,
 sda.GroomingIntervalMinutes
FROM dataset ds, StandardDatasetAggregation sda 
WHERE ds.datasetid = sda.datasetid
ORDER by ds.datasetDefaultName