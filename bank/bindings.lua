-- Bank preset rows contain three dynamic labels: number, name, and extra text.
local presetCount = require("presets/slots").count
local bankIds = require("bank/ids")
local labelsPerPreset = bankIds.labelsPerPreset
local nameLabelOffset = bankIds.nameLabelOffset
local labels = {}
local appearance = {}
local numbers = {}

for slot = 1, presetCount do
    numbers[slot] = { slot = slot, interfaceID = bankIds.interface,
        staticID = bankIds.presetLabel, categoryID = bankIds.category,
        dynamicID = (slot - 1) * labelsPerPreset + bankIds.numberLabelOffset }
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

local bob = require("presets/slots").bob
labels[bob] = { slot = bob, interfaceID = bankIds.interface,
    staticID = bankIds.presetLabel, categoryID = bankIds.category, dynamicID = bankIds.bobName }
appearance[#appearance + 1] = { slot = bob, staticID = bankIds.presetBackground,
    dynamicID = bankIds.bobBackground, kind = "RECTANGLE", colourKind = "background" }
appearance[#appearance + 1] = { slot = bob, staticID = bankIds.presetLabel,
    dynamicID = bankIds.bobName, kind = "LABEL", colourKind = "text" }

return {
    presetCount = presetCount,
    entryCount = #labels,
    labels = labels,
    appearance = appearance,
    numbers = numbers,
}
