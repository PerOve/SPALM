# Cleanup functions for the SPALM module

function Invoke-SPALMCleanup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceSite,

        [Parameter(Mandatory = $true)]
        [string]$TargetSite,

        [Parameter(Mandatory = $false)]
        [switch]$BackupBeforeChanges,

        [Parameter(Mandatory = $false)]
        [string]$BackupPath,

        [Parameter(Mandatory = $false)]
        [switch]$RemoveFields,

        [Parameter(Mandatory = $false)]
        [switch]$RemoveContentTypes,

        [Parameter(Mandatory = $false)]
        [switch]$RemoveLists,

        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )

    process {
        try {
            # Get cleanup plan
            Write-Verbose "Getting cleanup plan"
            $cleanupPlan = Get-SPALMCleanupPlan -SourceSite $SourceSite -TargetSite $TargetSite

            if (-not $cleanupPlan) {
                throw "Failed to create cleanup plan"
            }

            # Create backup if requested
            if ($BackupBeforeChanges) {
                Write-Verbose "Creating backup"
                $backupResult = Backup-SPALMSiteArtifacts -SiteUrl $TargetSite -BackupPath $BackupPath

                if (-not $backupResult) {
                    throw "Failed to create backup"
                }
            }

            # Apply cleanup
            if (-not $WhatIf) {
                Write-Verbose "Connecting to target site: $TargetSite"
                $targetConnection = Connect-SPALMSite -Url $TargetSite

                if (-not $targetConnection) {
                    throw "Failed to connect to target site"
                }

                # Remove lists if requested
                if ($RemoveLists) {
                    Write-Verbose "Removing lists"
                    foreach ($list in $cleanupPlan.ListsToRemove) {
                        try {
                            Remove-PnPList -Identity $list.Title -Force
                            Write-Verbose "Removed list: $($list.Title)"
                        }
                        catch {
                            Write-Warning "Failed to remove list $($list.Title): $_"
                        }
                    }
                }

                # Remove content types if requested
                if ($RemoveContentTypes) {
                    Write-Verbose "Removing content types"
                    foreach ($contentType in $cleanupPlan.ContentTypesToRemove) {
                        try {
                            Remove-PnPContentType -Identity $contentType.Name -Force
                            Write-Verbose "Removed content type: $($contentType.Name)"
                        }
                        catch {
                            Write-Warning "Failed to remove content type $($contentType.Name): $_"
                        }
                    }
                }

                # Remove fields if requested
                if ($RemoveFields) {
                    Write-Verbose "Removing fields"
                    foreach ($field in $cleanupPlan.FieldsToRemove) {
                        try {
                            Remove-PnPField -Identity $field.InternalName -Force
                            Write-Verbose "Removed field: $($field.Title)"
                        }
                        catch {
                            Write-Warning "Failed to remove field $($field.Title): $_"
                        }
                    }
                }

                # Disconnect from target site
                Disconnect-SPALMSite

                Write-Verbose "Site cleanup completed successfully"
            }
            else {
                Write-Verbose "WhatIf mode, no changes made"
                Write-Verbose "Cleanup plan:"
                $cleanupPlan | Format-List
            }

            return $true
        }
        catch {
            Write-Error "Error cleaning up site: $_"
            return $false
        }
    }
}

function Get-SPALMCleanupPlan {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceSite,

        [Parameter(Mandatory = $true)]
        [string]$TargetSite
    )

    process {
        try {
            # Compare sites
            Write-Verbose "Comparing sites"
            $comparison = Compare-SPALMSite -SourceSite $SourceSite -TargetSite $TargetSite -IncludeColumns -IncludeContentTypes -IncludeLists -IncludeViews

            if (-not $comparison) {
                throw "Failed to compare sites"
            }

            # Create cleanup plan
            $cleanupPlan = [PSCustomObject]@{
                SourceSite = $SourceSite
                TargetSite = $TargetSite
                FieldsToRemove = @()
                ContentTypesToRemove = @()
                ListsToRemove = @()
            }

            # Connect to target site
            Write-Verbose "Connecting to target site: $TargetSite"
            $targetConnection = Connect-SPALMSite -Url $TargetSite

            if (-not $targetConnection) {
                throw "Failed to connect to target site"
            }

            # Process field cleanup
            Write-Verbose "Processing field cleanup"
            foreach ($column in $comparison.Columns) {
                if ($column.Status -eq "OnlyInTarget") {
                    $targetField = Get-PnPField -Identity $column.InternalName

                    # Skip built-in fields
                    if ($targetField.InternalName.StartsWith("_") -or $targetField.Group -eq "Core Document Columns" -or $targetField.Group -eq "Core Task and Issue Columns") {
                        continue
                    }

                    $cleanupPlan.FieldsToRemove += $targetField
                }
            }

            # Process content type cleanup
            Write-Verbose "Processing content type cleanup"
            foreach ($contentType in $comparison.ContentTypes) {
                if ($contentType.Status -eq "OnlyInTarget") {
                    $targetContentType = Get-PnPContentType -Identity $contentType.Id

                    # Skip built-in content types
                    if ($targetContentType.Name.StartsWith("System") -or $targetContentType.Group -eq "" -or $null -eq $targetContentType.Group) {
                        continue
                    }

                    $cleanupPlan.ContentTypesToRemove += $targetContentType
                }
            }

            # Process list cleanup
            Write-Verbose "Processing list cleanup"
            foreach ($list in $comparison.Lists) {
                if ($list.Status -eq "OnlyInTarget") {
                    $targetList = Get-PnPList -Identity $list.Title

                    # Skip hidden lists
                    if ($targetList.Hidden) {
                        continue
                    }

                    $cleanupPlan.ListsToRemove += $targetList
                }
            }

            # Disconnect from target site
            Disconnect-SPALMSite

            return $cleanupPlan
        }
        catch {
            Write-Error "Error creating cleanup plan: $_"
            return $null
        }
    }
}
