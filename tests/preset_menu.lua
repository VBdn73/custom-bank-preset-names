local test = require("tests.test_helper")
local menu = require("bank/menu")
local bindings = require("bank/bindings")
MiniMenuActionType = { CANCEL = 1006 }
local hoveredLabels = {}
ui = { Interfaces = { GetComponent = function(_, _, _, _, dynamicID)
    return hoveredLabels[dynamicID]
end } }

local function entry(slot)
    local binding = bindings.labels[slot]
    return { componentData = { component = {
        interfaceID = binding.interfaceID, staticID = binding.staticID,
        categoryID = binding.categoryID, dynamicID = binding.dynamicID, visibleGlobal = true,
    } } }
end

local function fixture(entries)
    local m = { entries = entries, entryCount = #entries, added = 0 }
    function m:Add(label, action, slot)
        self.added = self.added + 1
        -- Model the client's low-priority insertion while leaving its exposed
        -- count as the pre-Add snapshot. Do not assume Add refreshes metadata.
        table.insert(self.entries, 1, { label = label, action = action, slot = slot })
    end
    function m:Swap(a, b)
        test.equal(b, a + 1, "Reordering uses adjacent swaps to preserve native order")
        self.entries[a], self.entries[b] = self.entries[b], self.entries[a]
    end
    return m
end

test.case("Preset menu adds one edit action and preserves native ordering and left click", function()
    local cancel, reset, load, select = {}, entry(18), entry(18), entry(18)
    cancel.actionType = MiniMenuActionType.CANCEL
    local m = fixture({ cancel, reset, load, select })
    local opened
    menu.add(m, bindings.labels, function(slot) opened = slot end)
    test.equal(m.added, 1)
    test.equal(opened, nil, "Building a menu must not open the editor")
    test.equal(m.entries[1], cancel)
    test.equal(m.entries[2].label, "Customize preset")
    test.equal(m.entries[3], reset)
    test.equal(m.entries[4], load)
    test.equal(m.entries[5], select)
    m.entries[2].action(m.entries[2].slot)
    test.equal(opened, 18)
end)

test.case("Menu captures each preset independently of the game's selected preset", function()
    for slot = 1, 18 do
        local m, opened = fixture({ {}, entry(slot) })
        menu.add(m, bindings.labels, function(value) opened = value end)
        m.entries[1].action(m.entries[1].slot)
        test.equal(opened, slot)
    end
end)

test.case("Adding an edit action never swaps or removes Select even with different Add metadata", function()
    local select, load, reset, cancel = entry(1), entry(1), entry(1), { actionType = MiniMenuActionType.CANCEL }
    select.verbText, load.verbText, reset.verbText = "Select", "Load", "Reset"
    local m = fixture({ cancel, reset, load, select })
    function m:Add(label, action, slot)
        -- Also cover an API exposing an appended entry and refreshed count.
        self.entries[#self.entries + 1] = { label = label, action = action, slot = slot }
        self.entryCount = #self.entries
    end
    menu.add(m, bindings.labels, function() end)
    test.equal(m.entries[1], cancel)
    test.equal(m.entries[2].label, "Customize preset")
    test.equal(m.entries[3], reset)
    test.equal(m.entries[4], load)
    test.equal(m.entries[5], select)
end)

test.case("Customize preset sits below Reset and above client configuration actions", function()
    local cancel = { actionType = MiniMenuActionType.CANCEL }
    local configure = { verbText = "Configure Menu Entries" }
    local shift = { verbText = "Set shift click" }
    local default = { verbText = "Set default click" }
    local reset, load, select = entry(1), entry(1), entry(1)
    reset.verbText = "Reset"
    local m = fixture({ cancel, configure, shift, default, reset, load, select })
    menu.add(m, bindings.labels, function() end)
    test.equal(m.entries[1], cancel)
    test.equal(m.entries[2], configure)
    test.equal(m.entries[3], shift)
    test.equal(m.entries[4], default)
    test.equal(m.entries[5].label, "Customize preset")
    test.equal(m.entries[6], reset)
    test.equal(m.entries[7], load)
    test.equal(m.entries[8], select)
end)

test.case("Menu ignores unrelated, restricted and missing components", function()
    local wrongInterface, wrongStatic, wrongCategory, numberLabel, restricted =
        entry(1), entry(1), entry(1), entry(1), entry(1)
    wrongInterface.componentData.component.interfaceID = 1
    wrongStatic.componentData.component.staticID = 1
    wrongCategory.componentData.component.categoryID = 1
    numberLabel.componentData.component.dynamicID = 0
    restricted.componentData.component.isRestricted = true
    local m = fixture({ {}, { componentData = {} }, wrongInterface, wrongStatic,
        wrongCategory, numberLabel, restricted })
    menu.add(m, bindings.labels, function() error("Should not open") end)
    test.equal(m.added, 0)
end)

test.case("Native row hit targets use the hovered name label to identify the slot", function()
    hoveredLabels[52] = { visibleGlobal = true, isMouseOver = true }
    local row = { componentData = { component = { interfaceID = 517, staticID = 999,
        categoryID = 0, dynamicID = 17 } } }
    local m, opened = fixture({ {}, row, row, row })
    menu.add(m, bindings.labels, function(slot) opened = slot end)
    test.equal(m.added, 1)
    m.entries[1].action(m.entries[1].slot)
    test.equal(opened, 18)
    hoveredLabels = {}
end)

test.case("Hidden or restricted hovered labels and non-bank menus do not get edit actions", function()
    for _, label in ipairs({
        { visibleGlobal = false, isMouseOver = true },
        { visibleGlobal = true, isMouseOver = true, isRestricted = true },
        { visibleGlobal = true, isMouseOver = false },
    }) do
        hoveredLabels[1] = label
        local m = fixture({ { componentData = { component = { interfaceID = 517 } } } })
        menu.add(m, bindings.labels, function() end)
        test.equal(m.added, 0)
    end
    hoveredLabels[1] = { visibleGlobal = true, isMouseOver = true }
    local m = fixture({ { componentData = { component = { interfaceID = 1 } } } })
    menu.add(m, bindings.labels, function() end)
    test.equal(m.added, 0)
    hoveredLabels = {}
end)

test.case("Hidden direct labels and restricted row targets do not get edit actions", function()
    local hidden = entry(1)
    hidden.componentData.component.visibleGlobal = false
    local m = fixture({ hidden })
    menu.add(m, bindings.labels, function() end)
    test.equal(m.added, 0)

    hoveredLabels[1] = { visibleGlobal = true, isMouseOver = true }
    local restrictedRow = { componentData = { component = {
        interfaceID = 517, staticID = 999, isRestricted = true,
    } } }
    m = fixture({ restrictedRow })
    menu.add(m, bindings.labels, function() end)
    test.equal(m.added, 0)
    hoveredLabels = {}
end)
