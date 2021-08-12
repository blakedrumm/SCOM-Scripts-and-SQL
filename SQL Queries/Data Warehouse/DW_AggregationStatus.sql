WITH AggregationInfo AS (
    SELECT 
    AggregationType = CASE 
        WHEN AggregationTypeId = 0 THEN 'Raw'
        WHEN AggregationTypeId = 20 THEN 'Hourly'
        WHEN AggregationTypeId = 30 THEN 'Daily'
        ELSE NULL
    END
    ,AggregationTypeId
    ,MIN(AggregationDateTime) as 'TimeUTC_NextToAggregate'
    ,COUNT(AggregationDateTime) as 'Count_OutstandingAggregations'
    ,DatasetId
    FROM StandardDatasetAggregationHistory
    WHERE LastAggregationDurationSeconds IS NULL
    GROUP BY DatasetId, AggregationTypeId
)
SELECT
SDS.SchemaName
,AI.AggregationType
,AI.TimeUTC_NextToAggregate
,Count_OutstandingAggregations
,SDA.MaxDataAgeDays
,SDA.LastGroomingDateTime
,SDS.DebugLevel
,AI.DataSetId
FROM StandardDataSet AS SDS WITH(NOLOCK)
JOIN AggregationInfo AS AI WITH(NOLOCK) ON SDS.DatasetId = AI.DatasetId 
JOIN dbo.StandardDatasetAggregation AS SDA WITH(NOLOCK) ON SDA.DatasetId = SDS.DatasetId AND SDA.AggregationTypeID = AI.AggregationTypeID
ORDER BY SchemaName DESC