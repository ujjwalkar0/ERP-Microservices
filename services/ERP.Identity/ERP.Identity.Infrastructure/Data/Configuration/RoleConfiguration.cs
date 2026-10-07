using ERP.Identity.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ERP.Identity.Infrastructure.Data.Configurations
{
    public class RoleConfiguration : IEntityTypeConfiguration<Role>
    {
        public void Configure(EntityTypeBuilder<Role> builder)
        {
            builder.ToTable("Role", "Identity");

            builder.HasKey(e => e.Id);

            builder.Property(e => e.Id)
                .HasDefaultValueSql("NEWSEQUENTIALID()");

            builder.HasOne<Role>()
                .WithMany()
                .HasForeignKey(e => e.ParentRoleId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.Property(e => e.Name)
                .HasMaxLength(100)
                .IsRequired();

            builder.Property(e => e.NormalizedName)
                .HasMaxLength(100)
                .IsRequired();

            builder.Property(e => e.IsSystem)
                .HasDefaultValue(false)
                .IsRequired();

            builder.HasIndex(e => e.NormalizedName)
                .HasDatabaseName("IX_Roles_Name")
                .IsUnique();

            builder.HasIndex(e => e.ParentRoleId)
                .HasDatabaseName("IX_Roles_ParentRoleId");
        }
    }
}