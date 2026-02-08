---
name: xcode-cloud-ci
description: Check Xcode Cloud CI build status via App Store Connect API. Triggers after `git push` in iOS/macOS projects using Xcode Cloud (no .github/workflows directory). Monitors builds, reports results, and helps debug failures.
---

# Xcode Cloud CI Watcher

After performing a `git push` in an iOS/macOS project using Xcode Cloud, check build status.

## Prerequisites

Credentials must be configured at `~/.config/app-store-connect/credentials.json`. See setup instructions below.

Required Python packages: `pip3 install PyJWT requests`

## Workflow

1. **After pushing**, wait before checking (builds need time to start)
2. **Determine polling strategy**:
   - Xcode Cloud builds typically take 5-15 minutes
   - Wait 2-3 minutes initially, poll every 30-60s
3. **Check status** using the check script
4. **On success**: Report and continue
5. **On failure**: Analyze the error, propose a fix

## Checking Status

```bash
# Check most recent build
scripts/check_xcode_cloud.py

# Filter by app/product name
scripts/check_xcode_cloud.py --product "MyApp"

# Filter by workflow
scripts/check_xcode_cloud.py --product "MyApp" --workflow "Release"

# Poll for up to 10 minutes
scripts/check_xcode_cloud.py --wait 600

# List available products
scripts/check_xcode_cloud.py --list-products

# List workflows for a product
scripts/check_xcode_cloud.py --product "MyApp" --list-workflows
```

## On Failure

1. Check the build details in App Store Connect
2. Analyze the error and identify root cause
3. Propose a specific fix with code changes
4. Ask: "Xcode Cloud build failed due to [reason]. I can fix this by [solution]. Should I implement this fix?"

## Credentials Setup

1. Go to [App Store Connect](https://appstoreconnect.apple.com) → Users and Access → Integrations → App Store Connect API
2. Click **+** to create a new key
3. Name it (e.g., "CI Watcher"), select **Developer** or **Admin** role
4. Download the `.p8` private key file (only downloadable once!)
5. Note the **Key ID** and **Issuer ID**

Create the credentials file:

```bash
mkdir -p ~/.config/app-store-connect
```

Create `~/.config/app-store-connect/credentials.json`:

```json
{
  "issuer_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "key_id": "XXXXXXXXXX",
  "private_key_path": "~/.config/app-store-connect/AuthKey_XXXXXXXXXX.p8"
}
```

Move your `.p8` file to `~/.config/app-store-connect/` and update the path.

Set restrictive permissions:

```bash
chmod 600 ~/.config/app-store-connect/credentials.json
chmod 600 ~/.config/app-store-connect/*.p8
```

