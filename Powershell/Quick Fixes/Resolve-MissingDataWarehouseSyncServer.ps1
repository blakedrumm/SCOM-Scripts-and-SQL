#Original Article: https://techcommunity.microsoft.com/t5/system-center-blog/kb-reports-are-not-populated-in-the-system-center-2012/ba-p/347232
#Populate these fields with Operational Database and Data Warehouse Information
#Note: change these values appropriately
$OperationalDbSqlServerInstance = "<OpsMgrDB server instance. If its default instance, only server name is required>"
$OperationalDbDatabaseName = "OperationsManager"
$DataWarehouseSqlServerInstance = "<OpsMgrDW server instance. If its default instance, only server name is required>"
$DataWarehouseDatabaseName = "OperationsManagerDW"
$ConsoleDirectory = "<OpsMgr Console Location by default it will be C:\Program Files\System Center 2012\Operations Manager\Console>"
##########################################
$dataWarehouseClass = get-SCOMClass -name:Microsoft.SystemCenter.DataWarehouse
$seviewerClass = get-SCOMClass -name:Microsoft.SystemCenter.OpsMgrDB.AppMonitoring
$advisorClass = get-SCOMClass -name:Microsoft.SystemCenter.DataWarehouse.AppMonitoring
$dwInstance = $dataWarehouseClass | Get-SCOMClassInstance
$seviewerInstance = $seviewerClass | Get-SCOMClassInstance
$advisorInstance = $advisorClass | Get-SCOMClassInstance
#Update the singleton property values
$dwInstance.Item($dataWarehouseClass.Item("MainDatabaseServerName")).Value = $DataWarehouseSqlServerInstance
$dwInstance.Item($dataWarehouseClass.Item("MainDatabaseName")).Value = $DataWarehouseDatabaseName
$seviewerInstance.Item($seviewerClass.item("MainDatabaseServerName")).Value = $OperationalDbSqlServerInstance
$seviewerInstance.Item($seviewerClass.item("MainDatabaseName")).Value = $OperationalDbDatabaseName
$advisorInstance.Item($advisorClass.item("MainDatabaseServerName")).Value = $DataWarehouseSqlServerInstance
$advisorInstance.Item($advisorClass.item("MainDatabaseName")).Value = $DataWarehouseDatabaseName
$dataWarehouseSynchronizationServiceClass = get-SCOMClass -name:Microsoft.SystemCenter.DataWarehouseSynchronizationService
#$dataWarehouseSynchronizationServiceInstance = $dataWarehouseSynchronizationServiceClass | Get-SCOMClassInstance
$mg = New-Object Microsoft.EnterpriseManagement.ManagementGroup -ArgumentList localhost
$dataWarehouseSynchronizationServiceInstance = New-Object Microsoft.EnterpriseManagement.Common.CreatableEnterpriseManagementObject -ArgumentList $mg, $dataWarehouseSynchronizationServiceClass
$dataWarehouseSynchronizationServiceInstance.Item($dataWarehouseSynchronizationServiceClass.Item("Id")).Value = [guid]::NewGuid().ToString()
#Add the properties to discovery data
$discoveryData = new-object Microsoft.EnterpriseManagement.ConnectorFramework.IncrementalDiscoveryData
$discoveryData.Add($dwInstance)
$discoveryData.Add($dataWarehouseSynchronizationServiceInstance)
$discoveryData.Add($seviewerInstance)
$discoveryData.Add($advisorInstance)
#$connector = Get-ScomConnector -name:"Operations Manager Internal Connector"
$momConnectorId = New-Object System.Guid("7431E155-3D9E-4724-895E-C03BA951A352")
$connector = $mg.ConnectorFramework.GetConnector($momConnectorId)
$discoveryData.Overwrite($connector)
#Update Global Settings. Needs to be done with PS V1 cmdlets
Add-pssnapin microsoft.enterprisemanagement.operationsmanager.client
cd $ConsoleDirectory
.\Microsoft.EnterpriseManagement.OperationsManager.ClientShell.NonInteractiveStartup.ps1
Set-DefaultSetting ManagementGroup\DataWarehouse\DataWarehouseDatabaseName $DataWarehouseDatabaseName
Set-DefaultSetting ManagementGroup\DataWarehouse\DataWarehouseServerName $DataWarehouseSqlServerInstance
