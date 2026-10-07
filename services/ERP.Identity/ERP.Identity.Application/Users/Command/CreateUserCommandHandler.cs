using AutoMapper;
using MediatR;
using ERP.Identity.Domain.Repositories;
using ERP.Identity.Domain.Entities;
using Microsoft.AspNetCore.Identity;
using ERP.Identity.Application.Users.DTOs;

namespace ERP.Identity.Application.Users.Command
{
    public class CreateUserCommandHandler : IRequestHandler<CreateUserCommand, CreateUserResponseDto>
    {
        private readonly IUserRepository _userRepository;
        private readonly IMapper _mapper;
        private readonly IPasswordHasher<User> _passwordHasher;

        public CreateUserCommandHandler(IUserRepository userRepository, IMapper mapper, IPasswordHasher<User> passwordHasher)
        {
            _userRepository = userRepository;
            _mapper = mapper;
            _passwordHasher = passwordHasher;
        }

        public async Task<CreateUserResponseDto> Handle(CreateUserCommand request, CancellationToken cancellationToken)
        {
            var user = _mapper.Map<User>(request);
            
            user.InitializeSecurityStamp();

            user.PasswordHash = _passwordHasher.HashPassword(user, request.Password);
            user.NormalizedEmail = user.Email.ToUpper();

            var userId = await _userRepository.AddAsync(user, cancellationToken);
            
            return new CreateUserResponseDto(userId);
        }
        
    }
}