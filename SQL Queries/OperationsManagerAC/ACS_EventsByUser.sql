--event distribution for a specific user (change the @user) – with percentages for the user and compared with the total #events in the DB
declare @user varchar(255)
set @user = ‘SYSTEM’
declare @total float
select @total = count(Id) from AdtServer.dvHeader
declare @totalforuser float
select @totalforuser = count(Id) from AdtServer.dvHeader where HeaderUser = @user
select count(Id), EventID, cast(convert(float,(count(Id)) / convert(float,@totalforuser) * 100) as decimal(10,2)) as PercentageForUser, cast(convert(float,(count(Id)) / (convert(float,@total)) * 100) as decimal(10,2)) as PercentageTotal
from AdtServer.dvHeader
where HeaderUser = @user
group by EventID
order by count(Id) desc
