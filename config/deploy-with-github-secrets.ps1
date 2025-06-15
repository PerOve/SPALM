<#
.SYNOPSIS
    Example script showing how to use GitHub secrets for deploying SharePoint artifacts
.DESCRIPTION
    This script demonstrates connecting to SharePoint using GitHub secrets or environment variables
    and then performing SPALM operations for automated deployments.
#>

# For local testing, you can set these environment variables (GitHub Actions will set them from secrets)
# $env:DEV_SITE_URL = "https://contoso.sharepoint.com/sites/dev"
# $env:TEST_SITE_URL = "https://contoso.sharepoint.com/sites/test"
# $env:PROD_SITE_URL = "https://contoso.sharepoint.com/sites/prod"
# $env:SOURCE_SITE_URL = "https://contoso.sharepoint.com/sites/source"
# $env:AZURE_APP_CLIENT_ID = "your-client-id"
# $env:AZURE_APP_CLIENT_SECRET = "your-client-secret"
# $env:AZURE_APP_TENANT_ID = "your-tenant-id"

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Dev", "Test", "Prod")]
    [string]$Environment = "Dev",

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,

    [Parameter(Mandatory = $false)]
    [switch]$BackupBeforeChanges
)

# Set up error handling
$ErrorActionPreference = "Stop"

try {
    # Import the module
    $moduleFolder = "$PSScriptRoot\..\src\SPALM"
    if (-not (Test-Path -Path $moduleFolder)) {
        # Adjust path when running from GitHub Actions
        $moduleFolder = "$PSScriptRoot\build\modules\SPALM"
    }

    Write-Host "Importing SPALM module from $moduleFolder"
    Import-Module "$moduleFolder\SPALM.psm1" -Force

    # Set up connections from GitHub secrets or environment variables
    Write-Host "Setting up connections from secrets/environment variables..."
    . "$PSScriptRoot\set-github-connections.ps1"

    # Connect to source and target sites
    Write-Host "Connecting to source site..."
    Connect-SPALMSite -ConnectionName "Source"

    Write-Host "Connecting to $Environment site..."
    Connect-SPALMSite -ConnectionName $Environment

    # Get source and target site URLs from the connection (we're already connected)
    $sourceSite = Get-PnPConnection "Source" | Select-Object -ExpandProperty Url
    $targetSite = Get-PnPConnection $Environment | Select-Object -ExpandProperty Url

    Write-Host "Source site: $sourceSite"
    Write-Host "Target site: $targetSite"

    # Run comparison
    Write-Host "Comparing source and target sites..."
    $comparison = Compare-SPALMSite -SourceSite $sourceSite -TargetSite $targetSite

    # Generate a migration plan
    Write-Host "Generating migration plan..."
    $plan = Get-SPALMMigrationPlan -SourceSite $sourceSite -TargetSite $targetSite

    # Export the comparison and plan for reference
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $comparisonPath = "$PSScriptRoot\comparison_$timestamp.json"
    $planPath = "$PSScriptRoot\migration_plan_$timestamp.json"

    $comparison | ConvertTo-Json -Depth 10 | Out-File -FilePath $comparisonPath -Force
    $plan | ConvertTo-Json -Depth 10 | Out-File -FilePath $planPath -Force

    Write-Host "Comparison saved to: $comparisonPath"
    Write-Host "Migration plan saved to: $planPath"

    # Execute the migration if not in WhatIf mode
    if (-not $WhatIf) {
        Write-Host "Executing site migration..."
        Invoke-SPALMSiteMigration -SourceSite $sourceSite -TargetSite $targetSite `
            -BackupBeforeChanges:$BackupBeforeChanges

        Write-Host "Migration completed successfully!"
    } else {
        Write-Host "WhatIf mode: No changes were made. Review the migration plan."
    }

    # Disconnect from all sites
    Disconnect-SPALMSite

} catch {
    Write-Error "An error occurred: $_"
    exit 1
}
