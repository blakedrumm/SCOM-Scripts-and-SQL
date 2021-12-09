#=================================================================================
#  Add and Remove Computers for a SCOM Group
#
#  Original Article: https://kevinholman.com/2021/09/29/explicit-group-membership-in-scom-using-powershell/
#
#  Author: Russ Slaten, as modified by Kevin Holman
#  v2.2
#=================================================================================
Param(
    [parameter(Mandatory=$true)]
    $ManagementServer,
    [parameter(Mandatory=$true)]
    $ManagementPackID,
    [parameter(Mandatory=$true)]
    $GroupID,
    $ComputersToAdd,
    $ComputersToRemove
    )


# Manual Testing section:
#=================================================================================
# $ManagementServer = "localhost"
# $ManagementPackID = "Demo.Test"
# $GroupID = "Demo.Test.Group"
# $ComputersToAdd = "SQL2019A.opsmgr.net,SQL2019B.opsmgr.net"
# $ComputersToRemove = ""
#=================================================================================


# Constants section:
#=================================================================================
$ScriptName = "AddRemoveComputersToSCOMGroup.ps1"
$EventID = "200"
#=================================================================================


# Starting Script section
#=================================================================================
# Gather the start time of the script
$StartTime = Get-Date
#Set variable to be used in logging events
$whoami = whoami
# Load MOMScript API
$momapi = New-Object -comObject MOM.ScriptAPI
#=================================================================================


# Begin Functions section
#=================================================================================
function GetSCOMManagementGroup
{
  param($ms)
  try
  {
    $mg = New-Object Microsoft.EnterpriseManagement.ManagementGroup($ms)
  }
  catch
  {
    Write-Host "Failed to Connect to SDK, Exiting:"$ms -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    exit
  }
  return $mg
}

function GetManagementPackToUpdate
{
  param($mg, $mpID)
  try
  {
    $mp = $mg.GetManagementPacks($mpID)[0]
    $vIncrement = $mp.Version.ToString().Split('.')
    $vIncrement[$vIncrement.Length - 1] = ([system.int32]::Parse($vIncrement[$vIncrement.Length - 1]) + 1).ToString()
    $mp.Version = ([string]::Join(".", $vIncrement))
  }
  catch
  {
    Write-Host "New MP:"$mpID
    $mp = CreateManagementPack -mpID $mpID
    $mg.ImportManagementPack($mp)
    $mp = GetManagementPack -mg $mg -mpID $mpID
  }
  return $mp
}

function GetManagementPack
{
  param ($mg, $mpID)
  try
  {
    $mp = $mg.GetManagementPacks($mpID)[0]
  }
  catch
  {
    Write-Host "Management Pack Not Found, Exiting:"$mpID -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    exit
  }
  return $mp
}

function CreateManagementPack
{
  param($mpID)
  $mpStore = New-Object Microsoft.EnterpriseManagement.Configuration.IO.ManagementPackFileStore
  $mp = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPack($mpID, $mpID, (New-Object Version(1, 0, 0)), $mpStore)
  return $mp
}

function GetReferenceAlias
{
  param($mp, $mpID)
  if ($mp.Name.ToUpper() -ne $mpID.ToUpper())
  {
    $bFound = $false
    foreach ($ref in $mp.References)
    {
      $s = ($ref.Value.ToString().Split("=")[1]).Split(",")[0]
      if ($s.ToUpper() -eq $mpID.ToUpper())
      {
        $bFound = $true
        $alias = $ref.Key
      }
    }
    if (!($bFound))
    {
      Write-Host "MP Reference Not Found, Exiting:"$mpID
      exit
    }
  }

  return $alias
}

function ValidateReference
{
  param($mg, $mp, $mpID)
  if ($mp.Name.ToUpper() -ne $mpID.ToUpper())
  {
    $bFound = $false
    foreach ($ref in $mp.References)
    {
      $s = ($ref.Value.ToString().Split("=")[1]).Split(",")[0]
      if ($s.ToUpper() -eq $mpID.ToUpper()) {$bFound = $true}
    }
    if (!($bFound))
    {
      Write-Host "New Reference:"$mpID
      $mp = CreateReference -mg $mg -mp $mp -mpID $mpID
    }
  }
  return $mp
}

