local test = require("tests.test_helper")

test.case("BoB mappings are explicit and cannot participate in numbered swaps", function()
    local bindings = dofile("bank/bindings.lua")
    local slots = require("presets/slots")
    test.equal(slots.valid(19), false)
    test.equal(slots.customisable(19), true)
    test.equal(slots.customisable(20), false)
    test.equal(bindings.presetCount, 18)
    test.equal(bindings.labels[19].dynamicID, 55)
    test.equal(bindings.appearance[37].dynamicID, 19)
    test.equal(bindings.appearance[37].staticID, 265)
    local writes = 0
    local service = require("presets/customisations").new({
        getContext = function() return "character" end,
        normalize = function(value) return value end,
        get = function() return "" end,
        save = function() writes = writes + 1; return true end,
    })
    test.equal(service.save(19, { name = "Pack yak" }), true)
    test.equal(writes, 1)
    test.equal(service.swap(18, 19), false)
    test.equal(writes, 1)
end)

test.case("BoB native hit target opens its own editor but is not a drag-swap destination", function()
    local bindings = dofile("bank/bindings.lua")
    local bob = { interfaceID = 517, staticID = 267, categoryID = 0, dynamicID = 19,
        visibleGlobal = true, xyGlobal = { x = 723, y = 827 }, height = 30 }
    ui = { Interfaces = { GetComponent = function(_, _, staticID, _, dynamicID)
        if staticID == 266 and dynamicID == 55 then
            return { visibleGlobal = true, xyGlobal = { x = 738, y = 827 }, height = 30 }
        end
    end } }
    local reorder = require("bank/reorder")
    test.equal(reorder.slotOf(bob, 18), nil)
    test.equal(reorder.slotOf(bob, 19), 19)
    local menu = dofile("bank/menu.lua")
    test.equal(menu.selectedSlot({ verbText = "Select", componentData = { component = bob } }, bindings.labels), 19)
    local chosen
    MiniMenuActionType = { CANCEL = 0 }
    local native = { entries = { { verbText = "Select", componentData = { component = bob } } },
        Add = function(_, _, _, slot) chosen = slot end }
    menu.add(native, bindings.labels, function() end)
    test.equal(chosen, 19)
end)

test.case("BoB preview omits preset number and inventory/equipment icons", function()
    local preview = dofile("bank/preview.lua")
    ui = { Interfaces = { GetComponent = function() return nil end } }
    id = { Sprite = { RS3_ICON_BANK_PRESET_BEAST_OF_BURDEN = 123 } }
    test.equal(preview.number(19), nil)
    test.equal(preview.decoration(19, 1), nil)
    test.equal(preview.decoration(19, 2), nil)
    test.equal(preview.decoration(19, 3).sprite, 123)
end)
