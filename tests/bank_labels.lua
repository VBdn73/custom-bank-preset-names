local test = require("tests.test_helper")

local function createFixture()
    local f = {
        label = { type = 1, content = "Combat" }, customName = "Bossing",
        bindings = { { slot = 1, interfaceID = 517, staticID = 266 } },
    }
    ui = {
        ComponentType = { LABEL = 1 },
        Interfaces = { GetComponent = function() return f.label end },
    }
    f.names = { get = function() return f.customName end }
    f.bank = dofile("bank/labels.lua")
    function f:update() self.bank.update(self.bindings, self.names) end
    function f:restore() self.bank.restore(self.bindings) end
    return f
end

test.case("Swapping with an uncustomised preset moves the cached predefined fallback immediately", function()
    local labels = { [9] = { type = 1, content = "Farming" },
        [10] = { type = 1, content = "10" } }
    local bindings = {
        { slot = 9, interfaceID = 517, staticID = 266, categoryID = 0, dynamicID = 25 },
        { slot = 10, interfaceID = 517, staticID = 266, categoryID = 0, dynamicID = 28 },
    }
    ui = { ComponentType = { LABEL = 1 }, Interfaces = {
        GetComponent = function(_, _, _, _, dynamicID)
            return labels[dynamicID == 25 and 9 or 10]
        end,
    } }
    local custom = { [9] = "Dragonkin Laboratory" }
    local names = { get = function(slot) return custom[slot] end }
    local bank = dofile("bank/labels.lua")
    bank.update(bindings, names)
    custom[9], custom[10] = custom[10], custom[9]
    bank.swapOriginals(bindings, 9, 10)
    bank.update(bindings, names)
    test.equal(labels[9].content, "10", "Never restore the old slot's Farming fallback")
    test.equal(labels[10].content, "Dragonkin Laboratory")
    bank.update(bindings, names)
    test.equal(labels[9].content, "10")
    -- The eventual native refresh agrees with the swapped fallback.
    labels[9].content, labels[10].content = "10", "Farming"
    bank.update(bindings, names)
    bank.restore(bindings)
    test.equal(labels[9].content, "10")
    test.equal(labels[10].content, "Farming")
end)

test.case("Labels apply custom names and reset to predefined text", function()
    local f = createFixture()
    f:update()
    test.equal(f.label.content, "Bossing")
    f:update() -- Repeated updates must not mistake our own text for original text.
    f.customName = nil
    f:update()
    test.equal(f.label.content, "Combat")
end)

test.case("Restoration uses the latest predefined text supplied by the game", function()
    local f = createFixture()
    f:update()
    f.label.content = "New predefined"
    f:update()
    test.equal(f.label.content, "Bossing")
    f:restore()
    test.equal(f.label.content, "New predefined")
end)

test.case("Shutdown never overwrites a newer game-side text change", function()
    local f = createFixture()
    f:update()
    f.label.content = "Changed just before shutdown"
    f:restore()
    test.equal(f.label.content, "Changed just before shutdown")
end)

test.case("A reopened bank captures its own original text", function()
    local f = createFixture()
    f:update()
    f.label = nil
    f:update()
    f.label = { type = 1, content = "Reopened" }
    f:update()
    test.equal(f.label.content, "Bossing")
    f:restore()
    test.equal(f.label.content, "Reopened")
end)

test.case("Replacing a component without closing the bank discards its old state", function()
    local f = createFixture()
    f:update()
    f.label = { type = 1, content = "Replacement" }
    f:update()
    f:restore()
    test.equal(f.label.content, "Replacement")
end)

for _, componentKind in ipairs({ "missing", "restricted", "not a label" }) do
    test.case("Updates skip components that are " .. componentKind, function()
        local f = createFixture()
        if componentKind == "missing" then
            f.label = nil
        elseif componentKind == "restricted" then
            f.label.isRestricted = true
        else
            f.label.type = 99
        end
        f:update()
        f:restore()
        if f.label then test.equal(f.label.content, "Combat") end
    end)
end

