namespace ERP.Identity.Domain.Entities
{
    public class Tenant
    {
        public Guid Id { get; set; }
        public string Name { get; set; }
        public string Slug { get; set; }
        public Guid ParentTenantId { get; set; }
        public Guid OwnerId { get; set; }
        public Guid PlanId { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime ExpireAt { get; set; }
        public Tenant ParentTanent { get; set; }
        public User Owner { get; set; }
        public ICollection<Tenant> Children { get; set; } = new List<Tenant>();
        public ICollection<User> Users { get; set; } = new List<User>();
    }
}