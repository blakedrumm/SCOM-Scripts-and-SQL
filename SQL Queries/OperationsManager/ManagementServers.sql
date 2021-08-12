SELECT *,REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REASONCODE,17,'The Health Service windows service is paused.'),25,'The Health Service Action Account is misconfigured or has invalid credentials.'),41,'The Health Service failed to parse the new configuration.'),42,'The Health Service failed to load the new configuration.'),43,'A System Rule failed to load.'),49,'Collection of Object State Change Events is stalled.'),50,'Collection of Monitor State Change Events is stalled.'),51,'Collection of Alerts is stalled.'),97,'The Health Service is unable to register with the Event Log Service. The Health Service cannot log additional Heartbeat and Connector events.'),98,'The Health Service is unable to parse configuration XML.'),1,'Reason Unknown. POSSIBLY due to Health Service not heartbeating within 3 minutes to SDK?') AS ReasonCodeResult
FROM MTV_HealthService mtv
LEFT JOIN AvailabilityHistory ahist
ON ahist.BaseManagedEntityId = mtv.BaseManagedEntityId
WHERE mtv.IsManagementServer = 1
OR mtv.IsGateway = 1
ORDER BY mtv.DisplayName
