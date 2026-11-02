local test = require("tests.test_helper")
local catalogue = require("presets/icon_catalogue")

local function fixture(slots, valid)
    local env = setmetatable({
        config = { Inv = { INV = 123 } },
        Inventory = { Find = function(id)
            test.equal(id, 123)
            return { isValid = valid, GetSlots = function() return slots end }
        end },
    }, { __index = _G })
    return assert(loadfile("presets/backpack_icons.lua", "t", env))(), env
end

test.case("Backpack snapshot exposes distinct valid item IDs without modifying the catalogue", function()
    local backpack = fixture({ { obj = { id = 31725 } }, {}, { obj = { id = 31725 } },
        { obj = { id = 1959 } }, { obj = { id = -1 } } }, true)
    local categories = backpack.categories()
    test.equal(#categories, 5)
    test.equal(#catalogue.categories, 4)
    local entries = categories[5].entries
    test.equal(#entries, 2)
    test.equal(entries[1].key, "item:31725")
    test.equal(entries[2].key, "item:1959")
    test.equal(catalogue.resolve(entries[1].key), 31725)
end)

test.case("Backpack unavailable and empty snapshots provide distinct messages", function()
    local backpack, env = fixture({}, true)
    test.equal(backpack.category().emptyMessage, "Backpack is empty.")
    env.Inventory.Find = function() return nil end
    test.equal(backpack.category().emptyMessage, "Backpack unavailable.")
    env.Inventory.Find = function() error("unavailable") end
    test.equal(backpack.category().emptyMessage, "Backpack unavailable.")
end)

test.case("Backpack snapshot supports sparse and zero-based slots", function()
    local backpack = fixture({ [0] = { obj = { id = 1 } }, [3] = { obj = { id = 2 } } }, true)
    local entries = backpack.category().entries
    test.equal(#entries, 2)
    test.equal(entries[1].key, "item:1")
    test.equal(entries[2].key, "item:2")
end)

test.case("Backpack displays item names with a safe fallback per item", function()
    local missing = setmetatable({ id = 2 }, { __index = function() error("name unavailable") end })
    local backpack = fixture({ { obj = { id = 1, name = "Noxious scythe" } },
        { obj = missing }, { obj = { id = 3, name = "" } } }, true)
    local entries = backpack.category().entries
    test.equal(#entries, 3)
    test.equal(entries[1].name, "Noxious scythe")
    test.equal(entries[2].name, "Item 2")
    test.equal(entries[3].name, "Item 3")
end)

test.case("Saved item display names resolve by ID without the backpack", function()
    local env = setmetatable({ config = { Obj = { FromID = function(id)
        if id == 31725 then return { name = "Noxious scythe" } end
        error("missing object")
    end } } }, { __index = _G })
    local isolated = assert(loadfile("presets/icon_catalogue.lua", "t", env))()
    test.equal(isolated.displayName("item:31725"), "Noxious scythe")
    test.equal(isolated.displayName("item:42"), "Item 42")
    test.equal(isolated.displayName("skills:farming"), "Farming")
    test.equal(isolated.displayName(""), nil)
    env.config = false
    test.equal(isolated.displayName("item:31725"), "Item 31725")
end)

test.case("Dynamic item IDs resolve independently and reject malformed keys", function()
    local entry = catalogue.get("item:31725")
    test.equal(entry.objectID, 31725)
    test.equal(entry.name, "Item 31725")
    for _, key in ipairs({ "item:0", "item:01", "item:-1", "item:1.0", "item:2147483648", "item:abc" }) do
        test.equal(catalogue.get(key), nil)
    end
end)
