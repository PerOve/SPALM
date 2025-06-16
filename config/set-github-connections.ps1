<#
.SYNOPSIS
    Script to set up SharePoint connections using GitHub secrets.
.DESCRIPTION
    This script demonstrates how to create SharePoint connections using GitHub secrets
    for secure CI/CD pipelines without relying on local config files.

    When running in a GitHub workflow, it uses GitHub secrets directly.
    When running locally, it looks for environment variables following the same pattern.
#>

# Import the necessary modules
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\src\SPALM\SPALM.psm1"
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
}

# Function to test if running in GitHub Actions or local environment
function Test-GitHubActionsEnvironment {
    return ($null -ne $env:GITHUB_ACTIONS)
}

# Function to get secrets from environment variables
function Get-SecretFromEnvironment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SecretName,

        [Parameter(Mandatory = $false)]
        [string]$DefaultValue = ""
    )

    $value = [System.Environment]::GetEnvironmentVariable($SecretName)
    if (-not $value) {
        Write-Verbose "Environment variable '$SecretName' not found, using default value"
        return $DefaultValue
    }

    return $value
}

# Function to create a connection object based on environment variables/secrets
function New-ConnectionFromSecrets {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConnectionName,

        [Parameter(Mandatory = $true)]
        [string]$UrlSecretName,

        [Parameter(Mandatory = $false)]
        [string]$AuthType = "ClientSecret",

        [Parameter(Mandatory = $false)]
        [string]$ClientIdSecretName = "AZURE_APP_CLIENT_ID",

        [Parameter(Mandatory = $false)]
        [string]$ClientSecretSecretName = "AZURE_APP_CLIENT_SECRET",

        [Parameter(Mandatory = $false)]
        [string]$TenantIdSecretName = "AZURE_APP_TENANT_ID",

        [Parameter(Mandatory = $false)]
        [string]$CertificatePathSecretName = "",
        [Parameter(Mandatory = $false)]
        [string]$CertificatePasswordSecretName = "" # This is just the name of the secret, not the actual password
    )

    $url = Get-SecretFromEnvironment -SecretName $UrlSecretName
    if (-not $url) {
        Write-Warning "URL for connection '$ConnectionName' not found in environment variables"
        return $null
    }

    $connection = @{
        "Url"      = $url
        "AuthType" = $AuthType
    }

    # Add appropriate auth parameters based on AuthType
    switch ($AuthType) {
        "ClientSecret" {
            $connection.ClientId = Get-SecretFromEnvironment -SecretName $ClientIdSecretName
            $connection.ClientSecret = Get-SecretFromEnvironment -SecretName $ClientSecretSecretName
            $connection.TenantId = Get-SecretFromEnvironment -SecretName $TenantIdSecretName
        }
        "Certificate" {
            $connection.ClientId = Get-SecretFromEnvironment -SecretName $ClientIdSecretName
            $connection.CertificatePath = Get-SecretFromEnvironment -SecretName $CertificatePathSecretName
            $connection.CertificatePassword = Get-SecretFromEnvironment -SecretName $CertificatePasswordSecretName
            $connection.TenantId = Get-SecretFromEnvironment -SecretName $TenantIdSecretName
        }
        "Interactive" {
            # No additional parameters needed for interactive auth
        }
    }

    return $connection
}

Write-Host "Setting up connections from GitHub secrets or environment variables..."

# Create the connections dictionary
$connections = @{}

# Set up connections for different environments
$connections["Dev"] = New-ConnectionFromSecrets -ConnectionName "Dev" -UrlSecretName "DEV_SITE_URL"
$connections["Test"] = New-ConnectionFromSecrets -ConnectionName "Test" -UrlSecretName "TEST_SITE_URL"
$connections["Prod"] = New-ConnectionFromSecrets -ConnectionName "Prod" -UrlSecretName "PROD_SITE_URL"
$connections["Source"] = New-ConnectionFromSecrets -ConnectionName "Source" -UrlSecretName "SOURCE_SITE_URL"

# Filter out null connections (where secrets weren't found)
$connections = $connections.GetEnumerator() | Where-Object { $null -ne $_.Value } | ForEach-Object {
    $hash = @{}
    $hash[$_.Key] = $_.Value
    $hash
} | Merge-Hashtable

# If running in GitHub Actions, print info about what was loaded
if (Test-GitHubActionsEnvironment) {
    Write-Host "Running in GitHub Actions environment"
    $connections.Keys | ForEach-Object {
        Write-Host "Connection '$_' configured with URL: $($connections[$_].Url)"
    }
} else {
    Write-Host "Running in local environment - creating temporary connections file"

    # Create private directory if it doesn't exist
    $privateDir = Join-Path -Path $PSScriptRoot -ChildPath "private"
    if (-not (Test-Path -Path $privateDir)) {
        New-Item -Path $privateDir -ItemType Directory -Force | Out-Null
    }

    # Save to a temporary private file that will be used by the module
    $connectionsFilePath = Join-Path -Path $privateDir -ChildPath "connections.private.json"
    $connections | ConvertTo-Json -Depth 5 | Out-File -FilePath $connectionsFilePath

    Write-Host "Temporary connection profiles created in $connectionsFilePath"
    Write-Host "These can be used with Connect-SPALMSite -ConnectionName 'Dev|Test|Prod|Source'"
}
