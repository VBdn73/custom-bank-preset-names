local test = require("tests.test_helper")

local function fixture()
    local component = { hidden = false }
    local environment = setmetatable({ require = function(path)
        if path == "bank/ids" then return require(path) end
        test.equal(path, "bank/preset_layout")
        return { update = function() end, restore = function() end }
    end, ui = { Interfaces = {
        GetComponent = function(_, interfaceID, staticID, categoryID)
            test.equal(interfaceID, 517)
            test.equal(staticID, 300)
            test.equal(categoryID, nil)
            return component
        end,
    } } }, { __index = _G })
    return assert(loadfile("bank/dropdown.lua", "t", environment))(), function(value) component = value end,
        component
end

test.case("Predefined dropdown stays untouched by default and restores on toggle", function()
    local dropdown, _, component = fixture()
    dropdown.update(false)
    test.equal(component.hidden, false)
    dropdown.update(true)
    test.equal(component.hidden, true)
    component.hidden = false -- The bank can rebuild/reset the dropdown.
    dropdown.update(true)
    test.equal(component.hidden, true)
    dropdown.update(false)
    test.equal(component.hidden, false)
end)

test.case("Compact background preference defaults on and persists without changing dropdown settings", function()
    local values = {}
    local environment = setmetatable({ PersistentDB = {
        GetString = function(_, key) return values[key] end,
        SetString = function(_, key, value) values[key] = value end,
    } }, { __index = _G })
    local function loadSettings()
        return assert(loadfile("presets/settings.lua", "t", environment))()
    end
    local settings = loadSettings()
    test.equal(settings.showCompactBackgrounds(), true)
    test.equal(settings.setShowCompactBackgrounds(false), true)
    settings = loadSettings()
    test.equal(settings.showCompactBackgrounds(), false)
    test.equal(settings.hidePredefinedDropdown(), false)
    test.equal(settings.setShowCompactBackgrounds(true), true)
    test.equal(loadSettings().showCompactBackgrounds(), true)
    environment.PersistentDB.SetString = function() return false end
    test.equal(settings.setShowCompactBackgrounds(false), false)
    test.equal(settings.showCompactBackgrounds(), true)
end)

test.case("Dropdown restoration preserves originally hidden state", function()
    local dropdown, _, component = fixture()
    component.hidden = true
    dropdown.update(true)
    dropdown.restore()
    test.equal(component.hidden, true)
end)

test.case("Dropdown skips missing/restricted components and reacquires replacements", function()
    local dropdown, replace, original = fixture()
    dropdown.update(true)
    replace(nil)
    dropdown.update(true)
    local restricted = { hidden = false, isRestricted = true }
    replace(restricted)
    dropdown.update(true)
    test.equal(restricted.hidden, false)
    local replacement = { hidden = false }
    replace(replacement)
    dropdown.update(true)
    test.equal(replacement.hidden, true)
    dropdown.restore()
    test.equal(replacement.hidden, false)
    test.equal(original.hidden, true, "Do not write to a disposed component")
end)

test.case("Dropdown preference defaults visible and persists both checkbox states", function()
    local values = {}
    local environment = setmetatable({ PersistentDB = {
        GetString = function(_, key) return values[key] end,
        SetString = function(_, key, value) values[key] = value end,
    } }, { __index = _G })
    local function loadSettings()
        return assert(loadfile("presets/settings.lua", "t", environment))()
    end
    local settings = loadSettings()
    test.equal(settings.hidePredefinedDropdown(), false)
    test.equal(settings.setHidePredefinedDropdown(true), true)
    settings = loadSettings()
    test.equal(settings.hidePredefinedDropdown(), true)
    test.equal(settings.setHidePredefinedDropdown(false), true)
    test.equal(settings.hidePredefinedDropdown(), false)
    environment.PersistentDB.SetString = function() return false end
    test.equal(settings.setHidePredefinedDropdown(true), false)
    test.equal(settings.hidePredefinedDropdown(), false)
end)