function ValidateReferencesFromInstances
{
  param($mg, $mp, $ht)

  $htClasses = @{}
  foreach($instance in $ht.GetEnumerator())
  {
    try {$htClasses.Add($instance.Value.ToString(),$instance.Value)} catch {}
  }

  foreach($instance in $htClasses.GetEnumerator())
  {
    $classMP = GetClassMPFromMG -mg $mg -criteria ([string]::Format("Name = '{0}'", $instance.Value))
    $mp = ValidateReference -mg $mg -mp $mp -mpID $classMP.Name
  }

  return $mp
}

function CreateReference
{
  param($mg, $mp, $mpID)
  try
  {
    $newMP = $mg.GetManagementPacks($mpID)[0]
    if (!($newMP.sealed))
    {
      Write-Host "MP to reference is not sealed, cannot add reference to"$mpID -ForegroundColor Red
      Write-Host "Exiting" -ForegroundColor Red
      Write-Host $_.Exception.Message -ForegroundColor Yellow
      exit
    }
  }
  catch
  {
    Write-Host "Referenced MP Not Found in Management Group, Exiting:"$mpID -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    exit
  }

  $alias = $mpID.Replace(".","")
  $reference = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackReference($newMP)
  $mp.References.Add($alias, $reference)
  return $mp
}

function XMLEncode
{
  param([string]$s)
  $s = $s.Replace("&", "&amp;")
  $s = $s.Replace("<", "&lt;")
  $s = $s.Replace(">", "&gt;")
  $s = $s.Replace('"', "&quot;")
  $s = $s.Replace("'", "&apos;")
  return $s.ToString()
}

function ValidateMonitoringObjects
{
  param($guids, $mg)
  [hashtable]$ht = @{}
  $guids = $guids.Split(",")
  foreach ($guid in $guids)
  {
    $guid = $guid.Trim()
    try
    {
      $mo = $mg.GetMonitoringObject($guid)
      try {$ht.Add($guid, ($mo.FullName).Split(":")[0])} catch {}
    }
    catch
    {
      try {$ht.Add($guid, 'NOTFOUND')} catch {}
    }
  }
  return $ht
}

function GetClassMPFromMG
{
  param($mg, $criteria)
  $searchCriteria = new-object Microsoft.EnterpriseManagement.Configuration.MonitoringClassCriteria($criteria)
  $class = ($mg.GetMonitoringClasses($searchCriteria))[0]
  $mp = $class.GetManagementPack()
  return $mp
}

function GetRelationshipMPFromMG
{
  param($mg, $criteria)
  $searchCriteria = new-object Microsoft.EnterpriseManagement.Configuration.MonitoringRelationshipClassCriteria($criteria)
  $relationship = ($mg.GetMonitoringRelationshipClasses($searchCriteria))[0]
  $mp = $relationship.GetManagementPack()
  return $mp
}

function GetMPElementClass
{
  param($mg, $mp, $class)

  $criteria = ([string]::Format("Name = '{0}'", $class))
  $refMP = GetClassMPFromMG -mg $mg -criteria $criteria
  $alias = ""
  if ($refMP.Name -ne $mp.Name)
  {
    $alias = (GetReferenceAlias -mp $mp -mpID $refMP.Name) + "!"
  }
  $mpElement = '$MPElement[Name="{0}{1}"]$' -f $alias, $class

  return $mpElement
}

function GetMPElementRelationship
{
  param($mg, $mp, $class, $relationship)

  if (($relationship.ToString() -eq 'Microsoft.SystemCenter.ComputerGroupContainsComputer') -and ($class.ToString() -ne 'Microsoft.Windows.Computer'))
  {
    $mpName = 'System.Library'
    $relationship = 'System.ConfigItemContainsConfigItem'
  }
  else
  {
    $criteria = ([string]::Format("Name = '{0}'", $relationship))
    $mpName = (GetRelationshipMPFromMG -mg $mg -criteria $criteria).Name
  }

  $alias = ""
  if ($mpName -ne $mp.Name)
  {
    $alias = (GetReferenceAlias -mp $mp -mpID $mpName) + "!"
  }
  $mpElement = '$MPElement[Name="{0}{1}"]$' -f $alias, $relationship

  return $mpElement
}

