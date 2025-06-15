# Migration functions for the SPALM module

function Invoke-SPALMSiteMigration {
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
        [switch]$WhatIf
    )

    process {
        try {
            # Get migration plan
            Write-Verbose "Getting migration plan"
            $migrationPlan = Get-SPALMMigrationPlan -SourceSite $SourceSite -TargetSite $TargetSite

            if (-not $migrationPlan) {
                throw "Failed to create migration plan"
            }

            # Create backup if requested
            if ($BackupBeforeChanges) {
                Write-Verbose "Creating backup"
                $backupResult = Backup-SPALMSiteArtifacts -SiteUrl $TargetSite -BackupPath $BackupPath

                if (-not $backupResult) {
                    throw "Failed to create backup"
                }
            }

            # Apply changes
            if (-not $WhatIf) {
                Write-Verbose "Connecting to target site: $TargetSite"
                $targetConnection = Connect-SPALMSite -Url $TargetSite

                if (-not $targetConnection) {
                    throw "Failed to connect to target site"
                }

                # Apply column changes
                Write-Verbose "Applying column changes"
                foreach ($column in $migrationPlan.Columns) {
                    switch ($column.Action) {
                        "Add" {
                            try {
                                Add-PnPFieldFromXml -FieldXml $column.SchemaXml
                                Write-Verbose "Added column: $($column.Title)"
                            }
                            catch {
                                Write-Warning "Failed to add column $($column.Title): $_"
                            }
                            break
                        }
                        "Update" {
                            try {
                                Set-PnPField -Identity $column.InternalName -Values @{
                                    Title = $column.Title
                                    Description = $column.Description
                                    Required = $column.Required
                                    Group = $column.Group
                                }
                                Write-Verbose "Updated column: $($column.Title)"
                            }
                            catch {
                                Write-Warning "Failed to update column $($column.Title): $_"
                            }
                            break
                        }
                        "Delete" {
                            try {
                                Remove-PnPField -Identity $column.InternalName -Force
                                Write-Verbose "Deleted column: $($column.Title)"
                            }
                            catch {
                                Write-Warning "Failed to delete column $($column.Title): $_"
                            }
                            break
                        }
                    }
                }

                # Apply content type changes
                Write-Verbose "Applying content type changes"
                foreach ($contentType in $migrationPlan.ContentTypes) {
                    switch ($contentType.Action) {
                        "Add" {
                            try {
                                $newContentType = Add-PnPContentType -Name $contentType.Name -Description $contentType.Description -Group $contentType.Group

                                # Add fields to content type
                                foreach ($field in $contentType.Fields) {
                                    try {
                                        Add-PnPFieldToContentType -Field $field.InternalName -ContentType $newContentType.Name
                                        Write-Verbose "Added field $($field.Title) to content type $($contentType.Name)"
                                    }
                                    catch {
                                        Write-Warning "Failed to add field $($field.Title) to content type $($contentType.Name): $_"
                                    }
                                }

                                Write-Verbose "Added content type: $($contentType.Name)"
                            }
                            catch {
                                Write-Warning "Failed to add content type $($contentType.Name): $_"
                            }
                            break
                        }
                        "Update" {
                            try {
                                Set-PnPContentType -Identity $contentType.Id -Name $contentType.Name -Description $contentType.Description -Group $contentType.Group

                                # Update field links
                                foreach ($field in $contentType.FieldsToAdd) {
                                    try {
                                        Add-PnPFieldToContentType -Field $field.InternalName -ContentType $contentType.Name
                                        Write-Verbose "Added field $($field.Title) to content type $($contentType.Name)"
                                    }
                                    catch {
                                        Write-Warning "Failed to add field $($field.Title) to content type $($contentType.Name): $_"
                                    }
                                }

                                foreach ($field in $contentType.FieldsToRemove) {
                                    try {
                                        Remove-PnPFieldFromContentType -Field $field.InternalName -ContentType $contentType.Name
                                        Write-Verbose "Removed field $($field.Title) from content type $($contentType.Name)"
                                    }
                                    catch {
                                        Write-Warning "Failed to remove field $($field.Title) from content type $($contentType.Name): $_"
                                    }
                                }

                                Write-Verbose "Updated content type: $($contentType.Name)"
                            }
                            catch {
                                Write-Warning "Failed to update content type $($contentType.Name): $_"
                            }
                            break
                        }
                        "Delete" {
                            try {
                                Remove-PnPContentType -Identity $contentType.Name -Force
                                Write-Verbose "Deleted content type: $($contentType.Name)"
                            }
                            catch {
                                Write-Warning "Failed to delete content type $($contentType.Name): $_"
                            }
                            break
                        }
                    }
                }

                # Apply list changes
                Write-Verbose "Applying list changes"
                foreach ($list in $migrationPlan.Lists) {
                    switch ($list.Action) {
                        "Add" {
                            try {
                                $newList = New-PnPList -Title $list.Title -Template $list.TemplateType -EnableVersioning:$list.EnableVersioning -OnQuickLaunch:$list.OnQuickLaunch

                                if ($list.Description) {
                                    Set-PnPList -Identity $newList -Description $list.Description
                                }

                                if ($list.EnableMinorVersions) {
                                    Set-PnPList -Identity $newList -EnableMinorVersions $list.EnableMinorVersions
                                }

                                # Add content types to list
                                Set-PnPList -Identity $newList -EnableContentTypes $true
                                foreach ($contentType in $list.ContentTypes) {
                                    try {
                                        Add-PnPContentTypeToList -List $newList -ContentType $contentType.Name
                                        Write-Verbose "Added content type $($contentType.Name) to list $($list.Title)"
                                    }
                                    catch {
                                        Write-Warning "Failed to add content type $($contentType.Name) to list $($list.Title): $_"
                                    }
                                }

                                # Add custom fields to list
                                foreach ($field in $list.Fields) {
                                    try {
                                        Add-PnPFieldToList -List $newList -Field $field.InternalName
                                        Write-Verbose "Added field $($field.Title) to list $($list.Title)"
                                    }
                                    catch {
                                        Write-Warning "Failed to add field $($field.Title) to list $($list.Title): $_"
                                    }
                                }

                                # Create views
                                foreach ($view in $list.Views) {
                                    try {
                                        Add-PnPView -List $newList -Title $view.Title -Fields $view.ViewFields -ViewQuery $view.ViewQuery -RowLimit $view.RowLimit -SetAsDefault:$view.DefaultView
                                        Write-Verbose "Created view $($view.Title) in list $($list.Title)"
                                    }
                                    catch {
                                        Write-Warning "Failed to create view $($view.Title) in list $($list.Title): $_"
                                    }
                                }

                                Write-Verbose "Added list: $($list.Title)"
                            }
                            catch {
                                Write-Warning "Failed to add list $($list.Title): $_"
                            }
                            break
                        }
                        "Update" {
                            try {
                                Set-PnPList -Identity $list.Title -EnableVersioning $list.EnableVersioning -EnableMinorVersions $list.EnableMinorVersions -Description $list.Description

                                # Update content types
                                foreach ($contentType in $list.ContentTypesToAdd) {
                                    try {
                                        Add-PnPContentTypeToList -List $list.Title -ContentType $contentType.Name
                                        Write-Verbose "Added content type $($contentType.Name) to list $($list.Title)"
                                    }
                                    catch {
                                        Write-Warning "Failed to add content type $($contentType.Name) to list $($list.Title): $_"
                                    }
                                }

                                foreach ($contentType in $list.ContentTypesToRemove) {
                                    try {
                                        Remove-PnPContentTypeFromList -List $list.Title -ContentType $contentType.Name
                                        Write-Verbose "Removed content type $($contentType.Name) from list $($list.Title)"
                                    }
                                    catch {
                                        Write-Warning "Failed to remove content type $($contentType.Name) from list $($list.Title): $_"
                                    }
                                }

                                # Update fields
                                foreach ($field in $list.FieldsToAdd) {
                                    try {
                                        Add-PnPFieldToList -List $list.Title -Field $field.InternalName
                                        Write-Verbose "Added field $($field.Title) to list $($list.Title)"
                                    }
                                    catch {
                                        Write-Warning "Failed to add field $($field.Title) to list $($list.Title): $_"
                                    }
                                }

                                foreach ($field in $list.FieldsToRemove) {
                                    try {
                                        Remove-PnPField -List $list.Title -Identity $field.InternalName -Force
                                        Write-Verbose "Removed field $($field.Title) from list $($list.Title)"
                                    }
                                    catch {
                                        Write-Warning "Failed to remove field $($field.Title) from list $($list.Title): $_"
                                    }
                                }

                                # Update views
                                foreach ($view in $list.ViewsToAdd) {
                                    try {
                                        Add-PnPView -List $list.Title -Title $view.Title -Fields $view.ViewFields -ViewQuery $view.ViewQuery -RowLimit $view.RowLimit -SetAsDefault:$view.DefaultView
                                        Write-Verbose "Added view $($view.Title) to list $($list.Title)"
                                    }
                                    catch {
                                        Write-Warning "Failed to add view $($view.Title) to list $($list.Title): $_"
                                    }
                                }

                                foreach ($view in $list.ViewsToUpdate) {
                                    try {
                                        Set-PnPView -List $list.Title -Identity $view.Title -Fields $view.ViewFields -ViewQuery $view.ViewQuery -RowLimit $view.RowLimit
                                        Write-Verbose "Updated view $($view.Title) in list $($list.Title)"
                                    }
                                    catch {
                                        Write-Warning "Failed to update view $($view.Title) in list $($list.Title): $_"
                                    }
                                }

                                foreach ($view in $list.ViewsToRemove) {
                                    try {
                                        Remove-PnPView -List $list.Title -Identity $view.Title -Force
                                        Write-Verbose "Removed view $($view.Title) from list $($list.Title)"
                                    }
                                    catch {
                                        Write-Warning "Failed to remove view $($view.Title) from list $($list.Title): $_"
                                    }
                                }

                                Write-Verbose "Updated list: $($list.Title)"
                            }
                            catch {
                                Write-Warning "Failed to update list $($list.Title): $_"
                            }
                            break
                        }
                        "Delete" {
                            try {
                                Remove-PnPList -Identity $list.Title -Force
                                Write-Verbose "Deleted list: $($list.Title)"
                            }
                            catch {
                                Write-Warning "Failed to delete list $($list.Title): $_"
                            }
                            break
                        }
                    }
                }

                # Disconnect from target site
                Disconnect-SPALMSite

                Write-Verbose "Site migration completed successfully"
            }
            else {
                Write-Verbose "WhatIf mode, no changes made"
                Write-Verbose "Migration plan:"
                $migrationPlan | Format-List
            }

            return $true
        }
        catch {
            Write-Error "Error migrating site: $_"
            return $false
        }
    }
}

