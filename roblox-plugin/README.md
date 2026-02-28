# Razon Agent Roblox Plugin

This folder contains the Roblox Studio plugin source for **Razon Agent**.

Current MVP features:
- Docked widget panel titled `Razon Agent`
- Prompt input box
- Buttons row with `Scan Selection` working
- Output panel with scan status and scanned script paths
- `Propose Changes`, `Approve`, and `Reject` are visible but disabled

## Files

- `src/RazonAgent.plugin.lua` - plugin entry script

## Manual Install (Beginner Friendly, Windows)

1. Close Roblox Studio if it is open.
2. Open File Explorer.
3. Paste this into the address bar and press Enter:
   `%LOCALAPPDATA%\Roblox\Plugins`
4. Copy `src/RazonAgent.plugin.lua` from this repo into that folder.
5. Rename the copied file to `RazonAgent.lua`.
6. Open Roblox Studio.
7. Go to the `Plugins` tab and click `Razon Agent` to show or hide the panel.

If you do not see it:
- Open `Plugins` -> `Manage Plugins` and make sure it is enabled.
- Restart Roblox Studio.

## How To Use Scan Selection

1. In Explorer, select one or more scripts, folders, or services.
2. Click `Scan Selection` in the `Razon Agent` panel.
3. The output panel will show:
   - status messages
   - scripts found count
   - scanned script paths

Behavior notes:
- If nothing is selected, it shows: `Select a Script or Folder in Explorer first.`
- If no scripts are found, it shows: `No scripts found in selection.`
- The scan is capped at 200 scripts and shows: `Scan capped at 200 scripts.` when hit.

