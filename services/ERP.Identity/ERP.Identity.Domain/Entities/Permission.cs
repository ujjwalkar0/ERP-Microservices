namespace ERP.Identity.Domain.Entities
{
    public class Permission
    {
        public Guid Id { get; set; }
        public String Code { get; set; }
        public String Name { get; set; }
        public String Module { get; set; }
        public ICollection<RolePermission> RolePermissions { get; set; } = new List<RolePermission>();
    }
}