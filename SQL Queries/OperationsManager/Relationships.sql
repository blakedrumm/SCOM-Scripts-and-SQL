SELECT COUNT(*) AS 'ContainedMembers', SourceObjectDisplayName, SourceObjectFullName
FROM RelationshipGenericView
GROUP BY SourceObjectDisplayName,SourceObjectFullName
ORDER BY COUNT(*) DESC