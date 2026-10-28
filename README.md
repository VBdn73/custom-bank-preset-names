# Custom bank preset names

Give your RuneScape bank presets custom names, colours, and skill icons. This Lua 5.4 plugin
changes their appearance locally, not their server-side names or behaviour.

## Features

- Custom names for all 18 numbered presets and the Beast of Burden row, up to 40 Unicode characters each.
- Background and text colours via swatches, a colour picker, or hex input.
- Optional skill icons replace the numbers on presets 1–18, using native client assets.
- Editable preset-row preview shows staged names, colours, and icons before saving.
- Dragging one bank preset onto another swaps their saved names, colours, and icons too.
- Beast of Burden has its own saved name and colours and is excluded from numbered-preset swaps.
- Edit names, colours, and icons only from inside the bank UI.
- Save settings locally for each character; reset individual presets at any time.
- Editor saves and customisation swaps validate names, colours, and icons together. On storage
  failure, the plugin attempts to restore previous customisations (best-effort, not
  atomic). Failed recovery is reported explicitly; console diagnostics identify the
  affected slot and field. Native bank preset swaps are not undone by this recovery.
- Draggable bank editor that remembers its position and follows preset selection.
- Option to hide the bank's predefined-name dropdown (visible by default).

No preset loading, automation, hidden information, or slot unlocking. Bank actions
are unchanged. Disabling restores original labels and colours where available
and removes plugin-owned icon sprites. Beast of Burden's native icon is unchanged.

See [changelog.md](changelog.md) for release changes.

## Availability and requirements

This is a development version for the RuneScape plugin beta. Distribution requires
Jagex moderation approval; this repository does not imply approval.

**Dependency:** PrettyUI (mod.io ID `6398181`) must be installed. Development
enable commands do not download dependencies automatically.

## How to use

1. In the bank UI, right-click a preset name and choose **Customize preset**.
2. Enter a name and click a background/text swatch to choose colours.
3. Click or drag across the smooth colour canvas, or enter `#RRGGBB`. Hue runs
   left to right, with white at the top and black at the bottom. Changes
   immediately update the preview. Click **×** or the same swatch again to close
   the picker without discarding the selected colour.
4. For a numbered preset, click **Icon** to open the Skills picker. Hover an icon
   to see its skill name; click it to stage that selection and close the picker.
   **Use preset number** or the adjacent **↺** stages the default number. Closing
   the picker without selecting leaves the staged value unchanged.
5. Click **Save** (or press Enter in the name field) to save the name, colours, and icon.
   **Reset** previews all defaults; click **Save** to commit the reset.
    Saving a blank name keeps your chosen colours and icon.

The editor shows a read-only preset heading; select another preset in the bank to switch
without closing it. Drag the title bar to move it. Its position is saved on close
and kept within UI bounds. **×** or closing the bank closes the editor.

- Click **i** to show or hide help notes, which start hidden.
- Plugin Hub settings and the ribbon panel only show **Hide predefined-name dropdown**
   and guidance for opening the editor. Customisations can only be edited in the bank UI.
- Switching presets discards unsaved edits. Saving requires your logged-in
  character's display name. Closing the editor also discards unsaved edits.
- Names cannot contain markup delimiters (`<`, `>`) or control characters.
- The **↺** icon beside each colour swatch restores that colour's default; click **Save** to apply it. A crossed
  swatch means Default. Text colour affects only the name.
- Colours are opaque `#RRGGBB` values.
- Only one icon or colour picker opens at a time. Unknown icon keys or unavailable
  assets fall back to the preset number; no images are downloaded or bundled.
- In Plugin Hub settings, **Hide predefined-name dropdown** hides the game's
  dropdown and expands the preset list. It applies to all presets without changing
  their predefined names; untick to restore the dropdown.

## Permissions

This plugin requests no additional permissions. It does not access chat or make
network requests.

## Data protection - Case 1 (local only)

The plugin stores your character's display name, preset names, colours, icon selections, editor
position, and dropdown preference locally. Nothing is sent to the developer or
external services. No screenshots or gameplay history are collected.

Settings persist locally through the client's `PersistentDB` API. The character
display name forms part of the storage keys, ignoring case and surrounding
spaces. Names, colours, and icons are stored per character; editor position is shared
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
- `bank/icons.lua`: saved-icon rendering, native number restoration, and sprite cleanup.
- `editor/`: shared editor, PrettyUI popup, layout, help, theme, and icons.
- `presets/`: validation and per-character persistent settings.
- `components/colour_picker/`: self-contained picker and colour conversions.
- `components/icon_picker/`: data-driven, storage-independent native sprite picker.
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
ID `(slot - 1) * 3 + 1` for the 18 numbered presets. Live diagnostics confirmed
the Beast of Burden name at dynamic 55, background at static 265/dynamic 19,
and hit target at static 267/dynamic 19 (all category 0). Its internal saved
entry is 19, but this does not make it a numbered or swappable preset.
Missing or restricted components are skipped. Game UI updates may require new
mappings. `pan Component` exports static definitions, not live dynamic rows;
use the separate `bank-interface-diagnostics` plugin to inspect live components.
Bind only unrestricted labels belonging to individual entries.

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
