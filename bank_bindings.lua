-- Bank preset rows contain three dynamic labels: number, name, and extra text.
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
