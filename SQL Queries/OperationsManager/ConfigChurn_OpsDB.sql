--see all of the configuration changes made in the last 24 hours in OpsDb
SELECT
  TOP 100
  MTV.Name,
  MTV.DisplayName,
  COUNT(*) as "Number of changes",
  MPV.FriendlyName AS ManagementPackFriendlyName,
  MPV.Name AS ManagementPackName,
  MTV.LanguageCode,
  Case MTV.Hosted
    When 0 then 'False'
    When 1 then 'True'
  End as [IsHosted],
  EntityTypeId
FROM
  dbo.EntityChangeLogView E 
  join ManagedTypeView MTV on MTV.Id = e.EntityTypeId 
  left join ManagementPackView MPV on MPV.Id = MTV.ManagementPackId and MPV.LanguageCode = MTV.LanguageCode
WHERE
  e.LastModified < GETUTCDATE() -1
  AND MTV.LanguageCode = (select LanguageCode from __MOMManagementGroupInfo__)
GROUP BY
  E.EntityTypeId, 
  MTV.Name,
  MTV.Hosted,
  MTV.LanguageCode,
  MTV.DisplayName,
  MPV.Name,
  MPV.FriendlyName,
  MTV.ManagementPackId
HAVING
  (
    COUNT(*)
  ) > 10
order by
  [Number of changes] DESC, LanguageCode DESC