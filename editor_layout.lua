-- Keep the embedded editor and its popup host sized together.
local layout = {
    width = 336,
    height = 294,
    titleHeight = 32,
    popupPadding = 8,
    popupHeaderHeight = 36,
    popupBottomPadding = 12,
}

layout.bodyHeight = layout.height - layout.titleHeight
layout.popupWidth = layout.width + layout.popupPadding * 2
layout.popupHeight = layout.popupHeaderHeight + layout.bodyHeight + layout.popupBottomPadding

return layout
