# SPALM - SharePoint ALM Tool

A comprehensive Application Lifecycle Management (ALM) tool for SharePoint Online sites using PowerShell and PnP.PowerShell.

## Overview

SPALM is designed to assist in managing the lifecycle of SharePoint Online sites through a DEV-TEST-PROD pipeline. It provides functionality to compare, provision, migrate, and clean up SharePoint artifacts including site columns, content types, lists, and list views.

## Features

- **Site Comparison**: Compare site columns, content types, lists, and list views between source and target SharePoint sites
- **Provisioning**: Create new sites based on existing configurations
- **Migration**: Apply changes from source to target sites
- **Cleanup**: Remove items from target sites that don't exist in source
- **CI/CD Pipeline Integration**: Azure DevOps YAML pipelines for automation
- **Docker Support**: Testing environment using Docker/Podman

## Project Structure

```
SPALM/
├── src/                    # Source code
│   ├── modules/            # PowerShell modules
│   │   ├── SPALM.Core/     # Core functionality
│   │   ├── SPALM.Comparison/  # Site comparison
│   │   ├── SPALM.Provisioning/ # Site provisioning
│   │   ├── SPALM.Migration/ # Change application
│   │   ├── SPALM.Cleanup/   # Cleanup functionality
│   │   └── SPALM.Pipeline/  # CI/CD integration
│   ├── scripts/            # PowerShell scripts
│   ├── functions/          # PowerShell functions
│   ├── tests/              # Pester tests
│   ├── docker/             # Docker container files
│   ├── pipelines/          # Azure DevOps YAML files
│   └── templates/          # Template files
├── build/                  # Build outputs
├── config/                 # Configuration files
├── docs/                   # Documentation
└── .vscode/                # VS Code settings
```

## Requirements

- PowerShell 7+
- PnP.PowerShell module
- Azure DevOps (for CI/CD pipelines)
- Docker or Podman (for testing)

## Installation

1. Clone this repository
2. Install required PowerShell modules:

```powershell
Install-Module -Name PnP.PowerShell -Scope CurrentUser
```

3. Configure connection settings in config/settings.json

## Usage

### Site Comparison

```powershell
Import-Module ./src/SPALM/SPALM.psm1
Compare-SPALMSite -SourceSite "https://tenant.sharepoint.com/sites/source" -TargetSite "https://tenant.sharepoint.com/sites/target"
```

### Apply Changes

```powershell
Import-Module ./src/SPALM/SPALM.psm1
Invoke-SPALMSiteMigration -SourceSite "https://tenant.sharepoint.com/sites/source" -TargetSite "https://tenant.sharepoint.com/sites/target"
```

### Create New Site from Existing

```powershell
Import-Module ./src/SPALM/SPALM.psm1
New-SPALMSiteFromSource -SourceSite "https://tenant.sharepoint.com/sites/prod" -NewSiteName "dev"
```

## CI/CD Pipeline

The repository includes ready-to-use Azure DevOps pipeline definitions for implementing a full DEV-TEST-PROD workflow. See `src/pipelines/` for details.

## Development

### Testing with Docker

```powershell
cd src/docker
docker build -t spalm-test -f Dockerfile .
docker run -it spalm-test
```

## Contributing

Contributions are welcome! Please read the contribution guidelines before submitting pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
