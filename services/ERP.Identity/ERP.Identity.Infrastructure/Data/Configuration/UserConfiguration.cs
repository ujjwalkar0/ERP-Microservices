using ERP.Identity.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ERP.Identity.Infrastructure.Data.Configurations
{
    public class UserConfiguration : IEntityTypeConfiguration<User>
    {
        public void Configure(EntityTypeBuilder<User> builder)
        {
            builder.ToTable("Users", "Identity");

            builder.HasKey(x => x.UserId);

            builder.Property(x => x.UserId)
                .HasDefaultValueSql("NEWSEQUENTIALID()");

            builder.Property(x => x.Username)
                .IsRequired()
                .HasMaxLength(100);

            builder.Property(x => x.Email)
                .IsRequired()
                .HasMaxLength(256);

            builder.Property(x => x.NormalizedEmail)
                .IsRequired()
                .HasMaxLength(256);
            
            builder.HasIndex(x => x.NormalizedEmail)
                .IsUnique()
                .HasDatabaseName("IX_Users_NormalizedEmail");

            builder.Property(x => x.SecurityStamp)
                .IsRequired()
                .HasMaxLength(256);

            builder.Property(x => x.AvatarUrl)
                .HasMaxLength(500);

            builder.Property(x => x.IsActive)
                .IsRequired()
                .HasDefaultValue(false);

            builder.Property(x => x.CreatedAt)
                .IsRequired()
                .HasDefaultValueSql("SYSUTCDATETIME()");

            // Index
            builder.HasIndex(x => x.Email)
                .IsUnique()
                .HasDatabaseName("IX_Users_Email");

            builder.HasIndex(x => x.Username)
                .IsUnique()
                .HasDatabaseName("IX_Users_Username");

            builder.HasIndex(x => x.TenantId)
                .HasDatabaseName("IX_Users_TenantId");

            // Relationship
            builder.HasMany(x => x.Tenants)
                .WithMany(x => x.Users)
                .UsingEntity(
                    "TenantUser",
                    j => j.ToTable("TenantUsers", "Identity")
                );

            builder.HasOne(x => x.RefferedBy)
                .WithMany(x => x.RefferedUsers)
                .HasForeignKey(x => x.RefferedById)
                .OnDelete(DeleteBehavior.NoAction);
        }
    }
}