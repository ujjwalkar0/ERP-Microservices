namespace ERP.Identity.Domain.Entities
{
    public class SecurityEvent
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public String EventType { get; set; }
        public int Severity { get; set; }
        public String IpAddress { get; set; }
        public DateTime Timestamp { get; set; }
        public User User { get; set; }
    }
}