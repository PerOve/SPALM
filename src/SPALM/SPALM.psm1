# SPALM.psm1
# SharePoint ALM toolkit for managing site columns, content types, lists and views across environments

# Import all internal functions first (as public functions may depend on them)
$internalPath = Join-Path -Path $PSScriptRoot -ChildPath 'Internal'
if (Test-Path -Path $internalPath) {
    # Import ConnectionHelpers first, then GitHubSecretHelpers, then the rest
    $priorityFiles = @(
        "ConnectionHelpers.ps1",
        "GitHubSecretHelpers.ps1"
    )

    # Import priority files first in specific order
    foreach ($fileName in $priorityFiles) {
        $filePath = Join-Path -Path $internalPath -ChildPath $fileName
        if (Test-Path -Path $filePath) {
            Write-Verbose "Importing internal module: $filePath"
            . $filePath
        }
    }

    # Import all other internal files
    foreach ($function in (Get-ChildItem -Path "$internalPath\*.ps1")) {
        if ($priorityFiles -notcontains $function.Name) {
            Write-Verbose "Importing internal module: $($function.FullName)"
            . $function.FullName
        }
    }
}

# Import all function files
$functionPath = Join-Path -Path $PSScriptRoot -ChildPath 'Functions'
if (Test-Path -Path $functionPath) {
    foreach ($function in (Get-ChildItem -Path "$functionPath\*.ps1")) {
        Write-Verbose "Importing function module: $($function.FullName)"
        . $function.FullName
    }
}

# Initialize the module
function Initialize-SPALM {
    [CmdletBinding()]
    param()

    process {
        try {
            # Check if PnP.PowerShell is available
            if (-not (Get-Module -Name PnP.PowerShell -ListAvailable)) {
                Write-Error "PnP.PowerShell module is not installed. Please install it with: Install-Module -Name PnP.PowerShell -Scope CurrentUser"
                return $false
            }            # Load configuration - check for private config first, then fall back to shared config
            $privateConfigPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "..\config\private\sites.private.json"
            $sharedConfigPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "..\config\settings.json"
            $templateConfigPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "..\config\sites.template.json"

            if (Test-Path -Path $privateConfigPath) {
                Write-Verbose "Loading private configuration from $privateConfigPath"
                $script:SPALMConfig = Get-Content -Path $privateConfigPath -Raw | ConvertFrom-Json
                $script:UsingPrivateConfig = $true
            } elseif (Test-Path -Path $sharedConfigPath) {
                Write-Verbose "Loading shared configuration from $sharedConfigPath"
                $script:SPALMConfig = Get-Content -Path $sharedConfigPath -Raw | ConvertFrom-Json
                $script:UsingPrivateConfig = $false
            } elseif (Test-Path -Path $templateConfigPath) {
                Write-Verbose "Loading template configuration from $templateConfigPath"
                $script:SPALMConfig = Get-Content -Path $templateConfigPath -Raw | ConvertFrom-Json
                $script:UsingPrivateConfig = $false
            } else {
                Write-Verbose "No configuration file found, using default configuration"
                $script:SPALMConfig = [PSCustomObject]@{
                    Environment = @{
                        Name      = "Development"
                        TenantUrl = ""
                    }
                    Sites       = @{
                        Source = @{
                            Url            = ""
                            Authentication = @{
                                Type = "Interactive"
                            }
                        }
                        Target = @{
                            Url            = ""
                            Authentication = @{
                                Type = "Interactive"
                            }
                        }
                    }
                    Logging     = @{
                        Level         = "Information"
                        FilePath      = "logs/spalm.log"
                        EnableConsole = $true
                    }
                }
            }

            Write-Verbose "SPALM module initialized successfully"
            return $true
        } catch {
            Write-Error "Failed to initialize SPALM module: $_"
            return $false
        }
    }
}

# Initialize the module when imported
$null = Initialize-SPALM
