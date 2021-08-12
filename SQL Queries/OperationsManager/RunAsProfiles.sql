--get all Run As profiles and associated accounts, 
	--credentials, Secure Storage ID values and targets
SELECT [Profile].SecureReferenceName ProfileName
	, Account.Name AccountName
	, Account.Domain
	, Account.UserName
	, Account.LastModified
	, [Override].OverrideName
	, [Override].Value SSID
	, bme.FullName
	, mt.TypeName
FROM CredentialManagerSecureStorage AS Account
JOIN SecureReferenceOverride AS [Override]
ON CONVERT (varchar(80), Account.SecureStorageId, 2) = [Override].Value
JOIN SecureReference AS [Profile]
ON [Override].SecureReferenceId = [Profile].SecureReferenceId
JOIN ManagedType mt
ON [Override].TypeContext = mt.ManagedTypeId
LEFT JOIN BaseManagedEntity bme
ON [Override].InstanceContext = bme.BaseManagedEntityId
ORDER BY ProfileName