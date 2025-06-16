<#
.SYNOPSIS
    Integration tests for the GitHub secrets connection functionality
.DESCRIPTION
    Tests the entire flow of the GitHub secrets connection system, including:
    - Setting up connections from environment variables
    - Using those connections with Connect-SPALMSite
    - Testing the proper prioritization of connection sources
#>

BeforeAll {
    # Import the necessary modules
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\SPALM\SPALM.psm1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
    }

    # Path to the script being tested
    $script:gitHubConnectionsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\config\set-github-connections.ps1"

    # Mock Connect-PnPOnline which is used by Connect-SPALMSite
    Mock Connect-PnPOnline {
        # Return different values based on parameters to verify correct parameters were used
        if ($Url -eq "https://env.sharepoint.com") {
            return "Connected to environment variable URL"
        }
        elseif ($Url -eq "https://private.sharepoint.com") {
            return "Connected to private config URL"
        }
        else {
            return "Connected to $Url"
        }
    }

    # Mock Get-InternalPrivateConnections
    Mock Get-InternalPrivateConnections {
        return @{
            "PrivateConnection" = @{
                "Url" = "https://private.sharepoint.com"
                "AuthType" = "ClientSecret"
                "ClientId" = "private-client-id"
                "ClientSecret" = "private-client-secret"
                "TenantId" = "private-tenant-id"
            }
        }
    }

    # Mock Out-File to prevent creating actual files
    Mock Out-File { return $true }

    # Mock Test-Path for the private directory
    Mock Test-Path { return $false } -ParameterFilter { $Path -like "*\private" }

    # Mock New-Item for creating directories
    Mock New-Item { return [PSCustomObject]@{ Path = $Path } }

    # Save current environment variable state
    $script:originalEnvVars = @{}
    $testVars = @(
        "DEV_SITE_URL",
        "TEST_SITE_URL",
        "PROD_SITE_URL",
        "SOURCE_SITE_URL",
        "AZURE_APP_CLIENT_ID",
        "AZURE_APP_CLIENT_SECRET",
        "AZURE_APP_TENANT_ID",
        "GITHUB_ACTIONS"
    )

    foreach ($var in $testVars) {
        if (Test-Path env:$var) {
            $script:originalEnvVars[$var] = [Environment]::GetEnvironmentVariable($var)
        }
    }
}

AfterAll {
    # Restore original environment variable state
    foreach ($key in $script:originalEnvVars.Keys) {
        [Environment]::SetEnvironmentVariable($key, $script:originalEnvVars[$key])
    }

    # Clean up any test vars that didn't exist before
    $testVars | ForEach-Object {
        if (-not $script:originalEnvVars.ContainsKey($_)) {
            [Environment]::SetEnvironmentVariable($_, $null)
        }
    }
}

Describe "GitHub Secrets Connection Integration" {
    Context "Environment variable connections" {
        BeforeEach {
            # Set up environment variables
            [Environment]::SetEnvironmentVariable("DEV_SITE_URL", "https://env.sharepoint.com")
            [Environment]::SetEnvironmentVariable("AZURE_APP_CLIENT_ID", "env-client-id")
            [Environment]::SetEnvironmentVariable("AZURE_APP_CLIENT_SECRET", "env-client-secret")
            [Environment]::SetEnvironmentVariable("AZURE_APP_TENANT_ID", "env-tenant-id")
            [Environment]::SetEnvironmentVariable("GITHUB_ACTIONS", "true")

            # Source the GitHub connections script
            . $script:gitHubConnectionsPath
        }

        It "Creates connections from environment variables" {
            # Check that the connections were created
            $connections | Should -Not -BeNullOrEmpty
            $connections.Dev | Should -Not -BeNullOrEmpty
            $connections.Dev.Url | Should -Be "https://env.sharepoint.com"
        }

        It "Properly connects using GitHub secret-based connection" {
            # Connect using the connection name
            $result = Connect-SPALMSite -ConnectionName "Dev"

            $result | Should -Be $true
            Should -Invoke Connect-PnPOnline -Times 1 -Exactly -ParameterFilter {
                $Url -eq "https://env.sharepoint.com" -and
                $ClientId -eq "env-client-id" -and
                $ClientSecret -eq "env-client-secret" -and
                $TenantId -eq "env-tenant-id"
            }
        }
    }

    Context "Prioritization of connection sources" {
        BeforeEach {
            # Clean up environment variables
            [Environment]::SetEnvironmentVariable("DEV_SITE_URL", $null)
            [Environment]::SetEnvironmentVariable("GITHUB_ACTIONS", $null)

            # Re-source the GitHub connections script
            . $script:gitHubConnectionsPath
        }

        It "Falls back to private connections when environment variables are not available" {
            # Connect using a connection name that exists in private configs
            $result = Connect-SPALMSite -ConnectionName "PrivateConnection"

            $result | Should -Be $true
            Should -Invoke Connect-PnPOnline -Times 1 -Exactly -ParameterFilter {
                $Url -eq "https://private.sharepoint.com" -and
                $ClientId -eq "private-client-id" -and
                $ClientSecret -eq "private-client-secret" -and
                $TenantId -eq "private-tenant-id"
            }
        }

        It "Uses explicitly provided parameters when no connection found" {
            # Connect using explicit parameters
            $result = Connect-SPALMSite -Url "https://explicit.sharepoint.com" -ClientId "explicit-id" -ClientSecret "explicit-secret"

            $result | Should -Be $true
            Should -Invoke Connect-PnPOnline -Times 1 -Exactly -ParameterFilter {
                $Url -eq "https://explicit.sharepoint.com" -and
                $ClientId -eq "explicit-id" -and
                $ClientSecret -eq "explicit-secret"
            }
        }
    }

    Context "Local environment behavior" {
        BeforeEach {
            # Set up as non-GitHub environment
            [Environment]::SetEnvironmentVariable("DEV_SITE_URL", "https://env.sharepoint.com")
            [Environment]::SetEnvironmentVariable("GITHUB_ACTIONS", $null)

            # Re-source the GitHub connections script
            . $script:gitHubConnectionsPath
        }

        It "Creates a local connections file when not in GitHub Actions" {
            # Should try to write a file
            Should -Invoke Test-Path -Times 1 -Exactly
            Should -Invoke New-Item -Times 1 -Exactly
            Should -Invoke Out-File -Times 1 -Exactly
        }
    }
}
