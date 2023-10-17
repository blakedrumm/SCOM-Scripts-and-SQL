-- Gather all Custom Reports that are saved in Management Packs
SELECT MPName, MPFriendlyName, CAST(MPXML AS xml)
FROM ManagementPack WITH (NOLOCK)
WHERE MPXML LIKE '%UICustomReport%'
