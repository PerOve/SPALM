# SPALM.Comparison.psm1
# SharePoint site comparison module for SPALM toolkit

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

# Comparison functions
function Compare-SPALMSite {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceSite,

        [Parameter(Mandatory = $true)]
        [string]$TargetSite,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeColumns,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeContentTypes,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeLists,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeViews,

        [Parameter(Mandatory = $false)]
        [switch]$ExportReport,

        [Parameter(Mandatory = $false)]
        [string]$ReportPath
    )

    begin {
        $result = [PSCustomObject]@{
            SourceSite = $SourceSite
            TargetSite = $TargetSite
            Columns = $null
            ContentTypes = $null
            Lists = $null
            ListViews = $null
            Summary = [PSCustomObject]@{
                TotalDifferences = 0
                ColumnsOnlyInSource = 0
                ColumnsOnlyInTarget = 0
                ColumnsDifferent = 0
                ContentTypesOnlyInSource = 0
                ContentTypesOnlyInTarget = 0
                ContentTypesDifferent = 0
                ListsOnlyInSource = 0
                ListsOnlyInTarget = 0
                ListsDifferent = 0
                ViewsOnlyInSource = 0
                ViewsOnlyInTarget = 0
                ViewsDifferent = 0
            }
        }
    }

    process {
        try {
            # Connect to source and target sites
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

            # Connect to target site
            Write-Verbose "Connecting to target site: $TargetSite"
            $targetConnection = Connect-SPALMSite -Url $TargetSite

            if (-not $targetConnection) {
                throw "Failed to connect to target site"
            }

            # Get target site data
            Write-Verbose "Getting target site data"
            $targetData = Get-SPALMSiteData

            # Disconnect from target site
            Disconnect-SPALMSite

            # Compare site data
            Write-Verbose "Comparing site data"

            # Compare columns if requested
            if ($IncludeColumns -or (-not $IncludeColumns -and -not $IncludeContentTypes -and -not $IncludeLists -and -not $IncludeViews)) {
                Write-Verbose "Comparing site columns"
                $result.Columns = Compare-SPALMSiteColumns -SourceColumns $sourceData.Columns -TargetColumns $targetData.Columns
                $result.Summary.ColumnsOnlyInSource = ($result.Columns | Where-Object { $_.Status -eq 'OnlyInSource' }).Count
                $result.Summary.ColumnsOnlyInTarget = ($result.Columns | Where-Object { $_.Status -eq 'OnlyInTarget' }).Count
                $result.Summary.ColumnsDifferent = ($result.Columns | Where-Object { $_.Status -eq 'Different' }).Count
                $result.Summary.TotalDifferences += $result.Summary.ColumnsOnlyInSource + $result.Summary.ColumnsOnlyInTarget + $result.Summary.ColumnsDifferent
            }

            # Compare content types if requested
            if ($IncludeContentTypes -or (-not $IncludeColumns -and -not $IncludeContentTypes -and -not $IncludeLists -and -not $IncludeViews)) {
                Write-Verbose "Comparing content types"
                $result.ContentTypes = Compare-SPALMContentTypes -SourceContentTypes $sourceData.ContentTypes -TargetContentTypes $targetData.ContentTypes
                $result.Summary.ContentTypesOnlyInSource = ($result.ContentTypes | Where-Object { $_.Status -eq 'OnlyInSource' }).Count
                $result.Summary.ContentTypesOnlyInTarget = ($result.ContentTypes | Where-Object { $_.Status -eq 'OnlyInTarget' }).Count
                $result.Summary.ContentTypesDifferent = ($result.ContentTypes | Where-Object { $_.Status -eq 'Different' }).Count
                $result.Summary.TotalDifferences += $result.Summary.ContentTypesOnlyInSource + $result.Summary.ContentTypesOnlyInTarget + $result.Summary.ContentTypesDifferent
            }

            # Compare lists if requested
            if ($IncludeLists -or (-not $IncludeColumns -and -not $IncludeContentTypes -and -not $IncludeLists -and -not $IncludeViews)) {
                Write-Verbose "Comparing lists"
                $result.Lists = Compare-SPALMLists -SourceLists $sourceData.Lists -TargetLists $targetData.Lists
                $result.Summary.ListsOnlyInSource = ($result.Lists | Where-Object { $_.Status -eq 'OnlyInSource' }).Count
                $result.Summary.ListsOnlyInTarget = ($result.Lists | Where-Object { $_.Status -eq 'OnlyInTarget' }).Count
                $result.Summary.ListsDifferent = ($result.Lists | Where-Object { $_.Status -eq 'Different' }).Count
                $result.Summary.TotalDifferences += $result.Summary.ListsOnlyInSource + $result.Summary.ListsOnlyInTarget + $result.Summary.ListsDifferent
            }

            # Compare views if requested
            if ($IncludeViews -or (-not $IncludeColumns -and -not $IncludeContentTypes -and -not $IncludeLists -and -not $IncludeViews)) {
                Write-Verbose "Comparing list views"
                $result.ListViews = Compare-SPALMListViews -SourceLists $sourceData.Lists -TargetLists $targetData.Lists
                $result.Summary.ViewsOnlyInSource = ($result.ListViews | Where-Object { $_.Status -eq 'OnlyInSource' }).Count
                $result.Summary.ViewsOnlyInTarget = ($result.ListViews | Where-Object { $_.Status -eq 'OnlyInTarget' }).Count
                $result.Summary.ViewsDifferent = ($result.ListViews | Where-Object { $_.Status -eq 'Different' }).Count
                $result.Summary.TotalDifferences += $result.Summary.ViewsOnlyInSource + $result.Summary.ViewsOnlyInTarget + $result.Summary.ViewsDifferent
            }

            # Export report if requested
            if ($ExportReport) {
                if (-not $ReportPath) {
                    $ReportPath = Join-Path -Path (Get-Location) -ChildPath "SPALM_Comparison_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
                }

                Export-SPALMComparisonReport -ComparisonResult $result -ReportPath $ReportPath
            }

            return $result
        }
        catch {
            Write-Error "Error comparing sites: $_"
            return $null
        }
    }
}

