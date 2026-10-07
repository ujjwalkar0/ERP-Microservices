using System.Net;
using ERP.Identity.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ERP.Identity.Infrastructure.Data.Configurations
{
    public class SecurityEventConfiguration : IEntityTypeConfiguration<SecurityEvent>
    {
        public void Configure(EntityTypeBuilder<SecurityEvent> builder)
        {
            builder.ToTable("SecurityEvents", "Identity");

            builder.HasKey(e => e.Id);

            builder.HasOne(e => e.User)
                .WithMany(e => e.SecurityEvents)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            
            builder.Property(e => e.EventType)
                .IsRequired()
                .HasMaxLength(100);

            builder.Property(e => e.Severity)
                .IsRequired();

            builder.Property(e => e.IpAddress)
                .IsRequired()
                .HasMaxLength(45);

            builder.Property(e => e.Timestamp)
                .IsRequired()
                .HasDefaultValueSql("SYSUTCDATETIME()");

        }
    }
}