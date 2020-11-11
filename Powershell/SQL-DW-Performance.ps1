#This script gathers performance data from SQL DW and outputs as Objects.
$SQLServer = "SQL1"
$db1 = "OperationsManagerDW"
#Disk space in MB
$query1 = @'
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
where Perf.vPerfDaily.Datetime between '2020-01-01' and '2020-07-30'
and vPerformanceRule.ObjectName='LogicalDisk'
and vPerformanceRule.CounterName='Free Megabytes'
and (vRule.RuleDefaultName='Logical Disk Free Megabytes 2000'
	or vRule.RuleDefaultName='Logical Disk Free Megabytes 2003'
	or vRule.RuleDefaultName='Logical Disk Free Megabytes 2008')
Order by Path, Name
'@

#CPU Utilization
$query2 = @'
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
where Perf.vPerfDaily.Datetime between '2020-01-01' and '2020-07-30'
and vPerformanceRule.ObjectName='Processor'
and vPerformanceRule.CounterName='% Processor Time'
and (vRule.RuleDefaultName='Processor % Processor Time Total 2003'
or vRule.RuleDefaultName='% Processor % Processor TIme Total 2008')
Order by Path,Name
'@

#Free disk space in Percentage
$query3 = @'
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
where Perf.vPerfDaily.Datetime between '2020-01-01' and '2020-07-30'
and vPerformanceRule.ObjectName='LogicalDisk'
and vPerformanceRule.CounterName='% Free Space'
and (vRule.RuleDefaultName='% Logical Disk Free space 2000'
	or vRule.RuleDefaultName='% Logical Disk Free Space 2003'
	or vRule.RuleDefaultName='% Logical Disk Free Space 2008')
Order by Path, Name
'@

# Memory Percentage Used
$query4 = @'
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
where Perf.vPerfDaily.Datetime between '2020-01-01' and '2020-07-30'
and vPerformanceRule.ObjectName='Memory'
and vPerformanceRule.CounterName='PercentMemoryUsed'
and (vRule.RuleDefaultName='Percent Memory Used')
Order by Path,Name
'@

<#	
$query5 = @'

'@
#>
$i = 0
$query = ($query1, $query2, $query3, $query4)
$query | % { $i++; Write-Host "Query : $i" -ForegroundColor Cyan; Invoke-Sqlcmd -ServerInstance $SQLServer -Database $db1 -Query $_ -OutputSqlErrors $true | ft * }