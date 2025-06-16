<#
.SYNOPSIS
    Pester tests for GitHubSecretHelpers.ps1
.DESCRIPTION
    Tests the GitHub secret helper functions that retrieve connection parameters from environment variables.
#>

BeforeAll {
    # Import the necessary modules
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\SPALM\SPALM.psm1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
    }
}

Describe "Get-InternalGitHubSecretParameters" {
    BeforeAll {
        # Save current environment variable state
        $originalEnvVars = @{}
        $testVars = @(
            "TEST_SITE_URL",
            "AZURE_APP_CLIENT_ID",
            "AZURE_APP_CLIENT_SECRET",
            "AZURE_APP_TENANT_ID",
            "GITHUB_ACTIONS"
        )

        foreach ($var in $testVars) {
            if (Test-Path env:$var) {
                $originalEnvVars[$var] = [Environment]::GetEnvironmentVariable($var)
            }
        }
    }

    AfterAll {
        # Restore original environment variable state
        foreach ($key in $originalEnvVars.Keys) {
            [Environment]::SetEnvironmentVariable($key, $originalEnvVars[$key])
        }

        # Clean up any test vars that didn't exist before
        foreach ($var in $testVars) {
            if (-not $originalEnvVars.ContainsKey($var)) {
                [Environment]::SetEnvironmentVariable($var, $null)
            }
        }
    }

    It "Returns null when site URL environment variable doesn't exist" {
        # Ensure environment variables don't exist
        [Environment]::SetEnvironmentVariable("TEST_SITE_URL", $null)
        [Environment]::SetEnvironmentVariable("AZURE_APP_CLIENT_ID", $null)
        [Environment]::SetEnvironmentVariable("AZURE_APP_CLIENT_SECRET", $null)
        [Environment]::SetEnvironmentVariable("AZURE_APP_TENANT_ID", $null)

        # Test the function
        $result = Get-InternalGitHubSecretParameters -ConnectionName "Test"
        $result | Should -BeNullOrEmpty
    }

    It "Returns Interactive connection when only URL is available" {
        # Set up environment variables
        [Environment]::SetEnvironmentVariable("TEST_SITE_URL", "https://test.sharepoint.com/sites/test")
        [Environment]::SetEnvironmentVariable("AZURE_APP_CLIENT_ID", $null)
        [Environment]::SetEnvironmentVariable("AZURE_APP_CLIENT_SECRET", $null)

        # Test the function
        $result = Get-InternalGitHubSecretParameters -ConnectionName "Test"

        # Check results
        $result | Should -Not -BeNullOrEmpty
        $result.Url | Should -Be "https://test.sharepoint.com/sites/test"
        $result.ConnectionType | Should -Be "Interactive"
        $result.ClientId | Should -BeNullOrEmpty
        $result.ClientSecret | Should -BeNullOrEmpty
    }

    It "Returns ClientSecret connection when ClientId and ClientSecret are available" {
        # Set up environment variables
        [Environment]::SetEnvironmentVariable("TEST_SITE_URL", "https://test.sharepoint.com/sites/test")
        [Environment]::SetEnvironmentVariable("AZURE_APP_CLIENT_ID", "test-client-id")
        [Environment]::SetEnvironmentVariable("AZURE_APP_CLIENT_SECRET", "test-client-secret")
        [Environment]::SetEnvironmentVariable("AZURE_APP_TENANT_ID", "test-tenant-id")

        # Test the function
        $result = Get-InternalGitHubSecretParameters -ConnectionName "Test"

        # Check results
        $result | Should -Not -BeNullOrEmpty
        $result.Url | Should -Be "https://test.sharepoint.com/sites/test"
        $result.ConnectionType | Should -Be "ClientSecret"
        $result.ClientId | Should -Be "test-client-id"
        $result.ClientSecret | Should -Be "test-client-secret"
        $result.TenantId | Should -Be "test-tenant-id"
    }

    It "Handles missing TenantId gracefully" {
        # Set up environment variables
        [Environment]::SetEnvironmentVariable("TEST_SITE_URL", "https://test.sharepoint.com/sites/test")
        [Environment]::SetEnvironmentVariable("AZURE_APP_CLIENT_ID", "test-client-id")
        [Environment]::SetEnvironmentVariable("AZURE_APP_CLIENT_SECRET", "test-client-secret")
        [Environment]::SetEnvironmentVariable("AZURE_APP_TENANT_ID", $null)

        # Test the function
        $result = Get-InternalGitHubSecretParameters -ConnectionName "Test"

        # Check results
        $result | Should -Not -BeNullOrEmpty
        $result.Url | Should -Be "https://test.sharepoint.com/sites/test"
        $result.ConnectionType | Should -Be "ClientSecret"
        $result.ClientId | Should -Be "test-client-id"
        $result.ClientSecret | Should -Be "test-client-secret"
        $result.TenantId | Should -BeNullOrEmpty
    }

    It "Uses uppercase connection name for environment variable" {
        # Set up environment variables with lowercase and uppercase
        [Environment]::SetEnvironmentVariable("test_site_url", $null)  # lowercase shouldn't be found
        [Environment]::SetEnvironmentVariable("TEST_SITE_URL", "https://test.sharepoint.com/sites/test")  # uppercase should be found

        # Test the function
        $result = Get-InternalGitHubSecretParameters -ConnectionName "test"  # lowercase input

        # Check results
        $result | Should -Not -BeNullOrEmpty
        $result.Url | Should -Be "https://test.sharepoint.com/sites/test"
    }
}

