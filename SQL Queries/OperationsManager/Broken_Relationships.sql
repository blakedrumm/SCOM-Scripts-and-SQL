---Check for Broken Relationship
Use OperationsManager
SELECT R.[RelationshipId],
       RT.[RelationshipTypeId],
       S.[FullName] as SourceName,
       T.[FullName] as TargetName
FROM dbo.[Relationship] R with (nolock)
    INNER JOIN dbo.[RelationshipType] RT with (nolock)
        ON RT.[RelationshipTypeId] = R.[RelationshipTypeId]
    INNER JOIN dbo.[BaseManagedEntity] S with (nolock)
        ON S.[BaseManagedEntityId] = R.[SourceEntityId]
    INNER JOIN dbo.[BaseManagedEntity] T with (nolock)
        ON T.[BaseManagedEntityId] = R.[TargetEntityId]
WHERE R.[IsDeleted] = 0
      AND (S.[IsDeleted] = 1 OR T.[IsDeleted] = 1)