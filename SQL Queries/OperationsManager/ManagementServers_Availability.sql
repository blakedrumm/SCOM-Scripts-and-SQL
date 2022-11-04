-- Last Modified:
-- September 13th, 2022 - (blakedrumm@microsoft.com) Seperate Availability History from ManagementServers.sql query.
SELECT mtv.BaseManagedEntityId,
mtv.DisplayName,
ahist.ReasonCode,
Case ahist.ReasonCode
When 17 then 'The Health Service windows service is paused.'
When 25 then 'The Health Service Action Account is misconfigured or has invalid credentials.'
When 41 then 'The Health Service failed to parse the new configuration.'
When 42 then 'The Health Service failed to load the new configuration.'
When 43 then 'A System Rule failed to load.'
When 49 then 'Collection of Object State Change Events is stalled.'
When 50 then 'Collection of Monitor State Change Events is stalled.'
When 51 then 'Collection of Alerts is stalled.'
When 97 then 'The Health Service is unable to register with the Event Log Service. The Health Service cannot log additional Heartbeat and Connector events.'
When 98 then 'The Health Service is unable to parse configuration XML.'
When 1 then 'Reason Unknown. POSSIBLY due to Health Service not heartbeating within 3 minutes to SDK?'
ELSE 'Unknown reason code.'
End as [ReasonCodeResult],
ahist.TimeStarted,
ahist.LastModified
FROM MTV_HealthService mtv
LEFT JOIN AvailabilityHistory ahist
ON ahist.BaseManagedEntityId = mtv.BaseManagedEntityId
WHERE mtv.IsManagementServer = 1
OR mtv.IsGateway = 1
ORDER BY mtv.DisplayName