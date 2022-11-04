SELECT ds.DatasetDefaultName,
       sdah.AggregationDateTime,
       atype.AggregationTypeDefaultName,
       sdah.AggregationCount,
       sdah.DirtyInd,
       sdah.FirstAggregationStartDateTime,
       sdah.FirstAggregationDurationSeconds,
       sdah.LastAggregationStartDateTime,
       sdah.LastAggregationDurationSeconds,
       sdah.DataLastReceivedDateTime
FROM StandardDatasetAggregationHistory sdah WITH(NOLOCK)
JOIN Dataset ds WITH (NOLOCK) ON sdah.DatasetId = ds.DatasetId
JOIN AggregationType atype WITH (NOLOCK) ON sdah.AggregationTypeId = atype.AggregationTypeId
ORDER BY sdah.FirstAggregationDurationSeconds DESC