function Get-SPALMMigrationPlan {
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

            # Create migration plan
            $migrationPlan = [PSCustomObject]@{
                SourceSite = $SourceSite
                TargetSite = $TargetSite
                Columns = @()
                ContentTypes = @()
                Lists = @()
            }

            # Connect to source site to get additional data
            Write-Verbose "Connecting to source site: $SourceSite"
            $sourceConnection = Connect-SPALMSite -Url $SourceSite

            if (-not $sourceConnection) {
                throw "Failed to connect to source site"
            }

            # Process column changes
            Write-Verbose "Processing column changes"
            foreach ($column in $comparison.Columns) {
                switch ($column.Status) {
                    "OnlyInSource" {
                        $sourceColumn = Get-PnPField -Identity $column.InternalName
                        $migrationPlan.Columns += [PSCustomObject]@{
                            Title = $column.Name
                            InternalName = $column.InternalName
                            Type = $column.Type
                            Action = "Add"
                            SchemaXml = $sourceColumn.SchemaXml
                        }
                    }
                    "Different" {
                        $sourceColumn = Get-PnPField -Identity $column.InternalName
                        $migrationPlan.Columns += [PSCustomObject]@{
                            Title = $column.Name
                            InternalName = $column.InternalName
                            Type = $column.Type
                            Action = "Update"
                            SchemaXml = $sourceColumn.SchemaXml
                            Description = $sourceColumn.Description
                            Required = $sourceColumn.Required
                            Group = $sourceColumn.Group
                        }
                    }
                    "OnlyInTarget" {
                        $migrationPlan.Columns += [PSCustomObject]@{
                            Title = $column.Name
                            InternalName = $column.InternalName
                            Type = $column.Type
                            Action = "Delete"
                        }
                    }
                }
            }

            # Process content type changes
            Write-Verbose "Processing content type changes"
            foreach ($contentType in $comparison.ContentTypes) {
                switch ($contentType.Status) {
                    "OnlyInSource" {
                        $sourceContentType = Get-PnPContentType -Identity $contentType.Id
                        $sourceFields = Get-PnPContentTypeField -ContentType $sourceContentType.Name

                        $migrationPlan.ContentTypes += [PSCustomObject]@{
                            Name = $contentType.Name
                            Id = $contentType.Id
                            Group = $contentType.Group
                            Action = "Add"
                            Description = $sourceContentType.Description
                            Fields = $sourceFields
                        }
                    }
                    "Different" {
                        $sourceContentType = Get-PnPContentType -Identity $contentType.Id
                        $sourceFields = Get-PnPContentTypeField -ContentType $sourceContentType.Name

                        # Connect to target site temporarily to get target fields
                        Disconnect-SPALMSite
                        Connect-SPALMSite -Url $TargetSite

                        $targetContentType = Get-PnPContentType -Identity $contentType.Id
                        $targetFields = Get-PnPContentTypeField -ContentType $targetContentType.Name

                        # Reconnect to source site
                        Disconnect-SPALMSite
                        Connect-SPALMSite -Url $SourceSite

                        # Calculate field differences
                        $fieldsToAdd = @()
                        $fieldsToRemove = @()

                        foreach ($sourceField in $sourceFields) {
                            if (-not ($targetFields | Where-Object { $_.Id.StringValue -eq $sourceField.Id.StringValue })) {
                                $fieldsToAdd += $sourceField
                            }
                        }

                        foreach ($targetField in $targetFields) {
                            if (-not ($sourceFields | Where-Object { $_.Id.StringValue -eq $targetField.Id.StringValue })) {
                                $fieldsToRemove += $targetField
                            }
                        }

                        $migrationPlan.ContentTypes += [PSCustomObject]@{
                            Name = $contentType.Name
                            Id = $contentType.Id
                            Group = $contentType.Group
                            Action = "Update"
                            Description = $sourceContentType.Description
                            FieldsToAdd = $fieldsToAdd
                            FieldsToRemove = $fieldsToRemove
                        }
                    }
                    "OnlyInTarget" {
                        $migrationPlan.ContentTypes += [PSCustomObject]@{
                            Name = $contentType.Name
                            Id = $contentType.Id
                            Group = $contentType.Group
                            Action = "Delete"
                        }
                    }
                }
            }

            # Process list changes
            Write-Verbose "Processing list changes"
            foreach ($list in $comparison.Lists) {
                switch ($list.Status) {
                    "OnlyInSource" {
                        $sourceList = Get-PnPList -Identity $list.Title
                        $sourceContentTypes = Get-PnPContentType -List $sourceList
                        $sourceFields = Get-PnPField -List $sourceList
                        $sourceViews = Get-PnPView -List $sourceList

                        $migrationPlan.Lists += [PSCustomObject]@{
                            Title = $list.Title
                            TemplateType = $list.TemplateType
                            Action = "Add"
                            Description = $sourceList.Description
                            EnableVersioning = $sourceList.EnableVersioning
                            EnableMinorVersions = $sourceList.EnableMinorVersions
                            OnQuickLaunch = $sourceList.OnQuickLaunch
                            ContentTypes = $sourceContentTypes
                            Fields = $sourceFields
                            Views = $sourceViews
                        }
                    }
                    "Different" {
                        $sourceList = Get-PnPList -Identity $list.Title
                        $sourceContentTypes = Get-PnPContentType -List $sourceList
                        $sourceFields = Get-PnPField -List $sourceList
                        $sourceViews = Get-PnPView -List $sourceList

                        # Connect to target site temporarily to get target data
                        Disconnect-SPALMSite
                        Connect-SPALMSite -Url $TargetSite

                        $targetList = Get-PnPList -Identity $list.Title
                        $targetContentTypes = Get-PnPContentType -List $targetList
                        $targetFields = Get-PnPField -List $targetList
                        $targetViews = Get-PnPView -List $targetList

                        # Reconnect to source site
                        Disconnect-SPALMSite
                        Connect-SPALMSite -Url $SourceSite

                        # Calculate content type differences
                        $contentTypesToAdd = @()
                        $contentTypesToRemove = @()

                        foreach ($sourceContentType in $sourceContentTypes) {
                            if (-not ($targetContentTypes | Where-Object { $_.Id.StringValue -eq $sourceContentType.Id.StringValue })) {
                                $contentTypesToAdd += $sourceContentType
                            }
                        }

                        foreach ($targetContentType in $targetContentTypes) {
                            if (-not ($sourceContentTypes | Where-Object { $_.Id.StringValue -eq $targetContentType.Id.StringValue })) {
                                $contentTypesToRemove += $targetContentType
                            }
                        }

                        # Calculate field differences
                        $fieldsToAdd = @()
                        $fieldsToRemove = @()

                        foreach ($sourceField in $sourceFields) {
                            if (-not ($targetFields | Where-Object { $_.InternalName -eq $sourceField.InternalName })) {
                                $fieldsToAdd += $sourceField
                            }
                        }

                        foreach ($targetField in $targetFields) {
                            if (-not ($sourceFields | Where-Object { $_.InternalName -eq $targetField.InternalName })) {
                                $fieldsToRemove += $targetField
                            }
                        }

                        # Calculate view differences
                        $viewsToAdd = @()
                        $viewsToUpdate = @()
                        $viewsToRemove = @()

                        foreach ($sourceView in $sourceViews) {
                            $targetView = $targetViews | Where-Object { $_.Title -eq $sourceView.Title }

                            if (-not $targetView) {
                                $viewsToAdd += $sourceView
                            }
                            else {
                                # Check if view is different
                                $isDifferent = $false

                                if ($sourceView.ViewQuery -ne $targetView.ViewQuery) {
                                    $isDifferent = $true
                                }

                                if ($sourceView.RowLimit -ne $targetView.RowLimit) {
                                    $isDifferent = $true
                                }

                                $sourceViewFields = $sourceView.ViewFields.SchemaXml
                                $targetViewFields = $targetView.ViewFields.SchemaXml

                                if ($sourceViewFields -ne $targetViewFields) {
                                    $isDifferent = $true
                                }

                                if ($isDifferent) {
                                    $viewsToUpdate += $sourceView
                                }
                            }
                        }

                        foreach ($targetView in $targetViews) {
                            if (-not ($sourceViews | Where-Object { $_.Title -eq $targetView.Title })) {
                                $viewsToRemove += $targetView
                            }
                        }

                        $migrationPlan.Lists += [PSCustomObject]@{
                            Title = $list.Title
                            TemplateType = $list.TemplateType
                            Action = "Update"
                            Description = $sourceList.Description
                            EnableVersioning = $sourceList.EnableVersioning
                            EnableMinorVersions = $sourceList.EnableMinorVersions
                            OnQuickLaunch = $sourceList.OnQuickLaunch
                            ContentTypesToAdd = $contentTypesToAdd
                            ContentTypesToRemove = $contentTypesToRemove
                            FieldsToAdd = $fieldsToAdd
                            FieldsToRemove = $fieldsToRemove
                            ViewsToAdd = $viewsToAdd
                            ViewsToUpdate = $viewsToUpdate
                            ViewsToRemove = $viewsToRemove
                        }
                    }
                    "OnlyInTarget" {
                        $migrationPlan.Lists += [PSCustomObject]@{
                            Title = $list.Title
                            TemplateType = $list.TemplateType
                            Action = "Delete"
                        }
                    }
                }
            }

            # Disconnect from source site
            Disconnect-SPALMSite

            return $migrationPlan
        }
        catch {
            Write-Error "Error creating migration plan: $_"
            return $null
        }
    }
}

