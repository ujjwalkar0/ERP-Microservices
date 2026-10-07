using System.Net;
using ERP.Identity.API.Models;

namespace ERP.Identity.API.Middleware
{
    public class ExceptionHandlingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ExceptionHandlingMiddleware> _logger;
        public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message);
                await HandleExceptionAsync(context, ex.Message);
            }
        }

        private static async Task HandleExceptionAsync(HttpContext context, String message)
        {
            context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
            context .Response.ContentType = "application/json";

            var response = new ApiResponse<object>
            {
                Success = false,
                Message = message,
                Data = null
            };

            await context.Response.WriteAsJsonAsync(response);
        }
    }
}