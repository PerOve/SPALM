# Setting Up Personal Configuration Files

This guide explains how to set up personal configuration files for SPALM that won't be committed to the public repository.

## Step 1: Create Private Configuration Files

1. Create a directory called `private` in the `config` folder if it doesn't already exist:

   ```powershell
   New-Item -Path "config/private" -ItemType Directory -Force
   ```

2. Create your personal SharePoint site configuration:

   ```powershell
   # Copy the template
   Copy-Item -Path "config/sites.template.json" -Destination "config/private/sites.private.json"

   # Edit the file with your personal settings
   notepad "config/private/sites.private.json"
   ```

3. Create your personal pipeline configuration:

   ```powershell
   # Copy the template
   Copy-Item -Path "config/pipeline.template.json" -Destination "config/private/pipeline.private.json"

   # Edit the file with your personal settings
   notepad "config/private/pipeline.private.json"
   ```

## Step 2: Create Connection Profiles (Optional)

1. Run the connection profile script:

   ```powershell
   ./config/create-private-connections.ps1
   ```

2. Or manually create a connection profiles file:
   ```powershell
   # Create a JSON file with your connection profiles
   @{
       "MyDev" = @{
           "Url" = "https://mytenant.sharepoint.com/sites/mydev"
           "AuthType" = "Interactive"
           "ClientId" = ""
           "TenantId" = ""
       }
   } | ConvertTo-Json -Depth 5 | Out-File -FilePath "config/private/connections.private.json"
   ```

## Step 3: Use Your Private Configuration

The SPALM module will automatically detect and use your private configuration files when available.

### Using a Connection Profile

```powershell
# Connect using a named connection profile
Connect-SPALMSite -ConnectionName "MyDev"

# Compare sites using connection profiles
Compare-SPALMSite -SourceConnectionName "MyDev" -TargetConnectionName "MyTest"
```

## Security Notes

- Never commit these files to a public repository
- Keep sensitive credentials in a secure password manager
- Consider using certificate-based authentication instead of client secrets
- For CI/CD pipelines, use secret variables in Azure DevOps instead of storing secrets in files
