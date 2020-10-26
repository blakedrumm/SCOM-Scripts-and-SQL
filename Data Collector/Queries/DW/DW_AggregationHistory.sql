SELECT ds.DatasetDefaultName,
  sdah.AggregationDateTime,
  sdah.AggregationTypeId,
  sdah.FirstAggregationStartDateTime,
  sdah.FirstAggregationDurationSeconds,
  sdah.LastAggregationStartDateTime,
  sdah.LastAggregationDurationSeconds,
  sdah.DirtyInd,
  sdah.DataLastReceivedDateTime,
  sdah.AggregationCount
FROM StandardDatasetAggregationHistory sdah
JOIN Dataset ds ON sdah.DatasetId = ds.DatasetId
ORDER BY StandardDatasetAggregationHistoryRowId DESC