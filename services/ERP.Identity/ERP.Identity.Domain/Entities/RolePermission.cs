namespace ERP.Identity.Domain.Entities
{
    public class RolePermission
    {
        public Guid Id { get; set; }
        public Guid RoleId { get; set; }
        public Guid PermissionId { get; set; }
        public Boolean IsDeined { get; set; }
        public Role Role { get; set; }
        public Permission Permission { get; set; }
    }
}