function GetGroup
{
  param($mg, $mp, $groupID)
  $group = $mg.GetMonitoringClasses($groupID)[0]
  if ($group -eq $null)
  { 
    Write-Host "Group Not Found, Exiting:"$groupID -ForegroundColor Red
    exit
  }
  return $group
}

function ValidateGroup
{
  param($mg, $mp, $groupID)
  $group = $mg.GetMonitoringClasses($groupID)[0]
  if ($group -eq $null)
  {
    if (($groupID.Split(".").Count) -eq 1)
    {
      #Group name not part of MP namespace
      $groupName = $groupID
      $nameSpace = $mp.Name
    }
    else
    {
      if ($groupID.IndexOf($mp.Name) -eq -1)
      {
        #Group name not part of MP namespace
        $groupName = $groupID
        $nameSpace = $mp.Name
      }
      else
      {
        #Group name is part of MP namespace
        $groupName = ($groupID.Substring($mp.Name.Length)).Split(".")[-1]
        $nameSpace = $groupID.Substring(0, ($groupID.Length - ($groupName.Length) - 1))
      }
    }

    if ($groupID -eq ($nameSpace + "." + $groupName))
    {
      Write-Host "New Group:"$groupID
      $mp = CreateGroup -mg $mg -mp $mp -groupID $nameSpace -groupName $groupName
    }
    else
    {
      Write-Host "Error Creating Group, the GroupID passed does not match the GroupID built" -ForegroundColor Red
      Write-Host "Make sure the MP ID includes the namespace of the group and periods are used as separators" -ForegroundColor Red
      Write-Host "GroupID Passed:" $groupID -ForegroundColor Red
      Write-Host "MP ID:" $mp.Name -ForegroundColor Red
      Write-Host "Group Name Generated:" $groupName -ForegroundColor Red
      Write-Host "Group Namespace Generated:" $nameSpace -ForegroundColor Red
      exit
    }
  }
  return $mp
}

function CreateGroup
{
  param($mg, $mp, $groupID, $groupName)
  $mp = ValidateReference -mg $mg -mp $mp -mpID 'Microsoft.SystemCenter.InstanceGroup.Library'
  $mp = ValidateReference -mg $mg -mp $mp -mpID 'System.Library'
  $alias = GetReferenceAlias -mp $mp -mpID 'Microsoft.SystemCenter.InstanceGroup.Library'
  $systemAlias = GetReferenceAlias -mp $mp -mpID 'System.Library'
  $formula ='<MembershipRule Comment="Empty Membership Rule">' + ` 
            '<MonitoringClass>$MPElement[Name="' + $alias + `
            '!Microsoft.SystemCenter.InstanceGroup"]$</MonitoringClass>' + ` 
            '<RelationshipClass>$MPElement[Name="' + $alias + `
            '!Microsoft.SystemCenter.InstanceGroupContainsEntities"]$</RelationshipClass>' + ` 
            '<Expression>' + ` 
            '<SimpleExpression>' + ` 
            '<ValueExpression>' + ` 
            '<Property>$MPElement[Name="' + $systemAlias + `
            '!System.Entity"]/DisplayName$' + `
            '</Property>' + ` 
            '</ValueExpression>' + ` 
            '<Operator>Equal</Operator>' + ` 
            '<ValueExpression>' + ` 
            '<Value>False</Value>' + ` 
            '</ValueExpression>' + ` 
            '</SimpleExpression>' + ` 
            '</Expression>' + `
            '</MembershipRule>'

  $group = New-Object Microsoft.EnterpriseManagement.Monitoring.CustomMonitoringObjectGroup($groupID, $groupName, (XMLEncode -s $groupName), $formula)
  $mp.InsertCustomMonitoringObjectGroup($group)
  return $mp
}

