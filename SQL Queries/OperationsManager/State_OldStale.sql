declare @statedaystokeep INT
SELECT @statedaystokeep = DaysToKeep from PartitionAndGroomingSettings WHERE ObjectName = 'StateChangeEvent' 
SELECT COUNT(*) as 'Total StateChanges', 
count(CASE WHEN sce.TimeGenerated > dateadd(dd,-@statedaystokeep,getutcdate()) THEN sce.TimeGenerated ELSE NULL END) as 'within grooming retention', 
count(CASE WHEN sce.TimeGenerated < dateadd(dd,-@statedaystokeep,getutcdate()) THEN sce.TimeGenerated ELSE NULL END) as '> grooming retention', 
count(CASE WHEN sce.TimeGenerated < dateadd(dd,-30,getutcdate()) THEN sce.TimeGenerated ELSE NULL END) as '> 30 days', 
count(CASE WHEN sce.TimeGenerated < dateadd(dd,-90,getutcdate()) THEN sce.TimeGenerated ELSE NULL END) as '> 90 days', 
count(CASE WHEN sce.TimeGenerated < dateadd(dd,-365,getutcdate()) THEN sce.TimeGenerated ELSE NULL END) as '> 365 days' 
from StateChangeEvent sce