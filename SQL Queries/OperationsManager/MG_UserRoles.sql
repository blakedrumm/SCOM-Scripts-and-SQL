SELECT Description, SUSER_SNAME([MemberSID]) as "RoleMember"
FROM AzMan_AzRoleAssignment A
join AzMan_Role_SIDMember B
on A.ID = b.RoleID