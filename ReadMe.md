This repo is being used for bug report at https://github.com/dotnet/Scaffolding/issues/2596.
I keep it only for 1 year and it will be removed after December 11, 2024.
Duplicate this repo if you think it is useful for the future.
No attribution is needed. 

## Disclaimer 

> Please carefully examine the batch files before executing them.
  Every effort has been made in the preparation of this repo to ensure the accuracy of the information
presented. However, the information contained in this repo is presented without warranty, either express or
implied. I am not be held liable for any damages caused or alleged to have been caused directly or indirectly by this repo.


## Problem Description

To illustrate the problem, I make 4 projects as follows:

- `Model` project with one entity model `User.cs`
    ```csharp
    public class User
    {
        public int Id { get; set; }
        public string Name { get; set; } = default!;
    }
    ```


- `Context` project with one database context `AppDbContext.cs`
    ```csharp
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }
        public DbSet<User> Users => Set<User>();
    }
    ```
- `MigrationForSqlite` project with a trivial class `Empty.cs`
    ```csharp
    public class Empty { }
    ```
   This project is used to keep migration files generated by ef tool for specific db provider (in this case for sqlite).

- `Api` project with `Program.cs`
    ```csharp
    var builder = WebApplication.CreateBuilder(args);


    builder.Services.AddDbContext<Context.AppDbContext>(dcob =>
    {
        dcob.UseSqlite("DataSource=Test.db", 
            sdcob => sdcob.MigrationsAssembly("MigrationForSqlite"));
    });


    var app = builder.Build();

    app.MapGet("/", () => "Hello World");

    app.Run();
    ```

I successfully did the following:

- migration: `dotnet ef migrations add Initializaiton -s Api -p MigrationForSqlite`
- applying migration: `dotnet ef database update -s Api`
- running api server: `dotnet run --project Api --launch-profile https`
- testing endpoint by navigating to `https://localhost:7255` that produces `Hello World`

After shutting the server down, I attempted to scaffold  endpoints for `User` model with the following batch file but I failed.
```
dotnet aspnet-codegenerator minimalapi ^
-p Api ^
-e UserEndpoints ^
-m Model.User ^
-dc Context.AppDbContext ^
-outDir Endpoints ^
-dbProvider sqlite
```

