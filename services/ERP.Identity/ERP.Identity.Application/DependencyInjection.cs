using Microsoft.Extensions.DependencyInjection;
using Microsoft.AspNetCore.Identity;
using ERP.Identity.Domain.Entities;
using FluentValidation;
using ERP.Identity.Application.Common.Behaviors;
using Microsoft.Extensions.Configuration;


namespace ERP.Identity.Application
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddApplication(this IServiceCollection services, IConfiguration configuration)
        {

            services.AddMediatR(cfg =>
            {
                cfg.LicenseKey = configuration["MediatR:LicenseKey"];
                cfg.RegisterServicesFromAssemblies(typeof(DependencyInjection).Assembly);
                cfg.AddOpenBehavior(typeof(ValidationBehavior<,>));
            });

            services.AddAutoMapper(cfg => cfg.AddMaps(typeof(DependencyInjection).Assembly));
            services.AddScoped<IPasswordHasher<User>, PasswordHasher<User>>();
            services.AddValidatorsFromAssembly(typeof(DependencyInjection).Assembly);

            return services;
        }
    }
}