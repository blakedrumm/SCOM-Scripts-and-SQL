-- Status:
-- 0: active, set by collector
-- 1: inactive, mark for closing during collector startup & indexing, set manually
-- 2: archived, ready for deletion, set from outside the collector
-- 100 - 108: closed, indexing in progress
-- 109: indexing complete
select * from dtpartition order by partitionstarttime DESC
