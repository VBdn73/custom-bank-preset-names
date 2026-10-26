# Changelog

## Unreleased

- Replaced predefined-colour dropdowns with stacked background/text colour swatches.
- Added a colour picker with a hue strip, shade area, hex input, preview, and Apply/Cancel/Default actions.
- Colour pickers open beside the clicked swatch and follow the editor when moved, flipping left and clamping at screen edges.
- Registered bank colour pickers as PrettyUI window overlays so dragging the editor does not cover the picker.
- Custom colours use the existing Save/Reset workflow and per-character storage.
- Removed the old predefined palette and named-colour lookup; older named selections now display as Default.

## 0.4.0 - 2026-10-25

- Custom names, background colours, and text colours now follow presets when swapping them by drag and drop in the bank.
- Prevented the previous slot's predefined name briefly appearing when moving a custom name to another slot.

## 0.3.0 - 2026-10-25

- Added independent preset background and text colours, with 13 colours plus Default.
- Bank editor now remembers its position between sessions.
- Improved editor layout and scrolling with PrettyUI controls.

## 0.2.0 - 2026-10-24

- Custom names are now saved separately for each character.
- Added a right-click option to edit names directly from the bank in a draggable popup.
- Marked renamed presets with an asterisk in the preset selector.
- Improved editor styling, save/error feedback, and collapsible information notes.

## 0.1.0 - 2026-10-24

- Initial release with local custom names for all 18 bank preset slots.
- Added a preset selector with Save and Reset controls and support for names up to 40 Unicode characters.
- Saved names locally and restored predefined names when reset or disabled.
