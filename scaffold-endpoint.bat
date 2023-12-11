dotnet aspnet-codegenerator minimalapi ^
-p Api ^
-e UserEndpoints ^
-m Model.User ^
-dc Context.AppDbContext ^
-outDir Endpoints ^
-dbProvider sqlite