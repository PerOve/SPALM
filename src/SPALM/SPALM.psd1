@{
    RootModule = 'SPALM.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'a9a68ce5-9c1f-4c80-b6a9-c9a6ae8757b5'
    Author = 'SPALM Team'
    CompanyName = 'SPALM'
    Copyright = '(c) 2025 SPALM. All rights reserved.'
    Description = 'SharePoint ALM toolkit for managing site columns, content types, lists and views across environments'
    PowerShellVersion = '7.0'
    CompatiblePSEditions = @('Core', 'Desktop')
    RequiredModules = @('PnP.PowerShell')
    FunctionsToExport = @(
        # Core functions
        'Connect-SPALMSite',
        'Disconnect-SPALMSite',
        'Get-SPALMConfiguration',
        'Set-SPALMConfiguration',

        # Comparison functions
        'Compare-SPALMSite',
        'Compare-SPALMSiteColumns',
        'Compare-SPALMContentTypes',
        'Compare-SPALMLists',
        'Compare-SPALMListViews',
        'Export-SPALMComparisonReport',

        # Provisioning functions
        'New-SPALMSiteFromSource',
        'Copy-SPALMSiteStructure',

        # Migration functions
        'Invoke-SPALMSiteMigration',
        'Get-SPALMMigrationPlan',
        'Backup-SPALMSiteArtifacts',

        # Cleanup functions
        'Invoke-SPALMCleanup',
        'Get-SPALMCleanupPlan'
    )
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('SharePoint', 'ALM', 'PnP', 'SPALM')
            ProjectUri = 'https://github.com/yourusername/SPALM'
        }
    }
}
