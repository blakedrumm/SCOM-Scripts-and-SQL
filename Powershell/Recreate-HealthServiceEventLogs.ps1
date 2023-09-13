# Author: Blake Drumm (blakedrumm@microsoft.com)
# Date Created: September 13th, 2023
#
# Recreate the HealthService Event Log into the OperationsManager Event Log. There is an issue with the HealthService in some cases going into the Application Event Log.
Get-Item "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\HealthService" -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force; Restart-Service HealthService -Force
