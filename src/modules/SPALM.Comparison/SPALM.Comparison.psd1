@{
    RootModule = 'SPALM.Comparison.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'fb3c71d5-f7a6-49f2-ab32-8f00b9c1e0d5'
    Author = 'SPALM Team'
    CompanyName = 'SPALM'
    Copyright = '(c) 2025 SPALM. All rights reserved.'
    Description = 'SharePoint site comparison module for SPALM toolkit'
    PowerShellVersion = '7.0'
    CompatiblePSEditions = @('Core', 'Desktop')
    RequiredModules = @('PnP.PowerShell', 'SPALM.Core')
    FunctionsToExport = @(
        'Compare-SPALMSite',
        'Compare-SPALMSiteColumns',
        'Compare-SPALMContentTypes',
        'Compare-SPALMLists',
        'Compare-SPALMListViews',
        'Export-SPALMComparisonReport'
    )
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('SharePoint', 'ALM', 'PnP', 'SPALM', 'Comparison')
            ProjectUri = 'https://github.com/yourusername/SPALM'
        }
    }
}
