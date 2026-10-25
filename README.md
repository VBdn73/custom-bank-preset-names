# Custom bank preset names

Give your RuneScape bank presets custom names that are easier to recognise.
This Lua 5.4 client plugin replaces the displayed preset labels locally, without
changing the game's server-side preset names or how presets work.

## Features

- Custom names for all 18 mapped bank preset slots.
- Independent background and preset-name colours: Default, Red, Green, or Blue.
- A scrollable preset selector, with **Save** and **Reset** controls.
- Right-click a bank preset name and choose **Customize preset** to open a popup for that slot.
- Names up to 40 Unicode characters long.
- Local settings kept separately for each character name.
- Restore the game's predefined name by resetting a slot or saving a blank name.
- No extra permissions, external dependencies, or network requests.

The plugin only changes displayed text and colours. It does not load presets, automate bank
actions, or unlock unavailable preset slots. Disabling it restores the original
labels and colours where the bank components are still available.

## Availability

This repository contains the development version. Live-client distribution
requires Jagex moderation approval; this repository does not imply approval.
For local testing, use the RuneScape plugin development beta as described below.

## How to use

1. Enable the plugin and open its ribbon entry or its Settings icon in the Plugin Hub.
2. Choose a preset number from the dropdown.
3. Enter a name, choose colours, and click **Save**, or press Enter, to save all three.
4. Click **Reset** to restore the game's predefined name and default colours.
   Saving a blank name restores only the predefined name, keeping your chosen colours.

An asterisk in the preset dropdown (for example, **Preset 3 \***) marks a slot
with a saved custom name, background colour, or text colour. Resetting the preset
removes the marker; saving a blank name removes it only if both colours are Default.

Click **i** to show or hide the storage and display-only information. These notes
start hidden in both editors. In the bank popup the button sits beside **×**;
in plugin settings it sits at the top-right of the content area.

Each preset editor includes **Background** and **Text colour** dropdowns with
**Default**, **Red**, **Green**, and **Blue**. Colour selections are saved together
with the name using **Save** at the bottom of the editor, on this device per character.
Default restores the game's colour. Text colour affects only the preset name.

Alternatively, right-click the preset's name in the bank and choose **Customize preset**.
The popup starts on the clicked slot, regardless of which preset is selected in
the bank. The popup opens centered within the bank; drag its title bar to move it
within the outer game UI, outside the bank's nested popover. This does not change
the plugin settings editor. Click **×** in the top-right
corner to dismiss it. The normal bank menu actions and default
left-click action are unchanged.

Changing the selected preset discards unsaved edits. You must be logged in with
your character's display name available before saving. Markup delimiters (`<` and
`>`) and control characters are not allowed in names.

## Storage and privacy

Custom names are saved on your device using the client's `PersistentDB` API.
The plugin uses the logged-in character's display name to separate settings,
ignoring case and surrounding spaces. It sends no data off-device.

- Settings are not synced between devices and are separate between beta and live clients.
- After a character rename, names must be re-entered or manually migrated.
- A reused character display name on the same device can inherit its previous settings.
- Older device-wide and tracking-ID-based settings are not automatically imported.

**Data protection: Case 1 (local only).** The data used is your character's display
name and the custom preset names you enter. The display name forms part of the
local storage keys; custom names are stored as their values. Nothing is transmitted
to the developer or external services.

Saved settings have no automatic expiry. Resetting a slot overwrites its custom
name with an empty string, but does not remove the character name from the storage
key. Disabling the plugin does not erase its stored settings. The plugin has no
full-data deletion control, including for previous character names and legacy keys;
do not assume uninstalling clears the client's database. The developer cannot
access or erase this local database remotely.

## Permissions

This plugin requests no additional permissions.

## Local development

Follow Jagex's [getting-started guide](https://developer.runescape.com/rs/getting-started.html)
to set up the plugin development beta. Place this repository in
`RuneScape-BETA/dev_plugins/custom-bank-preset-names/`.

