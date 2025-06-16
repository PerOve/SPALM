<#
.SYNOPSIS
    Test runner script for SPALM module tests
.DESCRIPTION
    This script runs all Pester tests for the SPALM module, including the
    new tests for GitHub secrets functionality.
#>

# Set the module path
$modulePath = "$PSScriptRoot\..\src\SPALM\SPALM.psm1"

# Check if the module exists
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module not found at: $modulePath"
    exit 1
}

# Import the module
Import-Module $modulePath -Force

# Check if Pester is installed
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Installing Pester module..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Import Pester
Import-Module Pester

# Run all tests
$testResults = Invoke-Pester -Path "$PSScriptRoot\..\src\tests" -OutputFormat NUnitXml -OutputFile "$PSScriptRoot\..\test-results.xml" -PassThru

# Report results
Write-Host "Tests Passed: $($testResults.PassedCount) of $($testResults.TotalCount) tests"

if ($testResults.FailedCount -gt 0) {
    Write-Host "Failed Tests:" -ForegroundColor Red
    foreach ($failure in $testResults.Failed) {
        Write-Host "- $($failure.Name): $($failure.ErrorRecord)" -ForegroundColor Red
    }
    exit 1
}

exit 0
