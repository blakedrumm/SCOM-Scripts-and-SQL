![ETL Trace](/media/git-guidance/etl_trace.png)

# Introduction
This Tool will assist you in gathering ETL Traces. You have the options of selecting specific Tracing to gather with this script.

The script will perform the following, in this order:
1. Stops any existing ETL Traces
 - *Optional:* Stops the SCOM Services
2. Starts the ETL Trace
 - *Optional:* Starts the SCOM Services back up
3. Script will wait for issue to occur
 - *Default:* Pauses Script, waits until you press Enter
 - *Optional:* Sleeps for x Seconds (`-SleepSeconds 10`)
 - *Optional:* Script will loop until an Event ID is detected  (`-DetectOpsMgrEventID`)
4. Stops ETL Trace
5. Formats ETL Trace
6. Zips Up Output and Opens Explorer Window for Viewing File

## Examples
Open Powershell Prompt as Administrator:
## All Available Commands
    .\Start-ScomETLTrace.ps1 -GetAdvisor -GetApmConnector -GetBID -GetConfigService -GetDAS -GetFailover -GetManaged -GetNASM -GetNative -GetScript -GetUI -VerboseTracing -DebugTracing -NetworkTrace -SleepSeconds -RestartSCOMServices -DetectOpsMgrEventID

###### Get Verbose Native ETL Trace
    .\Start-ScomETLTrace.ps1 -GetNative -VerboseTracing

###### Gather Verbose ETL Trace and detect for 1210 Event ID (Sleep for 30 Seconds between checks)
    .\Start-ScomETLTrace.ps1 -VerboseTracing -DetectOpsMgrEventID 1210 -SleepSeconds 30

###### Restart SCOM Services after starting an ETL Trace. Sleep for 2 Minutes and stop the Trace Automatically
    .\Start-ScomETLTrace.ps1 -Sleep 120 -RestartSCOMServices

#### Get All ETL Traces
###### Get Verbose Tracing for all the Default Tracing Available (just like running this: -GetAdvisor -GetApmConnector -GetBID -GetConfigService -GetDAS -GetFailover -GetManaged -GetNASM -GetNative -GetScript -GetUI)
    .\Start-ScomETLTrace.ps1 -VerboseTracing
###### Get Debug Tracing for all the Default Tracing Available (just like running this: -GetAdvisor -GetApmConnector -GetBID -GetConfigService -GetDAS -GetFailover -GetManaged -GetNASM -GetNative -GetScript -GetUI)
    .\Start-ScomETLTrace.ps1 -DebugTracing
###### Get Verbose Tracing for all the Default Tracing Available and Network Tracing (just like running this: -GetAdvisor -GetApmConnector -GetBID -GetConfigService -GetDAS -GetFailover -GetManaged -GetNASM -GetNative -GetScript -GetUI)
    .\Start-ScomETLTrace.ps1 -VerboseTracing -NetworkTrace
