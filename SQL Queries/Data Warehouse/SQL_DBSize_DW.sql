-- Modified 2/9/2022 - Included Free Space %, added MB to value fields.
-- Blake Drumm (blakedrumm@microsoft.com)

SELECT left(sf.NAME, 15) AS 'Name',
       CONCAT(convert(decimal(12, 0), round(sf.size/128.000, 2)), ' MB') AS 'FileSize(MB)',
       convert(VARCHAR(6), LEFT(100 * (sf.size-fileproperty(sf.name, 'SpaceUsed')) / sf.size, 2)) + '%' 'FreeSpace(%)',
                                                                                                        CONCAT(convert(decimal(12, 2), round(fileproperty(sf.name, 'SpaceUsed')/128.000, 2)), ' MB') AS 'SpaceUsed(MB)',
                                                                                                        CONCAT(convert(decimal(12, 2), round((sf.size-fileproperty(sf.name, 'SpaceUsed'))/128.000, 2)), ' MB') AS 'FreeSpace(MB)',
                                                                                                        CASE smf.is_percent_growth
                                                                                                            WHEN 1 THEN CONVERT(VARCHAR(10), smf.growth) +' %'
                                                                                                            ELSE convert(VARCHAR(10), smf.growth/128) +' MB'
                                                                                                        END AS 'AutoGrow',
                                                                                                        CONCAT(convert(decimal(12, 0), round(sf.maxsize/128.000, 2)), ' MB') AS 'AutoGrowthMB(MAX)',
                                                                                                        left(sf.FILENAME, 120) AS 'Location',
                                                                                                        sf.FILEID AS 'FileId'
FROM dbo.sysfiles sf WITH (NOLOCK)
JOIN sys.master_files smf WITH (NOLOCK) ON smf.physical_name = sf.filename
