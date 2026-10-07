## Basic querying (1–10)

1. Get all users with IsActive = true.
2. Get a single user by UserId using Find vs FirstOrDefault vs SingleOrDefault — compare behavior when the id doesn't exist.
3. Get the first 10 tenants ordered by CreatedAt ascending.
4. Get usernames only (a single-column projection) for all users in a tenant.
5. Get tenants whose Name contains a given substring, case-insensitively.
6. Get users created in the last 7 days.
7. Get the count of all permissions grouped by Module.
8. Get distinct Module values from Permission.
9. Check whether a username already exists (AnyAsync) before insert.
10. Get users ordered by CreatedAt, then break ties with UserId.

## Filtering and predicates (11–20)
11. Get users whose email domain is contoso.io (parse from Email).
12. Get users where AvatarUrl is null OR RefferedById is null.
13. Get tenants expiring in the next 30 days AND still active.
14. Get users NOT in a given list of UserIds.
15. Build a dynamic filter: search by username, email, or tenant name depending on which parameter is non-null (PredicateBuilder or expression composition).
16. Get users whose CreatedAt falls on a weekend.
17. Get roles where IsSystem = true for a specific tenant's role set.
18. Get SecurityEvents with Severity >= 3 in the last 24 hours.
19. Get users updated more recently than they were created by more than a given threshold.
20. Filter permissions by a list of Code values using Contains.

## Joins (21–35)
21. Join Users to Tenants on TenantId (no FK exists — write it as an explicit join).
22. Join UserRole → Role → RolePermission → Permission to list a user's effective permissions.
23. Join TenantUsers to get all tenants a user belongs to, including their "home" tenant via Users.TenantId, deduplicated.
24. Left join tenants to users so tenants with zero users still appear, with UserCount = 0.
25. Join UserLogins to Users to list which provider each user signed up with.
26. Join UserClaim to Users and pivot claims into columns (department, timezone, etc.) per user.
27. Self-join Users to Users via RefferedById to build a referrer/referee pair list.
28. Join Role to Role via ParentRoleId to list each role with its parent's name.
29. Join Tenants to Tenants via ParentTenantId, excluding self-referencing roots.
30. Cross join Role and Permission to find permission codes NOT covered by any RolePermission row for that role (anti-join).
31. Join UserSession to Users to find sessions with ExpireAt in the past that are presumably stale.
32. Join SecurityEvents to Users to Tenants to report events per tenant.
33. Multi-join: Users → UserRole → Role → filter by role name → project username + role name.
34. Join UserToken to Users where Name = 'RefreshToken' and the token was issued (approximate via a naming/date convention you add).
35. Join RoleUser and UserRole and confirm (or find mismatches) that both reflect the same assignments.

# Grouping and aggregation (36–50)
36. Count users per tenant, sorted descending.
37. Count active vs inactive users per tenant (GroupBy + conditional sum).
38. Find the tenant with the most roles.
39. Average number of permissions per role.
40. Total SecurityEvents per EventType, per month, for the last 6 months.
41. Find the busiest hour of day for LoginSucceeded events (group by hour extracted from Timestamp).
42. Group users by referral chain depth (how many hops back to a non-referred user) — recursive, tricky.
43. Find the min and max CreatedAt per tenant.
44. Group UserClaim by ClaimType and count distinct ClaimValues.
45. For each Module, count permissions and, separately, how many are actually granted to at least one role.
46. Group sessions by DeviceId to find users with more than 3 distinct devices.
47. Find tenants where the owner is NOT a member of that tenant in TenantUsers (data integrity check via grouping/anti-join).
48. Group roles by IsSystem and count users assigned to each group.
49. Running total of tenant signups per day over the last 90 days.
50. Find the median CreatedAt gap between consecutive users in the same tenant (this pushes past plain LINQ into raw SQL or client evaluation — notice where).

# Existence, Any/All, set logic (51–60)
51. Users who have never triggered a SecurityEvent.
52. Users who have at least one UserRole with a system role.
53. Tenants with no expired sessions among their users.
54. Roles with zero granted permissions.
55. Users present in TenantUsers for a tenant other than their TenantId.
56. Find users who have ALL of a given set of permission codes (not just any).
57. Find permissions that are granted to every role in a tenant (rare, but write the query).
58. Tenants whose owner has IsActive = false — should probably not happen; find it.
59. Users with a UserLogins row for Google but not for Microsoft.
60. Symmetric difference: users in tenant A's TenantUsers but not tenant B's, and vice versa.

