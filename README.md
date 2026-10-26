# Custom bank preset names

Give your RuneScape bank presets recognisable names and colours. This Lua 5.4
plugin changes their appearance locally, not their server-side names or behaviour.

## Features

- Custom names for all 18 mapped preset slots, up to 40 Unicode characters each.
- Independent custom background and name-text colours, selected with clickable swatches.
- Dragging one bank preset onto another swaps their saved names and colours too.
- Edit through the plugin's ribbon/settings panel or directly from the bank.
- Save settings locally for each character; reset individual presets at any time.
- Draggable bank editor with a position remembered between client sessions.
- Optional settings-only checkbox to hide the bank's predefined-name dropdown
  (visible by default).

The plugin does not load presets, automate actions, reveal hidden information, or
unlock unavailable slots. Existing bank actions are unchanged. Disabling it
restores original labels and colours where the bank components remain available.

See [changelog.md](changelog.md) for release changes.

## Availability and requirements

This repository contains the development version. Distribution requires Jagex
moderation approval; this repository does not imply approval. Local testing uses
the RuneScape plugin development beta.

**Dependency:** PrettyUI (mod.io ID `6398181`) must be installed. Development
enable commands do not download dependencies automatically.

## How to use

1. Enable the plugin and open its ribbon entry or Settings icon in the Plugin Hub.
2. Select a preset and enter a name. Click the rectangle beside **Background colour**
   or **Text colour** to open the colour picker.
3. Choose a hue from the strip, then a shade from the colour area, or enter an
   exact `#RRGGBB` hex colour. **Apply** updates the swatch; **Cancel** discards the
   picker edit. Click **Save** in the editor (or press Enter in the name field)
   to save the name and both colours and apply them to the bank.
4. Click **Reset** to restore the predefined name and default colours. Saving a
   blank name restores only the name, keeping your chosen colours.

Alternatively, right-click a preset name in the bank and choose **Customize
preset**. The editor opens for that slot. Drag its title bar to move it; its
position is saved on close, shared across characters, and kept within UI bounds.
Click **×** to close it; it also closes when the bank disappears.

- An asterisk (`*`) in the preset selector marks a saved custom name or colour.
- Click **i** to show or hide help notes, which start hidden.
- Scroll the ribbon form or use its scrollbar when controls do not fit. Scrolling
  over a dropdown operates that dropdown. Resizing preserves unfinished edits.
- Changing presets discards unsaved edits. You must be logged in with your
  character's display name available to save.
- Names cannot contain markup delimiters (`<`, `>`) or control characters.
- **Default** in the picker stages the game's colour for that field; click **Save**
  to apply it. A dash in the swatch means Default. Text colour affects only the name.
- Colours are fully opaque and stored as `#RRGGBB`. Older named-colour settings
  are treated as Default; choose a new colour with the picker to customise them again.
- In the Plugin Hub settings menu, tick **Hide predefined-name dropdown** to
  hide the game's name dropdown below the bank preset list. Untick to restore it.
  This applies to every preset; it does not change the selected predefined name.
  The preset list expands into the freed space while this option is enabled.

## Permissions

This plugin requests no additional permissions. It does not access chat or make
network requests.

## Data protection - Case 1 (local only)

The plugin uses your character's display name, entered preset names, chosen
colours, and editor position. Nothing is transmitted outside the plugin to the
developer or external services. It does not take screenshots.

Settings persist locally through the client's `PersistentDB` API. The character
display name forms part of the storage keys, ignoring case and surrounding
spaces. Names and colours are stored per character; editor position is shared
across characters on this device, as is the dropdown visibility preference.
No gameplay history is stored.

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
- `editor/`: shared editor, PrettyUI popup, layout, colours, and icons.
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
