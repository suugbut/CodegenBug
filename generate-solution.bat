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