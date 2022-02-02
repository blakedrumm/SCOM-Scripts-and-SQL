<#
	.SYNOPSIS
		Gather SCOM General Information and Output to Console
	
	.DESCRIPTION
		This is a useful tool for troubleshooting customer environments.
	
	.PARAMETER Servers
		Each server you want to run the General Info gather against.
	
	.EXAMPLE
		PS C:\> .\Get-SCOMGeneralInformation.ps1
		PS C:\> .\Get-SCOMGeneralInformation.ps1 -Servers MS01-2019.contoso.com
	
	.NOTES
		Author: Blake Drumm (blakedrumm@microsoft.com)
		GitHub: https://github.com/blakedrumm
#>
[CmdletBinding()]
param
(
	[Parameter(ValueFromPipeline = $true,
			   Position = 0)]
	[string[]]$Servers
)
BEGIN
{
	Write-Output @" 
===================================================================
==========================  Start of Script =======================
===================================================================
"@
	Function Time-Stamp
	{
		$TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
		return "$TimeStamp - "
	}
	function Get-ProductVersion
	{
		param
		(
			[Parameter(Mandatory = $true,
					   Position = 1)]
			[ValidateSet('SCOM', 'SSRS')]
			[string]$Product,
			[Parameter(Mandatory = $true,
					   Position = 2)]
			[string]$BuildVersion
		)
		
		#Last Updated SQL Server List on 12/07/2021
		#Last Updated SCOM Version List on 12/07/2021
		#Last Updated SSRS Version List on 12/27/2021
		
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
		elseif ($Product -eq 'SSRS')
		{
			$Output = switch ($BuildVersion)
			{
    <# 
       SQL Server Reporting Services (SSRS) 2019 Versions
    #>
				'15.0.1102.932' { "SQL Server Reporting Services 2019 - October 2021 Release / 2021 October 20" }
				'15.0.7961.31630' { "SQL Server Reporting Services 2019 - October 2021 Release / 2021 October 20" } #File Version
				'15.0.1102.911' { "SQL Server Reporting Services 2019 - June 2021 Release / 2021 June 24" }
				'15.0.7842.32355' { "SQL Server Reporting Services 2019 - June 2021 Release / 2021 June 24" } #File Version
				'15.0.1102.896' { "SQL Server Reporting Services 2019 - April 2021 Release / 2021 April 07" }
				'15.0.7765.17516' { "SQL Server Reporting Services 2019 - April 2021 Release / 2021 April 07" } #File Version
				'15.0.1102.861' { "SQL Server Reporting Services 2019 - August 2020 Release / 2020 August 31" }
				'15.0.7545.4810' { "SQL Server Reporting Services 2019 - August 2020 Release / 2020 August 31" } #File Version
				'15.0.1102.675' { "SQL Server Reporting Services 2019 - October 2021 Release / 2021 October 20" }
				'15.0.7243.37714' { "SQL Server Reporting Services 2019 - Initial Release / 2019 November 1" } #File Version
    <# 
       SQL Server Reporting Services (SSRS) 2017 Versions
    #>
				'14.0.600.1763' { "SQL Server Reporting Services 2017 - June 2021 Release / 2021 June 28" }
				'14.0.7844.42503' { "SQL Server Reporting Services 2017 - June 2021 Release / 2021 June 28" } #File Version
				
				'14.0.600.1669' { "SQL Server Reporting Services 2017 - August 2020 Release / 2020 August 31" }
				'14.0.7544.5078' { "SQL Server Reporting Services 2017 - August 2020 Release / 2020 August 31" } #File Version
				'14.0.600.1572' { "SQL Server Reporting Services 2017 - April 2020 Release / 2020 April 6" }
				'14.0.600.1453' { "SQL Server Reporting Services 2017 - November 2019 Release 2 / 2019 November 14" }
				'14.0.600.1451' { "SQL Server Reporting Services 2017 - November 2019 Release / 2019 November 13" }
				'14.0.600.1274' { "SQL Server Reporting Services 2017 - July 2019 Release / 2019 July 1" }
				'14.0.600.1109' { "SQL Server Reporting Services 2017 - February 2019 Release / 2019 February 12" }
				'14.0.600.906' { "SQL Server Reporting Services 2017 - September 2018 Release / 2018 September 12" }
				'14.0.600.892' { "SQL Server Reporting Services 2017 - August 2018 Release / 2018 August 31" }
				'14.0.600.744' { "SQL Server Reporting Services 2017 - April 2018 Release / 2018 April 25" }
				'14.0.600.689' { "SQL Server Reporting Services 2017 - February 2018 Release / 2018 February 28" }
				'14.0.600.594' { "SQL Server Reporting Services 2017 - January 2018 Release / 2018 January 9" }
				'14.0.600.490' { "SQL Server Reporting Services 2017 - November 2017 Release / 2017 November 1" }
				'14.0.600.451' { "SQL Server Reporting Services 2017 - Initial Release / 2017 September 30" }
				
    <# 
       SQL Server Reporting Services (SSRS) 2016 and below Versions (these were integrated into SQL Install Directly)
    #>
				"13.0.6404.1" { "On-Demand Hotfix Update Package For SQL Server 2016 Service Pack 3 (SP3) / 2021 October 27" }
				"13.0.6300.2" { "Microsoft SQL Server 2016 Service Pack 3 (SP3) / 2021 September 15" }
				"13.0.5888.11" { "Cumulative Update 17 (CU17) For SQL Server 2016 Service Pack 2 / 2021 March 29" }
				"13.0.5882.1" { "Cumulative Update 16 (CU16) For SQL Server 2016 Service Pack 2 / 2021 February 11" }
				"13.0.5865.1" { "Security Update For SQL Server 2016 SP2 CU15: January 12, 2021 / 2021 January 12" }
				"13.0.5850.14" { "Cumulative Update 15 (CU15) For SQL Server 2016 Service Pack 2 / 2020 September 28" }
				"13.0.5830.85" { "Cumulative Update 14 (CU14) For SQL Server 2016 Service Pack 2 / 2020 August 06" }
				"13.0.5820.21" { "Cumulative Update 13 (CU13) For SQL Server 2016 Service Pack 2 / 2020 May 28" }
				"13.0.5698.0" { "Cumulative Update 12 (CU12) For SQL Server 2016 Service Pack 2 / 2020 February 25" }
				"13.0.5622.0" { "Security Update For SQL Server 2016 SP2 CU11: February 11, 2020 / 2020 February 11" }
				"13.0.5598.27" { "Cumulative Update 11 (CU11) For SQL Server 2016 Service Pack 2 / 2019 December 09" }
				"13.0.5492.2" { "Cumulative Update 10 (CU10) For SQL Server 2016 Service Pack 2 / 2019 October 08" }
				"13.0.5479.0" { "4515435 Cumulative Update 9 (CU9) For SQL Server 2016 Service Pack 2 / 2019 September 30" }
				"13.0.5426.0" { "Cumulative Update 8 (CU8) For SQL Server 2016 Service Pack 2 / 2019 July 31" }
				"13.0.5382.0" { "On-Demand Hotfix Update Package 2 For SQL Server 2016 Service Pack 2 (SP2) Cumulative Update 7 (CU7) / 2019 July 09" }
				"13.0.5366.0" { "Security Update For SQL Server 2016 SP2 CU7 GDR: July 9, 2019 / 2019 July 09" }
				"13.0.5343.1" { "On-Demand Hotfix Update Package For SQL Server 2016 Service Pack 2 (SP2) Cumulative Update 7 (CU7) / 2019 June 24" }
				"13.0.5337.0" { "Cumulative Update 7 (CU7) For SQL Server 2016 Service Pack 2 / 2019 May 22" }
				"13.0.5292.0" { "Cumulative Update 6 (CU6) For SQL Server 2016 Service Pack 2 / 2019 March 19" }
				"13.0.5270.0" { "On-Demand Hotfix Update Package For SQL Server 2016 SP2 CU5 / 2019 February 14" }
				"13.0.5264.1" { "Cumulative Update 5 (CU5) For SQL Server 2016 Service Pack 2 / 2019 January 23" }
				"13.0.5239.0" { "On-Demand Hotfix Update Package 2 For SQL Server 2016 SP2 CU4 / 2018 December 21" }
				"13.0.5233.0" { "Cumulative Update 4 (CU4) For SQL Server 2016 Service Pack 2 / 2018 November 13" }
				"13.0.5221.0" { "FIX: Assertion Error Occurs When You Restart The SQL Server 2016 Database / 2018 October 09" }
				"13.0.5221.0" { "FIX: '3414' And '9003' Errors And A .Pmm Log File Grows Large In SQL Server 2016 / 2018 October 09" }
				"13.0.5216.0" { "Cumulative Update 3 (CU3) For SQL Server 2016 Service Pack 2 / 2018 September 21" }
				"13.0.5201.2" { "Security Update For The Remote Code Execution Vulnerability In SQL Server 2016 SP2 CU: August 19, 2018 / 2018 August 19" }
				"13.0.5161.0" { "Security Update For The Remote Code Execution Vulnerability In SQL Server 2016 SP2 CU: August 14, 2018 / 2018 August 14" }
				"13.0.5153.0" { "Cumulative Update 2 (CU2) For SQL Server 2016 Service Pack 2 / 2018 July 17" }
				"13.0.5149.0" { "Cumulative Update 1 (CU1) For SQL Server 2016 Service Pack 2 / 2018 May 30" }
				"13.0.5103.6" { "Security Update For SQL Server 2016 SP2 GDR: January 12, 2021 / 2021 January 12" }
				"13.0.5102.14" { "Security Update For SQL Server 2016 SP2 GDR: February 11, 2020 / 2020 February 11" }
				"13.0.5101.9" { "Security Update For SQL Server 2016 SP2 GDR: July 9, 2019 / 2019 July 09" }
				"13.0.5081.1" { "Security Update For The Remote Code Execution Vulnerability In SQL Server 2016 SP2 GDR: August 14, 2018 / 2018 August 14" }
				"13.0.5026.0" { "Microsoft SQL Server 2016 Service Pack 2 (SP2) / 2018 April 24" }
				"13.0.4604.0" { "Security Update For SQL Server 2016 SP1 CU15 GDR: July 9, 2019 / 2019 July 09" }
				"13.0.4577.0" { "On-Demand Hotfix Update Package For SQL Server 2016 Service Pack 1 (SP1) Cumulative Update 15 (CU15) / 2019 June 20" }
				"13.0.4574.0" { "Cumulative Update 15 (CU15) For SQL Server 2016 Service Pack 1 / 2019 May 16" }
				"13.0.4560.0" { "Cumulative Update 14 (CU14) For SQL Server 2016 Service Pack 1 / 2019 March 19" }
				"13.0.4550.1" { "Cumulative Update 13 (CU13) For SQL Server 2016 Service Pack 1 / 2019 January 23" }
				"13.0.4541.0" { "Cumulative Update 12 (CU12) For SQL Server 2016 Service Pack 1 / 2018 November 13" }
				"13.0.4531.0" { "FIX: The 'Modification_Counter' In DMV Sys.Dm_Db_Stats_Properties Shows Incorrect Value When Partitions Are Merged Through ALTER PARTITION In SQL Server 2016 / 2018 September 27" }
				"13.0.4528.0" { "Cumulative Update 11 (CU11) For SQL Server 2016 Service Pack 1 / 2018 September 18" }
				"13.0.4522.0" { "Security Update For The Remote Code Execution Vulnerability In SQL Server 2016 SP1 CU: August 14, 2018 / 2018 August 14" }
				"13.0.4514.0" { "Cumulative Update 10 (CU10) For SQL Server 2016 Service Pack 1 / 2018 July 16" }
				"13.0.4502.0" { "Cumulative Update 9 (CU9) For SQL Server 2016 Service Pack 1 / 2018 May 30" }
				"13.0.4477.0" { "On-Demand Hotfix Update Package For SQL Server 2016 SP1 / 2018 June 02" }
				"13.0.4474.0" { "Cumulative Update 8 (CU8) For SQL Server 2016 Service Pack 1 / 2018 March 19" }
				"13.0.4466.4" { "Cumulative Update 7 (CU7) For SQL Server 2016 Service Pack 1 - Security Advisory ADV180002 / 2018 January 04" }
				"13.0.4457.0" { "Cumulative Update 6 (CU6) For SQL Server 2016 Service Pack 1 / 2017 November 21" }
				"13.0.4451.0" { "Cumulative Update 5 (CU5) For SQL Server 2016 Service Pack 1 / 2017 September 18" }
				"13.0.4446.0" { "Cumulative Update 4 (CU4) For SQL Server 2016 Service Pack 1 / 2017 August 08" }
				"13.0.4435.0" { "Cumulative Update 3 (CU3) For SQL Server 2016 Service Pack 1 / 2017 May 15" }
				"13.0.4422.0" { "Cumulative Update 2 (CU2) For SQL Server 2016 Service Pack 1 / 2017 March 22" }
				"13.0.4411.0" { "Cumulative Update 1 (CU1) For SQL Server 2016 Service Pack 1 / 2017 January 18" }
				"13.0.4259.0" { "Security Update For SQL Server 2016 SP1 GDR: July 9, 2019 / 2019 July 09" }
				"13.0.4224.16" { "Security Update For The Remote Code Execution Vulnerability In SQL Server 2016 SP1 GDR: August 22, 2018 / 2018 August 22" }
				"13.0.4223.10" { "Security Update For The Remote Code Execution Vulnerability In SQL Server 2016 SP1 GDR: August 14, 2018 / 2018 August 14" }
				"13.0.4210.6" { "Description Of The Security Update For SQL Server 2016 SP1 GDR: January 3, 2018 - Security Advisory ADV180002 / 2018 January 03" }
				"13.0.4206.0" { "Security Update For SQL Server 2016 Service Pack 1 GDR: August 8, 2017 / 2017 August 08" }
				"13.0.4202.2" { "GDR Update Package For SQL Server 2016 SP1 / 2016 December 16" }
				"13.0.4199.0" { "Important Update For SQL Server 2016 SP1 Reporting Services / 2016 November 23" }
				"13.0.4001.0" { "Microsoft SQL Server 2016 Service Pack 1 (SP1) / 2016 November 16" }
				"13.0.2218.0" { "Description Of The Security Update For SQL Server 2016 CU: January 6, 2018 - Security Advisory ADV180002 / 2018 January 06" }
				"13.0.2216.0" { "Cumulative Update 9 (CU9) For SQL Server 2016 / 2017 November 21" }
				"13.0.2213.0" { "Cumulative Update 8 (CU8) For SQL Server 2016 / 2017 September 18" }
				"13.0.2210.0" { "Cumulative Update 7 (CU7) For SQL Server 2016 / 2017 August 08" }
				"13.0.2204.0" { "Cumulative Update 6 (CU6) For SQL Server 2016 / 2017 May 15" }
				"13.0.2197.0" { "Cumulative Update 5 (CU5) For SQL Server 2016 / 2017 March 21" }
				"13.0.2193.0" { "Cumulative Update 4 (CU4) For SQL Server 2016 / 2017 January 18" }
				"13.0.2190.2" { "On-Demand Hotfix Update Package For SQL Server 2016 CU3 / 2016 December 16" }
				"13.0.2186.6" { "Cumulative Update 3 (CU3) For SQL Server 2016 / 2016 November 08" }
				"13.0.2186.6" { "MS16-136: Description Of The Security Update For SQL Server 2016 CU: November 8, 2016 / 2016 November 08" }
				"13.0.2170.0" { "On-Demand Hotfix Update Package For SQL Server 2016 CU2 / 2016 November 01" }
				"13.0.2169.0" { "On-Demand Hotfix Update Package For SQL Server 2016 CU2 / 2016 October 26" }
				"13.0.2164.0" { "Cumulative Update 2 (CU2) For SQL Server 2016 / 2016 September 22" }
				"13.0.2149.0" { "Cumulative Update 1 (CU1) For SQL Server 2016 / 2016 July 26" }
				"13.0.1745.2" { "Description Of The Security Update For SQL Server 2016 GDR: January 6, 2018 - Security Advisory ADV180002 / 2018 January 06" }
				"13.0.1742.0" { "Security Update For SQL Server 2016 RTM GDR: August 8, 2017 / 2017 August 08" }
				"13.0.1728.2" { "GDR Update Package For SQL Server 2016 RTM / 2016 December 16" }
				"13.0.1722.0" { "MS16-136: Description Of The Security Update For SQL Server 2016 GDR: November 8, 2016 / 2016 November 08" }
				"13.0.1711.0" { "Processing A Partition Causes Data Loss On Other Partitions After The Database Is Restored In SQL Server 2016 (1200) / 2016 August 17" }
				"13.0.1708.0" { "Critical Update For SQL Server 2016 MSVCRT Prerequisites / 2016 June 03" }
				"13.0.1601.5" { "Microsoft SQL Server 2016 RTM / 2016 June 01" }
				"13.0.1400.361" { "Microsoft SQL Server 2016 Release Candidate 3 (RC3) / 2016 April 15" }
				"13.0.1300.275" { "Microsoft SQL Server 2016 Release Candidate 2 (RC2) / 2016 April 01" }
				"13.0.1200.242" { "Microsoft SQL Server 2016 Release Candidate 1 (RC1) / 2016 March 18" }
				"13.0.1100.288" { "Microsoft SQL Server 2016 Release Candidate 0 (RC0) / 2016 March 07" }
				"13.0.1000.281" { "Microsoft SQL Server 2016 Community Technology Preview 3.3 (CTP3.3) / 2016 February 03" }
				"13.0.900.73" { "Microsoft SQL Server 2016 Community Technology Preview 3.2 (CTP3.2) / 2015 December 16" }
				"13.0.800.11" { "Microsoft SQL Server 2016 Community Technology Preview 3.1 (CTP3.1) / 2015 November 30" }
				"13.0.700.139" { "Microsoft SQL Server 2016 Community Technology Preview 3.0 (CTP3.0) / 2015 October 28" }
				"13.0.600.65" { "Microsoft SQL Server 2016 Community Technology Preview 2.4 (CTP2.4) / 2015 September 30" }
				"13.0.500.53" { "Microsoft SQL Server 2016 Community Technology Preview 2.3 (CTP2.3) / 2015 August 28" }
				"13.0.407.1" { "Microsoft SQL Server 2016 Community Technology Preview 2.2 (CTP2.2) / 2015 July 23" }
				"13.0.400.91" { "Microsoft SQL Server 2016 Community Technology Preview 2.2 (CTP2.2) / 2015 July 22" }
				"13.0.300.44" { "Microsoft SQL Server 2016 Community Technology Preview 2.1 (CTP2.1) / 2015 June 24" }
				"13.0.200.172" { "Microsoft SQL Server 2016 Community Technology Preview 2 (CTP2) / 2015 May 27" }
				"12.0.6433.1" { "Security Update For SQL Server 2014 SP3 CU4: January 12, 2021 / 2021 January 12" }
				"12.0.6372.1" { "Security Update For SQL Server 2014 SP3 CU4: February 11, 2020 / 2020 February 11" }
				"12.0.6329.1" { "Cumulative Update Package 4 (CU4) For SQL Server 2014 Service Pack 3 / 2019 July 29" }
				"12.0.6293.0" { "Security Update For SQL Server 2014 SP3 CU3 GDR: July 9, 2019 / 2019 July 09" }
				"12.0.6259.0" { "Cumulative Update Package 3 (CU3) For SQL Server 2014 Service Pack 3 / 2019 April 16" }
				"12.0.6214.1" { "Cumulative Update Package 2 (CU2) For SQL Server 2014 Service Pack 3 / 2019 February 19" }
				"12.0.6205.1" { "Cumulative Update Package 1 (CU1) For SQL Server 2014 Service Pack 3 / 2018 December 12" }
				"12.0.6164.21" { "Security Update For SQL Server 2014 SP3 GDR: January 12, 2021 / 2021 January 12" }
				"12.0.6118.4" { "Security Update For SQL Server 2014 SP3 GDR: February 11, 2020 / 2020 February 11" }
				"12.0.6108.1" { "Security Update For SQL Server 2014 SP3 GDR: July 9, 2019 / 2019 July 09" }
				"12.0.6024.0" { "SQL Server 2014 Service Pack 3 (SP3) / 2018 October 30" }
				"12.0.5687.1" { "Cumulative Update Package 18 (CU18) For SQL Server 2014 Service Pack 2 / 2019 July 29" }
				"12.0.5659.1" { "Security Update For SQL Server 2014 SP2 CU17 GDR: July 9, 2019 / 2019 July 09" }
				"12.0.5632.1" { "Cumulative Update Package 17 (CU17) For SQL Server 2014 Service Pack 2 / 2019 April 16" }
				"12.0.5626.1" { "Cumulative Update Package 16 (CU16) For SQL Server 2014 Service Pack 2 / 2019 February 19" }
				"12.0.5605.1" { "Cumulative Update Package 15 (CU15) For SQL Server 2014 Service Pack 2 / 2018 December 12" }
				"12.0.5600.1" { "Cumulative Update Package 14 (CU14) For SQL Server 2014 Service Pack 2 / 2018 October 15" }
				"12.0.5590.1" { "Cumulative Update Package 13 (CU13) For SQL Server 2014 Service Pack 2 / 2018 August 27" }
				"12.0.5589.7" { "Cumulative Update Package 12 (CU12) For SQL Server 2014 Service Pack 2 / 2018 June 18" }
				"12.0.5579.0" { "Cumulative Update Package 11 (CU11) For SQL Server 2014 Service Pack 2 / 2018 March 19" }
				"12.0.5571.0" { "Cumulative Update Package 10 (CU10) For SQL Server 2014 Service Pack 2 - Security Advisory ADV180002 / 2018 January 16" }
				"12.0.5563.0" { "Cumulative Update Package 9 (CU9) For SQL Server 2014 Service Pack 2 / 2017 December 19" }
				"12.0.5557.0" { "Cumulative Update Package 8 (CU8) For SQL Server 2014 Service Pack 2 / 2017 October 17" }
				"12.0.5556.0" { "Cumulative Update Package 7 (CU7) For SQL Server 2014 Service Pack 2 / 2017 August 29" }
				"12.0.5553.0" { "Cumulative Update Package 6 (CU6) For SQL Server 2014 Service Pack 2 / 2017 August 08" }
				"12.0.5546.0" { "Cumulative Update Package 5 (CU5) For SQL Server 2014 Service Pack 2 / 2017 April 18" }
				"12.0.5540.0" { "Cumulative Update Package 4 (CU4) For SQL Server 2014 Service Pack 2 / 2017 February 21" }
				"12.0.5538.0" { "Cumulative Update Package 3 (CU3) For SQL Server 2014 Service Pack 2 - The Article Incorrectly Says It's Version 12.0.5537 / 2016 December 28" }
				"12.0.5532.0" { "MS16-136: Description Of The Security Update For SQL Server 2014 Service Pack 2 CU: November 8, 2016 / 2016 November 08" }
				"12.0.5522.0" { "Cumulative Update Package 2 (CU2) For SQL Server 2014 Service Pack 2 / 2016 October 18" }
				"12.0.5511.0" { "Cumulative Update Package 1 (CU1) For SQL Server 2014 Service Pack 2 / 2016 August 26" }
				"12.0.5223.6" { "Security Update For SQL Server 2014 SP2 GDR: July 9, 2019 / 2019 July 09" }
				"12.0.5214.6" { "Security Update For SQL Server 2014 Service Pack 2 GDR: January 16, 2018 - Security Advisory ADV180002 / 2018 January 16" }
				"12.0.5207.0" { "Security Update For SQL Server 2014 Service Pack 2 GDR: August 8, 2017 / 2017 August 08" }
				"12.0.5203.0" { "MS16-136: Description Of The Security Update For SQL Server 2014 Service Pack 2 GDR: November 8, 2016 / 2016 November 08" }
				"12.0.5000.0" { "SQL Server 2014 Service Pack 2 (SP2) / 2016 July 11" }
				"12.0.4522.0" { "Cumulative Update Package 13 (CU13) For SQL Server 2014 Service Pack 1 / 2017 August 08" }
				"12.0.4511.0" { "Cumulative Update Package 12 (CU12) For SQL Server 2014 Service Pack 1 / 2017 April 18" }
				"12.0.4502.0" { "Cumulative Update Package 11 (CU11) For SQL Server 2014 Service Pack 1 / 2017 February 21" }
				"12.0.4491.0" { "Cumulative Update Package 10 (CU10) For SQL Server 2014 Service Pack 1 / 2016 December 28" }
				"12.0.4487.0" { "MS16-136: Description Of The Security Update For SQL Server 2014 Service Pack 1 CU: November 8, 2016 / 2016 November 08" }
				"12.0.4474.0" { "Cumulative Update Package 9 (CU9) For SQL Server 2014 Service Pack 1 / 2016 October 18" }
				"12.0.4468.0" { "Cumulative Update Package 8 (CU8) For SQL Server 2014 Service Pack 1 / 2016 August 15" }
				"12.0.4463.0" { "A Memory Leak Occurs When You Use Azure Storage In SQL Server 2014 / 2016 August 04" }
				"12.0.4459.0" { "Cumulative Update Package 7 (CU7) For SQL Server 2014 Service Pack 1 / 2016 June 20" }
				"12.0.4457.1" { "REFRESHED Cumulative Update Package 6 (CU6) For SQL Server 2014 Service Pack 1 / 2016 May 31" }
				"12.0.4449.1" { "DEPRECATED Cumulative Update Package 6 (CU6) For SQL Server 2014 Service Pack 1 / 2016 April 19" }
				"12.0.4439.1" { "Cumulative Update Package 5 (CU5) For SQL Server 2014 Service Pack 1 / 2016 February 22" }
				"12.0.4437.0" { "On-Demand Hotfix Update Package For SQL Server 2014 Service Pack 1 Cumulative Update 4 / 2016 February 05" }
				"12.0.4436.0" { "Cumulative Update Package 4 (CU4) For SQL Server 2014 Service Pack 1 / 2015 December 22" }
				"12.0.4433.0" { "FIX: Error 3203 And A SQL Server 2014 Backup Job Can't Restart When A Network Failure Occurs / 2015 December 09" }
				"12.0.4432.0" { "FIX: Error When Your Stored Procedure Calls Another Stored Procedure On Linked Server In SQL Server 2014 / 2015 November 19" }
				"12.0.4237.0" { "Security Update For SQL Server 2014 Service Pack 1 GDR: August 8, 2017 / 2017 August 08" }
				"12.0.4232.0" { "MS16-136: Description Of The Security Update For SQL Server 2014 Service Pack 1 GDR: November 8, 2016 / 2016 November 08" }
				"12.0.4427.24" { "Cumulative Update Package 3 (CU3) For SQL Server 2014 Service Pack 1 / 2015 October 21" }
				"12.0.4422.0" { "Cumulative Update Package 2 (CU2) For SQL Server 2014 Service Pack 1 / 2015 August 17" }
				"12.0.4419.0" { "An On-Demand Hotfix Update Package Is Available For SQL Server 2014 SP1 / 2015 July 24" }
				"12.0.4416.0" { "Cumulative Update Package 1 (CU1) For SQL Server 2014 Service Pack 1 / 2015 June 22" }
				"12.0.4219.0" { "TLS 1.2 Support For SQL Server 2014 SP1 / 2016 January 27" }
				"12.0.4213.0" { "MS15-058: Description Of The Nonsecurity Update For SQL Server 2014 Service Pack 1 GDR: July 14, 2015 / 2015 July 14" }
				"12.0.4100.1" { "SQL Server 2014 Service Pack 1 (SP1) / 2015 May 14" }
				"12.0.4050.0" { "SQL Server 2014 Service Pack 1 (SP1) / 2015 April 15" }
				"12.0.2569.0" { "Cumulative Update Package 14 (CU14) For SQL Server 2014 / 2016 June 20" }
				"12.0.2568.0" { "Cumulative Update Package 13 (CU13) For SQL Server 2014 / 2016 April 18" }
				"12.0.2564.0" { "Cumulative Update Package 12 (CU12) For SQL Server 2014 / 2016 February 22" }
				"12.0.2560.0" { "Cumulative Update Package 11 (CU11) For SQL Server 2014 / 2015 December 22" }
				"12.0.2556.4" { "Cumulative Update Package 10 (CU10) For SQL Server 2014 / 2015 October 20" }
				"12.0.2553.0" { "Cumulative Update Package 9 (CU9) For SQL Server 2014 / 2015 August 17" }
				"12.0.2548.0" { "MS15-058: Description Of The Security Update For SQL Server 2014 QFE: July 14, 2015 / 2015 July 14" }
				"12.0.2546.0" { "Cumulative Update Package 8 (CU8) For SQL Server 2014 / 2015 June 22" }
				"12.0.2506.0" { "Update Enables Premium Storage Support For Data Files On Azure Storage And Resolves Backup Failures / 2015 May 19" }
				"12.0.2505.0" { "FIX: Error 1205 When You Execute Parallel Query That Contains Outer Join Operators In SQL Server 2014 / 2015 May 19" }
				"12.0.2504.0" { "FIX: Poor Performance When A Query Contains Table Joins In SQL Server 2014 / 2015 May 05" }
				"12.0.2504.0" { "FIX: Unpivot Transformation Task Changes Null To Zero Or Empty Strings In SSIS 2014 / 2015 May 05" }
				"12.0.2495.0" { "Cumulative Update Package 7 (CU7) For SQL Server 2014 / 2015 April 23" }
				"12.0.2488.0" { "FIX: Deadlock Cannot Be Resolved Automatically When You Run A SELECT Query That Can Result In A Parallel Batch-Mode Scan / 2015 April 01" }
				"12.0.2485.0" { "An On-Demand Hotfix Update Package Is Available For SQL Server 2014 / 2015 March 16" }
				"12.0.2480.0" { "Cumulative Update Package 6 (CU6) For SQL Server 2014 / 2015 February 16" }
				"12.0.2474.0" { "FIX: Alwayson Availability Groups Are Reported As NOT SYNCHRONIZING / 2015 May 15" }
				"12.0.2472.0" { "FIX: Cannot Show Requested Dialog After You Connect To The Latest SQL Database Update V12 (Preview) With SQL Server 2014 / 2015 January 28" }
				"12.0.2464.0" { "Large Query Compilation Waits On RESOURCE_SEMAPHORE_QUERY_COMPILE In SQL Server 2014 / 2015 January 05" }
				"12.0.2456.0" { "Cumulative Update Package 5 (CU5) For SQL Server 2014 / 2014 December 18" }
				"12.0.2436.0" { "FIX: 'Remote Hardening Failure' Exception Cannot Be Caught And A Potential Data Loss When You Use SQL Server 2014 / 2014 November 27" }
				"12.0.2430.0" { "Cumulative Update Package 4 (CU4) For SQL Server 2014 / 2014 October 21" }
				"12.0.2423.0" { "FIX: RTDATA_LIST Waits When You Run Natively Stored Procedures That Encounter Expected Failures In SQL Server 2014 / 2014 October 22" }
				"12.0.2405.0" { "FIX: Poor Performance When A Query Contains Table Joins In SQL Server 2014 / 2014 September 25" }
				"12.0.2402.0" { "Cumulative Update Package 3 (CU3) For SQL Server 2014 / 2014 August 18" }
				"12.0.2381.0" { "MS14-044: Description Of The Security Update For SQL Server 2014 (QFE) / 2014 August 12" }
				"12.0.2370.0" { "Cumulative Update Package 2 (CU2) For SQL Server 2014 / 2014 June 27" }
				"12.0.2342.0" { "Cumulative Update Package 1 (CU1) For SQL Server 2014 / 2014 April 21" }
				"12.0.2271.0" { "TLS 1.2 Support For SQL Server 2014 RTM / 2016 January 27" }
				"12.0.2269.0" { "MS15-058: Description Of The Security Update For SQL Server 2014 GDR: July 14, 2015 / 2015 July 14" }
				"12.0.2254.0" { "MS14-044: Description Of The Security Update For SQL Server 2014 (GDR) / 2014 August 12" }
				"12.0.2000.8" { "SQL Server 2014 RTM / 2014 April 01" }
				"12.0.1524.0" { "Microsoft SQL Server 2014 Community Technology Preview 2 (CTP2) / 2013 October 15" }
				"11.0.9120.0" { "Microsoft SQL Server 2014 Community Technology Preview 1 (CTP1) / 2013 June 25" }
				"11.0.7507.2" { "Security Update For SQL Server 2012 SP4 GDR: January 12, 2021 / 2021 January 12" }
				"11.0.7493.4" { "Security Update For SQL Server 2012 SP4 GDR: February 11, 2020 / 2020 February 11" }
				"11.0.7469.6" { "On-Demand Hotfix Update Package For SQL Server 2012 SP4 / 2018 March 28" }
				"11.0.7462.6" { "Description Of The Security Update For SQL Server 2012 SP4 GDR: January 12, 2018 - Security Advisory ADV180002 / 2018 January 12" }
				"11.0.7001.0" { "SQL Server 2012 Service Pack 4 (SP4) / 2017 October 05" }
				"11.0.6615.2" { "Description Of The Security Update For SQL Server 2012 SP3 CU: January 16, 2018 - Security Advisory ADV180002 / 2018 January 16" }
				"11.0.6607.3" { "Cumulative Update Package 10 (CU10) For SQL Server 2012 Service Pack 3 / 2017 August 08" }
				"11.0.6607.3" { "Security Update For SQL Server 2012 Service Pack 3 CU: August 8, 2017 / 2017 August 08" }
				"11.0.6598.0" { "Cumulative Update Package 9 (CU9) For SQL Server 2012 Service Pack 3 / 2017 May 15" }
				"11.0.6594.0" { "Cumulative Update Package 8 (CU8) For SQL Server 2012 Service Pack 3 / 2017 March 21" }
				"11.0.6579.0" { "Cumulative Update Package 7 (CU7) For SQL Server 2012 Service Pack 3 / 2017 January 17" }
				"11.0.6567.0" { "Cumulative Update Package 6 (CU6) For SQL Server 2012 Service Pack 3 / 2016 November 17" }
				"11.0.6567.0" { "MS16-136: Description Of The Security Update For SQL Server 2012 Service Pack 3 CU: November 8, 2016 / 2016 November 08" }
				"11.0.6544.0" { "Cumulative Update Package 5 (CU5) For SQL Server 2012 Service Pack 3 / 2016 September 21" }
				"11.0.6540.0" { "Cumulative Update Package 4 (CU4) For SQL Server 2012 Service Pack 3 / 2016 July 19" }
				"11.0.6537.0" { "Cumulative Update Package 3 (CU3) For SQL Server 2012 Service Pack 3 / 2016 May 17" }
				"11.0.6523.0" { "Cumulative Update Package 2 (CU2) For SQL Server 2012 Service Pack 3 / 2016 March 22" }
				"11.0.6518.0" { "Cumulative Update Package 1 (CU1) For SQL Server 2012 Service Pack 3 / 2016 January 19" }
				"11.0.6260.1" { "Description Of The Security Update For SQL Server 2012 SP3 GDR: January 16, 2018 - Security Advisory ADV180002 / 2018 January 16" }
				"11.0.6251.0" { "Description Of The Security Update For SQL Server 2012 Service Pack 3 GDR: August 8, 2017 / 2017 August 08" }
				"11.0.6248.0" { "MS16-136: Description Of The Security Update For SQL Server 2012 Service Pack 3 GDR: November 8, 2016 / 2016 November 08" }
				"11.0.6216.27" { "TLS 1.2 Support For SQL Server 2012 SP3 GDR / 2016 January 27" }
				"11.0.6020.0" { "SQL Server 2012 Service Pack 3 (SP3) / 2015 November 23" }
				"11.0.5678.0" { "Cumulative Update Package 16 (CU16) For SQL Server 2012 Service Pack 2 / 2017 January 18" }
				"11.0.5676.0" { "Cumulative Update Package 15 (CU15) For SQL Server 2012 Service Pack 2 / 2016 November 17" }
				"11.0.5676.0" { "MS16-136: Description Of The Security Update For SQL Server 2012 Service Pack 2 CU: November 8, 2016 / 2016 November 08" }
				"11.0.5657.0" { "Cumulative Update Package 14 (CU14) For SQL Server 2012 Service Pack 2 / 2016 September 20" }
				"11.0.5655.0" { "Cumulative Update Package 13 (CU13) For SQL Server 2012 Service Pack 2 / 2016 July 19" }
				"11.0.5649.0" { "Cumulative Update Package 12 (CU12) For SQL Server 2012 Service Pack 2 / 2016 May 16" }
				"11.0.5646.0" { "Cumulative Update Package 11 (CU11) For SQL Server 2012 Service Pack 2 / 2016 March 22" }
				"11.0.5644.0" { "Cumulative Update Package 10 (CU10) For SQL Server 2012 Service Pack 2 / 2016 January 20" }
				"11.0.5641.0" { "Cumulative Update Package 9 (CU9) For SQL Server 2012 Service Pack 2 / 2015 November 18" }
				"11.0.5636.3" { "FIX: Performance Decrease When Application With Connection Pooling Frequently Connects Or Disconnects In SQL Server / 2015 September 22" }
				"11.0.5634.0" { "Cumulative Update Package 8 (CU8) For SQL Server 2012 Service Pack 2 / 2015 September 21" }
				"11.0.5629.0" { "FIX: Access Violations When You Use The Filetable Feature In SQL Server 2012 / 2015 August 31" }
				"11.0.5623.0" { "Cumulative Update Package 7 (CU7) For SQL Server 2012 Service Pack 2 / 2015 July 20" }
				"11.0.5613.0" { "MS15-058: Description Of The Security Update For SQL Server 2012 Service Pack 2 QFE: July 14, 2015 / 2015 July 14" }
				"11.0.5592.0" { "Cumulative Update Package 6 (CU6) For SQL Server 2012 Service Pack 2 / 2015 May 19" }
				"11.0.5582.0" { "Cumulative Update Package 5 (CU5) For SQL Server 2012 Service Pack 2 / 2015 March 16" }
				"11.0.5571.0" { "FIX: Alwayson Availability Groups Are Reported As NOT SYNCHRONIZING / 2015 May 15" }
				"11.0.5569.0" { "Cumulative Update Package 4 (CU4) For SQL Server 2012 Service Pack 2 / 2015 January 20" }
				"11.0.5556.0" { "Cumulative Update Package 3 (CU3) For SQL Server 2012 Service Pack 2 / 2014 November 17" }
				"11.0.5548.0" { "Cumulative Update Package 2 (CU2) For SQL Server 2012 Service Pack 2 / 2014 September 15" }
				"11.0.5532.0" { "Cumulative Update Package 1 (CU1) For SQL Server 2012 Service Pack 2 / 2014 July 24" }
				"11.0.5522.0" { "FIX: Data Loss In Clustered Index Occurs When You Run Online Build Index In SQL Server 2012 (Hotfix For SQL2012 SP2) / 2014 June 20" }
				"11.0.5388.0" { "MS16-136: Description Of The Security Update For SQL Server 2012 Service Pack 2 GDR: November 8, 2016 / 2016 November 08" }
				"11.0.5352.0" { "TLS 1.2 Support For SQL Server 2012 SP2 GDR / 2016 January 27" }
				"11.0.5343.0" { "MS15-058: Description Of The Security Update For SQL Server 2012 Service Pack 2 GDR: July 14, 2015 / 2015 July 14" }
				"11.0.5058.0" { "SQL Server 2012 Service Pack 2 (SP2) / 2014 June 10" }
				"11.0.3513.0" { "MS15-058: Description Of The Security Update For SQL Server 2012 SP1 QFE: July 14, 2015 / 2015 July 14" }
				"11.0.3492.0" { "Cumulative Update Package 16 (CU16) For SQL Server 2012 Service Pack 1 / 2015 May 18" }
				"11.0.3487.0" { "Cumulative Update Package 15 (CU15) For SQL Server 2012 Service Pack 1 / 2015 March 16" }
				"11.0.3486.0" { "Cumulative Update Package 14 (CU14) For SQL Server 2012 Service Pack 1 / 2015 January 19" }
				"11.0.3460.0" { "MS14-044: Description Of The Security Update For SQL Server 2012 Service Pack 1 (QFE) / 2014 August 12" }
				"11.0.3482.0" { "Cumulative Update Package 13 (CU13) For SQL Server 2012 Service Pack 1 / 2014 November 17" }
				"11.0.3470.0" { "Cumulative Update Package 12 (CU12) For SQL Server 2012 Service Pack 1 / 2014 September 15" }
				"11.0.3449.0" { "Cumulative Update Package 11 (CU11) For SQL Server 2012 Service Pack 1 / 2014 July 21" }
				"11.0.3437.0" { "FIX: Data Loss In Clustered Index Occurs When You Run Online Build Index In SQL Server 2012 (Hotfix For SQL2012 SP1) / 2014 June 10" }
				"11.0.3431.0" { "Cumulative Update Package 10 (CU10) For SQL Server 2012 Service Pack 1 / 2014 May 19" }
				"11.0.3412.0" { "Cumulative Update Package 9 (CU9) For SQL Server 2012 Service Pack 1 / 2014 March 18" }
				"11.0.3401.0" { "Cumulative Update Package 8 (CU8) For SQL Server 2012 Service Pack 1 / 2014 January 20" }
				"11.0.3393.0" { "Cumulative Update Package 7 (CU7) For SQL Server 2012 Service Pack 1 / 2013 November 18" }
				"11.0.3381.0" { "Cumulative Update Package 6 (CU6) For SQL Server 2012 Service Pack 1 / 2013 September 16" }
				"11.0.3373.0" { "Cumulative Update Package 5 (CU5) For SQL Server 2012 Service Pack 1 / 2013 July 16" }
				"11.0.3368.0" { "Cumulative Update Package 4 (CU4) For SQL Server 2012 Service Pack 1 / 2013 May 31" }
				"11.0.3350.0" { "FIX: You Can'T Create Or Open SSIS Projects Or Maintenance Plans After You Apply Cumulative Update 3 For SQL Server 2012 SP1 / 2013 April 17" }
				"11.0.3349.0" { "Cumulative Update Package 3 (CU3) For SQL Server 2012 Service Pack 1 / 2013 March 18" }
				"11.0.3339.0" { "Cumulative Update Package 2 (CU2) For SQL Server 2012 Service Pack 1 / 2013 January 25" }
				"11.0.3335.0" { "FIX: Component Installation Process Fails After You Install SQL Server 2012 SP1 / 2013 January 14" }
				"11.0.3321.0" { "Cumulative Update Package 1 (CU1) For SQL Server 2012 Service Pack 1 / 2012 November 20" }
				"11.0.3156.0" { "MS15-058: Description Of The Security Update For SQL Server 2012 SP1 GDR: July 14, 2015 / 2015 July 14" }
				"11.0.3153.0" { "MS14-044: Description Of The Security Update For SQL Server 2012 Service Pack 1 (GDR) / 2014 August 12" }
				"11.0.3128.0" { "Windows Installer Starts Repeatedly After You Install SQL Server 2012 SP1 / 2013 January 03" }
				"11.0.3000.0" { "SQL Server 2012 Service Pack 1 (SP1) / 2012 November 06" }
				"11.0.2845.0" { "SQL Server 2012 Service Pack 1 Customer Technology Preview 4 (CTP4) / 2012 September 20" }
				"11.0.2809.24" { "SQL Server 2012 Service Pack 1 Customer Technology Preview 3 (CTP3) / 2012 July 05" }
				"11.0.2424.0" { "Cumulative Update Package 11 (CU11) For SQL Server 2012 / 2013 December 17" }
				"11.0.2420.0" { "Cumulative Update Package 10 (CU10) For SQL Server 2012 / 2013 October 21" }
				"11.0.2419.0" { "Cumulative Update Package 9 (CU9) For SQL Server 2012 / 2013 August 21" }
				"11.0.2410.0" { "Cumulative Update Package 8 (CU8) For SQL Server 2012 / 2013 June 18" }
				"11.0.2405.0" { "Cumulative Update Package 7 (CU7) For SQL Server 2012 / 2013 April 15" }
				"11.0.2401.0" { "Cumulative Update Package 6 (CU6) For SQL Server 2012 / 2013 February 18" }
				"11.0.2395.0" { "Cumulative Update Package 5 (CU5) For SQL Server 2012 / 2012 December 18" }
				"11.0.9000.5" { "Microsoft SQL Server 2012 With Power View For Multidimensional Models Customer Technology Preview (CTP3) / 2012 November 27" }
				"11.0.2383.0" { "Cumulative Update Package 4 (CU4) For SQL Server 2012 / 2012 October 18" }
				"11.0.2376.0" { "Microsoft Security Bulletin MS12-070 / 2012 October 09" }
				"11.0.2332.0" { "Cumulative Update Package 3 (CU3) For SQL Server 2012 / 2012 August 29" }
				"11.0.2325.0" { "Cumulative Update Package 2 (CU2) For SQL Server 2012 / 2012 June 18" }
				"11.0.2318.0" { "SQL Server 2012 Express Localdb RTM / 2012 April 19" }
				"11.0.2316.0" { "Cumulative Update Package 1 (CU1) For SQL Server 2012 / 2012 April 12" }
				"11.0.2218.0" { "Microsoft Security Bulletin MS12-070 / 2012 October 09" }
				"11.0.2214.0" { "FIX: SSAS Uses Only 20 Cores In SQL Server 2012 Business Intelligence / 2012 April 06" }
				"11.0.2100.60" { "SQL Server 2012 RTM / 2012 March 06" }
				# If nothing else found then default to version number
				default { "Unknown Version" }
			}
			return $Output
		}
		return $Output
	}
}
PROCESS
{
	foreach ($Server in $input)
	{
		if ($Server)
		{
			if ($Server.GetType().Name -eq 'ManagementServer')
			{
				if (!$setdefault)
				{
					$Servers = @()
					$setdefault = $true
				}
				$Servers += $Server.DisplayName
			}
			elseif ($Server.GetType().Name -eq 'AgentManagedComputer')
			{
				if (!$setdefault)
				{
					$Servers = @()
					$setdefault = $true
				}
				$Servers += $Server.DisplayName
			}
			elseif ($Server.GetType().Name -eq 'MonitoringObject')
			{
				if (!$setdefault)
				{
					$Servers = @()
					$setdefault = $true
				}
				$Servers += $Server.DisplayName
			}
		}
	}
	function Get-SCOMGeneralInfo
	{
		#The last major overhaul to this function was on 1/6/22
		param
		(
			[cmdletbinding()]
			[Parameter(Position = 1)]
			[array]$Servers
		)
		trap
		{
			#potential error code
			#use continue or break keywords
			#$e = $_.Exception
			$line = $_.InvocationInfo.ScriptLineNumber
			$msg = $e.Message
			
			Write-Verbose "Caught Exception: $($error[0]) at line: $line"
		}
		$Comp = $env:COMPUTERNAME
		Write-Progress -Activity "Collection Running" -Status "Progress-> 5%" -PercentComplete 10
		
		Write-Progress -Activity "Collection Running" -Status "Progress-> 10%" -PercentComplete 10
		foreach ($server in $Servers)
		{
			function Inner-GeneralInfoFunction
			{
				param
				(
					[cmdletbinding()]
					[switch]$LocalManagementServer
				)
				# Uncomment the below to turn on Verbose Output.
				#$VerbosePreference = 'Continue'
				trap
				{
					#potential error code
					#use continue or break keywords
					$e = $_.Exception
					$line = $_.InvocationInfo.ScriptLineNumber
					$msg = $e.Message
					
					Write-Verbose "Caught Exception: $e at line: $line"
				}
				Function Time-Stamp
				{
					$TimeStamp = Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
					return "$TimeStamp - "
				}
				
				#region AllServersGeneralInfo
				$ProductVersionScript = "function Get-ProductVersion { ${function:Get-ProductVersion} }"
				. ([ScriptBlock]::Create($ProductVersionScript))
				
				#=======================================================================
				# Start General Information Gather
				#=======================================================================
				# Get PowerShell Version section
				#=======================================================================
				$PSVer = $PSVersionTable.PSVersion
				[string]$PSMajor = $PSVer.Major
				[string]$PSMinor = $PSVer.Minor
				$PSVersion = $PSMajor + "." + $PSMinor
				#=======================================================================
				# Get PowerShell CLR Version section
				#=======================================================================
				$CLRVer = $PSVersionTable.CLRVersion
				[string]$CLRMajor = $CLRVer.Major
				[string]$CLRMinor = $CLRVer.Minor
				$CLRVersion = $CLRMajor + "." + $CLRMinor
				#=======================================================================
				$OSVersion = (Get-WMIObject win32_operatingsystem).Caption
				$Freespace = Get-PSDrive -PSProvider FileSystem | Select-Object @{ Name = 'Drive'; Expression = { $_.Root } }, @{ Name = "Used (GB)"; Expression = { "{0:###0.00}" -f ($_.Used / 1GB) } }, @{ Name = "Free (GB)"; Expression = { "{0:###0.00}" -f ($_.Free / 1GB) } }, @{ Name = "Total (GB)"; Expression = { "{0:###0.00}" -f (($_.Free / 1GB) + ($_.Used / 1GB)) } }
				$localServices = (Get-WmiObject Win32_service).where{ $_.name -eq 'omsdk' -or $_.name -eq 'cshost' -or $_.name -eq 'HealthService' -or $_.name -eq 'System Center Management APM' -or $_.name -eq 'AdtAgent' -or $_.name -match "MSSQLSERVER" -or $_.name -like "SQLAgent*" -or $_.name -eq 'SQLBrowser' -or $_.name -eq 'SQLServerReportingServices' } | Format-List @{ Label = "Service Display Name"; Expression = 'DisplayName' }, @{ Label = "Service Name"; Expression = 'Name' }, @{ Label = "Account Name"; Expression = 'StartName' }, @{ Label = "Start Mode"; Expression = 'StartMode' }, @{ Label = "Current State"; Expression = 'State' } | Out-String -Width 4096
				#=======================================================================
				# Build IP List from Windows Computer Property
				#=======================================================================
				#We want to remove Link local IP
				$ip = ([System.Net.Dns]::GetHostAddresses($Env:COMPUTERNAME)).IPAddressToString;
				[string]$IPList = ""
				$IPSplit = $IP.Split(",")
				FOREACH ($IPAddr in $IPSplit)
				{
					[string]$IPAddr = $IPAddr.Trim()
					IF (!($IPAddr.StartsWith("fe80") -or $IPAddr.StartsWith("169.254")))
					{
						$IPList = $IPList + $IPAddr + ","
					}
				}
				$IPList = $IPList.TrimEnd(",")
				#=======================================================================
				# Get TLS12Enforced Section
				#=======================================================================
				#Set the value to good by default then look for any bad or missing settings
				$TLS12Enforced = $True
				
				IF (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client")
				{
					$Enabled = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client").Enabled
					$DisabledByDefault = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client").DisabledByDefault
					IF ($Enabled -ne 0 -or $DisabledByDefault -ne 1)
					{
						$TLS12Enforced = $False
					}
				}
				ELSE
				{
					$TLS12Enforced = $False
				}
				
				IF (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server")
				{
					$Enabled = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server").Enabled
					$DisabledByDefault = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server").DisabledByDefault
					IF ($Enabled -ne 0 -or $DisabledByDefault -ne 1)
					{
						$TLS12Enforced = $False
					}
				}
				ELSE
				{
					$TLS12Enforced = $False
				}
				
				IF (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client")
				{
					$Enabled = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client").Enabled
					$DisabledByDefault = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client").DisabledByDefault
					IF ($Enabled -ne 0 -or $DisabledByDefault -ne 1)
					{
						$TLS12Enforced = $False
					}
				}
				ELSE
				{
					$TLS12Enforced = $False
				}
				
				IF (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server")
				{
					$Enabled = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server").Enabled
					$DisabledByDefault = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server").DisabledByDefault
					IF ($Enabled -ne 0 -or $DisabledByDefault -ne 1)
					{
						$TLS12Enforced = $False
					}
				}
				ELSE
				{
					$TLS12Enforced = $False
				}
				
				IF (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client")
				{
					$Enabled = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client").Enabled
					$DisabledByDefault = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client").DisabledByDefault
					IF ($Enabled -ne 0 -or $DisabledByDefault -ne 1)
					{
						$TLS12Enforced = $False
					}
				}
				ELSE
				{
					$TLS12Enforced = $False
				}
				
				IF (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server")
				{
					$Enabled = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server").Enabled
					$DisabledByDefault = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server").DisabledByDefault
					IF ($Enabled -ne 0 -or $DisabledByDefault -ne 1)
					{
						$TLS12Enforced = $False
					}
				}
				ELSE
				{
					$TLS12Enforced = $False
				}
				
				IF (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client")
				{
					$Enabled = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client").Enabled
					$DisabledByDefault = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client").DisabledByDefault
					IF ($Enabled -ne 0 -or $DisabledByDefault -ne 1)
					{
						$TLS12Enforced = $False
					}
				}
				ELSE
				{
					$TLS12Enforced = $False
				}
				
				IF (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server")
				{
					$Enabled = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server").Enabled
					$DisabledByDefault = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server").DisabledByDefault
					IF ($Enabled -ne 0 -or $DisabledByDefault -ne 1)
					{
						$TLS12Enforced = $False
					}
				}
				ELSE
				{
					$TLS12Enforced = $False
				}
				
				IF (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client")
				{
					$Enabled = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client").Enabled
					$DisabledByDefault = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client").DisabledByDefault
					IF ($Enabled -ne 1 -or $DisabledByDefault -ne 0)
					{
						$TLS12Enforced = $False
					}
				}
				ELSE
				{
					$TLS12Enforced = $False
				}
				
				IF (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server")
				{
					$Enabled = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server").Enabled
					$DisabledByDefault = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server").DisabledByDefault
					IF ($Enabled -ne 1 -or $DisabledByDefault -ne 0)
					{
						$TLS12Enforced = $False
					}
				}
				ELSE
				{
					$TLS12Enforced = $False
				}
				
				IF (Test-Path "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319")
				{
					$SchUseStrongCrypto = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319").SchUseStrongCrypto
					IF ($SchUseStrongCrypto -ne 1)
					{
						$TLS12Enforced = $False
					}
				}
				ELSE
				{
					$TLS12Enforced = $False
				}
				
				IF (Test-Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319")
				{
					$SchUseStrongCrypto = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319").SchUseStrongCrypto
					IF ($SchUseStrongCrypto -ne 1)
					{
						$TLS12Enforced = $False
					}
				}
				ELSE
				{
					$TLS12Enforced = $False
				}
				#endregion AllServersGeneralInfo
				Add-Type -TypeDefinition @"
public class OpsMgrSetupRegKey{
    public string CurrentVersion;
    public string DatabaseName;
    public string DatabaseServerName;
    public string DatabaseVersion;
    public string DataWarehouseDBName;
    public string DataWarehouseDBServerName;
    public string InstallDirectory;
    public string InstalledOn;
    public string ManagementServerPort;
    public string Product;
    public string ServerVersion;
    public string UIVersion;
}
"@
				
				# this is the path we want to retrieve the values from
				$opsMgrSetupRegKeyPath = 'HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup'
				
				# get the values
				try
				{
					$opsMgrSetupRegKey = Get-ItemProperty -Path $opsMgrSetupRegKeyPath -ErrorAction Stop
					
					# construct a new object
					$setuplocation = New-Object OpsMgrSetupRegKey
					
					#set the object values from the registry key
					$setuplocation.CurrentVersion = $opsMgrSetupRegKey.CurrentVersion
					$setuplocation.DatabaseName = $opsMgrSetupRegKey.DatabaseName
					$setuplocation.DatabaseServerName = $opsMgrSetupRegKey.DatabaseServerName
					$setuplocation.DatabaseVersion = $opsMgrSetupRegKey.DatabaseVersion
					$setuplocation.DataWarehouseDBName = $opsMgrSetupRegKey.DataWarehouseDBName
					$setuplocation.DataWarehouseDBServerName = $opsMgrSetupRegKey.DataWarehouseDBServerName
					$setuplocation.InstallDirectory = $opsMgrSetupRegKey.InstallDirectory
					$setuplocation.InstalledOn = $opsMgrSetupRegKey.InstalledOn
					$setuplocation.ManagementServerPort = $opsMgrSetupRegKey.ManagementServerPort
					$setuplocation.Product = $opsMgrSetupRegKey.Product
					$setuplocation.ServerVersion = $opsMgrSetupRegKey.ServerVersion
					$setuplocation.UIVersion = $opsMgrSetupRegKey.UIVersion
					
					$Agent = $false
					$ManagementServer = $false
					$Gateway = $false
				}
				catch
				{
					$setuplocation = $null
				}
				if ($setuplocation)
				{
					if ($setuplocation.Product -eq "Microsoft Monitoring Agent")
					{
						$Agent = $true
						$installdir = (Resolve-Path "$($setuplocation.InstallDirectory)`..\")
					}
					elseif ($setuplocation.Product -like "System Center Operations Manager*Server")
					{
						$ManagementServer = $true
						$installdir = (Resolve-Path "$($setuplocation.InstallDirectory)`..\")
						$SCOMPath = $installdir.Path.TrimEnd("\")
						if ($LocalManagementServer)
						{
							$global:localLocation = $installdir
						}
						if ($setuplocation.InstallDirectory -like "*Gateway*")
						{
							$Gateway = $true
						}
					}
					$healthServiceState = Get-ItemProperty "$($setuplocation.InstallDirectory)\Health Service State"
					
					function Get-FolderSize
					{
						
						Begin
						{
							
							$fso = New-Object -comobject Scripting.FileSystemObject
						}
						
						Process
						{
							
							$Path = $input.Fullname
							$Folder = $Fso.GetFolder($Path)
							$DateModified = $Folder.DateLastModified
							$DateCreated = $Folder.DateCreated
							$Size = $Folder.Size
							[PSCustomObject]@{ Location = $Path; Size = (Format-FileSize $Size); Modified = $DateModified; Created = $DateCreated }
						}
					}
					
					Function Format-FileSize($size)
					{
						# Param ([int]$size)
						If ($size -gt 1TB) { [string]::Format("{0:0.00} TB", $size / 1TB) }
						ElseIf ($size -gt 1GB) { [string]::Format("{0:0.00} GB", $size / 1GB) }
						ElseIf ($size -gt 1MB) { [string]::Format("{0:0.00} MB", $size / 1MB) }
						ElseIf ($size -gt 1KB) { [string]::Format("{0:0.00} kB", $size / 1KB) }
						ElseIf ($size -gt 0) { [string]::Format("{0:0.00} B", $size) }
						Else { "" }
					}
					$HSStateFolder = $healthServiceState | Get-FolderSize
					
					try
					{
						$configUpdated = @()
						Write-Verbose "Grabbing Connector Configuration Cache on $env:COMPUTERNAME"
						$mgsFound = Get-ChildItem -Path "$($HSStateFolder.Location)\Connector Configuration Cache" -ErrorAction Stop
						Write-Verbose "Management Groups Found: $mgsFound"
						foreach ($ManagementGroup in $mgsFound)
						{
							Write-Verbose "Current Management Group: $ManagementGroup"
							$HSConfigInformation = $null
							$HSConfigInformation = [pscustomobject] @{ }
							$HSConfigInformation | Add-Member -MemberType NoteProperty -Name 'Management Group Name' -Value $ManagementGroup.Name
							try
							{
								Write-Verbose "Get-ItemProperty `"$($ManagementGroup.PSPath)\OpsMgrConnector.Config.xml`""
								$LastUpdated = ((Get-ItemProperty "$($ManagementGroup.PSPath)\OpsMgrConnector.Config.xml" -ErrorAction Stop).LastWriteTime | Get-Date -Format "MMMM dd, yyyy h:mm tt")
								$HSConfigInformation | Add-Member -MemberType NoteProperty -Name 'Last Time Configuration Updated' -Value $($LastUpdated)
							}
							catch
							{
								Write-Verbose "Could not detect file: OpsMgrConnector.Config.xml"
								$HSConfigInformation | Add-Member -MemberType NoteProperty -Name 'Last Time Configuration Updated' -Value 'Could not detect file: OpsMgrConnector.Config.xml'
							}
							Write-Verbose "Adding: $HSConfigInformation"
							$configUpdated += $HSConfigInformation
						}
						Write-Verbose "Completed: $configUpdated"
					}
					catch
					{
						Write-Verbose $error[0]
						$configUpdated = $false
					}
				}
				
				#Start SCOM Management Server, Agent, and Gateway Related Gathering.
				if ($ManagementServer)
				{
					#=======================================================================
					# Get Certificate Section
					#=======================================================================
					$CertRegKey = "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Machine Settings"
					IF (Test-Path $CertRegKey)
					{
						[array]$CertValue = (Get-ItemProperty $CertRegKey).ChannelCertificateSerialNumber
						IF ($Certvalue)
						{
							$CertLoaded = $True
							[string]$ThumbPrint = (Get-ItemProperty $CertRegKey).ChannelCertificateHash
							$Cert = Get-ChildItem -path cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $ThumbPrint }
							IF ($Cert)
							{
								[datetime]$CertExpiresDateTime = $Cert.NotAfter
								[string]$CertExpires = $CertExpiresDateTime.ToShortDateString()
								$CertIssuerArr = $Cert.Issuer
								$CertIssuerSplit = $CertIssuerArr.Split(",")
								[string]$CertIssuer = $CertIssuerSplit[0].TrimStart("CN=")
							}
							ELSE
							{
								$CertIssuer = "NotFound"
								$CertExpires = "NotFound"
							}
							
						}
						ELSE
						{
							$CertLoaded = $False
						}
					}
					ELSE
					{
						$CertLoaded = $False
					}
					
					$ManagementServers = (Get-SCOMManagementServer).DisplayName
					$ServerVersionSwitch = (Get-ProductVersion -Product SCOM -BuildVersion $setuplocation.ServerVersion)
					$LocalServerVersionSwitchOut = $ServerVersionSwitch + " (" + $setuplocation.ServerVersion + ")"
					
					$serverdll = Get-Item "$($setuplocation.InstallDirectory)`MOMAgentManagement.dll" | foreach-object { "{0}" -f [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_).FileVersion }
					$ServerVersionDLLSwitch = (Get-ProductVersion -Product SCOM -BuildVersion $serverdll)
					$ServerVersionDLL = $ServerVersionDLLSwitch + " (" + $serverdll + ")"
					
					$OctoberPatchserverDLL = Get-Item "$($setuplocation.InstallDirectory)`MOMModules2.dll" | foreach-object { "{0}" -f [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_).FileVersion }
					$OctoberPatchserverDLLSwitch = (Get-ProductVersion -Product SCOM -BuildVersion $OctoberPatchserverDLL)
					$OctoberPatchserver = $OctoberPatchserverDLLSwitch + " (" + $OctoberPatchserverDLL + ")"
					try
					{
						$ServerAgentOMVersionDLL = Get-Item "$($setuplocation.InstallDirectory)`\AgentManagement\amd64\OMVersion.dll" -ErrorAction Stop | foreach-object { "{0}" -f [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_).FileVersion }
						if ($ServerAgentOMVersionDLL)
						{
							$ServerAgentVersionDLLSwitch = (Get-ProductVersion -Product SCOM -BuildVersion $ServerAgentOMVersionDLL)
							$ServerAgentVersionDLL = $ServerAgentVersionDLLSwitch + " (" + $ServerAgentOMVersionDLL + ")"
							$ServerAgentVersion_info = $true
						}
						$ServerAgentUnixVersionDLL = Get-ItemProperty "$($setuplocation.InstallDirectory)`\AgentManagement\UnixAgents\DownloadedKits\*" -ErrorAction Stop | Format-Table Name -AutoSize | Out-String -Width 4096
					}
					catch
					{
						$ServerAgentVersion_info = $false
					}
					try
					{
						$UIExe = Get-Item "$($setuplocation.InstallDirectory)`..\Console\Microsoft.EnterpriseManagement.Monitoring.Console.exe" -ErrorAction Stop | foreach-object { "{0}" -f [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_).FileVersion }
						if (($setuplocation.UIVersion) -and ($UIExe))
						{
							$UIVersionSwitch = (Get-ProductVersion -Product SCOM -BuildVersion $setuplocation.UIVersion)
							$UIVersionFinal = $UIVersionSwitch + " (" + $setuplocation.UIVersion + ")"
							
							$UIVersionExeSwitch = (Get-ProductVersion -Product SCOM -BuildVersion $UIExe)
							$UIVersionExe = $UIVersionExeSwitch + " (" + $UIExe + ")"
							$UI_info = $true
						}
						
					}
					catch
					{
						$UI_info = $false
					}
					try
					{
						$WebConsoleDLL = Get-Item "$($setuplocation.InstallDirectory)`..\WebConsole\WebHost\bin\Microsoft.Mom.Common.dll" -ErrorAction SilentlyContinue | foreach-object { "{0}" -f [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_).FileVersion }
						if ($null -eq $WebConsoleDLL)
						{
							$WebConsoleDLL = Get-Item "$($setuplocation.InstallDirectory)`..\WebConsole\Microsoft.Mom.Common.dll" -ErrorAction Stop | foreach-object { "{0}" -f [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_).FileVersion }
						}
						$WebConsoleDLLSwitch = (Get-ProductVersion -Product SCOM -BuildVersion $WebConsoleDLL)
						$WebConsoleVersionDLL = $WebConsoleDLLSwitch + " (" + $WebConsoleDLL + ")"
						
						$WebConsolePatchDLL = Get-Item "$($setuplocation.InstallDirectory)`..\WebConsole\AppDiagnostics\AppAdvisor\Web\Bin\ARViewer.dll" -ErrorAction Stop | foreach-object { "{0}" -f [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_).FileVersion }
						$WebConsolePatchSwitch = (Get-ProductVersion -Product SCOM -BuildVersion $WebConsolePatchDLL)
						$WebConsolePatchVersionDLL = $WebConsolePatchSwitch + " (" + $WebConsolePatchDLL + ")"
						
						$WebConsole_info = $true
					}
					catch { $WebConsole_info = $false }
					$CurrentVersionSwitch = (Get-ProductVersion -Product SCOM -BuildVersion $setuplocation.CurrentVersion)
					$CurrentVersionFinal = $CurrentVersionSwitch + " (" + $setuplocation.CurrentVersion + ")"
					
					$ReportingRegistryKey = get-itemproperty -path "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Reporting" -ErrorAction SilentlyContinue | Select-Object * -exclude PSPath, PSParentPath, PSChildName, PSProvider, PSDrive
					if ($LocalManagementServer)
					{
						try
						{
							$OMSQLPropertiesImport = Import-Csv "$OutputPath`\SQL_Properties_OpsDB.csv"
							##########################################
							#########################################
							#####################################
							################################
							$OMSQLVersionSwitch = (Get-ProductVersion -Product SQL -BuildVersion $OMSQLPropertiesImport.ProductVersion)
							$OMSQLProperties = $OMSQLVersionSwitch + "`n(" + ($OMSQLPropertiesImport).ProductVersion + ") -" + " (" + ($OMSQLPropertiesImport).ProductLevel + ")" + " - " + ($OMSQLPropertiesImport).Edition + " - " + ($OMSQLPropertiesImport).Version
							if ($OMSQLPropertiesImport.IsClustered -eq 1)
							{
								$OMSQLProperties = $OMSQLProperties + "`n" + "[Clustered]"
							}
							else
							{
								$OMSQLProperties = $OMSQLProperties + "`n" + "[Not Clustered]"
							}
							try
							{
								if ('TRUE' -match $OMSQLPropertiesImport.Is_Broker_Enabled)
								{
									$OMSQLProperties = $OMSQLProperties + "`n" + "[Broker Enabled]"
								}
								else
								{
									$OMSQLProperties = $OMSQLProperties + "`n" + "[Broker Not Enabled]"
								}
							}
							catch
							{
								$OMSQLProperties = $OMSQLProperties + "`n" + "[Broker Not Found or Disabled]"
							}
							try
							{
								if ('TRUE' -match $OMSQLPropertiesImport.Is_CLR_Enabled)
								{
									$OMSQLProperties = $OMSQLProperties + "`n" + "[CLR Enabled]"
								}
								else
								{
									$OMSQLProperties = $OMSQLProperties + "`n" + "[CLR Not Enabled]"
								}
							}
							catch
							{
								$OMSQLProperties = $OMSQLProperties + "`n" + "[CLR Not Found or Disabled]"
							}
							if (1 -eq $OMSQLPropertiesImport.IsFullTextInstalled)
							{
								$OMSQLProperties = $OMSQLProperties + "`n" + "[FullText Installed]"
							}
							else
							{
								$OMSQLProperties = $OMSQLProperties + "`n" + "[FullText Not Installed]"
							}
							if ($OMSQLPropertiesImport.Collation -notmatch "SQL_Latin1_General_CP1_CI_AS|Latin1_General_CI_AS|Latin1_General_100_CI_AS|French_CI_AS|French_100_CI_AS|Cyrillic_General_CI_AS|Chinese_PRC_CI_AS|Chinese_Simplified_Pinyin_100_CI_AS|Chinese_Traditional_Stroke_Count_100_CI_AS|Japanese_CI_ASJapanese_XJIS_100_CI_AS|Traditional_Spanish_CI_AS|Modern_Spanish_100_CI_AS|Latin1_General_CI_AS|Cyrillic_General_100_CI_AS|Korean_100_CI_AS|Czech_100_CI_AS|Hungarian_100_CI_AS|Polish_100_CI_AS|Finnish_Swedish_100_CI_AS")
							{
								$OMSQLProperties = $OMSQLProperties + "`n" + "(ISSUE: " + $OMSQLPropertiesImport.Collation + ") <------------"
							}
							$OMSQLProperties = $OMSQLProperties + "`n"
						}
						catch
						{
							
							#potential error code
							#use continue or break keywords
							#$e = $_.Exception
							$line = $_.InvocationInfo.ScriptLineNumber
							$msg = $e.Message
							
							Write-Verbose "Caught Exception: $($error[0]) at line: $line"
							"$(Time-Stamp)Caught Exception: $($error[0]) at line: $line" | Out-File $OutputPath\Error.log -Append
						}
						
						try
						{
							$DWSQLPropertiesImport = Import-Csv "$OutputPath`\SQL_Properties_DW.csv"
							##########################################
							#########################################
							#####################################
							################################
							$DWSQLVersionSwitch = (Get-ProductVersion -Product SQL -BuildVersion $DWSQLPropertiesImport.ProductVersion)
							$DWSQLProperties = $DWSQLVersionSwitch + "`n(" + ($DWSQLPropertiesImport).ProductVersion + ") - (" + ($DWSQLPropertiesImport).ProductLevel + ") - " + ($DWSQLPropertiesImport).Edition + " - " + ($DWSQLPropertiesImport).Version
							if ($DWSQLPropertiesImport.IsClustered -eq 1)
							{
								$DWSQLProperties = $DWSQLProperties + "`n" + "[Clustered]"
							}
							else
							{
								$DWSQLProperties = $DWSQLProperties + "`n" + "[Not Clustered]"
							}
							try
							{
								if ('TRUE' -match $DWSQLPropertiesImport.Is_Broker_Enabled)
								{
									$DWSQLProperties = $DWSQLProperties + "`n" + "[Broker Enabled]"
								}
								else
								{
									$DWSQLProperties = $DWSQLProperties + "`n" + "[Broker Not Enabled]"
								}
							}
							catch
							{
								$DWSQLProperties = $DWSQLProperties + "`n" + "[Broker Not Found or Disabled]"
							}
							if ($DWSQLPropertiesImport.IsFullTextInstalled -eq 1)
							{
								$DWSQLProperties = $DWSQLProperties + "`n" + "[FullText Installed]"
							}
							else
							{
								$DWSQLProperties = $DWSQLProperties + "`n" + "[FullText Not Installed]"
							}
							if ($DWSQLPropertiesImport.Collation -notmatch "SQL_Latin1_General_CP1_CI_AS|Latin1_General_CI_AS|Latin1_General_100_CI_AS|French_CI_AS|French_100_CI_AS|Cyrillic_General_CI_AS|Chinese_PRC_CI_AS|Chinese_Simplified_Pinyin_100_CI_AS|Chinese_Traditional_Stroke_Count_100_CI_AS|Japanese_CI_ASJapanese_XJIS_100_CI_AS|Traditional_Spanish_CI_AS|Modern_Spanish_100_CI_AS|Latin1_General_CI_AS|Cyrillic_General_100_CI_AS|Korean_100_CI_AS|Czech_100_CI_AS|Hungarian_100_CI_AS|Polish_100_CI_AS|Finnish_Swedish_100_CI_AS")
							{
								$DWSQLProperties = $DWSQLProperties + "`n" + "(ISSUE: " + $DWSQLPropertiesImport.Collation + ") <------------"
							}
						}
						catch
						{
							#potential error code
							#use continue or break keywords
							#$e = $_.Exception
							$line = $_.InvocationInfo.ScriptLineNumber
							$msg = $e.Message
							
							Write-Verbose "Caught Exception: $($error[0]) at line: $line"
							"$(Time-Stamp)Caught Exception: $($error[0]) at line: $line" | Out-File $OutputPath\Error.log -Append
						}
					}
					
					try
					{
						$rmsEmulator = Get-SCOMRMSEmulator -ErrorAction Stop | Select-Object -Property DisplayName -ExpandProperty DisplayName
					}
					catch
					{
						$rmsEmulator = "Unable to run Get-SCOMRMSEmulator."
					}
					
					
					try
					{
						$ManagementGroup = Get-SCOMManagementGroup -ErrorAction Stop | Select-Object -Property Name -ExpandProperty Name
					}
					catch
					{
						$ManagementGroup = "Unable to run Get-SCOMManagementGroup."
					}
					$LastUpdatedConfiguration = (Get-WinEvent -LogName 'Operations Manager' -ErrorAction SilentlyContinue | Where{ $_.Id -eq 1210 } | Select-Object -First 1).TimeCreated
					if (!$LastUpdatedConfiguration) { $LastUpdatedConfiguration = "No Event ID 1210 Found in Operations Manager Event Log" }
					else { $LastUpdatedConfiguration = $LastUpdatedConfiguration | Get-Date -Format "MMMM dd, yyyy h:mm tt" }
					
					[double]$WorkflowCount = $null
					[double]$WorkflowCount = (((Get-Counter -Counter '\Health Service\Workflow Count' -ErrorAction SilentlyContinue -SampleInterval 5 -MaxSamples 5).CounterSamples).CookedValue | Measure-Object -Average).Average
					#=======================================================================
					
					$ACSReg = "HKLM:\SYSTEM\CurrentControlSet\Services\AdtServer"
					IF (Test-Path $ACSReg)
					{
						#This is an ACS Collector server
						$ACS = $true
						
					}
					ELSE
					{
						#This is NOT an ACS Collector server
						$ACS = $false
						
					}
					try
					{
						if ($LocalManagementServer)
						{
							$dbOutput = [pscustomobject]@{ }
							$dbOutput | Add-Member -MemberType NoteProperty -Name 'Operations Manager DB Server Name' -Value $setuplocation.DatabaseServerName -ErrorAction SilentlyContinue
							$dbOutput | Add-Member -MemberType NoteProperty -Name 'Operations Manager DB Name' -Value $setuplocation.DatabaseName -ErrorAction SilentlyContinue
							$dbOutput | Add-Member -MemberType NoteProperty -Name 'Operations Manager SQL Properties' -Value $OMSQLProperties -ErrorAction SilentlyContinue
							$dbOutput | Add-Member -MemberType NoteProperty -Name 'Data Warehouse DB Server Name' -Value $setuplocation.DataWarehouseDBServerName -ErrorAction SilentlyContinue
							$dbOutput | Add-Member -MemberType NoteProperty -Name 'Data Warehouse DB Name' -Value $setuplocation.DataWarehouseDBName -ErrorAction SilentlyContinue
							$dbOutput | Add-Member -MemberType NoteProperty -Name 'Data Warehouse SQL Properties' -Value $DWSQLProperties -ErrorAction SilentlyContinue
						}
						
						if ($LocalManagementServer)
						{
							$foundsomething = $false
							try
							{
								$UserRolesImport = Import-Csv "$OutputPath`\UserRoles.csv"
								$UserRoles = "User Role Name" + " - " + "Is System?" + "`n----------------------------`n"
								$UserRolesImport | % {
									if ($_.IsSystem -eq $false)
									{
										$foundsomething = $true
										$UserRoles += $_.UserRoleName + " - " + $_.IsSystem + "`n"
									}
								}
								if ($foundsomething)
								{
									$dbOutput | Add-Member -MemberType NoteProperty -Name 'User Roles (Non-Default)' -Value $UserRoles
								}
							}
							catch
							{
								#potential error code
								#use continue or break keywords
								#$e = $_.Exception
								$line = $_.InvocationInfo.ScriptLineNumber
								$msg = $e.Message
								
								Write-Verbose "Caught Exception: $($error[0]) at line: $line"
								"$(Time-Stamp)Caught Exception: $($error[0]) at line: $line" | Out-File $OutputPath\Error.log -Append
							}
						}
					}
					catch
					{
						Write-Warning $error[0]
					}
					
				}
				elseif ($Agent)
				{
					
					#$ManagementGroups = Get-Item "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Agent Management Groups\*" | Select-Object PSChildName -ExpandProperty PSChildName
					$ADIntegration = (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\HealthService\Parameters\ConnectorManager).EnableADIntegration
					
					$ADIntegrationSwitch = switch ($ADIntegration)
					{
						'0' { "Disabled" }
						'1' { "Enabled" }
					}
					
					$LastUpdatedConfiguration = (Get-WinEvent -LogName 'Operations Manager' | Where{ $_.Id -eq 1210 } | Select-Object -First 1).TimeCreated
					if (!$LastUpdatedConfiguration) { $LastUpdatedConfiguration = "No Event ID 1210 Found in Operations Manager Event Log" }
					else { $LastUpdatedConfiguration = $LastUpdatedConfiguration | Get-Date -Format "MMMM dd, yyyy h:mm tt" }
					
					[string]$SCOMAgentURVersion = (Get-ProductVersion -Product SCOM -BuildVersion $setuplocation.CurrentVersion)
					
					# Load Agent Scripting Module
					#=======================================================================
					$AgentCfg = New-Object -ComObject "AgentConfigManager.MgmtSvcCfg"
					#=======================================================================
					
					# Get Agent Management groups section
					#=======================================================================
					#Get management groups
					$MGs = $AgentCfg.GetManagementGroups()
					$MGDetails = @()
					foreach ($MG in $MGs)
					{
						$MGDetails += $MG | Select *
					<#
				    $managementGroup.ManagementGroupName
				    $managementGroup.ManagementServer
				    $managementGroup.ManagementServerPort
				    $managementGroup.IsManagementGroupFromActiveDirectory
				    $managementGroup.ActionAccount
				    #>
					}
					# Get Agent OMS Workspaces section
					#=======================================================================
					# This section depends on AgentConfigManager.MgmtSvcCfg object in previous section
					[string]$OMSList = ''
					# Agent might not support OMS
					$AgentSupportsOMS = $AgentCfg | Get-Member -Name 'GetCloudWorkspaces'
					IF (!$AgentSupportsOMS)
					{
						#This agent version does not support Cloud Workspaces.
					}
					ELSE
					{
						$OMSWorkSpaces = $AgentCfg.GetCloudWorkspaces()
						FOREACH ($OMSWorkSpace in $OMSWorkSpaces)
						{
							$OMSList = $OMSList + $OMSWorkspace.workspaceId + ", "
						}
						IF ($OMSList)
						{
							$OMSList = $OMSList.TrimEnd(", ")
						}
						
						#Get ProxyURL
						[string]$ProxyURL = $AgentCfg.proxyUrl
					}
					
					#=======================================================================
					# Get Certificate Section
					#=======================================================================
					$CertRegKey = "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Machine Settings"
					IF (Test-Path $CertRegKey)
					{
						[array]$CertValue = (Get-ItemProperty $CertRegKey).ChannelCertificateSerialNumber
						IF ($Certvalue)
						{
							$CertLoaded = $True
							[string]$ThumbPrint = (Get-ItemProperty $CertRegKey).ChannelCertificateHash
							$Cert = Get-ChildItem -path cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $ThumbPrint }
							IF ($Cert)
							{
								[datetime]$CertExpiresDateTime = $Cert.NotAfter
								[string]$CertExpires = $CertExpiresDateTime.ToShortDateString()
								$CertIssuerArr = $Cert.Issuer
								$CertIssuerSplit = $CertIssuerArr.Split(",")
								[string]$CertIssuer = $CertIssuerSplit[0].TrimStart("CN=")
							}
							ELSE
							{
								$CertIssuer = "NotFound"
								$CertExpires = "NotFound"
							}
							
						}
						ELSE
						{
							$CertLoaded = $False
						}
					}
					ELSE
					{
						$CertLoaded = $False
					}
					# Build IP List from Windows Computer Property
					#=======================================================================
					#We want to remove Link local IP
					$ip = ([System.Net.Dns]::GetHostAddresses($Env:COMPUTERNAME)).IPAddressToString;
					[string]$IPList = ""
					$IPSplit = $IP.Split(",")
					FOREACH ($IPAddr in $IPSplit)
					{
						[string]$IPAddr = $IPAddr.Trim()
						IF (!($IPAddr.StartsWith("fe80") -or $IPAddr.StartsWith("169.254")))
						{
							$IPList = $IPList + $IPAddr + ","
						}
					}
					$IPList = $IPList.TrimEnd(",")
					$SCOMAgentVersion = $SCOMAgentURVersion + " (" + $setuplocation.AgentVersion + ")"
					
					$AgentURDLL = Get-Item "$($setuplocation.InstallDirectory)`..\Agent\Tools\TMF\OMAgentTraceTMFVer.Dll" -ErrorAction SilentlyContinue | foreach-object { "{0}" -f [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_).FileVersion }
					[string]$SCOMAgentURVersionDLL = (Get-ProductVersion -Product SCOM -BuildVersion $AgentURDLL)
					$SCOMAgentVersionDLL = $SCOMAgentURVersionDLL + " (" + $AgentURDLL + ")"
				}
				elseif ($Gateway)
				{
					$GatewayDLL = Get-Item "$($setuplocation.InstallDirectory)`..\Gateway\MOMAgentManagement.dll" | foreach-object { "{0}" -f [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_).FileVersion }
				}
				
				$setupOutput = [pscustomobject]@{ }
				$setupOutput | Add-Member -MemberType NoteProperty -Name 'Computer Name' -Value $env:COMPUTERNAME
				if ($WorkflowCount)
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'Workflow Count' -Value $WorkflowCount
				}
				$setupOutput | Add-Member -MemberType NoteProperty -Name 'IP Address' -Value $IPList
				$setupOutput | Add-Member -MemberType NoteProperty -Name 'OS Version' -Value $OSVersion
				if ($setuplocation)
				{
					if ($setuplocation.ManagementServerPort)
					{
						$setupOutput | Add-Member -MemberType NoteProperty -Name 'Management Server Port' -Value $setuplocation.ManagementServerPort
					}
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'Product' -Value $setuplocation.Product
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'Installed On' -Value $setuplocation.InstalledOn
				}
				if ($ACS)
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'ACS Collector' -Value 'True'
				}
				else
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'ACS Collector' -Value 'False'
				}
				if ($SCOMAgentVersion)
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'Current Agent Version (Registry: HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup)' -Value $SCOMAgentVersion
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'Current Agent Version (DLL: ..\Agent\Tools\TMF\OMAgentTraceTMFVer.Dll)' -Value $SCOMAgentVersionDLL
				}
				if ($CurrentVersionFinal)
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'Current Version (Registry: HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup)' -Value $CurrentVersionFinal
				}
				if ($LocalServerVersionSwitchOut)
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'Server Version (Registry: HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup)' -Value $LocalServerVersionSwitchOut
					$setupOutput | Add-Member -MemberType NoteProperty -Name '               (DLL: ..\Server\MOMAgentManagement.dll)' -Value $ServerVersionDLL
				}
				if ('10.19.10552.0' -eq $OctoberPatchserverDLL)
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'Server Version [Patch] (DLL: ..\Server\MOMModules2.dll)' -Value $OctoberPatchserver
				}
				if ($ServerAgentVersion_info)
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'Agent Management Windows Version (DLL: ..\Server\AgentManagement\amd64\OMVersion.dll)' -Value $ServerAgentVersionDLL
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'Agent Management Unix/Linux Versions (Files: ..\Server\AgentManagement\UnixAgents\DownloadedKits\*)' -Value $ServerAgentUnixVersionDLL
				}
				
				if ($UI_info)
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'UI Version (Registry: HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup)' -Value $UIVersionFinal
					$setupOutput | Add-Member -MemberType NoteProperty -Name '           (EXE: ..\Console\Microsoft.EnterpriseManagement.Monitoring.Console.exe)' -Value $UIVersionExe
				}
				if ($WebConsole_info)
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'Web Console Version (DLL: ..\WebConsole\WebHost\bin\Microsoft.Mom.Common.dll)' -Value $WebConsoleVersionDLL
					if ('10.19.10550.0' -eq $WebConsolePatchDLL)
					{
						$setupOutput | Add-Member -MemberType NoteProperty -Name 'Web Console Version [Patch] (DLL: ..\WebConsole\AppDiagnostics\AppAdvisor\Web\Bin\ARViewer.dll)' -Value $WebConsolePatchVersionDLL
					}
				}
				if ($ADIntegrationSwitch)
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'AD Integration' -Value $ADIntegrationSwitch
				}
				
				if ($setuplocation)
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'Installation Directory' -Value $setuplocation.InstallDirectory
				}
				if ($MGDetails)
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name '(Agent) Management Group Details' -Value ($MGDetails | Format-List * | Out-String -Width 4096)
				}
				elseif ($MGlist)
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name '(Agent) Management Group Name' -Value $MGlist
				}
				elseif ($ManagementGroup)
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name '(Management Server) Management Group Name' -Value $ManagementGroup
				}
				if ($ManagementServers)
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'Management Servers in Management Group' -Value (($ManagementServers | Sort-Object) -join ", ")
				}
				if ($OMSList)
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'Agent OMS Workspaces' -Value $OMSList
				}
				if ($ProxyURL)
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'Proxy URL' -Value $ProxyURL
				}
				
				if ($rmsEmulator)
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'Remote Management Server Emulator (Primary Server)' -Value "$rmsEmulator"
				}
				$setupOutput | Add-Member -MemberType NoteProperty -Name 'Free Space' -Value $($Freespace | Format-Table * | Out-String -Width 4096)
				if ($CertLoaded)
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'Certificate Loaded' -Value $CertLoaded
				}
				else
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'Certificate Loaded' -Value 'Unable to detect any certificate in registry.'
				}
				$setupOutput | Add-Member -MemberType NoteProperty -Name 'TLS 1.2 Enforced' -Value $TLS12Enforced
				$setupOutput | Add-Member -MemberType NoteProperty -Name 'Powershell Version' -Value $PSVersion
				$setupOutput | Add-Member -MemberType NoteProperty -Name 'CLR Version' -Value $CLRVersion
				if ($setuplocation)
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'Health Service State Directory' -Value $($HSStateFolder | Format-Table * -AutoSize | Out-String -Width 4096)
				}
				if ($configUpdated)
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'Last Time Configuration Updated (File: ..\OpsMgrConnector.Config.xml)' -Value $($configUpdated | Format-Table -AutoSize | Out-String -Width 4096)
				}
				if ($LastUpdatedConfiguration)
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'Last Time Configuration Updated (1210 EventID)' -Value $LastUpdatedConfiguration
				}
				else
				{
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'Last Time Configuration Updated (1210 EventID)' -Value 'Unable to locate 1210 EventID.'
				}
				$setupOutput | Add-Member -MemberType NoteProperty -Name 'Current System Time' -Value (Get-Date -Format "MMMM dd, yyyy h:mm tt")
				
				if ('7.2.11719.0' -ge $setuplocation.ServerVersion) # SCOM 2016 RTM
				{
					try { $UseMIAPI = (Get-Item 'HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup\UseMIAPI' -ErrorAction Stop | Select-Object Name, Property).Property } # https://docs.microsoft.com/en-us/system-center/scom/whats-new-in-om?view=sc-om-2019#scalability-improvement-with-unix-or-linux-agent-monitoring
					catch [System.Management.Automation.RuntimeException]{ $UseMIAPI = 'Not Set (or Unknown)' }
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'UseMIAPI Registry' -Value $UseMIAPI
				}
				$ReportingRegistryKey = get-itemproperty -path "HKLM:\SOFTWARE\Microsoft\System Center Operations Manager\12\Setup\Reporting" -ErrorAction SilentlyContinue | Select-Object * -exclude PSPath, PSParentPath, PSChildName, PSProvider, PSDrive
				if ($ReportingRegistryKey)
				{
						<#
$setupOutputRemote += @"

================================ `
=---- Reporting Server ----= `
================================
"@
#>
					$ReportingInstallPath = $ReportingRegistryKey.InstallDirectory
					$ReportingDLL = Get-Item "$ReportingInstallPath`\Tools\TMF\OMTraceTMFVer.Dll" -ErrorAction Stop | foreach-object { "{0}" -f [System.Diagnostics.FileVersionInfo]::GetVersionInfo($_).FileVersion }
					$ReportingProductVersionSwitch = (Get-ProductVersion -Product SCOM -BuildVersion $ReportingDLL)
					$ReportingInfo = $ReportingProductVersionSwitch + " (" + $ReportingDLL + ")"
					$setupOutput | Add-Member -MemberType NoteProperty -Name 'Reporting Services Version (DLL: ..\Reporting\Tools\TMF\OMTraceTMFVer.dll)' -Value $ReportingInfo
					try
					{
						
						$RS = "root\Microsoft\SqlServer\ReportServer\" + (Get-WmiObject -Namespace root\Microsoft\SqlServer\ReportServer -Class __Namespace -Recurse -ErrorAction Stop | Select -First 1).Name
						$RSV = $RS + "\" + (Get-WmiObject -Namespace $RS -Class __Namespace -Recurse -ErrorAction Stop | Select -First 1).Name + "\Admin"
						$RSInfo = Get-WmiObject -Namespace $RSV -Class MSReportServer_ConfigurationSetting -ErrorAction Stop
						
						try
						{
							$RSInfoSwitch = (Get-ProductVersion -Product SSRS -BuildVersion $RSInfo.Version)
							$RSInfoSwitchInfo = $RSInfoSwitch + " (" + $RSInfo.Version + ")"
						}
						catch
						{
							$RSInfoSwitchInfo = "Unable to detect / return Product version for SSRS"
							Write-Verbose "Unable to detect / return Product version for SSRS: $($error[0])"
						}
						
						$SSRS_Info = [pscustomobject]@{ }
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'ConnectionPoolSize' -Value $RSInfo.ConnectionPoolSize -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'DatabaseLogonAccount' -Value $RSInfo.DatabaseLogonAccount -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'DatabaseLogonTimeout' -Value $RSInfo.DatabaseLogonTimeout -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'DatabaseLogonType' -Value $RSInfo.DatabaseLogonType -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'DatabaseName' -Value $RSInfo.DatabaseName -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'DatabaseQueryTimeout' -Value $RSInfo.DatabaseQueryTimeout -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'ExtendedProtectionLevel' -Value $RSInfo.ExtendedProtectionLevel -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'ExtendedProtectionScenario' -Value $RSInfo.ExtendedProtectionScenario -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'FileShareAccount' -Value $RSInfo.FileShareAccount -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'InstanceName' -Value $RSInfo.InstanceName -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'IsInitialized' -Value $RSInfo.IsInitialized -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'IsPowerBIFeatureEnabled' -Value $RSInfo.IsPowerBIFeatureEnabled -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'IsReportManagerEnabled' -Value $RSInfo.IsReportManagerEnabled -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'IsSharePointIntegrated' -Value $RSInfo.IsSharePointIntegrated -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'IsWebServiceEnabled' -Value $RSInfo.IsWebServiceEnabled -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'IsWindowsServiceEnabled' -Value $RSInfo.IsWindowsServiceEnabled -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'MachineAccountIdentity' -Value $RSInfo.MachineAccountIdentity -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'PathName' -Value $RSInfo.PathName -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'SecureConnectionLevel' -Value $RSInfo.SecureConnectionLevel -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'ServiceName' -Value $RSInfo.ServiceName -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'UnattendedExecutionAccount' -Value $RSInfo.UnattendedExecutionAccount -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'Version' -Value $RSInfoSwitchInfo -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportManager' -Value $RSInfo.VirtualDirectoryReportManager -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportServer' -Value $RSInfo.VirtualDirectoryReportServer -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'WindowsServiceIdentityActual' -Value $RSInfo.WindowsServiceIdentityActual -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name 'WindowsServiceIdentityConfigured' -Value $RSInfo.WindowsServiceIdentityConfigured -ErrorAction SilentlyContinue
						$SSRS_Info | Add-Member -MemberType NoteProperty -Name ' ' -Value ' ' -ErrorAction SilentlyContinue
						$setupOutput | Add-Member -MemberType NoteProperty -Name 'Reporting Services Information' -Value ($SSRS_Info | Format-List * | Out-String -Width 4096)
					}
					catch { continue }
				}
				$setupOutput | Add-Member -MemberType NoteProperty -Name 'Services' -Value $localServices
				return $setupOutput
			}
			#End Inner General Info
			trap
			{
				#potential error code
				#use continue or break keywords
				$e = $_.Exception
				$line = $_.InvocationInfo.ScriptLineNumber
				$msg = $e.Message
				Write-Host "Caught Exception: $e at line: $line" -ForegroundColor Red
				"$(Time-Stamp)Caught Exception: $e at line: $line" | Out-File $OutputPath\Error.log -Append
			}
			if ($server -eq $Comp) # If server equals Local Computer
			{
				$GeneralInfoGather = Inner-GeneralInfoFunction -LocalManagementServer
				@"
======================================
=---- Local General Information  ----=
======================================
"@ | Write-Output
				$GeneralInfoGather | Write-Output
			}
			else
			{
				$InnerGeneralInfoFunctionScript = "function Inner-GeneralInfoFunction { ${function:Inner-GeneralInfoFunction} }"
				$ProductVersionScript = "function Get-ProductVersion { ${function:Get-ProductVersion} }"
				$GeneralInfoGather = Invoke-Command -ComputerName $server -ArgumentList $InnerGeneralInfoFunctionScript, $ProductVersionScript -ScriptBlock {
					Param ($script,
						$versionscript)
					. ([ScriptBlock]::Create($script))
					. ([ScriptBlock]::Create($versionscript))
					Inner-GeneralInfoFunction
				}
				@"
========================================
=----- Remote General Information -----=
========================================
"@ | Write-Output
				$GeneralInfoGather | select * -ExcludeProperty PSComputerName, RunspaceId | Out-String -Width 4096 | Write-Output
			}
		}
		Write-Progress -Activity "Collection Running" -Status "Progress-> 50%" -PercentComplete 10
		
		Write-Progress -Activity "Collection Running" -Status "Progress-> 76%" -PercentComplete 76
		
		Write-Progress -Activity "Collection Running" -Status "Progress-> 80%" -PercentComplete 80
		$UpdatesOutput = foreach ($Server in $Servers)
		{
			; Invoke-Command -ComputerName $Server -ScriptBlock { Get-HotFix } -ErrorAction SilentlyContinue
		}
		if ($UpdatesOutput.HotfixId)
		{
			@"
================================
=----- Installed Updates  -----=
================================
"@ | Write-Output
			$UpdatesOutput | Sort InstalledOn, PSComputerName -Descending | Add-Member -MemberType AliasProperty -Name 'Computer Name' -Value PSComputerName -PassThru | Select-Object -Property 'Computer Name', Description, HotFixID, InstalledBy, InstalledOn, Caption | Format-Table * -AutoSize | Write-Output
		}
		else
		{
			@"
=================================================
=----- Unable to Detect Installed Updates  -----=
=================================================
"@ | Write-Output
		}
		
		Write-Progress -Activity "Collection Running" -Status "Progress-> 84%" -PercentComplete 84
		if ($Servers.Count -gt 1)
		{
			@"
======================================= 
=-- ConfigService.config File Check --= 
=======================================
"@ | Write-Output
			$localpath = (get-itemproperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup" -ErrorAction Stop).InstallDirectory
			foreach ($server in $ManagementServers)
			{
				
				if ($server -notmatch $env:COMPUTERNAME)
				{
					try
					{
						$remoteConfig = $null
						$remoteConfig = Invoke-Command -ComputerName $server -ScriptBlock {
							trap
							{
								#potential error code
								#use continue or break keywords
								$e = $_.Exception
								$line = $_.InvocationInfo.ScriptLineNumber
								$msg = $e.Message
								Write-Host "Caught Exception: $e at line: $line" -ForegroundColor Red
							}
							$scompath = (get-itemproperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup" -ErrorAction Stop).InstallDirectory
							return (Get-Content -Path "$scompath`\ConfigService.config" -ErrorAction Stop)
						} -ErrorAction Stop
						$compare = Compare-Object -ReferenceObject (Get-Content -Path "$localpath`\ConfigService.config" -ErrorAction Stop) -DifferenceObject $remoteConfig -ErrorAction Stop
						
						if ($compare)
						{
							Write-Output "There are differences between : $server <-> $env:ComputerName" | Write-Output
						}
						else
						{
							Write-Output "Configuration Matches between : $server <-> $env:ComputerName" | Write-Output
						}
					}
					catch
					{
						"$(Time-Stamp)$server (Remote) - Unreachable" | Out-File $OutputPath\Error.log -Append
						Write-Output "$server (Remote) - Unreachable" | Write-Output
					}
				}
				else
				{
					Write-Output "$server (Source)" | Write-Output
				}
			}
			Write-Progress -Activity "Collection Running" -Status "Progress-> 87%" -PercentComplete 87
			
			" " | Write-Output
			@"
================================
=------ Clock Sync Check ------=
================================
"@ | Write-Output
			foreach ($server in $Servers)
			{
				try
				{
					
					if ($server -ne $Comp)
					{
						try
						{
							$remoteTime = Invoke-Command -ComputerName $Server { return [System.DateTime]::UtcNow } -ErrorAction Stop
						}
						catch
						{
							Write-Output "Unable to run any commands against the Remote Server : $server" | Write-Output
							continue
						}
						
						$localTime = [System.DateTime]::UtcNow
						if ($remoteTime.Hour -match $localtime.Hour)
						{
							if ($remoteTime.Minute -match $localtime.Minute)
							{
								Write-Output "Time synchronized between : $server <-> $Comp" | Write-Output
							}
						}
						elseif (!$remoteTime)
						{
							Write-Output "Unable to check the Time of Remote Server : $server" | Write-Output
						}
						else
						{
							Write-Output "Time NOT synchronized between : $server <-> $Comp : Remote Time: $remoteTime - Local Time: $localTime" | Write-Output
						}
					}
				}
				catch { Write-Warning $_ }
			}
			Write-Progress -Activity "Collection Running" -Status "Progress-> 90%" -PercentComplete 90
		}
		
		Write-Progress -Activity "Collection Running" -Status "Progress-> 92%" -PercentComplete 92
		
		Write-Progress -Activity "Collection Running" -Status "Progress-> 94%" -PercentComplete 94
		if ($pingall)
		{
			foreach ($server in $TestedTLSservers)
			{
				Invoke-Command -ComputerName $server -ErrorAction SilentlyContinue -ScriptBlock {
					#Start Checking for Connectivity to Management Servers in MG
					$pingoutput = @()
					foreach ($ms in $using:ManagementServers)
					{
						if ($ms -eq $env:COMPUTERNAME) { continue }
						try
						{
							$test = @()
							$test = (Test-Connection -ComputerName $ms -Count 4 | measure-Object -Property ResponseTime -Average).average
							$response = @()
							$response = ($test -as [int])
							$innerdata = @()
							[string]$innerdata = "$using:server -> $ms : $response ms"
						}
						catch
						{
							Write-Warning $_
							continue
						}
					}
					return $innerdata
				} | Write-Output
			}
		}
		$pingoutput | Write-Output
		
		Write-Progress -Activity "Collection Running" -Status "Progress-> 96%" -PercentComplete 96
	}
	if ($Servers)
	{
		Get-SCOMGeneralInfo -Servers $Servers
	}
	else
	{
		Get-SCOMGeneralInfo -Servers $env:COMPUTERNAME
	}
	
}
END
{
	Write-Verbose "$(Time-Stamp)Script has completed!"
}
