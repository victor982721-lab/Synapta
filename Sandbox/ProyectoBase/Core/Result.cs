namespace ProyectoBase.Core
{
    public class Result : IResult
    {
        public bool Success { get; init; }
        public string Message { get; init; } = string.Empty;

        public static Result Ok(string message = "") =>
            new Result { Success = true, Message = message };

        public static Result Fail(string message = "") =>
            new Result { Success = false, Message = message };
    }
}