function CreateEmptyMembershipRule
{
  param($mg, $mp, $relationship, $rules)

  if ($relationship -eq 'Microsoft.SystemCenter.InstanceGroupContainsEntities')
  {
    $class = 'Microsoft.SystemCenter.InstanceGroup'
  }
  else
  {
    $class = 'Microsoft.Windows.Computer'
  }
  
  $propertyName = '$MPElement[Name="{0}!System.Entity"]/DisplayName$' -f (GetReferenceAlias -mp $mp -mpID 'System.Library')

  $rulesNode = $rules.SelectSingleNode("/Node1/MembershipRules")
  $rule = $rules.CreateElement("MembershipRule")
  [void]$rule.SetAttribute("Comment", "Scripted Membership Rule")
  [void]$rulesNode.AppendChild($rule)

  $mClass = $rules.CreateElement("MonitoringClass")
  $mClass.InnerText = (GetMPElementClass -mg $mg -mp $mp -class $class)
  [void]$rulesNode.MembershipRule.AppendChild($mClass)

  $rClass = $rules.CreateElement("RelationshipClass")
  $rClass.InnerText = (GetMPElementRelationship -mg $mg -mp $mp -class $class -relationship $relationship)
  [void]$rulesNode.MembershipRule.AppendChild($rClass)

  $expression = $rules.CreateElement("Expression")
  [void]$rulesNode.MembershipRule.AppendChild($expression)

  $eNode = $rules.SelectSingleNode("/Node1/MembershipRules/MembershipRule/Expression")
  $simpleExpression = $rules.CreateElement("SimpleExpression")
  [void]$eNode.AppendChild($simpleExpression)

  $sNode = $rules.SelectSingleNode("/Node1/MembershipRules/MembershipRule/Expression/SimpleExpression")
  $valueExpression = $rules.CreateElement("ValueExpression")
  [void]$sNode.AppendChild($valueExpression)

  $vNode = $rules.SelectSingleNode("/Node1/MembershipRules/MembershipRule/Expression/SimpleExpression/ValueExpression")
  $property = $rules.CreateElement("Property")
  $property.InnerText = $propertyName
  [void]$vNode.AppendChild($property)

  $operator = $rules.CreateElement("Operator")
  $operator.InnerText = "Equal"
  [void]$sNode.AppendChild($operator)

  $valueExpression = $rules.CreateElement("ValueExpression")
  [void]$sNode.AppendChild($valueExpression)

  $vNode = $sNode.ChildNodes[2]
  $value = $rules.CreateElement("Value")
  $value.InnerText = "False"
  [void]$vNode.AppendChild($value)

  return $rules
}

function GetGroupDiscovery
{
  param($group)
  $groupDiscovery = $group.GetMonitoringDiscoveries()[0]
  if ($groupDiscovery -eq $null)
  {
    Write-Host "Group Discovery Not Found, Exiting" -ForegroundColor Red
    exit
  }
  return $groupDiscovery
}

function GetGroupMembershipRules
{
  param($config)
  $rulesStart = $config.IndexOf("<MembershipRules>")
  $rulesEnd = ($config.IndexOf("</MembershipRules>") + 18) - $rulesStart
  $rules = $config.Substring($rulesStart, $rulesEnd)
  $rules = '<Node1>' + $rules + '</Node1>'
  return $rules
}

function GetGroupInstances
{
  param($mg, $mp, $groupID)

  $group = GetGroup -mg $mg -mp $mp -groupID $groupID
  $discovery = GetGroupDiscovery -group $group
  $configuration = $discovery.DataSource.Configuration
  $rules = GetGroupMembershipRules -config $configuration
  $xPath = "/Node1/MembershipRules/MembershipRule/IncludeList/MonitoringObjectId"
  $guids = Select-Xml -Content $rules -XPath $xPath
  $existingInstances = @{}

  foreach($instance in $guids) 
  { 
    try {$existingInstances.Add($instance.ToString(),$instance)} catch {}
  }

  return $existingInstances
}

function UpdateGroup
{
  param($mg, $mp, $groupID, $instancesToAdd, $instancesToRemove)

  $existingInstances = GetGroupInstances -mg $mg -mp $mp -groupID $groupID

  if ($instancesToAdd -ne $null){$instancesToAdd = ValidateMonitoringObjects -guids $instancesToAdd -mg $mg}
  else {$instancesToAdd = @{}}

  $instancesToAdd = RemoveEntriesFromHashTable -guids $instancesToRemove -existingInstances $existingInstances -ht $instancesToAdd
  $mp = ValidateReferencesFromInstances -mg $mg -mp $mp -ht $instancesToAdd

  Write-Host "Update MP:"$mp.Name
  $mp.AcceptChanges()
  $mp = GetUpdatedGroupDiscovery -mg $mg -mp $mp -groupID $groupID -instancesToAdd $instancesToAdd -instancesToRemove $instancesToRemove

  return $mp
}

