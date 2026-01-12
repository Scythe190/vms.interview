namespace VMS.Interview.Models;

public class Visitor
{
    public Guid Id { get; set; }

    public string FullName { get; set; } = string.Empty;

    public DateTime CheckedInAt { get; set; }
}
