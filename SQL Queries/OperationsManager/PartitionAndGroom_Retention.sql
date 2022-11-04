SELECT [ObjectName]
      ,[IsPartitioned]
      ,[InsertViewName]
      ,[GroomingSproc]
      ,[DaysToKeep]
      ,[GroomingRunTime]
      ,[DataGroomedMaxTime]
      ,[IsInternal]
  FROM [PartitionAndGroomingSettings] WITH (NOLOCK)
  ORDER BY ObjectName