# SPALM Module - GitHub Copilot Workspace

This file helps GitHub Copilot understand the context of this workspace.

## Project Information

- **Name**: SPALM (SharePoint ALM Toolkit)
- **Language**: PowerShell
- **Main Dependencies**: PnP.PowerShell
- **Purpose**: SharePoint Online site columns, content types, lists, and views management across environments

## Important References

1. Detailed instructions: `docs/CopilotInstructions.md`
2. Quick reference prompt: `docs/CopilotPrompt.md`
3. VS Code configuration: `.vscode/copilot.jsonc`
4. PnP.PowerShell GitHub: https://github.com/pnp/powershell
5. PowerShell Module Structure:
   - SPALM.psd1 - Module manifest
   - SPALM.psm1 - Module loader
   - Functions/ - Individual function files by category

## Coding Standards

- Use comment-based help for all public functions
- Follow PowerShell approved verb-noun naming convention (Verb-SPALMNoun)
- Implement error handling with try/catch blocks
- Include parameter validation
- Use PnP.PowerShell for all SharePoint operations
- Write Pester tests for all public functions
