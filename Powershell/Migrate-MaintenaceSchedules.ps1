#Original Author: Mike Wallace (mike.wallace@microsoft.com)

# Export Maintenance Schedules from Old Management Group
Import-Module OperationsManager
$schedlist = Get-SCOMMaintenanceScheduleList
Foreach($sched in $schedlist){
    $schedp = Get-SCOMMaintenanceSchedule -id $sched.ScheduleId
    $monobjs = $schedp.MonitoringObjects
    foreach($monobj in $monobjs){
        $obj = Get-SCOMMonitoringObject -id $monobj
        if ($obj.FullName -match '.Group'){
            $monlist += $obj.DisplayName + ";"
            $grp = "yes"
        }
    }
    $name = $schedp.ScheduleName
    $rec = $schedp.Recursive
    $enable = $schedp.IsEnabled
    $astart = $schedp.ActiveStartTime
    $aend = $schedp.ActiveEndDate
    $dur = $schedp.Duration
    $freqtype = $schedp.ScheduleRecurrence.FreqType
    $freqinterval = $schedp.ScheduleRecurrence.FreqInterval
    if($monlist -ne $null){
        $str = $name + "," + $rec + "," + $enable + "," + $monlist + "," + $astart + "," + $aend + "," + $dur + "," + $freqtype + "," + $freqinterval
        $str >> MainSchedOut.txt
        $monlist = $null
    }
} 


# Import Maintenance Schedules into New Management Group
Import-Module OperationsManager
$maintscheds = Get-Content MainSchedOut.txt

foreach($maintsched in $maintscheds){
    $monobjids = @()
    $schedvs = $maintsched.split(",")
    $name = $schedvs[0]
    $rec = $schedvs[1]
    $enable = $schedvs[2]
    $monobjarr = $schedvs[3].split(";")
    foreach($monobj in $monobjarr){
        if($monobj -ne ""){
            
            $monitem = Get-SCOMMonitoringObject -DisplayName $monobj
            $monobjid = $monitem.Id.guid
            if($monobjid -eq $null){
                $str = $monobj + " Group not found in this management group, moving to next"
                $str
            }else{
                $monobjids += $monobjid
            }
        }
    }
    $monobjs = $monobjids
    $monobjids = $null
    if(!($monobjs -match "-")){
        $str = "For Maint Sched " + $name + " No Groups Found in this Management Group, Skipping Maintenance Schedule Creation"
        $str
    }else{
        $astart = $schedvs[4]
        $aend = $schedvs[5]
        $dur = $schedvs[6]
        $freqtype = $schedvs[7]
        $freqinterval = [int]$schedvs[8]
        $str = "Creating Maint Schedule: " + $name
        $str
        New-SCOMMaintenanceSchedule -Name $name -Recursive $true -Enabled $true -MonitoringObjects $monobjs -ActiveStartTime $astart -ActiveEndDate $aend -Duration $dur -ReasonCode "PlannedOther" -Comments "Created from Powershell" -FreqType $freqtype -FreqInterval $freqinterval
    }
} 