function Backup-SPALMSiteArtifacts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SiteUrl,

        [Parameter(Mandatory = $false)]
        [string]$BackupPath
    )

    process {
        try {
            # Set default backup path if not provided
            if (-not $BackupPath) {
                $BackupPath = Join-Path -Path (Get-Location) -ChildPath "backups"
            }

            # Create backup directory if it doesn't exist
            if (-not (Test-Path -Path $BackupPath)) {
                New-Item -Path $BackupPath -ItemType Directory -Force | Out-Null
            }

            # Generate backup file name
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $siteUrlSafe = ($SiteUrl -replace "https://|http://", "" -replace "[^a-zA-Z0-9]", "_")
            $backupFile = Join-Path -Path $BackupPath -ChildPath "$siteUrlSafe`_$timestamp.json"

            # Connect to site
            Write-Verbose "Connecting to site: $SiteUrl"
            $siteConnection = Connect-SPALMSite -Url $SiteUrl

            if (-not $siteConnection) {
                throw "Failed to connect to site"
            }

            # Get site data
            Write-Verbose "Getting site data"
            $siteData = Get-SPALMSiteData

            # Disconnect from site
            Disconnect-SPALMSite

            # Export site data
            Write-Verbose "Exporting site data"
            $siteData | ConvertTo-Json -Depth 10 | Out-File -FilePath $backupFile -Force

            Write-Verbose "Backup created successfully: $backupFile"
            return $backupFile
        }
        catch {
            Write-Error "Error backing up site artifacts: $_"
            return $false
        }
    }
}
