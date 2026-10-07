using ERP.Identity.API.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace ERP.Identity.API.Filters
{
    public class ApiResponseFilter : IAsyncResultFilter
    {
        public async Task OnResultExecutionAsync(
            ResultExecutingContext context, 
            ResultExecutionDelegate next
        )
        {
            if (context.Result is ObjectResult objectResult)
            {
                var response = new ApiResponse<object>
                {
                    Success = true,
                    Message = "Request Successfull",
                    Data = objectResult.Value
                };

                context.Result = new ObjectResult(response)
                {
                    StatusCode = objectResult.StatusCode
                };
            }
            await next();
        }
    }
}