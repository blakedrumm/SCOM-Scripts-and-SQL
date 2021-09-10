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
FROM CredentialManagerSecureStorage AS Account WITH (NOLOCK)
JOIN SecureReferenceOverride AS [Override] WITH (NOLOCK)
ON CONVERT (varchar(80), Account.SecureStorageId, 2) = [Override].Value
JOIN SecureReference AS [Profile] WITH (NOLOCK)
ON [Override].SecureReferenceId = [Profile].SecureReferenceId
JOIN ManagedType mt WITH (NOLOCK)
ON [Override].TypeContext = mt.ManagedTypeId
LEFT JOIN BaseManagedEntity bme WITH (NOLOCK)
ON [Override].InstanceContext = bme.BaseManagedEntityId
ORDER BY ProfileName