Describe "SPALM Module" {
    BeforeAll {
        # Import the module
        Import-Module $PSScriptRoot/../../src/SPALM/SPALM.psm1 -Force
    }

    Context "Module Loading" {
        It "Imports successfully" {
            Get-Module SPALM | Should -Not -BeNullOrEmpty
        }

        It "Exports the expected core functions" {
            $module = Get-Module SPALM
            $module | Should -Not -BeNullOrEmpty
            $exportedFunctions = $module.ExportedFunctions.Keys
            $exportedFunctions | Should -Contain "Connect-SPALMSite"
            $exportedFunctions | Should -Contain "Disconnect-SPALMSite"
            $exportedFunctions | Should -Contain "Get-SPALMConfiguration"
            $exportedFunctions | Should -Contain "Set-SPALMConfiguration"
        }

        It "Exports the expected comparison functions" {
            $module = Get-Module SPALM
            $module | Should -Not -BeNullOrEmpty
            $exportedFunctions = $module.ExportedFunctions.Keys
            $exportedFunctions | Should -Contain "Compare-SPALMSite"
            $exportedFunctions | Should -Contain "Compare-SPALMSiteColumns"
            $exportedFunctions | Should -Contain "Compare-SPALMContentTypes"
            $exportedFunctions | Should -Contain "Compare-SPALMLists"
            $exportedFunctions | Should -Contain "Compare-SPALMListViews"
            $exportedFunctions | Should -Contain "Export-SPALMComparisonReport"
        }

        It "Exports the expected provisioning functions" {
            $module = Get-Module SPALM
            $module | Should -Not -BeNullOrEmpty
            $exportedFunctions = $module.ExportedFunctions.Keys
            $exportedFunctions | Should -Contain "New-SPALMSiteFromSource"
            $exportedFunctions | Should -Contain "Copy-SPALMSiteStructure"
        }

        It "Exports the expected migration functions" {
            $module = Get-Module SPALM
            $module | Should -Not -BeNullOrEmpty
            $exportedFunctions = $module.ExportedFunctions.Keys
            $exportedFunctions | Should -Contain "Invoke-SPALMSiteMigration"
            $exportedFunctions | Should -Contain "Get-SPALMMigrationPlan"
            $exportedFunctions | Should -Contain "Backup-SPALMSiteArtifacts"
        }

        It "Exports the expected cleanup functions" {
            $module = Get-Module SPALM
            $module | Should -Not -BeNullOrEmpty
            $exportedFunctions = $module.ExportedFunctions.Keys
            $exportedFunctions | Should -Contain "Invoke-SPALMCleanup"
            $exportedFunctions | Should -Contain "Get-SPALMCleanupPlan"
        }
    }
}
