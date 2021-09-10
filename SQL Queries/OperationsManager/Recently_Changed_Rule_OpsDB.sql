SELECT RuleName,
	mp.MPFriendlyName,
	RuleCategory,
	RuleEnabled,
	r.LastModified
FROM Rules r WITH (NOLOCK)
INNER JOIN ManagementPack mp WITH (NOLOCK)
ON r.ManagementPackId = mp.ManagementPackId
WHERE r.LastModified > DATEADD(day, -4, GETUTCDATE())
ORDER BY r.LastModified DESC