The error messages are:
```
Building project ...
Finding the generator 'minimalapi'...
Running the generator 'minimalapi'...

Minimal hosting scenario!
Attempting to figure out the EntityFramework metadata for the model and DbContext: 'User'
Unable to create a 'DbContext' of type 'Context.AppDbContext'. The exception 'Unable to resolve service for type 'Microsoft.EntityFrameworkCore.DbContextOptions`1[ContUnable to create a 'DbContext' of type 'Context.AppDbContext'. The exception 'Unable to resolve service for type 'Microsoft.EntityFrameworkCore.DbContextOptions`1[Context.AppDbContext]' while attempting to activate 'Context.AppDbContext'.' was thrown while attempting to create an instance. For the different patterns supported at design time, see https://go.microsoft.com/fwlink/?linkid=851728 StackTrace:
   at Microsoft.EntityFrameworkCore.Design.Internal.DbContextOperations.CreateContext(String contextType)
   at Microsoft.EntityFrameworkCore.Design.DbContextActivator.CreateInstance(Type contextType, Assembly startupAssembly, IOperationReportHandler reportHandler, String[] args)
   at Microsoft.EntityFrameworkCore.Design.DbContextActivator.CreateInstance(Type contextType, Assembly startupAssembly, IOperationReportHandler reportHandler)
   at Microsoft.VisualStudio.Web.CodeGeneration.EntityFrameworkCore.EntityFrameworkModelProcessor.TryCreateContextUsingAppCode(Type dbContextType, Type startupType)

Unable to resolve service for type 'Microsoft.EntityFrameworkCore.DbContextOptions`1[Context.AppDbContext]' while attempting to activate 'Context.AppDbContext'. StackTrace:
   at Microsoft.Extensions.DependencyInjection.ActivatorUtilities.ConstructorMatcher.CreateInstance(IServiceProvider provider)
   at Microsoft.Extensions.DependencyInjection.ActivatorUtilities.CreateInstance(IServiceProvider provider, Type instanceType, Object[] parameters)
   at Microsoft.EntityFrameworkCore.Design.Internal.DbContextOperations.<>c__DisplayClass20_5.<FindContextTypes>b__13()
   at Microsoft.EntityFrameworkCore.Design.Internal.DbContextOperations.CreateContext(String contextType)

Unable to resolve service for type 'Microsoft.EntityFrameworkCore.DbContextOptions`1[Context.AppDbContext]' while attempting to activate 'Context.AppDbContext'.
   at Microsoft.VisualStudio.Web.CodeGeneration.ActionInvoker.<BuildCommandLine>b__6_0()
   at Microsoft.Extensions.CommandLineUtils.CommandLineApplication.Execute(String[] args)
   at Microsoft.VisualStudio.Web.CodeGeneration.ActionInvoker.Execute(String[] args)
   at Microsoft.VisualStudio.Web.CodeGeneration.CodeGenCommand.Execute(String[] args)
RunTime 00:00:20.53
```

## How to reproduce?

As generating 4 projects takes time, in this repo I provide you with `generate-solution.bat` with the following contents
```
cls

REM Create projects
dotnet new classlib -o Model
dotnet new classlib -o Context
dotnet new classlib -o MigrationForSqlite
dotnet new webapi   -o Api



REM Model
del Model\Class1.cs
copy templates\Model.User.cs Model\User.cs



REM Context
del Context\Class1.cs
copy templates\Context.AppDbContext.cs Context\AppDbContext.cs
dotnet add Context reference Model
dotnet add Context package Microsoft.EntityFrameworkCore




REM MigrationForSqlite
del MigrationForSqlite\Class1.cs
copy templates\MigrationForSqlite.Empty.cs MigrationForSqlite\Empty.cs
dotnet add MigrationForSqlite reference Context
dotnet add MigrationForSqlite package Microsoft.EntityFrameworkCore.Sqlite



REM Api
del Api\Program.cs
copy templates\Api.Program.cs Api\Program.cs
dotnet add Api reference MigrationForSqlite
dotnet add Api package Microsoft.EntityFrameworkCore.Tools
dotnet add Api package Microsoft.VisualStudio.Web.CodeGeneration.Design
REM remove InvariantGlobalization
findstr /C:"<InvariantGlobalization>true</InvariantGlobalization>" Api\Api.csproj
type Api\Api.csproj | findstr /v /C:"<InvariantGlobalization>true</InvariantGlobalization>" > temp.csproj
move /y temp.csproj Api\Api.csproj
del temp.csproj



REM Create a solution and add projects
dotnet new sln -n Test
dotnet sln add Api
dotnet sln add Model
dotnet sln add Context
dotnet sln add MigrationForSqlite
```

I also provide you with the following batch files:

- `remove-solution.bat` to remove the generated solution
- `migrate.bat` to do migration
- `apply-migration.bat` to apply migration
- `scaffold-endpoint.bat` to scaffold endpoints for `User` model
- `run-api.bat` to run the server




The following are the detailed steps I did. 



### Migrating

Executing `migrate.bat` that contains the following command
```
dotnet ef migrations add Initialization ^
-s Api ^
-p MigrationForSqlite
```

successfully produces `Migrations` folder in `MigrationForSqlite` project and the following logs.

```
Build started...
Build succeeded.
Done. To undo this action, use 'ef migrations remove'
```

### Applying Migration

Executing `apply-migration.bat` that contains the following command
```
dotnet ef database update ^
-s Api
```

successfully produces `Test.db` file in `Api` project and the following logs.

```
Build started...
Build succeeded.
info: Microsoft.EntityFrameworkCore.Database.Command[20101]
      Executed DbCommand (19ms) [Parameters=[], CommandType='Text', CommandTimeout='30']
      PRAGMA journal_mode = 'wal';
info: Microsoft.EntityFrameworkCore.Database.Command[20101]
      Executed DbCommand (8ms) [Parameters=[], CommandType='Text', CommandTimeout='30']
      CREATE TABLE "__EFMigrationsHistory" (
          "MigrationId" TEXT NOT NULL CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY,
          "ProductVersion" TEXT NOT NULL
      );
info: Microsoft.EntityFrameworkCore.Database.Command[20101]
      Executed DbCommand (3ms) [Parameters=[], CommandType='Text', CommandTimeout='30']
      SELECT COUNT(*) FROM "sqlite_master" WHERE "name" = '__EFMigrationsHistory' AND "type" = 'table';
info: Microsoft.EntityFrameworkCore.Database.Command[20101]
      Executed DbCommand (1ms) [Parameters=[], CommandType='Text', CommandTimeout='30']
      SELECT "MigrationId", "ProductVersion"
      FROM "__EFMigrationsHistory"
      ORDER BY "MigrationId";
info: Microsoft.EntityFrameworkCore.Migrations[20402]
      Applying migration '20231211025924_Initialization'.
Applying migration '20231211025924_Initialization'.
info: Microsoft.EntityFrameworkCore.Database.Command[20101]
      Executed DbCommand (0ms) [Parameters=[], CommandType='Text', CommandTimeout='30']
      CREATE TABLE "Users" (
          "Id" INTEGER NOT NULL CONSTRAINT "PK_Users" PRIMARY KEY AUTOINCREMENT,
          "Name" TEXT NOT NULL
      );
info: Microsoft.EntityFrameworkCore.Database.Command[20101]
      Executed DbCommand (0ms) [Parameters=[], CommandType='Text', CommandTimeout='30']
      INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
      VALUES ('20231211025924_Initialization', '8.0.0');
Done.
```

### Running Web Api

In order to make sure the `Api` project works as expected, execute 
`run-api.bat` that contains the following command

```
dotnet run ^
--project Api ^
--launch-profile https
```

and it produces the following logs.

```
Building...
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: https://localhost:7255
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://localhost:5192
info: Microsoft.Hosting.Lifetime[0]
      Application started. Press Ctrl+C to shut down.
info: Microsoft.Hosting.Lifetime[0]
      Hosting environment: Development
info: Microsoft.Hosting.Lifetime[0]
      Content root path: F:\Repos\CodeGenerator\Api
```

Navigating to `https://localhost:7255` produces `Hello World`.


### Scaffolding User Endpoints
First make sure to shutdown the server by pressing `ctrl+c` on the terminal window.

Executing `scaffold-endpoint.bat` that contains the following command
```
dotnet aspnet-codegenerator minimalapi ^
-p Api ^
-e UserEndpoints ^
-m Model.User ^
-dc Context.AppDbContext ^
-outDir Endpoints ^
-dbProvider sqlite
```

produces the following error.

```
Building project ...
Finding the generator 'minimalapi'...
Running the generator 'minimalapi'...

Minimal hosting scenario!
Attempting to figure out the EntityFramework metadata for the model and DbContext: 'User'
Unable to create a 'DbContext' of type 'Context.AppDbContext'. The exception 'Unable to resolve service for type 'Microsoft.EntityFrameworkCore.DbContextOptions`1[ContUnable to create a 'DbContext' of type 'Context.AppDbContext'. The exception 'Unable to resolve service for type 'Microsoft.EntityFrameworkCore.DbContextOptions`1[Context.AppDbContext]' while attempting to activate 'Context.AppDbContext'.' was thrown while attempting to create an instance. For the different patterns supported at design time, see https://go.microsoft.com/fwlink/?linkid=851728 StackTrace:
   at Microsoft.EntityFrameworkCore.Design.Internal.DbContextOperations.CreateContext(String contextType)
   at Microsoft.EntityFrameworkCore.Design.DbContextActivator.CreateInstance(Type contextType, Assembly startupAssembly, IOperationReportHandler reportHandler, String[] args)
   at Microsoft.EntityFrameworkCore.Design.DbContextActivator.CreateInstance(Type contextType, Assembly startupAssembly, IOperationReportHandler reportHandler)
   at Microsoft.VisualStudio.Web.CodeGeneration.EntityFrameworkCore.EntityFrameworkModelProcessor.TryCreateContextUsingAppCode(Type dbContextType, Type startupType)

Unable to resolve service for type 'Microsoft.EntityFrameworkCore.DbContextOptions`1[Context.AppDbContext]' while attempting to activate 'Context.AppDbContext'. StackTrace:
   at Microsoft.Extensions.DependencyInjection.ActivatorUtilities.ConstructorMatcher.CreateInstance(IServiceProvider provider)
   at Microsoft.Extensions.DependencyInjection.ActivatorUtilities.CreateInstance(IServiceProvider provider, Type instanceType, Object[] parameters)
   at Microsoft.EntityFrameworkCore.Design.Internal.DbContextOperations.<>c__DisplayClass20_5.<FindContextTypes>b__13()
   at Microsoft.EntityFrameworkCore.Design.Internal.DbContextOperations.CreateContext(String contextType)

Unable to resolve service for type 'Microsoft.EntityFrameworkCore.DbContextOptions`1[Context.AppDbContext]' while attempting to activate 'Context.AppDbContext'.
   at Microsoft.VisualStudio.Web.CodeGeneration.ActionInvoker.<BuildCommandLine>b__6_0()
   at Microsoft.Extensions.CommandLineUtils.CommandLineApplication.Execute(String[] args)
   at Microsoft.VisualStudio.Web.CodeGeneration.ActionInvoker.Execute(String[] args)
   at Microsoft.VisualStudio.Web.CodeGeneration.CodeGenCommand.Execute(String[] args)
RunTime 00:00:20.53
```