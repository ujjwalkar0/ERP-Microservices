-- ============================================================================
-- APPEND: Backfill TenantUsers so every tenant has at least one member
-- Safe to run standalone, after the main seed script. Idempotent.
-- ============================================================================

SET NOCOUNT ON;

-- 1. Make sure every tenant's owner is actually linked in TenantUsers
INSERT INTO [Identity].[TenantUsers] (TenantsId, UsersUserId)
SELECT t.Id, t.OwnerId
FROM [Identity].[Tenants] t
WHERE NOT EXISTS (
    SELECT 1 FROM [Identity].[TenantUsers] tu
    WHERE tu.TenantsId = t.Id AND tu.UsersUserId = t.OwnerId
);

PRINT 'Step 1 (owners linked) done.';

-- 2. Make sure every user's "home" tenant (Users.TenantId) is reflected in TenantUsers
--    Joined against Tenants (not just IS NOT NULL) to skip any orphaned TenantId
--    values that don't correspond to a real tenant row.
INSERT INTO [Identity].[TenantUsers] (TenantsId, UsersUserId)
SELECT u.TenantId, u.UserId
FROM [Identity].[Users] u
JOIN [Identity].[Tenants] t ON t.Id = u.TenantId
WHERE NOT EXISTS (
      SELECT 1 FROM [Identity].[TenantUsers] tu
      WHERE tu.TenantsId = u.TenantId AND tu.UsersUserId = u.UserId
  );

PRINT 'Step 2 (home tenants linked) done.';

-- Report any orphaned TenantId values found, so you can investigate the source data
SELECT u.UserId, u.TenantId AS OrphanedTenantId
FROM [Identity].[Users] u
WHERE u.TenantId IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM [Identity].[Tenants] t WHERE t.Id = u.TenantId);

-- 3. Catch-all: any tenant STILL with zero members gets one random existing user assigned
--    (materialized into temp tables to avoid a NEWID()-in-subquery FK check quirk)
IF OBJECT_ID('tempdb..#TenantsWithoutUsers') IS NOT NULL DROP TABLE #TenantsWithoutUsers;
IF OBJECT_ID('tempdb..#AssignedUsers')       IS NOT NULL DROP TABLE #AssignedUsers;

SELECT t.Id AS TenantId
INTO #TenantsWithoutUsers
FROM [Identity].[Tenants] t
WHERE NOT EXISTS (SELECT 1 FROM [Identity].[TenantUsers] tu WHERE tu.TenantsId = t.Id);

SELECT twu.TenantId,
       (SELECT TOP 1 u.UserId FROM [Identity].[Users] u ORDER BY NEWID()) AS UserId
INTO #AssignedUsers
FROM #TenantsWithoutUsers twu;

INSERT INTO [Identity].[TenantUsers] (TenantsId, UsersUserId)
SELECT TenantId, UserId
FROM #AssignedUsers
WHERE UserId IS NOT NULL;

PRINT 'Step 3 (catch-all assignment) done.';

DROP TABLE #TenantsWithoutUsers;
DROP TABLE #AssignedUsers;

-- ============================================================================
-- Verify: should return 0
-- ============================================================================
SELECT COUNT(*) AS TenantsStillWithoutUsers
FROM [Identity].[Tenants] t
WHERE NOT EXISTS (SELECT 1 FROM [Identity].[TenantUsers] tu WHERE tu.TenantsId = t.Id);