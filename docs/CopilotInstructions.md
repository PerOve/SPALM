# GitHub Copilot Instructions for SPALM Development

## Overview

This document provides guidance for GitHub Copilot when working with the SPALM (SharePoint ALM) toolkit. SPALM is built on top of PnP.PowerShell and provides functionality for comparing, provisioning, migrating, and cleaning up SharePoint artifacts across multiple environments.

## PnP.PowerShell References

### GitHub Repository

The PnP.PowerShell module is an open-source project available on GitHub. When suggesting code for SPALM functions, reference the official repository for best practices and examples:

- **Repository**: [PnP.PowerShell GitHub Repository](https://github.com/pnp/powershell)
- **Issues and Features**: [PnP.PowerShell Issues](https://github.com/pnp/powershell/issues)
- **Command Documentation**: [PnP.PowerShell Wiki](https://github.com/pnp/powershell/wiki)

### Microsoft Documentation

For comprehensive documentation on PnP.PowerShell, refer to the official Microsoft Learn resources:

- **PnP.PowerShell Module Documentation**: [PnP PowerShell Overview](https://learn.microsoft.com/en-us/powershell/sharepoint/sharepoint-pnp/sharepoint-pnp-cmdlets)
- **SharePoint Online Management**: [SharePoint Online Management Shell](https://learn.microsoft.com/en-us/powershell/sharepoint/sharepoint-online/connect-sharepoint-online)
- **SharePoint Development**: [SharePoint Development Patterns and Practices](https://learn.microsoft.com/en-us/sharepoint/dev/solution-guidance/pnp)

## SPALM Module Structure

The SPALM toolkit is organized as a single PowerShell module with separate function files grouped by purpose:

1. **Core.ps1** - Core functions for connecting to SharePoint, configuration management
2. **Comparison.ps1** - Functions for comparing SharePoint artifacts between sites
3. **Provisioning.ps1** - Functions for creating and provisioning SharePoint sites
4. **Migration.ps1** - Functions for migrating SharePoint artifacts between sites
5. **Cleanup.ps1** - Functions for cleaning up SharePoint artifacts

## Code Generation Guidelines

When suggesting or generating code for SPALM:

### Authentication and Connection

Always use PnP.PowerShell's modern authentication methods and connection patterns:

```powershell
# Example connection pattern
function Connect-SPALMSite {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Interactive", "ClientSecret", "Certificate")]
        [string]$ConnectionType = "Interactive"

        # Additional parameters
    )

    # Connection logic with proper error handling
}
```

### Error Handling

Implement comprehensive error handling using try/catch blocks and appropriate logging:

```powershell
try {
    # SharePoint operation
}
catch {
    Write-Error "Operation failed: $_"
    # Additional error handling
}
```

### Parameter Validation

Use parameter validation attributes for input validation:

```powershell
[Parameter(Mandatory = $true)]
[ValidateNotNullOrEmpty()]
[string]$SiteUrl
```

### Documentation

Include comment-based help for all functions following PowerShell best practices:

```powershell
<#
.SYNOPSIS
    Brief description of function
.DESCRIPTION
    Detailed description of function
.PARAMETER ParameterName
    Description of parameter
.EXAMPLE
    Example-Function -Parameter Value
.NOTES
    Additional information
#>
```

## SharePoint Concepts Reference

When working with SharePoint artifacts in SPALM, refer to these resources:

- **Site Columns**: [Site Column Overview](https://learn.microsoft.com/en-us/sharepoint/dev/general-development/site-column-xml-format)
- **Content Types**: [Content Type Overview](https://learn.microsoft.com/en-us/sharepoint/dev/general-development/content-type-xml-format)
- **Lists and Libraries**: [Lists and Libraries Overview](https://learn.microsoft.com/en-us/sharepoint/dev/general-development/list-schema-xml-format)
- **Views**: [View Schema Overview](https://learn.microsoft.com/en-us/sharepoint/dev/schema/view-schema)

## Examples for Common Tasks

### Comparing Site Columns

```powershell
# Example pattern for comparing site columns
$sourceColumns = Get-PnPField -Connection $sourceConnection -IncludeAll
$targetColumns = Get-PnPField -Connection $targetConnection -IncludeAll

# Process and compare
```

### Creating Site Columns

```powershell
# Example pattern for creating site columns
$fieldXml = '<Field ID="{guid}" Name="FieldName" Type="Text" />'
Add-PnPFieldFromXml -FieldXml $fieldXml
```

### Provisioning Content Types

```powershell
# Example pattern for provisioning content types
$contentTypeInfo = @{
    Name = "CustomContentType"
    Group = "Custom Content Types"
    Description = "Description"
}
Add-PnPContentType @contentTypeInfo
```

## Security and Compliance

When working with SharePoint data, ensure code follows security best practices:

- Store credentials securely, never in plain text
- Use least privilege principles for connections
- Consider tenant throttling limits
- Implement proper logging for audit trails

## Testing

Encourage test-driven development with Pester for all SPALM functions:

```powershell
# Example Pester test pattern
Describe "Function-Name" {
    BeforeAll {
        # Test setup
    }

    It "Should perform expected action" {
        # Test code and assertions
    }
}
```

## Continuous Integration/Deployment

Reference Azure DevOps pipeline practices for SharePoint solutions:

- Build validation
- Automated testing
- Environment-specific deployments (DEV/TEST/PROD)
- Release approval workflows
