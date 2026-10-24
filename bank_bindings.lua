-- Bank preset rows contain three dynamic labels: number, name, and extra text.
-- Captured rows 6-9 have name IDs 16, 19, 22, 25. Row 7 was tested in-client.
-- Extend that row layout to all 18 slots; recheck after bank UI asset changes.
local presetCount = 18
local labels = {}
for slot = 1, presetCount do
    labels[slot] = {
        slot = slot,
        interfaceID = 517,
        staticID = 266,
        categoryID = 0,
        dynamicID = (slot - 1) * 3 + 1,
    }
end

return {
    presetCount = presetCount,
    labels = labels,
}
