# Changelog

## Unreleased

- Added optional native skill icons for numbered presets 1–18, covering all 29 skills.
- Displayed the same saved icons on both preset-management rows and compact bank
  Presets buttons, following presets 1–9 and 10–18 when switching pages.
- Centred compact icons within a 24 × 24 area while preserving their aspect ratio;
  retained native number text for page detection and restored number colour on cleanup.
- Used explicit compact sprite IDs outside native category 0 and refreshed their
  sibling render order to prevent icons disappearing during bank/page redraws.
- Applied explicit sprite IDs and sibling render-order refresh to management-row
  icons as well, so switching preset selections does not leave them behind native backgrounds.
- Added a reusable Skills icon picker with selection highlighting and skill-name labels.
- Icons preview immediately in the editor and commit with names and colours on **Save**.
- Added icon reset controls; full **Reset** stages all defaults, including the preset number.
- Icon and colour pickers are mutually exclusive and follow the editor's overlay positioning.
- Stored stable icon keys per character; existing names and colours require no migration.
- Included icons in native preset swaps and best-effort grouped-save recovery.
- Restored native numbers on reset, unavailable resources, rendering failure, and shutdown;
  removed plugin-owned sprites without changing native row interactions or BoB's icon.
- Added a font-independent dropdown arrow and a small bank-icon inset for clearer spacing.
- Removed temporary asset-inspection tools and expanded mocked regression coverage.

## 0.6.0 - 2026-10-27

- Preset names and colours are now edited only in the bank via **Customize preset**.
- Simplified settings and ribbon panels to dropdown visibility and editor guidance.
- Added a preset preview with staged names, colours, and bank icons.
- Replaced the colour picker with a smooth canvas and instant previews.
- Made the picker draggable and prevented clicks passing through it.
- Replaced picker buttons with reset icons beside each colour swatch.
- Added best-effort recovery for failed customisation saves and swaps.
- Refactored editor layout, shared controls, and bank IDs.

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
