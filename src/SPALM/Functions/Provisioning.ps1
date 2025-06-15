# Provisioning functions for the SPALM module

function New-SPALMSiteFromSource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceSite,

        [Parameter(Mandatory = $true)]
        [string]$NewSiteUrl,

        [Parameter(Mandatory = $true)]
        [string]$NewSiteTitle,

        [Parameter(Mandatory = $false)]
        [string]$NewSiteDescription = "",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeContentTypes,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeLists,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeViews
    )

    process {
        try {
            # Connect to source site
            Write-Verbose "Connecting to source site: $SourceSite"
            $sourceConnection = Connect-SPALMSite -Url $SourceSite

            if (-not $sourceConnection) {
                throw "Failed to connect to source site"
            }

            # Get source site data
            Write-Verbose "Getting source site data"
            $sourceData = Get-SPALMSiteData

            # Disconnect from source site
            Disconnect-SPALMSite

            # Check if new site exists
            Write-Verbose "Checking if new site exists: $NewSiteUrl"
            try {
                $newSiteConnection = Connect-SPALMSite -Url $NewSiteUrl

                if ($newSiteConnection) {
                    Write-Verbose "Site already exists, will use existing site"
                    Disconnect-SPALMSite
                }
            }
            catch {
                # Site doesn't exist, create it
                Write-Verbose "Site doesn't exist, creating new site"
                $tenantUrl = ($NewSiteUrl -split "/sites/|/teams/")[0]
                $siteName = ($NewSiteUrl -split "/sites/|/teams/")[1]

                Connect-SPALMSite -Url "$tenantUrl/sites" #Connect to tenant admin

                # Create the new site
                New-PnPSite -Type TeamSite -Title $NewSiteTitle -Url $NewSiteUrl -Description $NewSiteDescription

                Disconnect-SPALMSite
            }

            # Connect to the new site
            Write-Verbose "Connecting to new site: $NewSiteUrl"
            $newSiteConnection = Connect-SPALMSite -Url $NewSiteUrl

            if (-not $newSiteConnection) {
                throw "Failed to connect to new site"
            }

            # Copy site structure
            Write-Verbose "Copying site structure"
            Copy-SPALMSiteStructure -SourceData $sourceData -IncludeContentTypes:$IncludeContentTypes -IncludeLists:$IncludeLists -IncludeViews:$IncludeViews

            # Disconnect from new site
            Disconnect-SPALMSite

            Write-Verbose "Site provisioning completed successfully"
            return $true
        }
        catch {
            Write-Error "Error provisioning site: $_"
            return $false
        }
    }
}

