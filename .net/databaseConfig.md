This error happens because the `dotnet ef` command-line tool isn't installed on your machine yet. It's an extra tool that doesn't come pre-installed with the standard .NET SDK.

To fix this, you just need to install it globally. Run this single command in your terminal:

```bash
dotnet tool install --global dotnet-ef
```

Once that finishes successfully, your machine will recognize the `dotnet ef` command. You can then run the migration commands exactly as before:

```bash
dotnet ef migrations add InitialCreate
dotnet ef database update
```