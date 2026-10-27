# Custom bank preset names

Give your RuneScape bank presets custom names and colours. This Lua 5.4 plugin
changes their appearance locally, not their server-side names or behaviour.

## Features

- Custom names for all 18 mapped preset slots, up to 40 Unicode characters each.
- Background and text colours via swatches, a colour picker, or hex input.
- Editable name field previews staged background and text colours before saving.
- Dragging one bank preset onto another swaps their saved names and colours too.
- Edit through the main Plugin Hub settings or directly from the bank.
- Save settings locally for each character; reset individual presets at any time.
- Editor saves and customisation swaps validate names and colours together. On storage
  failure, the plugin attempts to restore previous customisations (best-effort, not
  atomic). Failed recovery is reported explicitly; console diagnostics identify the
  affected slot and field. Native bank preset swaps are not undone by this recovery.
- Draggable bank editor that remembers its position and follows preset selection.
- Option to hide the bank's predefined-name dropdown (visible by default).

No preset loading, automation, hidden information, or slot unlocking. Bank actions
are unchanged. Disabling restores original labels and colours where available.

See [changelog.md](changelog.md) for release changes.

## Availability and requirements

This is a development version for the RuneScape plugin beta. Distribution requires
Jagex moderation approval; this repository does not imply approval.

**Dependency:** PrettyUI (mod.io ID `6398181`) must be installed. Development
enable commands do not download dependencies automatically.

## How to use

1. Open the plugin's Plugin Hub Settings icon.
2. Select a preset, enter a name, and click a background/text swatch to choose colours.
3. Click or drag across the hue strip and shade area, or enter `#RRGGBB`. Changes
   immediately update the preview. Click the same swatch again to close the picker.
4. Click **Save** (or press Enter in the name field) to save the name and colours.
   **Reset** previews all defaults; click **Save** to commit the reset.
   Saving a blank name keeps your chosen colours.

In the bank, right-click a preset name and choose **Customize preset**. The editor
shows a read-only preset heading; select another preset in the bank to switch
without closing it. Drag the title bar to move it. Its position is saved on close
and kept within UI bounds. **×** or closing the bank closes the editor.

- An asterisk (`*`) in the preset selector marks a saved custom name or colour.
- Click **i** to show or hide help notes, which start hidden.
- The ribbon panel only shows **Hide predefined-name dropdown**; preset editing
  stays in the main Plugin Hub settings and bank UI.
- Switching presets discards unsaved edits. Saving requires your logged-in
  character's display name. Closing the editor also discards unsaved edits.
- Names cannot contain markup delimiters (`<`, `>`) or control characters.
- The **↺** icon beside each colour swatch restores that colour's default; click **Save** to apply it. A crossed
  swatch means Default. Text colour affects only the name.
- Colours are opaque `#RRGGBB` values. Older named colours use Default until replaced.
- In Plugin Hub settings, **Hide predefined-name dropdown** hides the game's
  dropdown and expands the preset list. It applies to all presets without changing
  their predefined names; untick to restore the dropdown.

## Permissions

This plugin requests no additional permissions. It does not access chat or make
network requests.

## Data protection - Case 1 (local only)

The plugin stores your character's display name, preset names, colours, editor
position, and dropdown preference locally. Nothing is sent to the developer or
external services. No screenshots or gameplay history are collected.

Settings persist locally through the client's `PersistentDB` API. The character
display name forms part of the storage keys, ignoring case and surrounding
spaces. Names and colours are stored per character; editor position is shared
across characters on this device, as is the dropdown visibility preference.

- Settings do not sync between devices; beta and live storage are separate.
- After a character rename, re-enter or manually migrate your settings. Reusing
  a display name on the same device can inherit its previous settings.
- Older device-wide and tracking-ID-based settings are not imported automatically.
- Settings have no automatic expiry. Reset clears a slot's customisation but
  does not remove the character name from its storage keys.
