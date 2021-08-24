-- Instead of using EventDescription, follow the steps here:
-- https://kevinholman.com/2008/04/22/using-event-description-as-criteria-for-a-rule/
SELECT MPName, MPFriendlyName, CAST(MPXML AS xml)
FROM ManagementPack
WHERE MPXML LIKE '%<XPathQuery Type="String">EventDescription</XPathQuery>%' AND MPFriendlyName != 'Apm.NTService'
