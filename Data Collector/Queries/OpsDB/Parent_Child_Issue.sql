SELECT c1.ParentAgentRowId, a1.NetworkName 'Parent',
c1.ChildAgentRowId, a1.NetworkName 'Child'
FROM CS.CommunicationRelationship c1
JOIN CS.Agent a1
ON c1.ParentAgentRowId = a1.AgentRowId
WHERE c1.ParentAgentRowId = c1.ChildAgentRowId
And c1.DeletedInd = 0
UNION
SELECT c2.ParentAgentRowId, a2p.NetworkName 'Parent',
c2.ChildAgentRowId, a2c.NetworkName 'Child'
FROM CS.CommunicationRelationship c2
JOIN CS.Agent a2p
ON c2.ParentAgentRowId = a2p.AgentRowId
JOIN CS.Agent a2c
ON c2.ChildAgentRowId = a2c.AgentRowId
JOIN CS.CommunicationRelationship c2r
ON c2.ParentAgentRowId = c2r.ChildAgentRowId
AND c2.ChildAgentRowId = c2r.ParentAgentRowId
WHERE c2.DeletedInd = 0
AND c2r.DeletedInd = 0