-- Bank preset rows contain three dynamic labels: number, name, and extra text.
local presetCount = require("presets/slots").count
local bankIds = require("bank/ids")
local labelsPerPreset = bankIds.labelsPerPreset
local nameLabelOffset = bankIds.nameLabelOffset
local labels = {}
local appearance = {}

for slot = 1, presetCount do
    appearance[#appearance + 1] = { slot = slot, staticID = bankIds.presetBackground, dynamicID = slot,
        kind = "RECTANGLE", colourKind = "background" }
    appearance[#appearance + 1] = { slot = slot, staticID = bankIds.presetLabel,
        dynamicID = (slot - 1) * labelsPerPreset + nameLabelOffset, kind = "LABEL", colourKind = "text" }
    labels[slot] = {
        slot = slot,
        interfaceID = bankIds.interface,
        staticID = bankIds.presetLabel,
        categoryID = bankIds.category,
        -- Dynamic IDs are zero-based; the name is the second label in each row.
        dynamicID = (slot - 1) * labelsPerPreset + nameLabelOffset,
    }
end

return {
    presetCount = presetCount,
    labels = labels,
    appearance = appearance,
}
