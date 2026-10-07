namespace ERP.Identity.Domain.Entities
{
    public class Role
    {
        public Guid Id { get; set; }
        public String Name { get; set; }
        public String NormalizedName { get; set; }
        public Guid ParentRoleId { get; set; }
        public Boolean IsSystem { get; set; }
        public Guid UserId { get; set; }
        public ICollection<User> Users { get; set; } = new List<User>();
        public ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
        public ICollection<RolePermission> RolePermissions { get; set; } = new List<RolePermission>();
    }
}