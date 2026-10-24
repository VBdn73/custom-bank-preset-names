-- Bank preset rows contain three dynamic labels: number, name, and extra text.
local presetCount = 18
local labelsPerPreset = 3
local nameLabelOffset = 1
local labels = {}

for slot = 1, presetCount do
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
}
