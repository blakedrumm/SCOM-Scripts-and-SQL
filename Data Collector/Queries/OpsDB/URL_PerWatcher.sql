SELECT
SourceObjectDisplayName as 'WatcherName',
  count(*) as 'NumberOfURLs',
  h.IsAgent,
  h.IsManagementServer
FROM RelationshipGenericView r 
JOIN MT_HealthService h with(NOLOCK) on r.SourceObjectDisplayName=h.DisplayName
WHERE r.RelationshipId like 'A98C9038-6E2A-9394-3B07-9C8380A8956D' and TargetObjectFullName like 'Microsoft.SystemCenter.WebApplicationTest.WebTest:%'
GROUP BY r.SourceObjectDisplayName,  h.IsAgent,h.IsManagementServer order by count(*) desc