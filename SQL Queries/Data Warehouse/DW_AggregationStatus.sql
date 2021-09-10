WITH AggregationInfo_DurationIsNotNull AS
  (SELECT AggregationType = CASE
                                WHEN AggregationTypeId = 0 THEN 'Raw'
                                WHEN AggregationTypeId = 20 THEN 'Hourly'
                                WHEN AggregationTypeId = 30 THEN 'Daily'
                                ELSE NULL
                            END,
                            AggregationTypeId,
                            MIN(AggregationDateTime) AS 'TimeUTC_NextToAggregate',
                            SUM(CAST (DirtyInd AS Int)) AS 'Count_OutstandingAggregations',
                            DatasetId
   FROM StandardDatasetAggregationHistory WITH(NOLOCK)
   WHERE LastAggregationDurationSeconds IS NOT NULL
   GROUP BY DatasetId,
            AggregationTypeId),
     AggregationInfo_DurationIsNull AS
  (SELECT AggregationType = CASE
                                WHEN AggregationTypeId = 0 THEN 'Raw'
                                WHEN AggregationTypeId = 20 THEN 'Hourly'
                                WHEN AggregationTypeId = 30 THEN 'Daily'
                                ELSE NULL
                            END ,
                            AggregationTypeId ,
                            MIN(AggregationDateTime) AS 'TimeUTC_NextToAggregate' ,
                            COUNT(AggregationDateTime) AS 'Count_Aggregations' ,
                            DatasetId
   FROM StandardDatasetAggregationHistory WITH(NOLOCK)
   WHERE LastAggregationDurationSeconds IS NULL
   GROUP BY DatasetId,
            AggregationTypeId)
SELECT SDS.SchemaName,
       AINN.AggregationType,
       AINN.TimeUTC_NextToAggregate,
       Count_OutstandingAggregations,
       Count_Aggregations,
       SDA.MaxDataAgeDays,
       SDA.LastGroomingDateTime,
       SDS.DebugLevel,
       AINN.DataSetId
FROM StandardDataSet AS SDS WITH(NOLOCK)
JOIN AggregationInfo_DurationIsNotNull AS AINN WITH(NOLOCK) ON SDS.DatasetId = AINN.DatasetId
INNER JOIN AggregationInfo_DurationIsNull AS AIIN WITH(NOLOCK) ON SDS.DatasetId = AIIN.DatasetId
JOIN dbo.StandardDatasetAggregation AS SDA WITH(NOLOCK) ON SDA.DatasetId = SDS.DatasetId
AND SDA.AggregationTypeID = AINN.AggregationTypeID
ORDER BY SchemaName DESC,
         AggregationType ASC,
         LastGroomingDateTime DESC