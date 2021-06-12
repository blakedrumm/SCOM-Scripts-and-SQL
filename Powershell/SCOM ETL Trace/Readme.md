![ETL Trace](/media/git-guidance/projects/etl_trace.png)

#Introduction
This Tool will assist you in gathering ETL Traces. You have the options of selecting specific Tracing to gather with this script.

The script will perform the following, in this order:
1. Stops any existing ETL Traces
2. Stops the SCOM Services
3. Starts the ETL Trace
4. Starts the SCOM Services back up
5. Pauses Script for you to Reproduce the issue (if you dont have the -DetectOpsMgrEventID switch or -SleepSeconds = 10)
6. Stops ETL Trace
7. Formats ETL Trace
8. Zips Up Output and Opens Explorer Window for Viewing File

##Example
Open Powershell Prompt as Administrator:
##All Available Commands
    .\Start-ScomETLTrace.ps1 -GetAdvisor -GetApmConnector -GetBID -GetConfigService -GetDAS -GetFailover -GetManaged -GetNASM -GetNative -GetScript -GetUI -VerboseTracing -DebugTracing -NetworkTrace -SleepSeconds -RestartSCOMServices -DetectOpsMgrEventID

###Get Verbose Native ETL Trace
    .\Start-ScomETLTrace.ps1 -GetNative -VerboseTracing

###Gather Verbose ETL Trace and detect for 1210 Event ID (Sleep for 30 Seconds between checks)
    .\Start-ScomETLTrace.ps1 -VerboseTracing -DetectOpsMgrEventID 1210 -SleepSeconds 30

###Restart SCOM Services after starting an ETL Trace. Sleep for 30 seconds and stop the Trace Automatically
    .\Start-ScomETLTrace.ps1 -Sleep 120 -RestartSCOMServices

###Get All ETL Tracing
####Get Verbose Tracing for all the Default Tracing Available (just like running this: -GetAdvisor -GetApmConnector -GetBID -GetConfigService -GetDAS -GetFailover -GetManaged -GetNASM -GetNative -GetScript -GetUI)
    .\Start-ScomETLTrace.ps1 -VerboseTracing
####Get Debug Tracing for all the Default Tracing Available (just like running this: -GetAdvisor -GetApmConnector -GetBID -GetConfigService -GetDAS -GetFailover -GetManaged -GetNASM -GetNative -GetScript -GetUI)
    .\Start-ScomETLTrace.ps1 -DebugTracing
####Get Verbose Tracing for all the Default Tracing Available and Network Tracing (just like running this: -GetAdvisor -GetApmConnector -GetBID -GetConfigService -GetDAS -GetFailover -GetManaged -GetNASM -GetNative -GetScript -GetUI)
    .\Start-ScomETLTrace.ps1 -VerboseTracing -NetworkTrace