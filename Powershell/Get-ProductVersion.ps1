#Author: Blake Drumm (blakedrumm@microsoft.com)
#Last Updated SQL Build List on 11/17/2021
#Last Updated SCOM Build List on 11/17/2021

function Get-ProductVersion
{
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[string]$Product,
		[Parameter(Mandatory = $false,
				   Position = 2)]
		[string]$BuildVersion
	)
	if ($BuildVersion -eq $null)
	{
		return "Unknown Version"
	}
	if ($Product -eq 'SCOM')
	{
		$Output = switch ($BuildVersion)
		{
    <# 
       System Center Operations Manager 2019 Versions
    #>
			'10.19.10185.0' { "SCOM 2019 Update Rollup 3 - Hotfix Oct 2021 for SCOM 2019 / Oct 2021" } #Agent
			'10.19.10552.0' { "SCOM 2019 Update Rollup 3 - Hotfix Oct 2021 for SCOM 2019 / Oct 2021" }
			'10.19.10550.0' { "SCOM 2019 Update Rollup 3 - Hotfix for Web Console / Oct 2021" }
			'10.19.10177.0' { "SCOM 2019 Update Rollup 3 / 2021 March 31" } #Agent
			'10.19.10505.0' { "SCOM 2019 Update Rollup 3 / 2021 March 31" }
			'10.19.10153.0' { "SCOM 2019 Update Rollup 2 / 2020 August 4" } #Agent
			'10.19.10407.0' { "SCOM 2019 Update Rollup 2 / 2020 August 4" }
			'10.19.10349.0' { "SCOM 2019 Update Rollup 1 - Hotfix for Alert Management / 2020 April 1" }
			'10.19.10140.0' { "SCOM 2019 Update Rollup 1 / 2020 February 4" } #Agent
			'10.19.10311.0' { "SCOM 2019 Update Rollup 1 / 2020 February 4" }
			'10.19.10014.0' { "SCOM 2019 RTM / 2019 March 14" } #Agent
			'10.19.10050.0' { "SCOM 2019 RTM / 2019 March 14" }
			'10.19.10003.0' { "SCOM 2019 Technical Preview / " }
    <# 
       System Center Operations Manager Semi-Annual Channel (SAC) Versions
    #>
			'8.0.13067.0' { "Version 1807 / 2018 July 24" } #Agent
			'7.3.13261.0' { "Version 1807 / 2018 July 24" }
			'8.0.13053.0' { "Version 1801 / 2018 February 8" } #Agent
			'7.3.13142.0' { "Version 1801 / 2018 February 8" }
			'7.3.13040.0' { "Version 1711 (preview) / 2017 November 9" }
    <# 
       System Center Operations Manager 2016 Versions
    #>
			'8.0.11057.0' { "SCOM 2016 Update Rollup 10 / 2020 November 19" } #Agent
			'7.2.12324.0' { "SCOM 2016 Update Rollup 10 / 2020 November 19" }
			'8.0.11049.0' { "SCOM 2016 Update Rollup 9 / 2020 March 24" } #Agent	
			'7.2.12265.0' { "SCOM 2016 Update Rollup 9 / 2020 March 24" }
			'8.0.11037.0' { "SCOM 2016 Update Rollup 8 / 2019 September 24" } #Agent
			'7.2.12213.0' { "SCOM 2016 Update Rollup 8 / 2019 September 24" }
			'8.0.11025.0' { "SCOM 2016 Update Rollup 7 / 2019 April 23" } #Agent
			'7.2.12150.0' { "SCOM 2016 Update Rollup 7 / 2019 April 23" }
			'8.0.11004.0' { "SCOM 2016 Update Rollup 6 / 2018 October 23" } #Agent
			'7.2.12066.0' { "SCOM 2016 Update Rollup 6 / 2018 October 23" }
			'8.0.10990.0' { "SCOM 2016 Update Rollup 5 / 2018 April 25" } #Agent
			'7.2.12016.0' { "SCOM 2016 Update Rollup 5 / 2018 April 25" }
			'8.0.10977.0' { "SCOM 2016 Update Rollup 4 / 2017 October 23" } #Agent	
			'7.2.11938.0' { "SCOM 2016 Update Rollup 4 / 2017 October 23" }
			'8.0.10970.0' { "SCOM 2016 Update Rollup 3 / 2017 May 23" } #Agent
			'7.2.11878.0' { "SCOM 2016 Update Rollup 3 / 2017 May 23" }
			'8.0.10949.0' { "SCOM 2016 Update Rollup 2 / 2017 February 22" } #Agent
			'7.2.11822.0' { "SCOM 2016 Update Rollup 2 / 2017 February 22" }
			'7.2.11759.0' { "SCOM 2016 Update Rollup 1 / 2016 October 13" }
			'8.0.10918.0' { "SCOM 2016 RTM / 2016 September 26" } #Agent
			'7.2.11719.0' { "SCOM 2016 RTM / 2016 September 26" }
			'7.2.11469.0' { "SCOM 2016 Technical Preview 5 / 2016 April" }
			'7.2.11257.0' { "SCOM 2016 Technical Preview 4 / 2016 July" }
			'7.2.11125.0' { "SCOM 2016 Technical Preview 3 / 2016 July" }
			'7.2.11097.0' { "SCOM 2016 Technical Preview 2 / 2016 June" }
			'7.2.10015.0' { "SCOM 2016 Technical Preview / 2016 " }
   <# 
      System Center Operations Manager 2012 R2 Versions
   #>
			'7.1.10305.0' 	 { "SCOM 2012 R2 Update Rollup 14 / 2017 November 28" } #Agent	
			'7.1.10226.1387' { "SCOM 2012 R2 Update Rollup 14 / 2017 November 28" }
			'7.1.10302.0' 	 { "SCOM 2012 R2 Update Rollup 13 / 2017 May 23" } #Agent
			'7.1.10226.1360' { "SCOM 2012 R2 Update Rollup 13 / 2017 May 23" }
			'7.1.10292.0' 	 { "SCOM 2012 R2 Update Rollup 12 / 2017 January 24" } #Agent
			'7.1.10226.1304' { "SCOM 2012 R2 Update Rollup 12 / 2017 January 24" }
			'7.1.10285.0' 	 { "SCOM 2012 R2 Update Rollup 11 / 2016 August 30" } #Agent
			'7.1.10226.1239' { "SCOM 2012 R2 Update Rollup 11 / 2016 August 30" }
			'7.1.10268.0'  	 { "SCOM 2012 R2 Update Rollup 9 / 2016 January 26" } #Agent
			'7.1.10226.1177' { "SCOM 2012 R2 Update Rollup 9 / 2016 January 26" }
			'7.1.10241.0' 	 { "SCOM 2012 R2 Update Rollup 8 / 2015 October 27" } #Agent
			'7.1.10226.1118' { "SCOM 2012 R2 Update Rollup 8 / 2015 October 27" }
			'7.1.10229.0' 	 { "SCOM 2012 R2 Update Rollup 7 / 2015 August 11" } #Agent
			'7.1.10226.1090' { "SCOM 2012 R2 Update Rollup 7 / 2015 August 11" }
			'7.1.10218.0'	 { "SCOM 2012 R2 Update Rollup 6 / 2015 April 28" } #Agent
			'7.1.10226.1064' { "SCOM 2012 R2 Update Rollup 6 / 2015 April 28" }
			'7.1.10213.0' 	 { "SCOM 2012 R2 Update Rollup 5 / 2015 February 10" } #Agent
			'7.1.10226.1052' { "SCOM 2012 R2 Update Rollup 5 / 2015 February 10" }
			'7.1.10211.0' 	 { "SCOM 2012 R2 Update Rollup 4 / 2014 October 28" } #Agent
			'7.1.10226.1046' { "SCOM 2012 R2 Update Rollup 4 / 2014 October 28" }
			'7.1.10204.0'	 { "SCOM 2012 R2 Update Rollup 3 / 2014 July 29" } #Agent
			'7.1.10226.1037' { "SCOM 2012 R2 Update Rollup 3 / 2014 July 29" }
			'7.1.10195.0'	 { "SCOM 2012 R2 Update Rollup 2 / 2014 April 23" } #Agent
			'7.1.10226.1015' { "SCOM 2012 R2 Update Rollup 2 / 2014 April 23" }
			'7.1.10188.0'	 { "SCOM 2012 R2 Update Rollup 1 / 2014 January 27" } #Agent
			'7.1.10226.1011' { "SCOM 2012 R2 Update Rollup 1 / 2014 January 27" }
			'7.1.10184.0'	 { "SCOM 2012 R2 RTM / 2013 October 22" } #Agent
			'7.1.10226.0'	 { "SCOM 2012 R2 RTM / 2013 October 22" }
   <# 
      System Center Operations Manager 2012 SP1 Versions
   #>
			'7.0.9538.1136' { "SCOM 2012 SP1 Update Rollup 10 / 2015 August 11" }
			'7.0.9538.1126' { "SCOM 2012 SP1 Update Rollup 9 / 2015 February 10" }
			'7.0.9538.1123' { "SCOM 2012 SP1 Update Rollup 8 / 2014 October 28" }
			'7.0.9538.1117' { "SCOM 2012 SP1 Update Rollup 7 / 2014 July 29" }
			'7.0.9538.1109' { "SCOM 2012 SP1 Update Rollup 6 / 2014 April 23" }
			'7.0.9538.1106' { "SCOM 2012 SP1 Update Rollup 5 / 2014 January 27" }
			'7.0.9538.1084' { "SCOM 2012 SP1 Update Rollup 4 / 2013 October 21" }
			'7.0.9538.1069' { "SCOM 2012 SP1 Update Rollup 3 / 2013 July 23" }
			'7.0.9538.1047' { "SCOM 2012 SP1 Update Rollup 2 / 2013 April 08" }
			'7.0.9538.1005' { "SCOM 2012 SP1 Update Rollup 1 / 2013 January 8" }
			
			'7.0.9538.0' { "SCOM 2012 SP1" }
   <# 
      System Center Operations Manager 2012 Versions
   #>
			'7.0.8289.0' { "SCOM 2012 Beta / 2011 July" }
			'7.0.8560.0' { "SCOM 2012 RTM" }
			
			'7.0.8560.1021' { "SCOM 2012 Update Rollup 1 / 2012 May 07" }
			'7.0.8560.1027' { "SCOM 2012 Update Rollup 2 / 2012 July 24" }
			'7.0.8560.1036' { "SCOM 2012 Update Rollup 3 / 2012 October 08" }
			'7.0.8560.1048' { "SCOM 2012 Update Rollup 8 / 2015 August 11" }
			# If nothing else found then default to version number
			default { "Unknown Version" }
		}
		return $Output
	}
	elseif ($Product -eq 'SQL')
	{
		$Output = switch ($BuildVersion)
		{
			"15.0.4178.1" { "Cumulative Update 13 (CU13) For SQL Server 2019 / 2021-10-05" }
			"15.0.4153.1" { "Cumulative Update 12 (CU12) For SQL Server 2019 / 2021-08-04" }
			"15.0.4138.2" { "Cumulative Update 11 (CU11) For SQL Server 2019 / 2021-06-10" }
			"15.0.4123.1" { "Cumulative Update 10 (CU10) For SQL Server 2019 / 2021-04-06" }
			"15.0.4102.2" { "Cumulative Update 9 (CU9) For SQL Server 2019 / 2021-02-11" }
			"15.0.4083.2" { "Security Update For SQL Server 2019 CU8: January 12, 2021 / 2021-01-12" }
			"15.0.4073.23" { "Cumulative Update 8 (CU8) For SQL Server 2019 / 2020-10-01" }
			"15.0.4063.15" { "Cumulative Update 7 (CU7) For SQL Server 2019 / 2020-09-02" }
			"15.0.4053.23" { "Cumulative Update 6 (CU6) For SQL Server 2019 / 2020-08-04" }
			"15.0.4043.16" { "Cumulative Update 5 (CU5) For SQL Server 2019 / 2020-06-22" }
			"15.0.4033.1" { "Cumulative Update 4 (CU4) For SQL Server 2019 / 2020-03-31" }
			"15.0.4023.6" { "Cumulative Update 3 (CU3) For SQL Server 2019 / 2020-03-12" }
			"15.0.4013.40" { "Cumulative Update 2 (CU2) For SQL Server 2019 / 2020-02-13" }
			"15.0.4003.23" { "Cumulative Update 1 (CU1) For SQL Server 2019 / 2020-01-07" }
			"15.0.2080.9" { "Security Update For SQL Server 2019 GDR: January 12, 2021 / 2021-01-12" }
			"15.0.2070.41" { "Servicing Update (GDR1) For SQL Server 2019 RTM / 2019-11-04" }
			"15.0.2000.5" { "Microsoft SQL Server 2019 RTM / 2019-11-04" }
			"15.0.1900.47" { "Microsoft SQL Server 2019 Release Candidate Refresh For Big Data Clusters Only (RC1.1) / 2019-08-29" }
			"15.0.1900.25" { "Microsoft SQL Server 2019 Release Candidate 1 (RC1) / 2019-08-21" }
			"15.0.1800.32" { "Microsoft SQL Server 2019 Community Technology Preview 3.2 (CTP 3.2) / 2019-07-24" }
			"15.0.1700.37" { "Microsoft SQL Server 2019 Community Technology Preview 3.1 (CTP 3.1) / 2019-06-26" }
			"15.0.1600.8" { "Microsoft SQL Server 2019 Community Technology Preview 3.0 (CTP 3.0) / 2019-05-22" }
			"15.0.1500.28" { "Microsoft SQL Server 2019 Community Technology Preview 2.5 (CTP 2.5) / 2019-04-23" }
			"15.0.1400.75" { "Microsoft SQL Server 2019 Community Technology Preview 2.4 (CTP 2.4) / 2019-03-26" }
			"15.0.1300.359" { "Microsoft SQL Server 2019 Community Technology Preview 2.3 (CTP 2.3) / 2019-03-01" }
			"15.0.1200.24" { "Microsoft SQL Server 2019 Community Technology Preview 2.2 (CTP 2.2) / 2018-12-11" }
			"15.0.1100.94" { "Microsoft SQL Server 2019 Community Technology Preview 2.1 (CTP 2.1) / 2018-11-06" }
			"15.0.1000.34" { "Microsoft SQL Server 2019 Community Technology Preview 2.0 (CTP 2.0) / 2018-09-24" }
			"14.0.3421.10" { "Cumulative Update 27 (CU27) For SQL Server 2017 / 2021-10-27" }
			"14.0.3411.3" { "Cumulative Update 26 (CU26) For SQL Server 2017 / 2021-09-14" }
			"14.0.3401.7" { "Cumulative Update 25 (CU25) For SQL Server 2017 / 2021-07-12" }
			"14.0.3391.2" { "Cumulative Update 24 (CU24) For SQL Server 2017 / 2021-05-10" }
			"14.0.3381.3" { "Cumulative Update 23 (CU23) For SQL Server 2017 / 2021-02-24" }
			"14.0.3370.1" { "Security Update For SQL Server 2017 CU22: January 12, 2021 / 2021-01-12" }
			"14.0.3356.20" { "Cumulative Update 22 (CU22) For SQL Server 2017 / 2020-09-10" }
			"14.0.3335.7" { "Cumulative Update 21 (CU21) For SQL Server 2017 / 2020-07-01" }
			"14.0.3294.2" { "Cumulative Update 20 (CU20) For SQL Server 2017 / 2020-04-07" }
			"14.0.3281.6" { "Cumulative Update 19 (CU19) For SQL Server 2017 / 2020-02-05" }
			"14.0.3257.3" { "Cumulative Update 18 (CU18) For SQL Server 2017 / 2019-12-09" }
			"14.0.3238.1" { "Cumulative Update 17 (CU17) For SQL Server 2017 / 2019-10-08" }
			"14.0.3223.3" { "Cumulative Update 16 (CU16) For SQL Server 2017 / 2019-08-01" }
			"14.0.3208.1" { "On-Demand Hotfix Update Package 2 For SQL Server 2017 Cumulative Update 15 (CU15) / 2019-07-09" }
			"14.0.3192.2" { "Security Update For SQL Server 2017 CU15: July 9, 2019 / 2019-07-09" }
			"14.0.3164.1" { "On-Demand Hotfix Update Package For SQL Server 2017 Cumulative Update 15 (CU15) / 2019-06-20" }
			"14.0.3162.1" { "Cumulative Update 15 (CU15) For SQL Server 2017 / 2019-05-24" }
			"14.0.3103.1" { "Security Update For SQL Server 2017 Cumulative Update 14 (CU14): May 14, 2019 / 2019-05-14" }
			"14.0.3076.1" { "Cumulative Update 14 (CU14) For SQL Server 2017 / 2019-03-25" }
			"14.0.3049.1" { "On-Demand Hotfix Update Package For SQL Server 2017 Cumulative Update 13 (CU13) / 2019-01-08" }
			"14.0.3048.4" { "Cumulative Update 13 (CU13) For SQL Server 2017 / 2018-12-18" }
			"14.0.3045.24" { "Cumulative Update 12 (CU12) For SQL Server 2017 / 2018-10-24" }
			"14.0.3038.14" { "Cumulative Update 11 (CU11) For SQL Server 2017 / 2018-09-21" }
			"14.0.3037.1" { "Cumulative Update 10 (CU10) For SQL Server 2017 / 2018-08-27" }
			"14.0.3035.2" { "Security Update For The Remote Code Execution Vulnerability In SQL Server 2017 CU: August 14, 2018 / 2018-08-14" }
			"14.0.3030.27" { "Cumulative Update 9 (CU9) For SQL Server 2017 / 2018-07-18" }
			"14.0.3029.16" { "Cumulative Update 8 (CU8) For SQL Server 2017 / 2018-06-21" }
			"14.0.3026.27" { "Cumulative Update 7 (CU7) For SQL Server 2017 / 2018-05-23" }
			"14.0.3025.34" { "Cumulative Update 6 (CU6) For SQL Server 2017 / 2018-04-19" }
			"14.0.3023.8" { "Cumulative Update 5 (CU5) For SQL Server 2017 / 2018-03-20" }
			"14.0.3022.28" { "Cumulative Update 4 (CU4) For SQL Server 2017 / 2018-02-17" }
			"14.0.3015.40" { "Cumulative Update 3 (CU3) For SQL Server 2017 - Security Advisory ADV180002 / 2018-01-04" }
			"14.0.3008.27" { "Cumulative Update 2 (CU2) For SQL Server 2017 / 2017-11-28" }
			"14.0.3006.16" { "Cumulative Update 1 (CU1) For SQL Server 2017 / 2017-10-23" }
			"14.0.2037.2" { "Security Update For SQL Server 2017 GDR: January 12, 2021 / 2021-01-12" }
			"14.0.2027.2" { "Security Update For SQL Server 2017 GDR: July 9, 2019 / 2019-07-09" }
			"14.0.2014.14" { "Security Update For SQL Server 2017 GDR: May 14, 2019 / 2019-05-14" }
			"14.0.2002.14" { "Security Update For The Remote Code Execution Vulnerability In SQL Server 2017 GDR: August 14, 2018 / 2018-08-14" }
			"14.0.2000.63" { "Security Update For SQL Server 2017 GDR: January 3, 2018 - Security Advisory ADV180002 / 2018-01-03" }
			"14.0.1000.169" { "Microsoft SQL Server 2017 RTM / 2017-10-02" }
			"14.0.900.75" { "Microsoft SQL Server 2017 Release Candidate 2 (RC2) (Linux Support; Codename Helsinki) / 2017-08-02" }
			"14.0.800.90" { "Microsoft SQL Server 2017 Release Candidate 1 (RC1) (Linux Support; Codename Helsinki) / 2017-07-17" }
			"14.0.600.250" { "Microsoft SQL Server 2017 Community Technical Preview 2.1 (CTP2.1) (Linux Support; Codename Helsinki) / 2017-05-17" }
			"14.0.500.272" { "Microsoft SQL Server 2017 Community Technical Preview 2.0 (CTP2.0) (Linux Support; Codename Helsinki) / 2017-04-19" }
			"14.0.405.198" { "Microsoft SQL Server Vnext Community Technology Preview 1.4 (CTP1.4) (Linux Support; Codename Helsinki) / 2017-03-17" }
			"14.0.304.138" { "Microsoft SQL Server Vnext Community Technology Preview 1.3 (CTP1.3) (Linux Support; Codename Helsinki) / 2017-02-17" }
			"14.0.200.24" { "Microsoft SQL Server Vnext Community Technology Preview 1.2 (CTP1.2) (Linux Support; Codename Helsinki) / 2017-01-20" }
			"14.0.100.187" { "Microsoft SQL Server Vnext Community Technology Preview 1.1 (CTP1.1) (Linux Support; Codename Helsinki) / 2016-12-16" }
			"14.0.1.246" { "Microsoft SQL Server Vnext Community Technology Preview 1 (CTP1) (Linux Support; Codename Helsinki) / 2016-11-16" }
			"13.0.6404.1" { "On-Demand Hotfix Update Package For SQL Server 2016 Service Pack 3 (SP3) / 2021-10-27" }
			"13.0.6300.2" { "Microsoft SQL Server 2016 Service Pack 3 (SP3) / 2021-09-15" }
			"13.0.5888.11" { "Cumulative Update 17 (CU17) For SQL Server 2016 Service Pack 2 / 2021-03-29" }
			"13.0.5882.1" { "Cumulative Update 16 (CU16) For SQL Server 2016 Service Pack 2 / 2021-02-11" }
			"13.0.5865.1" { "Security Update For SQL Server 2016 SP2 CU15: January 12, 2021 / 2021-01-12" }
			"13.0.5850.14" { "Cumulative Update 15 (CU15) For SQL Server 2016 Service Pack 2 / 2020-09-28" }
			"13.0.5830.85" { "Cumulative Update 14 (CU14) For SQL Server 2016 Service Pack 2 / 2020-08-06" }
			"13.0.5820.21" { "Cumulative Update 13 (CU13) For SQL Server 2016 Service Pack 2 / 2020-05-28" }
			"13.0.5698.0" { "Cumulative Update 12 (CU12) For SQL Server 2016 Service Pack 2 / 2020-02-25" }
			"13.0.5622.0" { "Security Update For SQL Server 2016 SP2 CU11: February 11, 2020 / 2020-02-11" }
			"13.0.5598.27" { "Cumulative Update 11 (CU11) For SQL Server 2016 Service Pack 2 / 2019-12-09" }
			"13.0.5492.2" { "Cumulative Update 10 (CU10) For SQL Server 2016 Service Pack 2 / 2019-10-08" }
			"13.0.5479.0" { "4515435 Cumulative Update 9 (CU9) For SQL Server 2016 Service Pack 2 / 2019-09-30" }
			"13.0.5426.0" { "Cumulative Update 8 (CU8) For SQL Server 2016 Service Pack 2 / 2019-07-31" }
			"13.0.5382.0" { "On-Demand Hotfix Update Package 2 For SQL Server 2016 Service Pack 2 (SP2) Cumulative Update 7 (CU7) / 2019-07-09" }
			"13.0.5366.0" { "Security Update For SQL Server 2016 SP2 CU7 GDR: July 9, 2019 / 2019-07-09" }
			"13.0.5343.1" { "On-Demand Hotfix Update Package For SQL Server 2016 Service Pack 2 (SP2) Cumulative Update 7 (CU7) / 2019-06-24" }
			"13.0.5337.0" { "Cumulative Update 7 (CU7) For SQL Server 2016 Service Pack 2 / 2019-05-22" }
			"13.0.5292.0" { "Cumulative Update 6 (CU6) For SQL Server 2016 Service Pack 2 / 2019-03-19" }
			"13.0.5270.0" { "On-Demand Hotfix Update Package For SQL Server 2016 SP2 CU5 / 2019-02-14" }
			"13.0.5264.1" { "Cumulative Update 5 (CU5) For SQL Server 2016 Service Pack 2 / 2019-01-23" }
			"13.0.5239.0" { "On-Demand Hotfix Update Package 2 For SQL Server 2016 SP2 CU4 / 2018-12-21" }
			"13.0.5233.0" { "Cumulative Update 4 (CU4) For SQL Server 2016 Service Pack 2 / 2018-11-13" }
			"13.0.5221.0" { "FIX: Assertion Error Occurs When You Restart The SQL Server 2016 Database / 2018-10-09" }
			"13.0.5221.0" { "FIX: '3414' And '9003' Errors And A .Pmm Log File Grows Large In SQL Server 2016 / 2018-10-09" }
			"13.0.5216.0" { "Cumulative Update 3 (CU3) For SQL Server 2016 Service Pack 2 / 2018-09-21" }
			"13.0.5201.2" { "Security Update For The Remote Code Execution Vulnerability In SQL Server 2016 SP2 CU: August 19, 2018 / 2018-08-19" }
			"13.0.5161.0" { "Security Update For The Remote Code Execution Vulnerability In SQL Server 2016 SP2 CU: August 14, 2018 / 2018-08-14" }
			"13.0.5153.0" { "Cumulative Update 2 (CU2) For SQL Server 2016 Service Pack 2 / 2018-07-17" }
			"13.0.5149.0" { "Cumulative Update 1 (CU1) For SQL Server 2016 Service Pack 2 / 2018-05-30" }
			"13.0.5103.6" { "Security Update For SQL Server 2016 SP2 GDR: January 12, 2021 / 2021-01-12" }
			"13.0.5102.14" { "Security Update For SQL Server 2016 SP2 GDR: February 11, 2020 / 2020-02-11" }
			"13.0.5101.9" { "Security Update For SQL Server 2016 SP2 GDR: July 9, 2019 / 2019-07-09" }
			"13.0.5081.1" { "Security Update For The Remote Code Execution Vulnerability In SQL Server 2016 SP2 GDR: August 14, 2018 / 2018-08-14" }
			"13.0.5026.0" { "Microsoft SQL Server 2016 Service Pack 2 (SP2) / 2018-04-24" }
			"13.0.4604.0" { "Security Update For SQL Server 2016 SP1 CU15 GDR: July 9, 2019 / 2019-07-09" }
			"13.0.4577.0" { "On-Demand Hotfix Update Package For SQL Server 2016 Service Pack 1 (SP1) Cumulative Update 15 (CU15) / 2019-06-20" }
			"13.0.4574.0" { "Cumulative Update 15 (CU15) For SQL Server 2016 Service Pack 1 / 2019-05-16" }
			"13.0.4560.0" { "Cumulative Update 14 (CU14) For SQL Server 2016 Service Pack 1 / 2019-03-19" }
			"13.0.4550.1" { "Cumulative Update 13 (CU13) For SQL Server 2016 Service Pack 1 / 2019-01-23" }
			"13.0.4541.0" { "Cumulative Update 12 (CU12) For SQL Server 2016 Service Pack 1 / 2018-11-13" }
			"13.0.4531.0" { "FIX: The 'Modification_Counter' In DMV Sys.Dm_Db_Stats_Properties Shows Incorrect Value When Partitions Are Merged Through ALTER PARTITION In SQL Server 2016 / 2018-09-27" }
			"13.0.4528.0" { "Cumulative Update 11 (CU11) For SQL Server 2016 Service Pack 1 / 2018-09-18" }
			"13.0.4522.0" { "Security Update For The Remote Code Execution Vulnerability In SQL Server 2016 SP1 CU: August 14, 2018 / 2018-08-14" }
			"13.0.4514.0" { "Cumulative Update 10 (CU10) For SQL Server 2016 Service Pack 1 / 2018-07-16" }
			"13.0.4502.0" { "Cumulative Update 9 (CU9) For SQL Server 2016 Service Pack 1 / 2018-05-30" }
			"13.0.4477.0" { "On-Demand Hotfix Update Package For SQL Server 2016 SP1 / 2018-06-02" }
			"13.0.4474.0" { "Cumulative Update 8 (CU8) For SQL Server 2016 Service Pack 1 / 2018-03-19" }
			"13.0.4466.4" { "Cumulative Update 7 (CU7) For SQL Server 2016 Service Pack 1 - Security Advisory ADV180002 / 2018-01-04" }
			"13.0.4457.0" { "Cumulative Update 6 (CU6) For SQL Server 2016 Service Pack 1 / 2017-11-21" }
			"13.0.4451.0" { "Cumulative Update 5 (CU5) For SQL Server 2016 Service Pack 1 / 2017-09-18" }
			"13.0.4446.0" { "Cumulative Update 4 (CU4) For SQL Server 2016 Service Pack 1 / 2017-08-08" }
			"13.0.4435.0" { "Cumulative Update 3 (CU3) For SQL Server 2016 Service Pack 1 / 2017-05-15" }
			"13.0.4422.0" { "Cumulative Update 2 (CU2) For SQL Server 2016 Service Pack 1 / 2017-03-22" }
			"13.0.4411.0" { "Cumulative Update 1 (CU1) For SQL Server 2016 Service Pack 1 / 2017-01-18" }
			"13.0.4259.0" { "Security Update For SQL Server 2016 SP1 GDR: July 9, 2019 / 2019-07-09" }
			"13.0.4224.16" { "Security Update For The Remote Code Execution Vulnerability In SQL Server 2016 SP1 GDR: August 22, 2018 / 2018-08-22" }
			"13.0.4223.10" { "Security Update For The Remote Code Execution Vulnerability In SQL Server 2016 SP1 GDR: August 14, 2018 / 2018-08-14" }
			"13.0.4210.6" { "Description Of The Security Update For SQL Server 2016 SP1 GDR: January 3, 2018 - Security Advisory ADV180002 / 2018-01-03" }
			"13.0.4206.0" { "Security Update For SQL Server 2016 Service Pack 1 GDR: August 8, 2017 / 2017-08-08" }
			"13.0.4202.2" { "GDR Update Package For SQL Server 2016 SP1 / 2016-12-16" }
			"13.0.4199.0" { "Important Update For SQL Server 2016 SP1 Reporting Services / 2016-11-23" }
			"13.0.4001.0" { "Microsoft SQL Server 2016 Service Pack 1 (SP1) / 2016-11-16" }
			"13.0.2218.0" { "Description Of The Security Update For SQL Server 2016 CU: January 6, 2018 - Security Advisory ADV180002 / 2018-01-06" }
			"13.0.2216.0" { "Cumulative Update 9 (CU9) For SQL Server 2016 / 2017-11-21" }
			"13.0.2213.0" { "Cumulative Update 8 (CU8) For SQL Server 2016 / 2017-09-18" }
			"13.0.2210.0" { "Cumulative Update 7 (CU7) For SQL Server 2016 / 2017-08-08" }
			"13.0.2204.0" { "Cumulative Update 6 (CU6) For SQL Server 2016 / 2017-05-15" }
			"13.0.2197.0" { "Cumulative Update 5 (CU5) For SQL Server 2016 / 2017-03-21" }
			"13.0.2193.0" { "Cumulative Update 4 (CU4) For SQL Server 2016 / 2017-01-18" }
			"13.0.2190.2" { "On-Demand Hotfix Update Package For SQL Server 2016 CU3 / 2016-12-16" }
			"13.0.2186.6" { "Cumulative Update 3 (CU3) For SQL Server 2016 / 2016-11-08" }
			"13.0.2186.6" { "MS16-136: Description Of The Security Update For SQL Server 2016 CU: November 8, 2016 / 2016-11-08" }
			"13.0.2170.0" { "On-Demand Hotfix Update Package For SQL Server 2016 CU2 / 2016-11-01" }
			"13.0.2169.0" { "On-Demand Hotfix Update Package For SQL Server 2016 CU2 / 2016-10-26" }
			"13.0.2164.0" { "Cumulative Update 2 (CU2) For SQL Server 2016 / 2016-09-22" }
			"13.0.2149.0" { "Cumulative Update 1 (CU1) For SQL Server 2016 / 2016-07-26" }
			"13.0.1745.2" { "Description Of The Security Update For SQL Server 2016 GDR: January 6, 2018 - Security Advisory ADV180002 / 2018-01-06" }
			"13.0.1742.0" { "Security Update For SQL Server 2016 RTM GDR: August 8, 2017 / 2017-08-08" }
			"13.0.1728.2" { "GDR Update Package For SQL Server 2016 RTM / 2016-12-16" }
			"13.0.1722.0" { "MS16-136: Description Of The Security Update For SQL Server 2016 GDR: November 8, 2016 / 2016-11-08" }
			"13.0.1711.0" { "Processing A Partition Causes Data Loss On Other Partitions After The Database Is Restored In SQL Server 2016 (1200) / 2016-08-17" }
			"13.0.1708.0" { "Critical Update For SQL Server 2016 MSVCRT Prerequisites / 2016-06-03" }
			"13.0.1601.5" { "Microsoft SQL Server 2016 RTM / 2016-06-01" }
			"13.0.1400.361" { "Microsoft SQL Server 2016 Release Candidate 3 (RC3) / 2016-04-15" }
			"13.0.1300.275" { "Microsoft SQL Server 2016 Release Candidate 2 (RC2) / 2016-04-01" }
			"13.0.1200.242" { "Microsoft SQL Server 2016 Release Candidate 1 (RC1) / 2016-03-18" }
			"13.0.1100.288" { "Microsoft SQL Server 2016 Release Candidate 0 (RC0) / 2016-03-07" }
			"13.0.1000.281" { "Microsoft SQL Server 2016 Community Technology Preview 3.3 (CTP3.3) / 2016-02-03" }
			"13.0.900.73" { "Microsoft SQL Server 2016 Community Technology Preview 3.2 (CTP3.2) / 2015-12-16" }
			"13.0.800.11" { "Microsoft SQL Server 2016 Community Technology Preview 3.1 (CTP3.1) / 2015-11-30" }
			"13.0.700.139" { "Microsoft SQL Server 2016 Community Technology Preview 3.0 (CTP3.0) / 2015-10-28" }
			"13.0.600.65" { "Microsoft SQL Server 2016 Community Technology Preview 2.4 (CTP2.4) / 2015-09-30" }
			"13.0.500.53" { "Microsoft SQL Server 2016 Community Technology Preview 2.3 (CTP2.3) / 2015-08-28" }
			"13.0.407.1" { "Microsoft SQL Server 2016 Community Technology Preview 2.2 (CTP2.2) / 2015-07-23" }
			"13.0.400.91" { "Microsoft SQL Server 2016 Community Technology Preview 2.2 (CTP2.2) / 2015-07-22" }
			"13.0.300.44" { "Microsoft SQL Server 2016 Community Technology Preview 2.1 (CTP2.1) / 2015-06-24" }
			"13.0.200.172" { "Microsoft SQL Server 2016 Community Technology Preview 2 (CTP2) / 2015-05-27" }
			"12.0.6433.1" { "Security Update For SQL Server 2014 SP3 CU4: January 12, 2021 / 2021-01-12" }
			"12.0.6372.1" { "Security Update For SQL Server 2014 SP3 CU4: February 11, 2020 / 2020-02-11" }
			"12.0.6329.1" { "Cumulative Update Package 4 (CU4) For SQL Server 2014 Service Pack 3 / 2019-07-29" }
			"12.0.6293.0" { "Security Update For SQL Server 2014 SP3 CU3 GDR: July 9, 2019 / 2019-07-09" }
			"12.0.6259.0" { "Cumulative Update Package 3 (CU3) For SQL Server 2014 Service Pack 3 / 2019-04-16" }
			"12.0.6214.1" { "Cumulative Update Package 2 (CU2) For SQL Server 2014 Service Pack 3 / 2019-02-19" }
			"12.0.6205.1" { "Cumulative Update Package 1 (CU1) For SQL Server 2014 Service Pack 3 / 2018-12-12" }
			"12.0.6164.21" { "Security Update For SQL Server 2014 SP3 GDR: January 12, 2021 / 2021-01-12" }
			"12.0.6118.4" { "Security Update For SQL Server 2014 SP3 GDR: February 11, 2020 / 2020-02-11" }
			"12.0.6108.1" { "Security Update For SQL Server 2014 SP3 GDR: July 9, 2019 / 2019-07-09" }
			"12.0.6024.0" { "SQL Server 2014 Service Pack 3 (SP3) / 2018-10-30" }
			"12.0.5687.1" { "Cumulative Update Package 18 (CU18) For SQL Server 2014 Service Pack 2 / 2019-07-29" }
			"12.0.5659.1" { "Security Update For SQL Server 2014 SP2 CU17 GDR: July 9, 2019 / 2019-07-09" }
			"12.0.5632.1" { "Cumulative Update Package 17 (CU17) For SQL Server 2014 Service Pack 2 / 2019-04-16" }
			"12.0.5626.1" { "Cumulative Update Package 16 (CU16) For SQL Server 2014 Service Pack 2 / 2019-02-19" }
			"12.0.5605.1" { "Cumulative Update Package 15 (CU15) For SQL Server 2014 Service Pack 2 / 2018-12-12" }
			"12.0.5600.1" { "Cumulative Update Package 14 (CU14) For SQL Server 2014 Service Pack 2 / 2018-10-15" }
			"12.0.5590.1" { "Cumulative Update Package 13 (CU13) For SQL Server 2014 Service Pack 2 / 2018-08-27" }
			"12.0.5589.7" { "Cumulative Update Package 12 (CU12) For SQL Server 2014 Service Pack 2 / 2018-06-18" }
			"12.0.5579.0" { "Cumulative Update Package 11 (CU11) For SQL Server 2014 Service Pack 2 / 2018-03-19" }
			"12.0.5571.0" { "Cumulative Update Package 10 (CU10) For SQL Server 2014 Service Pack 2 - Security Advisory ADV180002 / 2018-01-16" }
			"12.0.5563.0" { "Cumulative Update Package 9 (CU9) For SQL Server 2014 Service Pack 2 / 2017-12-19" }
			"12.0.5557.0" { "Cumulative Update Package 8 (CU8) For SQL Server 2014 Service Pack 2 / 2017-10-17" }
			"12.0.5556.0" { "Cumulative Update Package 7 (CU7) For SQL Server 2014 Service Pack 2 / 2017-08-29" }
			"12.0.5553.0" { "Cumulative Update Package 6 (CU6) For SQL Server 2014 Service Pack 2 / 2017-08-08" }
			"12.0.5546.0" { "Cumulative Update Package 5 (CU5) For SQL Server 2014 Service Pack 2 / 2017-04-18" }
			"12.0.5540.0" { "Cumulative Update Package 4 (CU4) For SQL Server 2014 Service Pack 2 / 2017-02-21" }
			"12.0.5538.0" { "Cumulative Update Package 3 (CU3) For SQL Server 2014 Service Pack 2 - The Article Incorrectly Says It's Version 12.0.5537 / 2016-12-28" }
			"12.0.5532.0" { "MS16-136: Description Of The Security Update For SQL Server 2014 Service Pack 2 CU: November 8, 2016 / 2016-11-08" }
			"12.0.5522.0" { "Cumulative Update Package 2 (CU2) For SQL Server 2014 Service Pack 2 / 2016-10-18" }
			"12.0.5511.0" { "Cumulative Update Package 1 (CU1) For SQL Server 2014 Service Pack 2 / 2016-08-26" }
			"12.0.5223.6" { "Security Update For SQL Server 2014 SP2 GDR: July 9, 2019 / 2019-07-09" }
			"12.0.5214.6" { "Security Update For SQL Server 2014 Service Pack 2 GDR: January 16, 2018 - Security Advisory ADV180002 / 2018-01-16" }
			"12.0.5207.0" { "Security Update For SQL Server 2014 Service Pack 2 GDR: August 8, 2017 / 2017-08-08" }
			"12.0.5203.0" { "MS16-136: Description Of The Security Update For SQL Server 2014 Service Pack 2 GDR: November 8, 2016 / 2016-11-08" }
			"12.0.5000.0" { "SQL Server 2014 Service Pack 2 (SP2) / 2016-07-11" }
			"12.0.4522.0" { "Cumulative Update Package 13 (CU13) For SQL Server 2014 Service Pack 1 / 2017-08-08" }
			"12.0.4511.0" { "Cumulative Update Package 12 (CU12) For SQL Server 2014 Service Pack 1 / 2017-04-18" }
			"12.0.4502.0" { "Cumulative Update Package 11 (CU11) For SQL Server 2014 Service Pack 1 / 2017-02-21" }
			"12.0.4491.0" { "Cumulative Update Package 10 (CU10) For SQL Server 2014 Service Pack 1 / 2016-12-28" }
			"12.0.4487.0" { "MS16-136: Description Of The Security Update For SQL Server 2014 Service Pack 1 CU: November 8, 2016 / 2016-11-08" }
			"12.0.4474.0" { "Cumulative Update Package 9 (CU9) For SQL Server 2014 Service Pack 1 / 2016-10-18" }
			"12.0.4468.0" { "Cumulative Update Package 8 (CU8) For SQL Server 2014 Service Pack 1 / 2016-08-15" }
			"12.0.4463.0" { "A Memory Leak Occurs When You Use Azure Storage In SQL Server 2014 / 2016-08-04" }
			"12.0.4459.0" { "Cumulative Update Package 7 (CU7) For SQL Server 2014 Service Pack 1 / 2016-06-20" }
			"12.0.4457.1" { "REFRESHED Cumulative Update Package 6 (CU6) For SQL Server 2014 Service Pack 1 / 2016-05-31" }
			"12.0.4449.1" { "DEPRECATED Cumulative Update Package 6 (CU6) For SQL Server 2014 Service Pack 1 / 2016-04-19" }
			"12.0.4439.1" { "Cumulative Update Package 5 (CU5) For SQL Server 2014 Service Pack 1 / 2016-02-22" }
			"12.0.4437.0" { "On-Demand Hotfix Update Package For SQL Server 2014 Service Pack 1 Cumulative Update 4 / 2016-02-05" }
			"12.0.4436.0" { "Cumulative Update Package 4 (CU4) For SQL Server 2014 Service Pack 1 / 2015-12-22" }
			"12.0.4433.0" { "FIX: Error 3203 And A SQL Server 2014 Backup Job Can't Restart When A Network Failure Occurs / 2015-12-09" }
			"12.0.4432.0" { "FIX: Error When Your Stored Procedure Calls Another Stored Procedure On Linked Server In SQL Server 2014 / 2015-11-19" }
			"12.0.4237.0" { "Security Update For SQL Server 2014 Service Pack 1 GDR: August 8, 2017 / 2017-08-08" }
			"12.0.4232.0" { "MS16-136: Description Of The Security Update For SQL Server 2014 Service Pack 1 GDR: November 8, 2016 / 2016-11-08" }
			"12.0.4427.24" { "Cumulative Update Package 3 (CU3) For SQL Server 2014 Service Pack 1 / 2015-10-21" }
			"12.0.4422.0" { "Cumulative Update Package 2 (CU2) For SQL Server 2014 Service Pack 1 / 2015-08-17" }
			"12.0.4419.0" { "An On-Demand Hotfix Update Package Is Available For SQL Server 2014 SP1 / 2015-07-24" }
			"12.0.4416.0" { "Cumulative Update Package 1 (CU1) For SQL Server 2014 Service Pack 1 / 2015-06-22" }
			"12.0.4219.0" { "TLS 1.2 Support For SQL Server 2014 SP1 / 2016-01-27" }
			"12.0.4213.0" { "MS15-058: Description Of The Nonsecurity Update For SQL Server 2014 Service Pack 1 GDR: July 14, 2015 / 2015-07-14" }
			"12.0.4100.1" { "SQL Server 2014 Service Pack 1 (SP1) / 2015-05-14" }
			"12.0.4050.0" { "SQL Server 2014 Service Pack 1 (SP1) / 2015-04-15" }
			"12.0.2569.0" { "Cumulative Update Package 14 (CU14) For SQL Server 2014 / 2016-06-20" }
			"12.0.2568.0" { "Cumulative Update Package 13 (CU13) For SQL Server 2014 / 2016-04-18" }
			"12.0.2564.0" { "Cumulative Update Package 12 (CU12) For SQL Server 2014 / 2016-02-22" }
			"12.0.2560.0" { "Cumulative Update Package 11 (CU11) For SQL Server 2014 / 2015-12-22" }
			"12.0.2556.4" { "Cumulative Update Package 10 (CU10) For SQL Server 2014 / 2015-10-20" }
			"12.0.2553.0" { "Cumulative Update Package 9 (CU9) For SQL Server 2014 / 2015-08-17" }
			"12.0.2548.0" { "MS15-058: Description Of The Security Update For SQL Server 2014 QFE: July 14, 2015 / 2015-07-14" }
			"12.0.2546.0" { "Cumulative Update Package 8 (CU8) For SQL Server 2014 / 2015-06-22" }
			"12.0.2506.0" { "Update Enables Premium Storage Support For Data Files On Azure Storage And Resolves Backup Failures / 2015-05-19" }
			"12.0.2505.0" { "FIX: Error 1205 When You Execute Parallel Query That Contains Outer Join Operators In SQL Server 2014 / 2015-05-19" }
			"12.0.2504.0" { "FIX: Poor Performance When A Query Contains Table Joins In SQL Server 2014 / 2015-05-05" }
			"12.0.2504.0" { "FIX: Unpivot Transformation Task Changes Null To Zero Or Empty Strings In SSIS 2014 / 2015-05-05" }
			"12.0.2495.0" { "Cumulative Update Package 7 (CU7) For SQL Server 2014 / 2015-04-23" }
			"12.0.2488.0" { "FIX: Deadlock Cannot Be Resolved Automatically When You Run A SELECT Query That Can Result In A Parallel Batch-Mode Scan / 2015-04-01" }
			"12.0.2485.0" { "An On-Demand Hotfix Update Package Is Available For SQL Server 2014 / 2015-03-16" }
			"12.0.2480.0" { "Cumulative Update Package 6 (CU6) For SQL Server 2014 / 2015-02-16" }
			"12.0.2474.0" { "FIX: Alwayson Availability Groups Are Reported As NOT SYNCHRONIZING / 2015-05-15" }
			"12.0.2472.0" { "FIX: Cannot Show Requested Dialog After You Connect To The Latest SQL Database Update V12 (Preview) With SQL Server 2014 / 2015-01-28" }
			"12.0.2464.0" { "Large Query Compilation Waits On RESOURCE_SEMAPHORE_QUERY_COMPILE In SQL Server 2014 / 2015-01-05" }
			"12.0.2456.0" { "Cumulative Update Package 5 (CU5) For SQL Server 2014 / 2014-12-18" }
			"12.0.2436.0" { "FIX: 'Remote Hardening Failure' Exception Cannot Be Caught And A Potential Data Loss When You Use SQL Server 2014 / 2014-11-27" }
			"12.0.2430.0" { "Cumulative Update Package 4 (CU4) For SQL Server 2014 / 2014-10-21" }
			"12.0.2423.0" { "FIX: RTDATA_LIST Waits When You Run Natively Stored Procedures That Encounter Expected Failures In SQL Server 2014 / 2014-10-22" }
			"12.0.2405.0" { "FIX: Poor Performance When A Query Contains Table Joins In SQL Server 2014 / 2014-09-25" }
			"12.0.2402.0" { "Cumulative Update Package 3 (CU3) For SQL Server 2014 / 2014-08-18" }
			"12.0.2381.0" { "MS14-044: Description Of The Security Update For SQL Server 2014 (QFE) / 2014-08-12" }
			"12.0.2370.0" { "Cumulative Update Package 2 (CU2) For SQL Server 2014 / 2014-06-27" }
			"12.0.2342.0" { "Cumulative Update Package 1 (CU1) For SQL Server 2014 / 2014-04-21" }
			"12.0.2271.0" { "TLS 1.2 Support For SQL Server 2014 RTM / 2016-01-27" }
			"12.0.2269.0" { "MS15-058: Description Of The Security Update For SQL Server 2014 GDR: July 14, 2015 / 2015-07-14" }
			"12.0.2254.0" { "MS14-044: Description Of The Security Update For SQL Server 2014 (GDR) / 2014-08-12" }
			"12.0.2000.8" { "SQL Server 2014 RTM / 2014-04-01" }
			"12.0.1524.0" { "Microsoft SQL Server 2014 Community Technology Preview 2 (CTP2) / 2013-10-15" }
			"11.0.9120.0" { "Microsoft SQL Server 2014 Community Technology Preview 1 (CTP1) / 2013-06-25" }
			"11.0.7507.2" { "Security Update For SQL Server 2012 SP4 GDR: January 12, 2021 / 2021-01-12" }
			"11.0.7493.4" { "Security Update For SQL Server 2012 SP4 GDR: February 11, 2020 / 2020-02-11" }
			"11.0.7469.6" { "On-Demand Hotfix Update Package For SQL Server 2012 SP4 / 2018-03-28" }
			"11.0.7462.6" { "Description Of The Security Update For SQL Server 2012 SP4 GDR: January 12, 2018 - Security Advisory ADV180002 / 2018-01-12" }
			"11.0.7001.0" { "SQL Server 2012 Service Pack 4 (SP4) / 2017-10-05" }
			"11.0.6615.2" { "Description Of The Security Update For SQL Server 2012 SP3 CU: January 16, 2018 - Security Advisory ADV180002 / 2018-01-16" }
			"11.0.6607.3" { "Cumulative Update Package 10 (CU10) For SQL Server 2012 Service Pack 3 / 2017-08-08" }
			"11.0.6607.3" { "Security Update For SQL Server 2012 Service Pack 3 CU: August 8, 2017 / 2017-08-08" }
			"11.0.6598.0" { "Cumulative Update Package 9 (CU9) For SQL Server 2012 Service Pack 3 / 2017-05-15" }
			"11.0.6594.0" { "Cumulative Update Package 8 (CU8) For SQL Server 2012 Service Pack 3 / 2017-03-21" }
			"11.0.6579.0" { "Cumulative Update Package 7 (CU7) For SQL Server 2012 Service Pack 3 / 2017-01-17" }
			"11.0.6567.0" { "Cumulative Update Package 6 (CU6) For SQL Server 2012 Service Pack 3 / 2016-11-17" }
			"11.0.6567.0" { "MS16-136: Description Of The Security Update For SQL Server 2012 Service Pack 3 CU: November 8, 2016 / 2016-11-08" }
			"11.0.6544.0" { "Cumulative Update Package 5 (CU5) For SQL Server 2012 Service Pack 3 / 2016-09-21" }
			"11.0.6540.0" { "Cumulative Update Package 4 (CU4) For SQL Server 2012 Service Pack 3 / 2016-07-19" }
			"11.0.6537.0" { "Cumulative Update Package 3 (CU3) For SQL Server 2012 Service Pack 3 / 2016-05-17" }
			"11.0.6523.0" { "Cumulative Update Package 2 (CU2) For SQL Server 2012 Service Pack 3 / 2016-03-22" }
			"11.0.6518.0" { "Cumulative Update Package 1 (CU1) For SQL Server 2012 Service Pack 3 / 2016-01-19" }
			"11.0.6260.1" { "Description Of The Security Update For SQL Server 2012 SP3 GDR: January 16, 2018 - Security Advisory ADV180002 / 2018-01-16" }
			"11.0.6251.0" { "Description Of The Security Update For SQL Server 2012 Service Pack 3 GDR: August 8, 2017 / 2017-08-08" }
			"11.0.6248.0" { "MS16-136: Description Of The Security Update For SQL Server 2012 Service Pack 3 GDR: November 8, 2016 / 2016-11-08" }
			"11.0.6216.27" { "TLS 1.2 Support For SQL Server 2012 SP3 GDR / 2016-01-27" }
			"11.0.6020.0" { "SQL Server 2012 Service Pack 3 (SP3) / 2015-11-23" }
			"11.0.5678.0" { "Cumulative Update Package 16 (CU16) For SQL Server 2012 Service Pack 2 / 2017-01-18" }
			"11.0.5676.0" { "Cumulative Update Package 15 (CU15) For SQL Server 2012 Service Pack 2 / 2016-11-17" }
			"11.0.5676.0" { "MS16-136: Description Of The Security Update For SQL Server 2012 Service Pack 2 CU: November 8, 2016 / 2016-11-08" }
			"11.0.5657.0" { "Cumulative Update Package 14 (CU14) For SQL Server 2012 Service Pack 2 / 2016-09-20" }
			"11.0.5655.0" { "Cumulative Update Package 13 (CU13) For SQL Server 2012 Service Pack 2 / 2016-07-19" }
			"11.0.5649.0" { "Cumulative Update Package 12 (CU12) For SQL Server 2012 Service Pack 2 / 2016-05-16" }
			"11.0.5646.0" { "Cumulative Update Package 11 (CU11) For SQL Server 2012 Service Pack 2 / 2016-03-22" }
			"11.0.5644.0" { "Cumulative Update Package 10 (CU10) For SQL Server 2012 Service Pack 2 / 2016-01-20" }
			"11.0.5641.0" { "Cumulative Update Package 9 (CU9) For SQL Server 2012 Service Pack 2 / 2015-11-18" }
			"11.0.5636.3" { "FIX: Performance Decrease When Application With Connection Pooling Frequently Connects Or Disconnects In SQL Server / 2015-09-22" }
			"11.0.5634.0" { "Cumulative Update Package 8 (CU8) For SQL Server 2012 Service Pack 2 / 2015-09-21" }
			"11.0.5629.0" { "FIX: Access Violations When You Use The Filetable Feature In SQL Server 2012 / 2015-08-31" }
			"11.0.5623.0" { "Cumulative Update Package 7 (CU7) For SQL Server 2012 Service Pack 2 / 2015-07-20" }
			"11.0.5613.0" { "MS15-058: Description Of The Security Update For SQL Server 2012 Service Pack 2 QFE: July 14, 2015 / 2015-07-14" }
			"11.0.5592.0" { "Cumulative Update Package 6 (CU6) For SQL Server 2012 Service Pack 2 / 2015-05-19" }
			"11.0.5582.0" { "Cumulative Update Package 5 (CU5) For SQL Server 2012 Service Pack 2 / 2015-03-16" }
			"11.0.5571.0" { "FIX: Alwayson Availability Groups Are Reported As NOT SYNCHRONIZING / 2015-05-15" }
			"11.0.5569.0" { "Cumulative Update Package 4 (CU4) For SQL Server 2012 Service Pack 2 / 2015-01-20" }
			"11.0.5556.0" { "Cumulative Update Package 3 (CU3) For SQL Server 2012 Service Pack 2 / 2014-11-17" }
			"11.0.5548.0" { "Cumulative Update Package 2 (CU2) For SQL Server 2012 Service Pack 2 / 2014-09-15" }
			"11.0.5532.0" { "Cumulative Update Package 1 (CU1) For SQL Server 2012 Service Pack 2 / 2014-07-24" }
			"11.0.5522.0" { "FIX: Data Loss In Clustered Index Occurs When You Run Online Build Index In SQL Server 2012 (Hotfix For SQL2012 SP2) / 2014-06-20" }
			"11.0.5388.0" { "MS16-136: Description Of The Security Update For SQL Server 2012 Service Pack 2 GDR: November 8, 2016 / 2016-11-08" }
			"11.0.5352.0" { "TLS 1.2 Support For SQL Server 2012 SP2 GDR / 2016-01-27" }
			"11.0.5343.0" { "MS15-058: Description Of The Security Update For SQL Server 2012 Service Pack 2 GDR: July 14, 2015 / 2015-07-14" }
			"11.0.5058.0" { "SQL Server 2012 Service Pack 2 (SP2) / 2014-06-10" }
			"11.0.3513.0" { "MS15-058: Description Of The Security Update For SQL Server 2012 SP1 QFE: July 14, 2015 / 2015-07-14" }
			"11.0.3492.0" { "Cumulative Update Package 16 (CU16) For SQL Server 2012 Service Pack 1 / 2015-05-18" }
			"11.0.3487.0" { "Cumulative Update Package 15 (CU15) For SQL Server 2012 Service Pack 1 / 2015-03-16" }
			"11.0.3486.0" { "Cumulative Update Package 14 (CU14) For SQL Server 2012 Service Pack 1 / 2015-01-19" }
			"11.0.3460.0" { "MS14-044: Description Of The Security Update For SQL Server 2012 Service Pack 1 (QFE) / 2014-08-12" }
			"11.0.3482.0" { "Cumulative Update Package 13 (CU13) For SQL Server 2012 Service Pack 1 / 2014-11-17" }
			"11.0.3470.0" { "Cumulative Update Package 12 (CU12) For SQL Server 2012 Service Pack 1 / 2014-09-15" }
			"11.0.3449.0" { "Cumulative Update Package 11 (CU11) For SQL Server 2012 Service Pack 1 / 2014-07-21" }
			"11.0.3437.0" { "FIX: Data Loss In Clustered Index Occurs When You Run Online Build Index In SQL Server 2012 (Hotfix For SQL2012 SP1) / 2014-06-10" }
			"11.0.3431.0" { "Cumulative Update Package 10 (CU10) For SQL Server 2012 Service Pack 1 / 2014-05-19" }
			"11.0.3412.0" { "Cumulative Update Package 9 (CU9) For SQL Server 2012 Service Pack 1 / 2014-03-18" }
			"11.0.3401.0" { "Cumulative Update Package 8 (CU8) For SQL Server 2012 Service Pack 1 / 2014-01-20" }
			"11.0.3393.0" { "Cumulative Update Package 7 (CU7) For SQL Server 2012 Service Pack 1 / 2013-11-18" }
			"11.0.3381.0" { "Cumulative Update Package 6 (CU6) For SQL Server 2012 Service Pack 1 / 2013-09-16" }
			"11.0.3373.0" { "Cumulative Update Package 5 (CU5) For SQL Server 2012 Service Pack 1 / 2013-07-16" }
			"11.0.3368.0" { "Cumulative Update Package 4 (CU4) For SQL Server 2012 Service Pack 1 / 2013-05-31" }
			"11.0.3350.0" { "FIX: You Can'T Create Or Open SSIS Projects Or Maintenance Plans After You Apply Cumulative Update 3 For SQL Server 2012 SP1 / 2013-04-17" }
			"11.0.3349.0" { "Cumulative Update Package 3 (CU3) For SQL Server 2012 Service Pack 1 / 2013-03-18" }
			"11.0.3339.0" { "Cumulative Update Package 2 (CU2) For SQL Server 2012 Service Pack 1 / 2013-01-25" }
			"11.0.3335.0" { "FIX: Component Installation Process Fails After You Install SQL Server 2012 SP1 / 2013-01-14" }
			"11.0.3321.0" { "Cumulative Update Package 1 (CU1) For SQL Server 2012 Service Pack 1 / 2012-11-20" }
			"11.0.3156.0" { "MS15-058: Description Of The Security Update For SQL Server 2012 SP1 GDR: July 14, 2015 / 2015-07-14" }
			"11.0.3153.0" { "MS14-044: Description Of The Security Update For SQL Server 2012 Service Pack 1 (GDR) / 2014-08-12" }
			"11.0.3128.0" { "Windows Installer Starts Repeatedly After You Install SQL Server 2012 SP1 / 2013-01-03" }
			"11.0.3000.0" { "SQL Server 2012 Service Pack 1 (SP1) / 2012-11-06" }
			"11.0.2845.0" { "SQL Server 2012 Service Pack 1 Customer Technology Preview 4 (CTP4) / 2012-09-20" }
			"11.0.2809.24" { "SQL Server 2012 Service Pack 1 Customer Technology Preview 3 (CTP3) / 2012-07-05" }
			"11.0.2424.0" { "Cumulative Update Package 11 (CU11) For SQL Server 2012 / 2013-12-17" }
			"11.0.2420.0" { "Cumulative Update Package 10 (CU10) For SQL Server 2012 / 2013-10-21" }
			"11.0.2419.0" { "Cumulative Update Package 9 (CU9) For SQL Server 2012 / 2013-08-21" }
			"11.0.2410.0" { "Cumulative Update Package 8 (CU8) For SQL Server 2012 / 2013-06-18" }
			"11.0.2405.0" { "Cumulative Update Package 7 (CU7) For SQL Server 2012 / 2013-04-15" }
			"11.0.2401.0" { "Cumulative Update Package 6 (CU6) For SQL Server 2012 / 2013-02-18" }
			"11.0.2395.0" { "Cumulative Update Package 5 (CU5) For SQL Server 2012 / 2012-12-18" }
			"11.0.9000.5" { "Microsoft SQL Server 2012 With Power View For Multidimensional Models Customer Technology Preview (CTP3) / 2012-11-27" }
			"11.0.2383.0" { "Cumulative Update Package 4 (CU4) For SQL Server 2012 / 2012-10-18" }
			"11.0.2376.0" { "Microsoft Security Bulletin MS12-070 / 2012-10-09" }
			"11.0.2332.0" { "Cumulative Update Package 3 (CU3) For SQL Server 2012 / 2012-08-29" }
			"11.0.2325.0" { "Cumulative Update Package 2 (CU2) For SQL Server 2012 / 2012-06-18" }
			"11.0.2318.0" { "SQL Server 2012 Express Localdb RTM / 2012-04-19" }
			"11.0.2316.0" { "Cumulative Update Package 1 (CU1) For SQL Server 2012 / 2012-04-12" }
			"11.0.2218.0" { "Microsoft Security Bulletin MS12-070 / 2012-10-09" }
			"11.0.2214.0" { "FIX: SSAS Uses Only 20 Cores In SQL Server 2012 Business Intelligence / 2012-04-06" }
			"11.0.2100.60" { "SQL Server 2012 RTM / 2012-03-06" }
			"11.0.1913.37" { "Microsoft SQL Server 2012 Release Candidate 1 (RC1) / 2011-12-16" }
			"11.0.1750.32" { "Microsoft SQL Server 2012 Release Candidate 0 (RC0) / 2011-11-17" }
			"11.0.1440.19" { "Microsoft SQL Server 2012 (Codename Denali) Community Technology Preview 3 (CTP3) / 2011-07-11" }
			"11.0.1103.9" { "Microsoft SQL Server 2012 (Codename Denali) Community Technology Preview 1 (CTP1) / 2010-11-08" }
			"10.50.6560.0" { "Description Of The Security Update For SQL Server 2008 R2 SP3 GDR: January 6, 2018 - Security Advisory ADV180002 / 2018-01-06" }
			"10.50.6549.0" { "An Unknown But Existing Build / " }
			"10.50.6542.0" { "Intermittent Service Terminations Occur After You Install Any SQL Server 2008 Or SQL Server 2008 R2 Versions From KB3135244 / 2016-03-03" }
			"10.50.6537.0" { "TLS 1.2 Support For SQL Server 2008 R2 SP3 / 2016-01-27" }
			"10.50.6529.0" { "MS15-058: Description Of The Security Update For SQL Server 2008 R2 Service Pack 3 QFE: July 14, 2015 / 2015-07-14" }
			"10.50.6525.0" { "An On-Demand Hotfix Update Package Is Available For SQL Server 2008 R2 Service Pack 3 (SP3) / 2015-02-09" }
			"10.50.6220.0" { "MS15-058: Description Of The Security Update For SQL Server 2008 R2 Service Pack 3 GDR: July 14, 2015 / 2015-07-14" }
			"10.50.6000.34" { "SQL Server 2008 R2 Service Pack 3 (SP3) / 2014-09-26" }
			"10.50.4343.0" { "TLS 1.2 Support For SQL Server 2008 R2 SP2 (IA-64 Only) / 2016-01-27" }
			"10.50.4339.0" { "MS15-058: Description Of The Security Update For SQL Server 2008 R2 Service Pack 2 QFE: July 14, 2015 / 2015-07-14" }
			"10.50.4331.0" { "Restore Log With Standby Mode On An Advanced Format Disk May Cause A 9004 Error In SQL Server 2008 R2 Or SQL Server 2012 / 2014-08-27" }
			"10.50.4321.0" { "MS14-044: Description Of The Security Update For SQL Server 2008 R2 Service Pack 2 (QFE) / 2014-08-12" }
			"10.50.4319.0" { "Cumulative Update Package 13 (CU13) For SQL Server 2008 R2 Service Pack 2 / 2014-06-30" }
			"10.50.4305.0" { "Cumulative Update Package 12 (CU12) For SQL Server 2008 R2 Service Pack 2 / 2014-04-21" }
			"10.50.4302.0" { "Cumulative Update Package 11 (CU11) For SQL Server 2008 R2 Service Pack 2 / 2014-02-18" }
			"10.50.4297.0" { "Cumulative Update Package 10 (CU10) For SQL Server 2008 R2 Service Pack 2 / 2013-12-16" }
			"10.50.4295.0" { "Cumulative Update Package 9 (CU9) For SQL Server 2008 R2 Service Pack 2 / 2013-10-29" }
			"10.50.4290.0" { "Cumulative Update Package 8 (CU8) For SQL Server 2008 R2 Service Pack 2 / 2013-08-30" }
			"10.50.4286.0" { "Cumulative Update Package 7 (CU7) For SQL Server 2008 R2 Service Pack 2 / 2013-06-17" }
			"10.50.4285.0" { "Cumulative Update Package 6 (CU6) For SQL Server 2008 R2 Service Pack 2 (Updated) / 2013-06-13" }
			"10.50.4279.0" { "Cumulative Update Package 6 (CU6) For SQL Server 2008 R2 Service Pack 2 (Replaced) / 2013-04-15" }
			"10.50.4276.0" { "Cumulative Update Package 5 (CU5) For SQL Server 2008 R2 Service Pack 2 / 2013-02-18" }
			"10.50.4270.0" { "Cumulative Update Package 4 (CU4) For SQL Server 2008 R2 Service Pack 2 / 2012-12-17" }
			"10.50.4266.0" { "Cumulative Update Package 3 (CU3) For SQL Server 2008 R2 Service Pack 2 / 2012-10-15" }
			"10.50.4263.0" { "Cumulative Update Package 2 (CU2) For SQL Server 2008 R2 Service Pack 2 / 2012-08-29" }
			"10.50.4260.0" { "Cumulative Update Package 1 (CU1) For SQL Server 2008 R2 Service Pack 2 / 2012-08-01" }
			"10.50.4046.0" { "TLS 1.2 Support For SQL Server 2008 R2 SP2 GDR (IA-64 Only) / 2016-01-27" }
			"10.50.4042.0" { "MS15-058: Description Of The Security Update For SQL Server 2008 R2 Service Pack 2 GDR: July 14, 2015 / 2015-07-14" }
			"10.50.4033.0" { "MS14-044: Description Of The Security Update For SQL Server 2008 R2 Service Pack 2 (GDR) / 2014-08-12" }
			"10.50.4000.0" { "SQL Server 2008 R2 Service Pack 2 (SP2) / 2012-07-26" }
			"10.50.3720.0" { "SQL Server 2008 R2 Service Pack 2 Community Technology Preview (CTP) / 2012-05-13" }
			"10.50.2881.0" { "An On-Demand Hotfix Update Package For SQL Server 2008 R2 Service Pack 1 / 2013-08-12" }
			"10.50.2876.0" { "Cumulative Update Package 13 (CU13) For SQL Server 2008 R2 Service Pack 1 / 2013-06-17" }
			"10.50.2875.0" { "Cumulative Update Package 12 (CU12) For SQL Server 2008 R2 Service Pack 1 (Updated) / 2013-06-13" }
			"10.50.2874.0" { "Cumulative Update Package 12 (CU12) For SQL Server 2008 R2 Service Pack 1 (Replaced) / 2013-04-15" }
			"10.50.2861.0" { "Microsoft Security Bulletin MS12-070 / 2012-10-09" }
			"10.50.2869.0" { "Cumulative Update Package 11 (CU11) For SQL Server 2008 R2 Service Pack 1 / 2013-02-18" }
			"10.50.2868.0" { "Cumulative Update Package 10 (CU10) For SQL Server 2008 R2 Service Pack 1 / 2012-12-17" }
			"10.50.2866.0" { "Cumulative Update Package 9 (CU9) For SQL Server 2008 R2 Service Pack 1 / 2012-11-06" }
			"10.50.2861.0" { "MS12-070: Description Of The Security Update For SQL Server 2008 R2 Service Pack 1 QFE: October 9, 2012 / 2012-10-09" }
			"10.50.2822.0" { "Cumulative Update Package 8 (CU8) For SQL Server 2008 R2 Service Pack 1 / 2012-08-29" }
			"10.50.2817.0" { "Cumulative Update Package 7 (CU7) For SQL Server 2008 R2 Service Pack 1 / 2012-06-18" }
			"10.50.2811.0" { "Cumulative Update Package 6 (CU6) For SQL Server 2008 R2 Service Pack 1 / 2012-04-16" }
			"10.50.2807.0" { "FIX: Access Violation When You Run DML Statements Against A Table That Has Partitioned Indexes In SQL Server 2008 R2 / 2012-03-12" }
			"10.50.2806.0" { "Cumulative Update Package 5 (CU5) For SQL Server 2008 R2 Service Pack 1 / 2012-02-22" }
			"10.50.2799.0" { "FIX: 'Non-Yielding Scheduler' Error Might Occur When You Run A Query That Uses The CHARINDEX Function In SQL Server 2008 R2 / 2012-02-22" }
			"10.50.2796.0" { "Cumulative Update Package 4 (CU4) For SQL Server 2008 R2 Service Pack 1 / 2011-12-20" }
			"10.50.2789.0" { "Cumulative Update Package 3 (CU3) For SQL Server 2008 R2 Service Pack 1 / 2011-10-17" }
			"10.50.2776.0" { "FIX: Slow Performance When An AFTER Trigger Runs On A Partitioned Table In SQL Server 2008 R2 / 2011-10-18" }
			"10.50.2772.0" { "Cumulative Update Package 2 (CU2) For SQL Server 2008 R2 Service Pack 1 / 2011-08-15" }
			"10.50.2769.0" { "Cumulative Update Package 1 (CU1) For SQL Server 2008 R2 Service Pack 1 / 2011-07-18" }
			"10.50.2550.0" { "Microsoft Security Bulletin MS12-070 / 2012-10-09" }
			"10.50.2500.0" { "SQL Server 2008 R2 Service Pack 1 (SP1) / 2011-07-11" }
			"10.50.1817.0" { "Cumulative Update Package 14 (CU14) For SQL Server 2008 R2 / 2012-06-18" }
			"10.50.1815.0" { "Cumulative Update Package 13 (CU13) For SQL Server 2008 R2 / 2012-04-17" }
			"10.50.1810.0" { "Cumulative Update Package 12 (CU12) For SQL Server 2008 R2 / 2012-02-21" }
			"10.50.1809.0" { "Cumulative Update Package 11 (CU11) For SQL Server 2008 R2 / 2012-01-09" }
			"10.50.1807.0" { "Cumulative Update Package 10 (CU10) For SQL Server 2008 R2 / 2011-10-19" }
			"10.50.1804.0" { "Cumulative Update Package 9 (CU9) For SQL Server 2008 R2 / 2011-08-16" }
			"10.50.1800.0" { "FIX: Database Data Files Might Be Incorrectly Marked As Sparse In SQL Server 2008 R2 Or In SQL Server 2008 Even When The Physical Files Are Marked As Not Sparse In The File System / 2011-10-18" }
			"10.50.1797.0" { "Cumulative Update Package 8 (CU8) For SQL Server 2008 R2 / 2011-06-20" }
			"10.50.1790.0" { "MS11-049: Description Of The Security Update For SQL Server 2008 R2 QFE: June 14, 2011 / 2011-06-17" }
			"10.50.1777.0" { "Cumulative Update Package 7 (CU7) For SQL Server 2008 R2 / 2011-06-16" }
			"10.50.1769.0" { "FIX: Non-Yielding Scheduler Error When You Run A Query That Uses A TVP In SQL Server 2008 Or In SQL Server 2008 R2 If SQL Profiler Or SQL Server Extended Events Is Used / 2011-04-18" }
			"10.50.1765.0" { "Cumulative Update Package 6 (CU6) For SQL Server 2008 R2 / 2011-02-21" }
			"10.50.1753.0" { "Cumulative Update Package 5 (CU5) For SQL Server 2008 R2 / 2010-12-23" }
			"10.50.1746.0" { "Cumulative Update Package 4 (CU4) For SQL Server 2008 R2 / 2010-10-18" }
			"10.50.1734.0" { "Cumulative Update Package 3 (CU3) For SQL Server 2008 R2 / 2010-08-20" }
			"10.50.1720.0" { "Cumulative Update Package 2 (CU2) For SQL Server 2008 R2 / 2010-06-25" }
			"10.50.1702.0" { "Cumulative Update Package 1 (CU1) For SQL Server 2008 R2 / 2010-05-18" }
			"10.50.1617.0" { "MS11-049: Description Of The Security Update For SQL Server 2008 R2 GDR: June 14, 2011 / 2011-06-14" }
			"10.50.1600.1" { "SQL Server 2008 R2 RTM / 2010-04-21" }
			"10.50.1352.12" { "Microsoft SQL Server 2008 R2 November Community Technology Preview (CTP) / 2009-11-12" }
			"10.50.1092.20" { "Microsoft SQL Server 2008 R2 August Community Technology Preview (CTP) / 2009-06-30" }
			"10.0.6556.0" { "Description Of The Security Update For SQL Server 2008 SP4 GDR: January 6, 2018 - Security Advisory ADV180002 / 2018-01-06" }
			"10.0.6547.0" { "Intermittent Service Terminations Occur After You Install Any SQL Server 2008 Or SQL Server 2008 R2 Versions From KB3135244 / 2016-03-03" }
			"10.0.6543.0" { "TLS 1.2 Support For SQL Server 2008 SP4 / 2016-01-27" }
			"10.0.6535.0" { "MS15-058: Description Of The Security Update For SQL Server 2008 Service Pack 4 QFE: July 14, 2015 / 2015-07-14" }
			"10.0.6526.0" { "An On-Demand Hotfix Update Package Is Available For SQL Server 2008 Service Pack 4 (SP4) / 2015-02-09" }
			"10.0.6241.0" { "MS15-058: Description Of The Security Update For SQL Server 2008 Service Pack 4 GDR: July 14, 2015 / 2015-07-14" }
			"10.0.6000.29" { "SQL Server 2008 Service Pack 4 (SP4) / 2014-09-30" }
			"10.0.5894.0" { "TLS 1.2 Support For SQL Server 2008 SP3 (IA-64 Only) / 2016-01-27" }
			"10.0.5890.0" { "MS15-058: Description Of The Security Update For SQL Server 2008 Service Pack 3 QFE: July 14, 2015 / 2015-07-14" }
			"10.0.5869.0" { "MS14-044: Description Of The Security Update For SQL Server 2008 SP3 (QFE) / 2014-08-12" }
			"10.0.5867.0" { "FIX: Error 8985 When You Run The 'Dbcc Shrinkfile' Statement By Using The Logical Name Of A File In SQL Server 2008 R2 Or SQL Server 2008 / 2014-07-02" }
			"10.0.5861.0" { "Cumulative Update Package 17 (CU17) For SQL Server 2008 Service Pack 3 / 2014-05-19" }
			"10.0.5852.0" { "Cumulative Update Package 16 (CU16) For SQL Server 2008 Service Pack 3 / 2014-03-17" }
			"10.0.5850.0" { "Cumulative Update Package 15 (CU15) For SQL Server 2008 Service Pack 3 / 2014-01-20" }
			"10.0.5848.0" { "Cumulative Update Package 14 (CU14) For SQL Server 2008 Service Pack 3 / 2013-11-18" }
			"10.0.5846.0" { "Cumulative Update Package 13 (CU13) For SQL Server 2008 Service Pack 3 / 2013-09-16" }
			"10.0.5844.0" { "Cumulative Update Package 12 (CU12) For SQL Server 2008 Service Pack 3 / 2013-07-16" }
			"10.0.5841.0" { "Cumulative Update Package 11 (CU11) For SQL Server 2008 Service Pack 3 (Updated) / 2013-06-13" }
			"10.0.5840.0" { "Cumulative Update Package 11 (CU11) For SQL Server 2008 Service Pack 3 (Replaced) / 2013-05-20" }
			"10.0.5835.0" { "Cumulative Update Package 10 (CU10) For SQL Server 2008 Service Pack 3 / 2013-03-18" }
			"10.0.5829.0" { "Cumulative Update Package 9 (CU9) For SQL Server 2008 Service Pack 3 / 2013-01-23" }
			"10.0.5828.0" { "Cumulative Update Package 8 (CU8) For SQL Server 2008 Service Pack 3 / 2012-11-19" }
			"10.0.5826.0" { "Microsoft Security Bulletin MS12-070 / 2012-10-09" }
			"10.0.5794.0" { "Cumulative Update Package 7 (CU7) For SQL Server 2008 Service Pack 3 / 2012-09-21" }
			"10.0.5788.0" { "Cumulative Update Package 6 (CU6) For SQL Server 2008 Service Pack 3 / 2012-07-16" }
			"10.0.5785.0" { "Cumulative Update Package 5 (CU5) For SQL Server 2008 Service Pack 3 / 2012-05-19" }
			"10.0.5775.0" { "Cumulative Update Package 4 (CU4) For SQL Server 2008 Service Pack 3 / 2012-03-20" }
			"10.0.5770.0" { "Cumulative Update Package 3 (CU3) For SQL Server 2008 Service Pack 3 / 2012-01-16" }
			"10.0.5768.0" { "Cumulative Update Package 2 (CU2) For SQL Server 2008 Service Pack 3 / 2011-11-22" }
			"10.0.5766.0" { "Cumulative Update Package 1 (CU1) For SQL Server 2008 Service Pack 3 / 2011-10-18" }
			"10.0.5544.0" { "TLS 1.2 Support For SQL Server 2008 SP3 GDR (IA-64 Only) / 2016-01-27" }
			"10.0.5538.0" { "MS15-058: Description Of The Security Update For SQL Server 2008 Service Pack 3 GDR: July 14, 2015 / 2015-07-14" }
			"10.0.5520.0" { "MS14-044: Description Of The Security Update For SQL Server 2008 SP3 (GDR) / 2014-08-12" }
			"10.0.5512.0" { "Microsoft Security Bulletin MS12-070 / 2012-10-09" }
			"10.0.5500.0" { "SQL Server 2008 Service Pack 3 (SP3) / 2011-10-06" }
			"10.0.5416.0" { "SQL Server 2008 Service Pack 3 CTP / 2011-08-22" }
			"10.0.4371.0" { "Microsoft Security Bulletin MS12-070 / 2012-10-09" }
			"10.0.4333.0" { "Cumulative Update Package 11 (CU11) For SQL Server 2008 Service Pack 2 / 2012-07-16" }
			"10.0.4332.0" { "Cumulative Update Package 10 (CU10) For SQL Server 2008 Service Pack 2 / 2012-05-20" }
			"10.0.4330.0" { "Cumulative Update Package 9 (CU9) For SQL Server 2008 Service Pack 2 / 2012-03-19" }
			"10.0.4326.0" { "Cumulative Update Package 8 (CU8) For SQL Server 2008 Service Pack 2 / 2012-01-30" }
			"10.0.4323.0" { "Cumulative Update Package 7 (CU7) For SQL Server 2008 Service Pack 2 / 2011-11-21" }
			"10.0.4321.0" { "Cumulative Update Package 6 (CU6) For SQL Server 2008 Service Pack 2 / 2011-09-20" }
			"10.0.4316.0" { "Cumulative Update Package 5 (CU5) For SQL Server 2008 Service Pack 2 / 2011-07-18" }
			"10.0.4285.0" { "Cumulative Update Package 4 (CU4) For SQL Server 2008 Service Pack 2 / 2011-05-16" }
			"10.0.4279.0" { "Cumulative Update Package 3 (CU3) For SQL Server 2008 Service Pack 2 / 2011-03-11" }
			"10.0.4272.0" { "Cumulative Update Package 2 (CU2) For SQL Server 2008 Service Pack 2 / 2011-02-10" }
			"10.0.4266.0" { "Cumulative Update Package 1 (CU1) For SQL Server 2008 Service Pack 2 / 2010-11-15" }
			"10.0.4067.0" { "Microsoft Security Bulletin MS12-070 / 2012-10-09" }
			"10.0.4064.0" { "MS11-049: Description Of The Security Update For SQL Server 2008 Service Pack 2 GDR: June 14, 2011 / 2011-06-14" }
			"10.0.4000.0" { "SQL Server 2008 Service Pack 2 (SP2) / 2010-09-29" }
			"10.0.3798.0" { "SQL Server 2008 Service Pack 2 CTP / 2010-07-07" }
			"10.0.2850.0" { "Cumulative Update Package 16 (CU16) For SQL Server 2008 Service Pack 1 / 2011-09-19" }
			"10.0.2847.0" { "Cumulative Update Package 15 (CU15) For SQL Server 2008 Service Pack 1 / 2011-07-18" }
			"10.0.2841.0" { "MS11-049: Description Of The Security Update For SQL Server 2008 Service Pack 1 QFE: June 14, 2011 / 2011-06-14" }
			"10.0.2821.0" { "Cumulative Update Package 14 (CU14) For SQL Server 2008 Service Pack 1 / 2011-05-16" }
			"10.0.2816.0" { "Cumulative Update Package 13 (CU13) For SQL Server 2008 Service Pack 1 / 2011-03-22" }
			"10.0.2808.0" { "Cumulative Update Package 12 (CU12) For SQL Server 2008 Service Pack 1 / 2011-02-10" }
			"10.0.2804.0" { "Cumulative Update Package 11 (CU11) For SQL Server 2008 Service Pack 1 / 2010-11-15" }
			"10.0.2799.0" { "Cumulative Update Package 10 (CU10) For SQL Server 2008 Service Pack 1 / 2010-09-21" }
			"10.0.2789.0" { "Cumulative Update Package 9 (CU9) For SQL Server 2008 Service Pack 1 / 2010-07-21" }
			"10.0.2787.0" { "FIX: The Reporting Services Service Stops Unexpectedly After You Apply SQL Server 2008 SP1 CU 7 Or CU8 / 2010-07-30" }
			"10.0.2775.0" { "Cumulative Update Package 8 (CU8) For SQL Server 2008 Service Pack 1 / 2010-05-17" }
			"10.0.2766.0" { "Cumulative Update Package 7 (CU7) For SQL Server 2008 Service Pack 1 / 2010-03-26" }
			"10.0.2757.0" { "Cumulative Update Package 6 (CU6) For SQL Server 2008 Service Pack 1 / 2010-01-18" }
			"10.0.2746.0" { "Cumulative Update Package 5 (CU5) For SQL Server 2008 Service Pack 1 / 2009-11-16" }
			"10.0.2740.0" { "FIX: Error Message When You Perform A Rolling Upgrade In A SQL Server 2008 Cluster : '18401, Login Failed For User SQLTEST\Agentservice. Reason: Server Is In Script Upgrade Mode. Only Administrator Can Connect At This Time.[Sqlstate 42000]' / 2009-11-24" }
			"10.0.2734.0" { "Cumulative Update Package 4 (CU4) For SQL Server 2008 Service Pack 1 / 2009-09-22" }
			"10.0.2723.0" { "Cumulative Update Package 3 (CU3) For SQL Server 2008 Service Pack 1 / 2009-07-21" }
			"10.0.2714.0" { "Cumulative Update Package 2 (CU2) For SQL Server 2008 Service Pack 1 / 2009-05-18" }
			"10.0.2712.0" { "FIX: Error Message In SQL Server 2008 When You Run An INSERT SELECT Statement On A Table: 'Violation Of PRIMARY KEY Constraint '<Primarykey>'. Cannot Insert Duplicate Key In Object '<Tablename>'' / 2009-07-21" }
			"10.0.2710.0" { "Cumulative Update Package 1 (CU1) For SQL Server 2008 Service Pack 1 / 2009-04-16" }
			"10.0.2573.0" { "MS11-049: Description Of The Security Update For SQL Server 2008 Service Pack 1 GDR: June 14, 2011 / 2011-06-14" }
			"10.0.2531.0" { "SQL Server 2008 Service Pack 1 (SP1) / 2009-04-07" }
			"10.0.2520.0" { "SQL Server 2008 Service Pack 1 - CTP / 2009-02-23" }
			"10.0.1835.0" { "Cumulative Update Package 10 (CU10) For SQL Server 2008 / 2010-03-15" }
			"10.0.1828.0" { "Cumulative Update Package 9 (CU9) For SQL Server 2008 / 2010-01-18" }
			"10.0.1823.0" { "Cumulative Update Package 8 (CU8) For SQL Server 2008 / 2009-11-16" }
			"10.0.1818.0" { "Cumulative Update Package 7 (CU7) For SQL Server 2008 / 2009-09-21" }
			"10.0.1812.0" { "Cumulative Update Package 6 (CU6) For SQL Server 2008 / 2009-07-21" }
			"10.0.1806.0" { "Cumulative Update Package 5 (CU5) For SQL Server 2008 / 2009-05-18" }
			"10.0.1798.0" { "Cumulative Update Package 4 (CU4) For SQL Server 2008 / 2009-03-17" }
			"10.0.1787.0" { "Cumulative Update Package 3 (CU3) For SQL Server 2008 / 2009-01-19" }
			"10.0.1779.0" { "Cumulative Update Package 2 (CU2) For SQL Server 2008 / 2008-11-19" }
			"10.0.1771.0" { "FIX: You May Receive Incorrect Results When You Run A Query That References Three Or More Tables In The FROM Clause In SQL Server 2008 / 2008-10-29" }
			"10.0.1763.0" { "Cumulative Update Package 1 (CU1) For SQL Server 2008 / 2008-10-28" }
			"10.0.1750.0" { "FIX: A MERGE Statement May Not Enforce A Foreign Key Constraint When The Statement Updates A Unique Key Column That Is Not Part Of A Clustering Key That Has A Single Row As The Update Source In SQL Server 2008 / 2008-08-25" }
			"10.0.1600.22" { "SQL Server 2008 RTM / 2008-08-07" }
			"10.0.1442.32" { "Microsoft SQL Server 2008 RC0 / 2008-06-05" }
			"10.0.1300.13" { "Microsoft SQL Server 2008 CTP, February 2008 / 2008-02-19" }
			"10.0.1075.23" { "Microsoft SQL Server 2008 CTP, November 2007 / 2007-11-18" }
			"10.0.1049.14" { "SQL Server 2008 CTP, July 2007 / 2007-07-31" }
			"10.0.1019.17" { "SQL Server 2008 CTP, June 2007 / 2007-05-21" }
			"9.0.5324" { "MS12-070: Description Of The Security Update For SQL Server 2005 Service Pack 4 QFE / 2012-10-09" }
			"9.0.5296" { "FIX: 'Msg 7359' Error When A View Uses Another View In SQL Server 2005 If The Schema Version Of A Remote Table Is Updated / 2011-10-24" }
			"9.0.5295" { "FIX: SQL Server Agent Job Randomly Stops When You Schedule The Job To Run Past Midnight On Specific Days In SQL Server 2005, In SQL Server 2008 Or In SQL Server 2008 R2 / 2012-05-21" }
			"9.0.5294" { "FIX: Error 5180 When You Use The ONLINE Option To Rebuild An Index In SQL Server 2005 / 2011-08-10" }
			"9.0.5292" { "MS11-049: Description Of The Security Update For SQL Server 2005 Service Pack 4 QFE: June 14, 2011 / 2011-06-14" }
			"9.0.5266" { "Cumulative Update Package 3 (CU3) For SQL Server 2005 Service Pack 4 / 2011-03-22" }
			"9.0.5259" { "Cumulative Update Package 2 (CU2) For SQL Server 2005 Service Pack 4 / 2011-02-22" }
			"9.0.5254" { "Cumulative Update Package 1 (CU1) For SQL Server 2005 Service Pack 4 / 2010-12-24" }
			"9.0.5069" { "Microsoft Security Bulletin MS12-070 / 2012-10-09" }
			"9.0.5057" { "MS11-049: Description Of The Security Update For SQL Server 2005 Service Pack 4 GDR: June 14, 2011 / 2011-06-14" }
			"9.0.5000" { "SQL Server 2005 Service Pack 4 (SP4) / 2010-12-17" }
			"9.0.4912" { "SQL Server 2005 Service Pack 4 (SP4) - Customer Technology Preview (CTP) / 2010-11-03" }
			"9.0.4342" { "FIX: SQL Server Agent Job Randomly Stops When You Schedule The Job To Run Past Midnight On Specific Days In SQL Server 2005, In SQL Server 2008 Or In SQL Server 2008 R2 / 2012-05-21" }
			"9.0.4340" { "MS11-049: Description Of The Security Update For SQL Server 2005 Service Pack 3 QFE: June 14, 2011 / 2011-06-14" }
			"9.0.4325" { "Cumulative Update Package 15 (CU15) For SQL Server 2005 Service Pack 3 / 2011-03-22" }
			"9.0.4317" { "Cumulative Update Package 14 (CU14) For SQL Server 2005 Service Pack 3 / 2011-02-21" }
			"9.0.4315" { "Cumulative Update Package 13 (CU13) For SQL Server 2005 Service Pack 3 / 2010-12-23" }
			"9.0.4311" { "Cumulative Update Package 12 (CU12) For SQL Server 2005 Service Pack 3 / 2010-10-18" }
			"9.0.4309" { "Cumulative Update Package 11 (CU11) For SQL Server 2005 Service Pack 3 / 2010-08-16" }
			"9.0.4305" { "Cumulative Update Package 10 (CU10) For SQL Server 2005 Service Pack 3 / 2010-06-23" }
			"9.0.4294" { "Cumulative Update Package 9 (CU9) For SQL Server 2005 Service Pack 3 / 2010-04-19" }
			"9.0.4285" { "Cumulative Update Package 8 (CU8) For SQL Server 2005 Service Pack 3 / 2010-02-16" }
			"9.0.4273" { "Cumulative Update Package 7 (CU7) For SQL Server 2005 Service Pack 3 / 2009-12-21" }
			"9.0.4268" { "FIX: Error Message When You Add A Subscription To A Republisher That Is In A Merge Publication In SQL Server 2005: 'Cannot Create The Subscription Because The Subscription Already Exists In The Subscription Database' / 2009-12-21" }
			"9.0.4266" { "Cumulative Update Package 6 (CU6) For SQL Server 2005 Service Pack 3 / 2009-10-19" }
			"9.0.4262" { "MS09-062: Description Of The Security Update For SQL Server 2005 Service Pack 3 QFE: October 13, 2009 / 2009-10-13" }
			"9.0.4230" { "Cumulative Update Package 5 (CU5) For SQL Server 2005 Service Pack 3 / 2009-08-17" }
			"9.0.4226" { "Cumulative Update Package 4 (CU4) For SQL Server 2005 Service Pack 3 / 2009-06-16" }
			"9.0.4224" { "FIX: Error Message When You Run A Query That Contains Duplicate Join Conditions In SQL Server 2005: 'Internal Query Processor Error: The Query Processor Could Not Produce A Query Plan' / 2009-06-16" }
			"9.0.4220" { "Cumulative Update Package 3 (CU3) For SQL Server 2005 Service Pack 3 / 2009-04-20" }
			"9.0.4216" { "FIX: The Performance Of Database Mirroring Decreases When You Run A Database Maintenance Job That Generates A Large Number Of Transaction Log Activities In SQL Server 2005 / 2009-04-20" }
			"9.0.4211" { "Cumulative Update Package 2 (CU2) For SQL Server 2005 Service Pack 3 / 2009-02-17" }
			"9.0.4207" { "Cumulative Update Package 1 (CU1) For SQL Server 2005 Service Pack 3 / 2008-12-20" }
			"9.0.4060" { "MS11-049: Description Of The Security Update For SQL Server 2005 Service Pack 3 GDR: June 14, 2011 / 2011-06-14" }
			"9.0.4053" { "MS09-062: Description Of The Security Update For SQL Server 2005 Service Pack 3 GDR: October 13, 2009 / 2009-10-13" }
			"9.0.4035" { "SQL Server 2005 Service Pack 3 (SP3) / 2008-12-15" }
			"9.0.4028" { "SQL Server 2005 Service Pack 3 (SP3) - CTP / 2008-10-27" }
			"9.0.3356" { "Cumulative Update Package 17 (CU17) For SQL Server 2005 Service Pack 2 / 2009-12-21" }
			"9.0.3355" { "Cumulative Update Package 16 (CU16) For SQL Server 2005 Service Pack 2 / 2009-10-19" }
			"9.0.3353" { "MS09-062: Description Of The Security Update For SQL Server 2005 Service Pack 2 QFE: October 13, 2009 / 2009-10-13" }
			"9.0.3330" { "Cumulative Update Package 15 (CU15) For SQL Server 2005 Service Pack 2 / 2009-08-18" }
			"9.0.3328" { "Cumulative Update Package 14 (CU14) For SQL Server 2005 Service Pack 2 / 2009-06-16" }
			"9.0.3325" { "Cumulative Update Package 13 (CU13) For SQL Server 2005 Service Pack 2 / 2009-04-20" }
			"9.0.3320" { "FIX: Error Message When You Run The DBCC CHECKDB Statement On A Database In SQL Server 2005: 'Unable To Deallocate A Kept Page' / 2009-04-01" }
			"9.0.3318" { "FIX: The Wmiprvse.Exe Host Process Stops Responding When You Run A SQL Server 2005-Based Application That Sends A Windows Management Instrumentation (WMI) Query To The SQL Server WMI Provider / 2009-04-20" }
			"9.0.3315" { "Cumulative Update Package 12 (CU12) For SQL Server 2005 Service Pack 2 / 2009-02-17" }
			"9.0.3310" { "MS09-004: Description Of The Security Update For SQL Server 2005 QFE: February 10, 2009 / 2009-02-10" }
			"9.0.3301" { "Cumulative Update Package 11 (CU11) For SQL Server 2005 Service Pack 2 / 2008-12-16" }
			"9.0.3294" { "Cumulative Update Package 10 (CU10) For SQL Server 2005 Service Pack 2 / 2008-10-20" }
			"9.0.3282" { "Cumulative Update Package 9 (CU9) For SQL Server 2005 Service Pack 2 / 2008-06-16" }
			"9.0.3260" { "FIX: Error Message When You Run A Distributed Query In SQL Server 2005: 'OLE DB Provider 'SQLNCLI' For Linked Server '<Linked Server>' Returned Message 'No Transaction Is Active'' / 2008-07-14" }
			"9.0.3259" { "FIX: In SQL Server 2005, The Session That Runs The TRUNCATE TABLE Statement May Stop Responding, And You Cannot End The Session / 2008-08-14" }
			"9.0.3259" { "FIX: An Ongoing MS DTC Transaction Is Orphaned In SQL Server 2005 / 2008-07-14" }
			"9.0.3257" { "Cumulative Update Package 8 (CU8) For SQL Server 2005 Service Pack 2 / 2008-06-18" }
			"9.0.3246" { "FIX: All The MDX Queries That Are Running On An Instance Of SQL Server 2005 Analysis Services Are Canceled When You Start Or Stop A SQL Server Profiler Trace For The Instance / 2008-05-23" }
			"9.0.3244" { "FIX: The Replication Log Reader Agent May Fail Intermittently When A Transactional Replication Synchronizes Data In SQL Server 2005 / 2008-06-03" }
			"9.0.3240" { "FIX: An Access Violation Occurs When You Update A Table Through A View By Using A Cursor In SQL Server 2005 / 2008-05-21" }
			"9.0.3239" { "Cumulative Update Package 7 (CU7) For SQL Server 2005 Service Pack 2 / 2008-04-17" }
			"9.0.3232" { "FIX: Error Message When You Synchronize The Data Of A Merge Replication In SQL Server 2005: 'The Merge Process Is Retrying A Failed Operation Made To Article 'Articlename' - Reason: 'Invalid Input Parameter Values. Check The Status Values For Detail.'' / 2008-03-19" }
			"9.0.3231" { "FIX: Error Message When You Run A Query That Uses A Join Condition In SQL Server 2005: 'Non-Yielding Scheduler' / 2008-03-18" }
			"9.0.3231" { "FIX: Error Message When You Run A Transaction From A Remote Server By Using A Linked Server In SQL Server 2005: 'This Operation Conflicts With Another Pending Operation On This Transaction' / 2008-03-14" }
			"9.0.3230" { "FIX: Error Message When You Run Queries On A Database That Has The SNAPSHOT Isolation Level Enabled In SQL Server 2005: 'Unable To Deallocate A Kept Page' / 2008-03-07" }
			"9.0.3228" { "Cumulative Update Package 6 (CU6) For SQL Server 2005 Service Pack 2 / 2008-02-19" }
			"9.0.3224" { "FIX: A Stored Procedure Cannot Finish Its Execution In SQL Server 2005 / 2008-02-04" }
			"9.0.3221" { "FIX: The Change May Be Undone During The Later Synchronizations When You Change An Article On The Subscriber In SQL Server 2005 / 2008-01-31" }
			"9.0.3221" { "FIX: A Query Takes Longer To Finish In SQL Server 2005 Than In SQL Server 2000 When You Open A Fast Forward-Only Cursor For The Query / 2008-01-11" }
			"9.0.3221" { "FIX: Error Messages When You Delete Some Records Of A Table In A Transaction Or When You Update Some Records Of A Table In A Transaction In SQL Server 2005: 'Msg 9002,' 'Msg 3314,' And 'Msg 9001' / 2008-01-10" }
			"9.0.3221" { "FIX: You Cannot Cancel The Query Execution Immediately If You Open A Fast Forward-Only Cursor For The Query In SQL Server 2005 / 2008-01-09" }
			"9.0.3215" { "Cumulative Update Package 5 (CU5) For SQL Server 2005 Service Pack 2 / 2007-12-18" }
			"9.0.3208" { "FIX: A Federated Database Server Stops Responding When You Run Parallel Queries On A Multiprocessor Computer That Uses NUMA Architecture In SQL Server 2005 / 2007-11-21" }
			"9.0.3206" { "FIX: Conflicts Are Not Logged When You Use The Microsoft SQL Server Subscriber Always Wins Conflict Resolver For An Article In A Merge Replication In Microsoft SQL Server 2005 / 2007-12-11" }
			"9.0.3200" { "Cumulative Update Package 4 (CU4) For SQL Server 2005 Service Pack 2 / 2007-10-17" }
			"9.0.3194" { "FIX: Some Changes From Subscribers Who Use SQL Server 2005 Compact Edition Or Web Synchronization Are Not Uploaded To The Publisher When You Use The Republishing Model In A Merge Publication In Microsoft SQL Server 2005 / 2007-09-24" }
			"9.0.3186" { "FIX: The Performance Of A Query That Performs An Insert Operation Or An Update Operation Is Much Slower In SQL Server 2005 SP2 Than In Earlier Versions Of SQL Server 2005 / 2007-08-29" }
			"9.0.3186" { "FIX: A Cursor Uses The Incorrect Transaction Isolation Level After You Change The Transaction Isolation Level For The Cursor In SQL Server 2005 / 2007-08-24" }
			"9.0.3186" { "FIX: Error Message When You Try To Edit A SQL Server Agent Job Or A Maintenance Plan By Using SQL Server Management Studio In SQL Server 2005: 'String Or Binary Data Would Be Truncated' / 2007-08-23" }
			"9.0.3186" { "FIX: Performance Is Very Slow When The Same Stored Procedure Is Executed At The Same Time In Many Connections On A Multiple-Processor Computer That Is Running SQL Server 2005 / 2007-08-22" }
			"9.0.3186" { "FIX: Error Message When You Try To Update The Index Key Columns Of A Non-Unique Clustered Index In SQL Server 2005: 'Cannot Insert Duplicate Key Row In Object 'Objectname' With Unique Index 'Indexname'' / 2007-08-21" }
			"9.0.3186" { "FIX: Error Message When You Use The UNLOAD And REWIND Options To Back Up A Database To A Tape Device In SQL Server 2005: 'Operation On Device '<Tapedevice>' Exceeded Retry Count' / 2007-08-20" }
			"9.0.3186" { "FIX: Error Message When You Use The Copy Database Wizard To Move A Database From SQL Server 2000 To SQL Server 2005 / 2007-08-20" }
			"9.0.3186" { "FIX: Error Message When You Run A SQL Server 2005 Integration Services Package That Contains A Script Component Transformation:'Insufficient Memory To Continue The Execution Of The Program' / 2007-08-20" }
			"9.0.3186" { "FIX: Error 9003 Is Logged In The SQL Server Error Log File When You Use Log Shipping In SQL Server 2005 / 2007-08-20" }
			"9.0.3186" { "FIX: Data Is Not Replicated To A Subscriber In A Different Partition By Using Parameterized Row Filters In SQL Server 2005 / 2007-08-17" }
			"9.0.3186" { "FIX: Error Message When You Run A Query That Is Associated With A Parallel Execution Plan In SQL Server 2005: 'SQL Server Assertion: File: <Lckmgr.Cpp>, Line=10850 Failed Assertion = 'Getlocallockpartition () == Xactlockinfo->Getlocallockpartition ()'' / 2007-08-17" }
			"9.0.3186" { "FIX: Error Message When You Try To Create An Oracle Publication By Using The New Publication Wizard In SQL Server 2005 Service Pack 2: 'OLE DB Provider 'Oraoledb.ORACLE' For Linked Server <Linkedservername> Returned Message' / 2007-08-17" }
			"9.0.3186" { "FIX: Error Message When You Run A Stored Procedure That References Tables After You Upgrade A Database From SQL Server 2000 To SQL Server 2005: 'A Time-Out Occurred While Waiting For Buffer Latch' / 2007-08-17" }
			"9.0.3186" { "FIX: You Receive A System.Invalidcastexception Exception When You Run An Application That Calls The Server.Jobserver.Jobs.Contains Method On A Computer That Has SQL Server 2005 Service Pack 2 Installed / 2007-08-13" }
			"9.0.3186" { "FIX: An Access Violation May Occur, And You May Receive An Error Message, When You Query The Sys.Dm_Exe_Sessions Dynamic Management View In SQL Server 2005 / 2007-08-13" }
			"9.0.3186" { "FIX: The Performance Of Insert Operations Against A Table That Contains An Identity Column May Be Slow In SQL Server 2005 / 2007-08-10" }
			"9.0.3186" { "FIX: Error Message When You Try To Insert More Than 3 Megabytes Of Data Into A Distributed Partitioned View In SQL Server 2005: 'A System Assertion Check Has Failed' / 2007-08-08" }
			"9.0.3186" { "Cumulative Update Package 3 (CU3) For SQL Server 2005 Service Pack 2 / 2007-08-23" }
			"9.0.3182" { "FIX: You Receive Error 8623 When You Run A Complex Query In SQL Server 2005 / 2007-08-03" }
			"9.0.3179" { "FIX: Error Message When You Run A Full-Text Query Against A Catalog In SQL Server 2005: 'The Execution Of A Full-Text Query Failed. The Content Index Is Corrupt.' / 2007-07-30" }
			"9.0.3178" { "FIX: A SQL Server Agent Job Fails When You Run The SQL Server Agent Job In The Context Of A Proxy Account In SQL Server 2005 / 2007-08-22" }
			"9.0.3177" { "FIX: Error Message When You Run A Stored Procedure That Starts A Transaction That Contains A Transact-SQL Statement In SQL Server 2005: 'New Request Is Not Allowed To Start Because It Should Come With Valid Transaction Descriptor' / 2007-08-22" }
			"9.0.3177" { "FIX: Error Message When You Run A Query That Fires An INSTEAD OF Trigger In SQL Server 2005 Service Pack 2: 'Internal Query Processor Error The Query Processor Could Not Produce A Query Plan' / 2007-08-20" }
			"9.0.3177" { "FIX: Error Message When You Synchronize A Merge Replication In Microsoft SQL Server 2005: 'Msmerge_Del_<GUID>, Line 42 String Or Binary Data Would Be Truncated' / 2007-08-09" }
			"9.0.3175" { "FIX: Error Message When The Distribution Agent Tries To Apply The Snapshot To The Subscriber In SQL Server 2005: 'Must Declare The Scalar Variable '@Variable'' / 2007-08-20" }
			"9.0.3175" { "FIX: The Distribution Agent May Skip Some Rows When You Configure A Transactional Replication That Uses The '-Skiperrors' Parameter In SQL Server 2005 / 2007-08-01" }
			"9.0.3175" { "The Service Pack Update Or Hotfix Installation Stops Unexpectedly When You Try To Install Either Microsoft SQL Server 2005 Service Pack 2 Or A Hotfix For SQL Server 2005 SP2 / 2007-07-10" }
			"9.0.3175" { "FIX: A Foreign Key Constraint That You Drop On A Table At The Publisher Is Not Dropped On The Table At The Subscriber In A SQL Server 2005 Merge Replication / 2007-06-29" }
			"9.0.3175" { "Cumulative Update Package 2 (CU2 Build 3175) For SQL Server 2005 Service Pack 2 Is Available / 2007-06-28" }
			"9.0.3171" { "FIX: You May Receive Error Messages When You Try To Log In To An Instance Of SQL Server 2005 And SQL Server Handles Many Concurrent Connections / 2007-07-16" }
			"9.0.3169" { "FIX: Error Message When You Run A Linked Server Query In SQL Server 2005: 'The Oledbprovider Unisys.Dmsii.1 For Linkserver '<Servername>' Reported An Error The Provider Ran Out Of Memory' / 2007-06-19" }
			"9.0.3169" { "FIX: Changes In The Publisher Database Are Not Replicated To The Subscribers In A Transactional Replication If The Publisher Database Runs Exposed In A Database Mirroring Session In SQL Server 2005 / 2007-05-25" }
			"9.0.3166" { "FIX: Blocking And Performance Problems May Occur When You Enable Trace Flag 1118 In SQL Server 2005 If The Temporary Table Creation Workload Is High / 2007-06-11" }
			"9.0.3166" { "FIX: A Database Is Marked As Suspect When You Update A Table That Contains A Nonclustered Index In SQL Server 2005 / 2007-07-16" }
			"9.0.3161" { "FIX: On A Computer That Is Running SQL Server 2005 And That Has Multiple Processors, You May Receive Incorrect Results When You Run A Query That Contains An Inner Join / 2007-09-24" }
			"9.0.3161" { "FIX: Error Message When You Perform A Piecemeal Restore Operation After You Enable Vardecimal Database Compression In SQL Server 2005 Service Pack 2: 'Piecemeal Restore Is Not Supported When An Upgrade Is Involved' / 2007-06-04" }
			"9.0.3161" { "FIX: The Query Performance Is Slow When You Run A Query That Uses A User-Defined Scalar Function Against An Instance Of SQL Server 2005 / 2007-05-09" }
			"9.0.3161" { "Cumulative Update Package (CU1 Build 3161) For SQL Server 2005 Service Pack 2 Is Available / 2007-04-16" }
			"9.0.3159" { "FIX: The Check Database Integrity Task And The Execute T-SQL Statement Task In A Maintenance Plan May Lose Database Context In Certain Circumstances In SQL Server 2005 Builds 3150 Through 3158 / 2007-04-03" }
			"9.0.3156" { "FIX: Error Message When You Try To Use Database Mail To Send An E-Mail Message In SQL Server 2005: 'Profile Name Is Not Valid (Microsoft SQL Server, Error 14607)' / 2007-04-25" }
			"9.0.3155" { "FIX: Error Message When You Run A Query That Contains Nested FOR XML Clauses In SQL Server 2005: 'The XML Data Type Is Damaged' / 2007-06-13" }
			"9.0.3155" { "FIX: Error Message When You Use Transactional Replication To Replicate The Execution Of Stored Procedures To Subscribers In SQL Server 2005: 'Insufficient Memory To Run Query' / 2007-06-12" }
			"9.0.3155" { "FIX: Failed Assertion Message In The Errorlog File When You Perform Various Operations In SQL Server 2005: 'Failed Assertion = 'Ffalse' Attempt To Access Expired Blob Handle (3)' / 2007-05-15" }
			"9.0.3155" { "FIX: You May Receive An Access Violation When You Perform A Bulk Copy Operation In SQL Server 2005 / 2007-04-25" }
			"9.0.3154" { "FIX: The Distribution Agent Does Not Deliver Commands To The Subscriber Even If The Distribution Agent Is Running In SQL Server 2005 / 2007-04-25" }
			"9.0.3154" { "FIX: The Distribution Agent Generates An Access Violation When You Configure A Transactional Replication Publication To Run An Additional Script After The Snapshot Is Applied At The Subscriber In SQL Server 2005 / 2007-04-25" }
			"9.0.3154" { "FIX: SQL Server 2005 Database Engine Generates Failed Assertion Errors When You Use The Replication Monitor To Monitor The Distribution Database / 2007-04-25" }
			"9.0.3153" { "FIX: A Gradual Increase In Memory Consumption For The USERSTORE_TOKENPERM Cache Store Occurs In SQL Server 2005 / 2007-04-16" }
			"9.0.3152" { "Cumulative Hotfix Package (Build 3152) For SQL Server 2005 Service Pack 2 Is Available / 2007-03-07" }
			"9.0.3080" { "MS09-062: Description Of The Security Update For GDI+ For SQL Server 2005 Service Pack 2 GDR: October 13, 2009 / 2009-10-13" }
			"9.0.3077" { "MS09-004: Description Of The Security Update For SQL Server 2005 GDR: February 10, 2009 / " }
			"9.0.3073" { "MS08-052: Description Of The Security Update For GDI+ For SQL Server 2005 Service Pack 2 GDR: September 9, 2008 / 2008-09-09" }
			"9.0.3068" { "MS08-040: Vulnerabilities In Microsoft SQL Server Could Allow Elevation Of Privilege / 2008-08-05" }
			"9.0.3054" { "FIX: The Check Database Integrity Task And The Execute T-SQL Statement Task In A Maintenance Plan May Lose Database Context In Certain Circumstances In SQL Server 2005 Builds 3042 Through 3053 / 2008-01-02" }
			"9.0.3050" { "Microsoft SQL Server 2005 Service Pack 2 Issue: Cleanup Tasks Run At Different Intervals Than Intended / 2007-03-07" }
			"9.0.3042" { "SQL Server 2005 Service Pack 2 (SP2) / 2007-02-19" }
			"9.0.3033" { "SQL Server 2005 Service Pack 2 (SP2) - CTP December 2006 / 2006-12-19" }
			"9.0.3027" { "SQL Server 2005 Service Pack 2 (SP2) - CTP November 2006 / 2006-11-06" }
			"9.0.3026" { "FIX: A '17187' Error Message May Be Logged In The Errorlog File When An Instance Of SQL Server 2005 Is Under A Heavy Load / 2007-02-14" }
			"9.0.2239" { "FIX: Transactions That Are Being Committed On The Principal Server May Not Be Copied To The Mirror Server When A Database Mirroring Failover Occurs In SQL Server 2005 / 2007-09-24" }
			"9.0.2237" { "FIX: A Memory Leak Occurs When You Call The Initialize Method And The Terminate Method Of The Sqldistribution Object In A Loop In An Application That You Develop By Using Microsoft Activex Replication Controls In SQL Server 2005 / 2007-09-24" }
			"9.0.2236" { "FIX: Error Message When You Use Service Broker In SQL Server 2005: 'An Error Occurred While Receiving Data: '64(The Specified Network Name Is No Longer Available.)'' / 2007-07-29" }
			"9.0.2236" { "FIX: A Service Broker Endpoint Stops Passing Messages In A Database Mirroring Session Of SQL Server 2005 / 2007-07-26" }
			"9.0.2234" { "FIX: SQL Server 2005 Stops And Then Restarts Unexpectedly And Errors Occur In The Tempdb Database / 2007-06-20" }
			"9.0.2233" { "FIX: Error Message When You Use The BULK INSERT Statement To Import A Data File Into A Table In SQL Server 2005 With SP1: 'The OLE DB Provider 'BULK' For Linked Server '(Null)' Reported An Error' / 2007-06-18" }
			"9.0.2233" { "FIX: Error Message When You Use Transactional Replication To Replicate The Execution Of Stored Procedures To Subscribers In SQL Server 2005: 'Insufficient Memory To Run Query' / 2007-06-12" }
			"9.0.2233" { "FIX: You May Receive Error 3456 When You Try To Restore A Transaction Log For A SQL Server 2005 Database / 2007-06-05" }
			"9.0.2232" { "FIX: A Memory Leak Occurs When You Use The Sp_Oamethod Stored Procedure To Call A Method Of A COM Object In SQL Server 2005 / 2007-06-19" }
			"9.0.2231" { "FIX: You Cannot Bring The SQL Server Group Online In A Cluster Environment After You Rename The Virtual Server Name Of The Default Instance Of SQL Server 2005 / 2007-11-06" }
			"9.0.2230" { "FIX: Error Message When You Use SQL Native Client To Connect To An Instance Of A Principal Server In A Database Mirroring Session: 'The Connection Attempted To Fail Over To A Server That Does Not Have A Failover Partner' / 2007-09-20" }
			"9.0.2229" { "FIX: You Receive Error Messages When You Use The BULK INSERT Statement In SQL Server 2005 To Import Data In Bulk / 2007-06-11" }
			"9.0.2227" { "FIX: You May Receive Error 1203 When You Run An INSERT Statement Against A Table That Has An Identity Column In SQL Server 2005 / 2007-06-26" }
			"9.0.2226" { "FIX: Error Message When The Replication Merge Agent Runs To Synchronize A Merge Replication Subscription In SQL Server 2005: 'The Merge Process Failed To Execute A Query Because The Query Timed Out' / 2007-06-22" }
			"9.0.2226" { "FIX: You Receive Error 18815 When The Log Reader Agent Runs For A Transactional Publication In SQL Server 2005 / 2007-06-22" }
			"9.0.2223" { "FIX: You May Experience Poor Performance After You Install SQL Server 2005 Service Pack 1 / 2007-06-18" }
			"9.0.2221" { "FIX: A Script Task Or A Script Component May Not Run Correctly When You Run An SSIS Package In SQL Server 2005 Build 2153 And Later Builds / 2007-07-11" }
			"9.0.2219" { "FIX: The Ghost Row Clean-Up Thread Does Not Remove Ghost Rows On Some Data Files Of A Database In SQL Server 2005 / 2007-04-25" }
			"9.0.2218" { "FIX: SQL Server 2005 Does Not Reclaim The Disk Space That Is Allocated To The Temporary Table If The Stored Procedure Is Stopped / 2007-04-25" }
			"9.0.2216" { "FIX: High CPU Utilization By SQL Server 2005 May Occur When You Use NUMA Architecture On A Computer That Has An X64-Based Version Of SQL Server 2005 Installed / 2007-05-15" }
			"9.0.2214" { "FIX: Error Message When You Run DML Statements Against A Table That Is Published For Merge Replication In SQL Server 2005: 'Could Not Find Stored Procedure' / 2007-02-19" }
			"9.0.2214" { "FIX: I/O Requests That Are Generated By The Checkpoint Process May Cause I/O Bottlenecks If The I/O Subsystem Is Not Fast Enough To Sustain The IO Requests In SQL Server 2005 / 2007-02-13" }
			"9.0.2211" { "FIX: You Receive Error 1456 When You Try To Add A Witness To A DBM Session In SQL Server 2005 / 2007-02-20" }
			"9.0.2211" { "FIX: You Receive Error 1456 When You Add A Witness To A Database Mirroring Session And The Database Name Is The Same As An Existing Database Mirroring Session In SQL Server 2005 / 2007-02-14" }
			"9.0.2209" { "FIX: SQL Server 2005 May Not Perform Histogram Amendments When You Use Trace Flags 2389 And 2390 / 2007-02-07" }
			"9.0.2208" { "FIX: A Memory Leak May Occur Every Time That You Synchronize A SQL Server Mobile Subscriber In SQL Server 2005 / 2007-01-09" }
			"9.0.2207" { "FIX: The Changes Are Not Reflected In The Publication Database After You Reinitialize The Subscriptions In SQL Server 2005 / 2006-12-19" }
			"9.0.2207" { "FIX: Error Message When You Use A Synonym For A Stored Procedure In SQL Server 2005: 'A Severe Error Occurred On The Current Command' / 2006-12-19" }
			"9.0.2207" { "FIX: Error Message In The Database Mail Log When You Try To Use The Sp_Send_Dbmail Stored Procedure To Send An E-Mail In SQL Server 2005: 'Invalid XML Message Format Received On The Externalmailqueue' / 2007-01-02" }
			"9.0.2206" { "FIX: You May Receive An Error Message When You Run A CLR Stored Procedure Or CLR Function That Uses A Context Connection In SQL Server 2005 / 2007-02-01" }
			"9.0.2206" { "FIX: The Full-Text Index Population For The Indexed View Is Very Slow In SQL Server 2005 / 2007-01-12" }
			"9.0.2206" { "FIX: Error Message When You Restore A Transaction-Log Backup That Is Generated In SQL Server 2000 SP4 To An Instance Of SQL Server 2005: Msg 3456, Level 16, State 1, Line 1. Could Not Redo Log Record' / 2007-01-02" }
			"9.0.2206" { "FIX: An Access Violation Is Logged In The SQL Server Errorlog File When You Run A Query That Uses A Plan Guide In SQL Server 2005 / 2006-12-13" }
			"9.0.2202" { "FIX: Some Search Results Are Missing When You Perform A Full-Text Search Operation On A Windows Sharepoint Services 2.0 Site After You Upgrade To SQL Server 2005 / 2007-02-16" }
			"9.0.2201" { "FIX: Updates To The SQL Server Mobile Subscriber May Not Be Reflected In The SQL Server 2005 Merge Publication / 2007-01-10" }
			"9.0.2198" { "FIX: You May Receive Incorrect Results When You Query A Table That Is Published In A Transactional Replication In SQL Server 2005 / 2007-02-21" }
			"9.0.2198" { "FIX: You Receive An Error Message When You Use The Print Preview Option On A Large Report In SQL Server 2005 Reporting Services / 2007-02-20" }
			"9.0.2198" { "FIX: The Restore Operation May Take A Long Time To Finish When You Restore A Database In SQL Server 2005 / 2007-02-02" }
			"9.0.2198" { "FIX: The Metadata Of The Description Object Of A Key Performance Indicator Appears In The Default Language After You Define A Translation For The Description Object In SQL Server 2005 Business Intelligence Development Studio / 2006-12-13" }
			"9.0.2198" { "FIX: SQL Server Agent Does Not Send An Alert Quickly Or Does Not Send An Alert When You Use An Alert Of The SQL Server Event Alert Type In SQL Server 2005 / 2007-01-04" }
			"9.0.2198" { "FIX: Error Message When You Run A Query That Uses A Fast Forward-Only Cursor In SQL Server 2005: 'Query Processor Could Not Produce A Query Plan Because Of The Hints Defined In This Query' / 2006-11-16" }
			"9.0.2198" { "FIX: SQL Server 2005 May Not Send A Message Notification That Is Based On The Specific String In The Forwarded Event When A Computer That Is Running SQL Server 2000 Forwards An Event To A Computer That Is Running SQL Server 2005 / 2006-11-28" }
			"9.0.2198" { "FIX: You Receive An Error Message, Or You Obtain An Incorrect Result When You Query Data In A Partitioned Table That Does Not Have A Clustered Index In SQL Server 2005 / 2006-12-13" }
			"9.0.2198" { "FIX: You May Experience Very Large Growth Increments Of A Principal Database After You Manually Fail Over A Database Mirroring Session In SQL Server 2005 / 2007-01-02" }
			"9.0.2196" { "Fix: Error Message When You Convert A Column From The Varbinary(Max) Data Type To The XML Data Type In SQL Server 2005: 'Msg 6322, Level 16, State 1, Line 2 Too Many Attributes Or Namespace Definitions' / 2006-11-10" }
			"9.0.2196" { "FIX: Error Message When You Trace The Audit Database Management Event And You Try To Bring A Database Online In SQL Server 2005: 'Msg 942, Level 14, State 4, Line 1' / 2006-12-05" }
			"9.0.2195" { "FIX: SQL Server 2005 May Stop Responding When You Use The Sqlbulkcopy Class To Import Data From Another Data Source / 2006-12-19" }
			"9.0.2194" { "FIX: Error Message When You Try To Use A SQL Server Authenticated Login To Log On To An Instance Of SQL Server 2005: 'Logon Error: 18456' / 2006-10-20" }
			"9.0.2192" { "FIX: Error Message When You Use A Table-Valued Function (TVF) Together With The CROSS APPLY Operator In A Query In SQL Server 2005: 'There Is Insufficient System Memory To Run This Query' / 2006-09-29" }
			"9.0.2192" { "FIX: Error Message When You Use A Label After A Transact-SQL Query In SQL Server 2005: 'Incorrect Syntax Near 'X'' / 2006-10-05" }
			"9.0.2191" { "FIX: An Empty String Is Replicated As A NULL Value When You Synchronize A Table To A SQL Server 2005 Compact Edition Subscriber / 2006-12-06" }
			"9.0.2190" { "FIX: Error Message When You Call The Sqltables Function Against An Instance Of SQL Server 2005: 'Invalid Cursor State (0)' / 2006-10-16" }
			"9.0.2189" { "FIX: You May Receive Different Date Values For Each Row When You Use The Getdate Function Within A Case Statement In SQL Server 2005 / 2006-09-22" }
			"9.0.2187" { "FIX: When You Run A Query That References A Partitioned Table In SQL Server 2005, Query Performance May Decrease / 2006-09-22" }
			"9.0.2181" { "FIX: A Deadlock Occurs And A Query Never Finishes When You Run The Query On A Computer That Is Running SQL Server 2005 And Has Multiple Processors / 2007-02-19" }
			"9.0.2181" { "FIX: Error Message When You Run An Application Against SQL Server 2005 That Uses Many Unique User Logins Or Performs Many User Login Impersonations: 'Insufficient System Memory To Run This Query' / 2006-10-04" }
			"9.0.2176" { "FIX: Error Message When You Use SQL Server 2005: 'High Priority System Task Thread Operating System Error Exception 0Xae Encountered' / " }
			"9.0.2176" { "FIX: Log Reader Agent Fails, And An Assertion Error Message Is Logged When You Use Transactional Replication In SQL Server 2005 / 2006-09-06" }
			"9.0.2175" { "FIX: The Color And The Background Image May Not Appear When You Try To Display A Report In HTML Format In Report Manager In SQL Server 2005 Reporting Services / 2006-08-08" }
			"9.0.2175" { "FIX: SQL Server 2005 Performance May Be Slower Than SQL Server 2000 Performance When You Use An API Server Cursor / 2006-08-14" }
			"9.0.2175" { "FIX: In SQL Server 2005, The Sp_Altermessage Stored Procedure Does Not Suppress System Error Messages That Are Logged In The SQL Server Error Log And In The Application Log / 2006-08-30" }
			"9.0.2175" { "FIX: A Query May Take A Long Time To Compile When The Query Contains Several JOIN Clauses Against A SQL Server 2005 Database / 2006-12-14" }
			"9.0.2175" { "FIX: A Handled Access Violation May Occur In The Cvalswitch::Getdatax Function When You Run A Complex Query In SQL Server 2005 / 2006-12-18" }
			"9.0.2174" { "FIX: You May Notice A Large Increase In Compile Time When You Enable Trace Flags 2389 And 2390 In SQL Server 2005 Service Pack 1 / 2006-07-25" }
			"9.0.2167" { "FIX: SQL Server 2005 Treats An Identity Column In A View As An Ordinary Int Column When The Compatibility Level Of The Database Is Set To 80 / 2006-08-09" }
			"9.0.2164" { "FIX: Some Rows In The Text Data Column Are Always Displayed For A Trace That You Create By Using SQL Server Profiler In SQL Server 2005 / 2007-02-08" }
			"9.0.2164" { "FIX: SQL Server 2005 May Overestimate The Cardinality Of The JOIN Operator When A SQL Server 2005 Query Contains A Join Predicate That Is A Multicolumn Predicate / 2006-09-19" }
			"9.0.2164" { "FIX: The SQL Server 2005 Query Optimizer May Incorrectly Estimate The Cardinality For A Query That Has A Predicate That Contains An Index Union Alternative / 2006-09-19" }
			"9.0.2164" { "FIX: Error Message When The Replication Merge Agent Runs In SQL Server 2005: 'Source: MSSQL_REPL, Error Number: MSSQL_REPL-2147199402' / 2006-10-26" }
			"9.0.2164" { "FIX: You May Receive An Error Message When You Manually Define A Back Up Database Task In SQL Server 2005 To Back Up The Transaction Log / 2006-08-29" }
			"9.0.2164" { "FIX: System Performance May Be Slow When An Application Submits Many Queries Against A SQL Server 2005 Database That Uses Simple Parameterization / 2006-09-26" }
			"9.0.2164" { "FIX: A Query Plan Is Not Cached In SQL Server 2005 When The Text Of The Hint Is A Large Object / 2006-09-06" }
			"9.0.2164" { "FIX: Memory Usage Of The Compiled Query Plan May Unexpectedly Increase In SQL Server 2005 / 2006-07-26" }
			"9.0.2164" { "FIX: The BULK INSERT Statement May Not Return Any Errors When You Try To Import Data From A Text File To A Table By Using The BULK INSERT Statement In Microsoft SQL Server 2005 / 2006-08-09" }
			"9.0.2156" { "FIX: The Value Of The Automatic Growth Increment Of A Database File May Be Very Large In SQL Server 2005 With Service Pack 1 / 2006-07-26" }
			"9.0.2153" { "Cumulative Hotfix Package (Build 2153) For SQL Server 2005 Is Available / 2006-09-14" }
			"9.0.2153" { "FIX: You May Receive An Error Message When You Install The Cumulative Hotfix Package (Build 2153) For SQL Server 2005 / 2006-05-23" }
			"9.0.2050" { "FIX: A Script Task Or A Script Component May Not Run Correctly When You Run An SSIS Package In SQL Server 2005 Build 2047 / 2007-07-11" }
			"9.0.2047" { "SQL Server 2005 Service Pack 1 (SP1) / 2006-04-18" }
			"9.0.2040" { "SQL Server 2005 Service Pack 1 (SP1) CTP March 2006 / 2006-03-12" }
			"9.0.2029" { "SQL Server 2005 Service Pack 1 (SP1) Beta / " }
			"9.0.1561" { "FIX: A Script Task Or A Script Component May Not Run Correctly When You Run An SSIS Package In SQL Server 2005 Build 1500 And Later Builds / 2007-07-11" }
			"9.0.1558" { "FIX: Error Message When You Restore A Transaction-Log Backup That Is Generated In SQL Server 2000 SP4 To An Instance Of SQL Server 2005: 'Msg 3456, Level 16, State 1, Line 1. Could Not Redo Log Record' / 2007-01-04" }
			"9.0.1554" { "FIX: When You Query Through A View That Uses The ORDER BY Clause In SQL Server 2005, The Result Is Still Returned In Random Order / 2007-06-26" }
			"9.0.1551" { "FIX: Error Message When You Schedule Some SQL Server 2005 Integration Services Packages To Run As Jobs: 'Package <Packagename> Has Been Cancelled' / 2007-01-22" }
			"9.0.1551" { "FIX: After You Detach A Microsoft SQL Server 2005 Database That Resides On Network-Attached Storage, You Cannot Reattach The SQL Server Database / 2006-11-22" }
			"9.0.1550" { "FIX: The Value Of The Automatic Growth Increment Of A Database File May Be Very Large In SQL Server 2005 / 2006-07-26" }
			"9.0.1550" { "FIX: You Receive An Error Message When You Try To Create A Differential Database Backup In SQL Server 2005 / 2006-11-22" }
			"9.0.1547" { "FIX: You Notice Additional Random Trailing Character In Values When You Retrieve The Values From A Fixed-Size Character Column Or A Fixed-Size Binary Column Of A Table In SQL Server 2005 / 2006-11-20" }
			"9.0.1545" { "FIX: SQL Server 2005 Performance May Be Slower Than SQL Server 2000 Performance When You Use An API Server Cursor / 2006-08-14" }
			"9.0.1541" { "FIX: Error Message When You Use A Server-Side Cursor To Run A Large Complex Query In SQL Server 2005: 'Error: 8623, Severity: 16, State: 1 The Query Processor Ran Out Of Internal Resources' / 2006-11-22" }
			"9.0.1541" { "FIX: You May Receive More Than 100,000 Page Faults When You Try To Back Up A SQL Server 2005 Database That Contains Hundreds Of Files And File Groups / 2006-11-22" }
			"9.0.1539" { "FIX: SQL Server 2005 System Performance May Be Slow When You Use A Keyset-Driven Cursor To Execute A FETCH Statement / 2006-08-11" }
			"9.0.1538" { "FIX: The SQL Server 2005 Sqlcommandbuilder.Deriveparameters Method Returns An Exception When The Input Parameter Is A XML Parameter That Has An Associated XSD From An SQL Schema / 2006-07-26" }
			"9.0.1536" { "FIX: The Monitor Server Does Not Monitor All Primary Servers And Secondary Servers When You Configure Log Shipping In SQL Server 2005 / 2006-07-26" }
			"9.0.1534" { "FIX: When You Run The 'Dbcc Dbreindex' Command Or The 'Alter Index' Command, Some Transactions Are Not Replicated To The Subscribers In A Transactional Replication In SQL Server 2005 / 2007-05-15" }
			"9.0.1533" { "FIX: Errors May Be Generated In The Tempdb Database When You Create And Then Drop Many Temporary Tables In SQL Server 2005 / 2006-07-26" }
			"9.0.1532" { "FIX: Indexes May Grow Very Large When You Insert A Row Into A Table And Then Update The Same Row In SQL Server 2005 / 2007-01-09" }
			"9.0.1531" { "FIX: The Internal Deadlock Monitor May Not Detect A Deadlock Between Two Or More Sessions In SQL Server 2005 / 2006-07-26" }
			"9.0.1528" { "FIX: When You Start A Merge Agent, Synchronization Between The Subscriber And The Publisher Takes A Long Time To Be Completed In SQL Server 2005 / 2007-01-15" }
			"9.0.1528" { "FIX: The CPU Usage Of The Server Reaches 100% When Many DML Activities Occur In SQL Server 2005 / 2007-01-04" }
			"9.0.1528" { "FIX: You Experience A Slow Uploading Process If Conflicts Occur When Many Merge Agents Upload Changes To The Publishers At The Same Time In SQL Server 2005 / 2007-01-11" }
			"9.0.1528" { "FIX: The Merge Agent Fails And A 'Permission Denied' Error Message Is Logged When You Synchronize A SQL Server 2005-Based Merge Publication / " }
			"9.0.1528" { "FIX: Error Message When An ADO.NET-Connected Application Tries To Reuse A Connection From The Connection Pool In SQL Server 2005: 'The Request Failed To Run Because The Batch Is Aborted' / 2006-07-26" }
			"9.0.1519" { "FIX: The Merge Agent Does Not Use A Specified Custom User Update To Handle Conflicting UPDATE Statements In SQL Server 2005 / 2007-01-20" }
			"9.0.1518" { "FIX: A SQL Server Login May Have More Permissions When You Log On To An Instance Of SQL Server 2005 / 2006-09-22" }
			"9.0.1518" { "FIX: An Incorrect Result May Appear In The Subscribing Database When You Set Database Mirroring For A Database And Database Failover Occurs In SQL Server 2005 / 2006-07-26" }
			"9.0.1518" { "FIX: You May Receive Error Messages When You Use The Sp_Cursoropen Statement To Open A Cursor On A User-Defined Stored Procedure In SQL Server 2005 / 2006-07-26" }
			"9.0.1514" { "FIX: The Replication On The Server Does Not Work Any Longer When You Manually Fail Over Databases In SQL Server 2005 / 2006-07-26" }
			"9.0.1503" { "FIX: You May Receive An Access Violation Error Message When You Run A SELECT Query In SQL Server 2005 / 2006-07-26" }
			"9.0.1502" { "FIX: You Cannot Restore The Log Backups On The Mirror Server After You Remove Database Mirroring For The Mirror Database In SQL Server 2005 / 2006-07-26" }
			"9.0.1500" { "FIX: Error Message When You Run Certain Queries Or Certain Stored Procedures In SQL Server 2005: 'A Severe Error Occurred On The Current Command' / 2006-06-01" }
			"9.0.1406" { "FIX: A Script Task Or A Script Component May Not Run Correctly When You Run An SSIS Package In SQL Server 2005 Build 1399 / 2007-07-11" }
			"9.0.1399" { "SQL Server 2005 RTM / 2005-11-07" }
			"8.0.2305" { "MS12-060: Description Of The Security Update For SQL Server 2000 Service Pack 4 QFE: August 14, 2012 / 2012-08-14" }
			"8.0.2301" { "MS12-027: Description Of The Security Update For Microsoft SQL Server 2000 Service Pack 4 QFE: April 10, 2012 / 2012-04-10" }
			"8.0.2283" { "FIX: An Access Violation Occurs When You Run A DELETE Statement Or An UPDATE Statement In The Itanium-Based Versions Of SQL Server 2000 After You Install Security Update MS09-004 / 2009-06-15" }
			"8.0.2282" { "MS09-004: Description Of The Security Update For SQL Server 2000 QFE And For MSDE 2000: February 10, 2009 / 2009-02-10" }
			"8.0.2279" { "FIX: When You Run The Spsbackup.Exe Utility To Back Up A SQL Server 2000 Database That Is Configured As A Back-End Database For A Windows Sharepoint Services Server, The Backup Operation Fails / 2009-04-08" }
			"8.0.2273" { "MS08-040: Description Of The Security Update For SQL Server 2000 QFE And MSDE 2000 July 8, 2008 / 2008-08-05" }
			"8.0.2271" { "FIX: The SPACE Function Always Returns One Space In SQL Server 2000 If The SPACE Function Uses A Collation That Differs From The Collation Of The Current Database / 2008-03-12" }
			"8.0.2265" { "FIX: The Data On The Publisher Does Not Match The Data On The Subscriber When You Synchronize A SQL Server 2005 Mobile Edition Subscriber With A SQL Server 2000 'Merge Replication' Publisher / 2007-12-19" }
			"8.0.2253" { "FIX: The CPU Utilization May Suddenly Increase To 100 Percent When There Are Many Connections To An Instance Of SQL Server 2000 On A Computer That Has Multiple Processors / 2007-10-09" }
			"8.0.2249" { "FIX: An Access Violation May Occur When You Try To Log In To An Instance Of SQL Server 2000 / 2007-05-25" }
			"8.0.2248" { "FIX: The Foreign Key That You Created Between Two Tables Does Not Work After You Run The CREATE INDEX Statement In SQL Server 2000 / 2007-06-14" }
			"8.0.2246" { "An Updated Version Of Sqlvdi.Dll Is Now Available For SQL Server 2000 / 2007-06-18" }
			"8.0.2245" { "FIX: You May Receive An Assertion Or Database Corruption May Occur When You Use The Bcp Utility Or The 'Bulk Insert' Transact-SQL Command To Import Data In SQL Server 2000 / 2007-04-24" }
			"8.0.2244" { "FIX: A Hotfix For Microsoft SQL Server 2000 Service Pack 4 May Not Update All The Necessary Files On An X64-Based Computer / 2007-05-10" }
			"8.0.2242" { "FIX: In SQL Server 2000, The Synchronization Process Is Slow, And The CPU Usage Is High On The Computer That Is Configured As The Distributor / 2007-03-28" }
			"8.0.2238" { "FIX: The Merge Agent Fails Intermittently When You Use Merge Replication That Uses A Custom Resolver After You Install SQL Server 2000 Service Pack 4 / 2007-02-21" }
			"8.0.2236" { "FIX: CPU Utilization May Approach 100 Percent On A Computer That Is Running SQL Server 2000 After You Run The BACKUP DATABASE Statement Or The BACKUP LOG Statement / 2007-02-02" }
			"8.0.2234" { "FIX: Error Messages When You Try To Update Table Rows Or Insert Table Rows Into A Table In SQL Server 2000: '644' Or '2511' / 2007-02-22" }
			"8.0.2232" { "FIX: SQL Server 2000 Stops Responding When You Cancel A Query Or When A Query Time-Out Occurs, And Error Messages Are Logged In The SQL Server Error Log File / 2007-01-15" }
			"8.0.2231" { "FIX: The Sqldumper.Exe Utility Cannot Generate A Filtered SQL Server Dump File When You Use The Remote Desktop Connection Service Or Terminal Services To Connect To A Windows 2000 Server-Based Computer In SQL Server 2000 / 2007-06-19" }
			"8.0.2229" { "FIX: Error Message When You Create A Merge Replication For Tables That Have Computed Columns In SQL Server 2000 Service Pack 4: 'The Process Could Not Log Conflict Information' / 2007-07-24" }
			"8.0.2226" { "FIX: You May Experience One Or More Symptoms When You Run A 'CREATE INDEX' Statement On An Instance Of SQL Server 2000 / 2006-11-20" }
			"8.0.2226" { "FIX: You May Receive Inconsistent Comparison Results When You Compare Strings By Using A Width Sensitive Collation In SQL Server 2000 / 2006-11-13" }
			"8.0.2223" { "FIX: The Server Stops Responding, The Performance Is Slow, And A Time-Out Occurs In SQL Server 2000 / 2007-07-20" }
			"8.0.2223" { "FIX: Error Message When You Schedule A Replication Merge Agent Job To Run After You Install SQL Server 2000 Service Pack 4: 'The Process Could Not Enumerate Changes At The 'Subscriber'' / 2006-10-31" }
			"8.0.2218" { "FIX: The Result May Be Sorted In The Wrong Order When You Run A Query That Uses The ORDER BY Clause To Sort A Column In A Table In SQL Server 2000 / 2007-06-19" }
			"8.0.2217" { "FIX: You Cannot Stop The SQL Server Service, Or Many Minidump Files And Many Log Files Are Generated In SQL Server 2000 / 2007-10-25" }
			"8.0.2215" { "FIX: Data In A Subscriber Of A Merge Publication In SQL Server 2000 Differs From The Data In The Publisher / 2007-01-12" }
			"8.0.2215" { "FIX: The Query Performance May Be Slow When You Query Data From A View In SQL Server 2000 / 2006-10-05" }
			"8.0.2215" { "FIX: Error Message When You Configure An Immediate Updating Transactional Replication In SQL Server 2000: 'Implicit Conversion From Datatype 'Text' To 'Nvarchar' Is Not Allowed' / 2006-10-30" }
			"8.0.2215" { "FIX: You May Receive An Access Violation Error Message When You Import Data By Using The 'Bulk Insert' Command In SQL Server 2000 / 2006-12-28" }
			"8.0.2209" { "The Knowledge Base (KB) Article You Requested Is Currently Not Available / " }
			"8.0.2207" { "FIX: A SQL Server 2000 Session May Be Blocked For The Whole Time That A Snapshot Agent Job Runs / 2006-08-28" }
			"8.0.2201" { "FIX: Error Message When You Try To Run A Query On A Linked Server In SQL Server 2000 / 2006-08-21" }
			"8.0.2199" { "FIX: SQL Server 2000 May Take A Long Time To Complete The Synchronization Phase When You Create A Merge Publication / 2006-07-26" }
			"8.0.2197" { "FIX: Each Query Takes A Long Time To Compile When You Execute A Single Query Or When You Execute Multiple Concurrent Queries In SQL Server 2000 / 2006-08-02" }
			"8.0.2197" { "FIX: The Query May Return Incorrect Results, And The Execution Plan For The Query May Contain A 'Table Spool' Operator In SQL Server 2000 / 2006-08-08" }
			"8.0.2197" { "FIX: A Profiler Trace In SQL Server 2000 May Stop Logging Events Unexpectedly, And You May Receive The Following Error Message: 'Failed To Read Trace Data' / 2006-10-18" }
			"8.0.2196" { "FIX: A Memory Leak Occurs When You Run A Remote Query By Using A Linked Server In SQL Server 2000 / 2006-08-14" }
			"8.0.2194" { "FIX: Error 17883 Is Logged In The SQL Server Error Log, And The Instance Of SQL Server 2000 Temporarily Stops Responding / 2007-02-21" }
			"8.0.2194" { "FIX: You Receive An Access Violation Error Message When You Try To Perform A Read Of A Large Binary Large Object Column In SQL Server 2000 / 2006-09-22" }
			"8.0.2192" { "FIX: You May Notice A Decrease In Performance When You Run A Query That Uses The UNION ALL Operator In SQL Server 2000 Service Pack 4 / 2006-08-04" }
			"8.0.2191" { "FIX: Error Message When You Run SQL Server 2000: 'Failed Assertion = 'Lockfound == TRUE'' / 2006-07-26" }
			"8.0.2191" { "FIX: You May Experience Heap Corruption, And SQL Server 2000 May Shut Down With Fatal Access Violations When You Try To Browse Files In SQL Server 2000 Enterprise Manager On A Windows Server 2003 X64-Based Computer / 2006-10-03" }
			"8.0.2189" { "FIX: An Access Violation May Occur When You Run A Query On A Table That Has A Multicolumn Index In SQL Server 2000 / 2006-07-26" }
			"8.0.2189" { "FIX: The SQL Server Process May End Unexpectedly When You Turn On Trace Flag -T1204 And A Profiler Trace Is Capturing The Lock:Deadlock Chain Event In SQL Server 2000 SP4 / 2006-07-19" }
			"8.0.2187" { "FIX: A Deadlock Occurs When The Scheduled SQL Server Agent Job That You Add Or That You Update Is Running In SQL Server 2000 / 2007-06-18" }
			"8.0.2187" { "A Cumulative Hotfix Package Is Available For SQL Server 2000 Service Pack 4 Build 2187 / 2006-10-16" }
			"8.0.2187" { "FIX: The Database Status Changes To Suspect When You Perform A Bulk Copy In A Transaction And Then Roll Back The Transaction In SQL Server 2000 / 2006-07-26" }
			"8.0.2187" { "FIX: Error Message When You Try To Apply A Hotfix On A SQL Server 2000-Based Computer That Is Configured As A MSCS Node: 'An Error In Updating Your System Has Occurred' / 2006-12-11" }
			"8.0.2180" { "FIX: The Password That You Specify In A BACKUP Statement Appears In The SQL Server Errorlog File Or In The Application Event Log If The BACKUP Statement Does Not Run In SQL Server 2000 / 2007-02-19" }
			"8.0.2180" { "FIX: You May Receive Error Messages When You Use Linked Servers In SQL Server 2000 On A 64-Bit Itanium Processor / 2006-07-26" }
			"8.0.2175" { "FIX: No Rows May Be Returned, And You May Receive An Error Message When You Try To Import SQL Profiler Trace Files Into Tables By Using The Fn_Trace_Gettable Function In SQL Server 2000 / 2006-07-26" }
			"8.0.2172" { "FIX: When You Query A View That Was Created By Using The VIEW_METADATA Option, An Access Violation May Occur In SQL Server 2000 / 2006-07-26" }
			"8.0.2171" { "FIX: Automatic Checkpoints On Some SQL Server 2000 Databases Do Not Run As Expected / 2006-07-26" }
			"8.0.2168" { "FIX: An Error Occurs When You Try To Access The Analysis Services Performance Monitor Counter Object After You Apply Windows Server 2003 SP1 / 2006-11-21" }
			"8.0.2166" { "FIX: An Error Message Is Logged, And New Diagnostics Do Not Capture The Thread Stack When The SQL Server User Mode Scheduler (UMS) Experiences A Nonyielding Thread In SQL Server 2000 Service Pack 4 / 2006-07-26" }
			"8.0.2162" { "A Cumulative Hotfix Package Is Available For SQL Server 2000 Service Pack 4 Build 2162 / 2006-09-15" }
			"8.0.2159" { "FIX: You May Experience Concurrency Issues When You Run The DBCC INDEXDEFRAG Statement In SQL Server 2000 / 2006-07-26" }
			"8.0.2156" { "FIX: You Receive An Error Message When You Try To Rebuild The Master Database After You Have Installed Hotfix Builds In SQL Server 2000 SP4 64-Bit / 2006-07-25" }
			"8.0.2151" { "FIX: You Receive An 'Error: 8526, Severity: 16, State: 2' Error Message In SQL Profiler When You Use SQL Query Analyzer To Start Or To Enlist Into A Distributed Transaction After You Have Installed SQL Server 2000 SP4 / 2006-07-25" }
			"8.0.2151" { "FIX: Incorrect Data Is Inserted Unexpectedly When You Perform A Bulk Copy Operation By Using The DB-Library API In SQL Server 2000 Service Pack 4 / 2007-06-13" }
			"8.0.2148" { "FIX: An Access Violation May Occur When You Run A SELECT Query And The NO_BROWSETABLE Option Is Set To ON In Microsoft SQL Server 2000 / 2006-07-25" }
			"8.0.2148" { "FIX: An Access Violation Occurs In The Mssdi98.Dll File, And SQL Server Crashes When You Use SQL Query Analyzer To Debug A Stored Procedure In SQL Server 2000 Service Pack 4 / 2006-07-25" }
			"8.0.2148" { "FIX: The Mssdmn.Exe Process May Use Lots Of CPU Capacity When You Perform A SQL Server 2000 Full Text Search Of Office Word Documents / 2006-06-01" }
			"8.0.2148" { "FIX: The Results Of The Query May Be Returned Much Slower Than You Expect When You Run A Query That Includes A GROUP BY Statement In SQL Server 2000 / 2006-06-01" }
			"8.0.2148" { "FIX: You Receive An Error Message If You Use The Sp_Addalias Or Sp_Dropalias Procedures When The IMPLICIT_TRANSACTIONS Option Is Set To ON In SQL Server 2000 SP4 / 2006-07-25" }
			"8.0.2148" { "FIX: Some 32-Bit Applications That Use SQL-DMO And SQL-VDI Apis May Stop Working After You Install SQL Server 2000 Service Pack 4 On An Itanium-Based Computer / 2006-06-01" }
			"8.0.2148" { "FIX: You Receive A 'Getting Registry Information' Message When You Run The Sqldiag.Exe Utility After You Install SQL Server 2000 SP4 / 2006-07-25" }
			"8.0.2147" { "FIX: You May Experience Slow Server Performance When You Start A Trace In An Instance Of SQL Server 2000 That Runs On A Computer That Has More Than Four Processors / 2006-06-01" }
			"8.0.2145" { "FIX: A Query That Uses A View That Contains A Correlated Subquery And An Aggregate Runs Slowly / 2005-10-25" }
			"8.0.2145" { "FIX: You Receive Query Results That Were Not Expected When You Use Both ANSI Joins And Non-ANSI Joins / 2006-06-07" }
			"8.0.2066" { "Microsoft Security Bulletin MS12-060 / 2012-08-14" }
			"8.0.2065" { "MS12-027: Description Of The Security Update For Microsoft SQL Server 2000 Service Pack 4 GDR: April 10, 2012 / 2012-04-10" }
			"8.0.2055" { "MS09-004: Vulnerabilities In Microsoft SQL Server Could Allow Remote Code Execution / 2009-02-10" }
			"8.0.2050" { "MS08-040: Description Of The Security Update For SQL Server 2000 GDR And MSDE 2000: July 8, 2008 / 2008-07-08" }
			"8.0.2040" { "FIX: Not All Memory Is Available When AWE Is Enabled On A Computer That Is Running A 32-Bit Version Of SQL Server 2000 SP4 / 2006-08-15" }
			"8.0.2039" { "SQL Server 2000 Service Pack 4 (SP4) / 2005-05-06" }
			"8.0.2026" { "SQL Server 2000 Service Pack 4 (SP4) Beta / " }
			"8.0.1547" { "FIX: You May Experience Slow Server Performance When You Start A Trace In An Instance Of SQL Server 2000 That Runs On A Computer That Has More Than Four Processors / 2006-06-01" }
			"8.0.1077" { "983814 MS12-070: Description Of The Security Update For SQL Server 2000 Reporting Services Service Pack 2 / 2012-10-09" }
			"8.0.1037" { "FIX: CPU Utilization May Approach 100 Percent On A Computer That Is Running SQL Server 2000 After You Run The BACKUP DATABASE Statement Or The BACKUP LOG Statement / " }
			"8.0.1036" { "FIX: Error Message When You Run A Full-Text Query In SQL Server 2000: 'Error: 17883, Severity: 1, State: 0' / 2007-01-11" }
			"8.0.1035" { "FIX: The 'Audit Logout' Event Does Not Appear In The Trace Results File When You Run A Profiler Trace Against A Linked Server Instance In SQL Server 2000 / 2006-09-22" }
			"8.0.1034" { "FIX: You May Intermittently Experience An Access Violation Error When A Query Is Executed In A Parallel Plan And The Execution Plan Contains Either A HASH JOIN Operation Or A Sort Operation In SQL Server 2000 / 2006-08-09" }
			"8.0.1029" { "FIX: Error Message When You Run An UPDATE Statement That Uses Two JOIN Hints To Update A Table In SQL Server 2000: 'Internal SQL Server Error' / 2006-06-01" }
			"8.0.1027" { "FIX: A 17883 Error May Occur You Run A Query That Uses A Hash Join In SQL Server 2000 / 2006-07-25" }
			"8.0.1025" { "FIX: You Receive Incorrect Results When You Run A Query That Uses A Cross Join Operator In SQL Server 2000 SP3 / 2006-06-01" }
			"8.0.1025" { "FIX: An Access Violation May Occur When You Run A SELECT Query And The NO_BROWSETABLE Option Is Set To ON In Microsoft SQL Server 2000 / 2006-07-25" }
			"8.0.1024" { "FIX: Error Message When You Use SQL Server 2000: 'Time Out Occurred While Waiting For Buffer Latch Type 3' / 2006-07-25" }
			"8.0.1021" { "FIX: Server Network Utility May Display Incorrect Protocol Properties In SQL Server 2000 / 2006-07-25" }
			"8.0.1020" { "FIX: The Subscriber May Not Be Able To Upload Changes To The Publisher When You Incrementally Add An Article To A Publication In SQL Server 2000 SP3 / 2006-07-25" }
			"8.0.1019" { "FIX: You May Receive A Memory-Related Error Message When You Repeatedly Create And Destroy An Out-Of-Process COM Object Within The Same Batch Or Stored Procedure In SQL Server 2000 / 2006-06-01" }
			"8.0.1017" { "FIX: The BULK INSERT Statement Silently Skips Insert Attempts When The Data Value Is NULL And The Column Is Defined As NOT NULL For INT, SMALLINT, And BIGINT Data Types In SQL Server 2000 / 2006-06-01" }
			"8.0.1014" { "FIX: You May Receive Error Message 701, Error Message 802, And Error Message 17803 When Many Hashed Buffers Are Available In SQL Server 2000 / 2006-06-01" }
			"8.0.1014" { "FIX: You Receive An Error Message When You Try To Delete Records By Running A Delete Transact-SQL Statement In SQL Server 2000 / 2006-07-25" }
			"8.0.1013" { "FIX: The Query Runs Slower Than You Expected When You Try To Parse A Query In SQL Server 2000 / 2006-06-01" }
			"8.0.1009" { "FIX: You Receive An 'Incorrect Syntax Near ')'' Error Message When You Run A Script That Was Generated By SQL-DMO For An Operator Object In SQL Server 2000 / 2006-06-01" }
			"8.0.1007" { "FIX: You May Receive A 'SQL Server Could Not Spawn Process_Loginread Thread' Error Message, And A Memory Leak May Occur When You Cancel A Remote Query In SQL Server 2000 / 2006-06-01" }
			"8.0.1003" { "FIX: Differential Database Backups May Not Contain Database Changes In The Page Free Space (PFS) Pages In SQL Server 2000 / 2006-06-01" }
			"8.0.1001" { "FIX: You May Receive A 17883 Error Message When SQL Server 2000 Performs A Very Large Hash Operation / 2006-06-01" }
			"8.0.1000" { "FIX: Database Recovery Does Not Occur, Or A User Database Is Marked As Suspect In SQL Server 2000 / 2006-06-01" }
			"8.0.997" { "FIX: You Cannot Create New TCP/IP Socket Based Connections After Error Messages 17882 And 10055 Are Written To The Microsoft SQL Server 2000 Error Log / 2006-07-18" }
			"8.0.996" { "FIX: SQL Server 2000 May Stop Responding To Other Requests When You Perform A Large Deallocation Operation / 2006-06-01" }
			"8.0.996" { "FIX: You Receive A 17883 Error Message And SQL Server 2000 May Stop Responding To Other Requests When You Perform Large In-Memory Sort Operations / 2006-06-01" }
			"8.0.994" { "FIX: Some Complex Queries Are Slower After You Install SQL Server 2000 Service Pack 2 Or SQL Server 2000 Service Pack 3 / 2006-06-01" }
			"8.0.994" { "FIX: You Experience Non-Convergence In A Replication Topology When You Unpublish Or Drop Columns From A Dynamically Filtered Publication In SQL Server 2000 / 2006-06-01" }
			"8.0.994" { "FIX: You Receive A 'Server: Msg 107, Level 16, State 3, Procedure TEMP_VIEW_Merge, Line 1' Error Message When The Sum Of The Length Of The Published Column Names In A Merge Publication Exceeds 4,000 Characters In SQL Server 2000 / 2006-06-01" }
			"8.0.993" { "FIX: The @@ERROR System Function May Return An Incorrect Value When You Execute A Transact-SQL Statement That Uses A Parallel Execution Plan In SQL Server 2000 32-Bit Or In SQL Server 2000 64-Bit / 2006-06-01" }
			"8.0.993" { "FIX: You Receive A 17883 Error In SQL Server 2000 Service Pack 3 Or In SQL Server 2000 Service Pack 3A When A Worker Thread Becomes Stuck In A Registry Call / 2006-06-01" }
			"8.0.993" { "FIX: Error Message When You Use A Loopback Linked Server To Run A Distributed Query In SQL Server 2000: 'Could Not Perform The Requested Operation Because The Minimum Query Memory Is Not Available' / 2006-05-15" }
			"8.0.991" { "FIX: Non-Convergence May Occur In A Merge Replication Topology If The Primary Connection To The Publisher Is Disconnected / 2006-06-01" }
			"8.0.990" { "FIX: SQL Server 2000 Stops Listening For New TCP/IP Socket Connections Unexpectedly After Error Message 17882 Is Written To The SQL Server 2000 Error Log / 2006-06-01" }
			"8.0.988" { "FIX: You Receive A 'Msg 3628' Error Message When You Run An Inner Join Query In SQL Server 2000 / 2006-06-01" }
			"8.0.985" { "FIX: Start Times In The SQL Profiler Are Different For The Audit:Login And Audit:Logout Events In SQL Server 2000 / 2006-06-01" }
			"8.0.980" { "FIX: A Fetch On A Dynamic Cursor Can Cause Unexpected Results In SQL Server 2000 Service Pack 3 / 2006-06-01" }
			"8.0.977" { "You Receive A 'The Product Does Not Have A Prerequisite Update Installed' Error Message When You Try To Install A SQL Server 2000 Post-Service Pack 3 Hotfix / 2005-08-31" }
			"8.0.973" { "FIX: A SPID Stops Responding With A NETWORKIO (0X800) Waittype In SQL Server Enterprise Manager When SQL Server Tries To Process A Fragmented TDS Network Packet / 2006-06-01" }
			"8.0.972" { "FIX: An Assertion Error Occurs When You Insert Data In The Same Row In A Table By Using Multiple Connections To An Instance Of SQL Server / 2006-06-01" }
			"8.0.970" { "FIX: A CHECKDB Statement Reports A 2537 Corruption Error After SQL Server Transfers Data To A Sql_Variant Column In SQL Server 2000 / 2006-06-01" }
			"8.0.967" { "FIX: You May Receive An Error Message When You Run A SET IDENTITY_INSERT ON Statement On A Table And Then Try To Insert A Row Into The Table In SQL Server 2000 / 2006-06-01" }
			"8.0.962" { "FIX: A User-Defined Function Returns Results That Are Not Correct For A Query / 2006-06-01" }
			"8.0.961" { "FIX: An Access Violation Exception May Occur When Multiple Users Try To Perform Data Modification Operations At The Same Time That Fire Triggers That Reference A Deleted Or An Inserted Table In SQL Server 2000 On A Computer That Is Running SMP / 2006-06-01" }
			"8.0.959" { "FIX: An Audit Object Permission Event Is Not Produced When You Run A TRUNCATE TABLE Statement / 2006-06-01" }
			"8.0.957" { "FIX: An Access Violation Exception May Occur When You Run A Query That Uses Index Names In The WITH INDEX Option To Specify An Index Hint / 2006-06-01" }
			"8.0.955" { "FIX: The @Date_Received Parameter Of The Xp_Readmail Extended Stored Procedure Incorrectly Returns The Date And The Time That An E-Mail Message Is Submitted By The Sender In SQL Server 2000 / 2007-01-08" }
			"8.0.954" { "FIX: The Osql.Exe Utility Does Not Run A Transact-SQL Script Completely If You Start The Program From A Remote Session By Using A Background Service And Then Log Off The Console Session / 2007-01-05" }
			"8.0.952" { "FIX: The Log Reader Agent May Cause 17883 Error Messages / 2006-06-01" }
			"8.0.952" { "FIX: Merge Replication Non-Convergence Occurs With SQL Server CE Subscribers / 2006-06-01" }
			"8.0.952" { "FIX: Merge Agent May Fail With An 'Invalid Character Value For Cast Specification' Error Message / 2006-06-01" }
			"8.0.949" { "FIX: Shared Page Locks Can Be Held Until End Of The Transaction And Can Cause Blocking Or Performance Problems In SQL Server 2000 Service Pack 3 (SP3) / 2006-06-02" }
			"8.0.948" { "FIX: You May Receive An 8623 Error Message When You Try To Run A Complex Query On An Instance Of SQL Server / 2006-06-01" }
			"8.0.944" { "FIX: SQL Debugging Does Not Work In Visual Studio .NET After You Install Windows XP Service Pack 2 / 2006-06-05" }
			"8.0.937" { "FIX: Additional Diagnostics Have Been Added To SQL Server 2000 To Detect Unreported Read Operation Failures / 2006-06-01" }
			"8.0.936" { "FIX: SQL Server 2000 May Underestimate The Cardinality Of A Query Expression Under Certain Circumstances / 2006-06-01" }
			"8.0.935" { "FIX: You May Notice Incorrect Values For The 'Active Transactions' Counter When You Perform Multiple Transactions On An Instance Of SQL Server 2000 That Is Running On An SMP Computer / 2006-06-01" }
			"8.0.934" { "FIX: You May Receive A 'The Query Processor Could Not Produce A Query Plan' Error Message In SQL Server When You Run A Query That Includes Multiple Subqueries That Use Self-Joins / 2006-06-01" }
			"8.0.933" { "FIX: The Mssqlserver Service Exits Unexpectedly In SQL Server 2000 Service Pack 3 / 2006-06-02" }
			"8.0.929" { "FIX: 8621 Error Conditions May Cause SQL Server 2000 64-Bit To Close Unexpectedly / 2006-06-01" }
			"8.0.928" { "FIX: The Thread Priority Is Raised For Some Threads In A Parallel Query / " }
			"8.0.927" { "FIX: Profiler RPC Events Truncate Parameters That Have A Text Data Type To 16 Characters / 2006-06-01" }
			"8.0.926" { "FIX: An Access Violation Exception May Occur When You Update A Text Column By Using A Stored Procedure In SQL Server 2000 / 2006-06-01" }
			"8.0.923" { "FIX: The Xp_Logininfo Procedure May Fail With Error 8198 After You Install Q825042 Or Any Hotfix With SQL Server 8.0.0840 Or Later / 2006-06-01" }
			"8.0.922" { "FIX: You May Receive An 'Invalid Object Name...' Error Message When You Run The DBCC CHECKCONSTRAINTS Transact-SQL Statement On A Table In SQL Server 2000 / 2005-10-25" }
			"8.0.919" { "FIX: When You Use Transact-SQL Cursor Variables To Perform Operations That Have Large Iterations, Memory Leaks May Occur In SQL Server 2000 / 2005-10-25" }
			"8.0.916" { "FIX: Sqlakw32.Dll May Corrupt SQL Statements / 2005-09-27" }
			"8.0.915" { "FIX: Rows Are Not Successfully Inserted Into A Table When You Use The BULK INSERT Command To Insert Rows / 2005-10-25" }
			"8.0.913" { "FIX: You Receive Query Results That Were Not Expected When You Use Both ANSI Joins And Non-ANSI Joins / 2006-06-07" }
			"8.0.911" { "FIX: When You Use Transact-SQL Cursor Variables To Perform Operations That Have Large Iterations, Memory Leaks May Occur In SQL Server 2000 / 2005-10-25" }
			"8.0.910" { "FIX: SQL Server 2000 May Not Start If Many Users Try To Log In To SQL Server When SQL Server Is Trying To Start / 2005-10-25" }
			"8.0.908" { "FIX: You Receive A 644 Error Message When You Run An UPDATE Statement And The Isolation Level Is Set To READ UNCOMMITTED / 2005-10-25" }
			"8.0.904" { "FIX: The Snapshot Agent May Fail After You Make Schema Changes To The Underlying Tables Of A Publication / 2005-04-22" }
			"8.0.892" { "FIX: You Receive An Error Message When You Try To Restore A Database Backup That Spans Multiple Devices / 2005-10-25" }
			"8.0.891" { "FIX: An Access Violation Exception May Occur When SQL Server Runs Many Parallel Query Processing Operations On A Multiprocessor Computer / 2005-04-01" }
			"8.0.879" { "FIX: The DBCC PSS Command May Cause Access Violations And 17805 Errors In SQL Server 2000 / 2005-10-25" }
			"8.0.878" { "FIX: You Receive Error Message 3456 When You Try To Apply A Transaction Log To A Server / 2005-10-25" }
			"8.0.876" { "FIX: Key Names Read From An .Ini File For A Dynamic Properties Task May Be Truncated / 2005-10-25" }
			"8.0.876" { "FIX: An Invalid Cursor State Occurs After You Apply Hotfix 8.00.0859 Or Later In SQL Server 2000 / 2005-10-25" }
			"8.0.876" { "FIX: An AWE System Uses More Memory For Sorting Or For Hashing Than A Non-AWE System In SQL Server 2000 / 2005-10-25" }
			"8.0.873" { "FIX: Some Queries That Have A Left Outer Join And An IS NULL Filter Run Slower After You Install SQL Server 2000 Post-SP3 Hotfix / 2005-10-25" }
			"8.0.871" { "FIX: SQL Query Analyzer May Stop Responding When You Close A Query Window Or Open A File / 2005-10-25" }
			"8.0.871" { "FIX: The Performance Of A Computer That Is Running SQL Server 2000 Degrades When Query Execution Plans Against Temporary Tables Remain In The Procedure Cache / 2005-10-25" }
			"8.0.870" { "FIX: Unconditional Update May Not Hold Key Locks On New Key Values / 2005-10-25" }
			"8.0.869" { "FIX: Access Violation When You Trace Keyset-Driven Cursors By Using SQL Profiler / 2005-10-25" }
			"8.0.866" { "FIX: An Access Violation Occurs In SQL Server 2000 When A High Volume Of Local Shared Memory Connections Occur After You Install Security Update MS03-031 / 2006-01-16" }
			"8.0.865" { "FIX: An Access Violation Occurs During Compilation If The Table Contains Statistics For A Computed Column / 2005-10-25" }
			"8.0.865" { "FIX: You Cannot Insert Explicit Values In An IDENTITY Column Of A SQL Server Table By Using The Sqlbulkoperations Function Or The Sqlsetpos ODBC Function In SQL Server 2000 / 2005-10-25" }
			"8.0.863" { "FIX: Query Performance May Be Slow And May Be Inconsistent When You Run A Query While Another Query That Contains An IN Operator With Many Values Is Compiled / 2005-10-25" }
			"8.0.863" { "FIX: A Floating Point Exception Occurs During The Optimization Of A Query / 2005-10-25" }
			"8.0.859" { "FIX: Issues That Are Resolved In SQL Server 2000 Build 8.00.0859 / 2005-03-31" }
			"8.0.858" { "FIX: Users Can Control The Compensating Change Process In Merge Replication / 2005-10-25" }
			"8.0.857" { "The Knowledge Base (KB) Article You Requested Is Currently Not Available / " }
			"8.0.857" { "FIX: A Query May Fail With Retail Assertion When You Use The NOLOCK Hint Or The READ UNCOMMITTED Isolation Level / 2005-11-23" }
			"8.0.857" { "FIX: An Internet Explorer Script Error Occurs When You Access Metadata Information By Using DTS In SQL Server Enterprise Manager / 2005-10-25" }
			"8.0.856" { "FIX: Key Locks Are Held Until The End Of The Statement For Rows That Do Not Pass Filter Criteria / 2005-10-25" }
			"8.0.854" { "FIX: An Access Violation Occurs When You Run DBCC UPDATEUSAGE On A Database That Has Many Objects / 2005-10-25" }
			"8.0.852" { "FIX: You May Receive An 'Internal SQL Server Error' Error Message When You Run A Transact-SQL SELECT Statement On A View That Has Many Subqueries In SQL Server 2000 / 2005-04-01" }
			"8.0.852" { "FIX: Slow Execution Times May Occur When You Run DML Statements Against Tables That Have Cascading Referential Integrity / 2005-10-25" }
			"8.0.851" { "FIX: A Deadlock Occurs If You Run An Explicit UPDATE STATISTICS Command / 2005-10-25" }
			"8.0.850" { "FIX: Linked Server Query May Return NULL If It Is Performed Through A Keyset Cursor / 2005-10-25" }
			"8.0.850" { "FIX: You Receive An 8623 Error Message In SQL Server When You Try To Run A Query That Has Multiple Correlated Subqueries / 2005-10-25" }
			"8.0.850" { "FIX: A Query That Uses A View That Contains A Correlated Subquery And An Aggregate Runs Slowly / 2005-10-25" }
			"8.0.848" { "FIX: A Member Of The Db_Accessadmin Fixed Database Role Can Create An Alias For The Dbo Special User / 2005-10-25" }
			"8.0.847" { "PRB: Additional SQL Server Diagnostics Added To Detect Unreported I/O Problems / 2005-10-25" }
			"8.0.845" { "FIX: A Query With A LIKE Comparison Results In A Non-Optimal Query Plan When You Use A Hungarian SQL Server Collation / 2005-10-05" }
			"8.0.845" { "FIX: No Exclusive Locks May Be Taken If The Disallowspagelocks Value Is Set To True / 2005-10-25" }
			"8.0.844" { "FIX: SQL Server 2000 Protocol Encryption Applies To JDBC Clients / 2006-10-17" }
			"8.0.842" { "FIX: Rows Are Unexpectedly Deleted When You Run A Distributed Query To Delete Or To Update A Linked Server Table / 2005-10-25" }
			"8.0.841" { "FIX: You Receive An Error Message When You Run A Parallel Query That Uses An Aggregation Function Or The GROUP BY Clause / " }
			"8.0.840" { "FIX: Extremely Large Number Of User Tables On AWE System May Cause Bpool::Map Errors / " }
			"8.0.840" { "FIX: Extremely Large Number Of User Tables On AWE System May Cause Bpool::Map Errors / 2005-09-27" }
			"8.0.839" { "FIX: An Access Violation May Occur When You Run A Query That Contains 32,000 Or More OR Clauses / " }
			"8.0.839" { "FIX: A Cursor With A Large Object Parameter May Cause An Access Violation On Cstmtcond::Xretexecute / 2005-10-25" }
			"8.0.837" { "FIX: Delayed Domain Authentication May Cause SQL Server To Stop Responding / 2005-10-25" }
			"8.0.837" { "FIX: Lock Monitor Exception In Deadlockmonitor::Resolvedeadlock / 2005-10-25" }
			"8.0.837" { "FIX: A Parallel Query May Generate An Access Violation After You Install SQL Server 2000 SP3 / 2005-10-25" }
			"8.0.837" { "FIX: MS DTC Transaction Commit Operation Blocks Itself / 2005-10-25" }
			"8.0.837" { "FIX: Build 8.0.0837: A Query That Contains A Correlated Subquery Runs Slowly / " }
			"8.0.819" { "FIX: You Are Prompted For Password Confirmation After You Change A Standard SQL Server Login / 2005-10-25" }
			"8.0.818" { "MS03-031: Security Patch For SQL Server 2000 Service Pack 3 / 2006-01-09" }
			"8.0.818" { "FIX: Localized Versions Of SQL Mail And The Web Assistant Wizard May Not Work As Expected In SQL Server 2000 64 Bit / 2005-03-16" }
			"8.0.818" { "FIX: A Transact-SQL Statement That Is Embedded In The Database Name Runs With System Administrator Permissions / 2005-02-10" }
			"8.0.818" { "FIX: You Are Prompted For Password Confirmation After You Change A Standard SQL Server Login / 2005-10-25" }
			"8.0.818" { "MS03-031: Security Patch For SQL Server 2000 64-Bit / 2006-03-14" }
			"8.0.816" { "FIX: Intense SQL Server Activity Results In Spinloop Wait / " }
			"8.0.814" { "FIX: Distribution Cleanup Agent Incorrectly Cleans Up Entries For Anonymous Subscribers / 2005-10-25" }
			"8.0.811" { "FIX: An Access Violation Exception May Occur When You Insert A Row In A Table That Is Referenced By Indexed Views In SQL Server 2000 / 2006-04-03" }
			"8.0.811" { "FIX: Distribution Cleanup Agent Incorrectly Cleans Up Entries For Anonymous Subscribers / " }
			"8.0.811" { "FIX: Invalid TDS Sent To SQL Server Results In Access Violation / 2005-10-25" }
			"8.0.807" { "FIX: Error Message 3628 May Occur When You Run A Complex Query / " }
			"8.0.804" { "FIX: Internal Query Processor Error 8623 When Microsoft SQL Server Tries To Compile A Plan For A Complex Query / 2005-10-25" }
			"8.0.801" { "FIX: SQL Server Enterprise Manager Unexpectedly Quits When You Modify A DTS Package / " }
			"8.0.800" { "FIX: The Sqldumper.Exe File Does Not Generate A Userdump File When It Runs Against A Windows Service / 2005-09-27" }
			"8.0.800" { "FIX: An Access Violation May Occur When You Run DBCC DBREINDEX On A Table That Has Hypothetical Indexes / 2005-09-27" }
			"8.0.800" { "FIX: Query On The Sysmembers Virtual Table May Fail With A Stack Overflow / 2005-09-27" }
			"8.0.798" { "FIX: Using Sp_Executesql In Merge Agent Operations / 2005-09-27" }
			"8.0.794" { "FIX: Using Sp_Executesql In Merge Agent Operations / 2005-09-27" }
			"8.0.794" { "FIX: OLE DB Conversion Errors May Occur After You Select A Literal String That Represents Datetime Data As A Column / 2005-09-27" }
			"8.0.794" { "FIX: Error 8623 Is Raised When SQL Server Compiles A Complex Query / 2005-09-27" }
			"8.0.794" { "FIX: SQL Server 2000 Might Produce An Incorrect Cardinality Estimate For Outer Joins / 2005-02-11" }
			"8.0.791" { "FIX: Performance Of A Query That Is Run From A Client Program On A SQL Server SP3 Database Is Slow After You Restart The Instance Of SQL Server / 2005-09-27" }
			"8.0.790" { "FIX: You Receive An Error Message When You Use The SQL-DMO Bulkcopy Object To Import Data Into A SQL Server Table / 2005-09-27" }
			"8.0.789" { "FIX: Error 17883 May Display Message Text That Is Not Correct / 2005-09-27" }
			"8.0.788" { "FIX: You Cannot Install SQL Server 2000 SP3 On The Korean Version Of SQL Server 2000 / 2005-09-27" }
			"8.0.781" { "FIX: SQL Server 2000 Uninstall Option Does Not Remove All Files / 2005-09-27" }
			"8.0.780" { "FIX: Code Point Comparison Semantics For SQL_Latin1_General_Cp850_BIN Collation / 2005-09-27" }
			"8.0.780" { "FIX: Sysindexes.Statblob Column May Be Corrupted After You Run A DBCC DBREINDEX Statement / 2005-09-27" }
			"8.0.780" { "SQL Server 2000 Hotfix Update For SQL Server 2000 Service Pack 3 And 3A / 2006-10-10" }
			"8.0.779" { "FIX: A Full-Text Population Fails After You Apply SQL Server 2000 Service Pack 3 / 2005-09-27" }
			"8.0.776" { "Unidentified / " }
			"8.0.775" { "FIX: A DTS Package That Uses Global Variables Ignores An Error Message Raised By RAISERROR / 2005-09-27" }
			"8.0.769" { "FIX: A DELETE Statement With A JOIN Might Fail And You Receive A 625 Error / 2005-09-27" }
			"8.0.769" { "FIX: Error Message: 'Insufficient Key Column Information For Updating' Occurs In SQL Server 2000 SP3 / 2005-09-27" }
			"8.0.765" { "FIX: An Access Violation Occurs If An Sp_Cursoropen Call References A Parameter That Is Not Defined / 2005-09-27" }
			"8.0.765" { "FIX: Merge Agent Can Resend Changes For Filtered Publications / 2005-09-27" }
			"8.0.765" { "FIX: Reinitialized SQL Server CE 2.0 Subscribers May Experience Data Loss And Non-Convergence / 2005-09-27" }
			"8.0.765" { "FIX: You May Experience Slow Performance When You Debug A SQL Server Service / 2005-09-27" }
			"8.0.763" { "FIX: DTS Designer May Generate An Access Violation After You Install SQL Server 2000 Service Pack 3 / 2005-09-27" }
			"8.0.762" { "FIX: Merge Publications Cannot Synchronize On SQL Server 2000 Service Pack 3 / 2005-09-27" }
			"8.0.760" { "SQL Server 2000 Service Pack 3 (SP3 / Sp3a) / 2003-08-27" }
			"8.0.743" { "FIX: A Transact-SQL Query That Uses Views May Fail Unexpectedly In SQL Server 2000 SP2 / 2005-10-18" }
			"8.0.743" { "FIX: Intense SQL Server Activity Results In Spinloop Wait In SQL Server 2000 Service Pack 2 / 2005-10-25" }
			"8.0.741" { "FIX: Many Extent Lock Time-Outs May Occur During Extent Allocation / 2005-02-10" }
			"8.0.736" { "FIX: A Memory Leak May Occur When You Use The Sp_Oamethod Stored Procedure To Call A Method Of A COM Object / 2005-09-27" }
			"8.0.735" { "FIX: A DELETE Statement With A JOIN Might Fail And You Receive A 625 Error / 2005-09-27" }
			"8.0.733" { "FIX: A Large Number Of NULL Values In Join Columns Result In Slow Query Performance / 2005-09-27" }
			"8.0.730" { "FIX: You May Experience Slow Performance When You Debug A SQL Server Service / 2005-09-27" }
			"8.0.728" { "FIX: Merge Replication With Alternate Synchronization Partners May Not Succeed After You Change The Retention Period / 2005-09-27" }
			"8.0.725" { "FIX: A Query With An Aggregate Function May Fail With A 3628 Error / 2005-09-27" }
			"8.0.725" { "FIX: Distribution Agent Fails With 'Violation Of Primary Key Constraint' Error Message / 2005-09-27" }
			"8.0.723" { "FIX: A UNION ALL View May Not Use Index If Partitions Are Removed At Compile Time / 2005-09-27" }
			"8.0.721" { "FIX: Indexed View May Cause A Handled Access Violation In Cindex::Setlevel1names / 2005-09-27" }
			"8.0.721" { "FIX: Update Or Delete Statement Fails With Error 1203 During Row Lock Escalation / 2005-09-27" }
			"8.0.718" { "FIX: Unexpected Results From Partial Aggregations Based On Conversions / 2005-09-27" }
			"8.0.715" { "FIX: Merge Agent Can Resend Changes For Filtered Publications / 2005-09-27" }
			"8.0.715" { "FIX: Reinitialized SQL Server CE 2.0 Subscribers May Experience Data Loss And Non-Convergence / 2005-09-27" }
			"8.0.714" { "FIX: Restoring A SQL Server 7.0 Database Backup In SQL Server 2000 Service Pack 2 (SP2) May Cause An Assertion Error In The Xdes.Cpp File / 2005-10-18" }
			"8.0.713" { "FIX: An Error Message Occurs When You Perform A Database Or A File SHRINK Operation / 2005-09-27" }
			"8.0.710" { "FIX: Latch Time-Out Message 845 Occurs When You Perform A Database Or File SHRINK Operation / 2005-09-27" }
			"8.0.705" { "FIX: The JOIN Queries In The Triggers That Involve The Inserted Table Or The Deleted Table May Return Results That Are Not Consistent / 2005-09-27" }
			"8.0.703" { "FIX: Cursors That Have A Long Lifetime May Cause Memory Fragmentation / 2005-09-27" }
			"8.0.702" { "FIX: Concurrency Enhancements For The Tempdb Database / 2006-07-19" }
			"8.0.701" { "FIX: A DELETE Statement With A Self-Join May Fail And You Receive A 625 Error / 2005-09-27" }
			"8.0.701" { "FIX: An Access Violation Occurs If An Sp_Cursoropen Call References A Parameter That Is Not Defined / 2005-09-27" }
			"8.0.700" { "FIX: Merge Replication Reconciler Stack Overflow / 2005-09-27" }
			"8.0.696" { "FIX: A Memory Leak Occurs When Cursors Are Opened During A Connection / 2005-09-27" }
			"8.0.696" { "FIX: The Fn_Get_Sql System Table Function May Cause Various Handled Access Violations / 2005-09-27" }
			"8.0.695" { "FIX: Update/Delete Statement Fails With Error 1203 During Page Lock Escalation / 2005-09-27" }
			"8.0.695" { "FIX: The Xp_Readmail Extended Stored Procedure Overwrites Attachment That Already Exists / 2005-02-10" }
			"8.0.695" { "FIX: The Xp_Readmail And Xp_Findnextmsg Extended Stored Procedures Do Not Read Mail In Time Received Order / 2005-02-10" }
			"8.0.693" { "FIX: Parallel Logical Operation Returns Results That Are Not Consistent / 2005-09-27" }
			"8.0.690" { "FIX: The SELECT Statement With Parallelism Enabled May Cause An Assertion / 2005-10-12" }
			"8.0.689" { "FIX: Replication Removed From Database After Restore WITH RECOVERY / 2005-10-11" }
			"8.0.688" { "FIX: Transaction Log Restore Fails With Message 3456 / 2005-10-11" }
			"8.0.686" { "SQL Server 2000 Security Update For Service Pack 2 / 2006-11-24" }
			"8.0.682" { "FIX: Assertion And Error Message 3314 Occurs If You Try To Roll Back A Text Operation With READ UNCOMMITTED / 2005-10-18" }
			"8.0.679" { "SQL Server 2000 Security Update For Service Pack 2 / 2006-11-24" }
			"8.0.678" { "FIX: A RESTORE DATABASE WITH RECOVERY Statement Can Fail With Error 9003 Or Error 9004 / 2005-09-27" }
			"8.0.667" { "2000 SP2+8/14 Fix / " }
			"8.0.665" { "2000 SP2+8/8 Fix / " }
			"8.0.661" { "FIX: Lock Escalation On A Scan While An Update Query Is Running Causes A 1203 Error Message To Occur / 2005-09-27" }
			"8.0.655" { "2000 SP2+7/24 Fix / " }
			"8.0.652" { "FIX: The Fn_Get_Sql System Table Function May Cause Various Handled Access Violations / 2005-09-27" }
			"8.0.650" { "FIX: SQL Server Grants Unnecessary Permissions Or An Encryption Function Contains Unchecked Buffers / 2003-11-05" }
			"8.0.644" { "FIX: Slow Compile Time And Execution Time With Query That Contains Aggregates And Subqueries / 2005-09-27" }
			"8.0.636" { "Microsoft Security Bulletin MS02-039 / 2002-06-24" }
			"8.0.608" { "FIX: SQL Extended Procedure Functions Contain Unchecked Buffers / 2004-06-21" }
			"8.0.604" { "2000 SP2+3/29 Fix / " }
			"8.0.599" { "FIX: Improved SQL Manager Robustness For Odd Length Buffer / 2005-09-27" }
			"8.0.594" { "FIX: Extremely Large Number Of User Tables On AWE System May Cause Bpool::Map Errors / 2005-09-27" }
			"8.0.584" { "FIX: Reorder Outer Joins With Filter Criteria Before Non-Selective Joins And Outer Joins / 2008-02-04" }
			"8.0.578" { "FIX: Unchecked Buffer May Occur When You Connect To Remote Data Source / 2005-09-27" }
			"8.0.578" { "FIX: SELECT With Timestamp Column That Uses FOR XML AUTO May Fail With Stack Overflow Or AV / 2005-09-27" }
			"8.0.568" { "317748 FIX: Handle Leak Occurs In SQL Server When Service Or Application Repeatedly Connects And Disconnects With Shared Memory Network Library / 2002-10-30" }
			"8.0.561" { "2000 SP2+1/29 Fix / " }
			"8.0.558" { "FIX: Query That Uses DESC Index May Result In Access Violation / 2005-09-26" }
			"8.0.558" { "FIX: COM May Not Be Uninitialized For Worker Thread When You Use Sp_OA / 2005-09-27" }
			"8.0.552" { "The Knowledge Base (KB) Article You Requested Is Currently Not Available / " }
			"8.0.552" { "FIX: SELECT From Computed Column That References UDF Causes SQL Server To Terminate / 2005-09-26" }
			"8.0.534" { "2000 SP2.01 / " }
			"8.0.532" { "SQL Server 2000 Service Pack 2 (SP2) / 2003-02-04" }
			"8.0.475" { "2000 SP1+1/29 Fix / " }
			"8.0.474" { "FIX: COM May Not Be Uninitialized For Worker Thread When You Use Sp_OA / 2005-09-27" }
			"8.0.473" { "FIX: Query That Uses DESC Index May Result In Access Violation / 2005-09-26" }
			"8.0.471" { "FIX: Shared Table Lock Is Not Released After Lock Escalation / 2005-09-26" }
			"8.0.469" { "FIX: SELECT From Computed Column That References UDF Causes SQL Server To Terminate / 2005-09-26" }
			"8.0.452" { "FIX: SELECT DISTINCT From Table With LEFT JOIN Of View Causes Error Messages Or Client Application May Stop Responding / 2005-09-26" }
			"8.0.444" { "FIX: Sqlputdata May Result In Leak Of Buffer Pool Memory / 2005-09-26" }
			"8.0.444" { "FIX: Querying Syslockinfo With Large Numbers Of Locks May Cause Server To Stop Responding / 2005-10-07" }
			"8.0.443" { "FIX: Sqltrace Start And Stop Is Now Reported In Windows NT Event Log For SQL Server 2000 / 2005-09-26" }
			"8.0.428" { "FIX: SQL Server Text Formatting Functions Contain Unchecked Buffers / 2004-08-05" }
			"8.0.384" { "SQL Server 2000 Service Pack 1 (SP1) / 2001-06-11" }
			"8.0.296" { "FIX: Query Method Used To Access Data May Allow Rights That The Login Might Not Normally Have / 2004-08-09" }
			"8.0.287" { "FIX: Deletes, Updates And Rank Based Selects May Cause Deadlock Of MSSEARCH / 2005-10-07" }
			"8.0.251" { "FIX: Error 644 Using Two Indexes On A Column With Uppercase Preference Sort Order / 2003-10-17" }
			"8.0.250" { "The Knowledge Base (KB) Article You Requested Is Currently Not Available / " }
			"8.0.249" { "FIX: Lock Monitor Uses Excessive CPU / 2003-09-12" }
			"8.0.239" { "FIX: Complex ANSI Join Query With Distributed Queries May Cause Handled Access Violation / 2003-10-09" }
			"8.0.233" { "FIX: Opening The Database Folder In SQL Server Enterprise Manager 2000 Takes A Long Time / 2003-10-09" }
			"8.0.231" { "FIX: Execution Of Sp_Oacreate On COM Object Without Type Information Causes Server Shut Down / 2003-10-09" }
			"8.0.226" { "FIX: Extreme Memory Usage When Adding Many Security Roles / 2006-11-21" }
			"8.0.225" { "Access Denied Error Message When You Try To Use A Network Drive To Modify Windows 2000 Permissions / 2006-10-30" }
			"8.0.223" { "FIX: Buffer Overflow Exploit Possible With Extended Stored Procedures / 2004-06-29" }
			"8.0.222" { "FIX: Exception Access Violation Encountered During Query Normalization / 2005-10-07" }
			"8.0.218" { "FIX: Scripting Object With Several Extended Properties May Cause Exception / 2003-10-09" }
			"8.0.217" { "FIX: CASE Using LIKE With Empty String Can Result In Access Violation Or Abnormal Server Shutdown / 2003-10-09" }
			"8.0.211" { "FIX: Complex Distinct Or Group By Query Can Return Unexpected Results With Parallel Execution Plan / 2003-11-05" }
			"8.0.210" { "FIX: Linked Server Query With Hyphen In LIKE Clause May Run Slowly / 2003-10-09" }
			"8.0.205" { "FIX: Sending Open Files As Attachment In SQL Mail Fails With Error 18025 / 2005-10-07" }
			"8.0.204" { "FIX: Optimizer Slow To Generate Query Plan For Complex Queries That Have Many Joins And Semi-Joins / 2003-10-09" }
			"8.0.194" { "SQL Server 2000 RTM (No SP) / 2000-11-30" }
			"8.0.190" { "SQL Server 2000 Gold / " }
			"8.0.100" { "SQL Server 2000 Beta 2 / " }
			"8.0.078" { "SQL Server 2000 EAP5 / " }
			"8.0.047" { "SQL Server 2000 EAP4 / " }
			"7.0.1152" { "MS08-040: Description Of The Security Update For SQL Server 7.0: July 8, 2008 / 2012-05-09" }
			"7.0.1149" { "FIX: An Access Violation Exception May Occur When You Run A SELECT Statement That Contains Complex JOIN Operations In SQL Server 7.0 / 2006-06-01" }
			"7.0.1143" { "New Connection Events Are Not Recorded In SQL Server Traces / 2005-10-25" }
			"7.0.1143" { "FIX: An Attention Signal That Is Sent From A SQL Server Client Application Because Of A Query Time-Out May Cause The SQL Server Service To Quit Unexpectedly / 2005-10-25" }
			"7.0.1097" { "A Complex UPDATE Statement That Uses An Index Spool Operation May Cause An Assertion / 2005-10-25" }
			"7.0.1094" { "MS03-031: Security Patch For SQL Server 7.0 Service Pack 4 / 2006-05-11" }
			"7.0.1094" { "MS03-031: Cumulative Security Patch For SQL Server / 2006-05-10" }
			"7.0.1092" { "FIX: Delayed Domain Authentication May Cause SQL Server To Stop Responding / 2005-10-25" }
			"7.0.1087" { "FIX: SQL Server 7.0 Scheduler May Periodically Stop Responding During Large Sort Operation / 2005-09-27" }
			"7.0.1079" { "FIX: Replication Removed From Database After Restore WITH RECOVERY / 2005-10-11" }
			"7.0.1078" { "INF: SQL Server 7.0 Security Update For Service Pack 4 / 2005-09-27" }
			"7.0.1077" { "SQL Server 2000 Security Update For Service Pack 2 / 2006-11-24" }
			"7.0.1063" { "SQL Server 7.0 Service Pack 4 (SP4) / 2002-04-26" }
			"7.0.1033" { "FIX: Error Message 9004 May Occur When You Restore A Log That Does Not Contain Any Transactions / 2005-10-12" }
			"7.0.1026" { "FIX: Assertion And Error Message 3314 Occurs If You Try To Roll Back A Text Operation With READ UNCOMMITTED / 2005-10-18" }
			"7.0.1004" { "FIX: SQL Server Text Formatting Functions Contain Unchecked Buffers / 2004-08-05" }
			"7.0.996" { "FIX: Query Method Used To Access Data May Allow Rights That The Login Might Not Normally Have / 2004-08-09" }
			"7.0.978" { "FIX: Update With Self Join May Update Incorrect Number Of Rows / 2003-10-28" }
			"7.0.977" { "FIX: SQL Server Profiler And SQL Server Agent Alerts May Fail To Work After Installing SQL Server 7.0 SP3 / 2002-04-25" }
			"7.0.970" { "FIX: SQL Server May Generate Nested Query For Linked Server When Option Is Disabled / 2002-10-15" }
			"7.0.970" { "FIX: Incorrect Results With Join Of Column Converted To Binary / 2003-10-29" }
			"7.0.961" { "SQL Server 7.0 Service Pack 3 (SP3) / 2000-12-15" }
			"7.0.921" { "FIX: SQL Server May Generate Nested Query For Linked Server When Option Is Disabled / 2002-10-15" }
			"7.0.919" { "FIX: Incorrect Results With Join Of Column Converted To Binary / 2003-10-29" }
			"7.0.918" { "FIX: Buffer Overflow Exploit Possible With Extended Stored Procedures / 2004-06-29" }
			"7.0.917" { "FIX: Bcp.Exe With Long Query String Can Result In Assertion Failure / 2005-09-26" }
			"7.0.910" { "FIX: SQL RPC That Raises Error Will Mask @@ERROR With Msg 7221 / 2003-10-31" }
			"7.0.905" { "FIX: Data Modification Query With A Distinct Subquery On A View May Cause Error 3624 / 2004-07-15" }
			"7.0.889" { "FIX: Replication Initialize Method Causes Handle Leak On Failure / 2005-10-05" }
			"7.0.879" { "FIX: Linked Index Server Query Through OLE DB Provider With OR Clause Reports Error 7349 / 2006-03-14" }
			"7.0.857" { "FIX: Transactional Publications With A Filter On Numeric Columns Fail To Replicate Data / 2006-03-14" }
			"7.0.843" { "FIX: Temporary Stored Procedures In SA Owned Databases May Bypass Permission Checks When You Run Stored Procedures / 2006-03-14" }
			"7.0.842" { "SQL Server 7.0 Service Pack 2 (SP2) / 2000-03-20" }
			"7.0.839" { "SQL Server 7.0 Service Pack 2 (SP2) Unidentified / " }
			"7.0.835" { "SQL Server 7.0 Service Pack 2 (SP2) Beta / " }
			"7.0.776" { "FIX: Non-Admin User That Executes Batch While Server Shuts Down May Encounter Retail Assertion / 2006-03-14" }
			"7.0.770" { "FIX: Slow Compile Time On Complex Joins With Unfiltered Table / 2006-03-14" }
			"7.0.745" { "FIX: SQL Server Components That Access The Registry In A Cluster Environment May Cause A Memory Leak / 2005-10-07" }
			"7.0.722" { "FIX: Replication: Problems Mapping Characters To DB2 OLEDB Subscribers / 2005-10-05" }
			"7.0.699" { "SQL Server 7.0 Service Pack 1 (SP1) / 1999-07-01" }
			"7.0.689" { "SQL Server 7.0 Service Pack 1 (SP1) Beta / " }
			"7.0.677" { "SQL Server 7.0 MSDE From Office 2000 Disc / " }
			"7.0.662" { "FIX: Query With Complex View Hierarchy May Be Slow To Compile / 2005-10-05" }
			"7.0.658" { "FIX: Access Violation Under High Cursor Stress / 2006-03-14" }
			"7.0.657" { "FIX: Unable To Perform Automated Installation Of SQL 7.0 Using File Images / 2005-10-05" }
			"7.0.643" { "FIX: SQL Cluster Install Fails When SVS Name Contains Special Characters / 2005-10-05" }
			"7.0.623" { "SQL Server 7.0 RTM (Gold, No SP) / 1998-11-27" }
			"7.0.583" { "SQL Server 7.0 RC1 / " }
			"7.0.517" { "SQL Server 7.0 Beta 3 / " }
			"6.50.480" { "FIX: Integrated Security Sprocs Have Race Condition Between Threads That Can Result In An Access Violation / 2005-10-07" }
			"6.50.479" { "Microsoft SQL Server 6.5 Post Service Pack 5A Update / 2000-09-12" }
			"6.50.469" { "FIX: SQL Performance Counters May Cause Handle Leak In Winlogon Process / " }
			"6.50.465" { "FIX: Memory Leak With Xp_Sendmail Using Attachments / " }
			"6.50.464" { "FIX: Insert Error (Msg 213) With NO_BROWSETABLE And INSERT EXEC / 1999-11-08" }
			"6.50.462" { "FIX: Terminating Clients With TSQL KILL May Cause ODS AV / " }
			"6.50.451" { "FIX: ODS Errors During Attention Signal May Cause SQL Server To Stop Responding / " }
			"6.50.444" { "FIX: Multiple Attachments Not Sent Correctly Using Xp_Sendmail / " }
			"6.50.441" { "FIX: SNMP Extended Stored Procedures May Leak Memory / " }
			"6.50.422" { "FIX: Large Query Text From Socket Client May Cause Open Data Services Access Violation / " }
			"6.50.416" { "Microsoft SQL Server 6.5 Service Pack 5A (Sp5a) / 1998-12-24" }
			"6.50.415" { "Microsoft SQL Server 6.5 Service Pack 5 (SP5) / " }
			"6.50.339" { "Y2K Hotfix / " }
			"6.50.297" { "Site Server 3.0 Commerce Edition Hotfix / " }
			"6.50.281" { "Microsoft SQL Server 6.5 Service Pack 4 (SP4) / " }
			"6.50.259" { "6.5 As Included With 'Small Business Server' Only / " }
			"6.50.258" { "Microsoft SQL Server 6.5 Service Pack 3A (Sp3a) / " }
			"6.50.252" { "Microsoft SQL Server 6.5 Service Pack 3 (SP3) / " }
			"6.50.240" { "Microsoft SQL Server 6.5 Service Pack 2 (SP2) / " }
			"6.50.213" { "Microsoft SQL Server 6.5 Service Pack 1 (SP1) / " }
			"6.50.201" { "Microsoft SQL Server 6.5 RTM / 1996-06-30" }
			"6.0.151" { "Microsoft SQL Server 6.0 Service Pack 3 (SP3) / " }
			"6.0.139" { "Microsoft SQL Server 6.0 Service Pack 2 (SP2) / " }
			"6.0.124" { "Microsoft SQL Server 6.0 Service Pack 1 (SP1) / " }
			"6.0.121" { "Microsoft SQL Server 6.0 RTM / 1995-06-13" }
			# If nothing else found then default to version number
			default { "Unknown Version" }
		}
	}
	return $Output
}
