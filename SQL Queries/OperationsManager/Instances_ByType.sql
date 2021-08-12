SELECT mt.TypeName, COUNT(*) AS NumEntitiesByType 
FROM BaseManagedEntity bme WITH(NOLOCK) 
            LEFT JOIN ManagedType mt WITH(NOLOCK) ON mt.ManagedTypeID = bme.BaseManagedTypeID 
WHERE bme.IsDeleted = 0 
GROUP BY mt.TypeName 
ORDER BY COUNT(*) DESC