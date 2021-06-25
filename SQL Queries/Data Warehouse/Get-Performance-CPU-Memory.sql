-- These scripts are to be run on the Data Warehouse DB.

    -- Adjust the date to suite your requirements. The rest of the script remains the same
    
-- CPU Utilization
select
vManagedEntity.Path
,Perf.vPerfdaily.DateTime
,Perf.vPerfdaily.SampleCount
,vPerformanceRule.ObjectName
,vPerformanceRule.CounterName
,vManagedEntity.Name
,Perf.vPerfdaily.Averagevalue
,Perf.vPerfdaily.MinValue
,Perf.vPerfdaily.MaxValue
,vRule.RuleDefaultName

from Perf.vPerfDaily
join vPerformanceRuleInstance on vPerformanceRuleInstance.PerformanceRuleInstanceRowid=Perf.vPerfDaily.PerformanceRuleInstanceRowid

join vPerformanceRule on vPerformanceRule.RuleRowId=vPerformanceRuleInstance.RuleRowId
join vManagedEntity on vManagedEntity.ManagedEntityRowid=Perf.vPerfDaily.ManagedEntityRowId
join vRule on vRule.RuleRowId=vPerformanceRuleInstance.RuleRowId
where Perf.vPerfDaily.Datetime between '2020-01-01' and '2021-06-25'
and vPerformanceRule.ObjectName='Processor'
and vPerformanceRule.CounterName='% Processor Time'
and (vRule.RuleDefaultName='Processor % Processor Time Total 2003'
or vRule.RuleDefaultName='% Processor % Processor TIme Total 2008')
Order by Path,Name

-- Disk space in MB
select
vManagedEntity.Path
,Perf.vPerfdaily.DateTime
,Perf.vPerfdaily.SampleCount
,vPerformanceRule.ObjectName
,vPerformanceRule.CounterName
,vManagedEntity.Name
,Perf.vPerfdaily.Averagevalue
,Perf.vPerfdaily.MinValue
,Perf.vPerfdaily.MaxValue
,vRule.RuleDefaultName

from Perf.vPerfDaily
join vPerformanceRuleInstance on vPerformanceRuleInstance.PerformanceRuleInstanceRowid=Perf.vPerfDaily.PerformanceRuleInstanceRowid

join vPerformanceRule on vPerformanceRule.RuleRowId=vPerformanceRuleInstance.RuleRowId
join vManagedEntity on vManagedEntity.ManagedEntityRowid=Perf.vPerfDaily.ManagedEntityRowId
join vRule on vRule.RuleRowId=vPerformanceRuleInstance.RuleRowId
where Perf.vPerfDaily.Datetime between '2020-01-01' and '2021-06-25'
and vPerformanceRule.ObjectName='LogicalDisk'
and vPerformanceRule.CounterName='Free Megabytes'
and (vRule.RuleDefaultName='Logical Disk Free Megabytes 2000'
or vRule.RuleDefaultName='Logical Disk Free Megabytes 2003'
or vRule.RuleDefaultName='Logical Disk Free Megabytes 2008')
Order by Path,Name

-- Free disk space in Percentage
select
vManagedEntity.Path
,Perf.vPerfdaily.DateTime
,Perf.vPerfdaily.SampleCount
,vPerformanceRule.ObjectName
,vPerformanceRule.CounterName
,vManagedEntity.Name
,Perf.vPerfdaily.Averagevalue
,Perf.vPerfdaily.MinValue
,Perf.vPerfdaily.MaxValue
,vRule.RuleDefaultName

from Perf.vPerfDaily
join vPerformanceRuleInstance on vPerformanceRuleInstance.PerformanceRuleInstanceRowid=Perf.vPerfDaily.PerformanceRuleInstanceRowid