Describe "Get-InternalConnectionParameters" {
    BeforeAll {
        # Save current environment variable state
        $originalEnvVars = @{}
        $testVars = @(
            "TEST_SITE_URL",
            "AZURE_APP_CLIENT_ID",
            "AZURE_APP_CLIENT_SECRET",
            "AZURE_APP_TENANT_ID"
        )

        foreach ($var in $testVars) {
            if (Test-Path env:$var) {
                $originalEnvVars[$var] = [Environment]::GetEnvironmentVariable($var)
            }
        }

        # Mock the Get-InternalPrivateConnections function
        Mock Get-InternalPrivateConnections {
            return @{
                "PrivateTest" = @{
                    "Url" = "https://private.sharepoint.com/sites/test"
                    "AuthType" = "ClientSecret"
                    "ClientId" = "private-client-id"
                    "ClientSecret" = "private-client-secret"
                    "TenantId" = "private-tenant-id"
                }
            }
        }
    }

    AfterAll {
        # Restore original environment variable state
        foreach ($key in $originalEnvVars.Keys) {
            [Environment]::SetEnvironmentVariable($key, $originalEnvVars[$key])
        }

        # Clean up any test vars that didn't exist before
        foreach ($var in $testVars) {
            if (-not $originalEnvVars.ContainsKey($var)) {
                [Environment]::SetEnvironmentVariable($var, $null)
            }
        }
    }

    It "Uses GitHub secrets when available" {
        # Set up environment variables
        [Environment]::SetEnvironmentVariable("TEST_SITE_URL", "https://test.sharepoint.com/sites/test")
        [Environment]::SetEnvironmentVariable("AZURE_APP_CLIENT_ID", "test-client-id")
        [Environment]::SetEnvironmentVariable("AZURE_APP_CLIENT_SECRET", "test-client-secret")

        # Test the function
        $result = Get-InternalConnectionParameters -SiteUrl "https://default.sharepoint.com" -ConnectionName "Test"

        # Should use GitHub secret parameters
        $result | Should -Not -BeNullOrEmpty
        $result.Url | Should -Be "https://test.sharepoint.com/sites/test"
        $result.ConnectionType | Should -Be "ClientSecret"
        $result.ClientId | Should -Be "test-client-id"
        $result.ClientSecret | Should -Be "test-client-secret"
    }

    It "Falls back to private connections when GitHub secrets not available" {
        # Ensure GitHub environment variables don't exist
        [Environment]::SetEnvironmentVariable("TEST_SITE_URL", $null)

        # Test the function with a connection name that exists in private connections
        $result = Get-InternalConnectionParameters -SiteUrl "https://default.sharepoint.com" -ConnectionName "PrivateTest"

        # Should use private connection parameters
        $result | Should -Not -BeNullOrEmpty
        $result.Url | Should -Be "https://private.sharepoint.com/sites/test"
        $result.ConnectionType | Should -Be "ClientSecret"
        $result.ClientId | Should -Be "private-client-id"
        $result.ClientSecret | Should -Be "private-client-secret"
        $result.TenantId | Should -Be "private-tenant-id"
    }

    It "Returns default parameters when no connection found" {
        # Ensure GitHub environment variables don't exist
        [Environment]::SetEnvironmentVariable("NONEXISTENT_SITE_URL", $null)

        # Test with a non-existent connection name
        $result = Get-InternalConnectionParameters -SiteUrl "https://default.sharepoint.com" -ConnectionName "NonExistent"

        # Should return default parameters
        $result | Should -Not -BeNullOrEmpty
        $result.Url | Should -Be "https://default.sharepoint.com"
        $result.ConnectionType | Should -Be "Interactive"
    }

    It "Uses the provided site URL when no connection name specified" {
        # Test without a connection name
        $result = Get-InternalConnectionParameters -SiteUrl "https://provided.sharepoint.com"

        # Should use the provided URL
        $result | Should -Not -BeNullOrEmpty
        $result.Url | Should -Be "https://provided.sharepoint.com"
        $result.ConnectionType | Should -Be "Interactive"
    }
}