- Disabling does not erase settings. There is no full-data deletion control for
  current or legacy keys; do not assume uninstalling clears the client database.
  The developer cannot access or delete these local settings remotely.

## Local development

Follow Jagex's [getting-started guide](https://developer.runescape.com/rs/getting-started.html).
Place the repository, including its subdirectories, in
`RuneScape-BETA/dev_plugins/custom-bank-preset-names/` and install PrettyUI.
Open the client console with **Alt + `**, then run:

```text
prf
pon custom-bank-preset-names
```

After Lua changes, run `prl custom-bank-preset-names`. After `plugin.json` changes,
run `prf` before reloading so the manifest and dependencies are rescanned.

### Tests

Run the mocked regression suite with Lua 5.4:

```sh
lua tests/run.lua
```

In the client, verify save/reset, all mapped slots (including preset 18), separate
character settings, persistence after reload/restart, popup position, scrolling,
resizing, help/close buttons, colour defaults, and restoration on disable.
Mocked tests do not replace in-client visual and interaction checks.

### Code overview

- `main.lua`: lifecycle, editor entry points, and label refresh/restoration.
- `bank/`: preset bindings, local label/colour overrides, and the context menu.
- `editor/`: shared editor, PrettyUI popup, layout, help, theme, and icons.
- `presets/`: validation and per-character persistent settings.
- `components/colour_picker/`: self-contained picker and colour conversions.
- `tests/`: mocked regression suites; `plugin.json`: manifest and dependency.

Use slash-separated imports such as `require("editor/view")`, without `.lua`.
The entry point passes the `prettyui` dependency global to editor modules;
do not use `require("prettyui")`. Preset slots are one-based; native dropdown
entry IDs are zero-based. An empty saved name means “use the predefined name”.

### Reusable colour picker

The picker remains bundled in this plugin, but has no editor, storage or PrettyUI
dependencies. Its public API is:

```lua
local picker = require("components/colour_picker/init")
local close, updatePosition = picker.open(host, {
    title = "Choose background colour", -- defaults to "Choose colour"
    initial = "#38A4FF",
    anchor = swatch, -- optional; defaults to host
    onApply = function(hex) end, -- #RRGGBB, or "" for Default
    onClose = function() end, -- optional; called before onApply
})
```

Call `close()` when the host is disposed and `updatePosition()` when it moves.
Both are safe after closing. Optional `theme` supplies `border` and `background`
RGBA tables. Optional `attachOverlay(root, updatePosition)` integrates the host's
overlay management and returns a cleanup function; the editor uses this to keep
the picker above PrettyUI windows during dragging/focus changes.

For later extraction, move `components/colour_picker/` into the new plugin and
replace the picker import in `editor/view.lua` and the utility import in
`presets/colour_value.lua` with dependency exports. The component itself uses
only the client UI API and its own colour utilities; it never saves settings.

`bank/bindings.lua` maps interface 517, static component 266, category 0, dynamic
ID `(slot - 1) * 3 + 1`. Missing or restricted components are skipped. Game UI
updates may require new mappings; use `pan Component` in the beta console to
inspect them. Bind only unrestricted labels belonging to individual slots.

Before submission, personally review and understand the code, test it, and follow
Jagex's [plugin guidelines](https://developer.runescape.com/rs/submission/guidelines.html)
and [submission process](https://developer.runescape.com/rs/submission/process.html).

## Feedback and collaboration

Report issues or propose contributions through this repository's issue tracker,
or contact [vincent.rs.plugins@gmail.com](mailto:vincent.rs.plugins@gmail.com).
For bugs, include reproduction steps and your client version. Do not post
personal information in public reports.

## EULA

This Plugin uses software licensed by Jagex to the developer under the terms of the Jagex End User Licence Agreement (EULA) found at https://legal.jagex.com/docs/terms/eula (and all terms incorporated into it by reference). The development and any use of the Plugin is at all times subject to the Jagex EULA.
