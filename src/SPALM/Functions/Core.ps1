# Core functions for the SPALM module

function Connect-SPALMSite {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Interactive", "ClientSecret", "Certificate")]
        [string]$ConnectionType = "Interactive",

        [Parameter(Mandatory = $false)]
        [string]$ConnectionName,

        [Parameter(Mandatory = $false)]
        [PSCredential]$Credentials,

        [Parameter(Mandatory = $false)]
        [string]$ClientId,

        [Parameter(Mandatory = $false)]
        [string]$ClientSecret,

        [Parameter(Mandatory = $false)]
        [string]$CertificatePath,

        [Parameter(Mandatory = $false)]
        [string]$CertificatePassword,

        [Parameter(Mandatory = $false)]
        [string]$TenantId
    )

    process {
        try {
            # Check if we should use a pre-configured connection
            # (from GitHub secrets, environment variables, or private settings)
            if ($ConnectionName) {
                Write-Verbose "Using connection profile: $ConnectionName"

                try {
                    # First check for GitHub secrets and environment variables
                    $githubParams = Get-InternalGitHubSecretParameters -ConnectionName $ConnectionName
                    if ($githubParams) {
                        Write-Verbose "Using GitHub secrets/environment variables for connection"
                        $connectionParams = $githubParams
                    }
                    # If no GitHub secrets found, try private connection settings
                    else {
                        Write-Verbose "No GitHub secrets found, checking for private connection settings"
                        $connectionParams = Get-InternalConnectParameters -SiteUrl $Url -ConnectionName $ConnectionName
                    }

                    # Override the URL and connection parameters
                    $Url = $connectionParams.Url
                    if ($connectionParams.ConnectionType) { $ConnectionType = $connectionParams.ConnectionType }
                    if ($connectionParams.ClientId) { $ClientId = $connectionParams.ClientId }
                    if ($connectionParams.ClientSecret) { $ClientSecret = $connectionParams.ClientSecret }
                    if ($connectionParams.CertificatePath) { $CertificatePath = $connectionParams.CertificatePath }
                    if ($connectionParams.CertificatePassword) { $CertificatePassword = $connectionParams.CertificatePassword }
                    if ($connectionParams.TenantId) { $TenantId = $connectionParams.TenantId }
                } catch {
                    Write-Warning "Error retrieving connection parameters for '$ConnectionName': $_"
                    # Continue with the parameters provided directly to the function
                }
            }

            Write-Verbose "Connecting to SharePoint site: $Url using $ConnectionType authentication"            # Check if we should use the default PnP ClientId (unless specified directly)
            $useDefaultClientId = (Use-InternalPnPDefaultClientId) -and (-not $ClientId)

            switch ($ConnectionType) {
                "Interactive" {
                    if ($useDefaultClientId) {
                        Write-Verbose "Using PnP PowerShell default ClientId for interactive auth"
                        Connect-PnPOnline -Url $Url -Interactive -UseDefaultClientId
                    } else {
                        Connect-PnPOnline -Url $Url -Interactive
                    }
                }
                "ClientSecret" {
                    if (-not $ClientId -or -not $ClientSecret) {
                        throw "ClientId and ClientSecret are required when using ClientSecret authentication"
                    }
                    if ($TenantId) {
                        Connect-PnPOnline -Url $Url -ClientId $ClientId -ClientSecret $ClientSecret -TenantId $TenantId
                    } else {
                        Connect-PnPOnline -Url $Url -ClientId $ClientId -ClientSecret $ClientSecret
                    }
                }
                "Certificate" {
                    if (-not $ClientId -or -not $CertificatePath) {
                        throw "ClientId and CertificatePath are required when using Certificate authentication"
                    }

                    $certParams = @{
                        Url             = $Url
                        ClientId        = $ClientId
                        CertificatePath = $CertificatePath
                    }

                    if ($CertificatePassword) {
                        $certParams.CertificatePassword = (ConvertTo-SecureString -String $CertificatePassword -AsPlainText -Force)
                    }

                    if ($TenantId) {
                        $certParams.TenantId = $TenantId
                    }

                    Connect-PnPOnline @certParams
                }
            }

            Write-Verbose "Connected to SharePoint site: $Url"
            return $true
        } catch {
            Write-Error "Failed to connect to SharePoint site: $_"
            return $false
        }
    }
}

function Disconnect-SPALMSite {
    [CmdletBinding()]
    param()

    process {
        try {
            Disconnect-PnPOnline
            Write-Verbose "Disconnected from SharePoint site"
            return $true
        } catch {
            Write-Error "Failed to disconnect from SharePoint site: $_"
            return $false
        }
    }
}

function Get-SPALMConfiguration {
    [CmdletBinding()]
    param()

    process {
        return $script:SPALMConfig
    }
}

function Set-SPALMConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Configuration
    )

    process {
        $script:SPALMConfig = $Configuration
        $configPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "../config/settings.json"
        $Configuration | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Force
        Write-Verbose "Configuration saved to $configPath"
        return $true
    }
}

function Merge-Hashtable {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object[]]$InputObject
    )

    begin {
        $result = @{}
    }

    process {
        if ($null -ne $InputObject) {
            foreach ($item in $InputObject) {
                if ($null -ne $item -and $item.Keys.Count -gt 0) {
                    foreach ($key in $item.Keys) {
                        $result[$key] = $item[$key]
                    }
                }
            }
        }
    }

    end {
        return $result
    }
}
