<#
.SYNOPSIS
    Pester tests for set-github-connections.ps1
.DESCRIPTION
    Tests the functionality of the GitHub connections script including environment detection,
    secret retrieval, and connection object creation.
#>

BeforeAll {
    # Import the necessary modules
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\SPALM\SPALM.psm1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
    }

    # Path to the script being tested
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\config\set-github-connections.ps1"

    # Dot source the script to get access to its functions
    . $scriptPath
}

Describe "Test-GitHubActionsEnvironment" {
    It "Returns false when not in GitHub Actions" {
        # Backup the original value
        $originalValue = $env:GITHUB_ACTIONS

        try {
            # Ensure GITHUB_ACTIONS is not set
            $env:GITHUB_ACTIONS = $null

            # Test the function
            Test-GitHubActionsEnvironment | Should -Be $false
        } finally {
            # Restore the original value
            $env:GITHUB_ACTIONS = $originalValue
        }
    }

    It "Returns true when in GitHub Actions" {
        # Backup the original value
        $originalValue = $env:GITHUB_ACTIONS

        try {
            # Set GITHUB_ACTIONS to simulate GitHub environment
            $env:GITHUB_ACTIONS = "true"

            # Test the function
            Test-GitHubActionsEnvironment | Should -Be $true
        } finally {
            # Restore the original value
            $env:GITHUB_ACTIONS = $originalValue
        }
    }
}

Describe "Get-SecretFromEnvironment" {
    BeforeAll {
        # Save current environment variable state
        $originalEnvVars = @{}
        $testVarName = "TEST_SECRET_VAR"
        if (Test-Path env:$testVarName) {
            $originalEnvVars[$testVarName] = [Environment]::GetEnvironmentVariable($testVarName)
        }
    }

    AfterAll {
        # Restore original environment variable state
        foreach ($key in $originalEnvVars.Keys) {
            [Environment]::SetEnvironmentVariable($key, $originalEnvVars[$key])
        }
        # Clean up any test vars that didn't exist before
        if (-not $originalEnvVars.ContainsKey($testVarName)) {
            [Environment]::SetEnvironmentVariable($testVarName, $null)
        }
    }

    It "Returns the environment variable value when it exists" {
        # Set test environment variable
        [Environment]::SetEnvironmentVariable($testVarName, "TestValue")

        # Test the function
        Get-SecretFromEnvironment -SecretName $testVarName | Should -Be "TestValue"
    }

    It "Returns the default value when environment variable doesn't exist" {
        # Ensure the var doesn't exist
        [Environment]::SetEnvironmentVariable($testVarName, $null)

        # Test with default value
        Get-SecretFromEnvironment -SecretName $testVarName -DefaultValue "DefaultValue" |
            Should -Be "DefaultValue"
    }

    It "Returns empty string when environment variable doesn't exist and no default is provided" {
        # Ensure the var doesn't exist
        [Environment]::SetEnvironmentVariable($testVarName, $null)

        # Test without default value
        Get-SecretFromEnvironment -SecretName $testVarName | Should -Be ""
    }
}

