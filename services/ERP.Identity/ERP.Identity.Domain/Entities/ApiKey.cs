namespace ERP.Identity.Domain.Entities
{
    public class ApiKey
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public String Name { get; set; }
        public String KeyHash { get; set; }
        public DateTime ExpiresAt { get; set; }
        public Boolean IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public Guid CreatedBy { get; set; }
        public Guid UpdatedBy { get; set; }
    }
}