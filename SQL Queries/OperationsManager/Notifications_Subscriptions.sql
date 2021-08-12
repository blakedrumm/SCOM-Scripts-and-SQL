-- This is the 2 queries joined together to provide the data that we want
Select Subscriptions.DisplayName, Subscriptions.RuleId,
Case subscriptions.enabled When 0 Then 'No' Else 'Yes' End as SubscriptionEnabled,
Subscribers.SubscriberName, Subscribers.DeviceName, Subscribers.DeviceProtocol,
Subscribers.DeviceAddress
FROM (
--This is the whole subscriber query with Address  
Select r.SubscriberName, r.SubscriberId,
D.C.value('Name[1]','varchar(4000)') DeviceName,
D.C.value('Protocol[1]','varchar(4000)') DeviceProtocol,
D.C.value('Address[1]','varchar(4000)') DeviceAddress
FROM (Select  N.C.value('Name[1]','varchar(4000)') SubscriberName,
   N.C.value('RecipientId[1]','varchar(4000)') SubscriberId,
   n.c.query('.') as xmlquery
from (Select cast(MDTImplementationXML as xml) Recxml FROM [dbo].[ModuleType] mt
Where MDTName = 'Microsoft.SystemCenter.Notification.Recipients' )a Cross Apply Recxml.nodes('//Recipient') N(C)) r
Cross Apply xmlquery.nodes('//Device') D(C)
) Subscribers
Join
(--These are the subscriptions
Select r.RuleId, r.RuleModuleId, r.enabled, R.DisplayName,
D.C.value('RecipientId[1]','varchar(4000)') SubscriberId
FROM (Select RuleId, rm.RuleModuleId, enabled, r.DisplayName,
    cast(RuleModuleConfiguration as XML) xmlquery
      FROM
      RuleModule rm
      join RuleView r on rm.RuleId = r.Id
      where r.Category = 'Notification'
      and RuleModuleName = 'CD1'
      --and Enabled <> 0
      ) r
Cross Apply xmlquery.nodes('//DirectoryReference') D(C)
) Subscriptions on Subscribers.SubscriberId = Subscriptions.SubscriberId
--Where ((Subscriptions.RuleId = Replace(Replace(@SubscriptionId,'{',''),'}','')
   --or @SubscriptionId IS NULL)
--and DeviceProtocol in ('SMS','SMTP'))
order by 1,2