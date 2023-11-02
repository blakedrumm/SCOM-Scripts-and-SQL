# Author: Blake Drumm (blakedrumm@microsoft.com)
# Date Created: November 1st, 2023
# ------------------------------------------------
# Description:
# This script will fix issues with the Health Service events showing in the Application Event Logs.
# ------------------------------------------------
Get-Item "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\HealthService" -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force; Restart-Service HealthService -Force
