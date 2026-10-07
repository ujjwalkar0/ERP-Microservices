using ERP.Identity.Domain.Entities;

namespace ERP.Identity.Domain.Repositories
{
    public interface IUserRepository
    {
        Task<Guid> AddAsync(User user, CancellationToken cancellationToken);

    }
}
