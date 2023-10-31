Select         A.[RaisedDateTime],
               A.[DWLastModifiedDateTime] as Last_Modified,
               M.[Path] as Path,
               M.[DisplayName] as Display_Name,
               M.[FullName],
               A.[AlertName],
               A.[AlertDescription],
               A.[Severity] as Severity,
               A.[RepeatCount] as Repeat_Count
From [Alert].[vAlert] as A
Join [dbo].[vManagedEntity] As M On A.ManagedEntityRowId=M.ManagedEntityRowId
--WHERE RaisedDateTime BETWEEN GETDATE()-60 AND GETDATE()
Order by RaisedDateTime Desc
