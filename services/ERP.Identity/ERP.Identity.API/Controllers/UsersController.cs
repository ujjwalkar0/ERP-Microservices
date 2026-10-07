using ERP.Identity.API.Models;
using ERP.Identity.Application.Users.Command;
using ERP.Identity.Application.Users.DTOs;
using MediatR;
using Microsoft.AspNetCore.Mvc;

namespace ERP.Identity.API.Controllers
{

    [ApiController]
    [Route("[controller]/[action]")]
    public class UsersController : ControllerBase
    {
        private readonly IMediator _mediator;
        public UsersController(IMediator mediator)
        {
            _mediator = mediator;
        }

        [HttpGet]
        public IActionResult Login()
        {
            return Ok("Hello World");
        }

        [HttpPost]
        [ProducesResponseType(typeof(ApiResponse<CreateUserResponseDto>), StatusCodes.Status200OK)]
        public async Task<ActionResult<CreateUserResponseDto>> Register([FromBody] CreateUserCommand command)
        {
            CreateUserResponseDto responseDto = await _mediator.Send(command);
            return CreatedAtAction("Get", new { id = responseDto.UserId }, responseDto);
        }
    }
}