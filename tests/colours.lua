local test = require("tests.test_helper")

test.case("Colours persist independently per slot, kind, and character", function()
    local context, db = "first", {}
    local previous = package.loaded["presets/names"]
    package.loaded["presets/names"] = { getContext = function() return context end }
    PersistentDB = {
        GetString = function(_, key) return db[key] end,
        SetString = function(_, key, value) db[key] = value end,
    }
    local colours = dofile("presets/colours.lua")
    package.loaded["presets/names"] = previous
    test.equal(colours.save(1, "background", "green"), true)
    test.equal(colours.save(1, "text", "red"), true)
    test.equal(colours.rgba(1, "background"), 0x008000FF)
    test.equal(colours.rgba(1, "text"), 0xFF0000FF)
    test.equal(colours.get(2, "text"), "")
    context = "second"
    test.equal(colours.get(1, "text"), "")
    context = "first"
    test.equal(colours.get(1, "text"), "red")
    test.equal(colours.save(1, "text", ""), true)
    test.equal(colours.rgba(1, "text"), nil)
    test.equal(colours.get(1, "background"), "green")
    test.equal(colours.save(19, "text", "red"), false)
    test.equal(colours.save(1, "text", "purple"), false)
    PersistentDB.SetString = function() return false end
    test.equal(colours.save(1, "background", "blue"), false)
    test.equal(colours.get(1, "background"), "green")
    context = nil
    test.equal(colours.save(1, "text", "red"), false)
    test.equal(colours.get(1, "background"), "")
end)

test.case("Appearance applies, resets, reacquires, and safely restores colours", function()
    local component = { type = 1, rgba = 0x222222FF }
    ui = { ComponentType = { RECTANGLE = 1 }, Interfaces = {
        GetComponent = function() return component end,
    } }
    local appearance = dofile("bank/appearance.lua")
    local bindings = { { slot = 1, staticID = 265, dynamicID = 1, kind = "RECTANGLE", colourKind = "background" } }
    local value = 0x008000FF
    local colours = { rgba = function() return value end }
    appearance.update(bindings, colours)
    appearance.update(bindings, colours)
    test.equal(component.rgba, value)
    value = nil
    appearance.update(bindings, colours)
    test.equal(component.rgba, 0x222222FF)
    value = 0xFF0000FF
    appearance.update(bindings, colours)
    component.rgba = 0xFFFFFFFF
    appearance.restore(bindings)
    test.equal(component.rgba, 0xFFFFFFFF)
    component = { type = 1, rgba = 0x111111FF }
    appearance.update(bindings, colours)
    appearance.restore(bindings)
    test.equal(component.rgba, 0x111111FF)
    component.isRestricted = true
    appearance.update(bindings, colours)
    test.equal(component.rgba, 0x111111FF)
end)