test.case("Shutdown skips missing, replaced, or non-label components", function()
    for _, replacement in ipairs({ false, { type = 1, content = "Replacement" },
        { type = 99, content = "Other control" } }) do
        local f = createFixture()
        f:update()
        f.label = replacement or nil
        f:restore()
        if replacement then
            test.equal(f.label.content, replacement.type == 1 and "Replacement" or "Other control")
        end
    end
end)

test.case("Restoration clears state and is safe to call twice", function()
    local f = createFixture()
    f:update()
    f:restore()
    f.label.content = "Later game text"
    f:restore()
    test.equal(f.label.content, "Later game text")
    f:update()
    f:restore()
    test.equal(f.label.content, "Later game text")
end)

test.case("Shutdown does not write to a tracked component whose type changed", function()
    local f = createFixture()
    f:update()
    f.label.type = 99
    f:restore()
    test.equal(f.label.content, "Bossing", "Non-label component is left untouched")
end)

test.case("Shutdown does not write to a tracked component that became restricted", function()
    local f = createFixture()
    f:update()
    f.label.isRestricted = true
    f:restore()
    test.equal(f.label.content, "Bossing", "Restricted component is left untouched")
    f.label.isRestricted = false
    f:restore()
    test.equal(f.label.content, "Bossing", "Skipped restoration clears tracked state")
end)

test.case("Updates stop writing when a tracked component becomes restricted", function()
    local f = createFixture()
    f:update()
    f.label.isRestricted = true
    f.label.content = "Locked preset"
    f:update()
    f:restore()
    test.equal(f.label.content, "Locked preset")
end)

test.case("Label updates and restoration write only text and never invoke component actions", function()
    local f = createFixture()
    -- A strict proxy rejects every non-text write and unexpected method lookup.
    -- This guards against visibility, geometry, and interaction changes without
    -- pretending that mocks can verify the real client's locked-slot behaviour.
    local properties = { type = 1, content = "Combat", isRestricted = false }
    local writes = 0
    f.label = setmetatable({}, {
        __index = function(_, key)
            if properties[key] == nil then error("Unexpected component access: " .. key) end
            return properties[key]
        end,
        __newindex = function(_, key, value)
            test.equal(key, "content", "Only label text may change")
            properties[key] = value
            writes = writes + 1
        end,
    })
    f:update()
    f:update()
    test.equal(writes, 1, "Unchanged names do not cause repeated writes")
    f:restore()
    test.equal(properties.content, "Combat")
    test.equal(writes, 2)
end)

test.case("Static bindings use the two-ID component lookup", function()
    local f = createFixture()
    ui.Interfaces.GetComponent = function(_, ...)
        test.equal(select("#", ...), 2, "Lookup argument count")
        local interfaceID, staticID = ...
        test.equal(interfaceID, 517)
        test.equal(staticID, 266)
        return f.label
    end
    f:update()
end)

test.case("All 18 dynamic bindings resolve, reset, and restore independently", function()
    local f = createFixture()
    local bindings = dofile("bank/bindings.lua")
    test.equal(bindings.presetCount, 18)
    test.equal(#bindings.labels, 18)
    local labels, customNames = {}, {}
    for slot, binding in ipairs(bindings.labels) do
        test.equal(binding.slot, slot)
        test.equal(binding.dynamicID, (slot - 1) * 3 + 1, "Name label offset")
        labels[binding.dynamicID] = { type = 1, content = "Predefined " .. slot }
        customNames[slot] = "Custom " .. slot
    end
    ui.Interfaces.GetComponent = function(_, interfaceID, staticID, categoryID, dynamicID)
        test.equal(interfaceID, 517)
        test.equal(staticID, 266)
        test.equal(categoryID, 0)
        return labels[dynamicID]
    end
    local names = { get = function(slot) return customNames[slot] end }
    f.bank.update(bindings.labels, names)
    for slot, binding in ipairs(bindings.labels) do
        test.equal(labels[binding.dynamicID].content, "Custom " .. slot)
    end
    customNames[18] = nil
    f.bank.update(bindings.labels, names)
    test.equal(labels[52].content, "Predefined 18")
    test.equal(labels[49].content, "Custom 17")
    f.bank.restore(bindings.labels)
    for slot, binding in ipairs(bindings.labels) do
        test.equal(labels[binding.dynamicID].content, "Predefined " .. slot)
    end
end)
