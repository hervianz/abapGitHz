# OAuth 2.0 Device Code Flow Authentication

## Overview

abapGit supports **OAuth 2.0 Device Authorization Grant (Device Code Flow)** for authenticating with Git providers via browser-based Single Sign-On (SSO) instead of using username and Personal Access Token (PAT).

This authentication method is particularly useful for:
- Corporate environments with SSO/SAML authentication
- Organizations that disable PAT creation
- Enhanced security through short-lived tokens
- Multi-factor authentication requirements

## Supported Providers

| Provider | Device Code Flow Support | Client Secret Required |
|----------|-------------------------|------------------------|
| GitHub (github.com) | ✅ Yes | ❌ No |
| GitHub Enterprise Server | ✅ Yes | ❌ No |
| GitLab (gitlab.com) | ✅ Yes | ❌ No |
| GitLab Self-Managed | ✅ Yes (v15.1+) | ❌ No |
| Other OAuth 2.0 providers | ⚠️ May work | ⚠️ May be required |

## How It Works

The Device Code Flow follows these steps:

1. **Initiate Flow**: abapGit requests a device code and user code from the OAuth provider
2. **User Authorization**: A dialog shows the verification URL and user code; browser opens automatically
3. **User Authentication**: User logs into the provider (using corporate SSO if configured) and enters the code
4. **Token Polling**: User clicks "Check Authorization" in abapGit; the system polls for the access token
5. **Token Storage**: On success, the access token is stored in-memory for the session (like PAT today)

