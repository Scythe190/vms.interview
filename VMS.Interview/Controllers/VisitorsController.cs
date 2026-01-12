using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VMS.Interview.Data;
using VMS.Interview.Models;

namespace VMS.Interview.Controllers;

[ApiController]
[Route("api/visitors")]
public class VisitorsController : ControllerBase
{
    private readonly ApplicationDbContext _dbContext;
    private readonly ILogger<VisitorsController> _logger;

    public VisitorsController(ApplicationDbContext dbContext, ILogger<VisitorsController> logger)
    {
        _dbContext = dbContext;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Visitor>>> GetAll(CancellationToken cancellationToken)
    {
        var visitors = await _dbContext.Visitors
            .AsNoTracking()
            .OrderByDescending(v => v.CheckedInAt)
            .ToListAsync(cancellationToken);

        return Ok(visitors);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<Visitor>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var visitor = await _dbContext.Visitors
            .AsNoTracking()
            .FirstOrDefaultAsync(v => v.Id == id, cancellationToken);

        if (visitor is null)
        {
            return NotFound();
        }

        return Ok(visitor);
    }

    [HttpPost]
    public async Task<ActionResult<Visitor>> Create([FromBody] CreateVisitorRequest request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.FullName))
        {
            return BadRequest("FullName is required.");
        }

        var visitor = new Visitor
        {
            Id = Guid.NewGuid(),
            FullName = request.FullName.Trim(),
            CheckedInAt = DateTime.UtcNow
        };

        _dbContext.Visitors.Add(visitor);
        await _dbContext.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Visitor created {VisitorId} {FullName}", visitor.Id, visitor.FullName);

        return CreatedAtAction(nameof(GetById), new { id = visitor.Id }, visitor);
    }

    public sealed record CreateVisitorRequest(string FullName);
}
