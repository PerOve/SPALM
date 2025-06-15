# Base image with PowerShell 7
FROM mcr.microsoft.com/powershell:7.3-ubuntu-22.04

# Set working directory
WORKDIR /app

# Install necessary packages
RUN apt-get update && \
    apt-get install -y curl git wget unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install PnP.PowerShell module
RUN pwsh -Command "Install-Module -Name PnP.PowerShell -Force -Scope AllUsers"

# Copy SPALM modules and scripts
COPY ../modules /app/modules
COPY ../scripts /app/scripts
COPY ../functions /app/functions
COPY ../tests /app/tests

# Create config directory and default configuration
RUN mkdir -p /app/config

# Add script to import all modules
RUN echo '#!/usr/bin/pwsh\n\
Import-Module ./modules/SPALM.Core/SPALM.Core.psm1 -Force\n\
Import-Module ./modules/SPALM.Comparison/SPALM.Comparison.psm1 -Force\n\
Import-Module ./modules/SPALM.Provisioning/SPALM.Provisioning.psm1 -Force\n\
Import-Module ./modules/SPALM.Migration/SPALM.Migration.psm1 -Force\n\
Import-Module ./modules/SPALM.Cleanup/SPALM.Cleanup.psm1 -Force\n\
Import-Module ./modules/SPALM.Pipeline/SPALM.Pipeline.psm1 -Force\n\
Write-Host "SPALM modules loaded successfully. Type Get-Command -Module SPALM.* to see available commands."\n\
' > /app/import-modules.ps1 && chmod +x /app/import-modules.ps1

# Add entrypoint script
RUN echo '#!/usr/bin/pwsh\n\
Write-Host "Welcome to SPALM Testing Environment"\n\
Write-Host "Loading SPALM modules..."\n\
./import-modules.ps1\n\
$Host.UI.RawUI.WindowTitle = "SPALM PowerShell Environment"\n\
' > /app/entrypoint.ps1 && chmod +x /app/entrypoint.ps1

# Set entrypoint
ENTRYPOINT ["pwsh", "-File", "/app/entrypoint.ps1"]
