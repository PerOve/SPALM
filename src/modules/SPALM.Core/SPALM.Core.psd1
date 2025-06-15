@{
    RootModule = 'SPALM.Core.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'a9a68ce5-9c1f-4c80-b6a9-c9a6ae8757b5'
    Author = 'SPALM Team'
    CompanyName = 'SPALM'
    Copyright = '(c) 2025 SPALM. All rights reserved.'
    Description = 'Core module for SharePoint ALM toolkit'
    PowerShellVersion = '7.0'
    CompatiblePSEditions = @('Core', 'Desktop')
    RequiredModules = @('PnP.PowerShell')
    FunctionsToExport = @(
        'Connect-SPALMSite',
        'Disconnect-SPALMSite',
        'Get-SPALMConfiguration',
        'Set-SPALMConfiguration'
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
