<#
.SYNOPSIS
    Pester tests for deploy-with-github-secrets.ps1
.DESCRIPTION
    Tests the deployment script that uses GitHub secrets for SharePoint connections.
#>

BeforeAll {
    # Import the necessary modules
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\SPALM\SPALM.psm1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
    }

    # Path to the script being tested
    $script:scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\config\deploy-with-github-secrets.ps1"

    # Mock all the functions that interact with external systems
    Mock Connect-SPALMSite { return $true }
    Mock Get-PnPConnection {
        param($ConnectionName)

        # Return mock connections based on name
        if ($ConnectionName -eq "Source") {
            return [PSCustomObject]@{ Url = "https://contoso.sharepoint.com/sites/source" }
        }
        elseif ($ConnectionName -eq "Dev") {
            return [PSCustomObject]@{ Url = "https://contoso.sharepoint.com/sites/dev" }
        }
        elseif ($ConnectionName -eq "Test") {
            return [PSCustomObject]@{ Url = "https://contoso.sharepoint.com/sites/test" }
        }
        elseif ($ConnectionName -eq "Prod") {
            return [PSCustomObject]@{ Url = "https://contoso.sharepoint.com/sites/prod" }
        }
    }

    Mock Compare-SPALMSite {
        return [PSCustomObject]@{
            ColumnsToAdd = @("Column1", "Column2")
            ContentTypesToAdd = @("ContentType1")
            ListsToAdd = @("List1")
        }
    }

    Mock Get-SPALMMigrationPlan {
        return [PSCustomObject]@{
            Steps = @(
                [PSCustomObject]@{
                    Action = "AddSiteColumn"
                    Name = "Column1"
                },
                [PSCustomObject]@{
                    Action = "AddContentType"
                    Name = "ContentType1"
                }
            )
        }
    }

    Mock Invoke-SPALMSiteMigration { return $true }
    Mock Disconnect-SPALMSite { return $true }
    Mock ConvertTo-Json { return "{}" }
    Mock Out-File { return $true }

    # Create a mock for the set-github-connections.ps1 file
    Mock Get-Content { return "# Mocked script content" }
    Mock Invoke-Expression { return $true }

    # Mock the dot sourcing of set-github-connections.ps1
    # This is a bit tricky, so we'll use a module scope variable to track if it was called
    $script:SetGitHubConnectionsCalled = $false
    Mock -CommandName '.' -ParameterFilter { $_ -like "*set-github-connections.ps1" } -MockWith {
        $script:SetGitHubConnectionsCalled = $true
    }
}

Describe "deploy-with-github-secrets.ps1" {
    BeforeAll {
        # Make environment variables available
        $env:SOURCE_SITE_URL = "https://contoso.sharepoint.com/sites/source"
        $env:DEV_SITE_URL = "https://contoso.sharepoint.com/sites/dev"
        $env:TEST_SITE_URL = "https://contoso.sharepoint.com/sites/test"
        $env:PROD_SITE_URL = "https://contoso.sharepoint.com/sites/prod"
    }

    AfterAll {
        # Clean up environment variables
        $env:SOURCE_SITE_URL = $null
        $env:DEV_SITE_URL = $null
        $env:TEST_SITE_URL = $null
        $env:PROD_SITE_URL = $null
    }

    Context "When running against Dev environment" {
        It "Sets up connections and runs comparison without errors" {
            # Run the script with parameters
            & $scriptPath -Environment "Dev" -WhatIf

            # Test if all expected function calls were made
            $script:SetGitHubConnectionsCalled | Should -BeTrue
            Should -Invoke Connect-SPALMSite -Times 2 -Exactly
            Should -Invoke Get-PnPConnection -Times 2 -Exactly
            Should -Invoke Compare-SPALMSite -Times 1 -Exactly
            Should -Invoke Get-SPALMMigrationPlan -Times 1 -Exactly
            Should -Invoke ConvertTo-Json -Times 2 -Exactly
            Should -Invoke Out-File -Times 2 -Exactly
            # Should not invoke migration in WhatIf mode
            Should -Invoke Invoke-SPALMSiteMigration -Times 0 -Exactly
            Should -Invoke Disconnect-SPALMSite -Times 1 -Exactly
        }
    }

    Context "When running with backup option" {
        It "Passes the BackupBeforeChanges parameter to Invoke-SPALMSiteMigration" {
            # Run the script with backup parameter
            & $scriptPath -Environment "Dev" -BackupBeforeChanges

            # Check that Invoke-SPALMSiteMigration was called with the BackupBeforeChanges parameter
            Should -Invoke Invoke-SPALMSiteMigration -Times 1 -Exactly -ParameterFilter {
                $BackupBeforeChanges -eq $true
            }
        }
    }

    Context "When running against different environments" {
        It "Connects to the specified environment" {
            # Test with Test environment
            & $scriptPath -Environment "Test" -WhatIf

            Should -Invoke Connect-SPALMSite -Times 1 -Exactly -ParameterFilter {
                $ConnectionName -eq "Source"
            }

            Should -Invoke Connect-SPALMSite -Times 1 -Exactly -ParameterFilter {
                $ConnectionName -eq "Test"
            }

            # Test with Prod environment
            & $scriptPath -Environment "Prod" -WhatIf

            Should -Invoke Connect-SPALMSite -Times 1 -Exactly -ParameterFilter {
                $ConnectionName -eq "Prod"
            }
        }
    }
}
