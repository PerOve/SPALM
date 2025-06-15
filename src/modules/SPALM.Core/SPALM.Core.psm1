# SPALM.Core.psm1
# Core module for SharePoint ALM toolkit

# Import functions
$functionPath = Join-Path -Path $PSScriptRoot -ChildPath 'functions'
if (Test-Path -Path $functionPath) {
    foreach ($function in (Get-ChildItem -Path "$functionPath\*.ps1")) {
        . $function.FullName
    }
}

# Import internal functions
$internalPath = Join-Path -Path $PSScriptRoot -ChildPath 'internal'
if (Test-Path -Path $internalPath) {
    foreach ($function in (Get-ChildItem -Path "$internalPath\*.ps1")) {
        . $function.FullName
    }
}

# Check if PnP.PowerShell is available
function Test-PnPAvailability {
    $pnpModule = Get-Module -Name PnP.PowerShell -ListAvailable
    if (-not $pnpModule) {
        Write-Error "PnP.PowerShell module is not installed. Please install it with: Install-Module -Name PnP.PowerShell -Scope CurrentUser"
        return $false
    }
    return $true
}

# Initialize module
function Initialize-SPALMCore {
    if (-not (Test-PnPAvailability)) {
        return $false
    }

    # Load configuration
    $configPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "..\..\config\settings.json"
    if (Test-Path -Path $configPath) {
        $script:SPALMConfig = Get-Content -Path $configPath -Raw | ConvertFrom-Json
    } else {
        $script:SPALMConfig = [PSCustomObject]@{
            DefaultTenantUrl = ""
            DefaultCredentialType = "Interactive"
            LogLevel = "Info"
        }
    }

    return $true
}

# Connection Functions
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

    begin {
        if (-not (Initialize-SPALMCore)) {
            return $false
        }
    }

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
        $configPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "..\..\config\settings.json"
        $Configuration | ConvertTo-Json | Out-File -FilePath $configPath -Force
        Write-Verbose "Configuration saved to $configPath"
        return $true
    }
}

# Run initialization
Initialize-SPALMCore > $null
