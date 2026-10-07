using Microsoft.AspNetCore.Mvc;

namespace ERP.Identity.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class AuthController : ControllerBase
    {
        public AuthController()
        {
            
        }

        [HttpGet]
        public IActionResult Get()
        {
            return Ok();
        }


    }
}