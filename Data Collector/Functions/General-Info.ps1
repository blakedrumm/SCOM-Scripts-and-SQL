function Get-SCOMGeneralInfo
{
	param
	(
		[Parameter(Position = 1)]
		[array]$Servers
	)

    #FREE SPACE

    # Name the server where this needs to be run
    $ServerName = 'localhost'

    # Check Total Capacity of the Drive
    $TCapacity =
    @{
        Expression = { "{0:n2}" -f ($_.Capacity / 1GB) };
        Name       = 'Total Capacity (GB)';
    }
 
    # Freespace to be displayed in GB
    $Freespace =
    @{
        Expression = { "{0:n2}" -f ($_.FreeSpace / 1GB) };
        Name       = 'Free Space (GB)';
    }
 
    # Percentage value of the free space
    $PercentFree =
    @{
        Expression = { [int]($_.Freespace * 100 / $_.Capacity) };
        Name       = 'Free (%)'
    }
 
    # Calculation
    $DiskFree = Get-WmiObject -namespace "root/cimv2" -computername $ServerName -query "SELECT Name, Capacity, FreeSpace FROM Win32_Volume WHERE Capacity > 0 and (DriveType = 2 OR DriveType = 3)" | Select-Object -Property Name, $TCapacity, $Freespace, $PercentFree  | Sort-Object 'Free (%)' -Descending
    $DiskFree = $DiskFree | % { "Drive: " + $_.Name + "`nTotal Capacity: " + $_.'Total Capacity (GB)' + "GB`n" + "Free Space: " + $_.'Free Space (GB)' + "GB`n" + "Free (%): " + $_.'Free (%)' + "`n" } | Out-String
	$global:setuplocation = get-itemproperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup" | Select-Object * -exclude PSPath, PSParentPath, PSChildName, PSProvider, PSDrive
    $location = $setuplocation.InstallDirectory
	Write-Host "-" -NoNewline -ForegroundColor Green
	$ServerVersionSwitch = switch ($setuplocation.ServerVersion)
	{
    <# 
       System Center Operations Manager 2019 Versions
    #>
		'10.19.10407.0' { "Update Rollup 2 for SCOM 2019 / 2020 August 4" }
		'10.19.10349.0' { "SCOM 2019 Hotfix for Alert Management / 2020 April 1" }
		'10.19.10311.0' { "Update Rollup 1 for SCOM 2019 / 2020 February 4" }
		'10.19.10050.0' { "SCOM 2019 / 2019 March 14" }
    <# 
       System Center Operations Manager Semi-Annual Channel (SAC) Versions
    #>
		'7.3.13261.0' { "Version 1807 / 2018 July 24" }
		'7.3.13142.0' { "Version 1801 / 2018 February 8" }
		'7.3.13040.0' { "Version 1711 (preview) / 2017 November 9" }
    <# 
       System Center Operations Manager 2016 Versions
    #>
		'7.2.12265.0' { "SCOM 2016 Update Rollup 9 / 2020 March 24" }
		'7.2.12213.0' { "SCOM 2016 Update Rollup 8 / 2019 September 24" }
		'7.2.12150.0' { "SCOM 2016 Update Rollup 7 / 2019 April 23" }
		'7.2.12066.0' { "SCOM 2016 Update Rollup 6 / 2018 October 23" }
		'7.2.12016.0' { "SCOM 2016 Update Rollup 5 / 2018 April 25" }
		'7.2.11938.0' { "SCOM 2016 Update Rollup 4 / 2017 October 23" }
		'7.2.11878.0' { "SCOM 2016 Update Rollup 3 / 2017 May 23" }
		'7.2.11822.0' { "SCOM 2016 Update Rollup 2 / 2017 February 22" }
		'7.2.11759.0' { "SCOM 2016 Update Rollup 1 / 2016 October 13" }
		'7.2.11719.0' { "SCOM 2016 RTM / 2016 September 26" }
		'7.2.11469.0' { "SCOM 2016 Technical Preview 5 / 2016 April" }
		'7.2.11257.0' { "SCOM 2016 Technical Preview 4 / 2016 July" }
		'7.2.11125.0' { "SCOM 2016 Technical Preview 3 / 2016 July" }
		'7.2.11097.0' { "SCOM 2016 Technical Preview 2 / 2016 June" }
		'7.2.10015.0' { "SCOM 2016 Update Rollup 2 / 2017 February 22" }
   <# 
      System Center Operations Manager 2012 R2 Versions
   #>
		'7.1.10226.1387' { "SCOM 2012 R2 Update Rollup 14 / 2017 November 28" }
		'7.1.10226.1360' { "SCOM 2012 R2 Update Rollup 13 / 2017 May 23" }
		'7.1.10226.1304' { "SCOM 2012 R2 Update Rollup 12 / 2017 January 24" }
		'7.1.10226.1239' { "SCOM 2012 R2 Update Rollup 11 / 2016 August 30" }
		'7.1.10226.1177' { "SCOM 2012 R2 Update Rollup 9 / 2016 January 26" }
		'7.1.10226.1118' { "SCOM 2012 R2 Update Rollup 8 / 2015 October 27" }
		'7.1.10226.1090' { "SCOM 2012 R2 Update Rollup 7 / 2015 August 11" }
		'7.1.10226.1064' { "SCOM 2012 R2 Update Rollup 6 / 2015 April 28" }
		'7.1.10226.1052' { "SCOM 2012 R2 Update Rollup 5 / 2015 February 10" }
		'7.1.10226.1046' { "SCOM 2012 R2 Update Rollup 4 / 2014 October 28" }
		'7.1.10226.1037' { "SCOM 2012 R2 Update Rollup 3 / 2014 July 29" }
		'7.1.10226.1015' { "SCOM 2012 R2 Update Rollup 2 / 2014 April 23" }
		'7.1.10226.1011' { "SCOM 2012 R2 Update Rollup 1 / 2014 January 27" }
		'7.1.10226.0' { "SCOM 2012 R2 RTM / 2013 October 22" }
   <# 
      System Center Operations Manager 2012 SP1 Versions
   #>
		'7.0.9538.0' { "SCOM 2012 SP1" }
		'7.0.9538.1005' { "SCOM 2012 SP1 Update Rollup 1 / 2013 January 8" }
		'7.0.9538.1047' { "SCOM 2012 SP1 Update Rollup 2 / 2013 April 08" }
		'7.0.9538.1069' { "SCOM 2012 SP1 Update Rollup 3 / 2013 July 23" }
		'7.0.9538.1084' { "SCOM 2012 SP1 Update Rollup 4 / 2013 October 21" }
		'7.0.9538.1106' { "SCOM 2012 SP1 Update Rollup 5 / 2014 January 27" }
		'7.0.9538.1109' { "SCOM 2012 SP1 Update Rollup 6 / 2014 April 23" }
		'7.0.9538.1117' { "SCOM 2012 SP1 Update Rollup 7 / 2014 July 29" }
		'7.0.9538.1123' { "SCOM 2012 SP1 Update Rollup 8 / 2014 October 28" }
		'7.0.9538.1126' { "SCOM 2012 SP1 Update Rollup 9 / 2015 February 10" }
		'7.0.9538.1136' { "SCOM 2012 SP1 Update Rollup 10 / 2015 August 11" }
   <# 
      System Center Operations Manager 2012 Versions
   #>
		'7.0.8289.0' { "SCOM 2012 Beta / 2011 July" }
		'7.0.8560.0' { "SCOM 2012 RTM" }
		'7.0.8560.1021' { "SCOM 2012 Update Rollup 1 / 2012 May 07" }
		'7.0.8560.1027' { "SCOM 2012 Update Rollup 2 / 2012 July 24" }
		'7.0.8560.1036' { "SCOM 2012 Update Rollup 3 / 2012 October 08" }
		'7.0.8560.1048' { "SCOM 2012 Update Rollup 8 / 2015 August 11" }
	}
	$setuplocation.ServerVersion = $ServerVersionSwitch + " (" + $setuplocation.ServerVersion + ")"
	
	$serverdll = Get-Item "$location`MOMAgentManagement.dll" | foreach-object { "{0}" -f [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_).FileVersion }
	$ServerVersionDLLSwitch = switch ($serverdll)
	{
    <# 
       System Center Operations Manager 2019 Versions
    #>
		'10.19.10407.0' { "Update Rollup 2 for SCOM 2019 / 2020 August 4" }
		'10.19.10349.0' { "SCOM 2019 Hotfix for Alert Management / 2020 April 1" }
		'10.19.10311.0' { "Update Rollup 1 for SCOM 2019 / 2020 February 4" }
		'10.19.10050.0' { "SCOM 2019 / 2019 March 14" }
    <# 
       System Center Operations Manager Semi-Annual Channel (SAC) Versions
    #>
		'7.3.13261.0' { "Version 1807 / 2018 July 24" }
		'7.3.13142.0' { "Version 1801 / 2018 February 8" }
		'7.3.13040.0' { "Version 1711 (preview) / 2017 November 9" }
    <# 
       System Center Operations Manager 2016 Versions
    #>
		'7.2.12265.0' { "SCOM 2016 Update Rollup 9 / 2020 March 24" }
		'7.2.12213.0' { "SCOM 2016 Update Rollup 8 / 2019 September 24" }
		'7.2.12150.0' { "SCOM 2016 Update Rollup 7 / 2019 April 23" }
		'7.2.12066.0' { "SCOM 2016 Update Rollup 6 / 2018 October 23" }
		'7.2.12016.0' { "SCOM 2016 Update Rollup 5 / 2018 April 25" }
		'7.2.11938.0' { "SCOM 2016 Update Rollup 4 / 2017 October 23" }
		'7.2.11878.0' { "SCOM 2016 Update Rollup 3 / 2017 May 23" }
		'7.2.11822.0' { "SCOM 2016 Update Rollup 2 / 2017 February 22" }
		'7.2.11759.0' { "SCOM 2016 Update Rollup 1 / 2016 October 13" }
		'7.2.11719.0' { "SCOM 2016 RTM / 2016 September 26" }
		'7.2.11469.0' { "SCOM 2016 Technical Preview 5 / 2016 April" }
		'7.2.11257.0' { "SCOM 2016 Technical Preview 4 / 2016 July" }
		'7.2.11125.0' { "SCOM 2016 Technical Preview 3 / 2016 July" }
		'7.2.11097.0' { "SCOM 2016 Technical Preview 2 / 2016 June" }
		'7.2.10015.0' { "SCOM 2016 Update Rollup 2 / 2017 February 22" }
   <# 
      System Center Operations Manager 2012 R2 Versions
   #>
		'7.1.10226.1387' { "SCOM 2012 R2 Update Rollup 14 / 2017 November 28" }
		'7.1.10226.1360' { "SCOM 2012 R2 Update Rollup 13 / 2017 May 23" }
		'7.1.10226.1304' { "SCOM 2012 R2 Update Rollup 12 / 2017 January 24" }
		'7.1.10226.1239' { "SCOM 2012 R2 Update Rollup 11 / 2016 August 30" }
		'7.1.10226.1177' { "SCOM 2012 R2 Update Rollup 9 / 2016 January 26" }
		'7.1.10226.1118' { "SCOM 2012 R2 Update Rollup 8 / 2015 October 27" }
		'7.1.10226.1090' { "SCOM 2012 R2 Update Rollup 7 / 2015 August 11" }
		'7.1.10226.1064' { "SCOM 2012 R2 Update Rollup 6 / 2015 April 28" }
		'7.1.10226.1052' { "SCOM 2012 R2 Update Rollup 5 / 2015 February 10" }
		'7.1.10226.1046' { "SCOM 2012 R2 Update Rollup 4 / 2014 October 28" }
		'7.1.10226.1037' { "SCOM 2012 R2 Update Rollup 3 / 2014 July 29" }
		'7.1.10226.1015' { "SCOM 2012 R2 Update Rollup 2 / 2014 April 23" }
		'7.1.10226.1011' { "SCOM 2012 R2 Update Rollup 1 / 2014 January 27" }
		'7.1.10226.0' { "SCOM 2012 R2 RTM / 2013 October 22" }
   <# 
      System Center Operations Manager 2012 SP1 Versions
   #>
		'7.0.9538.0' { "SCOM 2012 SP1" }
		'7.0.9538.1005' { "SCOM 2012 SP1 Update Rollup 1 / 2013 January 8" }
		'7.0.9538.1047' { "SCOM 2012 SP1 Update Rollup 2 / 2013 April 08" }
		'7.0.9538.1069' { "SCOM 2012 SP1 Update Rollup 3 / 2013 July 23" }
		'7.0.9538.1084' { "SCOM 2012 SP1 Update Rollup 4 / 2013 October 21" }
		'7.0.9538.1106' { "SCOM 2012 SP1 Update Rollup 5 / 2014 January 27" }
		'7.0.9538.1109' { "SCOM 2012 SP1 Update Rollup 6 / 2014 April 23" }
		'7.0.9538.1117' { "SCOM 2012 SP1 Update Rollup 7 / 2014 July 29" }
		'7.0.9538.1123' { "SCOM 2012 SP1 Update Rollup 8 / 2014 October 28" }
		'7.0.9538.1126' { "SCOM 2012 SP1 Update Rollup 9 / 2015 February 10" }
		'7.0.9538.1136' { "SCOM 2012 SP1 Update Rollup 10 / 2015 August 11" }
   <# 
      System Center Operations Manager 2012 Versions
   #>
		'7.0.8289.0' { "SCOM 2012 Beta / 2011 July" }
		'7.0.8560.0' { "SCOM 2012 RTM" }
		'7.0.8560.1021' { "SCOM 2012 Update Rollup 1 / 2012 May 07" }
		'7.0.8560.1027' { "SCOM 2012 Update Rollup 2 / 2012 July 24" }
		'7.0.8560.1036' { "SCOM 2012 Update Rollup 3 / 2012 October 08" }
		'7.0.8560.1048' { "SCOM 2012 Update Rollup 8 / 2015 August 11" }
	}
	$ServerVersionDLL = $ServerVersionDLLSwitch + " (" + $serverdll + ")"
	
	$UIVersionSwitch = switch ($setuplocation.UIVersion)
	{
    <# 
       System Center Operations Manager 2019 Versions
    #>
		'10.19.10407.0' { "Update Rollup 2 for SCOM 2019 / 2020 August 4" }
		'10.19.10349.0' { "SCOM 2019 Hotfix for Alert Management / 2020 April 1" }
		'10.19.10311.0' { "Update Rollup 1 for SCOM 2019 / 2020 February 4" }
		'10.19.10050.0' { "SCOM 2019 / 2019 March 14" }
    <# 
       System Center Operations Manager Semi-Annual Channel (SAC) Versions
    #>
		'7.3.13261.0' { "Version 1807 / 2018 July 24" }
		'7.3.13142.0' { "Version 1801 / 2018 February 8" }
		'7.3.13040.0' { "Version 1711 (preview) / 2017 November 9" }
    <# 
       System Center Operations Manager 2016 Versions
    #>
		'7.2.12265.0' { "SCOM 2016 Update Rollup 9 / 2020 March 24" }
		'7.2.12213.0' { "SCOM 2016 Update Rollup 8 / 2019 September 24" }
		'7.2.12150.0' { "SCOM 2016 Update Rollup 7 / 2019 April 23" }
		'7.2.12066.0' { "SCOM 2016 Update Rollup 6 / 2018 October 23" }
		'7.2.12016.0' { "SCOM 2016 Update Rollup 5 / 2018 April 25" }
		'7.2.11938.0' { "SCOM 2016 Update Rollup 4 / 2017 October 23" }
		'7.2.11878.0' { "SCOM 2016 Update Rollup 3 / 2017 May 23" }
		'7.2.11822.0' { "SCOM 2016 Update Rollup 2 / 2017 February 22" }
		'7.2.11759.0' { "SCOM 2016 Update Rollup 1 / 2016 October 13" }
		'7.2.11719.0' { "SCOM 2016 RTM / 2016 September 26" }
		'7.2.11469.0' { "SCOM 2016 Technical Preview 5 / 2016 April" }
		'7.2.11257.0' { "SCOM 2016 Technical Preview 4 / 2016 July" }
		'7.2.11125.0' { "SCOM 2016 Technical Preview 3 / 2016 July" }
		'7.2.11097.0' { "SCOM 2016 Technical Preview 2 / 2016 June" }
		'7.2.10015.0' { "SCOM 2016 Update Rollup 2 / 2017 February 22" }
   <# 
      System Center Operations Manager 2012 R2 Versions
   #>
		'7.1.10226.1387' { "SCOM 2012 R2 Update Rollup 14 / 2017 November 28" }
		'7.1.10226.1360' { "SCOM 2012 R2 Update Rollup 13 / 2017 May 23" }
		'7.1.10226.1304' { "SCOM 2012 R2 Update Rollup 12 / 2017 January 24" }
		'7.1.10226.1239' { "SCOM 2012 R2 Update Rollup 11 / 2016 August 30" }
		'7.1.10226.1177' { "SCOM 2012 R2 Update Rollup 9 / 2016 January 26" }
		'7.1.10226.1118' { "SCOM 2012 R2 Update Rollup 8 / 2015 October 27" }
		'7.1.10226.1090' { "SCOM 2012 R2 Update Rollup 7 / 2015 August 11" }
		'7.1.10226.1064' { "SCOM 2012 R2 Update Rollup 6 / 2015 April 28" }
		'7.1.10226.1052' { "SCOM 2012 R2 Update Rollup 5 / 2015 February 10" }
		'7.1.10226.1046' { "SCOM 2012 R2 Update Rollup 4 / 2014 October 28" }
		'7.1.10226.1037' { "SCOM 2012 R2 Update Rollup 3 / 2014 July 29" }
		'7.1.10226.1015' { "SCOM 2012 R2 Update Rollup 2 / 2014 April 23" }
		'7.1.10226.1011' { "SCOM 2012 R2 Update Rollup 1 / 2014 January 27" }
		'7.1.10226.0' { "SCOM 2012 R2 RTM / 2013 October 22" }
   <# 
      System Center Operations Manager 2012 SP1 Versions
   #>
		'7.0.9538.0' { "SCOM 2012 SP1" }
		'7.0.9538.1005' { "SCOM 2012 SP1 Update Rollup 1 / 2013 January 8" }
		'7.0.9538.1047' { "SCOM 2012 SP1 Update Rollup 2 / 2013 April 08" }
		'7.0.9538.1069' { "SCOM 2012 SP1 Update Rollup 3 / 2013 July 23" }
		'7.0.9538.1084' { "SCOM 2012 SP1 Update Rollup 4 / 2013 October 21" }
		'7.0.9538.1106' { "SCOM 2012 SP1 Update Rollup 5 / 2014 January 27" }
		'7.0.9538.1109' { "SCOM 2012 SP1 Update Rollup 6 / 2014 April 23" }
		'7.0.9538.1117' { "SCOM 2012 SP1 Update Rollup 7 / 2014 July 29" }
		'7.0.9538.1123' { "SCOM 2012 SP1 Update Rollup 8 / 2014 October 28" }
		'7.0.9538.1126' { "SCOM 2012 SP1 Update Rollup 9 / 2015 February 10" }
		'7.0.9538.1136' { "SCOM 2012 SP1 Update Rollup 10 / 2015 August 11" }
   <# 
      System Center Operations Manager 2012 Versions
   #>
		'7.0.8289.0' { "SCOM 2012 Beta / 2011 July" }
		'7.0.8560.0' { "SCOM 2012 RTM" }
		'7.0.8560.1021' { "SCOM 2012 Update Rollup 1 / 2012 May 07" }
		'7.0.8560.1027' { "SCOM 2012 Update Rollup 2 / 2012 July 24" }
		'7.0.8560.1036' { "SCOM 2012 Update Rollup 3 / 2012 October 08" }
		'7.0.8560.1048' { "SCOM 2012 Update Rollup 8 / 2015 August 11" }
	}
	$setuplocation.UIVersion = $UIVersionSwitch + " (" + $setuplocation.UIVersion + ")"
	
	$UIDLL = Get-Item "$location`..\Console\Microsoft.EnterpriseManagement.Monitoring.Console.exe" | foreach-object { "{0}" -f [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_).FileVersion }
	$UIVersionDLLSwitch = switch ($UIDLL)
	{
    <# 
       System Center Operations Manager 2019 Versions
    #>
		'10.19.10407.0' { "Update Rollup 2 for SCOM 2019 / 2020 August 4" }
		'10.19.10349.0' { "SCOM 2019 Hotfix for Alert Management / 2020 April 1" }
		'10.19.10311.0' { "Update Rollup 1 for SCOM 2019 / 2020 February 4" }
		'10.19.10050.0' { "SCOM 2019 / 2019 March 14" }
    <# 
       System Center Operations Manager Semi-Annual Channel (SAC) Versions
    #>
		'7.3.13261.0' { "Version 1807 / 2018 July 24" }
		'7.3.13142.0' { "Version 1801 / 2018 February 8" }
		'7.3.13040.0' { "Version 1711 (preview) / 2017 November 9" }
    <# 
       System Center Operations Manager 2016 Versions
    #>
		'7.2.12265.0' { "SCOM 2016 Update Rollup 9 / 2020 March 24" }
		'7.2.12213.0' { "SCOM 2016 Update Rollup 8 / 2019 September 24" }
		'7.2.12150.0' { "SCOM 2016 Update Rollup 7 / 2019 April 23" }
		'7.2.12066.0' { "SCOM 2016 Update Rollup 6 / 2018 October 23" }
		'7.2.12016.0' { "SCOM 2016 Update Rollup 5 / 2018 April 25" }
		'7.2.11938.0' { "SCOM 2016 Update Rollup 4 / 2017 October 23" }
		'7.2.11878.0' { "SCOM 2016 Update Rollup 3 / 2017 May 23" }
		'7.2.11822.0' { "SCOM 2016 Update Rollup 2 / 2017 February 22" }
		'7.2.11759.0' { "SCOM 2016 Update Rollup 1 / 2016 October 13" }
		'7.2.11719.0' { "SCOM 2016 RTM / 2016 September 26" }
		'7.2.11469.0' { "SCOM 2016 Technical Preview 5 / 2016 April" }
		'7.2.11257.0' { "SCOM 2016 Technical Preview 4 / 2016 July" }
		'7.2.11125.0' { "SCOM 2016 Technical Preview 3 / 2016 July" }
		'7.2.11097.0' { "SCOM 2016 Technical Preview 2 / 2016 June" }
		'7.2.10015.0' { "SCOM 2016 Update Rollup 2 / 2017 February 22" }
   <# 
      System Center Operations Manager 2012 R2 Versions
   #>
		'7.1.10226.1387' { "SCOM 2012 R2 Update Rollup 14 / 2017 November 28" }
		'7.1.10226.1360' { "SCOM 2012 R2 Update Rollup 13 / 2017 May 23" }
		'7.1.10226.1304' { "SCOM 2012 R2 Update Rollup 12 / 2017 January 24" }
		'7.1.10226.1239' { "SCOM 2012 R2 Update Rollup 11 / 2016 August 30" }
		'7.1.10226.1177' { "SCOM 2012 R2 Update Rollup 9 / 2016 January 26" }
		'7.1.10226.1118' { "SCOM 2012 R2 Update Rollup 8 / 2015 October 27" }
		'7.1.10226.1090' { "SCOM 2012 R2 Update Rollup 7 / 2015 August 11" }
		'7.1.10226.1064' { "SCOM 2012 R2 Update Rollup 6 / 2015 April 28" }
		'7.1.10226.1052' { "SCOM 2012 R2 Update Rollup 5 / 2015 February 10" }
		'7.1.10226.1046' { "SCOM 2012 R2 Update Rollup 4 / 2014 October 28" }
		'7.1.10226.1037' { "SCOM 2012 R2 Update Rollup 3 / 2014 July 29" }
		'7.1.10226.1015' { "SCOM 2012 R2 Update Rollup 2 / 2014 April 23" }
		'7.1.10226.1011' { "SCOM 2012 R2 Update Rollup 1 / 2014 January 27" }
		'7.1.10226.0' { "SCOM 2012 R2 RTM / 2013 October 22" }
   <# 
      System Center Operations Manager 2012 SP1 Versions
   #>
		'7.0.9538.0' { "SCOM 2012 SP1" }
		'7.0.9538.1005' { "SCOM 2012 SP1 Update Rollup 1 / 2013 January 8" }
		'7.0.9538.1047' { "SCOM 2012 SP1 Update Rollup 2 / 2013 April 08" }
		'7.0.9538.1069' { "SCOM 2012 SP1 Update Rollup 3 / 2013 July 23" }
		'7.0.9538.1084' { "SCOM 2012 SP1 Update Rollup 4 / 2013 October 21" }
		'7.0.9538.1106' { "SCOM 2012 SP1 Update Rollup 5 / 2014 January 27" }
		'7.0.9538.1109' { "SCOM 2012 SP1 Update Rollup 6 / 2014 April 23" }
		'7.0.9538.1117' { "SCOM 2012 SP1 Update Rollup 7 / 2014 July 29" }
		'7.0.9538.1123' { "SCOM 2012 SP1 Update Rollup 8 / 2014 October 28" }
		'7.0.9538.1126' { "SCOM 2012 SP1 Update Rollup 9 / 2015 February 10" }
		'7.0.9538.1136' { "SCOM 2012 SP1 Update Rollup 10 / 2015 August 11" }
   <# 
      System Center Operations Manager 2012 Versions
   #>
		'7.0.8289.0' { "SCOM 2012 Beta / 2011 July" }
		'7.0.8560.0' { "SCOM 2012 RTM" }
		'7.0.8560.1021' { "SCOM 2012 Update Rollup 1 / 2012 May 07" }
		'7.0.8560.1027' { "SCOM 2012 Update Rollup 2 / 2012 July 24" }
		'7.0.8560.1036' { "SCOM 2012 Update Rollup 3 / 2012 October 08" }
		'7.0.8560.1048' { "SCOM 2012 Update Rollup 8 / 2015 August 11" }
	}
	$UIVersionDLL = $UIVersionDLLSwitch + " (" + $UIDLL + ")"
	
	$WebConsoleDLL = Get-Item "$location`..\WebConsole\WebHost\bin\Microsoft.Mom.Common.dll" -ErrorAction SilentlyContinue | foreach-object { "{0}`t{1}" -f [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_).FileVersion }
	$WebConsoleDLLSwitch = switch ($WebConsoleDLL)
	{
    <# 
       System Center Operations Manager 2019 Versions
    #>
		'10.19.10407.0' { "Update Rollup 2 for SCOM 2019 / 2020 August 4" }
		'10.19.10349.0' { "SCOM 2019 Hotfix for Alert Management / 2020 April 1" }
		'10.19.10311.0' { "Update Rollup 1 for SCOM 2019 / 2020 February 4" }
		'10.19.10050.0' { "SCOM 2019 / 2019 March 14" }
    <# 
       System Center Operations Manager Semi-Annual Channel (SAC) Versions
    #>
		'7.3.13261.0' { "Version 1807 / 2018 July 24" }
		'7.3.13142.0' { "Version 1801 / 2018 February 8" }
		'7.3.13040.0' { "Version 1711 (preview) / 2017 November 9" }
    <# 
       System Center Operations Manager 2016 Versions
    #>
		'7.2.12265.0' { "SCOM 2016 Update Rollup 9 / 2020 March 24" }
		'7.2.12213.0' { "SCOM 2016 Update Rollup 8 / 2019 September 24" }
		'7.2.12150.0' { "SCOM 2016 Update Rollup 7 / 2019 April 23" }
		'7.2.12066.0' { "SCOM 2016 Update Rollup 6 / 2018 October 23" }
		'7.2.12016.0' { "SCOM 2016 Update Rollup 5 / 2018 April 25" }
		'7.2.11938.0' { "SCOM 2016 Update Rollup 4 / 2017 October 23" }
		'7.2.11878.0' { "SCOM 2016 Update Rollup 3 / 2017 May 23" }
		'7.2.11822.0' { "SCOM 2016 Update Rollup 2 / 2017 February 22" }
		'7.2.11759.0' { "SCOM 2016 Update Rollup 1 / 2016 October 13" }
		'7.2.11719.0' { "SCOM 2016 RTM / 2016 September 26" }
		'7.2.11469.0' { "SCOM 2016 Technical Preview 5 / 2016 April" }
		'7.2.11257.0' { "SCOM 2016 Technical Preview 4 / 2016 July" }
		'7.2.11125.0' { "SCOM 2016 Technical Preview 3 / 2016 July" }
		'7.2.11097.0' { "SCOM 2016 Technical Preview 2 / 2016 June" }
		'7.2.10015.0' { "SCOM 2016 Update Rollup 2 / 2017 February 22" }
   <# 
      System Center Operations Manager 2012 R2 Versions
   #>
		'7.1.10226.1387' { "SCOM 2012 R2 Update Rollup 14 / 2017 November 28" }
		'7.1.10226.1360' { "SCOM 2012 R2 Update Rollup 13 / 2017 May 23" }
		'7.1.10226.1304' { "SCOM 2012 R2 Update Rollup 12 / 2017 January 24" }
		'7.1.10226.1239' { "SCOM 2012 R2 Update Rollup 11 / 2016 August 30" }
		'7.1.10226.1177' { "SCOM 2012 R2 Update Rollup 9 / 2016 January 26" }
		'7.1.10226.1118' { "SCOM 2012 R2 Update Rollup 8 / 2015 October 27" }
		'7.1.10226.1090' { "SCOM 2012 R2 Update Rollup 7 / 2015 August 11" }
		'7.1.10226.1064' { "SCOM 2012 R2 Update Rollup 6 / 2015 April 28" }
		'7.1.10226.1052' { "SCOM 2012 R2 Update Rollup 5 / 2015 February 10" }
		'7.1.10226.1046' { "SCOM 2012 R2 Update Rollup 4 / 2014 October 28" }
		'7.1.10226.1037' { "SCOM 2012 R2 Update Rollup 3 / 2014 July 29" }
		'7.1.10226.1015' { "SCOM 2012 R2 Update Rollup 2 / 2014 April 23" }
		'7.1.10226.1011' { "SCOM 2012 R2 Update Rollup 1 / 2014 January 27" }
		'7.1.10226.0' { "SCOM 2012 R2 RTM / 2013 October 22" }
   <# 
      System Center Operations Manager 2012 SP1 Versions
   #>
		'7.0.9538.0' { "SCOM 2012 SP1" }
		'7.0.9538.1005' { "SCOM 2012 SP1 Update Rollup 1 / 2013 January 8" }
		'7.0.9538.1047' { "SCOM 2012 SP1 Update Rollup 2 / 2013 April 08" }
		'7.0.9538.1069' { "SCOM 2012 SP1 Update Rollup 3 / 2013 July 23" }
		'7.0.9538.1084' { "SCOM 2012 SP1 Update Rollup 4 / 2013 October 21" }
		'7.0.9538.1106' { "SCOM 2012 SP1 Update Rollup 5 / 2014 January 27" }
		'7.0.9538.1109' { "SCOM 2012 SP1 Update Rollup 6 / 2014 April 23" }
		'7.0.9538.1117' { "SCOM 2012 SP1 Update Rollup 7 / 2014 July 29" }
		'7.0.9538.1123' { "SCOM 2012 SP1 Update Rollup 8 / 2014 October 28" }
		'7.0.9538.1126' { "SCOM 2012 SP1 Update Rollup 9 / 2015 February 10" }
		'7.0.9538.1136' { "SCOM 2012 SP1 Update Rollup 10 / 2015 August 11" }
   <# 
      System Center Operations Manager 2012 Versions
   #>
		'7.0.8289.0' { "SCOM 2012 Beta / 2011 July" }
		'7.0.8560.0' { "SCOM 2012 RTM" }
		'7.0.8560.1021' { "SCOM 2012 Update Rollup 1 / 2012 May 07" }
		'7.0.8560.1027' { "SCOM 2012 Update Rollup 2 / 2012 July 24" }
		'7.0.8560.1036' { "SCOM 2012 Update Rollup 3 / 2012 October 08" }
		'7.0.8560.1048' { "SCOM 2012 Update Rollup 8 / 2015 August 11" }
	}
	$WebConsoleVersionDLL = $WebConsoleDLLSwitch + " (" + $WebConsoleDLL + ")"
	
	$CurrentVersionSwitch = switch ($setuplocation.CurrentVersion)
	{
    <# 
       System Center Operations Manager 2019 Versions
    #>
		'10.19.10407.0' { "Update Rollup 2 for SCOM 2019 / 2020 August 4" }
		'10.19.10349.0' { "SCOM 2019 Hotfix for Alert Management / 2020 April 1" }
		'10.19.10311.0' { "Update Rollup 1 for SCOM 2019 / 2020 February 4" }
		'10.19.10050.0' { "SCOM 2019 / 2019 March 14" }
    <# 
       System Center Operations Manager Semi-Annual Channel (SAC) Versions
    #>
		'7.3.13261.0' { "Version 1807 / 2018 July 24" }
		'7.3.13142.0' { "Version 1801 / 2018 February 8" }
		'7.3.13040.0' { "Version 1711 (preview) / 2017 November 9" }
    <# 
       System Center Operations Manager 2016 Versions
    #>
		'7.2.12265.0' { "SCOM 2016 Update Rollup 9 / 2020 March 24" }
		'7.2.12213.0' { "SCOM 2016 Update Rollup 8 / 2019 September 24" }
		'7.2.12150.0' { "SCOM 2016 Update Rollup 7 / 2019 April 23" }
		'7.2.12066.0' { "SCOM 2016 Update Rollup 6 / 2018 October 23" }
		'7.2.12016.0' { "SCOM 2016 Update Rollup 5 / 2018 April 25" }
		'7.2.11938.0' { "SCOM 2016 Update Rollup 4 / 2017 October 23" }
		'7.2.11878.0' { "SCOM 2016 Update Rollup 3 / 2017 May 23" }
		'7.2.11822.0' { "SCOM 2016 Update Rollup 2 / 2017 February 22" }
		'7.2.11759.0' { "SCOM 2016 Update Rollup 1 / 2016 October 13" }
		'7.2.11719.0' { "SCOM 2016 RTM / 2016 September 26" }
		'7.2.11469.0' { "SCOM 2016 Technical Preview 5 / 2016 April" }
		'7.2.11257.0' { "SCOM 2016 Technical Preview 4 / 2016 July" }
		'7.2.11125.0' { "SCOM 2016 Technical Preview 3 / 2016 July" }
		'7.2.11097.0' { "SCOM 2016 Technical Preview 2 / 2016 June" }
		'7.2.10015.0' { "SCOM 2016 Update Rollup 2 / 2017 February 22" }
   <# 
      System Center Operations Manager 2012 R2 Versions
   #>
		'7.1.10226.1387' { "SCOM 2012 R2 Update Rollup 14 / 2017 November 28" }
		'7.1.10226.1360' { "SCOM 2012 R2 Update Rollup 13 / 2017 May 23" }
		'7.1.10226.1304' { "SCOM 2012 R2 Update Rollup 12 / 2017 January 24" }
		'7.1.10226.1239' { "SCOM 2012 R2 Update Rollup 11 / 2016 August 30" }
		'7.1.10226.1177' { "SCOM 2012 R2 Update Rollup 9 / 2016 January 26" }
		'7.1.10226.1118' { "SCOM 2012 R2 Update Rollup 8 / 2015 October 27" }
		'7.1.10226.1090' { "SCOM 2012 R2 Update Rollup 7 / 2015 August 11" }
		'7.1.10226.1064' { "SCOM 2012 R2 Update Rollup 6 / 2015 April 28" }
		'7.1.10226.1052' { "SCOM 2012 R2 Update Rollup 5 / 2015 February 10" }
		'7.1.10226.1046' { "SCOM 2012 R2 Update Rollup 4 / 2014 October 28" }
		'7.1.10226.1037' { "SCOM 2012 R2 Update Rollup 3 / 2014 July 29" }
		'7.1.10226.1015' { "SCOM 2012 R2 Update Rollup 2 / 2014 April 23" }
		'7.1.10226.1011' { "SCOM 2012 R2 Update Rollup 1 / 2014 January 27" }
		'7.1.10226.0' { "SCOM 2012 R2 RTM / 2013 October 22" }
   <# 
      System Center Operations Manager 2012 SP1 Versions
   #>
		'7.0.9538.0' { "SCOM 2012 SP1" }
		'7.0.9538.1005' { "SCOM 2012 SP1 Update Rollup 1 / 2013 January 8" }
		'7.0.9538.1047' { "SCOM 2012 SP1 Update Rollup 2 / 2013 April 08" }
		'7.0.9538.1069' { "SCOM 2012 SP1 Update Rollup 3 / 2013 July 23" }
		'7.0.9538.1084' { "SCOM 2012 SP1 Update Rollup 4 / 2013 October 21" }
		'7.0.9538.1106' { "SCOM 2012 SP1 Update Rollup 5 / 2014 January 27" }
		'7.0.9538.1109' { "SCOM 2012 SP1 Update Rollup 6 / 2014 April 23" }
		'7.0.9538.1117' { "SCOM 2012 SP1 Update Rollup 7 / 2014 July 29" }
		'7.0.9538.1123' { "SCOM 2012 SP1 Update Rollup 8 / 2014 October 28" }
		'7.0.9538.1126' { "SCOM 2012 SP1 Update Rollup 9 / 2015 February 10" }
		'7.0.9538.1136' { "SCOM 2012 SP1 Update Rollup 10 / 2015 August 11" }
   <# 
      System Center Operations Manager 2012 Versions
   #>
		'7.0.8289.0' { "SCOM 2012 Beta / 2011 July" }
		'7.0.8560.0' { "SCOM 2012 RTM" }
		'7.0.8560.1021' { "SCOM 2012 Update Rollup 1 / 2012 May 07" }
		'7.0.8560.1027' { "SCOM 2012 Update Rollup 2 / 2012 July 24" }
		'7.0.8560.1036' { "SCOM 2012 Update Rollup 3 / 2012 October 08" }
		'7.0.8560.1048' { "SCOM 2012 Update Rollup 8 / 2015 August 11" }
	}
	
	Write-Host "-" -NoNewline -ForegroundColor Green
	
	$MOMmgmtGroupInfoImport = Import-Csv "$OutputPath`\MOMManagementGroupInfo.csv"
	$DBVersionSwitch = switch ($MOMmgmtGroupInfoImport.DBVersion)
	{
    <# 
       System Center Operations Manager 2019 Versions
    #>
		'10.19.10407.0' { "Update Rollup 2 for SCOM 2019 / 2020 August 4" }
		'10.19.10349.0' { "SCOM 2019 Hotfix for Alert Management / 2020 April 1" }
		'10.19.10311.0' { "Update Rollup 1 for SCOM 2019 / 2020 February 4" }
		'10.19.10050.0' { "SCOM 2019 / 2019 March 14" }
    <# 
       System Center Operations Manager Semi-Annual Channel (SAC) Versions
    #>
		'7.3.13261.0' { "Version 1807 / 2018 July 24" }
		'7.3.13142.0' { "Version 1801 / 2018 February 8" }
		'7.3.13040.0' { "Version 1711 (preview) / 2017 November 9" }
    <# 
       System Center Operations Manager 2016 Versions
    #>
		'7.2.12265.0' { "SCOM 2016 Update Rollup 9 / 2020 March 24" }
		'7.2.12213.0' { "SCOM 2016 Update Rollup 8 / 2019 September 24" }
		'7.2.12150.0' { "SCOM 2016 Update Rollup 7 / 2019 April 23" }
		'7.2.12066.0' { "SCOM 2016 Update Rollup 6 / 2018 October 23" }
		'7.2.12016.0' { "SCOM 2016 Update Rollup 5 / 2018 April 25" }
		'7.2.11938.0' { "SCOM 2016 Update Rollup 4 / 2017 October 23" }
		'7.2.11878.0' { "SCOM 2016 Update Rollup 3 / 2017 May 23" }
		'7.2.11822.0' { "SCOM 2016 Update Rollup 2 / 2017 February 22" }
		'7.2.11759.0' { "SCOM 2016 Update Rollup 1 / 2016 October 13" }
		'7.2.11719.0' { "SCOM 2016 RTM / 2016 September 26" }
		'7.2.11469.0' { "SCOM 2016 Technical Preview 5 / 2016 April" }
		'7.2.11257.0' { "SCOM 2016 Technical Preview 4 / 2016 July" }
		'7.2.11125.0' { "SCOM 2016 Technical Preview 3 / 2016 July" }
		'7.2.11097.0' { "SCOM 2016 Technical Preview 2 / 2016 June" }
		'7.2.10015.0' { "SCOM 2016 Update Rollup 2 / 2017 February 22" }
   <# 
      System Center Operations Manager 2012 R2 Versions
   #>
		'7.1.10226.1387' { "SCOM 2012 R2 Update Rollup 14 / 2017 November 28" }
		'7.1.10226.1360' { "SCOM 2012 R2 Update Rollup 13 / 2017 May 23" }
		'7.1.10226.1304' { "SCOM 2012 R2 Update Rollup 12 / 2017 January 24" }
		'7.1.10226.1239' { "SCOM 2012 R2 Update Rollup 11 / 2016 August 30" }
		'7.1.10226.1177' { "SCOM 2012 R2 Update Rollup 9 / 2016 January 26" }
		'7.1.10226.1118' { "SCOM 2012 R2 Update Rollup 8 / 2015 October 27" }
		'7.1.10226.1090' { "SCOM 2012 R2 Update Rollup 7 / 2015 August 11" }
		'7.1.10226.1064' { "SCOM 2012 R2 Update Rollup 6 / 2015 April 28" }
		'7.1.10226.1052' { "SCOM 2012 R2 Update Rollup 5 / 2015 February 10" }
		'7.1.10226.1046' { "SCOM 2012 R2 Update Rollup 4 / 2014 October 28" }
		'7.1.10226.1037' { "SCOM 2012 R2 Update Rollup 3 / 2014 July 29" }
		'7.1.10226.1015' { "SCOM 2012 R2 Update Rollup 2 / 2014 April 23" }
		'7.1.10226.1011' { "SCOM 2012 R2 Update Rollup 1 / 2014 January 27" }
		'7.1.10226.0' { "SCOM 2012 R2 RTM / 2013 October 22" }
   <# 
      System Center Operations Manager 2012 SP1 Versions
   #>
		'7.0.9538.0' { "SCOM 2012 SP1" }
		'7.0.9538.1005' { "SCOM 2012 SP1 Update Rollup 1 / 2013 January 8" }
		'7.0.9538.1047' { "SCOM 2012 SP1 Update Rollup 2 / 2013 April 08" }
		'7.0.9538.1069' { "SCOM 2012 SP1 Update Rollup 3 / 2013 July 23" }
		'7.0.9538.1084' { "SCOM 2012 SP1 Update Rollup 4 / 2013 October 21" }
		'7.0.9538.1106' { "SCOM 2012 SP1 Update Rollup 5 / 2014 January 27" }
		'7.0.9538.1109' { "SCOM 2012 SP1 Update Rollup 6 / 2014 April 23" }
		'7.0.9538.1117' { "SCOM 2012 SP1 Update Rollup 7 / 2014 July 29" }
		'7.0.9538.1123' { "SCOM 2012 SP1 Update Rollup 8 / 2014 October 28" }
		'7.0.9538.1126' { "SCOM 2012 SP1 Update Rollup 9 / 2015 February 10" }
		'7.0.9538.1136' { "SCOM 2012 SP1 Update Rollup 10 / 2015 August 11" }
   <# 
      System Center Operations Manager 2012 Versions
   #>
		'7.0.8289.0' { "SCOM 2012 Beta / 2011 July" }
		'7.0.8560.0' { "SCOM 2012 RTM" }
		'7.0.8560.1021' { "SCOM 2012 Update Rollup 1 / 2012 May 07" }
		'7.0.8560.1027' { "SCOM 2012 Update Rollup 2 / 2012 July 24" }
		'7.0.8560.1036' { "SCOM 2012 Update Rollup 3 / 2012 October 08" }
		'7.0.8560.1048' { "SCOM 2012 Update Rollup 8 / 2015 August 11" }
	}
	
	$MOMmgmtGroupInfo = $DBVersionSwitch + " (" + $MOMmgmtGroupInfoImport.DBVersion + ")"
	$setuplocation.CurrentVersion = $CurrentVersionSwitch + " (" + $setuplocation.CurrentVersion + ")"
	
	Write-Host "-" -NoNewline -ForegroundColor Green
	
	$OMSQLPropertiesImport = Import-Csv "$OutputPath`\SQL_Properties_OM.csv"
	$OMSQLVersionSwitch = switch ($OMSQLPropertiesImport.ProductVersion)
	{
		'13.0.5830.85' { "CU14 for Microsoft SQL Server 2016 SP2 (KB4564903) / 2020 August 6" }
		'13.0.5820.21' { "CU13 for Microsoft SQL Server 2016 SP2 (KB4549825) / 2020 May 28" }
		'13.0.5698.0' { "CU12 for Microsoft SQL Server 2016 SP2 (KB4536648) / 2020 February 25" }
		'13.0.5622.0' { "Security update for SQL Server 2016 SP2 CU11 (KB4535706) / 2020 February 11" }
		'13.0.5598.27' { "CU11 for Microsoft SQL Server 2016 SP2 (KB4527378) / 2019 December 9" }
		'13.0.5492.2' { "CU10 for Microsoft SQL Server 2016 SP2 (KB4524334) / 2019 October 8" }
		'13.0.5479.0' { "CU9 for Microsoft SQL Server 2016 SP2 (KB4515435) (withdrawn) / 2019 September 30" }
		'13.0.5426.0' { "CU8 for Microsoft SQL Server 2016 SP2 (KB4505830) / 2019 July 31" }
		'13.0.5382.0' { "On-demand hotfix update package for SQL Server 2016 SP2 CU7 (KB4510807) / 2019 July 10" }
		'13.0.5366.0' { "Security update for SQL Server 2016 SP2 CU7 (KB4505222) / 2019 July 9" }
		'13.0.5343.1' { "On-demand hotfix update package for SQL Server 2016 SP2 CU7 (KB4508636) / 2019 June 24" }
		'13.0.5337.0' { "CU7 for Microsoft SQL Server 2016 SP2 (KB4495256) / 2019 May 22" }
		'13.0.5292.0' { "CU6 for Microsoft SQL Server 2016 SP2 (KB4488536) / 2019 March 19" }
		'13.0.5270.0' { "FIX: Restoring backup to SQL Server 2016 from SQL Server 2008 or 2008 R2 takes a long time (KB4490237) / 2019 February 14" }
		'13.0.5264.1' { "CU5 for Microsoft SQL Server 2016 SP2 (KB4475776) / 2019 January 23" }
		'13.0.5239.0' { "FIX: On-demand hotfix update package 2 for SQL Server 2016 SP2 CU4 (KB4482972) / 2018 December 21" }
		'13.0.5233.0' { "CU4 for Microsoft SQL Server 2016 SP2 (KB4464106) / 2018 November 13" }
		'13.0.5216.0' { "CU3 for Microsoft SQL Server 2016 SP2 (KB4458871) / 2018 September 21" }
		'13.0.5201.1' { "Security update for the remote code execution vulnerability in SQL Server 2016 SP2 (CU) (KB4458621) / 2018 August 19" }
		'13.0.5161.0' { "(Replaced) Security update for the remote code execution vulnerability in SQL Server 2016 SP2 (CU) (KB4293807) / 2018 August 14" }
		'13.0.5153.0' { "CU2 for Microsoft SQL Server 2016 SP2 (KB4340355) / 2018 July 16" }
		'13.0.5149.0' { "CU1 for Microsoft SQL Server 2016 SP2 (KB4135048) / 2018 May 29" }
		'13.0.5102.14' { "Security update for SQL Server 2016 SP2 GDR (KB4532097) / 2020 February 11" }
		'13.0.5101.9' { "Security update for SQL Server 2016 SP2 GDR (KB4505220) / 2019 July 9" }
		'13.0.5081.1' { "Security update for the remote code execution vulnerability in SQL Server 2016 SP2 GDR (KB4293802) / 2018 August 14" }
		'13.0.5026.0' { "SQL Server 2016 Service Pack 2 (SP2) / 2018 April 24" }
		'13.0.4604.0' { "Security update for SQL Server 2016 SP1 CU15 GDR (KB4505221) / 2019 July 9" }
		'13.0.4577.0' { "On-demand hotfix update package for SQL Server 2016 SP1 CU15 (KB4508471) / 2019 June 20" }
		'13.0.4574.0' { "CU15 for Microsoft SQL Server 2016 SP1 (KB4495257) / 2019 May 16" }
		'13.0.4560.0' { "CU14 for Microsoft SQL Server 2016 SP1 (KB4488535) / 2019 March 19" }
		'13.0.4550.1' { "CU13 for Microsoft SQL Server 2016 SP1 (KB4475775) / 2019 January 23" }
		'13.0.4541.0' { "CU12 for Microsoft SQL Server 2016 SP1 (KB4464343) / 2018 November 13" }
		'13.0.4531.0' { "FIX: The `"modification_counter`" in DMV sys.dm_db_stats_properties shows incorrect value when partitions are merged through ALTER PARTITION in SQL Server 2016 (KB4465443) / 2018 September 27" }
		'13.0.4528.0' { "CU11 for Microsoft SQL Server 2016 SP1 (KB4459676) / 2018 September 18" }
		'13.0.4522.0' { "Security update for the remote code execution vulnerability in SQL Server 2016 SP1 (CU) (KB4293808) / 2018 August 14" }
		'13.0.4514.0' { "CU10 for Microsoft SQL Server 2016 SP1 (KB4341569) / 2018 July 16" }
		'13.0.4502.0' { "CU9 for Microsoft SQL Server 2016 SP1 (KB4100997) / 2018 May 29" }
		'13.0.4474.0' { "CU8 for Microsoft SQL Server 2016 SP1 (KB4077064) / 2018 March 19" }
		'13.0.4466.4' { "CU7 for Microsoft SQL Server 2016 SP1 (KB4057119) / 2018 January 4" }
		'13.0.4457.0' { "CU6 for Microsoft SQL Server 2016 SP1 (KB4037354) / 2017 November 21" }
		'13.0.4451.0' { "CU5 for Microsoft SQL Server 2016 SP1 (KB4040714) / 2017 September 18" }
		'13.0.4446.0' { "CU4 for Microsoft SQL Server 2016 SP1 (KB4024305) / 2017 August 8" }
		'13.0.4435.0' { "CU3 for Microsoft SQL Server 2016 SP1 (KB4019916) / 2017 May 15" }
		'13.0.4422.0' { "CU2 for Microsoft SQL Server 2016 SP1 (KB4013106) / 2017 March 20" }
		'13.0.4411.0' { "CU1 for Microsoft SQL Server 2016 SP1 (KB3208177) / 2017 January 18" }
		'13.0.4259.0' { "Security update for SQL Server 2016 SP1 GDR (KB4505219) / 2019 July 9" }
		'13.0.4224.16' { "Security update for the remote code execution vulnerability in SQL Server 2016 SP1 (GDR) (KB4458842) / 2018 August 22" }
		'13.0.4223.10' { "(Replaced) Security update for the remote code execution vulnerability in SQL Server 2016 SP1 (GDR) (KB4293801) / 2018 August 14" }
		'13.0.4210.6' { "Security Update for SQL Server 2016 Service Pack 1 GDR (KB4057118) / 2018 January 4" }
		'13.0.4206.0' { "Security Update for SQL Server 2016 Service Pack 1 GDR (KB4019089) / 2017 August 8" }
		'13.0.4202.2' { "GDR update package for SQL Server 2016 SP1 (KB3210089) / 2016 December 16" }
		'13.0.4199.0' { "FIX: Important update for SQL Server 2016 SP1 Reporting Services (KB3207512) / 2016 November 23" }
		'13.0.4001.0' { "SQL Server 2016 Service Pack 1 (SP1) / 2016 November 16" }
		'13.0.2218.0' { "Security Update for SQL Server 2016 RTM CU (KB4058559) / 2018 January 8" }
		'13.0.2216.0' { "CU9 for Microsoft SQL Server 2016 RTM (KB4037357) / 2017 November 21" }
		'13.0.2213.0' { "CU8 for Microsoft SQL Server 2016 RTM (KB4040713) / 2017 September 18" }
		'13.0.2210.0' { "CU7 for Microsoft SQL Server 2016 RTM (KB4024304) / 2017 August 8" }
		'13.0.2204.0' { "CU6 for Microsoft SQL Server 2016 RTM (KB4019914) / 2017 May 15" }
		'13.0.2197.0' { "CU5 for Microsoft SQL Server 2016 RTM (KB4013105) / 2017 March 20" }
		'13.0.2193.0' { "CU4 for Microsoft SQL Server 2016 RTM (KB3205052) / 2017 January 18" }
		'13.0.2186.6' { "MS16-136: CU3 for Microsoft SQL Server 2016 RTM (KB3205413) / 2016 November 8" }
		'13.0.2170.0' { "FIX: On-demand hotfix update package for SQL Server 2016 CU2 RTM (KB3199171) / 2016 October 26" }
		'13.0.2169.0' { "FIX: On-demand hotfix update package for SQL Server 2016 CU2 RTM (KB3195813) / 2016 October 26" }
		'13.0.2164.0' { "CU2 for Microsoft SQL Server 2016 RTM (KB3182270) / 2016 September 22" }
		'13.0.2149.0' { "CU1 for Microsoft SQL Server 2016 RTM (KB3164674) / 2016 July 26" }
		'13.0.1745.2' { "Security Update for SQL Server 2016 RTM GDR (KB4058560) / 2018 January 8" }
		'13.0.1742.0' { "Security Update for SQL Server 2016 RTM GDR (KB4019088) / 2017 August 8" }
		'13.0.1728.2' { "GDR update package for SQL Server 2016 RTM (KB3210111) / 2016 December 16" }
		'13.0.1722.0' { "MS16-136: Security Update for SQL Server 2016 GDR (KB3194716) / 2016 November 8" }
		'13.0.1711.0' { "FIX: Processing a partition causes data loss on other partitions after the database is restored in SQL Server 2016 (1200) (KB3179258) / 2016 August 11" }
		'13.0.1708.0' { "Critical update for SQL Server 2016 MSVCRT prerequisites / 2016 June 3" }
		'13.0.1601.5' { "SQL Server 2016 RTM / 2016 June 1" }
		'12.0.6372.1' { "Security update for SQL Server 2014 SP3 CU4 (KB4535288) / 2020 February 11" }
		'12.0.6329.1' { "CU4 for Microsoft SQL Server 2014 SP3 (KB4500181) / 2019 July 29" }
		'12.0.6293.0' { "Security update for SQL Server 2014 SP3 CU3 (KB4505422) / 2019 July 9" }
		'12.0.6259.0' { "CU3 for Microsoft SQL Server 2014 SP3 (KB4491539) / 2019 April 16" }
		'12.0.6214.1' { "CU2 for Microsoft SQL Server 2014 SP3 (KB4482960) / 2019 February 19" }
		'12.0.6205.1' { "CU1 for Microsoft SQL Server 2014 SP3 (KB4470220) / 2018 December 13" }
		'12.0.6118.4' { "Security update for SQL Server 2014 SP3 GDR (KB4532095) / 2020 February 11" }
		'12.0.6108.1' { "Security update for SQL Server 2014 SP3 GDR (KB4505218) / 2019 July 9" }
		'12.0.6024.0' { "Microsoft SQL Server 2014 Service Pack 3 (SP3) / 2018 October 30" }
		'12.0.5687.1' { "CU18 for Microsoft SQL Server 2014 SP2 (KB4500180) / 2019 July 29" }
		'12.0.5659.1' { "Security update for SQL Server 2014 SP2 CU17 GDR (KB4505419) / 2019 July 9" }
		'12.0.5632.1' { "CU17 for Microsoft SQL Server 2014 SP2 (KB4491540) / 2019 April 16" }
		'12.0.5626.1' { "CU16 for Microsoft SQL Server 2014 SP2 (KB4482967) / 2019 February 19" }
		'12.0.5605.1' { "CU15 for Microsoft SQL Server 2014 SP2 (KB4469137) / 2018 December 13" }
		'12.0.5600.1' { "CU14 for Microsoft SQL Server 2014 SP2 (KB4459860) / 2018 October 15" }
		'12.0.5590.1' { "CU13 for Microsoft SQL Server 2014 SP2 (KB4456287) / 2018 August 27" }
		'12.0.5589.7' { "CU12 for Microsoft SQL Server 2014 SP2 (KB4130489) / 2018 June 18" }
		'12.0.5579.0' { "CU11 for Microsoft SQL Server 2014 SP2 (KB4077063) / 2018 March 19" }
		'12.0.5571.0' { "CU10 for Microsoft SQL Server 2014 SP2 (KB4052725) / 2018 January 16" }
		'12.0.5563.0' { "CU9 for Microsoft SQL Server 2014 SP2 (KB4055557) / 2017 December 18" }
		'12.0.5557.0' { "CU8 for Microsoft SQL Server 2014 SP2 (KB4037356) / 2017 October 17" }
		'12.0.5556.0' { "CU7 for Microsoft SQL Server 2014 SP2 (KB4032541) / 2017 August 28" }
		'12.0.5553.0' { "CU6 for Microsoft SQL Server 2014 SP2 (KB4019094) / 2017 August 8" }
		'12.0.5546.0' { "CU5 for Microsoft SQL Server 2014 SP2 (KB4013098) / 2017 April 17" }
		'12.0.5540.0' { "CU4 for Microsoft SQL Server 2014 SP2 (KB4010394) / 2017 February 21" }
		'12.0.5538.0' { "CU3 for Microsoft SQL Server 2014 SP2 (KB3204388) / 2016 December 28" }
		'12.0.5532.0' { "MS16-136: Security Update for SQL Server 2014 Service Pack 2 CU (KB3194718) / 2016 November 8" }
		'12.0.5522.0' { "CU2 for Microsoft SQL Server 2014 SP2 (KB3188778) / 2016 October 17" }
		'12.0.5511.0' { "CU1 for Microsoft SQL Server 2014 SP2 (KB3178925) / 2016 August 26" }
		'12.0.5223.6' { "Security update for SQL Server 2014 SP2 GDR (KB4505217) / 2019 July 9" }
		'12.0.5214.6' { "Security Update for SQL Server 2014 Service Pack 2 GDR (KB4057120) / 2018 January 16" }
		'12.0.5207.0' { "Security Update for SQL Server 2014 Service Pack 2 GDR (KB4019093) / 2017 August 8" }
		'12.0.5203.0' { "MS16-136: Security Update for SQL Server 2014 Service Pack 2 GDR (KB3194714) / 2016 November 8" }
		'12.0.5000.0' { "Microsoft SQL Server 2014 Service Pack 2 (SP2) / 2016 July 11" }
		'12.0.4522.0' { "CU13 for Microsoft SQL Server 2014 SP1 (KB4019099) / 2017 August 8" }
		'12.0.4511.0' { "CU12 for Microsoft SQL Server 2014 SP1 (KB4017793) / 2017 April 17" }
		'12.0.4502.0' { "CU11 for Microsoft SQL Server 2014 SP1 (KB4010392) / 2017 February 21" }
		'12.0.4491.0' { "CU10 for Microsoft SQL Server 2014 SP1 (KB3204399) / 2016 December 28" }
		'12.0.4487.0' { "MS16-136: Security Update for SQL Server 2014 Service Pack 1 CU (KB3194722) / 2016 November 8" }
		'12.0.4474.0' { "CU9 for Microsoft SQL Server 2014 SP1 (KB3186964) / 2016 October 17" }
		'12.0.4468.0' { "CU8 for Microsoft SQL Server 2014 SP1 (KB3174038) / 2016 August 15" }
		'12.0.4463.0' { "FIX: A memory leak occurs when you use Azure Storage in SQL Server 2014 (KB3174370) / 2016 August 4" }
		'12.0.4459.0' { "CU7 for Microsoft SQL Server 2014 SP1 (KB3162659) / 2016 June 20" }
		'12.0.4457.0' { "CU6 (re-released) for Microsoft SQL Server 2014 SP1 (KB3167392) / 2016 May 30" }
		'12.0.4449.0' { "CU6 (replaced) for Microsoft SQL Server 2014 SP1 (KB3144524) / 2016 April 18" }
		'12.0.4439.1' { "CU5 for Microsoft SQL Server 2014 SP1 (KB3130926) / 2016 February 21" }
		'12.0.4437.0' { "On-demand hotfix update package for SQL Server 2014 SP1 CU4 (KB3130999) / 2016 February 5" }
		'12.0.4436.0' { "CU4 for Microsoft SQL Server 2014 SP1 (KB3106660) / 2015 December 22" }
		'12.0.4427.24' { "CU3 for Microsoft SQL Server 2014 SP1 (KB3094221) / 2015 October 20" }
		'12.0.4422.0' { "CU2 for Microsoft SQL Server 2014 SP1 (KB3075950) / 2015 August 17" }
		'12.0.4416.0' { "CU1 for Microsoft SQL Server 2014 SP1 (KB3067839) / 2015 June 22" }
		'12.0.4237.0' { "Security Update for SQL Server 2014 Service Pack 1 GDR (KB4019091) / 2017 August 8" }
		'12.0.4232.0' { "MS16-136: Security Update for SQL Server 2014 Service Pack 1 GDR (KB3194720) / 2016 November 8" }
		'12.0.4219.0' { "TLS 1.2 support for Microsoft SQL Server 2014 SP1 GDR / 2016 January 29" }
		'12.0.4213.0' { "MS15-058: Nonsecurity update for SQL Server 2014 SP1 (GDR) (KB3070446) / 2015 July 14" }
		'12.0.4100.1' { "Microsoft SQL Server 2014 Service Pack 1 / 2015 May 15" }
		'12.0.2569.0' { "CU14 for Microsoft SQL Server 2014 (KB3158271) / 2016 June 20" }
		'12.0.2568.0' { "CU13 for Microsoft SQL Server 2014 (KB3144517) / 2016 April 18" }
		'12.0.2564.0' { "CU12 for Microsoft SQL Server 2014 (KB3130923) / 2016 February 21" }
		'12.0.2560.0' { "CU11 for Microsoft SQL Server 2014 (KB3106659) / 2015 December 22" }
		'12.0.2556.4' { "CU10 for Microsoft SQL Server 2014 (KB3094220) / 2015 October 20" }
		'12.0.2553.0' { "CU9 for Microsoft SQL Server 2014 (KB3075949) / 2015 August 17" }
		'12.0.2548.0' { "MS15-058: Security update for SQL Server 2014 (QFE) (KB3045323) / 2015 July 14" }
		'12.0.2546.0' { "CU8 for Microsoft SQL Server 2014 (KB3067836) / 2015 June 22" }
		'12.0.2495.0' { "CU7 for Microsoft SQL Server 2014 (KB3046038) / 2015 April 23" }
		'12.0.2480.0' { "CU6 for Microsoft SQL Server 2014 (KB3031047) / 2015 February 16" }
		'12.0.2474.0' { "FIX: AlwaysOn availability groups are reported as NOT SYNCHRONIZING (KB3034679) / 2014 February 4" }
		'12.0.2456.0' { "CU5 for Microsoft SQL Server 2014 (KB3011055) / 2014 December 18" }
		'12.0.2430.0' { "CU4 for Microsoft SQL Server 2014 (KB2999197) / 2014 October 21" }
		'12.0.2402.0' { "CU3 for Microsoft SQL Server 2014 (KB2984923) / 2014 August 18" }
		'12.0.2381.0' { "MS14-044: Security update for SQL Server 2014 (QFE) (KB2977316) / 2014 August 12" }
		'12.0.2370.0' { "CU2 for Microsoft SQL Server 2014 (KB2967546) / 2014 June 27" }
		'12.0.2342.0' { "CU1 for Microsoft SQL Server 2014 (KB2931693) / 2014 April 21" }
		'12.0.2271.0' { "TLS 1.2 support for Microsoft SQL Server 2014 GDR / 2016 January 29" }
		'12.0.2269.0' { "MS15-058: Security Update for SQL Server 2014 (GDR) (KB3045324) / 2015 July 14" }
		'12.0.2254.0' { "MS14-044: Security Update for SQL Server 2014 (GDR) (KB2977315) / 2014 August 12" }
		'12.0.2000.8' { "Microsoft SQL Server 2014 RTM / 2014 April 1" }
		'11.0.7493.4' { "Security Update for SQL Server 2012 SP4 GDR (KB4532098) / 2020 February 11" }
		'11.0.7469.6' { "On-demand hotfix update package for SQL Server 2012 SP4 (KB4091266) / 2018 March 28" }
		'11.0.7462.6' { "Security Update for SQL Server 2012 SP4 GDR (KB4057116) / 2018 January 12" }
		'11.0.7001.0' { "SQL Server 2012 Service Pack 4 (KB4018073) / 2017 October 5" }
		'11.0.6615.2' { "Security Update for SQL Server 2012 SP3 CU (KB4057121) / 2018 January 16" }
		'11.0.6607.3' { "CU10 for Microsoft SQL Server 2012 SP3 (KB4025925) / 2017 August 8" }
		'11.0.6598.0' { "CU9 for Microsoft SQL Server 2012 SP3 (KB4016762) / 2017 May 15" }
		'11.0.6594.0' { "CU8 for Microsoft SQL Server 2012 SP3 (KB4013104) / 2017 March 21" }
		'11.0.6579.0' { "CU7 for Microsoft SQL Server 2012 SP3 (KB3205051) / 2017 January 18" }
		'11.0.6567.0' { "MS16-136: CU6 for Microsoft SQL Server 2012 SP3 (KB3194992) / 2016 November 8" }
		'11.0.6544.0' { "CU5 for Microsoft SQL Server 2012 SP3 (KB3180915) / 2016 September 20" }
		'11.0.6540.0' { "CU4 for Microsoft SQL Server 2012 SP3 (KB3165264) / 2016 July 18" }
		'11.0.6537.0' { "CU3 for Microsoft SQL Server 2012 SP3 (KB3152635) / 2016 May 15" }
		'11.0.6523.0' { "CU2 for Microsoft SQL Server 2012 SP3 (KB3137746) / 2016 March 22" }
		'11.0.6518.0' { "CU1 for Microsoft SQL Server 2012 SP3 (KB3123299) / 2016 January 19" }
		'11.0.6260.1' { "Security Update for SQL Server 2012 Service Pack 3 GDR (KB4057115) / 2018 January 16" }
		'11.0.6251.0' { "Security Update for SQL Server 2012 Service Pack 3 GDR (KB4019092) / 2017 August 8" }
		'11.0.6248.0' { "MS16-136: Security Update for SQL Server 2012 Service Pack 3 GDR (KB3194721) / 2016 November 8" }
		'11.0.6216.27' { "TLS 1.2 support for Microsoft SQL Server 2012 SP3 GDR / 2016 January 29" }
		'11.0.6020.0' { "SQL Server 2012 Service Pack 3 (KB3072779) / 2015 November 21" }
		'11.0.5678.0' { "CU16 for Microsoft SQL Server 2012 SP2 (KB3205054) / 2017 January 18" }
		'11.0.5676.0' { "MS16-136: CU15 for Microsoft SQL Server 2012 SP2 (KB3205416) / 2016 November 8" }
		'11.0.5657.0' { "CU14 for Microsoft SQL Server 2012 SP2 (KB3180914) / 2016 September 20" }
		'11.0.5655.0' { "CU13 for Microsoft SQL Server 2012 SP2 (KB3165266) / 2016 July 18" }
		'11.0.5649.0' { "CU12 for Microsoft SQL Server 2012 SP2 (KB3152637) / 2016 May 15" }
		'11.0.5646.0' { "CU11 for Microsoft SQL Server 2012 SP2 (KB3137745) / 2016 March 22" }
		'11.0.5644.2' { "CU10 for Microsoft SQL Server 2012 SP2 (KB3120313) / 2016 January 19" }
		'11.0.5641.0' { "CU9 for Microsoft SQL Server 2012 SP2 (KB3098512) / 2015 November 18" }
		'11.0.5634.1' { "CU8 for Microsoft SQL Server 2012 SP2 (KB3082561) / 2015 September 21" }
		'11.0.5623.0' { "CU7 for Microsoft SQL Server 2012 SP2 (KB3072100) / 2015 July 20" }
		'11.0.5613.0' { "MS15-058: Security Update for SQL Server 2012 SP2 QFE (KB3045319) / 2015 July 14" }
		'11.0.5592.0' { "CU6 for Microsoft SQL Server 2012 SP2 (KB3052468) / 2015 May 18" }
		'11.0.5582.0' { "CU5 for Microsoft SQL Server 2012 SP2 (KB3037255) / 2015 March 16" }
		'11.0.5571.0' { "FIX: AlwaysOn availability groups are reported as NOT SYNCHRONIZING (KB3034679) / 2015 February 4" }
		'11.0.5569.0' { "CU4 for Microsoft SQL Server 2012 SP2 (KB3007556) / 2015 January 20" }
		'11.0.5556.0' { "CU3 for Microsoft SQL Server 2012 SP2 (KB3002049) / 2014 November 17" }
		'11.0.5548.0' { "CU2 for Microsoft SQL Server 2012 SP2 (KB2983175) / 2014 September 15" }
		'11.0.5532.0' { "CU1 for Microsoft SQL Server 2012 SP2 (KB2976982) / 2014 July 23" }
		'11.0.5522.0' { "FIX for SQL Server 2012 SP2: Data loss in clustered index (KB2969896) / 2014 June 20" }
		'11.0.5388.0' { "MS16-136: Security Update for SQL Server 2012 Service Pack 2 GD2 (KB3194719) / 2016 November 8" }
		'11.0.5352.0' { "TLS 1.2 support for Microsoft SQL Server 2012 SP2 GDR / 2016 January 29" }
		'11.0.5343.0' { "MS15-058: Security Update for SQL Server 2012 SP2 GDR (KB3045321) / 2014 July 14" }
		'11.0.5058.0' { "SQL Server 2012 Service Pack 2 (KB2958429) / 2014 June 10" }
		'11.0.3513.0' { "MS15-058: Security Update for SQL Server 2012 SP1 QFE (KB3045317) / 2015 July 14" }
		'11.0.3492.0' { "CU16 for Microsoft SQL Server 2012 SP1 (KB3052476) / 2015 May 18" }
		'11.0.3487.0' { "CU15 for Microsoft SQL Server 2012 SP1 (KB3038001) / 2015 March 16" }
		'11.0.3486.0' { "CU14 for Microsoft SQL Server 2012 SP1 (KB3007556) / 2015 January 21" }
		'11.0.3482.0' { "CU13 for Microsoft SQL Server 2012 SP1 (KB3002044) / 2014 November 17" }
		'11.0.3470.0' { "CU12 for Microsoft SQL Server 2012 SP1 (KB2975396) / 2014 September 15" }
		'11.0.3467.0' { "FIX: Log Reader Agent crashes during initialization when you use transactional replication in SQL Server(KB2975402) / 2014 August 28" }
		'11.0.3460.0' { "MS14-044: Security Update for Microsoft SQL Server 2012 SP1 (QFE)(KB2977325) / 2014 August 12" }
		'11.0.3449.0' { "CU11 for Microsoft SQL Server 2012 SP1 (KB2975396) / 2014 July 21" }
		'11.0.3437.0' { "FIX for SQL Server 2012 SP1: Data loss in clustered index (KB2969896) / 2014 June 10" }
		'11.0.3431.0' { "CU10 for Microsoft SQL Server 2012 SP1 (KB2954099) / 2014 May 19" }
		'11.0.3412.0' { "CU9 for Microsoft SQL Server 2012 SP1 (KB2931078) / 2014 March 18" }
		'11.0.3401.0' { "CU8 for Microsoft SQL Server 2012 SP1 (KB2917531) / 2014 January 20" }
		'11.0.3393.0' { "CU7 for Microsoft SQL Server 2012 SP1 (KB2894115) / 2013 November 18" }
		'11.0.3381.0' { "CU6 for Microsoft SQL Server 2012 SP1 (KB2874879) / 2013 September 16" }
		'11.0.3373.0' { "CU5 for Microsoft SQL Server 2012 SP1 (KB2861107) / 2013 July 16" }
		'11.0.3368.0' { "CU4 for Microsoft SQL Server 2012 SP1 (KB2833645) / 2013 May 31" }
		'11.0.3349.0' { "CU3 for Microsoft SQL Server 2012 SP1 (KB2812412) / 2013 March 18" }
		'11.0.3339.0' { "CU2 for Microsoft SQL Server 2012 SP1 (KB2790947) / 2013 January 25" }
		'11.0.3321.0' { "CU1 for Microsoft SQL Server 2012 SP1 (KB2765331) / 2012 November 20" }
		'11.0.3156.0' { "MS15-058: Security Update for SQL Server 2012 SP1 GDR (KB3045318) / 2015 July 14" }
		'11.0.3153.0' { "MS14-044: Security Update for SQL Server 2012 SP1 GDR (KB2977326) / 2014 August 12" }
		'11.0.3128.0' { "FIX: Windows Installer starts repeatedly after you install SQL Server 2012 SP1 (KB2793634) / 2013 January 3" }
		'11.0.3000.0' { "SQL Server 2012 Service Pack 1 (KB2674319) / 2012 November 6" }
		'11.0.2424.0' { "CU11 for Microsoft SQL Server 2012 (KB2908007) / 2013 December 17" }
		'11.0.2420.0' { "CU10 for Microsoft SQL Server 2012 (KB2891666) / 2013 October 21" }
		'11.0.2419.0' { "CU9 for Microsoft SQL Server 2012 (KB2867319) / 2013 August 21" }
		'11.0.2410.0' { "CU8 for Microsoft SQL Server 2012 (KB2844205) / 2013 June 18" }
		'11.0.2405.0' { "CU7 for Microsoft SQL Server 2012 (KB2823247) / 2013 April 15" }
		'11.0.2401.0' { "CU6 for Microsoft SQL Server 2012 (KB2728897) / 2013 February 18" }
		'11.0.2395.0' { "CU5 for Microsoft SQL Server 2012 (KB2777772) / 2012 December 18" }
		'11.0.2383.0' { "CU4 for Microsoft SQL Server 2012 (KB2758687) / 2012 October 18" }
		'11.0.2376.0' { "MS12-070: Security Update for SQL Server 2012 QFE (KB2716441) / 2012 October 9" }
		'11.0.2332.0' { "CU3 for Microsoft SQL Server 2012 (KB2723749) / 2012 August 29" }
		'11.0.2325.0' { "CU2 for Microsoft SQL Server 2012 (KB2703275) / 2012 June 18" }
		'11.0.2316.0' { "CU1 for Microsoft SQL Server 2012 (KB2679368) / 2012 April 12" }
		'11.0.2218.0' { "MS12-070: Security Update for SQL Server 2012 GDR (KB2716442) / 2012 October 9" }
		'11.0.2100.0' { "SQL Server 2012 RTM / 2012 March 6" }
		'10.50.6560.0' { "Security Update for SQL Server 2008 R2 SP3 GDR (KB4057113) / 2018 January 6" }
		'10.50.6542.0' { "TLS 1.2 support for Microsoft SQL Server 2008 R2 SP3 (updated) / 2016 March 3" }
		'10.50.6537.0' { "TLS 1.2 support for Microsoft SQL Server 2008 R2 SP3 (replaced, see KB3146034) / 2016 January 29" }
		'10.50.6529.0' { "MS15-058: Security Update for SQL Server 2008 R2 SP3 QFE (KB3045314) / 2015 July 14" }
		'10.50.6525.0' { "FIX: On-demand Hotfix Update Package for SQL Server 2008 R2 SP3 (KB3033860) / 2015 February 9" }
		'10.50.6220.0' { "MS15-058: Security Update for SQL Server 2008 R2 SP3 GDR (KB3045316) / 2015 July 14" }
		'10.50.6000.34' { "SQL Server 2008 R2 Service Pack 3 / 2014 September 26" }
		'10.50.4344.0' { "TLS 1.2 support for SQL Server 2008 R2 SP2 (IA-64) (updated) / 2016 March 3" }
		'10.50.4343.0' { "TLS 1.2 support for SQL Server 2008 R2 SP2 (IA-64) (replaced, see KB3146034) / 2016 January 29" }
		'10.50.4339.0' { "MS15-058: Security Update for SQL Server 2008 R2 SP2 QFE (KB3045312) / 2015 July 14" }
		'10.50.4331.0' { "MS14-044: Security Update for SQL Server 2008 R2 SP2 QFE (KB2977319) / 2014 August 12" }
		'10.50.4319.0' { "CU13 for Microsoft SQL Server 2008 R2 SP2(KB2967540) / 2014 June 30" }
		'10.50.4305.0' { "CU12 for Microsoft SQL Server 2008 R2 SP2(KB2938478) / 2014 April 21" }
		'10.50.4302.0' { "CU11 for Microsoft SQL Server 2008 R2 SP2(KB2926028) / 2014 February 18" }
		'10.50.4297.0' { "CU10 for Microsoft SQL Server 2008 R2 SP2(KB2908087) / 2013 December 16" }
		'10.50.4295.0' { "CU9 for Microsoft SQL Server 2008 R2 SP2(KB2887606) / 2013 October 29" }
		'10.50.4290.0' { "CU8 for Microsoft SQL Server 2008 R2 SP2(KB2871401) / 2013 August 30" }
		'10.50.4286.0' { "CU7 for Microsoft SQL Server 2008 R2 SP2(KB2844090) / 2013 June 17" }
		'10.50.4285.0' { "CU6 re-released for Microsoft SQL Server 2008 R2 SP2(KB2830140) / 2013 June 13" }
		'10.50.4279.0' { "CU6 (replaced) for Microsoft SQL Server 2008 R2 SP2(KB2830140) / 2013 April 15" }
		'10.50.4276.0' { "CU5 for Microsoft SQL Server 2008 R2 SP2(KB2797460) / 2013 February 18" }
		'10.50.4270.0' { "CU4 for Microsoft SQL Server 2008 R2 SP2(KB2777358) / 2012 December 17" }
		'10.50.4266.0' { "CU3 for Microsoft SQL Server 2008 R2 SP2(KB2754552) / 2012 October 15" }
		'10.50.4263.0' { "CU2 for Microsoft SQL Server 2008 R2 SP2(KB2740411) / 2012 August 29" }
		'10.50.4260.0' { "CU1 for Microsoft SQL Server 2008 R2 SP2(KB2720425) / 2012 August 1" }
		'10.50.4047.0' { "TLS 1.2 support for SQL Server 2008 R2 SP2 GDR (IA-64) (updated) / 2016 March 3" }
		'10.50.4046.0' { "TLS 1.2 support for SQL Server 2008 R2 SP2 GDR (IA-64) (replaced, see KB3146034) / 2016 January 29" }
		'10.50.4042.0' { "MS15-058: Security Update for SQL Server 2008 R2 SP2 GDR (KB3045313) / 2015 July 14" }
		'10.50.4033.0' { "MS14-044: Security Update for SQL Server 2008 R2 SP2 GDR (KB2977320) / 2014 August 12" }
		'10.50.4000.0' { "SQL Server 2008 R2 Service Pack 2 / 2012 July 26" }
		'10.50.2500.0' { "SQL Server 2008 R2 Service Pack 1 / 2011 July 11" }
		'10.50.1600.1' { "SQL Server 2008 R2 RTM / 2010 April 21" }
		'10.00.6556.0' { "Security Update for SQL Server 2008 SP4 GDR (KB4057114) / 2018 January 6" }
		'10.00.6547.0' { "TLS 1.2 support for Microsoft SQL Server 2008 SP4 (updated) / 2016 March 3" }
		'10.00.6543.0' { "TLS 1.2 support for Microsoft SQL Server 2008 SP4 (replaced, see KB3146034) / 2016 January 29" }
		'10.00.6535.0' { "MS15-058: Security Update for SQL Server 2008 SP4 QFE (KB3045308) / 2015 July 14" }
		'10.00.6526.0' { "FIX: On-demand Hotfix Update Package for SQL Server 2008 SP4 (KB3034373) / 2015 February 9" }
		'10.00.6241.0' { "MS15-058: Security Update for SQL Server 2008 SP4 GDR (KB3045311) / 2015 July 14" }
		'10.00.6000.0' { "SQL Server 2008 Service Pack 4 / 2014 September 30" }
		'10.00.5896.0' { "TLS 1.2 support for SQL Server 2008 SP3 (IA-64) (updated) / 2016 March 3" }
		'10.00.5894.0' { "TLS 1.2 support for SQL Server 2008 SP3 (IA-64) (replaced, see KB3146034) / 2016 January 29" }
		'10.00.5890.0' { "MS15-058: Security Update for SQL Server 2008 SP3 QFE (KB3045303) / 2015 July 14" }
		'10.00.5869.0' { "MS14-044: Security Update for SQL Server 2008 SP3 QFE (KB2977322) / 2014 August 12" }
		'10.00.5861.0' { "CU17 for Microsoft SQL Server 2008 SP3(KB2958696) / 2014 May 19" }
		'10.00.5852.0' { "CU16 for Microsoft SQL Server 2008 SP3(KB2936421) / 2014 March 17" }
		'10.00.5850.0' { "CU15 for Microsoft SQL Server 2008 SP3(KB2923520) / 2014 January 20" }
		'10.00.5848.0' { "CU14 for Microsoft SQL Server 2008 SP3(KB2893410) / 2013 November 18" }
		'10.00.5846.0' { "CU13 for Microsoft SQL Server 2008 SP3(KB2880350) / 2013 September 16" }
		'10.00.5844.0' { "CU12 for Microsoft SQL Server 2008 SP3(KB2863205) / 2013 July 16" }
		'10.00.5841.0' { "CU11 (updated) for Microsoft SQL Server 2008 SP3(KB2834048) / 2013 June 13" }
		'10.00.5840.0' { "CU11 (replaced) for Microsoft SQL Server 2008 SP3(KB2834048) / 2013 May 20" }
		'10.00.5835.0' { "CU10 for Microsoft SQL Server 2008 SP3(KB2814783) / 2013 March 18" }
		'10.00.5829.0' { "CU9 for Microsoft SQL Server 2008 SP3(KB2799883) / 2013 January 20" }
		'10.00.5828.0' { "CU8 for Microsoft SQL Server 2008 SP3(KB2771833) / 2012 November 19" }
		'10.00.5826.0' { "MS12-070: Security Update for SQL Server 2008 SP3 QFE (KB2716435) / 2012 October 9" }
		'10.00.5794.0' { "CU7 for Microsoft SQL Server 2008 SP3(KB2738350) / 2012 September 21" }
		'10.00.5788.0' { "CU6 for Microsoft SQL Server 2008 SP3(KB2715953) / 2012 July 16" }
		'10.00.5785.0' { "CU5 for Microsoft SQL Server 2008 SP3(KB2696626) / 2012 May 19" }
		'10.00.5775.0' { "CU4 for Microsoft SQL Server 2008 SP3(KB2673383) / 2012 March 20" }
		'10.00.5770.0' { "CU3 for Microsoft SQL Server 2008 SP3(KB2648098) / 2012 January 16" }
		'10.00.5768.0' { "CU2 for Microsoft SQL Server 2008 SP3(KB2633143) / 2011 November 22" }
		'10.00.5766.0' { "CU1 for Microsoft SQL Server 2008 SP3(KB2617146) / 2011 October 18" }
		'10.00.5545.0' { "TLS 1.2 support for SQL Server 2008 SP3 GDR (IA-64) (updated) / 2016 March 3" }
		'10.00.5544.0' { "TLS 1.2 support for SQL Server 2008 SP3 GDR (IA-64) (replaced, see KB3146034) / 2016 January 29" }
		'10.00.5538.0' { "MS15-058: Security Update for SQL Server 2008 SP3 GDR (KB3045305) / 2015 July 14" }
		'10.00.5520.0' { "MS14-044: Security Update for SQL Server 2008 SP3 GDR (KB2977321) / 2014 August 12" }
		'10.00.5512.0' { "MS12-070: Security Update for SQL Server 2008 SP3 GDR (KB2716436) / 2012 October 9" }
		'10.00.5500.0' { "SQL Server 2008 Service Pack 3 / 2011 October 6" }
		'10.00.4000.0' { "SQL Server 2008 Service Pack 2 / 2010 September 29" }
		'10.00.2531.0' { "SQL Server 2008 Service Pack 1 / 2009 April 7" }
		'10.00.1600.0' { "SQL Server 2008 RTM / 2008 August 7" }
	}
	$OMSQLPropertiesImport.ProductVersion =
	$OMSQLProperties = $OMSQLVersionSwitch + "`n(" + ($OMSQLPropertiesImport).ProductVersion + ") -" + " (" + ($OMSQLPropertiesImport).ProductLevel + ")" + " - " + ($OMSQLPropertiesImport).Edition
	if ($OMSQLPropertiesImport.IsClustered -eq 1)
	{
		$OMSQLProperties = $OMSQLProperties + "`n" + "[Clustered]"
	}
	if ($OMSQLPropertiesImport.Is_Broker_Enabled -eq 1)
	{
		$OMSQLProperties = $OMSQLProperties + "`n" + "[Broker Enabled]"
	}
	if ($OMSQLPropertiesImport.IsFullTextInstalled -eq 1)
	{
		$OMSQLProperties = $OMSQLProperties + "`n" + "[FullText Installed]"
	}
	if ($OMSQLPropertiesImport.Collation -ne 'SQL_Latin1_General_CP1_CI_AS')
	{
		$OMSQLProperties = $OMSQLProperties + " - " + "[ISSUE: " + $OMSQLPropertiesImport.Collation + "] <------------"
	}
	$OMSQLProperties = $OMSQLProperties + "`n"
	Write-Host "-" -NoNewline -ForegroundColor Green
	$DWSQLPropertiesImport = Import-Csv "$OutputPath`\SQL_Properties_DW.csv"
	$DWSQLVersionSwitch = switch ($DWSQLPropertiesImport.ProductVersion)
	{
		'13.0.5830.85' { "CU14 for Microsoft SQL Server 2016 SP2 (KB4564903) / 2020 August 6" }
		'13.0.5820.21' { "CU13 for Microsoft SQL Server 2016 SP2 (KB4549825) / 2020 May 28" }
		'13.0.5698.0' { "CU12 for Microsoft SQL Server 2016 SP2 (KB4536648) / 2020 February 25" }
		'13.0.5622.0' { "Security update for SQL Server 2016 SP2 CU11 (KB4535706) / 2020 February 11" }
		'13.0.5598.27' { "CU11 for Microsoft SQL Server 2016 SP2 (KB4527378) / 2019 December 9" }
		'13.0.5492.2' { "CU10 for Microsoft SQL Server 2016 SP2 (KB4524334) / 2019 October 8" }
		'13.0.5479.0' { "CU9 for Microsoft SQL Server 2016 SP2 (KB4515435) (withdrawn) / 2019 September 30" }
		'13.0.5426.0' { "CU8 for Microsoft SQL Server 2016 SP2 (KB4505830) / 2019 July 31" }
		'13.0.5382.0' { "On-demand hotfix update package for SQL Server 2016 SP2 CU7 (KB4510807) / 2019 July 10" }
		'13.0.5366.0' { "Security update for SQL Server 2016 SP2 CU7 (KB4505222) / 2019 July 9" }
		'13.0.5343.1' { "On-demand hotfix update package for SQL Server 2016 SP2 CU7 (KB4508636) / 2019 June 24" }
		'13.0.5337.0' { "CU7 for Microsoft SQL Server 2016 SP2 (KB4495256) / 2019 May 22" }
		'13.0.5292.0' { "CU6 for Microsoft SQL Server 2016 SP2 (KB4488536) / 2019 March 19" }
		'13.0.5270.0' { "FIX: Restoring backup to SQL Server 2016 from SQL Server 2008 or 2008 R2 takes a long time (KB4490237) / 2019 February 14" }
		'13.0.5264.1' { "CU5 for Microsoft SQL Server 2016 SP2 (KB4475776) / 2019 January 23" }
		'13.0.5239.0' { "FIX: On-demand hotfix update package 2 for SQL Server 2016 SP2 CU4 (KB4482972) / 2018 December 21" }
		'13.0.5233.0' { "CU4 for Microsoft SQL Server 2016 SP2 (KB4464106) / 2018 November 13" }
		'13.0.5216.0' { "CU3 for Microsoft SQL Server 2016 SP2 (KB4458871) / 2018 September 21" }
		'13.0.5201.1' { "Security update for the remote code execution vulnerability in SQL Server 2016 SP2 (CU) (KB4458621) / 2018 August 19" }
		'13.0.5161.0' { "(Replaced) Security update for the remote code execution vulnerability in SQL Server 2016 SP2 (CU) (KB4293807) / 2018 August 14" }
		'13.0.5153.0' { "CU2 for Microsoft SQL Server 2016 SP2 (KB4340355) / 2018 July 16" }
		'13.0.5149.0' { "CU1 for Microsoft SQL Server 2016 SP2 (KB4135048) / 2018 May 29" }
		'13.0.5102.14' { "Security update for SQL Server 2016 SP2 GDR (KB4532097) / 2020 February 11" }
		'13.0.5101.9' { "Security update for SQL Server 2016 SP2 GDR (KB4505220) / 2019 July 9" }
		'13.0.5081.1' { "Security update for the remote code execution vulnerability in SQL Server 2016 SP2 GDR (KB4293802) / 2018 August 14" }
		'13.0.5026.0' { "SQL Server 2016 Service Pack 2 (SP2) / 2018 April 24" }
		'13.0.4604.0' { "Security update for SQL Server 2016 SP1 CU15 GDR (KB4505221) / 2019 July 9" }
		'13.0.4577.0' { "On-demand hotfix update package for SQL Server 2016 SP1 CU15 (KB4508471) / 2019 June 20" }
		'13.0.4574.0' { "CU15 for Microsoft SQL Server 2016 SP1 (KB4495257) / 2019 May 16" }
		'13.0.4560.0' { "CU14 for Microsoft SQL Server 2016 SP1 (KB4488535) / 2019 March 19" }
		'13.0.4550.1' { "CU13 for Microsoft SQL Server 2016 SP1 (KB4475775) / 2019 January 23" }
		'13.0.4541.0' { "CU12 for Microsoft SQL Server 2016 SP1 (KB4464343) / 2018 November 13" }
		'13.0.4531.0' { "FIX: The `"modification_counter`" in DMV sys.dm_db_stats_properties shows incorrect value when partitions are merged through ALTER PARTITION in SQL Server 2016 (KB4465443) / 2018 September 27" }
		'13.0.4528.0' { "CU11 for Microsoft SQL Server 2016 SP1 (KB4459676) / 2018 September 18" }
		'13.0.4522.0' { "Security update for the remote code execution vulnerability in SQL Server 2016 SP1 (CU) (KB4293808) / 2018 August 14" }
		'13.0.4514.0' { "CU10 for Microsoft SQL Server 2016 SP1 (KB4341569) / 2018 July 16" }
		'13.0.4502.0' { "CU9 for Microsoft SQL Server 2016 SP1 (KB4100997) / 2018 May 29" }
		'13.0.4474.0' { "CU8 for Microsoft SQL Server 2016 SP1 (KB4077064) / 2018 March 19" }
		'13.0.4466.4' { "CU7 for Microsoft SQL Server 2016 SP1 (KB4057119) / 2018 January 4" }
		'13.0.4457.0' { "CU6 for Microsoft SQL Server 2016 SP1 (KB4037354) / 2017 November 21" }
		'13.0.4451.0' { "CU5 for Microsoft SQL Server 2016 SP1 (KB4040714) / 2017 September 18" }
		'13.0.4446.0' { "CU4 for Microsoft SQL Server 2016 SP1 (KB4024305) / 2017 August 8" }
		'13.0.4435.0' { "CU3 for Microsoft SQL Server 2016 SP1 (KB4019916) / 2017 May 15" }
		'13.0.4422.0' { "CU2 for Microsoft SQL Server 2016 SP1 (KB4013106) / 2017 March 20" }
		'13.0.4411.0' { "CU1 for Microsoft SQL Server 2016 SP1 (KB3208177) / 2017 January 18" }
		'13.0.4259.0' { "Security update for SQL Server 2016 SP1 GDR (KB4505219) / 2019 July 9" }
		'13.0.4224.16' { "Security update for the remote code execution vulnerability in SQL Server 2016 SP1 (GDR) (KB4458842) / 2018 August 22" }
		'13.0.4223.10' { "(Replaced) Security update for the remote code execution vulnerability in SQL Server 2016 SP1 (GDR) (KB4293801) / 2018 August 14" }
		'13.0.4210.6' { "Security Update for SQL Server 2016 Service Pack 1 GDR (KB4057118) / 2018 January 4" }
		'13.0.4206.0' { "Security Update for SQL Server 2016 Service Pack 1 GDR (KB4019089) / 2017 August 8" }
		'13.0.4202.2' { "GDR update package for SQL Server 2016 SP1 (KB3210089) / 2016 December 16" }
		'13.0.4199.0' { "FIX: Important update for SQL Server 2016 SP1 Reporting Services (KB3207512) / 2016 November 23" }
		'13.0.4001.0' { "SQL Server 2016 Service Pack 1 (SP1) / 2016 November 16" }
		'13.0.2218.0' { "Security Update for SQL Server 2016 RTM CU (KB4058559) / 2018 January 8" }
		'13.0.2216.0' { "CU9 for Microsoft SQL Server 2016 RTM (KB4037357) / 2017 November 21" }
		'13.0.2213.0' { "CU8 for Microsoft SQL Server 2016 RTM (KB4040713) / 2017 September 18" }
		'13.0.2210.0' { "CU7 for Microsoft SQL Server 2016 RTM (KB4024304) / 2017 August 8" }
		'13.0.2204.0' { "CU6 for Microsoft SQL Server 2016 RTM (KB4019914) / 2017 May 15" }
		'13.0.2197.0' { "CU5 for Microsoft SQL Server 2016 RTM (KB4013105) / 2017 March 20" }
		'13.0.2193.0' { "CU4 for Microsoft SQL Server 2016 RTM (KB3205052) / 2017 January 18" }
		'13.0.2186.6' { "MS16-136: CU3 for Microsoft SQL Server 2016 RTM (KB3205413) / 2016 November 8" }
		'13.0.2170.0' { "FIX: On-demand hotfix update package for SQL Server 2016 CU2 RTM (KB3199171) / 2016 October 26" }
		'13.0.2169.0' { "FIX: On-demand hotfix update package for SQL Server 2016 CU2 RTM (KB3195813) / 2016 October 26" }
		'13.0.2164.0' { "CU2 for Microsoft SQL Server 2016 RTM (KB3182270) / 2016 September 22" }
		'13.0.2149.0' { "CU1 for Microsoft SQL Server 2016 RTM (KB3164674) / 2016 July 26" }
		'13.0.1745.2' { "Security Update for SQL Server 2016 RTM GDR (KB4058560) / 2018 January 8" }
		'13.0.1742.0' { "Security Update for SQL Server 2016 RTM GDR (KB4019088) / 2017 August 8" }
		'13.0.1728.2' { "GDR update package for SQL Server 2016 RTM (KB3210111) / 2016 December 16" }
		'13.0.1722.0' { "MS16-136: Security Update for SQL Server 2016 GDR (KB3194716) / 2016 November 8" }
		'13.0.1711.0' { "FIX: Processing a partition causes data loss on other partitions after the database is restored in SQL Server 2016 (1200) (KB3179258) / 2016 August 11" }
		'13.0.1708.0' { "Critical update for SQL Server 2016 MSVCRT prerequisites / 2016 June 3" }
		'13.0.1601.5' { "SQL Server 2016 RTM / 2016 June 1" }
		'12.0.6372.1' { "Security update for SQL Server 2014 SP3 CU4 (KB4535288) / 2020 February 11" }
		'12.0.6329.1' { "CU4 for Microsoft SQL Server 2014 SP3 (KB4500181) / 2019 July 29" }
		'12.0.6293.0' { "Security update for SQL Server 2014 SP3 CU3 (KB4505422) / 2019 July 9" }
		'12.0.6259.0' { "CU3 for Microsoft SQL Server 2014 SP3 (KB4491539) / 2019 April 16" }
		'12.0.6214.1' { "CU2 for Microsoft SQL Server 2014 SP3 (KB4482960) / 2019 February 19" }
		'12.0.6205.1' { "CU1 for Microsoft SQL Server 2014 SP3 (KB4470220) / 2018 December 13" }
		'12.0.6118.4' { "Security update for SQL Server 2014 SP3 GDR (KB4532095) / 2020 February 11" }
		'12.0.6108.1' { "Security update for SQL Server 2014 SP3 GDR (KB4505218) / 2019 July 9" }
		'12.0.6024.0' { "Microsoft SQL Server 2014 Service Pack 3 (SP3) / 2018 October 30" }
		'12.0.5687.1' { "CU18 for Microsoft SQL Server 2014 SP2 (KB4500180) / 2019 July 29" }
		'12.0.5659.1' { "Security update for SQL Server 2014 SP2 CU17 GDR (KB4505419) / 2019 July 9" }
		'12.0.5632.1' { "CU17 for Microsoft SQL Server 2014 SP2 (KB4491540) / 2019 April 16" }
		'12.0.5626.1' { "CU16 for Microsoft SQL Server 2014 SP2 (KB4482967) / 2019 February 19" }
		'12.0.5605.1' { "CU15 for Microsoft SQL Server 2014 SP2 (KB4469137) / 2018 December 13" }
		'12.0.5600.1' { "CU14 for Microsoft SQL Server 2014 SP2 (KB4459860) / 2018 October 15" }
		'12.0.5590.1' { "CU13 for Microsoft SQL Server 2014 SP2 (KB4456287) / 2018 August 27" }
		'12.0.5589.7' { "CU12 for Microsoft SQL Server 2014 SP2 (KB4130489) / 2018 June 18" }
		'12.0.5579.0' { "CU11 for Microsoft SQL Server 2014 SP2 (KB4077063) / 2018 March 19" }
		'12.0.5571.0' { "CU10 for Microsoft SQL Server 2014 SP2 (KB4052725) / 2018 January 16" }
		'12.0.5563.0' { "CU9 for Microsoft SQL Server 2014 SP2 (KB4055557) / 2017 December 18" }
		'12.0.5557.0' { "CU8 for Microsoft SQL Server 2014 SP2 (KB4037356) / 2017 October 17" }
		'12.0.5556.0' { "CU7 for Microsoft SQL Server 2014 SP2 (KB4032541) / 2017 August 28" }
		'12.0.5553.0' { "CU6 for Microsoft SQL Server 2014 SP2 (KB4019094) / 2017 August 8" }
		'12.0.5546.0' { "CU5 for Microsoft SQL Server 2014 SP2 (KB4013098) / 2017 April 17" }
		'12.0.5540.0' { "CU4 for Microsoft SQL Server 2014 SP2 (KB4010394) / 2017 February 21" }
		'12.0.5538.0' { "CU3 for Microsoft SQL Server 2014 SP2 (KB3204388) / 2016 December 28" }
		'12.0.5532.0' { "MS16-136: Security Update for SQL Server 2014 Service Pack 2 CU (KB3194718) / 2016 November 8" }
		'12.0.5522.0' { "CU2 for Microsoft SQL Server 2014 SP2 (KB3188778) / 2016 October 17" }
		'12.0.5511.0' { "CU1 for Microsoft SQL Server 2014 SP2 (KB3178925) / 2016 August 26" }
		'12.0.5223.6' { "Security update for SQL Server 2014 SP2 GDR (KB4505217) / 2019 July 9" }
		'12.0.5214.6' { "Security Update for SQL Server 2014 Service Pack 2 GDR (KB4057120) / 2018 January 16" }
		'12.0.5207.0' { "Security Update for SQL Server 2014 Service Pack 2 GDR (KB4019093) / 2017 August 8" }
		'12.0.5203.0' { "MS16-136: Security Update for SQL Server 2014 Service Pack 2 GDR (KB3194714) / 2016 November 8" }
		'12.0.5000.0' { "Microsoft SQL Server 2014 Service Pack 2 (SP2) / 2016 July 11" }
		'12.0.4522.0' { "CU13 for Microsoft SQL Server 2014 SP1 (KB4019099) / 2017 August 8" }
		'12.0.4511.0' { "CU12 for Microsoft SQL Server 2014 SP1 (KB4017793) / 2017 April 17" }
		'12.0.4502.0' { "CU11 for Microsoft SQL Server 2014 SP1 (KB4010392) / 2017 February 21" }
		'12.0.4491.0' { "CU10 for Microsoft SQL Server 2014 SP1 (KB3204399) / 2016 December 28" }
		'12.0.4487.0' { "MS16-136: Security Update for SQL Server 2014 Service Pack 1 CU (KB3194722) / 2016 November 8" }
		'12.0.4474.0' { "CU9 for Microsoft SQL Server 2014 SP1 (KB3186964) / 2016 October 17" }
		'12.0.4468.0' { "CU8 for Microsoft SQL Server 2014 SP1 (KB3174038) / 2016 August 15" }
		'12.0.4463.0' { "FIX: A memory leak occurs when you use Azure Storage in SQL Server 2014 (KB3174370) / 2016 August 4" }
		'12.0.4459.0' { "CU7 for Microsoft SQL Server 2014 SP1 (KB3162659) / 2016 June 20" }
		'12.0.4457.0' { "CU6 (re-released) for Microsoft SQL Server 2014 SP1 (KB3167392) / 2016 May 30" }
		'12.0.4449.0' { "CU6 (replaced) for Microsoft SQL Server 2014 SP1 (KB3144524) / 2016 April 18" }
		'12.0.4439.1' { "CU5 for Microsoft SQL Server 2014 SP1 (KB3130926) / 2016 February 21" }
		'12.0.4437.0' { "On-demand hotfix update package for SQL Server 2014 SP1 CU4 (KB3130999) / 2016 February 5" }
		'12.0.4436.0' { "CU4 for Microsoft SQL Server 2014 SP1 (KB3106660) / 2015 December 22" }
		'12.0.4427.24' { "CU3 for Microsoft SQL Server 2014 SP1 (KB3094221) / 2015 October 20" }
		'12.0.4422.0' { "CU2 for Microsoft SQL Server 2014 SP1 (KB3075950) / 2015 August 17" }
		'12.0.4416.0' { "CU1 for Microsoft SQL Server 2014 SP1 (KB3067839) / 2015 June 22" }
		'12.0.4237.0' { "Security Update for SQL Server 2014 Service Pack 1 GDR (KB4019091) / 2017 August 8" }
		'12.0.4232.0' { "MS16-136: Security Update for SQL Server 2014 Service Pack 1 GDR (KB3194720) / 2016 November 8" }
		'12.0.4219.0' { "TLS 1.2 support for Microsoft SQL Server 2014 SP1 GDR / 2016 January 29" }
		'12.0.4213.0' { "MS15-058: Nonsecurity update for SQL Server 2014 SP1 (GDR) (KB3070446) / 2015 July 14" }
		'12.0.4100.1' { "Microsoft SQL Server 2014 Service Pack 1 / 2015 May 15" }
		'12.0.2569.0' { "CU14 for Microsoft SQL Server 2014 (KB3158271) / 2016 June 20" }
		'12.0.2568.0' { "CU13 for Microsoft SQL Server 2014 (KB3144517) / 2016 April 18" }
		'12.0.2564.0' { "CU12 for Microsoft SQL Server 2014 (KB3130923) / 2016 February 21" }
		'12.0.2560.0' { "CU11 for Microsoft SQL Server 2014 (KB3106659) / 2015 December 22" }
		'12.0.2556.4' { "CU10 for Microsoft SQL Server 2014 (KB3094220) / 2015 October 20" }
		'12.0.2553.0' { "CU9 for Microsoft SQL Server 2014 (KB3075949) / 2015 August 17" }
		'12.0.2548.0' { "MS15-058: Security update for SQL Server 2014 (QFE) (KB3045323) / 2015 July 14" }
		'12.0.2546.0' { "CU8 for Microsoft SQL Server 2014 (KB3067836) / 2015 June 22" }
		'12.0.2495.0' { "CU7 for Microsoft SQL Server 2014 (KB3046038) / 2015 April 23" }
		'12.0.2480.0' { "CU6 for Microsoft SQL Server 2014 (KB3031047) / 2015 February 16" }
		'12.0.2474.0' { "FIX: AlwaysOn availability groups are reported as NOT SYNCHRONIZING (KB3034679) / 2014 February 4" }
		'12.0.2456.0' { "CU5 for Microsoft SQL Server 2014 (KB3011055) / 2014 December 18" }
		'12.0.2430.0' { "CU4 for Microsoft SQL Server 2014 (KB2999197) / 2014 October 21" }
		'12.0.2402.0' { "CU3 for Microsoft SQL Server 2014 (KB2984923) / 2014 August 18" }
		'12.0.2381.0' { "MS14-044: Security update for SQL Server 2014 (QFE) (KB2977316) / 2014 August 12" }
		'12.0.2370.0' { "CU2 for Microsoft SQL Server 2014 (KB2967546) / 2014 June 27" }
		'12.0.2342.0' { "CU1 for Microsoft SQL Server 2014 (KB2931693) / 2014 April 21" }
		'12.0.2271.0' { "TLS 1.2 support for Microsoft SQL Server 2014 GDR / 2016 January 29" }
		'12.0.2269.0' { "MS15-058: Security Update for SQL Server 2014 (GDR) (KB3045324) / 2015 July 14" }
		'12.0.2254.0' { "MS14-044: Security Update for SQL Server 2014 (GDR) (KB2977315) / 2014 August 12" }
		'12.0.2000.8' { "Microsoft SQL Server 2014 RTM / 2014 April 1" }
		'11.0.7493.4' { "Security Update for SQL Server 2012 SP4 GDR (KB4532098) / 2020 February 11" }
		'11.0.7469.6' { "On-demand hotfix update package for SQL Server 2012 SP4 (KB4091266) / 2018 March 28" }
		'11.0.7462.6' { "Security Update for SQL Server 2012 SP4 GDR (KB4057116) / 2018 January 12" }
		'11.0.7001.0' { "SQL Server 2012 Service Pack 4 (KB4018073) / 2017 October 5" }
		'11.0.6615.2' { "Security Update for SQL Server 2012 SP3 CU (KB4057121) / 2018 January 16" }
		'11.0.6607.3' { "CU10 for Microsoft SQL Server 2012 SP3 (KB4025925) / 2017 August 8" }
		'11.0.6598.0' { "CU9 for Microsoft SQL Server 2012 SP3 (KB4016762) / 2017 May 15" }
		'11.0.6594.0' { "CU8 for Microsoft SQL Server 2012 SP3 (KB4013104) / 2017 March 21" }
		'11.0.6579.0' { "CU7 for Microsoft SQL Server 2012 SP3 (KB3205051) / 2017 January 18" }
		'11.0.6567.0' { "MS16-136: CU6 for Microsoft SQL Server 2012 SP3 (KB3194992) / 2016 November 8" }
		'11.0.6544.0' { "CU5 for Microsoft SQL Server 2012 SP3 (KB3180915) / 2016 September 20" }
		'11.0.6540.0' { "CU4 for Microsoft SQL Server 2012 SP3 (KB3165264) / 2016 July 18" }
		'11.0.6537.0' { "CU3 for Microsoft SQL Server 2012 SP3 (KB3152635) / 2016 May 15" }
		'11.0.6523.0' { "CU2 for Microsoft SQL Server 2012 SP3 (KB3137746) / 2016 March 22" }
		'11.0.6518.0' { "CU1 for Microsoft SQL Server 2012 SP3 (KB3123299) / 2016 January 19" }
		'11.0.6260.1' { "Security Update for SQL Server 2012 Service Pack 3 GDR (KB4057115) / 2018 January 16" }
		'11.0.6251.0' { "Security Update for SQL Server 2012 Service Pack 3 GDR (KB4019092) / 2017 August 8" }
		'11.0.6248.0' { "MS16-136: Security Update for SQL Server 2012 Service Pack 3 GDR (KB3194721) / 2016 November 8" }
		'11.0.6216.27' { "TLS 1.2 support for Microsoft SQL Server 2012 SP3 GDR / 2016 January 29" }
		'11.0.6020.0' { "SQL Server 2012 Service Pack 3 (KB3072779) / 2015 November 21" }
		'11.0.5678.0' { "CU16 for Microsoft SQL Server 2012 SP2 (KB3205054) / 2017 January 18" }
		'11.0.5676.0' { "MS16-136: CU15 for Microsoft SQL Server 2012 SP2 (KB3205416) / 2016 November 8" }
		'11.0.5657.0' { "CU14 for Microsoft SQL Server 2012 SP2 (KB3180914) / 2016 September 20" }
		'11.0.5655.0' { "CU13 for Microsoft SQL Server 2012 SP2 (KB3165266) / 2016 July 18" }
		'11.0.5649.0' { "CU12 for Microsoft SQL Server 2012 SP2 (KB3152637) / 2016 May 15" }
		'11.0.5646.0' { "CU11 for Microsoft SQL Server 2012 SP2 (KB3137745) / 2016 March 22" }
		'11.0.5644.2' { "CU10 for Microsoft SQL Server 2012 SP2 (KB3120313) / 2016 January 19" }
		'11.0.5641.0' { "CU9 for Microsoft SQL Server 2012 SP2 (KB3098512) / 2015 November 18" }
		'11.0.5634.1' { "CU8 for Microsoft SQL Server 2012 SP2 (KB3082561) / 2015 September 21" }
		'11.0.5623.0' { "CU7 for Microsoft SQL Server 2012 SP2 (KB3072100) / 2015 July 20" }
		'11.0.5613.0' { "MS15-058: Security Update for SQL Server 2012 SP2 QFE (KB3045319) / 2015 July 14" }
		'11.0.5592.0' { "CU6 for Microsoft SQL Server 2012 SP2 (KB3052468) / 2015 May 18" }
		'11.0.5582.0' { "CU5 for Microsoft SQL Server 2012 SP2 (KB3037255) / 2015 March 16" }
		'11.0.5571.0' { "FIX: AlwaysOn availability groups are reported as NOT SYNCHRONIZING (KB3034679) / 2015 February 4" }
		'11.0.5569.0' { "CU4 for Microsoft SQL Server 2012 SP2 (KB3007556) / 2015 January 20" }
		'11.0.5556.0' { "CU3 for Microsoft SQL Server 2012 SP2 (KB3002049) / 2014 November 17" }
		'11.0.5548.0' { "CU2 for Microsoft SQL Server 2012 SP2 (KB2983175) / 2014 September 15" }
		'11.0.5532.0' { "CU1 for Microsoft SQL Server 2012 SP2 (KB2976982) / 2014 July 23" }
		'11.0.5522.0' { "FIX for SQL Server 2012 SP2: Data loss in clustered index (KB2969896) / 2014 June 20" }
		'11.0.5388.0' { "MS16-136: Security Update for SQL Server 2012 Service Pack 2 GD2 (KB3194719) / 2016 November 8" }
		'11.0.5352.0' { "TLS 1.2 support for Microsoft SQL Server 2012 SP2 GDR / 2016 January 29" }
		'11.0.5343.0' { "MS15-058: Security Update for SQL Server 2012 SP2 GDR (KB3045321) / 2014 July 14" }
		'11.0.5058.0' { "SQL Server 2012 Service Pack 2 (KB2958429) / 2014 June 10" }
		'11.0.3513.0' { "MS15-058: Security Update for SQL Server 2012 SP1 QFE (KB3045317) / 2015 July 14" }
		'11.0.3492.0' { "CU16 for Microsoft SQL Server 2012 SP1 (KB3052476) / 2015 May 18" }
		'11.0.3487.0' { "CU15 for Microsoft SQL Server 2012 SP1 (KB3038001) / 2015 March 16" }
		'11.0.3486.0' { "CU14 for Microsoft SQL Server 2012 SP1 (KB3007556) / 2015 January 21" }
		'11.0.3482.0' { "CU13 for Microsoft SQL Server 2012 SP1 (KB3002044) / 2014 November 17" }
		'11.0.3470.0' { "CU12 for Microsoft SQL Server 2012 SP1 (KB2975396) / 2014 September 15" }
		'11.0.3467.0' { "FIX: Log Reader Agent crashes during initialization when you use transactional replication in SQL Server(KB2975402) / 2014 August 28" }
		'11.0.3460.0' { "MS14-044: Security Update for Microsoft SQL Server 2012 SP1 (QFE)(KB2977325) / 2014 August 12" }
		'11.0.3449.0' { "CU11 for Microsoft SQL Server 2012 SP1 (KB2975396) / 2014 July 21" }
		'11.0.3437.0' { "FIX for SQL Server 2012 SP1: Data loss in clustered index (KB2969896) / 2014 June 10" }
		'11.0.3431.0' { "CU10 for Microsoft SQL Server 2012 SP1 (KB2954099) / 2014 May 19" }
		'11.0.3412.0' { "CU9 for Microsoft SQL Server 2012 SP1 (KB2931078) / 2014 March 18" }
		'11.0.3401.0' { "CU8 for Microsoft SQL Server 2012 SP1 (KB2917531) / 2014 January 20" }
		'11.0.3393.0' { "CU7 for Microsoft SQL Server 2012 SP1 (KB2894115) / 2013 November 18" }
		'11.0.3381.0' { "CU6 for Microsoft SQL Server 2012 SP1 (KB2874879) / 2013 September 16" }
		'11.0.3373.0' { "CU5 for Microsoft SQL Server 2012 SP1 (KB2861107) / 2013 July 16" }
		'11.0.3368.0' { "CU4 for Microsoft SQL Server 2012 SP1 (KB2833645) / 2013 May 31" }
		'11.0.3349.0' { "CU3 for Microsoft SQL Server 2012 SP1 (KB2812412) / 2013 March 18" }
		'11.0.3339.0' { "CU2 for Microsoft SQL Server 2012 SP1 (KB2790947) / 2013 January 25" }
		'11.0.3321.0' { "CU1 for Microsoft SQL Server 2012 SP1 (KB2765331) / 2012 November 20" }
		'11.0.3156.0' { "MS15-058: Security Update for SQL Server 2012 SP1 GDR (KB3045318) / 2015 July 14" }
		'11.0.3153.0' { "MS14-044: Security Update for SQL Server 2012 SP1 GDR (KB2977326) / 2014 August 12" }
		'11.0.3128.0' { "FIX: Windows Installer starts repeatedly after you install SQL Server 2012 SP1 (KB2793634) / 2013 January 3" }
		'11.0.3000.0' { "SQL Server 2012 Service Pack 1 (KB2674319) / 2012 November 6" }
		'11.0.2424.0' { "CU11 for Microsoft SQL Server 2012 (KB2908007) / 2013 December 17" }
		'11.0.2420.0' { "CU10 for Microsoft SQL Server 2012 (KB2891666) / 2013 October 21" }
		'11.0.2419.0' { "CU9 for Microsoft SQL Server 2012 (KB2867319) / 2013 August 21" }
		'11.0.2410.0' { "CU8 for Microsoft SQL Server 2012 (KB2844205) / 2013 June 18" }
		'11.0.2405.0' { "CU7 for Microsoft SQL Server 2012 (KB2823247) / 2013 April 15" }
		'11.0.2401.0' { "CU6 for Microsoft SQL Server 2012 (KB2728897) / 2013 February 18" }
		'11.0.2395.0' { "CU5 for Microsoft SQL Server 2012 (KB2777772) / 2012 December 18" }
		'11.0.2383.0' { "CU4 for Microsoft SQL Server 2012 (KB2758687) / 2012 October 18" }
		'11.0.2376.0' { "MS12-070: Security Update for SQL Server 2012 QFE (KB2716441) / 2012 October 9" }
		'11.0.2332.0' { "CU3 for Microsoft SQL Server 2012 (KB2723749) / 2012 August 29" }
		'11.0.2325.0' { "CU2 for Microsoft SQL Server 2012 (KB2703275) / 2012 June 18" }
		'11.0.2316.0' { "CU1 for Microsoft SQL Server 2012 (KB2679368) / 2012 April 12" }
		'11.0.2218.0' { "MS12-070: Security Update for SQL Server 2012 GDR (KB2716442) / 2012 October 9" }
		'11.0.2100.0' { "SQL Server 2012 RTM / 2012 March 6" }
		'10.50.6560.0' { "Security Update for SQL Server 2008 R2 SP3 GDR (KB4057113) / 2018 January 6" }
		'10.50.6542.0' { "TLS 1.2 support for Microsoft SQL Server 2008 R2 SP3 (updated) / 2016 March 3" }
		'10.50.6537.0' { "TLS 1.2 support for Microsoft SQL Server 2008 R2 SP3 (replaced, see KB3146034) / 2016 January 29" }
		'10.50.6529.0' { "MS15-058: Security Update for SQL Server 2008 R2 SP3 QFE (KB3045314) / 2015 July 14" }
		'10.50.6525.0' { "FIX: On-demand Hotfix Update Package for SQL Server 2008 R2 SP3 (KB3033860) / 2015 February 9" }
		'10.50.6220.0' { "MS15-058: Security Update for SQL Server 2008 R2 SP3 GDR (KB3045316) / 2015 July 14" }
		'10.50.6000.34' { "SQL Server 2008 R2 Service Pack 3 / 2014 September 26" }
		'10.50.4344.0' { "TLS 1.2 support for SQL Server 2008 R2 SP2 (IA-64) (updated) / 2016 March 3" }
		'10.50.4343.0' { "TLS 1.2 support for SQL Server 2008 R2 SP2 (IA-64) (replaced, see KB3146034) / 2016 January 29" }
		'10.50.4339.0' { "MS15-058: Security Update for SQL Server 2008 R2 SP2 QFE (KB3045312) / 2015 July 14" }
		'10.50.4331.0' { "MS14-044: Security Update for SQL Server 2008 R2 SP2 QFE (KB2977319) / 2014 August 12" }
		'10.50.4319.0' { "CU13 for Microsoft SQL Server 2008 R2 SP2(KB2967540) / 2014 June 30" }
		'10.50.4305.0' { "CU12 for Microsoft SQL Server 2008 R2 SP2(KB2938478) / 2014 April 21" }
		'10.50.4302.0' { "CU11 for Microsoft SQL Server 2008 R2 SP2(KB2926028) / 2014 February 18" }
		'10.50.4297.0' { "CU10 for Microsoft SQL Server 2008 R2 SP2(KB2908087) / 2013 December 16" }
		'10.50.4295.0' { "CU9 for Microsoft SQL Server 2008 R2 SP2(KB2887606) / 2013 October 29" }
		'10.50.4290.0' { "CU8 for Microsoft SQL Server 2008 R2 SP2(KB2871401) / 2013 August 30" }
		'10.50.4286.0' { "CU7 for Microsoft SQL Server 2008 R2 SP2(KB2844090) / 2013 June 17" }
		'10.50.4285.0' { "CU6 re-released for Microsoft SQL Server 2008 R2 SP2(KB2830140) / 2013 June 13" }
		'10.50.4279.0' { "CU6 (replaced) for Microsoft SQL Server 2008 R2 SP2(KB2830140) / 2013 April 15" }
		'10.50.4276.0' { "CU5 for Microsoft SQL Server 2008 R2 SP2(KB2797460) / 2013 February 18" }
		'10.50.4270.0' { "CU4 for Microsoft SQL Server 2008 R2 SP2(KB2777358) / 2012 December 17" }
		'10.50.4266.0' { "CU3 for Microsoft SQL Server 2008 R2 SP2(KB2754552) / 2012 October 15" }
		'10.50.4263.0' { "CU2 for Microsoft SQL Server 2008 R2 SP2(KB2740411) / 2012 August 29" }
		'10.50.4260.0' { "CU1 for Microsoft SQL Server 2008 R2 SP2(KB2720425) / 2012 August 1" }
		'10.50.4047.0' { "TLS 1.2 support for SQL Server 2008 R2 SP2 GDR (IA-64) (updated) / 2016 March 3" }
		'10.50.4046.0' { "TLS 1.2 support for SQL Server 2008 R2 SP2 GDR (IA-64) (replaced, see KB3146034) / 2016 January 29" }
		'10.50.4042.0' { "MS15-058: Security Update for SQL Server 2008 R2 SP2 GDR (KB3045313) / 2015 July 14" }
		'10.50.4033.0' { "MS14-044: Security Update for SQL Server 2008 R2 SP2 GDR (KB2977320) / 2014 August 12" }
		'10.50.4000.0' { "SQL Server 2008 R2 Service Pack 2 / 2012 July 26" }
		'10.50.2500.0' { "SQL Server 2008 R2 Service Pack 1 / 2011 July 11" }
		'10.50.1600.1' { "SQL Server 2008 R2 RTM / 2010 April 21" }
		'10.00.6556.0' { "Security Update for SQL Server 2008 SP4 GDR (KB4057114) / 2018 January 6" }
		'10.00.6547.0' { "TLS 1.2 support for Microsoft SQL Server 2008 SP4 (updated) / 2016 March 3" }
		'10.00.6543.0' { "TLS 1.2 support for Microsoft SQL Server 2008 SP4 (replaced, see KB3146034) / 2016 January 29" }
		'10.00.6535.0' { "MS15-058: Security Update for SQL Server 2008 SP4 QFE (KB3045308) / 2015 July 14" }
		'10.00.6526.0' { "FIX: On-demand Hotfix Update Package for SQL Server 2008 SP4 (KB3034373) / 2015 February 9" }
		'10.00.6241.0' { "MS15-058: Security Update for SQL Server 2008 SP4 GDR (KB3045311) / 2015 July 14" }
		'10.00.6000.0' { "SQL Server 2008 Service Pack 4 / 2014 September 30" }
		'10.00.5896.0' { "TLS 1.2 support for SQL Server 2008 SP3 (IA-64) (updated) / 2016 March 3" }
		'10.00.5894.0' { "TLS 1.2 support for SQL Server 2008 SP3 (IA-64) (replaced, see KB3146034) / 2016 January 29" }
		'10.00.5890.0' { "MS15-058: Security Update for SQL Server 2008 SP3 QFE (KB3045303) / 2015 July 14" }
		'10.00.5869.0' { "MS14-044: Security Update for SQL Server 2008 SP3 QFE (KB2977322) / 2014 August 12" }
		'10.00.5861.0' { "CU17 for Microsoft SQL Server 2008 SP3(KB2958696) / 2014 May 19" }
		'10.00.5852.0' { "CU16 for Microsoft SQL Server 2008 SP3(KB2936421) / 2014 March 17" }
		'10.00.5850.0' { "CU15 for Microsoft SQL Server 2008 SP3(KB2923520) / 2014 January 20" }
		'10.00.5848.0' { "CU14 for Microsoft SQL Server 2008 SP3(KB2893410) / 2013 November 18" }
		'10.00.5846.0' { "CU13 for Microsoft SQL Server 2008 SP3(KB2880350) / 2013 September 16" }
		'10.00.5844.0' { "CU12 for Microsoft SQL Server 2008 SP3(KB2863205) / 2013 July 16" }
		'10.00.5841.0' { "CU11 (updated) for Microsoft SQL Server 2008 SP3(KB2834048) / 2013 June 13" }
		'10.00.5840.0' { "CU11 (replaced) for Microsoft SQL Server 2008 SP3(KB2834048) / 2013 May 20" }
		'10.00.5835.0' { "CU10 for Microsoft SQL Server 2008 SP3(KB2814783) / 2013 March 18" }
		'10.00.5829.0' { "CU9 for Microsoft SQL Server 2008 SP3(KB2799883) / 2013 January 20" }
		'10.00.5828.0' { "CU8 for Microsoft SQL Server 2008 SP3(KB2771833) / 2012 November 19" }
		'10.00.5826.0' { "MS12-070: Security Update for SQL Server 2008 SP3 QFE (KB2716435) / 2012 October 9" }
		'10.00.5794.0' { "CU7 for Microsoft SQL Server 2008 SP3(KB2738350) / 2012 September 21" }
		'10.00.5788.0' { "CU6 for Microsoft SQL Server 2008 SP3(KB2715953) / 2012 July 16" }
		'10.00.5785.0' { "CU5 for Microsoft SQL Server 2008 SP3(KB2696626) / 2012 May 19" }
		'10.00.5775.0' { "CU4 for Microsoft SQL Server 2008 SP3(KB2673383) / 2012 March 20" }
		'10.00.5770.0' { "CU3 for Microsoft SQL Server 2008 SP3(KB2648098) / 2012 January 16" }
		'10.00.5768.0' { "CU2 for Microsoft SQL Server 2008 SP3(KB2633143) / 2011 November 22" }
		'10.00.5766.0' { "CU1 for Microsoft SQL Server 2008 SP3(KB2617146) / 2011 October 18" }
		'10.00.5545.0' { "TLS 1.2 support for SQL Server 2008 SP3 GDR (IA-64) (updated) / 2016 March 3" }
		'10.00.5544.0' { "TLS 1.2 support for SQL Server 2008 SP3 GDR (IA-64) (replaced, see KB3146034) / 2016 January 29" }
		'10.00.5538.0' { "MS15-058: Security Update for SQL Server 2008 SP3 GDR (KB3045305) / 2015 July 14" }
		'10.00.5520.0' { "MS14-044: Security Update for SQL Server 2008 SP3 GDR (KB2977321) / 2014 August 12" }
		'10.00.5512.0' { "MS12-070: Security Update for SQL Server 2008 SP3 GDR (KB2716436) / 2012 October 9" }
		'10.00.5500.0' { "SQL Server 2008 Service Pack 3 / 2011 October 6" }
		'10.00.4000.0' { "SQL Server 2008 Service Pack 2 / 2010 September 29" }
		'10.00.2531.0' { "SQL Server 2008 Service Pack 1 / 2009 April 7" }
		'10.00.1600.0' { "SQL Server 2008 RTM / 2008 August 7" }
	}
	$DWSQLProperties = $DWSQLVersionSwitch + "`n(" + ($DWSQLPropertiesImport).ProductVersion + ") - (" + ($DWSQLPropertiesImport).ProductLevel + ") - " + ($DWSQLPropertiesImport).Edition
	if ($DWSQLPropertiesImport.IsClustered -eq 1)
	{
		$DWSQLProperties = $DWSQLProperties + "`n" + "[Clustered]"
	}
	if ($DWSQLPropertiesImport.Is_Broker_Enabled -eq 1)
	{
		$DWSQLProperties = $DWSQLProperties + "`n" + "[Broker Enabled]"
	}
	if ($DWSQLPropertiesImport.IsFullTextInstalled -eq 1)
	{
		$DWSQLProperties = $DWSQLProperties + "`n" + "[FullText Installed]"
	}
	if ($DWSQLPropertiesImport.Collation -ne 'SQL_Latin1_General_CP1_CI_AS')
	{
		$DWSQLProperties = $DWSQLProperties + "`n" + "(ISSUE: " + $DWSQLPropertiesImport.Collation + ") <------------"
	}
	$installdir = (Resolve-Path $location`..\)
	$rmsEmulator = Get-SCOMRMSEmulator | Select-Object -Property DisplayName -ExpandProperty DisplayName
	Write-Host "-" -NoNewline -ForegroundColor Green
	$ManagementGroup = Get-SCOMManagementGroup | Select-Object -Property Name -ExpandProperty Name
	#$GatewayDLL = Get-Item "C:\Program Files\System Center Operations Manager\Gateway\MOMAgentManagement.dll" | foreach-object { "{0}" -f [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_).FileVersion }

	$setupOutput = [pscustomobject]@{
		'Computer Name'		     = $env:COMPUTERNAME
		'Management Server Port' = $setuplocation.ManagementServerPort
		'Product'			     = $setuplocation.Product
		'Installed On'		     = $setuplocation.InstalledOn
		'Current Version (Registry)' = $setuplocation.CurrentVersion
		'Server Version (Registry)' = $setuplocation.ServerVersion
		'               (DLL)'   = $ServerVersionDLL
		'UI Version (Registry)'  = $setuplocation.UIVersion
		'           (DLL)'  = $UIVersionDLL
		'DB Version (Query)'	 = $MOMmgmtGroupInfo
		'Installation Directory' = $installdir
		'Management Group Name' = $ManagementGroup
		'Management Servers in Management Group' = "$ManagementServers"
		'Remote Management Server Emulator (Primary Server)' = "$rmsEmulator"
        'Free Space' = $DiskFree
	}
	$dbOutput = [pscustomobject]@{
		'Operations Manager DB Server Name' = $setuplocation.DatabaseServerName
		'Operations Manager DB Name'	    = $setuplocation.DatabaseName
		'Operations Manager SQL Properties' = $OMSQLProperties
		'Data Warehouse DB Server Name'	    = $setuplocation.DataWarehouseDBServerName
		'Data Warehouse DB Name'		    = $setuplocation.DataWarehouseDBName
		'Data Warehouse SQL Properties'	    = $DWSQLProperties
	}
	Write-Host "-" -NoNewline -ForegroundColor Green
	$UserRolesImport = Import-Csv "$OutputPath`\UserRoles.csv"
	$UserRoles = "User Role Name" + " - " + "Is System?" + "`n----------------------------`n"
	$UserRolesImport | % {
		if ($_.IsSystem -eq $false)
		{
			$foundFalse = $true
			$UserRoles += $_.UserRoleName + " - " + $_.IsSystem + "`n"
		}
	}
	if ($foundFalse)
	{
		$dbOutput | Add-Member -MemberType NoteProperty -Name 'User Roles (Non-Default)' -Value $UserRoles
	}
	"================================`n=---- General Information  ----=`n================================" | Out-File -FilePath "$OutputPath\General Information.txt"
	$setupOutput | Out-File -FilePath "$OutputPath\General Information.txt" -Append
	"================================`n=---- Database Information ----=`n================================" | Out-File -FilePath "$OutputPath\General Information.txt" -Append
	$dbOutput | Out-File -FilePath "$OutputPath\General Information.txt" -Append
	"================================`n=----- Installed Updates  -----=`n================================" | Out-File -FilePath "$OutputPath\General Information.txt" -Append
	$hotfixOutput = $TestedTLSservers | %{ Write-Host "-" -NoNewline -ForegroundColor Green; Get-HotFix -ComputerName $_ } | Sort InstalledOn, Source -Descending | Format-Table -AutoSize | Out-File -FilePath "$OutputPath\General Information.txt" -Append
	return $true
}