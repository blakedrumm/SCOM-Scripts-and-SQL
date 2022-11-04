SELECT 
  ManagedTypePropertyName, 
  SettingValue, 
  mtv.DisplayName, 
  gs.LastModified 
FROM 
  GlobalSettings gs WITH (NOLOCK)
  INNER JOIN ManagedTypeProperty mtp WITH (NOLOCK) on gs.ManagedTypePropertyId = mtp.ManagedTypePropertyId 
  INNER JOIN ManagedTypeView mtv on mtp.ManagedTypeId = mtv.Id 
ORDER BY 
  mtv.DisplayName