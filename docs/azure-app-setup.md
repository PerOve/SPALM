# Setting Up Azure App Registration for SPALM

This guide explains how to set up an Azure App Registration with the necessary permissions for SPALM to work with SharePoint Online, Microsoft Graph, and user information.

## Step 1: Register a New App in Azure Active Directory

1. Sign in to the [Azure Portal](https://portal.azure.com)
2. Navigate to **Azure Active Directory** → **App registrations**
3. Click on **New registration**
4. Enter the following information:
   - **Name**: SPALM App
   - **Supported account types**: Accounts in this organizational directory only (Single tenant)
   - **Redirect URI**: (Web) https://localhost
5. Click **Register**

## Step 2: Configure API Permissions

### Add SharePoint Permissions

1. In your app registration, go to **API permissions**
2. Click **Add a permission**
3. Select **SharePoint**
4. Choose **Application permissions**
5. Add the following permissions:
   - **Sites.FullControl.All**
   - **TermStore.ReadWrite.All**
   - **User.ReadWrite.All**

### Add Microsoft Graph Permissions

1. Click **Add a permission** again
2. Select **Microsoft Graph**
3. Choose **Application permissions**
4. Add the following permissions:
   - **Group.ReadWrite.All**
   - **User.Read.All**
   - **Directory.Read.All**

## Step 3: Grant Admin Consent

1. After adding all permissions, click the **Grant admin consent for [Your Organization]** button
2. Confirm the action

## Step 4: Create a Client Secret

1. Go to **Certificates & secrets**
2. Under **Client secrets**, click **New client secret**
3. Add a description and select expiration (recommended: 1 year)
4. Click **Add**
5. **IMPORTANT**: Copy and securely store the secret value immediately (it will only be shown once)

## Step 5: Configure GitHub Secrets

Add the following secrets to your GitHub repository:

1. Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**
2. Add the following secrets:
   - **AZURE_APP_CLIENT_ID**: Your app's Application (client) ID
   - **AZURE_APP_CLIENT_SECRET**: The client secret you created
   - **AZURE_APP_TENANT_ID**: Your tenant ID
   - **DEV_SITE_URL**: Your development SharePoint site URL
   - **TEST_SITE_URL**: Your test SharePoint site URL
   - **PROD_SITE_URL**: Your production SharePoint site URL
   - **SOURCE_SITE_URL**: Your source/template site URL

## Step 6: Test the Connection

You can test the connection using PowerShell:

```powershell
# Install PnP.PowerShell if needed
Install-Module -Name PnP.PowerShell -Force -Scope CurrentUser

# Connect using app-only authentication
$clientId = "YOUR_CLIENT_ID"
$clientSecret = "YOUR_CLIENT_SECRET"
$tenantId = "YOUR_TENANT_ID"
$siteUrl = "https://yourtenant.sharepoint.com/sites/yoursite"

Connect-PnPOnline -Url $siteUrl -ClientId $clientId -ClientSecret $clientSecret -TenantId $tenantId

# Verify connection
Get-PnPWeb

# Disconnect
Disconnect-PnPOnline
```

## Using the PnP PowerShell Default ClientId

As mentioned in the [PnP PowerShell documentation](https://pnp.github.io/powershell/articles/defaultclientid.html), you can also use the default PnP PowerShell ClientId if you prefer. However, for production environments, it's recommended to use your own registered app for better control and security.
