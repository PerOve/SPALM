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
        [PSCredential]$Credentials,

        [Parameter(Mandatory = $false)]
        [string]$ClientId,

        [Parameter(Mandatory = $false)]
        [string]$ClientSecret,

        [Parameter(Mandatory = $false)]
        [string]$CertificatePath,

        [Parameter(Mandatory = $false)]
        [string]$CertificatePassword
    )

    process {
        try {
            switch ($ConnectionType) {
                "Interactive" {
                    Connect-PnPOnline -Url $Url -Interactive
                }
                "ClientSecret" {
                    if (-not $ClientId -or -not $ClientSecret) {
                        throw "ClientId and ClientSecret are required when using ClientSecret authentication"
                    }
                    Connect-PnPOnline -Url $Url -ClientId $ClientId -ClientSecret $ClientSecret
                }
                "Certificate" {
                    if (-not $ClientId -or -not $CertificatePath) {
                        throw "ClientId and CertificatePath are required when using Certificate authentication"
                    }
                    if ($CertificatePassword) {
                        Connect-PnPOnline -Url $Url -ClientId $ClientId -CertificatePath $CertificatePath -CertificatePassword (ConvertTo-SecureString -String $CertificatePassword -AsPlainText -Force)
                    } else {
                        Connect-PnPOnline -Url $Url -ClientId $ClientId -CertificatePath $CertificatePath
                    }
                }
            }

            Write-Verbose "Connected to SharePoint site: $Url"
            return $true
        }
        catch {
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
        }
        catch {
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
