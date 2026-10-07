/* ============================================================================
   BULK DATA GENERATOR  ---  Identity / Tenant schema (SQL Server)
   Matches the final state of database.sql (after all EF migrations).

   Insert order is dictated by the FK graph:
     Users            -> first (TenantId has an index but NO FK, so it may
                         point at tenant rows that do not exist yet)
     Tenants          -> needs Users to exist (FK_Tenants_Users_OwnerId)
     Users.RefferedById / RoleId / CreatedBy / UpdatedBy -> back-filled later
     Role -> Permission -> RolePermission -> UserRole / RoleUser
     Claims / Logins / Tokens / Sessions / SecurityEvents

   Self-referencing FKs (ParentTenantId, ParentRoleId) are satisfied inside a
   single INSERT statement because SQL Server validates FKs per statement,
   not per row. Root rows point at themselves.

   HOW TO RUN
     1. Point your session at the right database (USE [YourDb]).
     2. Tune the knobs in the CONFIG section.
     3. Execute. Progress is printed per batch.

   All data is synthetic. Password hashes are placeholder strings, not real
   hashes -- nothing here is usable for login.
   ============================================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;

-- ============================================================================
-- CONFIG  -- change these to control how heavy the load is
-- ============================================================================
DECLARE @TenantCount      int = 200;      -- tenants
DECLARE @RootTenants      int = 20;       -- of those, top-level (self-parented)
DECLARE @UserCount        int = 50000;    -- users  (must be >= @TenantCount)
DECLARE @RolesPerTenant   int = 8;        -- roles per tenant
DECLARE @ClaimsPerUser    int = 3;
DECLARE @TokensPerUser    int = 2;
DECLARE @SessionsPerUser  int = 6;
DECLARE @EventsPerUser    int = 10;
DECLARE @LoginPercent     int = 40;       -- % of users with an external login
DECLARE @ReferralPercent  int = 70;       -- % of users that were referred
DECLARE @BatchSize        int = 20000;    -- users per batch for the big tables

/* Rough row estimate at the defaults:
     Users 50k | Tenants 200 | TenantUsers ~52k | Role 1.6k | Permission 120
     RolePermission ~77k | UserRole ~110k | RoleUser ~110k | UserClaim 150k
     UserLogins 20k | UserToken 100k | UserSession 300k | SecurityEvents 500k
   ~1.4M rows total. Scale @UserCount to go bigger -- everything else follows. */

IF @UserCount < @TenantCount
BEGIN
    RAISERROR('@UserCount must be >= @TenantCount (every tenant needs an owner).', 16, 1);
    RETURN;
END

DECLARE @t0 datetime2 = SYSUTCDATETIME();
PRINT '=== Generating data: ' + CAST(@UserCount AS varchar(20)) + ' users / '
      + CAST(@TenantCount AS varchar(20)) + ' tenants ===';

-- ============================================================================
-- 0. Numbers (tally) table + lookup value lists
-- ============================================================================
IF OBJECT_ID('tempdb..#Nums')  IS NOT NULL DROP TABLE #Nums;
IF OBJECT_ID('tempdb..#T')     IS NOT NULL DROP TABLE #T;
IF OBJECT_ID('tempdb..#U')     IS NOT NULL DROP TABLE #U;
IF OBJECT_ID('tempdb..#R')     IS NOT NULL DROP TABLE #R;
IF OBJECT_ID('tempdb..#P')     IS NOT NULL DROP TABLE #P;

DECLARE @MaxN int = CASE WHEN @UserCount > 1000000 THEN @UserCount ELSE 1000000 END;

