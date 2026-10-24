# Custom bank preset names

A Lua 5.4 RuneScape client plugin for local, display-only preset names. It does
not change server-side preset names, load presets, or automate bank actions.

## Bank preset support

All 18 preset slots now have name-label bindings in `bank_bindings.lua`.
The mappings use interface 517, static component 266, category 0, and name-label
dynamic ID `(slot - 1) * 3 + 1`, following the captured row layout for slots 6–9.
Slot 7 has been confirmed working in-client; verify the remaining slots on your
client, particularly the first and last slots. Missing components are skipped;
the plugin does not unlock unavailable presets or create missing game rows.
Custom names and reset-to-predefined behavior work independently for each slot.
Previously saved names are preserved.

### Interface discovery tool

Development-only interface scanning has been moved out of this plugin to
`../../developer-tools/bank-interface-diagnostics/`. That folder contains the
scanner, configuration, standalone development plugin entry point, tests, and
reuse instructions. This plugin no longer scans interface IDs or prints
`[Bank IDs]` diagnostic output. The tool is not a runtime dependency.

In the beta client console, use `pan Component` to export the component name/ID
index to your clipboard. Find the bank preset name labels and verify their slot
mapping in the client. Add one entry per label in `bank_bindings.lua`, specifying
`slot` (1-based), `interfaceID`, and `staticID`. Dynamic labels also require
`categoryID` and `dynamicID`. Do not bind generic labels reused for a selected
preset unless you implement selection-aware slot resolution first. Adjust
`presetCount` if your client exposes a different number of presets.

Bindings must resolve to unrestricted `ui.ComponentType.LABEL` components.
The plugin reacquires labels on each client logic tick, retains their predefined
text, and restores it when reset or disabled. If the game updates a label while
overridden, its latest text becomes the fallback. Dynamic component mappings
must be rechecked after client UI changes.

## Install and use

1. Join the RuneScape plugin development beta and import your save as described
   in https://developer.runescape.com/rs/getting-started.html.
2. Keep this folder under `RuneScape-BETA/dev_plugins/` (already correctly placed).
3. Open the console with **Alt + `**, run `prf`, then
   `pon custom-bank-preset-names`.
4. Open the plugin's ribbon entry or its Settings icon in the Plugin Hub.
5. Choose a preset number from the scrollable dropdown, type a name, and press **Save** or Enter. Changing
   preset numbers discards unsaved edits. **Reset**, or saving a blank name,
   returns to the game's predefined name.
6. After editing Lua files, run `prl custom-bank-preset-names`.

Names are limited to 40 Unicode characters; markup delimiters and control
characters are rejected. Settings are saved immediately through `PersistentDB`.
They are isolated per RuneScape character on this device, not synced to other
devices, and separate between beta and live clients. The character's display name
(ignoring case and surrounding spaces) separates local settings. No extra
permissions are required and no data is sent off-device. After a character rename,
names must be re-entered or manually migrated. A reused display name on this device
can inherit settings previously saved under that name.

Old device-wide names are retained but not automatically imported: their original
character cannot be determined. Re-enter those names for each desired character.
Settings from the previous tracking-ID-based version are also retained but are
not automatically imported. Saving is blocked until the logged-in character's
display name is available.

Before submission, replace the placeholder `contactEmailAddress` in
`plugin.json`, personally review the code, test in the beta client, and follow
Jagex's moderation/submission process. Live use requires moderation approval.

## Verification

Run `lua tests/run.lua` with Lua 5.4 installed for mocked regression tests.
In-client testing is still required: save/reset names, reopen the bank, change a
predefined name while overridden, reload/disable the plugin, restart the client,
and verify each mapped slot (including dynamic labels and locked presets).

API references: [structure](https://developer.runescape.com/rs/structure.html),
[UI](https://developer.runescape.com/rs/ui/interface.html),
[events](https://developer.runescape.com/rs/core/events.html), and
[persistence](https://developer.runescape.com/rs/core/persistentdb.html).
