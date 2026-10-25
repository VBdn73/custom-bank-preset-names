-- Keep the embedded editor and its popup host sized together.
local layout = {
    width = 336,
    height = 294,
    compactHeight = 226,
    titleHeight = 32,
    padding = 8,
    textHeight = 28,
    noteHeight = 18,
    fieldHeight = 32,
    buttonHeight = 30,
    buttonGap = 20,
    dropdownVisibleEntries = 8,
    rows = {
        title = 8,
        selector = 48,
        nameLabel = 90,
        input = 122,
        colourLabel = 166,
        colourInput = 198,
        colourStatus = 270,
        colourButtons = 238,
        buttons = 166,
        status = 198,
        storageNote = 226,
        scopeNotes = 246,
    },
    noteSpacing = 20,
    popupPadding = 8,
    popupHeaderHeight = 36,
    popupBottomPadding = 12,
    popupBorderInset = 1,
    popupTitleBarInset = 4,
    popupTitleBarHeight = 30,
    popupTitleX = 12,
    popupTitleY = 7,
    popupTitleHeight = 26,
    popupCloseSize = 22,
}

layout.controlWidth = layout.width - layout.padding * 2
layout.buttonWidth = (layout.controlWidth - layout.buttonGap) / 2
layout.resetX = layout.padding + layout.buttonWidth + layout.buttonGap
layout.bodyHeight = layout.height - layout.titleHeight
layout.compactBodyHeight = layout.compactHeight - layout.titleHeight
layout.popupWidth = layout.width + layout.popupPadding * 2
layout.popupHeight = layout.popupHeaderHeight + layout.bodyHeight + layout.popupBottomPadding
layout.compactPopupHeight = layout.popupHeaderHeight + layout.compactBodyHeight + layout.popupBottomPadding
layout.colourHeight = 64

return layout
