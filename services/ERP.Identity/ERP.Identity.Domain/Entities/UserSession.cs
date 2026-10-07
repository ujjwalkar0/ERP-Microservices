namespace ERP.Identity.Domain.Entities
{
    public class UserSession
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid DeviceId { get; set; }
        public String IpAddress { get; set; }
        public DateTime ExpireAt { get; set; }
        public DateTime CreatedAt { get; set; }    
    }
}