function Get-SPALMSiteData {
    [CmdletBinding()]
    param()

    process {
        try {
            $siteData = [PSCustomObject]@{
                Columns = Get-PnPField -IncludeAll
                ContentTypes = Get-PnPContentType -IncludeAll
                Lists = Get-PnPList -IncludeAll
            }

            # Enrich lists with views
            foreach ($list in $siteData.Lists) {
                $list | Add-Member -MemberType NoteProperty -Name "Views" -Value (Get-PnPView -List $list -IncludeAll)
            }

            return $siteData
        }
        catch {
            Write-Error "Error getting site data: $_"
            return $null
        }
    }
}

function Compare-SPALMSiteColumns {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$SourceColumns,

        [Parameter(Mandatory = $true)]
        [object[]]$TargetColumns
    )

    process {
        $results = @()

        # First, find columns that exist in source but not in target
        foreach ($sourceColumn in $SourceColumns) {
            $targetColumn = $TargetColumns | Where-Object { $_.InternalName -eq $sourceColumn.InternalName }

            if (-not $targetColumn) {
                $results += [PSCustomObject]@{
                    Name = $sourceColumn.Title
                    InternalName = $sourceColumn.InternalName
                    Type = $sourceColumn.TypeAsString
                    Status = "OnlyInSource"
                    Differences = $null
                }
            }
            else {
                $differences = @()

                # Compare properties
                if ($sourceColumn.Title -ne $targetColumn.Title) {
                    $differences += "Title: '$($sourceColumn.Title)' vs '$($targetColumn.Title)'"
                }

                if ($sourceColumn.TypeAsString -ne $targetColumn.TypeAsString) {
                    $differences += "Type: '$($sourceColumn.TypeAsString)' vs '$($targetColumn.TypeAsString)'"
                }

                if ($sourceColumn.Group -ne $targetColumn.Group) {
                    $differences += "Group: '$($sourceColumn.Group)' vs '$($targetColumn.Group)'"
                }

                if ($sourceColumn.Required -ne $targetColumn.Required) {
                    $differences += "Required: '$($sourceColumn.Required)' vs '$($targetColumn.Required)'"
                }

                if ($differences.Count -gt 0) {
                    $results += [PSCustomObject]@{
                        Name = $sourceColumn.Title
                        InternalName = $sourceColumn.InternalName
                        Type = $sourceColumn.TypeAsString
                        Status = "Different"
                        Differences = $differences
                    }
                }
            }
        }

        # Find columns that exist in target but not in source
        foreach ($targetColumn in $TargetColumns) {
            $sourceColumn = $SourceColumns | Where-Object { $_.InternalName -eq $targetColumn.InternalName }

            if (-not $sourceColumn) {
                $results += [PSCustomObject]@{
                    Name = $targetColumn.Title
                    InternalName = $targetColumn.InternalName
                    Type = $targetColumn.TypeAsString
                    Status = "OnlyInTarget"
                    Differences = $null
                }
            }
        }

        return $results
    }
}

