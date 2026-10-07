using ERP.Identity.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ERP.Identity.Infrastructure.Data.Configurations
{
    public class PermissionConfiguration : IEntityTypeConfiguration<Permission>
    {
        public void Configure(EntityTypeBuilder<Permission> builder)
        {
            builder.ToTable("Permission", "Identity");

            builder.HasKey(e => e.Id);

            builder.Property(e => e.Id)
                .HasDefaultValueSql("NEWSEQUENTIALID()");

            builder.Property(e => e.Code)
                .HasMaxLength(200)
                .IsRequired();

            builder.Property(e => e.Code)
                .HasMaxLength(200)
                .IsRequired();

            builder.Property(e => e.Module)
                .HasMaxLength(100)
                .IsRequired();

            builder.HasIndex(e => e.Code)
                .HasDatabaseName("IX_Permission_Code");
        }
    }
}