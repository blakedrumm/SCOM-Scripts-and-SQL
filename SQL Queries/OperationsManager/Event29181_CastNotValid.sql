select
   DiscoveryName,
   MPName,
   MPFriendlyName,
   MPVersion,
   MPIsSealed,
   MPLastModified,
   MPCreated,
   PrincipalName 
from
   discovery d 
   join
      ManagementPack MP 
      on MP.ManagementPackId = d.ManagementPackId 
   join
      DiscoverySource DS 
      on DS.DiscoveryRuleId = d.DiscoveryId 
   join
      DiscoverySourceToTypedManagedEntity DSTME 
      on DSTME.DiscoverySourceId = DS.DiscoverySourceId 
   join
      MTV_HealthService MHS 
      on MHS.BaseManagedEntityId = DSTME.TypedManagedEntityId 
where
   MaximumQueueSize is null 
   or DisplayName = ''