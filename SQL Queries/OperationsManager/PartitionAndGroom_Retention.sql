SELECT [ObjectName]
      ,[IsPartitioned]
      ,[InsertViewName]
      ,[GroomingSproc]
      ,[DaysToKeep]
      ,[GroomingRunTime]
      ,[DataGroomedMaxTime]
      ,[IsInternal]
  FROM [PartitionAndGroomingSettings] WITH (NOLOCK)
  WHERE ObjectId NOT IN ('18','17','16','15','10','11')
  ORDER BY ObjectName