function GetUpdatedGroupDiscovery
{
  param($mg, $mp, $groupID, $instancesToAdd, $instancesToRemove)
  $group = GetGroup -mg $mg -mp $mp -groupID $groupID
  $discovery = GetGroupDiscovery -group $group
  $configuration = $discovery.DataSource.Configuration
  $relationship = GetRelationshipType -mg $mg -discovery $discovery
  [xml]$rules = GetGroupMembershipRules -config $configuration
  $exclusions = GetExclusions -rules $rules
  
  foreach($instance in $instancesToAdd.GetEnumerator())
  {
    $rules = AddGUIDToDiscovery -guid $instance.Key.ToString() -mg $mg -mp $mp -class $instance.Value.ToString() -rules $rules -exclusions $exclusions -relationship $relationship
  }

  if ($instancesToRemove -ne $null) 
  {
    foreach($instance in $instancesToRemove.Split(","))
    {
      Write-Host "Delete GUID:"$instance
      $rules = RemoveGUIDFromDiscovery -guid $instance.Trim() -rules $rules
    }
    
    $rules = DeleteEmptyIncludeNodes -mg $mg -mp $mp -rules $rules -relationship $relationship
  }
  
  $configuration = CleanUpDiscoveryConfiguration -configuration $configuration -rules $rules

  $discovery.Status = [Microsoft.EnterpriseManagement.Configuration.ManagementPackElementStatus]::PendingUpdate
  $discovery.DataSource.Configuration = $configuration.ToString().Trim()
  $mp = $discovery.GetManagementPack()
  Write-Host "Update MP:"$mp.Name
  [void]$mp.AcceptChanges()
  [void]$mg.RefreshMonitoringGroupMembers($mp)

  return $mp
}

function DeleteEmptyIncludeNodes
{
  param($mg, $mp, $relationship, $rules)
  $xPath = "/Node1/MembershipRules/MembershipRule"
  $nodes = $rules.SelectNodes($xPath)

  foreach ($node in $nodes)
  { 
    if (($node.IncludeList.ChildNodes.Count -eq 0) -and ($node.IncludeList.MonitoringObjectId.Count -eq 0))
    {
      if ((($node.SelectSingleNode("Expression")).Name -eq 'Expression') -and (($node.SelectSingleNode("IncludeList")).Name -eq 'IncludeList'))
      {
        [void]$node.RemoveChild($node.SelectSingleNode("IncludeList"))
      }
      elseif (($node.SelectSingleNode("IncludeList")).Name -eq 'IncludeList')
      {
        [void]$node.ParentNode.RemoveChild($node)
      }
    }
  }

  if ($rules.SelectNodes($xPath).Count -eq 0)
  {
    $rules = CreateEmptyMembershipRule -mg $mg -mp $mp -relationship $relationship -rules $rules
  }

  return $rules
}

function CleanUpDiscoveryConfiguration
{
  param($configuration, $rules)
  
  $newRules = ($rules.OuterXml).Replace("<Node1>", "").Replace("</Node1>", "")
  $i = $configuration.IndexOf("<MembershipRules>")
  [string]$configuration = $configuration.SubString(0, $i) + $newRules

  return $configuration
}

function GetRelationshipType
{
  param($mg, $discovery)
  $id = ($discovery.DiscoveryRelationshipCollection[0].TypeID).ToString().Split("=")[1]
  $criteria = ([string]::Format("Id = '{0}'", $id))
  $searchCriteria = new-object Microsoft.EnterpriseManagement.Configuration.MonitoringRelationshipClassCriteria($criteria)
  $relationship = ($mg.GetMonitoringRelationshipClasses($searchCriteria))[0]
  return $relationship
}

function GetExclusions
{
  param($rules)
  $xPath = "/Node1/MembershipRules/MembershipRule/ExcludeList/MonitoringObjectId"
  $guids = $rules.SelectNodes($xPath)
  $exclusions = @{}

  foreach($instance in $guids) 
  { 
    try {$exclusions.Add($instance.InnerText.ToString(),$instance.InnerText.ToString())} catch {}
  }

  return $exclusions
}

