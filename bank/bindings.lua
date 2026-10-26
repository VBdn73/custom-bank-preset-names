-- Bank preset rows contain three dynamic labels: number, name, and extra text.
local presetCount = require("presets/slots").count
local labelsPerPreset = 3
local nameLabelOffset = 1
local labels = {}
local appearance = {}

for slot = 1, presetCount do
    appearance[#appearance + 1] = { slot = slot, staticID = 265, dynamicID = slot,
        kind = "RECTANGLE", colourKind = "background" }
    appearance[#appearance + 1] = { slot = slot, staticID = 266,
        dynamicID = (slot - 1) * labelsPerPreset + nameLabelOffset, kind = "LABEL", colourKind = "text" }
    labels[slot] = {
        slot = slot,
        interfaceID = 517,
        staticID = 266,
        categoryID = 0,
        -- Dynamic IDs are zero-based; the name is the second label in each row.
        dynamicID = (slot - 1) * labelsPerPreset + nameLabelOffset,
    }
end

return {
    presetCount = presetCount,
    labels = labels,
    appearance = appearance,
}
