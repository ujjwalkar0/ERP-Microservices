using ERP.Identity.Domain.Entities;
using ERP.Identity.Domain.Repositories;
using ERP.Identity.Infrastructure;

namespace ERP.Identity.Infrastructure.Repository
{
    public class UserRepository : IUserRepository
    {
        private readonly IdentityDbContext _context;
        public UserRepository(IdentityDbContext context)
        {
            _context = context;
        }

        public async Task<Guid> AddAsync(User user, CancellationToken cancellationToken)
        {
            await _context.Users.AddAsync(user, cancellationToken);
            await _context.SaveChangesAsync();

            return user.UserId;
        }
    }
}