function AddGUIDToDiscovery
{
  param($mg, $mp, $guid, $class, $rules, $exclusions, $relationship)

  $guids = GetIncludedGUIDS -rules $rules
  
  if (!($guids.Contains($guid)))
  {
    $classes = GetMembershipRuleMonitoringClasses -rules $rules
    Write-Host "New GUID:"$guid":"$class
    if ($classes.ContainsKey($class.ToString()))
    {
      $rules = AddIncludeGUID -rules $rules -guid $guid -class $classes.Get_Item($class.ToString())
    }
    else
    {
      Write-Host "New Membership Rule:"$class
      $rules = CreateNewMembershipRule -mg $mg -mp $mp -rules $rules -guid $guid -class $class -exclusions $exclusions -relationship $relationship
    }
  }

  return $rules
}

function CreateNewMembershipRule
{
  param($mg, $mp, $guid, $class, $rules, $exclusions, $relationship)

  [xml]$xml = $rules
 
  $rulesNode = $xml.SelectSingleNode("/Node1/MembershipRules")
  $rule = $xml.CreateElement("MembershipRule")
  [void]$rule.SetAttribute("Comment", "Scripted Membership Rule")
  [void]$rulesNode.AppendChild($rule)

  $mClass = $xml.CreateElement("MonitoringClass")
  $mClass.InnerText = (GetMPElementClass -mg $mg -mp $mp -class $class)
  [void]$rulesNode.MembershipRule.AppendChild($mClass)

  $rClass = $xml.CreateElement("RelationshipClass")
  $rClass.InnerText = (GetMPElementRelationship -mg $mg -mp $mp -class $class -relationship $relationship)
  [void]$rulesNode.MembershipRule.AppendChild($rClass)

  $iList = $xml.CreateElement("IncludeList")
  [void]$rulesNode.MembershipRule.AppendChild($iList)

  $count = ($rulesNode.ChildNodes.Count) - 1
  $includeNode = $rulesNode.ChildNodes[$count].ChildNodes[2]
  $mObjectId = $xml.CreateElement("MonitoringObjectId")
  $mObjectId.InnerText = $guid.Trim()
  [void]$includeNode.AppendChild($mObjectId)

  if ($exclusions.Count -gt 0)
  {
    $eList = $xml.CreateElement("ExcludeList")
    [void]$rulesNode.MembershipRule.AppendChild($eList)

    foreach ($guid in $exclusions.GetEnumerator())
    {
      $excludeNode = $rulesNode.ChildNodes[$count].ChildNodes[3]
      $mObjectId = $xml.CreateElement("MonitoringObjectId")
      $mObjectId.InnerText = $guid.Value.ToString().Trim()
      [void]$excludeNode.AppendChild($mObjectId)
    }
  }
  
  return $xml
}

function AddIncludeGUID
{
  param($guid, $class, $rules)

  [xml]$xml = $rules
  $xPath = "/Node1/MembershipRules/MembershipRule"
  $ruleNodes = $xml.SelectNodes($xPath)

  foreach ($rule in $ruleNodes)
  {
    $className = ($rule.Get_InnerXML()).Split('"')[1]
    if ($className -eq $class)
    {
      $includeNode = $rule.SelectSingleNode("IncludeList")
      if ($includeNode -ne $null)
      {
        $child = $xml.CreateElement("MonitoringObjectId")
        $child.InnerText = $guid
        [void]$includeNode.AppendChild($child)
        break
      }      
    }
  }

  return $xml
}

function GetMembershipRuleMonitoringClasses
{
  param($rules)

  [xml]$xml = $rules
  $xPath = "/Node1/MembershipRules/MembershipRule"
  $ruleNodes = $xml.SelectNodes($xPath)
  $ht = @{}

  foreach ($rule in $ruleNodes)
  {
    $includeNode = $rule.SelectSingleNode("IncludeList")
    if ($includeNode -ne $null)
    {
      $fullPath = ($rule.Get_InnerXML()).Split('"')[1]
      $class = $fullPath.Split("!")[1]
      try { $ht.Add($class.ToString(), $fullPath) } catch {}
    }
  }

  return $ht
}

