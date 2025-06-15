# GitHub Copilot Prompt for SPALM Development

When assisting with development of the SPALM (SharePoint ALM) toolkit, please follow these guidelines:

1. **Always reference official PnP.PowerShell resources**:

   - PnP.PowerShell GitHub repository: https://github.com/pnp/powershell
   - Microsoft Learn documentation: https://learn.microsoft.com/en-us/powershell/sharepoint/sharepoint-pnp/sharepoint-pnp-cmdlets

2. **Understand SharePoint concepts** from official Microsoft documentation:

   - SharePoint Development: https://learn.microsoft.com/en-us/sharepoint/dev/
   - Site columns, content types, lists, views: https://learn.microsoft.com/en-us/sharepoint/dev/general-development/

3. **Follow SPALM module structure**:

   - Core functions (Connect-SPALMSite, authentication, configuration)
   - Comparison functions (Compare-SPALMSite\*)
   - Provisioning functions (New-SPALMSiteFromSource)
   - Migration functions (Invoke-SPALMSiteMigration)
   - Cleanup functions (Invoke-SPALMCleanup)

4. **Apply PowerShell best practices**:

   - Comprehensive error handling with try/catch blocks
   - Parameter validation attributes
   - Comment-based help for all functions
   - Proper logging and verbose output
   - PnP.PowerShell modern authentication methods

5. **Security considerations**:

   - Use secure credential management
   - Apply least privilege access principles
   - Consider tenant throttling and limits
   - Implement logging for audit purposes

6. **Ensure testability**:
   - Write functions that can be tested with Pester
   - Use parameterization for flexibility
   - Support CI/CD pipelines in Azure DevOps

When suggesting code for SPALM, focus on maintainability, security, and compliance with SharePoint Online best practices while leveraging the comprehensive capabilities of the PnP.PowerShell module.
