# GitHub Actions Workflows for SPALM

This directory contains GitHub Actions workflow definitions for building, testing, and deploying the SPALM module.

## Available Workflows

### build-and-deploy.yml

This workflow handles building, testing, and deploying the SPALM module to SharePoint environments.

#### Triggers

- **Push**: Triggers on pushes to main, develop, feature/_, and release/_ branches
- **Pull Request**: Triggers on pull requests to main and develop branches
- **Manual**: Can be triggered manually with environment selection

#### Jobs

1. **Build Job**:

   - Sets up PowerShell environment
   - Installs required modules (PnP.PowerShell, Pester)
   - Builds the SPALM module
   - Runs tests and uploads test results
   - Uploads build artifacts

2. **Deploy Job** (manual trigger only):
   - Downloads build artifacts
   - Connects to SharePoint using app-only authentication
   - Executes appropriate SPALM commands based on target environment
   - Uploads migration plan for production deployments

## Setting Up GitHub Actions

1. **Configure Secrets**:

   Navigate to your repository Settings → Secrets and variables → Actions, and add the following secrets:

   - `AZURE_APP_CLIENT_ID`: The client ID of your Azure App registration
   - `AZURE_APP_CLIENT_SECRET`: The client secret of your Azure App registration
   - `AZURE_APP_TENANT_ID`: Your tenant ID
   - `DEV_SITE_URL`: Your development SharePoint site URL
   - `TEST_SITE_URL`: Your test SharePoint site URL
   - `PROD_SITE_URL`: Your production SharePoint site URL
   - `SOURCE_SITE_URL`: Your source/template SharePoint site URL

2. **Configure Environments** (Optional but recommended):

   Navigate to Settings → Environments and create environments for dev, test, and prod with appropriate protection rules:

   **For DEV**:

   - No protection rules (or minimal)

   **For TEST**:

   - Required reviewers for deployments

   **For PROD**:

   - Required reviewers (multiple)
   - Wait timer (e.g., 15 minutes)
   - Deployment branches limited to main

## Usage

### Running a Manual Deployment

1. Go to the Actions tab in your repository
2. Select the "Build and Test SPALM" workflow
3. Click "Run workflow"
4. Select the target environment (dev, test, prod)
5. Click "Run workflow"

### Viewing Workflow Results

After the workflow runs, you can:

1. View build and test results
2. Download artifacts (built module, test results, migration plans)
3. Check deployment logs
