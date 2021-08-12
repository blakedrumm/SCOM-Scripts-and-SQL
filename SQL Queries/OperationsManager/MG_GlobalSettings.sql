SELECT mtp.ManagedTypePropertyName AS 'Property', 
  gs.SettingValue
FROM GlobalSettings gs
JOIN ManagedTypeProperty mtp ON mtp.ManagedTypePropertyId = gs.ManagedTypePropertyId
ORDER BY mtp.ManagedTypePropertyName