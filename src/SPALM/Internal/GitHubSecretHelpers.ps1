# Internal helper functions for handling GitHub secrets and environment variables

function Get-InternalGitHubSecretParameters {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConnectionName
    )

    process {
        try {
            # Check if we're in a GitHub environment
            if ($env:GITHUB_ACTIONS -eq $true) {
                Write-Verbose "Using GitHub environment for connection '$ConnectionName'"
            }

            # Determine URL environment variable based on connection name
            $urlVarName = "$($ConnectionName.ToUpper())_SITE_URL"
            $siteUrl = [System.Environment]::GetEnvironmentVariable($urlVarName)

            if (-not $siteUrl) {
                Write-Verbose "No site URL found for connection '$ConnectionName' (variable: $urlVarName)"
                return $null
            }

            # Get authentication parameters
            $clientId = [System.Environment]::GetEnvironmentVariable("AZURE_APP_CLIENT_ID")
            $clientSecret = [System.Environment]::GetEnvironmentVariable("AZURE_APP_CLIENT_SECRET")
            $tenantId = [System.Environment]::GetEnvironmentVariable("AZURE_APP_TENANT_ID")

            # Determine auth type based on available parameters
            $authType = "Interactive"
            if ($clientId -and $clientSecret) {
                $authType = "ClientSecret"
            }

            $params = @{
                Url            = $siteUrl
                ConnectionType = $authType
            }

            if ($authType -eq "ClientSecret") {
                $params.ClientId = $clientId
                $params.ClientSecret = $clientSecret
                if ($tenantId) {
                    $params.TenantId = $tenantId
                }
            }

            return $params
        } catch {
            Write-Error "Error retrieving GitHub secret parameters: $_"
            return $null
        }
    }
}

function Get-InternalConnectionParameters {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SiteUrl,

        [Parameter(Mandatory = $false)]
        [string]$ConnectionName
    )

    process {
        try {
            # If connection name is specified, first check GitHub secrets/env vars
            if ($ConnectionName) {
                $githubParams = Get-InternalGitHubSecretParameters -ConnectionName $ConnectionName
                if ($githubParams) {
                    Write-Verbose "Using parameters from GitHub secrets/environment variables"
                    return $githubParams
                }
            }

            # Then try to find in private connections
            $privateConnections = Get-InternalPrivateConnections

            if ($privateConnections -and $ConnectionName) {
                if ($privateConnections.$ConnectionName) {
                    $connInfo = $privateConnections.$ConnectionName
                    $params = @{
                        Url = $connInfo.Url
                    }

                    switch ($connInfo.AuthType) {
                        "ClientSecret" {
                            $params.ConnectionType = "ClientSecret"
                            $params.ClientId = $connInfo.ClientId
                            $params.ClientSecret = $connInfo.ClientSecret
                            $params.TenantId = $connInfo.TenantId
                        }
                        "Certificate" {
                            $params.ConnectionType = "Certificate"
                            $params.ClientId = $connInfo.ClientId
                            $params.CertificatePath = $connInfo.CertificatePath
                            if ($connInfo.CertificatePassword) {
                                $securePassword = ConvertTo-SecureString -String $connInfo.CertificatePassword -AsPlainText -Force
                                $params.CertificatePassword = $securePassword
                            }
                            $params.TenantId = $connInfo.TenantId
                        }
                        default {
                            $params.ConnectionType = "Interactive"
                            # Interactive auth doesn't need additional parameters
                        }
                    }

                    return $params
                }
            }

            # If we didn't find a matching connection, return basic parameters
            return @{
                Url            = $SiteUrl
                ConnectionType = "Interactive"
            }
        } catch {
            Write-Error "Error retrieving connection parameters: $_"
            return @{
                Url            = $SiteUrl
                ConnectionType = "Interactive"
            }
        }
    }
}
