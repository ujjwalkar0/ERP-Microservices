using ERP.Identity.Application.Users.DTOs;
using MediatR;

namespace ERP.Identity.Application.Users.Command
{
    public record CreateUserCommand
    (
        string Username,
        string Email,
        string Password
    ) : IRequest<CreateUserResponseDto>;
}