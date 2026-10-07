using AutoMapper;
using ERP.Identity.Application.Users.Command;
using ERP.Identity.Domain.Entities;

namespace ERP.Identity.Application.Common.Mappings
{
    public class UserProfile : Profile
    {
        public UserProfile()
        {
            CreateMap<CreateUserCommand, User>()
                .ForMember(
                    dest => dest.PasswordHash,
                    opt => opt.Ignore()
                );
        }
    }
}