function GetIncludedGUIDs
{
  param($rules)
  $xPath = "/Node1/MembershipRules/MembershipRule/IncludeList/MonitoringObjectId"
  $guids = $guids = $rules.SelectNodes($xPath)
  $ht = @{}
  foreach ($g in $guids) { try { $ht.Add($g.InnerText.ToString(), $g.InnerText.ToString()) } catch {} }
  return $ht
}

function RemoveGUIDFromDiscovery
{
  param($guid, $rules)
  $xPath = "/Node1/MembershipRules/MembershipRule/IncludeList[MonitoringObjectId='{0}']/MonitoringObjectId" -f $guid.ToString()
  $guids = $rules.SelectNodes($xPath)

  foreach ($g in $guids)
  {
    if ($g.InnerText -eq $guid.ToString())
    {
      [void]$g.ParentNode.RemoveChild($g)
    }
  }

  return $rules
}

function RemoveEntriesFromHashTable
{
  param($guids, $existingInstances, $ht)
  if ($guids -ne $null)
  {
    $guids = $guids.Split(",")
    foreach ($guid in $guids)
    {
      $guid = $guid.Trim()
      try
      {
        $ht.Remove($guid)
      }
      catch {}
    }
  }

  foreach ($guid in $existingInstances.GetEnumerator())
  { 
    if ($ht.ContainsKey($guid.Key.ToString()))
    {
      $ht.Remove($guid.Key.ToString())
    }
  }
  return $ht
}
#=================================================================================
# End Functions section


# Begin MAIN script section
#=================================================================================
try { Import-Module OperationsManager } catch
{ 
  Write-Host "SCOM Module Not Found, Exiting" -ForegroundColor Red
  Write-Host $_.Exception.Message -ForegroundColor Yellow
  exit
}

# Log script event that we are starting
$Message = "`nScript is starting. `nRunning as ($whoami). `nManagement Server: ($ManagementServer). `nManagement Pack ID: ($ManagementPackID). `nGroup ID: ($GroupID). `nComputers to add: ($ComputersToAdd). `nComputers to remove: ($ComputersToRemove)."
Write-Host $Message
$momapi.LogScriptEvent($ScriptName,$EventID,0,$Message)

# Get all Windows Computers in the Management Group into a Hashtable
$Message = "`nGetting All Windows Computer objects from SCOM..."
Write-Host $Message
$momapi.LogScriptEvent($ScriptName,$EventID,0,$Message)
$WCArr = Get-SCOMClass -Name Microsoft.Windows.Computer | Get-SCOMClassInstance
$HashTable = @{}
FOREACH($WC in $WCarr){$HashTable.Add("$($WC.DisplayName)","$($WC.Id)")}

# Create an array of GUIDs for the objects to add and remove
$InstancesToAdd = @()
$InstancesToRemove = @()
[array]$ComputersToAddArr = $ComputersToAdd.Split(",")
FOREACH ($ComputerName in $ComputersToAddArr)
{
  $CompId = $HashTable.$ComputerName
  $InstancesToAdd += $CompId
}
[array]$ComputersToRemoveArr = $ComputersToRemove.Split(",")
FOREACH ($ComputerName in $ComputersToRemoveArr)
{
  $CompId = $HashTable.$ComputerName
  $InstancesToRemove += $CompId
}  

#Execute functions
$MG = GetSCOMManagementGroup -ms $ManagementServer
$MP = GetManagementPackToUpdate -mg $MG -mpID $ManagementPackID
$MP = ValidateGroup -mg $MG -mp $MP -groupID $GroupID
$MP = UpdateGroup -mg $MG -mp $MP -groupID $GroupID -instancesToAdd $InstancesToAdd -instancesToRemove $InstancesToRemove
#=================================================================================
# End MAIN script section


# End of script section
#=================================================================================
#Log an event for script ending and total execution time.
$EndTime = Get-Date
$ScriptTime = ($EndTime - $StartTime).TotalSeconds
$Message = "`nScript Completed. `nRuntime: ($ScriptTime) seconds."
Write-Host $Message
$momapi.LogScriptEvent($ScriptName,$EventID,0,$Message)
#=================================================================================
# End of script