Describe "New-ConnectionFromSecrets" {
    BeforeAll {
        # Save current environment variable state
        $originalEnvVars = @{}
        $testVars = @(
            "TEST_URL",
            "TEST_CLIENT_ID",
            "TEST_CLIENT_SECRET",
            "TEST_TENANT_ID",
            "TEST_CERT_PATH",
            "TEST_CERT_PASSWORD"
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

    It "Returns null when URL is not found" {
        # Ensure the URL var doesn't exist
        [Environment]::SetEnvironmentVariable("TEST_URL", $null)

        # Test the function
        $result = New-ConnectionFromSecrets -ConnectionName "Test" -UrlSecretName "TEST_URL"
        $result | Should -BeNullOrEmpty
    }

    It "Creates a connection object with ClientSecret auth type" {
        # Set test environment variables
        [Environment]::SetEnvironmentVariable("TEST_URL", "https://test.sharepoint.com")
        [Environment]::SetEnvironmentVariable("TEST_CLIENT_ID", "test-client-id")
        [Environment]::SetEnvironmentVariable("TEST_CLIENT_SECRET", "test-client-secret")
        [Environment]::SetEnvironmentVariable("TEST_TENANT_ID", "test-tenant-id")

        # Test the function
        $result = New-ConnectionFromSecrets -ConnectionName "Test" -UrlSecretName "TEST_URL" `
            -ClientIdSecretName "TEST_CLIENT_ID" `
            -ClientSecretSecretName "TEST_CLIENT_SECRET" `
            -TenantIdSecretName "TEST_TENANT_ID"

        $result | Should -Not -BeNullOrEmpty
        $result.Url | Should -Be "https://test.sharepoint.com"
        $result.AuthType | Should -Be "ClientSecret"
        $result.ClientId | Should -Be "test-client-id"
        $result.ClientSecret | Should -Be "test-client-secret"
        $result.TenantId | Should -Be "test-tenant-id"
    }

    It "Creates a connection object with Certificate auth type" {
        # Set test environment variables
        [Environment]::SetEnvironmentVariable("TEST_URL", "https://test.sharepoint.com")
        [Environment]::SetEnvironmentVariable("TEST_CLIENT_ID", "test-client-id")
        [Environment]::SetEnvironmentVariable("TEST_CERT_PATH", "/path/to/cert.pfx")
        [Environment]::SetEnvironmentVariable("TEST_CERT_PASSWORD", "test-cert-password")
        [Environment]::SetEnvironmentVariable("TEST_TENANT_ID", "test-tenant-id")

        # Test the function
        $result = New-ConnectionFromSecrets -ConnectionName "Test" -UrlSecretName "TEST_URL" `
            -AuthType "Certificate" `
            -ClientIdSecretName "TEST_CLIENT_ID" `
            -CertificatePathSecretName "TEST_CERT_PATH" `
            -CertificatePasswordSecretName "TEST_CERT_PASSWORD" `
            -TenantIdSecretName "TEST_TENANT_ID"

        $result | Should -Not -BeNullOrEmpty
        $result.Url | Should -Be "https://test.sharepoint.com"
        $result.AuthType | Should -Be "Certificate"
        $result.ClientId | Should -Be "test-client-id"
        $result.CertificatePath | Should -Be "/path/to/cert.pfx"
        $result.CertificatePassword | Should -Be "test-cert-password"
        $result.TenantId | Should -Be "test-tenant-id"
    }

    It "Creates a connection object with Interactive auth type" {
        # Set test environment variables
        [Environment]::SetEnvironmentVariable("TEST_URL", "https://test.sharepoint.com")

        # Test the function
        $result = New-ConnectionFromSecrets -ConnectionName "Test" -UrlSecretName "TEST_URL" `
            -AuthType "Interactive"

        $result | Should -Not -BeNullOrEmpty
        $result.Url | Should -Be "https://test.sharepoint.com"
        $result.AuthType | Should -Be "Interactive"
        # Should not have auth parameters
        $result.ClientId | Should -BeNullOrEmpty
        $result.ClientSecret | Should -BeNullOrEmpty
    }
}

Describe "Merge-Hashtable" {
    It "Merges multiple hashtables correctly" {
        # Create test hashtables
        $hash1 = @{ Key1 = "Value1"; Key2 = "Value2" }
        $hash2 = @{ Key3 = "Value3"; Key4 = "Value4" }
        $hash3 = @{ Key5 = "Value5"; Key6 = "Value6" }

        # Create array of hashtables and pipe to the function
        $result = @($hash1, $hash2, $hash3) | Merge-Hashtable

        # Test the result
        $result | Should -Not -BeNullOrEmpty
        $result.Keys.Count | Should -Be 6
        $result.Key1 | Should -Be "Value1"
        $result.Key2 | Should -Be "Value2"
        $result.Key3 | Should -Be "Value3"
        $result.Key4 | Should -Be "Value4"
        $result.Key5 | Should -Be "Value5"
        $result.Key6 | Should -Be "Value6"
    }

    It "Handles empty input gracefully" {
        # Create empty array
        $emptyArray = @()

        # Test with empty array
        $result = $emptyArray | Merge-Hashtable

        # Result should be an empty hashtable
        $result | Should -Not -BeNullOrEmpty
        $result.Keys.Count | Should -Be 0
    }

    It "Overwrites duplicate keys with the latest value" {
        # Create test hashtables with duplicates
        $hash1 = @{ Key1 = "Original"; Key2 = "Value2" }
        $hash2 = @{ Key1 = "Overwritten"; Key3 = "Value3" }

        # Create array of hashtables and pipe to the function
        $result = @($hash1, $hash2) | Merge-Hashtable

        # Test the result
        $result | Should -Not -BeNullOrEmpty
        $result.Keys.Count | Should -Be 3
        $result.Key1 | Should -Be "Overwritten"  # Should be the value from hash2
        $result.Key2 | Should -Be "Value2"
        $result.Key3 | Should -Be "Value3"
    }
}
