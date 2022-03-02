select name AS 'Database'
       , suser_sname(owner_sid) AS 'Owner'
 from sys.databases
GO