;WITH E1(N) AS (SELECT 1 FROM (VALUES(1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) v(N)),
      E2(N) AS (SELECT 1 FROM E1 a CROSS JOIN E1 b),
      E4(N) AS (SELECT 1 FROM E2 a CROSS JOIN E2 b),
      E6(N) AS (SELECT 1 FROM E4 a CROSS JOIN E2 b),
      E8(N) AS (SELECT 1 FROM E6 a CROSS JOIN E2 b)
SELECT TOP (@MaxN) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
INTO #Nums
FROM E8;
CREATE UNIQUE CLUSTERED INDEX CIX_Nums ON #Nums(N);

DECLARE @First TABLE (Id int IDENTITY(1,1) PRIMARY KEY, V nvarchar(40));
INSERT @First(V) VALUES
 (N'Aarav'),(N'Priya'),(N'Rohan'),(N'Ananya'),(N'Vikram'),(N'Meera'),(N'Arjun'),(N'Kavya'),
 (N'Ishaan'),(N'Divya'),(N'Karan'),(N'Neha'),(N'Siddharth'),(N'Riya'),(N'Aditya'),(N'Sneha'),
 (N'Liam'),(N'Emma'),(N'Noah'),(N'Olivia'),(N'Mateo'),(N'Sofia'),(N'Yusuf'),(N'Amara'),
 (N'Chen'),(N'Mei'),(N'Hiroshi'),(N'Yuki'),(N'Lucas'),(N'Isabela');

DECLARE @Last TABLE (Id int IDENTITY(1,1) PRIMARY KEY, V nvarchar(40));
INSERT @Last(V) VALUES
 (N'Sharma'),(N'Patel'),(N'Reddy'),(N'Nair'),(N'Iyer'),(N'Gupta'),(N'Khan'),(N'Joshi'),
 (N'Mehta'),(N'Bose'),(N'Smith'),(N'Johnson'),(N'Garcia'),(N'Martinez'),(N'Brown'),(N'Wilson'),
 (N'Okafor'),(N'Mwangi'),(N'Haddad'),(N'Novak'),(N'Kim'),(N'Tanaka'),(N'Zhang'),(N'Silva'),
 (N'Rossi'),(N'Dubois'),(N'Muller'),(N'Andersen'),(N'Costa'),(N'OConnor');

DECLARE @Domain TABLE (Id int IDENTITY(1,1) PRIMARY KEY, V nvarchar(60));
INSERT @Domain(V) VALUES
 (N'example.com'),(N'contoso.io'),(N'northwind.dev'),(N'fabrikam.net'),(N'acme-corp.co'),
 (N'testmail.org'),(N'demo-suite.app'),(N'sandbox.dev');

DECLARE @Company TABLE (Id int IDENTITY(1,1) PRIMARY KEY, V nvarchar(60));
INSERT @Company(V) VALUES
 (N'Contoso'),(N'Fabrikam'),(N'Northwind'),(N'Adventure Works'),(N'Litware'),(N'Proseware'),
 (N'Wingtip'),(N'Tailspin'),(N'Blue Yonder'),(N'Lucerne'),(N'Trey Research'),(N'Alpine Ski'),
 (N'Woodgrove'),(N'Humongous'),(N'Consolidated'),(N'VanArsdel');

DECLARE @Suffix TABLE (Id int IDENTITY(1,1) PRIMARY KEY, V nvarchar(30));
INSERT @Suffix(V) VALUES
 (N'Holdings'),(N'Labs'),(N'Systems'),(N'Digital'),(N'Partners'),(N'Group'),(N'Technologies'),(N'Industries');

DECLARE @RoleName TABLE (Id int IDENTITY(1,1) PRIMARY KEY, V nvarchar(40), IsSystem bit);
INSERT @RoleName(V, IsSystem) VALUES
 (N'Owner',1),(N'Administrator',1),(N'Manager',0),(N'Editor',0),
 (N'Contributor',0),(N'Analyst',0),(N'Support Agent',0),(N'Viewer',0),
 (N'Auditor',0),(N'Billing Admin',0),(N'Developer',0),(N'Guest',0);

DECLARE @Module TABLE (Id int IDENTITY(1,1) PRIMARY KEY, V nvarchar(60));
INSERT @Module(V) VALUES
 (N'Tenants'),(N'Users'),(N'Roles'),(N'Permissions'),(N'Billing'),(N'Reports'),
 (N'Settings'),(N'Audit'),(N'Sessions'),(N'Notifications'),(N'Files'),(N'Integrations'),
 (N'Api'),(N'Webhooks'),(N'Support'),(N'Dashboard'),(N'Exports'),(N'Security'),
 (N'Subscriptions'),(N'Invitations');

DECLARE @Action TABLE (Id int IDENTITY(1,1) PRIMARY KEY, V nvarchar(30));
INSERT @Action(V) VALUES (N'Read'),(N'Create'),(N'Update'),(N'Delete'),(N'Export'),(N'Approve');

DECLARE @ClaimType TABLE (Id int IDENTITY(1,1) PRIMARY KEY, V nvarchar(80));
INSERT @ClaimType(V) VALUES
 (N'department'),(N'country'),(N'timezone'),(N'employee_id'),(N'cost_center'),(N'locale'),(N'mfa_enabled');

DECLARE @ClaimVal TABLE (Id int IDENTITY(1,1) PRIMARY KEY, V nvarchar(80));
INSERT @ClaimVal(V) VALUES
 (N'engineering'),(N'IN'),(N'Asia/Kolkata'),(N'EMP-00917'),(N'CC-4412'),(N'en-IN'),(N'true'),
 (N'finance'),(N'US'),(N'America/New_York'),(N'en-US'),(N'false');

DECLARE @Provider TABLE (Id int IDENTITY(1,1) PRIMARY KEY, V nvarchar(40));
INSERT @Provider(V) VALUES (N'Google'),(N'Microsoft'),(N'GitHub'),(N'Apple'),(N'Okta'),(N'LinkedIn');

DECLARE @EventType TABLE (Id int IDENTITY(1,1) PRIMARY KEY, V nvarchar(60), Severity int);
INSERT @EventType(V, Severity) VALUES
 (N'LoginSucceeded',1),(N'LoginFailed',2),(N'PasswordChanged',2),(N'PasswordResetRequested',2),
 (N'MfaChallengeSucceeded',1),(N'MfaChallengeFailed',3),(N'LockedOut',3),(N'RoleAssigned',2),
 (N'PermissionDenied',2),(N'TokenRevoked',2),(N'SuspiciousLocation',3),(N'BruteForceDetected',4),
 (N'SessionExpired',1),(N'EmailChanged',2),(N'ApiKeyCreated',2);

-- ============================================================================
-- 1. Tenant staging (GUIDs + hierarchy decided up front)
-- ============================================================================
SELECT
    n.N                         AS rn,
    NEWID()                     AS Id,
    CAST(NULL AS uniqueidentifier) AS OwnerId,
    CASE WHEN n.N <= @RootTenants THEN n.N
         ELSE ((n.N * 3) % @RootTenants) + 1 END AS ParentRn
INTO #T
FROM #Nums n
WHERE n.N <= @TenantCount;
CREATE UNIQUE CLUSTERED INDEX CIX_T ON #T(rn);

-- ============================================================================
-- 2. User staging (round-robin across tenants so rn -> tenant is predictable)
-- ============================================================================
DECLARE @nFirst int  = (SELECT COUNT(*) FROM @First);
DECLARE @nLast  int  = (SELECT COUNT(*) FROM @Last);
DECLARE @nDom   int  = (SELECT COUNT(*) FROM @Domain);

SELECT
    n.N                                   AS rn,
    NEWID()                               AS UserId,
    ((n.N - 1) % @TenantCount) + 1        AS TenantRn,
    f.V                                   AS FirstName,
    l.V                                   AS LastName,
    d.V                                   AS Domain
INTO #U
FROM #Nums n
JOIN @First  f ON f.Id = ((n.N * 7)  % @nFirst) + 1
JOIN @Last   l ON l.Id = ((n.N * 13) % @nLast)  + 1
JOIN @Domain d ON d.Id = ((n.N * 5)  % @nDom)   + 1
WHERE n.N <= @UserCount;
CREATE UNIQUE CLUSTERED INDEX CIX_U ON #U(rn);
CREATE INDEX IX_U_Tenant ON #U(TenantRn, rn);

UPDATE t
SET OwnerId = u.UserId
FROM #T t
JOIN #U u ON u.rn = t.rn;          -- user #n owns tenant #n (round-robin guarantees match)

-- ============================================================================
-- 3. Users  (RefferedById / RoleId / CreatedBy / UpdatedBy filled in later)
-- ============================================================================
PRINT 'Inserting Users...';

INSERT INTO [Identity].[Users]
    (UserId, Username, Email, NormalizedEmail, PasswordHash, SecurityStamp,
     TenantId, AvatarUrl, IsActive, CreatedAt, UpdatedAt,
     CreatedBy, UpdatedBy, RefferedById, RoleId)
SELECT
    u.UserId,
    LOWER(u.FirstName + N'.' + u.LastName + CAST(u.rn AS nvarchar(12))),
    LOWER(u.FirstName + N'.' + u.LastName + CAST(u.rn AS nvarchar(12)) + N'@' + u.Domain),
    UPPER(u.FirstName + N'.' + u.LastName + CAST(u.rn AS nvarchar(12)) + N'@' + u.Domain),
    -- placeholder, NOT a real hash
    N'AQAAAAIAAYagAAAAE' + REPLACE(CAST(NEWID() AS nvarchar(36)), N'-', N''),
    REPLACE(CAST(NEWID() AS nvarchar(36)), N'-', N''),
    t.Id,
    CASE WHEN u.rn % 4 = 0 THEN NULL
         ELSE N'https://cdn.example.com/avatars/' + CAST(u.rn % 500 AS nvarchar(6)) + N'.png' END,
    CASE WHEN u.rn % 11 = 0 THEN CAST(0 AS bit) ELSE CAST(1 AS bit) END,
    DATEADD(MINUTE, -(u.rn % 1051) * 37, DATEADD(DAY, -(u.rn % 900), SYSUTCDATETIME())),
    DATEADD(HOUR,   -(u.rn % 720),  SYSUTCDATETIME()),
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000000',
    NULL,
    '00000000-0000-0000-0000-000000000000'
FROM #U u
JOIN #T t ON t.rn = u.TenantRn;

PRINT '  Users: ' + CAST(@@ROWCOUNT AS varchar(20));

-- ============================================================================
-- 4. Tenants  (OwnerId FK now resolvable; roots self-parent)
-- ============================================================================
PRINT 'Inserting Tenants...';

DECLARE @nComp int = (SELECT COUNT(*) FROM @Company);
DECLARE @nSuf  int = (SELECT COUNT(*) FROM @Suffix);

INSERT INTO [Identity].[Tenants]
    (Id, Name, Slug, ParentTenantId, IsActive, CreatedAt, ExpireAt, OwnerId, PlanId)
SELECT
    t.Id,
    c.V + N' ' + s.V + N' ' + CAST(t.rn AS nvarchar(10)),
    LOWER(REPLACE(c.V, N' ', N'-')) + N'-' + LOWER(s.V) + N'-' + CAST(t.rn AS nvarchar(10)),
    p.Id,
    CASE WHEN t.rn % 17 = 0 THEN CAST(0 AS bit) ELSE CAST(1 AS bit) END,
    DATEADD(DAY, -(900 - (t.rn % 800)), SYSUTCDATETIME()),
    DATEADD(DAY,  (30 + (t.rn % 700)),  SYSUTCDATETIME()),
    t.OwnerId,
    NEWID()
FROM #T t
JOIN #T p       ON p.rn = t.ParentRn
JOIN @Company c ON c.Id = ((t.rn * 3) % @nComp) + 1
JOIN @Suffix  s ON s.Id = ((t.rn * 5) % @nSuf)  + 1;

PRINT '  Tenants: ' + CAST(@@ROWCOUNT AS varchar(20));

-- ============================================================================
-- 5. Back-fill Users: audit columns + referral chain
-- ============================================================================
PRINT 'Back-filling Users (CreatedBy / UpdatedBy / RefferedById)...';

UPDATE usr
SET CreatedBy = t.OwnerId,
    UpdatedBy = t.OwnerId
FROM [Identity].[Users] usr
JOIN #U u ON u.UserId = usr.UserId
JOIN #T t ON t.rn = u.TenantRn;

-- referrer is an earlier user in the SAME tenant (rn - k * @TenantCount)
UPDATE usr
SET RefferedById = p.UserId
FROM [Identity].[Users] usr
JOIN #U s ON s.UserId = usr.UserId
JOIN #U p ON p.rn = s.rn - (@TenantCount * ((ABS(CHECKSUM(s.UserId)) % 3) + 1))
WHERE ABS(CHECKSUM(s.UserId, 17)) % 100 < @ReferralPercent;

PRINT '  Referrals set: ' + CAST(@@ROWCOUNT AS varchar(20));

-- ============================================================================
-- 6. TenantUsers  (own tenant for everyone + ~5% cross-tenant membership)
-- ============================================================================
PRINT 'Inserting TenantUsers...';

INSERT INTO [Identity].[TenantUsers] (TenantsId, UsersUserId)
SELECT DISTINCT x.TenantId, x.UserId
FROM (
    SELECT t.Id AS TenantId, u.UserId
    FROM #U u JOIN #T t ON t.rn = u.TenantRn
    UNION
    SELECT t2.Id, u.UserId
    FROM #U u
    JOIN #T t2 ON t2.rn = ((u.rn * 7) % @TenantCount) + 1
    WHERE ABS(CHECKSUM(u.UserId, 31)) % 100 < 5
) x;

PRINT '  TenantUsers: ' + CAST(@@ROWCOUNT AS varchar(20));

-- ============================================================================
-- 7. Role  (per tenant; index 1 is the self-parented root of that tenant)
-- ============================================================================
PRINT 'Inserting Roles...';

DECLARE @nRoleName int = (SELECT COUNT(*) FROM @RoleName);

SELECT
    t.rn        AS TenantRn,
    r.N         AS RoleIdx,
    NEWID()     AS Id,
    t.OwnerId   AS OwnerId
INTO #R
FROM #T t
CROSS JOIN (SELECT N FROM #Nums WHERE N <= @RolesPerTenant) r;
CREATE UNIQUE CLUSTERED INDEX CIX_R ON #R(TenantRn, RoleIdx);

INSERT INTO [Identity].[Role] (Id, Name, NormalizedName, ParentRoleId, IsSystem, UserId)
SELECT
    r.Id,
    rn.V + N' T' + CAST(r.TenantRn AS nvarchar(10)),
    UPPER(REPLACE(rn.V, N' ', N'_')) + N'_T' + CAST(r.TenantRn AS nvarchar(10)),
    parent.Id,
    rn.IsSystem,
    r.OwnerId
FROM #R r
JOIN @RoleName rn ON rn.Id = ((r.RoleIdx - 1) % @nRoleName) + 1
JOIN #R parent    ON parent.TenantRn = r.TenantRn
                 AND parent.RoleIdx  = CASE WHEN r.RoleIdx = 1 THEN 1 ELSE 1 END;  -- root of own tenant

PRINT '  Roles: ' + CAST(@@ROWCOUNT AS varchar(20));

-- ============================================================================
-- 8. Permission  (module x action matrix)
-- ============================================================================
PRINT 'Inserting Permissions...';

INSERT INTO [Identity].[Permission] (Id, Code, Name, Module)
SELECT NEWID(), m.V + N'.' + a.V, a.V + N' ' + m.V, m.V
FROM @Module m CROSS JOIN @Action a;

SELECT Id, Code INTO #P FROM [Identity].[Permission];
CREATE UNIQUE CLUSTERED INDEX CIX_P ON #P(Id);

DECLARE @cnt int;
SELECT @cnt = COUNT(*) FROM #P;
PRINT '  Permissions: ' + CAST(@cnt AS varchar(20));

-- ============================================================================
-- 9. RolePermission  (~40% of the role x permission matrix, ~5% denied)
-- ============================================================================
PRINT 'Inserting RolePermissions...';

INSERT INTO [Identity].[RolePermission] (Id, RoleId, PermissionId, IsDeined)
SELECT NEWID(), r.Id, p.Id,
       CASE WHEN ABS(CHECKSUM(r.Id, p.Id, 7)) % 20 = 0 THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END
FROM #R r
JOIN #P p ON r.RoleIdx <= 2                              -- Owner/Admin get everything
          OR (ABS(CHECKSUM(r.Id, p.Id)) % 10) < 4;       -- others get ~40%

PRINT '  RolePermissions: ' + CAST(@@ROWCOUNT AS varchar(20));

-- ============================================================================
-- 10. UserRole  (one primary role per user + occasional extras)
-- ============================================================================
PRINT 'Inserting UserRoles...';

-- primary role
INSERT INTO [Identity].[UserRole] (Id, UserId, RoleId, AssignedBy)
SELECT NEWID(), u.UserId, r.Id, r.OwnerId
FROM #U u
JOIN #R r ON r.TenantRn = u.TenantRn
         AND r.RoleIdx  = (ABS(CHECKSUM(u.UserId)) % @RolesPerTenant) + 1;

-- extra roles (~20% chance per remaining role)
INSERT INTO [Identity].[UserRole] (Id, UserId, RoleId, AssignedBy)
SELECT NEWID(), u.UserId, r.Id, r.OwnerId
FROM #U u
JOIN #R r ON r.TenantRn = u.TenantRn
         AND r.RoleIdx <> (ABS(CHECKSUM(u.UserId)) % @RolesPerTenant) + 1
         AND (ABS(CHECKSUM(u.UserId, r.Id)) % 10) < 2;

SELECT @cnt = COUNT(*) FROM [Identity].[UserRole];
PRINT '  UserRoles: ' + CAST(@cnt AS varchar(20));

-- keep the many-to-many navigation table consistent with UserRole
INSERT INTO [Identity].[RoleUser] (RolesId, UsersUserId)
SELECT DISTINCT RoleId, UserId FROM [Identity].[UserRole];

PRINT '  RoleUser: ' + CAST(@@ROWCOUNT AS varchar(20));

-- Users.RoleId points at the primary role
UPDATE usr
SET RoleId = r.Id
FROM [Identity].[Users] usr
JOIN #U u ON u.UserId = usr.UserId
JOIN #R r ON r.TenantRn = u.TenantRn
         AND r.RoleIdx  = (ABS(CHECKSUM(u.UserId)) % @RolesPerTenant) + 1;

-- ============================================================================
-- 11. UserClaim
-- ============================================================================
PRINT 'Inserting UserClaims...';

DECLARE @nCT int = (SELECT COUNT(*) FROM @ClaimType);
DECLARE @nCV int = (SELECT COUNT(*) FROM @ClaimVal);

INSERT INTO [dbo].[UserClaim] (Id, UserId, ClaimType, ClaimValue)
SELECT NEWID(), u.UserId, ct.V, cv.V
FROM #U u
JOIN #Nums n     ON n.N <= @ClaimsPerUser
JOIN @ClaimType ct ON ct.Id = (((u.rn + n.N) * 3) % @nCT) + 1
JOIN @ClaimVal  cv ON cv.Id = (((u.rn + n.N) * 5) % @nCV) + 1;

PRINT '  UserClaims: ' + CAST(@@ROWCOUNT AS varchar(20));

-- ============================================================================
-- 12. UserLogins  (PK is LoginProvider + ProviderKey, so keys carry rn)
-- ============================================================================
PRINT 'Inserting UserLogins...';

DECLARE @nProv int = (SELECT COUNT(*) FROM @Provider);

INSERT INTO [dbo].[UserLogins] (LoginProvider, ProviderKey, UserId)
SELECT pv.V,
       LOWER(pv.V) + N'|' + CAST(u.rn AS nvarchar(12)) + N'|'
            + LEFT(REPLACE(CAST(NEWID() AS nvarchar(36)), N'-', N''), 16),
       u.UserId
FROM #U u
JOIN @Provider pv ON pv.Id = ((u.rn * 11) % @nProv) + 1
WHERE ABS(CHECKSUM(u.UserId, 43)) % 100 < @LoginPercent;

PRINT '  UserLogins: ' + CAST(@@ROWCOUNT AS varchar(20));

-- ============================================================================
-- 13. UserToken  (PK is UserId + LoginProvider + Name)
-- ============================================================================
PRINT 'Inserting UserTokens...';

DECLARE @TokenName TABLE (Id int IDENTITY(1,1) PRIMARY KEY, V nvarchar(60));
INSERT @TokenName(V) VALUES
 (N'RefreshToken'),(N'AccessToken'),(N'ResetPassword'),(N'EmailConfirmation'),(N'AuthenticatorKey');

INSERT INTO [dbo].[UserToken] (UserId, LoginProvider, Name, Value)
SELECT u.UserId, N'Local', tn.V,
       REPLACE(CAST(NEWID() AS nvarchar(36)), N'-', N'')
     + REPLACE(CAST(NEWID() AS nvarchar(36)), N'-', N'')
FROM #U u
JOIN #Nums n      ON n.N <= @TokensPerUser
JOIN @TokenName tn ON tn.Id = n.N;

PRINT '  UserTokens: ' + CAST(@@ROWCOUNT AS varchar(20));

-- ============================================================================
-- 14. UserSession + SecurityEvents  (the big ones -- inserted in batches so
--     the transaction log does not blow up on large @UserCount values)
-- ============================================================================
PRINT 'Inserting UserSessions and SecurityEvents (batched)...';

DECLARE @nEvt int = (SELECT COUNT(*) FROM @EventType);
DECLARE @lo int = 1, @hi int = 0, @batchNo int = 0;

WHILE @lo <= @UserCount
BEGIN
    SET @hi = @lo + @BatchSize - 1;
    SET @batchNo = @batchNo + 1;

    INSERT INTO [dbo].[UserSession] (Id, UserId, DeviceId, IpAddress, ExpireAt, CreatedAt)
    SELECT
        NEWID(),
        u.UserId,
        NEWID(),
        CAST(10 + (u.rn + n.N) % 240 AS nvarchar(3)) + N'.'
          + CAST((u.rn * 3 + n.N) % 256 AS nvarchar(3)) + N'.'
          + CAST((u.rn * 7 + n.N) % 256 AS nvarchar(3)) + N'.'
          + CAST((u.rn * 11 + n.N) % 254 + 1 AS nvarchar(3)),
        DATEADD(HOUR,  (u.rn + n.N) % 720, SYSUTCDATETIME()),
        DATEADD(MINUTE, -((u.rn * 13 + n.N * 97) % 525600), SYSUTCDATETIME())
    FROM #U u
    JOIN #Nums n ON n.N <= @SessionsPerUser
    WHERE u.rn BETWEEN @lo AND @hi;

    INSERT INTO [Identity].[SecurityEvents] (Id, UserId, EventType, Severity, IpAddress, [Timestamp])
    SELECT
        NEWID(),
        u.UserId,
        e.V,
        e.Severity,
        CAST(10 + (u.rn + n.N * 3) % 240 AS nvarchar(3)) + N'.'
          + CAST((u.rn * 5 + n.N) % 256 AS nvarchar(3)) + N'.'
          + CAST((u.rn * 17 + n.N) % 256 AS nvarchar(3)) + N'.'
          + CAST((u.rn * 23 + n.N) % 254 + 1 AS nvarchar(3)),
        DATEADD(MINUTE, -((u.rn * 29 + n.N * 613) % 525600), SYSUTCDATETIME())
    FROM #U u
    JOIN #Nums n   ON n.N <= @EventsPerUser
    JOIN @EventType e ON e.Id = (((u.rn * 7) + n.N) % @nEvt) + 1
    WHERE u.rn BETWEEN @lo AND @hi;

    PRINT '  batch ' + CAST(@batchNo AS varchar(10))
          + ' (users ' + CAST(@lo AS varchar(12)) + '-'
          + CAST(CASE WHEN @hi > @UserCount THEN @UserCount ELSE @hi END AS varchar(12)) + ') done';

    SET @lo = @hi + 1;
END

-- ============================================================================
-- 15. Summary
-- ============================================================================
PRINT '=== Finished in '
      + CAST(DATEDIFF(SECOND, @t0, SYSUTCDATETIME()) AS varchar(20)) + ' seconds ===';

SELECT 'Identity.Tenants'        AS TableName, COUNT_BIG(*) AS Rows FROM [Identity].[Tenants]
UNION ALL SELECT 'Identity.Users',          COUNT_BIG(*) FROM [Identity].[Users]
UNION ALL SELECT 'Identity.TenantUsers',    COUNT_BIG(*) FROM [Identity].[TenantUsers]
UNION ALL SELECT 'Identity.Role',           COUNT_BIG(*) FROM [Identity].[Role]
UNION ALL SELECT 'Identity.RoleUser',       COUNT_BIG(*) FROM [Identity].[RoleUser]
UNION ALL SELECT 'Identity.UserRole',       COUNT_BIG(*) FROM [Identity].[UserRole]
UNION ALL SELECT 'Identity.Permission',     COUNT_BIG(*) FROM [Identity].[Permission]
UNION ALL SELECT 'Identity.RolePermission', COUNT_BIG(*) FROM [Identity].[RolePermission]
UNION ALL SELECT 'Identity.SecurityEvents', COUNT_BIG(*) FROM [Identity].[SecurityEvents]
UNION ALL SELECT 'dbo.UserClaim',           COUNT_BIG(*) FROM [dbo].[UserClaim]
UNION ALL SELECT 'dbo.UserLogins',          COUNT_BIG(*) FROM [dbo].[UserLogins]
UNION ALL SELECT 'dbo.UserToken',           COUNT_BIG(*) FROM [dbo].[UserToken]
UNION ALL SELECT 'dbo.UserSession',         COUNT_BIG(*) FROM [dbo].[UserSession]
ORDER BY TableName;

DROP TABLE #Nums, #T, #U, #R, #P;
GO


/* ============================================================================
   RESET -- wipe generated data (child tables first). Uncomment to use.
   ============================================================================
DELETE FROM [Identity].[SecurityEvents];
DELETE FROM [dbo].[UserSession];
DELETE FROM [dbo].[UserToken];
DELETE FROM [dbo].[UserLogins];
DELETE FROM [dbo].[UserClaim];
DELETE FROM [Identity].[RolePermission];
DELETE FROM [Identity].[RoleUser];
DELETE FROM [Identity].[UserRole];
DELETE FROM [Identity].[TenantUsers];
DELETE FROM [Identity].[Permission];
-- break the self / cross references before deleting the parents
UPDATE [Identity].[Role]    SET ParentRoleId   = Id;
UPDATE [Identity].[Users]   SET RefferedById   = NULL;
UPDATE [Identity].[Tenants] SET ParentTenantId = Id;
ALTER TABLE [Identity].[Tenants] NOCHECK CONSTRAINT [FK_Tenants_Users_OwnerId];
DELETE FROM [Identity].[Role];
DELETE FROM [Identity].[Tenants];
DELETE FROM [Identity].[Users];
ALTER TABLE [Identity].[Tenants] WITH CHECK CHECK CONSTRAINT [FK_Tenants_Users_OwnerId];
GO
*/