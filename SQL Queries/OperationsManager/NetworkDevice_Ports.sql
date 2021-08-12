;WITH 
CTE as (
SELECT
 n.DisplayName as 'NetworkDeviceName',
 n.Vendor_16EE4AB2_CBCC_BAD3_B249_A56E6BF207D0 as Vendor,
 n.Model_4BD92846_5429_2E69_6653_C6A6F7D9D484 as Model,
 b.Path,count(b.path) as DiscoveredPortCount
FROM MT_System$NetworkManagement$Port p WITH(NOLOCK)
JOIN BaseManagedEntity b WITH(NOLOCK) on p.BaseManagedEntityId=b.BaseManagedEntityId
JOIN dbo.MTV_System$NetworkManagement$Node n WITH (NOLOCK) on b.TopLevelHostEntityId=n.BaseManagedEntityId
GROUP BY n.DisplayName, n.Vendor_16EE4AB2_CBCC_BAD3_B249_A56E6BF207D0, n.Model_4BD92846_5429_2E69_6653_C6A6F7D9D484, b.Path
),

cte1 as (
SELECT
 b.Path,count(b.path) as MonitoredPortCount
FROM MT_System$NetworkManagement$Port p WITH(NOLOCK)
JOIN state s WITH(NOLOCK) on p.BaseManagedEntityId=s.BaseManagedEntityId
JOIN BaseManagedEntity b WITH(NOLOCK) on s.BaseManagedEntityId=b.BaseManagedEntityId 
join Monitor m WITH(NOLOCK) on m.MonitorId = s.MonitorId
WHERE m.MonitorName='System.Health.EntityState' and s.HealthState<>0
GROUP BY b.Path
)

SELECT 
  c1.NetworkDeviceName,
  c1.Vendor,
  c1.Model, 
  c1.DiscoveredPortCount, 
  case when (c2.MonitoredPortCount IS NULL) THEN 0 ELSE c2.MonitoredPortCount END AS MonitoredPortCount 
FROM cte c1 left join cte1 c2 on c1.Path=c2.Path