join vPerformanceRule on vPerformanceRule.RuleRowId=vPerformanceRuleInstance.RuleRowId
join vManagedEntity on vManagedEntity.ManagedEntityRowid=Perf.vPerfDaily.ManagedEntityRowId
join vRule on vRule.RuleRowId=vPerformanceRuleInstance.RuleRowId
where Perf.vPerfDaily.Datetime between '2020-01-01' and '2021-06-25'
and vPerformanceRule.ObjectName='LogicalDisk'
and vPerformanceRule.CounterName='% Free Space'
and (vRule.RuleDefaultName='% Logical Disk Free space 2000'
or vRule.RuleDefaultName='% Logical Disk Free Space 2003'
or vRule.RuleDefaultName='% Logical Disk Free Space 2008')
Order by Path,Name

-- Memory Percentage Used
select
vManagedEntity.Path
,Perf.vPerfdaily.DateTime
,Perf.vPerfdaily.SampleCount
,vPerformanceRule.ObjectName
,vPerformanceRule.CounterName
,vManagedEntity.Name
,Perf.vPerfdaily.Averagevalue
,Perf.vPerfdaily.MinValue
,Perf.vPerfdaily.MaxValue
,vRule.RuleDefaultName

from Perf.vPerfDaily
join vPerformanceRuleInstance on vPerformanceRuleInstance.PerformanceRuleInstanceRowid=Perf.vPerfDaily.PerformanceRuleInstanceRowid

join vPerformanceRule on vPerformanceRule.RuleRowId=vPerformanceRuleInstance.RuleRowId
join vManagedEntity on vManagedEntity.ManagedEntityRowid=Perf.vPerfDaily.ManagedEntityRowId
join vRule on vRule.RuleRowId=vPerformanceRuleInstance.RuleRowId
where Perf.vPerfDaily.Datetime between '2020-01-01' and '2021-06-25'
and vPerformanceRule.ObjectName='Memory'
and vPerformanceRule.CounterName='PercentMemoryUsed'
and (vRule.RuleDefaultName='Percent Memory Used')
Order by Path,Name



-- Queries from OpsDB
-- Query to get Logical Disk Free
USE OperationsManager
SELECT [Path], ObjectName, CounterName, InstanceName, SampleValue as [% Free Megabytes], TimeSampled
FROM PerformanceDataAllView pdv with (NOLOCK) 
inner join PerformanceCounterView pcv on pdv.performancesourceinternalid = pcv.performancesourceinternalid
inner join BaseManagedEntity bme on pcv.ManagedEntityId = bme.BaseManagedEntityId
WHERE Path = 'ServerFQDN' AND ObjectName = 'LogicalDisk' AND CounterName = 'Free Megabytes' 
ORDER BY TimeSampled DESC
-- Replace ServerFQDN with the server for which you need to collect the data.

-- Query to get memory.
USE OperationsManager
SELECT [Path], ObjectName, CounterName, InstanceName, SampleValue as [% Memory Used], TimeSampled
FROM PerformanceDataAllView pdv with (NOLOCK) 
inner join PerformanceCounterView pcv on pdv.performancesourceinternalid = pcv.performancesourceinternalid
inner join BaseManagedEntity bme on pcv.ManagedEntityId = bme.BaseManagedEntityId
WHERE Path = 'ServerFQDN' AND ObjectName = 'Memory' AND CounterName = 'PercentMemoryUsed'
ORDER BY TimeSampled DESC
-- Replace ServerFQDN with the server for which you need to collect the data.

-- Query to get % Processor time.
USE OperationsManager
SELECT [Path], ObjectName, CounterName, InstanceName, SampleValue as [% Processor Time], TimeSampled
FROM PerformanceDataAllView pdv with (NOLOCK) 
inner join PerformanceCounterView pcv on pdv.performancesourceinternalid = pcv.performancesourceinternalid
inner join BaseManagedEntity bme on pcv.ManagedEntityId = bme.BaseManagedEntityId
WHERE Path = 'ServerFQDN' AND ObjectName = 'Processor' AND CounterName = '% Processor Time' and InstanceName ='_Total'
ORDER BY TimeSampled DESC
-- Replace ServerFQDN with the server for which you need to collect the data.
