SELECT 
AgentPendingActionId, 
AgentName,
ManagementServerName,
Case PendingActionType
When 0 then 'Manual Approval'
When 1 then 'Push Install'
When 2 then 'Updated Needed'
When 10 then 'Repair Failed'
When 17 then 'Push Install Failed'
When 18 then 'Update Failed'
End as [PendingActionType],
PendingActionData,
LastModified
FROM AgentPendingAction WITH (NOLOCK)
