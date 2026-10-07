namespace ERP.Identity.Domain.Entities
{
    public class UserRole
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid RoleId { get; set; }
        public Guid AssignedBy { get; set; }
        public User User { get; set; }
        public Role Role { get; set; }
        public User AssignedByUser { get; set; }
    }
    
}