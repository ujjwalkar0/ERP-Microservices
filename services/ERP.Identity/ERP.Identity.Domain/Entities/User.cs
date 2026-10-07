using System.Security.Cryptography;

namespace ERP.Identity.Domain.Entities
{
    public class User
    {
        public String Username { get; set; }
        public String Email { get; set; }
        public String NormalizedEmail { get; set; }
        public String PasswordHash { get; set; }
        public String SecurityStamp { get; set; }
        public Guid TenantId { get; set; }
        public Guid UserId { get; set; }
        public String? AvatarUrl { get; set; }
        public Boolean IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public Guid CreatedBy { get; set; }
        public Guid UpdatedBy { get; set; }
        public Guid? RefferedById { get; set; }
        public User RefferedBy { get; set; }
        public Guid RoleId { get; set; }
        public ICollection<Tenant> Tenants { get; set; } = new List<Tenant>();
        public ICollection<Tenant> OwnedTenants { get; set; } = new List<Tenant>();
        public ICollection<User> RefferedUsers { get; set; } = new List<User>();
        public ICollection<Role> Roles { get; set; } = new List<Role>();
        public ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
        public ICollection<UserRole> AssignedByUsers { get; set; } = new List<UserRole>();
        public ICollection<UserClaim> UserClaims { get; set; } = new List<UserClaim>();
        public ICollection<UserLogin> UserLogins { get; set; } = new List<UserLogin>();
        public ICollection<UserToken> UserTokens { get; set; } = new List<UserToken>();
        public ICollection<SecurityEvent> SecurityEvents { get; set; } = new List<SecurityEvent>();

        public void InitializeSecurityStamp()
        {
            SecurityStamp = Convert.ToHexString(RandomNumberGenerator.GetBytes(32));
        }

        public void RegenerateSecurityStamp()
        {
            SecurityStamp = Convert.ToHexString(RandomNumberGenerator.GetBytes(32));
        }
    }
}