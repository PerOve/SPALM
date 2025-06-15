# SPALM - SharePoint ALM Tool Documentation

## Table of Contents

1. [Overview](#overview)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Core Modules](#core-modules)
5. [Usage Examples](#usage-examples)
6. [CI/CD Pipeline](#cicd-pipeline)
7. [Docker Container](#docker-container)
8. [Troubleshooting](#troubleshooting)

## Overview

SPALM (SharePoint ALM Tool) is designed to facilitate the application lifecycle management (ALM) of SharePoint Online sites. It provides functionality for comparing, provisioning, migrating, and cleaning up SharePoint artifacts across multiple environments.

## Installation

### Prerequisites

- PowerShell 7.0 or higher
- PnP.PowerShell module

### Steps

1. Clone the repository:

```powershell
git clone https://github.com/yourusername/SPALM.git
cd SPALM
```

2. Install required PowerShell modules:

```powershell
Install-Module -Name PnP.PowerShell -Scope CurrentUser
Install-Module -Name Pester -Scope CurrentUser -SkipPublisherCheck
```

3. Import SPALM module:

```powershell
Import-Module ./src/SPALM/SPALM.psm1 -Force
```

## Configuration

SPALM uses a configuration file located at `config/settings.json`. This file contains settings for:

- Environment details
- Site URLs
- Authentication settings
- Logging configuration
- Comparison options
- Migration options
- Pipeline environments

Example configuration:

```json
{
  "Environment": {
    "Name": "Development",
    "TenantUrl": "https://contoso.sharepoint.com"
  },
  "Sites": {
    "Source": {
      "Url": "https://contoso.sharepoint.com/sites/source",
      "Authentication": {
        "Type": "Interactive"
      }
    },
    "Target": {
      "Url": "https://contoso.sharepoint.com/sites/target",
      "Authentication": {
        "Type": "Interactive"
      }
    }
  },
  "Logging": {
    "Level": "Information",
    "FilePath": "logs/spalm.log",
    "EnableConsole": true
  },
  "Comparison": {
    "IncludeFields": true,
    "IncludeContentTypes": true,
    "IncludeLists": true,
    "IncludeViews": true,
    "ExportReport": true,
    "ExportPath": "reports"
  },
  "Migration": {
    "CreateChangeLog": true,
    "BackupBeforeChanges": true,
    "BackupPath": "backups",
    "ApplyChanges": false,
    "RemoveItemsNotInSource": false
  },
  "Pipeline": {
    "Environments": ["DEV", "TEST", "PROD"],
    "DevSiteUrl": "https://contoso.sharepoint.com/sites/dev",
    "TestSiteUrl": "https://contoso.sharepoint.com/sites/test",
    "ProdSiteUrl": "https://contoso.sharepoint.com/sites/prod"
  }
}
```

## Core Modules

### SPALM.Core

The core module provides fundamental functionality for connecting to SharePoint sites and managing configuration.

Key functions:

- `Connect-SPALMSite`: Connect to a SharePoint site
- `Disconnect-SPALMSite`: Disconnect from a SharePoint site
- `Get-SPALMConfiguration`: Get the current configuration
- `Set-SPALMConfiguration`: Set the configuration

### SPALM.Comparison

The comparison module provides functionality to compare SharePoint artifacts between sites.

Key functions:

- `Compare-SPALMSite`: Compare two SharePoint sites
- `Compare-SPALMSiteColumns`: Compare site columns
- `Compare-SPALMContentTypes`: Compare content types
- `Compare-SPALMLists`: Compare lists
- `Compare-SPALMListViews`: Compare list views
- `Export-SPALMComparisonReport`: Export a comparison report

### SPALM.Provisioning

The provisioning module provides functionality to create new SharePoint sites based on existing ones.

Key functions:

- `New-SPALMSiteFromSource`: Create a new site based on a source site
- `Copy-SPALMSiteStructure`: Copy site structure to a new site

### SPALM.Migration

The migration module provides functionality to apply changes from a source site to a target site.

Key functions:

- `Invoke-SPALMSiteMigration`: Apply changes from source to target site
- `Get-SPALMMigrationPlan`: Generate a migration plan
- `Backup-SPALMSiteArtifacts`: Backup site artifacts before migration

### SPALM.Cleanup

The cleanup module provides functionality to remove items from a target site that don't exist in the source.

Key functions:

- `Invoke-SPALMCleanup`: Remove items from target not in source
- `Get-SPALMCleanupPlan`: Generate a cleanup plan

## Usage Examples

### Compare Two Sites

```powershell
Import-Module ./src/SPALM/SPALM.psm1
$comparison = Compare-SPALMSite -SourceSite "https://contoso.sharepoint.com/sites/source" -TargetSite "https://contoso.sharepoint.com/sites/target" -IncludeColumns -IncludeContentTypes -IncludeLists -IncludeViews -ExportReport -ReportPath "./comparison_report.json"
```

### Apply Changes from Source to Target

```powershell
Import-Module ./src/SPALM/SPALM.psm1
Invoke-SPALMSiteMigration -SourceSite "https://contoso.sharepoint.com/sites/source" -TargetSite "https://contoso.sharepoint.com/sites/target" -BackupBeforeChanges -BackupPath "./backups"
```

### Create a New Development Site from Production

```powershell
Import-Module ./src/SPALM/SPALM.psm1
New-SPALMSiteFromSource -SourceSite "https://contoso.sharepoint.com/sites/prod" -NewSiteUrl "https://contoso.sharepoint.com/sites/dev" -NewSiteTitle "Development Site"
```

### Clean Up a Target Site

```powershell
Import-Module ./src/SPALM/SPALM.psm1
Invoke-SPALMCleanup -SourceSite "https://contoso.sharepoint.com/sites/source" -TargetSite "https://contoso.sharepoint.com/sites/target" -BackupBeforeChanges -BackupPath "./backups" -WhatIf
```

## CI/CD Pipeline

SPALM includes an Azure DevOps pipeline definition (`src/pipelines/azure-pipelines.yml`) that implements a full DEV-TEST-PROD workflow.

The pipeline includes the following stages:

1. **Build**: Build the SPALM modules and scripts
2. **Test**: Run Pester tests to validate the modules
3. **Deploy_DEV**: Deploy to the DEV environment
4. **Deploy_TEST**: Deploy to the TEST environment
5. **Deploy_PROD**: Deploy to the PROD environment

### Pipeline Variables

The pipeline requires the following variables to be defined in Azure DevOps:

- `TestSiteUrl`: URL of the test site
- `TestUsername`: Username for the test site
- `TestPassword`: Password for the test site
- `DevSiteUrl`: URL of the DEV site
- `DevClientId`: Client ID for the DEV site
- `DevClientSecret`: Client secret for the DEV site
- `TestSiteUrl`: URL of the TEST site
- `TestClientId`: Client ID for the TEST site
- `TestClientSecret`: Client secret for the TEST site
- `ProdSiteUrl`: URL of the PROD site
- `ProdClientId`: Client ID for the PROD site
- `ProdClientSecret`: Client secret for the PROD site

## Docker Container

SPALM includes a Docker container definition for testing the scripts in an isolated environment. The container includes PowerShell 7 and the required PnP.PowerShell module.

### Building the Container

```
cd src/docker
docker build -t spalm-test -f Dockerfile .
```

### Running the Container

```
docker run -it spalm-test
```

## Troubleshooting

### Common Issues

#### PnP.PowerShell Not Found

If you encounter an error that PnP.PowerShell is not found, make sure you have installed it:

```powershell
Install-Module -Name PnP.PowerShell -Scope CurrentUser
```

#### Authentication Issues

If you have problems authenticating to SharePoint, try using the Interactive authentication type:

```powershell
Connect-SPALMSite -Url "https://contoso.sharepoint.com/sites/dev" -ConnectionType "Interactive"
```

#### Module Import Errors

If you have problems importing the SPALM modules, make sure you are using the correct paths:

```powershell
Import-Module ./src/SPALM/SPALM.psm1 -Force
```

### Logging

SPALM uses PowerShell's built-in logging capabilities. To enable verbose logging:

```powershell
$VerbosePreference = "Continue"
```

To enable debug logging:

```powershell
$DebugPreference = "Continue"
```
