namespace ERP.Identity.Domain.Entities
{
    public class UserLogin
    {
        public String LoginProvider { get; set; }
        public String ProviderKey { get; set; }
        public Guid UserId { get; set; }
        public User User { get; set; }
    }
}