function Compare-SPALMContentTypes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$SourceContentTypes,

        [Parameter(Mandatory = $true)]
        [object[]]$TargetContentTypes
    )

    process {
        $results = @()

        # First, find content types that exist in source but not in target
        foreach ($sourceContentType in $SourceContentTypes) {
            $targetContentType = $TargetContentTypes | Where-Object { $_.Id.StringValue -eq $sourceContentType.Id.StringValue }

            if (-not $targetContentType) {
                $results += [PSCustomObject]@{
                    Name = $sourceContentType.Name
                    Id = $sourceContentType.Id.StringValue
                    Group = $sourceContentType.Group
                    Status = "OnlyInSource"
                    Differences = $null
                }
            }
            else {
                $differences = @()

                # Compare properties
                if ($sourceContentType.Name -ne $targetContentType.Name) {
                    $differences += "Name: '$($sourceContentType.Name)' vs '$($targetContentType.Name)'"
                }

                if ($sourceContentType.Group -ne $targetContentType.Group) {
                    $differences += "Group: '$($sourceContentType.Group)' vs '$($targetContentType.Group)'"
                }

                if ($sourceContentType.Description -ne $targetContentType.Description) {
                    $differences += "Description: '$($sourceContentType.Description)' vs '$($targetContentType.Description)'"
                }

                # Compare field links
                $sourceFields = Get-PnPContentTypeField -ContentType $sourceContentType.Name
                $targetFields = Get-PnPContentTypeField -ContentType $targetContentType.Name

                foreach ($sourceField in $sourceFields) {
                    if (-not ($targetFields | Where-Object { $_.Id.StringValue -eq $sourceField.Id.StringValue })) {
                        $differences += "Field missing in target: '$($sourceField.Title)'"
                    }
                }

                foreach ($targetField in $targetFields) {
                    if (-not ($sourceFields | Where-Object { $_.Id.StringValue -eq $targetField.Id.StringValue })) {
                        $differences += "Field only in target: '$($targetField.Title)'"
                    }
                }

                if ($differences.Count -gt 0) {
                    $results += [PSCustomObject]@{
                        Name = $sourceContentType.Name
                        Id = $sourceContentType.Id.StringValue
                        Group = $sourceContentType.Group
                        Status = "Different"
                        Differences = $differences
                    }
                }
            }
        }

        # Find content types that exist in target but not in source
        foreach ($targetContentType in $TargetContentTypes) {
            $sourceContentType = $SourceContentTypes | Where-Object { $_.Id.StringValue -eq $targetContentType.Id.StringValue }

            if (-not $sourceContentType) {
                $results += [PSCustomObject]@{
                    Name = $targetContentType.Name
                    Id = $targetContentType.Id.StringValue
                    Group = $targetContentType.Group
                    Status = "OnlyInTarget"
                    Differences = $null
                }
            }
        }

        return $results
    }
}

function Compare-SPALMLists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$SourceLists,

        [Parameter(Mandatory = $true)]
        [object[]]$TargetLists
    )

    process {
        $results = @()

        # First, find lists that exist in source but not in target
        foreach ($sourceList in $SourceLists) {
            # Skip hidden lists
            if ($sourceList.Hidden) {
                continue
            }

            $targetList = $TargetLists | Where-Object { $_.Title -eq $sourceList.Title }

            if (-not $targetList) {
                $results += [PSCustomObject]@{
                    Title = $sourceList.Title
                    TemplateType = $sourceList.BaseTemplate
                    Url = $sourceList.DefaultViewUrl
                    Status = "OnlyInSource"
                    Differences = $null
                }
            }
            else {
                $differences = @()

                # Compare properties
                if ($sourceList.Description -ne $targetList.Description) {
                    $differences += "Description: '$($sourceList.Description)' vs '$($targetList.Description)'"
                }

                if ($sourceList.BaseTemplate -ne $targetList.BaseTemplate) {
                    $differences += "Template Type: '$($sourceList.BaseTemplate)' vs '$($targetList.BaseTemplate)'"
                }

                if ($sourceList.Hidden -ne $targetList.Hidden) {
                    $differences += "Hidden: '$($sourceList.Hidden)' vs '$($targetList.Hidden)'"
                }

                if ($sourceList.EnableVersioning -ne $targetList.EnableVersioning) {
                    $differences += "EnableVersioning: '$($sourceList.EnableVersioning)' vs '$($targetList.EnableVersioning)'"
                }

                if ($sourceList.EnableMinorVersions -ne $targetList.EnableMinorVersions) {
                    $differences += "EnableMinorVersions: '$($sourceList.EnableMinorVersions)' vs '$($targetList.EnableMinorVersions)'"
                }

                # Compare content types
                $sourceContentTypes = Get-PnPContentType -List $sourceList
                $targetContentTypes = Get-PnPContentType -List $targetList

                foreach ($sourceContentType in $sourceContentTypes) {
                    if (-not ($targetContentTypes | Where-Object { $_.Id.StringValue -eq $sourceContentType.Id.StringValue })) {
                        $differences += "Content type missing in target: '$($sourceContentType.Name)'"
                    }
                }

                foreach ($targetContentType in $targetContentTypes) {
                    if (-not ($sourceContentTypes | Where-Object { $_.Id.StringValue -eq $targetContentType.Id.StringValue })) {
                        $differences += "Content type only in target: '$($targetContentType.Name)'"
                    }
                }

                # Compare fields
                $sourceFields = Get-PnPField -List $sourceList
                $targetFields = Get-PnPField -List $targetList

                foreach ($sourceField in $sourceFields) {
                    if (-not ($targetFields | Where-Object { $_.InternalName -eq $sourceField.InternalName })) {
                        $differences += "Field missing in target: '$($sourceField.Title)'"
                    }
                }

                foreach ($targetField in $targetFields) {
                    if (-not ($sourceFields | Where-Object { $_.InternalName -eq $targetField.InternalName })) {
                        $differences += "Field only in target: '$($targetField.Title)'"
                    }
                }

                if ($differences.Count -gt 0) {
                    $results += [PSCustomObject]@{
                        Title = $sourceList.Title
                        TemplateType = $sourceList.BaseTemplate
                        Url = $sourceList.DefaultViewUrl
                        Status = "Different"
                        Differences = $differences
                    }
                }
            }
        }

        # Find lists that exist in target but not in source
        foreach ($targetList in $TargetLists) {
            # Skip hidden lists
            if ($targetList.Hidden) {
                continue
            }

            $sourceList = $SourceLists | Where-Object { $_.Title -eq $targetList.Title }

            if (-not $sourceList) {
                $results += [PSCustomObject]@{
                    Title = $targetList.Title
                    TemplateType = $targetList.BaseTemplate
                    Url = $targetList.DefaultViewUrl
                    Status = "OnlyInTarget"
                    Differences = $null
                }
            }
        }

        return $results
    }
}

