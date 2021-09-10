exec sp_executesql N'-- CredentialManagerStoreByCriteriaWithoutSecretData <LanguageCode1,LanguageCode2>
SELECT 
Case [SecureData].[Type]
When 0 then ''SNMPv3 Account''
When 1 then ''Action Account''
When 2 then ''Windows''
When 3 then ''Simple Authentication''
When 4 then ''Basic Authentication''
When 5 then ''Digest Authentication''
When 6 then ''Community String''
When 7 then ''Binary Authentication''
End as [Type],[SecureData].[Name],[SecureData].[Description],[SecureData].[Domain],[SecureData].[UserName],[SecureData].[LastModified],REPLACE(REPLACE([SecureData].[IsSystem],0,''False''),1,''True'') AS IsSystem,[SecureData].[AssemblyQualifiedName],[SecureData].[Id],[SecureData].[SecureStorageId],[SecureData].[ConfigurationXml]
FROM dbo.fn_CredentialManagerStoreByCriteriaWithoutSecretDataView(@LanguageCode1, @LanguageCode2) AS SecureData
ORDER BY Type, Name',N'@LanguageCode1 nvarchar(3),@LanguageCode2 nvarchar(3)',@LanguageCode1=N'ENU',@LanguageCode2=N'ENU'