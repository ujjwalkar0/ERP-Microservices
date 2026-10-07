using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using ERP.Identity.Domain.Repositories;
using ERP.Identity.Infrastructure.Repository;
using ERP.Identity.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace ERP.Identity.Infrastructure
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddInfrastructure(this IServiceCollection service, IConfiguration configuration)
        {
            service.AddDbContext<IdentityDbContext>(option => 
            option.UseSqlServer(configuration.GetConnectionString("DefaultConnection")));
            service.AddScoped<IUserRepository, UserRepository>();
            return service;
        }

    }
}