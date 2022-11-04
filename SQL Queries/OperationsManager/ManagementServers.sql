-- Last Modified:
-- September 13th, 2022 - (blakedrumm@microsoft.com) Remove Reason Code Availability History and move to another TSQL Query.
SELECT *
FROM MTV_HealthService mtv
WHERE mtv.IsManagementServer = 1
OR mtv.IsGateway = 1
ORDER BY mtv.DisplayName