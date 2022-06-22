-- Modified 2/9/2022 - Included Free Space %, added MB to value fields.
-- Modified 6/21/2022 - Attempted to fix Arithmetic Overflow error when run in large environments. Added 'SpaceUsed(%)' and 'AutoGrowStatus' columns.
-- Blake Drumm (blakedrumm@microsoft.com)

SELECT sf.NAME AS 'Name',
CONCAT(convert(decimal(12,2), round(sf.size/128.000, 2)), ' MB') AS 'FileSize(MB)',
CONCAT(convert(int, round(100 * convert(bigint,(sf.size-fileproperty(sf.name, 'SpaceUsed'))) / convert(bigint,sf.size), 2)),' %') AS 'FreeSpace(%)',
CONCAT(convert(decimal(12,2), round((sf.size-fileproperty(sf.name, 'SpaceUsed'))/128.000, 2)), ' MB') AS 'FreeSpace(MB)',
CONCAT(convert(int, 100 - (round(100 * convert(bigint,(sf.size-fileproperty(sf.name, 'SpaceUsed'))) / convert(bigint,sf.size), 2))),' %') AS 'SpaceUsed(%)',
CONCAT(convert(decimal(12,2), round(fileproperty(sf.name, 'SpaceUsed')/128.000, 2)), ' MB') AS 'SpaceUsed(MB)',
CASE smf.growth
	WHEN 0 THEN 'Disabled'
	ELSE 'Enabled'
END AS 'AutoGrowStatus',
CASE smf.is_percent_growth
    WHEN 1 THEN CONCAT(CONVERT(bigint, smf.growth), ' %')
    ELSE CONCAT(convert(decimal(12,2), smf.growth/128),' MB')
END AS 'AutoGrow',
CASE (sf.maxsize)
    WHEN -1 THEN 'Unlimited'
    WHEN 268435456 THEN 'Max Size (2TB)'
    ELSE CONCAT(convert(decimal(12,2), round(sf.maxsize/128.000, 2)), ' MB')
END AS 'AutoGrowthMB(MAX)',
sf.FILENAME AS 'Location',
sf.FILEID AS 'FileId'
FROM dbo.sysfiles sf WITH (NOLOCK)
JOIN sys.master_files smf WITH (NOLOCK) ON smf.physical_name = sf.filename
ORDER BY FileId
