--Machines (more readable)
select replace(right(Description, (len(Description) – patindex(‘%\%’,Description))),’$’,”)
from dtMachine
