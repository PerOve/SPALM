<#
.SYNOPSIS
    Example script to create a private SharePoint connection profile.
    SAVE THIS AS private-connection.ps1 IN THE config/private DIRECTORY
.DESCRIPTION
    This script demonstrates how to create and store SharePoint connection settings
    for personal use in a way that won't be committed to the public repository.
#>

$personalConnections = @{
    "MyDevTenant"  = @{
        "Url"                 = "https://mytenant.sharepoint.com/sites/mydev"
        "AuthType"            = "Interactive" # Interactive, ClientSecret, Certificate
        "ClientId"            = "" # For app-only authentication
        "CertificatePath"     = "" # For certificate authentication
        "CertificatePassword" = "" # For certificate authentication
        "TenantId"            = "" # For app-only authentication
    }
    "MyTestTenant" = @{
        "Url"                 = "https://mytenant.sharepoint.com/sites/mytest"
        "AuthType"            = "Interactive"
        "ClientId"            = ""
        "CertificatePath"     = ""
        "CertificatePassword" = ""
        "TenantId"            = ""
    }
    "MyProdTenant" = @{
        "Url"                 = "https://mytenant.sharepoint.com/sites/myprod"
        "AuthType"            = "Interactive"
        "ClientId"            = ""
        "CertificatePath"     = ""
        "CertificatePassword" = ""
        "TenantId"            = ""
    }
}

# Save this to a private file
$personalConnections | ConvertTo-Json -Depth 5 | Out-File -FilePath "$PSScriptRoot\private\connections.private.json"

Write-Host "Personal connection profiles have been created in config/private/connections.private.json"
