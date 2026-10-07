namespace ERP.Identity.Domain.Entities
{
    public class UserToken
    {
        public Guid UserId { get; set; }
        public String LoginProvider { get; set; }
        public String Name { get; set; }
        public String Value { get; set; }
        public User User { get; set; }
    }
}