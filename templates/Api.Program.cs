using Microsoft.EntityFrameworkCore;


var builder = WebApplication.CreateBuilder(args);


builder.Services.AddDbContext<Context.AppDbContext>(dcob =>
{
    dcob.UseSqlite("DataSource=Test.db", 
        sdcob => sdcob.MigrationsAssembly("MigrationForSqlite"));
});


var app = builder.Build();

app.MapGet("/", () => "Hello World");

app.Run();