# Hierarchies and recursion (61–68)
61. Get direct children of a tenant.
62. Get all descendants of a tenant at any depth (compare Include chains vs a recursive CTE via FromSql).
63. Get all ancestors of a tenant up to the root.
64. Compute the depth of each tenant in its hierarchy.
65. Same three (children/descendants/ancestors) for Role.ParentRoleId.
66. Detect any accidental cycles in ParentTenantId beyond the intended self-referencing roots.
67. For a given role, get the union of permissions from itself and all its ancestor roles.
68. Find the "widest" level of the tenant tree (the depth with the most nodes).

# Projections and DTOs (69–75)
69. Project into an anonymous type combining username, tenant name, and primary role name.
70. Project into a named DTO/record and confirm EF still avoids loading full entities.
71. Use Select with a nested collection projection (user with a list of their role names, no separate query).
72. Conditionally project a field based on another field's value (e.g., mask email if user inactive).
73. Project a computed column, like DaysSinceCreated, and check whether it's computed in SQL or in memory.
74. Return paginated results plus a total count in one round trip.
75. Project into a dictionary keyed by UserId.

# Change tracking, tracking behavior (76–82)
76. Load a user with AsNoTracking, modify a field, call SaveChanges — confirm nothing persists — then fix it.
77. Load the same user twice in one context and confirm you get the same tracked instance.
78. Detach an entity mid-context and try to update it again.
79. Use AsNoTrackingWithIdentityResolution on a query with duplicate related entities and explain why it matters.
80. Update a user's IsActive via a tracked entity vs via ExecuteUpdateAsync, and compare the generated SQL.
81. Demonstrate a scenario where change tracking causes an unexpected UPDATE on an unrelated column (owned types or shadow properties).
82. Show what happens when two DbContexts load and save the same row concurrently (concurrency conflict) — add a rowversion/timestamp column mentally and describe the fix.

# Includes and loading strategies (83–90)
83. Eager-load a user's roles and each role's permissions with Include/ThenInclude.
84. Same query using AsSplitQuery and compare the SQL and round trips.
85. Explicit loading: load a user first, then explicitly load their TenantUsers afterward.
86. Lazy loading: enable it, then show the classic N+1 it causes when iterating tenants and touching .Users.
87. Filtered include: load users with only their active sessions (ExpireAt in the future).
88. Include a self-referencing navigation one level deep only (a role and its immediate parent, not the whole chain).
89. Combine Include with Where and explain why filtering after Include behaves differently than filtering the root query.
90. Load a tenant with a capped number of related users (e.g., latest 5) — note this needs a workaround pre-EF9/with Take inside Include where supported.

# Writes: insert/update/delete (91–100)
91. Insert a new tenant plus its owner user in one SaveChanges call, letting EF resolve the FK from navigation properties.
92. Bulk-insert 100 UserClaim rows for one user in a single call.
93. Update a role's Name and confirm only that column appears in the generated UPDATE.
94. Soft-delete a user (flip IsActive) vs hard-delete, and trace what happens to dependent rows in UserRole, UserClaim, etc. given the ON DELETE CASCADE settings in the schema.
95. Delete a tenant and observe the FK constraint failures caused by ON DELETE NO ACTION on ParentTenantId and FK_Tenants_Users_OwnerId — then write the cleanup order needed.
96. Reassign all users from one role to another using ExecuteUpdateAsync on UserRole.
97. Add a permission and grant it to every "Owner" role across all tenants in one batch.
98. Implement optimistic concurrency on Users (add a rowversion column, then write the retry logic for a DbUpdateConcurrencyException).
99. Write a transaction that creates a tenant, its owner user, a default role, and the RolePermission grants for that role — all atomic, rolling back cleanly on any failure.
100. Seed data via HasData in OnModelCreating for the Permission table, and explain why HasData doesn't work well for tables with NEWSEQUENTIALID() defaults like Tenants and Users.