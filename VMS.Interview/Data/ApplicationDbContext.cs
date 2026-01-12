using Microsoft.EntityFrameworkCore;
using VMS.Interview.Models;

namespace VMS.Interview.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<Visitor> Visitors => Set<Visitor>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Visitor>(entity =>
        {
            entity.HasKey(v => v.Id);
            entity.Property(v => v.FullName)
                .HasMaxLength(200)
                .IsRequired();
            entity.Property(v => v.CheckedInAt)
                .IsRequired();
        });
    }
}
