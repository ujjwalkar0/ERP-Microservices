namespace ERP.Identity.Domain.Entities
{
    public class UserClaim
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public String ClaimType { get; set; }
        public String ClaimValue { get; set; }
        public User User { get; set; }
    }
}