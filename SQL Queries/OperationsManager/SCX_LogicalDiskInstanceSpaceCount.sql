-- Added May 15th, 2023 - Udish Mudiar
select count(*) from BaseManagedEntity
where FullName like '%Linux%logicaldisk%'
or FullName like '%Solaris%logicaldisk%'
or FullName like '%AIX%logicaldisk%'
