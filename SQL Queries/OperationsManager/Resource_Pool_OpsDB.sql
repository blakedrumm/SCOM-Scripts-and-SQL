select
BaseManagedEntity.DisplayName as 'ServerName'
--,cs.WorkFlowExecutionLocationAgent.AgentRowId
--,cs.workflowexecutionlocation.WorkflowExecutionLocationRowId
,cs.workflowexecutionlocation.DisplayName as 'Resource Pool'
,cs.agent.AgentGuid
from cs.WorkFlowExecutionLocationAgent WITH (NOLOCK)
inner join cs.workflowexecutionlocation WITH (NOLOCK)
ON cs.WorkFlowExecutionLocationAgent.WorkFlowExecutionLocationAgentRowId = cs.workflowexecutionlocation.WorkflowExecutionLocationRowId
inner join CS.agent WITH (NOLOCK)
ON CS.agent.AgentRowId=cs.WorkFlowExecutionLocationAgent.AgentRowId
inner join BaseManagedEntity WITH (NOLOCK)
ON BaseManagedEntity.BaseManagedEntityId = CS.agent.AgentGuid
-- Take the last line off to get all
where cs.workflowexecutionlocation.AgentPoolInd = '1'