Open the client console with **Alt + `**, then run:

```text
prf
pon custom-bank-preset-names
```

After changing Lua files, reload the plugin:

```text
prl custom-bank-preset-names
```

### Tests

In-client checks: test several rows including preset 18, reopen the bank and
reload the plugin to verify persistence, and check scrolling, hover/selection
outlines, independent Default resets, and restoration when disabling the plugin.

The bank popup uses the native `RS3_BUTTON_INFO_PARENT_0/1/2`
and `RS3_BUTTON_CLOSE_PARENT_0/1/2` sprites as idle, hover, and pressed artwork.
Their exact match to the bank icons still needs an in-client visual check:
reload the plugin, right-click a preset name, and choose **Customize preset**. Compare
the icons with the bank's top-right controls, hover/click them, and confirm that
info toggles the help notes and close dismisses only the editor, not the bank.
The plugin settings editor uses the same native info icon and states.

Run the mocked regression suite from the repository root with Lua 5.4:

```sh
lua tests/run.lua
```

### Code layout

Start with `main.lua` to follow the plugin's lifecycle:

| File | Responsibility |
| --- | --- |
| `main.lua` | Opens editors, refreshes them each logic tick, reapplies bank labels before drawing, and restores labels on shutdown. |
| `constants.lua` | Shares the editor title and maximum name length between modules. |
| `bank/bindings.lua` | Maps the 18 preset slots to their bank label component IDs. |
| `bank/labels.lua` | Applies custom labels while remembering the latest predefined text for restoration. |
| `bank/menu.lua` | Adds a Customize preset action using component identity or the hovered name label when native actions belong to a row hit target. |
| `editor/view.lua` | Builds the editor, handles selection and saving, and centres controls when resized. |
| `editor/popup.lua` | Hosts the editor in a bank popup with the clicked slot preselected. |
| `editor/layout.lua` | Defines control positions and dimensions, including derived popup sizes. |
| `editor/theme.lua` | Defines named UI colours and creates native colour values on demand. |
| `editor/icon.lua` | Builds native sprite controls and updates their hover/pressed artwork. |
| `presets/names.lua` | Validates names, separates settings by character, caches reads, and verifies writes to `PersistentDB`. |
| `presets/text_validation.lua` | Counts UTF-8 code points and rejects malformed text without the optional `utf8` library. |
| `plugin.json` | Declares the plugin's name, version, UI entry points, and contact address. |
| `tests/run.lua` | Runs the regression suites and reports totals with a failing exit status when needed. |
| `tests/name_editor.lua` | Mocks native controls to test editor layout and interactions. |

Runtime modules use slash-separated imports relative to the plugin root, without
the `.lua` extension, such as `require("editor/view")`. This also applies inside
nested modules. Dotted imports such as `require("editor.view")` are not supported
by the client. See the [official dependency documentation](https://developer.runescape.com/rs/structure.html#dependencies).
Keep the `bank/`, `editor/`, and `presets/` directories when installing the plugin.

Preset slots are **one-based** throughout storage and bank bindings. Only the
native dropdown uses **zero-based** entry IDs; the editor converts between them.
An empty saved name means “use the game's predefined name”, not a custom blank label.

### Interface bindings

`bank/bindings.lua` defines the preset label mappings. They currently use interface
517, static component 266, category 0, and dynamic ID `(slot - 1) * 3 + 1`.
Missing or restricted components are skipped. Game UI updates may require these
mappings to be updated.

Use `pan Component` in the beta console to export the component index when
investigating UI changes. Bind only unrestricted label components corresponding
to individual preset slots, not a shared selected-preset label.

## Feedback

Report problems through this repository's issue tracker or contact
[vincent.rs.plugins@gmail.com](mailto:vincent.rs.plugins@gmail.com).
Include reproduction steps and your client version, and avoid sharing personal
information in public reports.

## EULA

This Plugin uses software licensed by Jagex to the developer under the terms of the Jagex End User Licence Agreement (EULA) found at https://legal.jagex.com/docs/terms/eula (and all terms incorporated into it by reference). The development and any use of the Plugin is at all times subject to the Jagex EULA.
