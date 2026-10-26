# Changelog

## 0.5.0 - 2026-10-26

- Replaced colour dropdowns with background/text swatches and a picker with hue, shade, hex input, preview, and Apply/Cancel/Default controls.
- Click a swatch again to close its picker. Crossed swatches indicate Default.
- Pickers follow the editor, stay within screen bounds, and remain above PrettyUI windows.
- Custom colours use the existing per-character Save/Reset workflow.
- Added a settings option to hide the bank's predefined-name dropdown and expand the preset list into its space.
- Selecting another bank preset now updates the open editor without closing it.
- Replaced the bank editor's preset dropdown with a read-only preset heading; the ribbon/settings selector remains available.
- Fixed layout and alignment in the side plugin menu.
- Extracted reusable colour-picker and help components, centralised slot/colour helpers, and expanded regression tests.

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