function Copy-SPALMSiteStructure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$SourceData,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeContentTypes,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeLists,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeViews
    )

    process {
        try {
            # Create site columns
            Write-Verbose "Creating site columns"
            foreach ($column in $SourceData.Columns) {
                # Skip built-in columns
                if ($column.InternalName.StartsWith("_") -or $column.Group -eq "Core Document Columns" -or $column.Group -eq "Core Task and Issue Columns") {
                    continue
                }

                # Create column
                try {
                    $fieldXml = $column.SchemaXml
                    Add-PnPFieldFromXml -FieldXml $fieldXml
                    Write-Verbose "Created column: $($column.Title)"
                }
                catch {
                    Write-Warning "Failed to create column $($column.Title): $_"
                }
            }

            # Create content types if requested
            if ($IncludeContentTypes) {
                Write-Verbose "Creating content types"
                foreach ($contentType in $SourceData.ContentTypes) {
                    # Skip built-in content types
                    if ($contentType.Name.StartsWith("System") -or $contentType.Group -eq "" -or $null -eq $contentType.Group) {
                        continue
                    }

                    # Create content type
                    try {
                        $newContentType = Add-PnPContentType -Name $contentType.Name -Description $contentType.Description -Group $contentType.Group

                        # Add fields to content type
                        $contentTypeFields = Get-PnPContentTypeField -ContentType $contentType.Name
                        foreach ($field in $contentTypeFields) {
                            # Skip built-in fields
                            if ($field.InternalName.StartsWith("_")) {
                                continue
                            }

                            try {
                                Add-PnPFieldToContentType -Field $field.InternalName -ContentType $newContentType.Name
                                Write-Verbose "Added field $($field.Title) to content type $($contentType.Name)"
                            }
                            catch {
                                Write-Warning "Failed to add field $($field.Title) to content type $($contentType.Name): $_"
                            }
                        }

                        Write-Verbose "Created content type: $($contentType.Name)"
                    }
                    catch {
                        Write-Warning "Failed to create content type $($contentType.Name): $_"
                    }
                }
            }

            # Create lists if requested
            if ($IncludeLists) {
                Write-Verbose "Creating lists"
                foreach ($list in $SourceData.Lists) {
                    # Skip hidden lists
                    if ($list.Hidden) {
                        continue
                    }

                    # Create list
                    try {
                        $newList = New-PnPList -Title $list.Title -Template $list.BaseTemplate -EnableVersioning:$list.EnableVersioning -OnQuickLaunch:$list.OnQuickLaunch

                        if ($list.Description) {
                            Set-PnPList -Identity $newList -Description $list.Description
                        }

                        if ($list.EnableMinorVersions) {
                            Set-PnPList -Identity $newList -EnableMinorVersions $list.EnableMinorVersions
                        }

                        # Add content types to list if requested
                        if ($IncludeContentTypes) {
                            # Get content types for list
                            $listContentTypes = Get-PnPContentType -List $list

                            # Enable content types
                            Set-PnPList -Identity $newList -EnableContentTypes $true

                            # Add content types to list
                            foreach ($contentType in $listContentTypes) {
                                # Skip built-in content types
                                if ($contentType.Name.StartsWith("System") -or $contentType.Group -eq "" -or $null -eq $contentType.Group) {
                                    continue
                                }

                                try {
                                    Add-PnPContentTypeToList -List $newList -ContentType $contentType.Name
                                    Write-Verbose "Added content type $($contentType.Name) to list $($list.Title)"
                                }
                                catch {
                                    Write-Warning "Failed to add content type $($contentType.Name) to list $($list.Title): $_"
                                }
                            }
                        }

                        # Add custom fields to list
                        $listFields = Get-PnPField -List $list
                        foreach ($field in $listFields) {
                            # Skip built-in fields
                            if ($field.InternalName.StartsWith("_") -or $field.InternalName -eq "Title" -or $field.Group -eq "" -or $null -eq $field.Group) {
                                continue
                            }

                            try {
                                Add-PnPFieldToList -List $newList -Field $field.InternalName
                                Write-Verbose "Added field $($field.Title) to list $($list.Title)"
                            }
                            catch {
                                Write-Warning "Failed to add field $($field.Title) to list $($list.Title): $_"
                            }
                        }

                        # Create views if requested
                        if ($IncludeViews) {
                            # Get views for list
                            $listViews = $list.Views

                            foreach ($view in $listViews) {
                                # Skip default view
                                if ($view.Title -eq "All Items") {
                                    continue
                                }

                                try {
                                    $viewFields = $view.ViewFields | ForEach-Object { $_ }

                                    Add-PnPView -List $newList -Title $view.Title -Fields $viewFields -ViewQuery $view.ViewQuery -RowLimit $view.RowLimit -SetAsDefault:$view.DefaultView
                                    Write-Verbose "Created view $($view.Title) in list $($list.Title)"
                                }
                                catch {
                                    Write-Warning "Failed to create view $($view.Title) in list $($list.Title): $_"
                                }
                            }
                        }

                        Write-Verbose "Created list: $($list.Title)"
                    }
                    catch {
                        Write-Warning "Failed to create list $($list.Title): $_"
                    }
                }
            }

            Write-Verbose "Site structure copied successfully"
            return $true
        }
        catch {
            Write-Error "Error copying site structure: $_"
            return $false
        }
    }
}
