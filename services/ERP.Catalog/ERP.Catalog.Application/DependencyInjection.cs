using Microsoft.Extensions.DependencyInjection;

namespace ERP.Catalog.Application
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddApplication(this IServiceCollection services)
        {
            return services;
        } 
    }
}