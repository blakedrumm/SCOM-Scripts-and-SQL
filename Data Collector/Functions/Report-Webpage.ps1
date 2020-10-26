Function Report-Webpage
{
	# The Name and Location of are we going to save this Report
	$ReportName = "DataCollector.html"
	$ReportPath = "$OutputPath\HTML Report\$ReportName"
	
	$ReportNameDW = "DataCollectorDW.html"
	$ReportPathDW = "$OutputPath\HTML Report\$ReportNameDW"
	
	
	# Create header for OpsMgr HTML Report
	$Head = "<style>"
	$Head += "BODY{background-color:#CCCCCC;font-family:Calibri,sans-serif; font-size: small;}"
	$Head += "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse; width: 98%;}"
	$Head += "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:#293956;color:white;padding: 5px; font-weight: bold;text-align:left;}"
	$Head += "H3{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:#293956;color:white;padding: 5px; font-weight: bold;text-align:left;}"
	$Head += "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:#F0F0F0; color:black; padding: 2px;}"
	$Head += ".tab {overflow: hidden; border: 1px solid #ccc; background-color: #f1f1f1;}"
	$Head += ".tab button {background-color: inherit; float: left; border: none; outline: none; cursor: pointer; padding: 14px 16px; transition: 0.3s; }"
	$Head += ".tab button:hover { background-color: #ddd; }"
	$Head += ".tab button.active { background-color: #ccc; }"
	$Head += ".tabcontent { display: none; padding: 6px 12px; border: 1px solid #ccc; border-top: none; }"
	$Head += "</style>"
	
	$Head += "<script type='text/javascript'>"
	$Head += "function openCategory(evt, cityName) {
  var i, tabcontent, tablinks;
  tabcontent = document.getElementsByClassName('tabcontent');
  for (i = 0; i < tabcontent.length; i++) {
    tabcontent[i].style.display = 'none';
  }
  tablinks = document.getElementsByClassName('tablinks');
  for (i = 0; i < tablinks.length; i++) {
    tablinks[i].className = tablinks[i].className.replace(' active', '');
  }

  document.getElementById(cityName).style.display = 'block';
  evt.currentTarget.className += ' active';
}"
	$Head += "</script>"
	
	# Create header for OpsMgr DW HTML Report
	$HeadDW = "<style>"
	$HeadDW += "BODY{background-color:#CCCCCC; color:grey;font-family:Calibri,sans-serif; font-size: small;}"
	$HeadDW += "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse; width: 98%;}"
	$HeadDW += "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:#293956;color:white;padding: 5px; font-weight: bold;text-align:left;}"
	$HeadDW += "H3{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:#293956;color:white;padding: 5px; font-weight: bold;text-align:left;}"
	$HeadDW += "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:#F0F0F0; color:black; padding: 2px;}"
	$HeadDW += ".tab {overflow: hidden; border: 1px solid #ccc; background-color: #f1f1f1;}"
	$HeadDW += ".tab button {background-color: inherit; float: left; border: none; outline: none; cursor: pointer; padding: 14px 16px; transition: 0.3s; }"
	$HeadDW += ".tab button:hover { background-color: #ddd; }"
	$HeadDW += ".tab button.active { background-color: #ccc; }"
	$HeadDW += ".tabcontent { display: none; padding: 6px 12px; border: 1px solid #ccc; border-top: none; }"
	$HeadDW += "</style>"
	
	$HeadDW += "<script type='text/javascript'>"
	$HeadDW += "function openCategoryDW(evt, cityName) {
  var i, tabcontent, tablinks;
  tabcontent = document.getElementsByClassName('tabcontent');
  for (i = 0; i < tabcontent.length; i++) {
    tabcontent[i].style.display = 'none';
  }
  tablinks = document.getElementsByClassName('tablinks');
  for (i = 0; i < tablinks.length; i++) {
    tablinks[i].className = tablinks[i].className.replace(' active', '');
  }

  document.getElementById(cityName).style.display = 'block';
  evt.currentTarget.className += ' active';
}"
	$HeadDW += "</script>"
	#$ReportOutput += "<p>Operational Database Server      :  $OpsDB_SQLServer</p>"
	#$ReportOutput += "<p>Data Warehouse Database Server   :  $DW_SQLServer</p>"  
	
	$CSVFileLocation = "$CSVFile\output"
	
	# Tabs for Operations Manager Report
	
	$ReportOutput += "<div class='tab'>"
	$ReportOutput += "<button class='tablinks' onclick=`"openCategory(event, 'general')`">General Information</button>"
	$ReportOutput += "<button class='tablinks' onclick=`"openCategory(event, 'alertView')`">Alert</button>"
	$ReportOutput += "<button class='tablinks' onclick=`"openCategory(event, 'configLogs')`">Config Logs</button>"
	$ReportOutput += "<button class='tablinks' onclick=`"openCategory(event, 'configChurn')`">Config Churn</button>"
	$ReportOutput += "<button class='tablinks' onclick=`"openCategory(event, 'eventView')`">Event</button>"
	$ReportOutput += "<button class='tablinks' onclick=`"openCategory(event, 'healthService')`">Health Service</button>"
	$ReportOutput += "<button class='tablinks' onclick=`"openCategory(event, 'instances')`">Instances</button>"
	$ReportOutput += "<button class='tablinks' onclick=`"openCategory(event, 'managementPack')`">Management Pack</button>"
	$ReportOutput += "<button class='tablinks' onclick=`"openCategory(event, 'managementServers')`">Management Servers</button>"
	$ReportOutput += "<button class='tablinks' onclick=`"openCategory(event, 'managementGroup')`">Management Groups</button>"
	$ReportOutput += "<button class='tablinks' onclick=`"openCategory(event, 'networkDevice')`">Network Device</button>"
	$ReportOutput += "<button class='tablinks' onclick=`"openCategory(event, 'operationsDBSQL')`">Ops DB/SQL</button>"
	$ReportOutput += "<button class='tablinks' onclick=`"openCategory(event, 'perfData')`">Performance</button>"
	$ReportOutput += "<button class='tablinks' onclick=`"openCategory(event, 'stateData')`">State Events</button>"
	$ReportOutput += "<button class='tablinks' onclick=`"openCategory(event, 'syncData')`">Sync Data</button>"
	$ReportOutput += "</div>"
	
	# Tabs for Operations Manager DW Report
	
	$ReportOutputDW += "<div class='tab'>"
	$ReportOutputDW += "<button class='tablinks' onclick=`"openCategoryDW(event, 'general')`">General Information</button>"
	$ReportOutputDW += "<button class='tablinks' onclick=`"openCategoryDW(event, 'configChurn')`">Config Churn</button>"
	$ReportOutputDW += "<button class='tablinks' onclick=`"openCategoryDW(event, 'aggregation')`">Aggregation</button>"
	$ReportOutputDW += "<button class='tablinks' onclick=`"openCategoryDW(event, 'databaseSize')`">Database & Table Size/Properties</button>"
	$ReportOutputDW += "<button class='tablinks' onclick=`"openCategoryDW(event, 'largeTables')`">Large Tables</button>"
	$ReportOutputDW += "<button class='tablinks' onclick=`"openCategoryDW(event, 'sqlProperties')`">SQL Properties</button>"
	$ReportOutputDW += "<button class='tablinks' onclick=`"openCategoryDW(event, 'stagingBackups')`">Staging & Backups</button>"
	$ReportOutputDW += "<button class='tablinks' onclick=`"openCategoryDW(event, 'greyed')`">Greyed Out</button>"
	$ReportOutputDW += "<button class='tablinks' onclick=`"openCategoryDW(event, 'indexMaint')`">Index Maint</button>"
	$ReportOutputDW += "</div>"
	
	# General Information - OpsMgr
	$reportDetail = $setupLocation.Product, $setupLocation.InstalledOn, $setupLocation.CurrentVersion, $setupLocation.ServerVersion, $setupLocation.UIVersion, $setupLocation.ManagementServerPort, "$ManagementServers", $setupLocation.DatabaseServerName, $setupLocation.DatabaseName, $setupLocation.InstallDirectory, "$OMSQLProperties"
	$reportDetail = "<tr>" + ($reportDetail | % { "<td>$_</td>" }) + "</tr>"
	$ReportOutput += @("<div id='general' class='tabcontent'>
<h3>General Information</h3>
<table style='width: 300px; '><th>Product</th><th>Installed On</th><th>Current Version</th><th>Server Version</th><th>UI Version</th><th>Management Server Port</th><th>Management Servers in Mgmt Group</th><th>Operations Manager DB Server</th><th>Operations Manager DB</th><th>Install Directory</th><th>Operations Manager SQL Properties</th>
", $reportDetail, "</table>
</div>")
	
	# General Information - OpsMgr DW
	
	$ReportOutputDW += @("<div id='general' class='tabcontent'>
<h3>General Information</h3>
<table style='width: 300px; '><th>Product</th><th>Installed On</th><th>Current Version</th><th>Server Version</th><th>UI Version</th><th>Data Warehouse DB Server</th><th>Operations Manager DW</th>
<tr><td>" + $setupLocation.Product + "</td><td>" + $setupLocation.InstalledOn + "</td><td>" + $setupLocation.CurrentVersion + "</td><td>" + $setupLocation.ServerVersion + "</td><td>" + $setupLocation.UIVersion + "</td><td>" + $setupLocation.DataWarehouseDBServerName + "</td><td>" + $setupLocation.DataWarehouseDBName + "</td></tr>
</table>
</div>")
	
	#
	#
	# !!! ALERT VIEW - OPSMGR !!!
	#
	#
	
	
	$AlertsByDayImport = Import-Csv "$CSVFileLocation`\Alerts_ByDay.csv"
	
	$ReportOutput += "<div id='alertView' class='tabcontent'>"
	$ReportOutput += "<h3>Alerts By Day</h3>"
	$ReportOutput += "<table style='width: 300px;'><th>Day Added</th><th># of Alerts Per Day</th>"
	foreach ($line in $AlertsByDayImport)
	{
		$ReportOutput += "<tr><td>" + $line[0].DayAdded + "</td><td>" + $line[0].NumAlertsPerDay + "</td></tr>"
	}
	$ReportOutput += "</table>"
	
	$AlertsByCountImport = Import-Csv "$CSVFileLocation`\Alerts_ByCount.csv"
	$ReportOutput += "<h3>Alerts By Count</h3>"
	$ReportOutput += "<table style='width: 300px;'><th>Alert Count</th><th>Alert String Name</th><th>Alert String Description</th><th>Monitoring Rule ID</th><th>Name</th>"
	foreach ($line in $AlertsByCountImport)
	{
		$ReportOutput += "<tr><td>" + $line[0].AlertCount + "</td><td>" + $line[0].AlertStringName + "</td><td>" + $line[0].AlertStringDescription + "</td><td>" + $line[0].MonitoringRuleId + "</td><td>" + $line[0].Name + "</td></tr>"
	}
	$ReportOutput += "</table>"
	
	$AlertsByRepeatImport = Import-Csv "$CSVFileLocation`\Alerts_ByRepeat.csv"
	$ReportOutput += "<h3>Alerts By Repeat</h3>"
	$ReportOutput += "<table style='width: 300px;'><th>Repeat Count</th><th>Alert String Name</th><th>Alert String Description</th><th>Monitoring Rule ID</th><th>Name</th>"
	foreach ($line in $AlertsByRepeatImport)
	{
		$ReportOutput += "<tr><td>" + $line[0].RepeatCount + "</td><td>" + $line[0].AlertStringName + "</td><td>" + $line[0].AlertStringDescription + "</td><td>" + $line[0].MonitoringRuleId + "</td><td>" + $line[0].Name + "</td></tr>"
	}
	$ReportOutput += "</table>"
	$ReportOutput += "</div>"
	
	#
	#
	# !!! END ALERT VIEW -OPSMGR !!!
	#
	#
	
	#
	#
	# !!! EVENT VIEW - OPSMGR !!!
	#
	#
	
	$EventsByComputerImport = Import-CSV "$CSVFileLocation`\Events_ByComputer.csv"
	$ReportOutput += "<div id='eventView' class='tabcontent'>"
	$ReportOutput += "<h3>Events By Computer</h3>"
	$ReportOutput += "<table style='width: 300px;'><th>Computer Name</th><th>Total Events</th><th>Event ID</th>"
	foreach ($line in $EventsByComputerImport)
	{
		$ReportOutput += "<tr><td>" + $line[0].ComputerName + "</td><td>" + $line[0].TotalEvents + "</td><td>" + $line[0].EventID + "</td></tr>"
	}
	$ReportOutput += "</table>"
	
	#EventsByNumber
	
	$EventsByNumberImport = Import-CSV "$CSVFileLocation`\Events_ByNumber.csv"
	$ReportOutput += "<h3>Events By Number</h3>"
	$ReportOutput += "<table style='width: 300px;'><th>Event ID</th><th>Total Events</th><th>Event Source</th>"
	foreach ($line in $EventsByNumberImport)
	{
		$ReportOutput += "<tr><td>" + $line[0].EventID + "</td><td>" + $line[0].TotalEvents + "</td><td>" + $line[0].EventSource + "</td></tr>"
	}
	$ReportOutput += "</table>"
	$ReportOutput += "</div>"
	
	#
	#
	# !!! END EVENT VIEW - OPSMGR !!!
	#
	#
	
	#
	#
	# !!! CONFIG LOGS - OPSMGR !!!
	#
	
	
	$ConfigLogsImport = Import-CSV "$CSVFileLocation`\Config_Logs.csv"
	$ReportOutput += "<div id='configLogs' class='tabcontent'>"
	$ReportOutput += "<h3>Config Logs</h3>"
	$ReportOutput += "<table style='width: 300px;'><th>Work Item Row ID</th><th>Work Item Name</th><th>Work Item State ID</th><th>Server Name</th><th>Instance Name</th><th>Started Date Time - UTC</th><th>Last Activity Date Time - UTC</th><th>Completed Date Time - UTC</th><th>Duration in Seconds</th>"
	foreach ($line in $ConfigLogsImport)
	{
		$ReportOutput += "<tr><td>" + $line[0].WorkItemRowId + "</td><td>" + $line[0].WorkItemName + "</td><td>" + $line[0].WorkItemStateId + "</td><td>" + $line[0].ServerName + "</td><td>" + $line[0].InstanceName + "</td><td>" + $line[0].StartedDateTimeUtc + "</td><td>" + $line[0].LastActivityDateTimeUtc + "</td><td>" + $line[0].CompletedDateTimeUtc + "</td><td>" + $line[0].DurationSeconds + "</td></tr>"
	}
	$ReportOutput += "</table>"
	$ReportOutput += "</div>"
	
	#
	# !!! CONFIG LOGS PACK - OPSMGR !!!
	#
	#
	
	#
	#
	# !!! CONFIG CHURN - OPSMGR !!!
	#
	#
	
	$ConfigChurnImport = Import-CSV "$CSVFileLocation`\OpsDBConfigChurn.csv"
	$ReportOutput += "<div id='configChurn' class='tabcontent'>"
	$ReportOutput += "<h3>Operations DB Config Churn</h3>"
	$ReportOutput += "<table style='width: 300px;'><th>Entity Type ID</th><th>Type Name</th><th>Number of Changes</th>"
	foreach ($line in $ConfigChurnImport)
	{
		$ReportOutput += "<tr><td>" + $line[0].EntityTypeId + "</td><td>" + $line[0].TypeName + "</td><td>" + $line[0].'Number of changes' + "</td></tr>"
	}
	$ReportOutput += "</table>"
	$ReportOutput += "</div>"
	
	#
	#
	# !!! END CONFIG CHURN - OPSMGR !!!
	#
	#
	
	#
	#
	# !!! MANAGEMENT PACK - OPSMGR !!!
	#
	#
	
	$ManagementPacksImport = Import-CSV "$CSVFileLocation`\ManagementPacks.csv"
	$ReportOutput += "<div id='managementPack' class='tabcontent'>"
	$ReportOutput += "<h3>Management Packs</h3>"
	$ReportOutput += "<table style='width: 300px;'><th>Management Pack ID</th><th>Version</th><th>Friendly Name</th><th>Display Name</th><th>Sealed</th><th>Last Modified</th><th>Time Created</th>"
	foreach ($mp in $ManagementPacksImport)
	{
		$ReportOutput += "<tr><td>" + $mp[0].ManagementPackID + "</td><td>" + $mp[0].Version + "</td><td>" + $mp[0].FriendlyName + "</td><td>" + $mp[0].DisplayName + "</td><td>" + $mp[0].Sealed + "</td><td>" + $mp[0].LastModified + "</td><td>" + $mp[0].TimeCreated + "</td></tr>"
	}
	$ReportOutput += "</table>"
	$ReportOutput += "</div>"
	
	#
	#
	# !!! END MANAGEMENT PACK - OPSMGR !!!
	#
	#
	
	#
	#
	# !!! MANAGEMENT GROUP - OPSMGR !!!
	#
	#
	
	$MGOverviewImport = Import-CSV "$CSVFileLocation`\MG_Overview.csv"
	$ReportOutput += "<div id='managementGroup' class='tabcontent'>"
	$ReportOutput += "<h3>Management Group(s) Overview</h3>"
	$ReportOutput += "<table style='width: 300px;'><th>Management Group Name</th><th>Management Server Count</th><th>Gateway Count</th><th>Agent Count</th><th>Agent's Pending</th><th>Unix/Linux Count</th><th>Network Device Count</th>"
	foreach ($line in $MGOverviewImport)
	{
		$ReportOutput += "<tr><td>" + $line[0].MG_Name + "</td><td>" + $line[0].MS_Count + "</td><td>" + $line[0].GW_Count + "</td><td>" + $line[0].Agent_Count + "</td><td>" + $line[0].Agent_Pending + "</td><td>" + $line[0].Unix_Count + "</td><td>" + $line[0].NetworkDevice_Count + "</td></tr>"
	}
	$ReportOutput += "</table>"
	
	$MGGlobalSettingsImport = Import-CSV "$CSVFileLocation`\MG_GlobalSettings.csv"
	$ReportOutput += "<h3>Management Group(s) Global Settings</h3>"
	$ReportOutput += "<table style='width: 300px;'><th>Property</th><th>Setting Value</th>"
	foreach ($line in $MGGlobalSettingsImport)
	{
		$ReportOutput += "<tr><td>" + $line[0].Property + "</td><td>" + $line[0].SettingValue + "</td></tr>"
	}
	$ReportOutput += "</table>"
	
	$MGUserRolesImport = Import-CSV "$CSVFileLocation`\MG_UserRoles.csv"
	$ReportOutput += "<h3>Management Group User Roles</h3>"
	$ReportOutput += "<table style='width: 300px;'><th>Description</th><th>Role Member</th>"
	foreach ($line in $MGUserRolesImport)
	{
		$ReportOutput += "<tr><td>" + $line[0].Description + "</td><td>" + $line[0].RoleMember + "</td></tr>"
	}
	$ReportOutput += "</table>"
	
	$MGResourcePoolImport = Import-CSV "$CSVFileLocation`\MG_ResourcePools.csv"
	$ReportOutput += "<h3>Management Group Resource Pools</h3>"
	$ReportOutput += "<table style='width: 300px;'><th>Resource Pool</th><th>Member</th>"
	foreach ($line in $MGResourcePoolImport)
	{
		$ReportOutput += "<tr><td>" + $line[0].ResourcePool + "</td><td>" + $line[0].Member + "</td></tr>"
	}
	$ReportOutput += "</table>"
	$ReportOutput += "</div>"
	
	#
	#
	# !!! END MANAGEMENT GROUP - OPSMGR !!!
	#
	#
	
	#
	#
	# !!! INSTANCES - OPSMGR !!!
	#
	#
	
	$InstancesByHostImport = Import-CSV "$CSVFileLocation`\Instances_ByHost.csv"
	$ReportOutput += "<div id='instances' class='tabcontent'>"
	$ReportOutput += "<h3>Instances By Host</h3>"
	$ReportOutput += "<table style='width: 300px;'><th>Display Name</th><th>Hosted Instances</th>"
	foreach ($line in $InstancesByHostImport)
	{
		$ReportOutput += "<tr><td>" + $line[0].DisplayName + "</td><td>" + $line[0].HostedInstances + "</td></tr>"
	}
	$ReportOutput += "</table>"
	
	$InstancesByTypeImport = Import-CSV "$CSVFileLocation`\Instances_ByType.csv"
	$ReportOutput += "<h3>Instances By Type</h3>"
	$ReportOutput += "<table style='width: 300px;'><th>Type Name</th><th>Number of Entities by Type</th>"
	foreach ($line in $InstancesByTypeImport)
	{
		$ReportOutput += "<tr><td>" + $line[0].TypeName + "</td><td>" + $line[0].NumEntitiesByType + "</td></tr>"
	}
	$ReportOutput += "</table>"
	
	$InstancesByTypeMTImport = Import-CSV "$CSVFileLocation`\Instances_ByType_MT.csv"
	$ReportOutput += "<h3>Instances By Type MT</h3>"
	$ReportOutput += "<table style='width: 300px;'><th>MT Table Name</th><th>Row Count</th>"
	foreach ($line in $InstancesByTypeMTImport)
	{
		$ReportOutput += "<tr><td>" + $line[0].MT_TableName + "</td><td>" + $line[0].RowCount + "</td></tr>"
	}
	$ReportOutput += "</table>"
	
	$InstancesByTypeAndHostImport = Import-CSV "$CSVFileLocation`\Instances_ByTypeAndHost.csv"
	$ReportOutput += "<h3>Instances By Type And Host</h3>"
	$ReportOutput += "<table style='width: 300px;'><th>Display Name</th><th>Hosted Instances</th><th>Typed Entity Name</th>"
	foreach ($line in $InstancesByTypeAndHostImport)
	{
		$ReportOutput += "<tr><td>" + $line[0].DisplayName + "</td><td>" + $line[0].HostedInstances + "</td><td>" + $line[0].TypedEntityName + "</td></tr>"
	}
	$ReportOutput += "</table>"
	
	$InstancesTotalBMEImport = Import-CSV "$CSVFileLocation`\Instances_TotalBME.csv"
	$ReportOutput += "<h3>Instances Total BME</h3>"
	$ReportOutput += "<table style='width: 300px;'><th>Total BME</th>"
	foreach ($line in $InstancesTotalBMEImport)
	{
		$ReportOutput += "<tr><td>" + $line[0].Column1 + "</td></tr>"
	}
	$ReportOutput += "</table>"
	$ReportOutput += "</div>"
	
	#
	#
	# !!! END INSTANCES - OPSMGR !!!
	#
	#
	
	#
	#
	# !!! MANAGEMENT SERVER - OPSMGR !!!
	#
	#
	
	$ManagementServersImport = Import-CSV "$CSVFileLocation`\ManagementServers.csv"
	$ReportOutput += "<div id='managementServers' class='tabcontent'>"
	$ReportOutput += "<h3>Management Servers</h3>"
	$ReportOutput += "<table style='width: 300px;'><th>Display Name</th><th>Is Management Server</th><th>Is Gateway</th><th>Is RHS</th><th>Version</th><th>Action Account Identity</th><th>Heartbeat Interval</th>"
	foreach ($line in $ManagementServersImport)
	{
		$ReportOutput += "<tr><td>" + $line[0].DisplayName + "</td><td>" + $line[0].IsManagementServer + "</td><td>" + $line[0].IsGateway + "</td><td>" + $line[0].IsRHS + "</td><td>" + $line[0].Version + "</td><td>" + $line[0].ActionAccountIdentity + "</td><td>" + $line[0].HeartbeatInterval + "</td></tr>"
	}
	$ReportOutput += "</table>"
	$ReportOutput += "</div>"
	
	#
	#
	# !!! END MANAGEMENT SERVER - OPSMGR !!!
	#
	#
	
	#
	#
	# !!! STATE VIEW - OPSMGR !!!
	#
	#
	
	# State Changes by Day
	$StateByDayImport = Import-CSV "$CSVFileLocation`\State_ByDay.csv"
	$ReportOutput += "<div id='stateData' class='tabcontent'>"
	$ReportOutput += "<h3>State Changes by Day</h3>"
	$ReportOutput += "<table style='width: 300px;'><th>Day Generated</th><th>State Changes Per Day</th>"
	foreach ($line in $StateByDayImport)
	{
		$ReportOutput += "<tr><td>" + $line[0].DayGenerated + "</td><td>" + $line[0].StateChangesPerDay + "</td></tr>"
	}
	$ReportOutput += "</table>"
	
	# State Changes by Monitor
	
	$StateByMonitorImport = Import-CSV "$CSVFileLocation`\State_ByMonitor.csv"
	$ReportOutput += "<h3>State Changes by Monitor</h3>"
	$ReportOutput += "<table style='width: 300px;'><th>Number of State Changes</th><th>Monitor Display Name</th><th>Monitor ID Name</th><th>Target Class</th>"
	foreach ($line in $StateByMonitorImport)
	{
		$ReportOutput += "<tr><td>" + $line[0].NumStateChanges + "</td><td>" + $line[0].MonitorDisplayName + "</td><td>" + $line[0].MonitorIdName + "</td><td>" + $line[0].TargetClass + "</td></tr>"
	}
	$ReportOutput += "</table>"
	
	#State Change by Monitor - 7 Days
	
	$StateByMonitor7DayImport = Import-CSV "$CSVFileLocation`\State_ByMonitor_7days.csv"
	$ReportOutput += "<h3>State Changes by Monitor - 7 Days</h3>"
	$ReportOutput += "<table style='width: 300px;'><th>Number of State Changes</th><th>Monitor Display Name</th><th>Monitor ID Name</th><th>Target Class</th>"
	foreach ($line in $StateByMonitor7DayImport)
	{
		$ReportOutput += "<tr><td>" + $line[0].NumStateChanges + "</td><td>" + $line[0].MonitorDisplayName + "</td><td>" + $line[0].MonitorIdName + "</td><td>" + $line[0].TargetClass + "</td></tr>"
	}
	$ReportOutput += "</table>"
	
	# State Change by Monitor and Day
	
	$StateByMonitorAndDayImport = Import-CSV "$CSVFileLocation`\State_ByMonitorAndDay.csv"
	$ReportOutput += "<h3>State Changes by Monitor and Day</h3>"
	$ReportOutput += "<table style='width: 300px;'><th>Day</th><th>Monitor Name</th><th>Total State Changes</th>"
	foreach ($line in $StateByMonitor7DayImport)
	{
		$ReportOutput += "<tr><td>" + $line[0].Day + "</td><td>" + $line[0].MonitorName + "</td><td>" + $line[0].TotalStateChanges + "</td></tr>"
	}
	$ReportOutput += "</table>"
	$ReportOutput += "</div>"
	
	#
	#
	# !!! END STATE CHANGE VIEW - OPSMGR !!!
	#
	#
	
	#
	#
	# !!! AGGREGATION - OPSMGR DW !!!
	#
	#
	
	$DWAggregationHistoryImport = Import-CSV "$CSVFileLocation`\DW_AggregationHistory.csv"
	$ReportOutputDW += "<div id='aggregation' class='tabcontent'>"
	$ReportOutputDW += "<h3>DW Aggregation History</h3>"
	$ReportOutputDW += "<table style='width: 300px;'><th>Dataset Default Name</th><th>Aggregation Date/Time</th><th>Aggregation Type ID</th><th>First Aggregation Start Date/Time</th><th>First Aggregation Duration in Seconds</th><th>Last Aggregation Start Date/Time</th><th>Last Aggregation Duration in Seconds</th><th>Dirty Ind</th><th>Data Last Recieved Date/Time</th><th>Aggregation Count</th>"
	foreach ($line in $DWAggregationHistoryImport)
	{
		$ReportOutputDW += "<tr><td>" + $line[0].DatasetDefaultName + "</td><td>" + $line[0].AggregationDateTime + "</td><td>" + $line[0].AggregationTypeId + "</td><td>" + $line[0].FirstAggregationStartDateTime + "</td><td>" + $line[0].FirstAggregationDurationSeconds + "</td><td>" + $line[0].LastAggregationStartDateTime + "</td><td>" + $line[0].LastAggregationDurationSeconds + "</td><td>" + $line[0].DirtyInd + "</td><td>" + $line[0].DataLastReceivedDateTime + "</td><td>" + $line[0].AggregationCount + "</td></tr>"
	}
	$ReportOutputDW += "</table>"
	
	$DWAggregationStatusImport = Import-CSV "$CSVFileLocation`\DW_AggregationStatus.csv"
	$ReportOutputDW += "<h3>DW Aggregation Status</h3>"
	$ReportOutputDW += "<table style='width: 300px;'><th>Schema Name</th><th>Aggregation Type</th><th>Time UTC - Next to Aggregate</th><th>Number of Outstanding Aggregations</th><th>Max Data Age in Days</th><th>Last Grooming Date & Time</th><th>Debug Level</th><th>Dataset ID</th>"
	foreach ($line in $DWAggregationStatusImport)
	{
		$ReportOutputDW += "<tr><td>" + $line[0].SchemaName + "</td><td>" + $line[0].AggregationType + "</td><td>" + $line[0].TimeUTC_NextToAggregate + "</td><td>" + $line[0].Count_OutstandingAggregations + "</td><td>" + $line[0].MaxDataAgeDays + "</td><td>" + $line[0].LastGroomingDateTime + "</td><td>" + $line[0].DebugLevel + "</td><td>" + $line[0].DataSetId + "</td></tr>"
	}
	$ReportOutputDW += "</table>"
	$ReportOutputDW += "</div>"
	
	#
	#
	# !!! END AGGREGATION - OPSMGR DW !!!
	#
	#
	
	#
	#
	# !!! DATABASE & TABLE SIZE PROP - OPSMGR DW !!!
	#
	#
	
	$DWSQLDBSizeImport = Import-CSV "$CSVFileLocation`\SQL_DBSize_DW.csv"
	$ReportOutputDW += "<div id='databaseSize' class='tabcontent'>"
	$ReportOutputDW += "<h3>Data Warehouse DB Size</h3>"
	$ReportOutputDW += "<table style='width: 300px;'><th>File Size (MB)</th><th>Space Used (MB)</th><th>Free Space (MB)</th><th>Auto Grow</th><th>Auth Growth MB Max </th><th>Name</th><th>Path</th><th>File ID</th>"
	foreach ($line in $DWSQLDBSizeImport)
	{
		$ReportOutputDW += "<tr><td>" + $line[0].'FileSize(MB)' + "</td><td>" + $line[0].'SpaceUsed(MB)' + "</td><td>" + $line[0].'FreeSpace(MB)' + "</td><td>" + $line[0].AutoGrow + "</td><td>" + $line[0].'AutoGrowthMB(MAX)' + "</td><td>" + $line[0].NAME + "</td><td>" + $line[0].PATH + "</td><td>" + $line[0].FILEID + "</td></tr>"
	}
	$ReportOutputDW += "</table>"
	
	
	$DWDatasetSpaceImport = Import-CSV "$CSVFileLocation`\DW_DatasetSpace.csv"
	$ReportOutputDW += "<h3>Data Warehouse Dataset Space</h3>"
	$ReportOutputDW += "<table style='width: 300px;'><th>Dataset Name</th><th>Aggregation Type Name</th><th>Max Data Age in Days</th><th>Size (GB)</th><th>Percent of DW</th>"
	foreach ($line in $DWDatasetSpaceImport)
	{
		$ReportOutputDW += "<tr><td>" + $line[0].DatasetName + "</td><td>" + $line[0].AggregationTypeName + "</td><td>" + $line[0].MaxDataAgeDays + "</td><td>" + $line[0].SizeGB + "</td><td>" + $line[0].PercentOfDW + "</td></tr>"
	}
	$ReportOutputDW += "</table>"
	$ReportOutputDW += "</div>"
	
	#
	#
	# !!! END DATABASE & TABLE SIZE PROP - OPGSMGR DW !!!
	#
	#
	
	#
	#
	# !!! RETENTION - OPSMGR DW !!!
	#
	#
	
	$DWRetentionImport = Import-CSV "$CSVFileLocation`\DW_Retention.csv"
	$ReportOutputDW += "<div id='retention' class='tabcontent'>"
	$ReportOutputDW += "<h3>Data Warehouse Retention</h3>"
	$ReportOutputDW += "<table style='width: 300px;'><th>Dataset Name</th><th>Aggregation Type</th><th>Retention Time in Days</th><th>Last Grooming Date/Time</th><th>Grooming Internal in Minutes</th>"
	foreach ($line in $DWRetentionImport)
	{
		$ReportOutputDW += "<tr><td>" + $line[0].'Dataset Name' + "</td><td>" + $line[0].'Agg Type 0=raw, 20=Hourly, 30=Daily' + "</td><td>" + $line[0].'Retention Time in Days' + "</td><td>" + $line[0].LastGroomingDateTime + "</td><td>" + $line[0].GroomingIntervalMinutes + "</td></tr>"
	}
	$ReportOutputDW += "</table>"
	$ReportOutputDW += "</div>"
	
	#
	#
	# !!! END RETENTION - OPSMGR DW!!!
	#
	#
	
	#
	#
	# !!! INDEX MAINT - OPSMGR DW !!!
	#
	#
	
	$DWIndexMaintImport = Import-CSV "$CSVFileLocation`\DW_Index_Maint.csv"
	$ReportOutputDW += "<div id='indexMaint' class='tabcontent'>"
	$ReportOutputDW += "<h3>Data Warehouse Index Maint</h3>"
	$ReportOutputDW += "<table style='width: 300px;'><th>Base Table Name</th><th>Optimization Start Date/Time</th><th>Optimization Duration in Seconds</th><th>Before Avg. Fragmentation in Percent</th><th>After Avg. Fragmentation in Percent</th><th>Optimization Method</th><th>Online Rebuild Last Performance Date/Time</th>"
	foreach ($line in $DWIndexMaintImport)
	{
		$ReportOutputDW += "<tr><td>" + $line[0].basetablename + "</td><td>" + $line[0].optimizationstartdatetime + "</td><td>" + $line[0].optimizationdurationseconds + "</td><td>" + $line[0].beforeavgfragmentationinpercent + "</td><td>" + $line[0].afteravgfragmentationinpercent + "</td><td>" + $line[0].optimizationmethod + "</td><td>" + $line[0].onlinerebuildlastperformeddatetime + "</td></tr>"
	}
	$ReportOutputDW += "</table>"
	$ReportOutputDW += "</div>"
	
	#
	#
	# !!! END INDEX MAINT - OPSMGR DW!!!
	#
	#
	
	#
	#
	# !!! LARGE TABLES - OPSMGR DW !!!
	#
	#
	
	$DWLargeTablesImport = Import-CSV "$CSVFileLocation`\SQL_LargeTables_DW.csv"
	$ReportOutputDW += "<div id='largeTables' class='tabcontent'>"
	$ReportOutputDW += "<h3>Data Warehouse Large Tables</h3>"
	$ReportOutputDW += "<table style='width: 300px;'><th>Table Name</th><th>Total Space (MB)</th><th>Data Size (MB)</th><th>Index Size (MB)</th><th>Unused (MB)</th><th>Row Count</th><th>l1</th><th>Schema</th>"
	foreach ($line in $DWLargeTablesImport)
	{
		$ReportOutputDW += "<tr><td>" + $line[0].Tablename + "</td><td>" + $line[0].'TotalSpace(MB)' + "</td><td>" + $line[0].'DataSize(MB)' + "</td><td>" + $line[0].'IndexSize(MB)' + "</td><td>" + $line[0].'Unused(MB)' + "</td><td>" + $line[0].Rowcount + "</td><td>" + $line[0].l1 + "</td><td>" + $line[0].Schema + "</td></tr>"
	}
	$ReportOutputDW += "</table>"
	$ReportOutputDW += "</div>"
	
	#
	#
	# !!! END LARGE TABLES - OPSMGR DW!!!
	#
	#
	
	#
	#
	# !!! STAGING/BACKUPS - OPSMGR DW !!!
	#
	#
	
	$DWStagingBacklogImport = Import-CSV "$CSVFileLocation`\DW_StagingBacklog.csv"
	$ReportOutputDW += "<div id='stagingBackups' class='tabcontent'>"
	$ReportOutputDW += "<h3>Data Warehouse Staging Backlog</h3>"
	$ReportOutputDW += "<table style='width: 300px;'><th>Table Name</th><th>Count</th>"
	foreach ($line in $DWStagingBacklogImport)
	{
		$ReportOutputDW += "<tr><td>" + $line[0].TableName + "</td><td>" + $line[0].Count + "</td></tr>"
	}
	$ReportOutputDW += "</table>"
	$ReportOutputDW += "</div>"
	
	#
	#
	# !!! END STAGING/BACKUPS - OPSMGR DW!!!
	#
	#
	
	
	$EndTime = Get-Date
	$TotalRunTime = $EndTime - $StartTime
	
	# Add the time to the Report
	$ReportOutput += "<br>"
	$ReportOutput += "<p>Total Script Run Time: $($TotalRunTime.hours) hrs $($TotalRunTime.minutes) min $($TotalRunTime.seconds) sec</p>"
	
	# Add the time to the DW Report
	$ReportOutputDW += "<br>"
	$ReportOutputDW += "<p>Total Script Run Time: $($TotalRunTime.hours) hrs $($TotalRunTime.minutes) min $($TotalRunTime.seconds) sec</p>"
	
	# Close the Body of the Report
	$ReportOutput += "</body>"
	$ReportOutputDW += "</body>"
	
	#Write-OutputToLog "Saving HTML Report to $ReportPath"
	#Write-OutputToLog "Saving DW HTML Report to $ReportPathDW"
	
	# Save the Final Report to a File
	ConvertTo-HTML -head $Head -body "$ReportOutput" | Out-File $ReportPath
	ConvertTo-HTML -head $HeadDW -body "$ReportOutputDW" | Out-File $ReportPathDW
	return $true
}