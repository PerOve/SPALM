# SharePoint ALM MCP Server
# This file defines the Model Context Protocol server for SharePoint ALM operations

Import-Module $PSScriptRoot/../SPALM/SPALM.psm1 -Force

# Define MCP functions
function Start-MCPServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Port = 8080
    )

    process {
        try {
            # Import the MCP Server module
            if (-not (Get-Module -Name Microsoft.PowerShell.MCP)) {
                Install-Module -Name Microsoft.PowerShell.MCP -Force -Scope CurrentUser
            }
            Import-Module -Name Microsoft.PowerShell.MCP -Force

            # Define routes for the MCP server
            $routes = @(
                @{
                    Method = "GET"
                    Path = "/api/health"
                    Handler = { return @{ status = "ok"; version = "1.0.0" } | ConvertTo-Json }
                },
                @{
                    Method = "GET"
                    Path = "/api/config"
                    Handler = { return Get-SPALMConfiguration | ConvertTo-Json -Depth 10 }
                },
                @{
                    Method = "POST"
                    Path = "/api/connect"
                    Handler = {
                        param($Request)
                        $body = $Request.Body | ConvertFrom-Json
                        $result = Connect-SPALMSite -Url $body.url -ConnectionType $body.connectionType
                        return @{ success = $result } | ConvertTo-Json
                    }
                },
                @{
                    Method = "POST"
                    Path = "/api/disconnect"
                    Handler = {
                        $result = Disconnect-SPALMSite
                        return @{ success = $result } | ConvertTo-Json
                    }
                },
                @{
                    Method = "POST"
                    Path = "/api/compare"
                    Handler = {
                        param($Request)
                        $body = $Request.Body | ConvertFrom-Json
                        $params = @{
                            SourceSite = $body.sourceSite
                            TargetSite = $body.targetSite
                        }

                        if ($body.includeColumns) { $params.IncludeColumns = $true }
                        if ($body.includeContentTypes) { $params.IncludeContentTypes = $true }
                        if ($body.includeLists) { $params.IncludeLists = $true }
                        if ($body.includeViews) { $params.IncludeViews = $true }

                        $result = Compare-SPALMSite @params
                        return $result | ConvertTo-Json -Depth 10
                    }
                }
            )

            # Start the MCP server
            Start-MCPServer -Port $Port -Routes $routes

            return $true
        }
        catch {
            Write-Error "Failed to start MCP server: $_"
            return $false
        }
    }
}

# Start the MCP server when this script is executed directly
if ($MyInvocation.InvocationName -ne ".") {
    Write-Host "Starting SPALM MCP Server..."
    Start-MCPServer
}
