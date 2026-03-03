# Fix: "Missing message metadata.transfer:Finalizing for locale en_US"

This error is a known Salesforce CLI/Metadata API quirk. Use one of these to deploy:

## Option 1: Deploy from VS Code / Cursor (recommended)

1. Install the **Salesforce Extension Pack** if you haven’t.
2. Right-click `force-app/main/default/classes` (or the single file).
3. Choose **SFDX: Deploy Source to Org** (or **Deploy Source to Org**).
4. The VS Code path often avoids this error.

## Option 2: Deploy Apex manually in the org

1. In Salesforce: **Setup** → Quick Find: **Apex Classes** → **New**.
2. Open `GrantApplicationController.cls` in your editor and copy all of its code.
3. Paste into the Apex class in the org, save.
4. Repeat for `GrantEligibilityService.cls` if needed.
5. For the LWC: **Setup** → **Lightning Components** → **New** and create/update the component, or deploy the LWC folder via VS Code.

## Option 3: Update Salesforce CLI and retry

```bash
npm install -g @salesforce/cli@latest
sf project deploy start --source-dir force-app --wait 10
```

## Option 4: Retry later

The error is often transient. Try the same deploy again after a few minutes or from a different network.