The flow is defined in [RFC 8628](https://datatracker.ietf.org/doc/html/rfc8628).

## Prerequisites

### For GitHub / GitHub Enterprise Server

1. Navigate to **Settings → Developer settings → OAuth Apps → New OAuth App**
   - For GitHub Enterprise: `https://YOUR-GHE-HOST/settings/applications`
2. Fill in the application details:
   - **Application name**: Any name (e.g., "abapGit CLI")
   - **Homepage URL**: Any URL (e.g., `https://github.com/abapGit/abapGit`)
   - **Authorization callback URL**: `http://localhost` (not used by Device Flow, but required)
3. **Enable Device Flow**: Check the "Enable Device Flow" checkbox in the app settings
4. Copy the **Client ID** (no client secret needed for Device Flow)

### For GitLab / GitLab Self-Managed

1. Navigate to **User Settings → Applications → Add new application**
   - For self-managed: `https://YOUR-GITLAB-HOST/-/profile/applications`
2. Fill in the application details:
   - **Name**: Any name (e.g., "abapGit")
   - **Redirect URI**: `http://localhost` (not used by Device Flow, but required)
   - **Scopes**: Select `api` and `read_user`
3. Click **Save application**
4. Copy the **Application ID** (= Client ID)

**Note**: GitLab version 15.1 or higher is required for Device Flow support.

## Usage

### Step 1: Access a Protected Repository

When you try to access an HTTPS repository that requires authentication, abapGit will show the **Authentication Method** dialog.

### Step 2: Select Authentication Method

Choose one of:
- **Username / Password / Personal Access Token** (traditional method)
- **SSO (OAuth 2.0 Device Code Flow)** (new method)

### Step 3: Enter OAuth App Credentials

If you selected SSO:

1. **Client ID** (required): Enter the Client ID from your registered OAuth App
2. **Client Secret** (optional): Leave empty for GitHub/GitLab; only enter if your provider requires it
3. **Device code URL** (auto-filled): The endpoint is auto-detected from your repository URL
   - GitHub: `https://github.com/login/device/code`
   - GitHub Enterprise: `https://YOUR-GHE-HOST/login/device/code`
   - GitLab: `https://gitlab.com/oauth/authorize_device`
   - You can edit this if your provider uses a non-standard endpoint

### Step 4: Authorize in Browser

1. A new dialog shows the **Verification URL** and **User Code**
2. Your default browser opens automatically to the verification URL
3. Log into your Git provider (using SSO if configured)
4. Enter the user code shown in the abapGit dialog
5. Approve the authorization request

### Step 5: Complete Authorization

1. Return to the abapGit dialog
2. Click **Check Authorization**
3. If successful, you'll see "Authorization successful!" and the dialog closes
4. abapGit will now use the OAuth token for all API requests

## When to Use Client Secret

### Standard OAuth 2.0 Device Code Flow

The Device Code Flow (RFC 8628) is designed for **public clients** (applications that cannot securely store secrets). By design, it does **NOT** require a client secret.

**GitHub, GitLab, and most OAuth providers do NOT require client secret for Device Code Flow.**

### Enterprise OAuth Providers

Some enterprise OAuth providers may require a client secret even for Device Code Flow as an additional security measure. This is non-standard but supported by abapGit.

**How to determine if you need a client secret:**

1. Check your OAuth provider's documentation for Device Code Flow
2. Try authenticating without a client secret first
3. If you receive an error like "invalid_client" or "client authentication failed", you may need to:
   - Provide a client secret in the "Client Secret (opt)" field
   - Check if your provider supports Device Flow for public clients
   - Consider using a different OAuth flow or authentication method

## Troubleshooting

### "OAuth Client ID not configured"

**Cause**: You didn't enter a Client ID in the dialog.

**Solution**: Register an OAuth App at your Git provider and enter the Client ID.

### "Code expired. Please cancel and try again."

**Cause**: The device code expired before you completed authorization (typically 15 minutes).

**Solution**: Click Cancel and start the flow again. Complete the authorization more quickly.

### "Access denied. Authorization was rejected."

**Cause**: You clicked "Deny" or "Cancel" during the browser authorization.

**Solution**: Start the flow again and click "Approve" in the browser.

### "OAuth device flow initiation failed"

**Possible causes**:
- Invalid Client ID
- Network connectivity issues
- Provider doesn't support Device Code Flow
- Incorrect device code URL

**Solutions**:
1. Verify your Client ID is correct
2. Check network connectivity to the OAuth provider
3. Verify the provider supports Device Code Flow
4. Check if the device code URL is correct (edit if needed)

### "Authentication cancelled" or Falls Back to Password Dialog

**Cause**: OAuth flow failed or was cancelled.

**Solution**: This is expected behavior. abapGit automatically falls back to the traditional username/password dialog. You can:
- Enter your username and PAT to continue
- Click Cancel and try OAuth again with correct settings

### Password Dialog Still Appears After Entering Client ID and Approving in Browser

**Cause**: An earlier version of the dialog mis-detected the SAP standard "Execute" command (`ONLI`) on the authentication-method screen as a cancellation, so OAuth was silently skipped and the basic-auth popup was shown instead.

**Solution**: Pull the latest version of this branch — the screen-1004 event handler no longer treats the Execute action as cancel and only relies on `sy-subrc` (which is non-zero only for true Back/Exit/Cancel). After updating, selecting **SSO (OAuth 2.0 Device Code Flow)** and clicking Execute will reliably show the device-code screen instead of the username/password popup.

### Browser Did Not Open Automatically

**Cause**: The SAP GUI front-end service `execute( iv_document = ... )` may silently fail on some platforms (e.g. when no default browser is registered, or in remote-GUI scenarios).

**Solution**: Copy the **Verification URL** shown in the dialog and open it manually in any browser, enter the **User Code** displayed in abapGit, approve access, then click **Check Authorization** in the dialog. The "Open Browser" pushbutton can also be clicked again to retry.

## Security Notes

1. **Token Storage**: OAuth access tokens are stored **in-memory only** during the session, just like PATs today. They do not persist across SAP sessions.

2. **Client Secret Security**: If your provider requires a client secret, it will be transmitted over HTTPS but stored in memory. For maximum security:
   - Use providers that support Device Flow without client secrets (GitHub, GitLab)
   - Rotate your OAuth app credentials regularly
   - Limit OAuth app scopes to minimum required permissions

3. **Token Scope**: The OAuth token has the same scopes as configured in your OAuth App. For abapGit, you typically need:
   - GitHub: Default scopes (repo access)
   - GitLab: `api` and `read_user` scopes

## Comparison: OAuth vs PAT

| Feature | OAuth Device Code Flow | Personal Access Token |
|---------|----------------------|----------------------|
| Setup | Requires OAuth App registration | Requires token generation |
| Authentication | Browser-based SSO | Copy/paste token |
| MFA Support | ✅ Yes (via SSO) | ⚠️ Depends on provider |
| Token Lifetime | Provider-controlled (hours) | Long-lived or no expiry |
| Corporate SSO | ✅ Yes | ❌ No |
| Session Storage | In-memory | In-memory |
| Background Jobs | ❌ No (requires GUI) | ✅ Yes |

## Limitations

1. **Requires SAP GUI**: OAuth Device Code Flow requires a graphical interface to display the dialog and open the browser. It is not available for:
   - Background jobs
   - Non-interactive API calls
   - ADT (ABAP Development Tools) context

   In these scenarios, abapGit will automatically use the traditional username/password authentication.

2. **Token Expiration**: OAuth tokens typically expire after a few hours. You'll need to re-authenticate when the token expires. PATs may have longer expiration or no expiration.

3. **No Refresh Token**: The current implementation does not support refresh tokens. When your access token expires, you must re-authenticate.

## FAQ

### Q: Do I need to register an OAuth App for every user?

**A:** No. You can register **one OAuth App per organization** and share the Client ID with all users. Each user will authenticate individually using their own credentials.

### Q: Can I use the same OAuth App for multiple repositories?

**A:** Yes. One OAuth App can authenticate to all repositories within the same Git provider (or GitHub Enterprise instance).

### Q: What if my organization doesn't allow OAuth App registration?

**A:** Contact your Git administrator to register an OAuth App for abapGit. Alternatively, use the traditional username/PAT authentication method.

### Q: Can I use OAuth with on-premise Git servers?

**A:** Yes, if your Git server supports OAuth 2.0 Device Code Flow. You may need to manually enter the device code URL in the dialog.

### Q: Why does the dialog ask for Client Secret if it's optional?

**A:** Client Secret support is included for enterprise OAuth providers that may require it as a non-standard security measure. For GitHub and GitLab, leave this field empty.

## Additional Resources

- [RFC 8628 - OAuth 2.0 Device Authorization Grant](https://datatracker.ietf.org/doc/html/rfc8628)
- [GitHub: Authorizing OAuth Apps - Device Flow](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#device-flow)
- [GitLab: OAuth 2.0 Device Authorization Grant](https://docs.gitlab.com/ee/api/oauth2.html#authorization-code-with-proof-key-for-code-exchange-pkce)
