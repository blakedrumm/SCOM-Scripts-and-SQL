SELECT ME.Path, HSO.StartDateTime AS OutageStartDateTime, DATEDIFF (DD, HSO.StartDateTime, GETUTCDATE()) 
AS OutageDays, HSO.ReasonCode, DS.Name AS ReasonString FROM vManagedEntity AS ME 
INNER JOIN vHealthServiceOutage AS HSO ON HSO.ManagedEntityRowId = ME.ManagedEntityRowId 
INNER JOIN vStringResource AS SR ON HSO.ReasonCode = REPLACE(LEFT(SR.StringResourceSystemName, LEN(SR.StringResourceSystemName) - CHARINDEX('.', REVERSE(SR.StringResourceSystemName))), 'System.Availability.StateData.Reasons.', '') 
INNER JOIN vDisplayString AS DS ON DS.ElementGuid = SR.StringResourceGuid WHERE (HSO.EndDateTime IS NULL) AND (SR.StringResourceSystemName LIKE 'System.Availability.StateData.Reasons.[0-9]%') AND DS.LanguageCode = 'ENU' 
ORDER BY OutageStartDateTime