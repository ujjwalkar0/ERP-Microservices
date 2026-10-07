using ERP.Identity.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ERP.Identity.Infrastructure.Data.Configurations
{
    public class UserLoginConfiguration : IEntityTypeConfiguration<UserLogin>
    {
        public void Configure(EntityTypeBuilder<UserLogin> builder)
        {
            builder.HasKey(x => new
            {
                x.LoginProvider,
                x.ProviderKey
            });

            builder.HasOne(e => e.User)
                .WithMany(e => e.UserLogins)
                .HasForeignKey(e => e.UserId);
        }
        
    }
}