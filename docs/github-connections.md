# Using GitHub Secrets for SPALM Connections

This document explains how to use GitHub Secrets for securing your SPALM connections in CI/CD environments.

## Benefits of GitHub Secrets Approach

1. **Enhanced Security**: Sensitive information like client IDs, secrets, and site URLs never leave the GitHub Actions secure environment
2. **CI/CD Friendly**: Perfect for automated workflows in GitHub Actions
3. **Centralized Management**: Manage all your connection information in one secure place
4. **Environment Support**: Different values per environment (dev/test/prod) using GitHub Environments

## Required GitHub Secrets

Set up the following secrets in your GitHub repository:

### Authentication Secrets (Repository Level)

- `AZURE_APP_CLIENT_ID`: The client ID of your Azure App Registration
- `AZURE_APP_CLIENT_SECRET`: The client secret of your Azure App Registration
- `AZURE_APP_TENANT_ID`: The tenant ID of your Azure organization

### Site URLs (Environment Level - dev, test, prod)

- `DEV_SITE_URL`: URL for your development SharePoint site
- `TEST_SITE_URL`: URL for your test SharePoint site
- `PROD_SITE_URL`: URL for your production SharePoint site
- `SOURCE_SITE_URL`: URL for your source SharePoint site (used for migrations)

## How to Use GitHub Secrets

### In GitHub Actions Workflows

The `set-github-connections.ps1` script is designed to work seamlessly in GitHub Actions by automatically detecting and using the environment variables that GitHub creates from your secrets:

```yaml
steps:
  - name: Connect to SharePoint
    shell: pwsh
    run: |
      # Load the module
      Import-Module ./src/SPALM/SPALM.psm1 -Force

      # Set up connections from GitHub secrets
      . ./config/set-github-connections.ps1

      # Connect using the predefined connection
      Connect-SPALMSite -ConnectionName "Dev" # or Test, Prod, Source

      # Your SPALM commands here...

    env:
      DEV_SITE_URL: ${{ secrets.DEV_SITE_URL }}
      TEST_SITE_URL: ${{ secrets.TEST_SITE_URL }}
      PROD_SITE_URL: ${{ secrets.PROD_SITE_URL }}
      AZURE_APP_CLIENT_ID: ${{ secrets.AZURE_APP_CLIENT_ID }}
      AZURE_APP_CLIENT_SECRET: ${{ secrets.AZURE_APP_CLIENT_SECRET }}
      AZURE_APP_TENANT_ID: ${{ secrets.AZURE_APP_TENANT_ID }}
```

### In Local Development Environment

For local development, you can:

1. Set environment variables with the same names before running your scripts:

```powershell
$env:DEV_SITE_URL = "https://mytenant.sharepoint.com/sites/dev"
$env:AZURE_APP_CLIENT_ID = "your-app-id"
$env:AZURE_APP_CLIENT_SECRET = "your-app-secret"
$env:AZURE_APP_TENANT_ID = "your-tenant-id"

# Then run the script
. ./config/set-github-connections.ps1

# Now connect
Connect-SPALMSite -ConnectionName "Dev"
```

2. Or run the script without environment variables to generate a temporary local file:

```powershell
# This will create a temporary connections.private.json file
. ./config/set-github-connections.ps1

# Then edit the file manually to add your connections
```

## GitHub Environments Setup

For secure deployment to multiple environments, create GitHub Environments with protection rules:

1. Go to your repository settings
2. Navigate to "Environments" and create environments for "dev", "test", and "prod"
3. Add environment-specific secrets (DEV_SITE_URL, TEST_SITE_URL, PROD_SITE_URL)
4. Add protection rules for sensitive environments (like requiring approval for prod)

## Testing

The GitHub secrets connection functionality has comprehensive tests:

- **Unit Tests**: Test individual components of the GitHub secrets system

  - `GitHubConnections.Tests.ps1`: Tests the functions in `set-github-connections.ps1`
  - `GitHubSecretHelpers.Tests.ps1`: Tests the helper functions in `GitHubSecretHelpers.ps1`
  - `DeployWithGitHubSecrets.Tests.ps1`: Tests the deployment script functionality

- **Integration Tests**:
  - `GitHubSecrets.Integration.Tests.ps1`: Tests how all components work together

To run the tests:

```powershell
# Run all tests
.\config\run-tests.ps1

# Run specific tests
Invoke-Pester -Path .\src\tests\GitHubConnections.Tests.ps1
```

## See Also

- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GitHub Environments Documentation](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [Azure App Registration Setup](./azure-app-setup.md)
