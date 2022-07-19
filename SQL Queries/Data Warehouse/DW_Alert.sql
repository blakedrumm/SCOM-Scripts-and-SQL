Select     M.[Path] as Path,
               M.[DisplayName] as Display_Name,
               M.[FullName],
               A.[AlertName],
               A.[AlertDescription],
               A.[RaisedDateTime],
               A.[DWLastModifiedDateTime] as Last_Modified,
               A.[Severity] as Severtiy,
               A.[RepeatCount] as Repeat_Count
From [Alert].[vAlert] as A
Join [dbo].[vManagedEntity] As M On A.ManagedEntityRowId=M.ManagedEntityRowId
Order by RaisedDateTime Desc