function Compare-SPALMListViews {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$SourceLists,

        [Parameter(Mandatory = $true)]
        [object[]]$TargetLists
    )

    process {
        $results = @()

        # Compare views in each list
        foreach ($sourceList in $SourceLists) {
            # Skip hidden lists
            if ($sourceList.Hidden) {
                continue
            }

            $targetList = $TargetLists | Where-Object { $_.Title -eq $sourceList.Title }

            if ($targetList) {
                $sourceViews = $sourceList.Views
                $targetViews = $targetList.Views

                # Find views in source but not in target
                foreach ($sourceView in $sourceViews) {
                    $targetView = $targetViews | Where-Object { $_.Title -eq $sourceView.Title }

                    if (-not $targetView) {
                        $results += [PSCustomObject]@{
                            ListTitle = $sourceList.Title
                            ViewTitle = $sourceView.Title
                            ViewUrl = $sourceView.ServerRelativeUrl
                            Status = "OnlyInSource"
                            Differences = $null
                        }
                    }
                    else {
                        $differences = @()

                        # Compare view properties
                        if ($sourceView.ViewQuery -ne $targetView.ViewQuery) {
                            $differences += "ViewQuery is different"
                        }

                        if ($sourceView.RowLimit -ne $targetView.RowLimit) {
                            $differences += "RowLimit: '$($sourceView.RowLimit)' vs '$($targetView.RowLimit)'"
                        }

                        if ($sourceView.DefaultView -ne $targetView.DefaultView) {
                            $differences += "DefaultView: '$($sourceView.DefaultView)' vs '$($targetView.DefaultView)'"
                        }

                        # Compare view fields
                        $sourceViewFields = $sourceView.ViewFields.SchemaXml
                        $targetViewFields = $targetView.ViewFields.SchemaXml

                        if ($sourceViewFields -ne $targetViewFields) {
                            $differences += "ViewFields are different"
                        }

                        if ($differences.Count -gt 0) {
                            $results += [PSCustomObject]@{
                                ListTitle = $sourceList.Title
                                ViewTitle = $sourceView.Title
                                ViewUrl = $sourceView.ServerRelativeUrl
                                Status = "Different"
                                Differences = $differences
                            }
                        }
                    }
                }

                # Find views in target but not in source
                foreach ($targetView in $targetViews) {
                    $sourceView = $sourceViews | Where-Object { $_.Title -eq $targetView.Title }

                    if (-not $sourceView) {
                        $results += [PSCustomObject]@{
                            ListTitle = $targetList.Title
                            ViewTitle = $targetView.Title
                            ViewUrl = $targetView.ServerRelativeUrl
                            Status = "OnlyInTarget"
                            Differences = $null
                        }
                    }
                }
            }
        }

        return $results
    }
}

function Export-SPALMComparisonReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ComparisonResult,

        [Parameter(Mandatory = $true)]
        [string]$ReportPath
    )

    process {
        try {
            $ComparisonResult | ConvertTo-Json -Depth 10 | Out-File -FilePath $ReportPath -Force
            Write-Verbose "Comparison report exported to $ReportPath"
            return $true
        }
        catch {
            Write-Error "Failed to export comparison report: $_"
            return $false
        }
    }
}
