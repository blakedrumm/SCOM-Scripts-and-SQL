--see all of the configuration changes made in the last 24 hours in OpsDb
SELECT 
  TOP 100 EntityTypeId, 
  TypeName, 
  COUNT(*) as "Number of changes" 
FROM 
  dbo.EntityChangeLog E 
  join ManagedType MT on MT.ManagedTypeId = e.EntityTypeId 
WHERE 
  e.LastModified < GETUTCDATE() -1 
GROUP BY 
  E.EntityTypeId, 
  TypeName 
HAVING 
  (
    COUNT(*)
  ) > 10 
order by 
  [Number of changes] desc
