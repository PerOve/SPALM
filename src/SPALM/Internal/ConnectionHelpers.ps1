# Internal helper functions for the SPALM module

function Get-InternalPrivateConnections {
    [CmdletBinding()]
    param()

    process {
        try {
            $privateConnectionsPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "..\config\private\connections.private.json"
            if (Test-Path -Path $privateConnectionsPath) {
                $connections = Get-Content -Path $privateConnectionsPath -Raw | ConvertFrom-Json
                return $connections
            }
            return $null
        } catch {
            Write-Verbose "No private connections found: $_"
            return $null
        }
    }
}

function Get-InternalConnectParameters {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SiteUrl,

        [Parameter(Mandatory = $false)]
        [string]$ConnectionName
    )

    process {
        try {
            # Try to find in private connections first
            $privateConnections = Get-InternalPrivateConnections

            if ($privateConnections -and $ConnectionName) {
                if ($privateConnections.$ConnectionName) {
                    $connInfo = $privateConnections.$ConnectionName
                    $params = @{
                        Url = $connInfo.Url
                    }

                    switch ($connInfo.AuthType) {
                        "ClientSecret" {
                            $params.ClientId = $connInfo.ClientId
                            $params.ClientSecret = $connInfo.ClientSecret
                            $params.TenantId = $connInfo.TenantId
                        }
                        "Certificate" {
                            $params.ClientId = $connInfo.ClientId
                            $params.CertificatePath = $connInfo.CertificatePath
                            if ($connInfo.CertificatePassword) {
                                $securePassword = ConvertTo-SecureString -String $connInfo.CertificatePassword -AsPlainText -Force
                                $params.CertificatePassword = $securePassword
                            }
                            $params.TenantId = $connInfo.TenantId
                        }
                        default {
                            # Interactive auth doesn't need additional parameters
                        }
                    }

                    return $params
                }
            }

            # If we didn't find a matching private connection, return basic parameters
            return @{
                Url = $SiteUrl
            }
        } catch {
            Write-Error "Error retrieving connection parameters: $_"
            return @{
                Url = $SiteUrl
            }
        }
    }
}
