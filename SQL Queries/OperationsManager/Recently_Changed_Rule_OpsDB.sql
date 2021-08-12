SELECT RuleName,
	mp.MPFriendlyName,
	RuleCategory,
	RuleEnabled,
	r.LastModified
FROM Rules r
INNER JOIN ManagementPack mp
ON r.ManagementPackId = mp.ManagementPackId
WHERE r.LastModified > DATEADD(day, -4, GETUTCDATE())
ORDER BY r.LastModified DESC