-- Take a snapshot when the picker opens. No inventory actions are performed.
local catalogue = require("presets/icon_catalogue")
local backpack = {}

function backpack.category()
    local category = { key = "backpack", name = "Bag", entries = {}, showWhenEmpty = true,
        emptyMessage = "Add items to Bag to use as icons." }
    local ok = pcall(function()
        assert(Inventory and config and config.Inv and config.Inv.INV)
        local inventory = Inventory.Find(config.Inv.INV)
        assert(inventory and inventory.isValid)
        local slots = inventory:GetSlots()
        assert(type(slots) == "table")
        local indices = {}
        for index in pairs(slots) do
            if type(index) == "number" then indices[#indices + 1] = index end
        end
        table.sort(indices)
        local seen = {}
        for _, index in ipairs(indices) do
            local slot = slots[index]
            local objectID = slot.obj and slot.obj.id
            if type(objectID) == "number" and objectID > 0 and objectID <= 2147483647
                and objectID % 1 == 0 then
                local key = "item:" .. string.format("%.0f", objectID)
                if not seen[key] then
                    seen[key] = true
                    local entry = catalogue.get(key)
                    entry.name = catalogue.objectName(slot.obj) or entry.name
                    category.entries[#category.entries + 1] = entry
                end
            end
        end
    end)
    if not ok then
        category.entries = {}
        category.emptyMessage = "Bag unavailable; reopen picker to retry."
    end
    return category
end

function backpack.categories()
    local categories = {}
    for _, category in ipairs(catalogue.categories) do categories[#categories + 1] = category end
    categories[#categories + 1] = backpack.category()
    return categories
end

return backpack
