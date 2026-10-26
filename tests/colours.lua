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
    test.equal(colours.save(1, "background", "#008000"), true)
    test.equal(colours.save(1, "text", "#FF0000"), true)
    test.equal(colours.rgba(1, "background"), 0x008000FF)
    test.equal(colours.rgba(1, "text"), 0xFF0000FF)
    test.equal(colours.get(2, "text"), "")
    context = "second"
    test.equal(colours.get(1, "text"), "")
    context = "first"
    test.equal(colours.get(1, "text"), "#FF0000")
    test.equal(colours.save(1, "text", ""), true)
    test.equal(colours.rgba(1, "text"), nil)
    test.equal(colours.get(1, "background"), "#008000")
    test.equal(colours.save(19, "text", "#FF0000"), false)
    test.equal(colours.save(1, "text", "not-a-colour"), false)
    test.equal(colours.save(3, "text", "#38a4ff"), true)
    test.equal(colours.get(3, "text"), "#38A4FF")
    test.equal(colours.rgba(3, "text"), 0x38A4FFFF)
    for _, invalid in ipairs({ "#FFF", "#12345678", "123456", "#GG0000", " #123456" }) do
        test.equal(colours.save(3, "text", invalid), false)
    end
    context = "second"
    test.equal(colours.get(3, "text"), "")
    context = "first"
    test.equal(colours.get(3, "text"), "#38A4FF", "Custom colours survive a storage reread")
    test.equal(colours.save(3, "text", "#000000"), true)
    test.equal(colours.rgba(3, "text"), 0x000000FF)
    test.equal(colours.save(3, "text", "#FFFFFF"), true)
    test.equal(colours.rgba(3, "text"), 0xFFFFFFFF)
    PersistentDB.SetString = function() return false end
    test.equal(colours.save(1, "background", "#0080FF"), false)
    test.equal(colours.get(1, "background"), "#008000")
    context = nil
    test.equal(colours.save(1, "text", "#FF0000"), false)
    test.equal(colours.get(1, "background"), "")
end)

test.case("Only hex colours and Default are accepted; invalid stored values fall back safely", function()
    local previous = package.loaded["presets/names"]
    package.loaded["presets/names"] = { getContext = function() return "character" end }
    local stored, writes = "obsolete-name", 0
    PersistentDB = {
        GetString = function() return stored end,
        SetString = function(_, _, value) stored = value; writes = writes + 1 end,
    }
    local colours = dofile("presets/colours.lua")
    package.loaded["presets/names"] = previous
    test.equal(colours.get(1, "text"), "")
    test.equal(colours.rgba(1, "text"), nil)
    for _, invalid in ipairs({ "obsolete-name", "#FFF", 123, false }) do
        test.equal(colours.save(1, "text", invalid), false)
    end
    test.equal(colours.save(1, "text", nil), false)
    test.equal(writes, 0, "Reject invalid values without overwriting storage")
    test.equal(colours.save(1, "text", "#123abc"), true)
    test.equal(colours.get(1, "text"), "#123ABC")
    test.equal(colours.rgba(1, "text"), 0x123ABCFF)
    test.equal(colours.save(1, "text", ""), true)
    test.equal(colours.rgba(1, "text"), nil)
end)

test.case("HSV conversions preserve primary, grey and arbitrary colours", function()
    local value = require("presets/colour_value")
    for _, hex in ipairs({ "#FF0000", "#00FF00", "#0000FF", "#000000", "#FFFFFF", "#808080", "#38A4FF" }) do
        test.equal(value.fromHSV(value.toHSV(hex)), hex)
    end
    test.equal(value.normalize(false), nil)
    test.equal(value.rgba("bad"), nil)
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
    test.equal(appearance.original(bindings, 1, "background"), 0x222222FF,
        "Default preview reads the original, not the saved customisation")
    test.equal(component.rgba, value, "Reading defaults does not alter the bank")
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
    test.equal(appearance.original(bindings, 1, "background"), nil)
    appearance.update(bindings, colours)
    test.equal(component.rgba, 0x111111FF)
end)
