local test = require("tests.test_helper")
local factory = require("presets/customisations")
local function fixture(failAt, mode, rollbackFails, withIcons)
    local data = { [1] = { name = "One", background = "", text = "#112233", icon = "skills:farming" },
        [2] = { name = "Two", background = "#445566", text = "", icon = "skills:necromancy" },
        [19] = { name = "BoB", background = "", text = "" } }
    local calls = 0
    local function save(slot, kind, value)
        calls = calls + 1
        data[slot][kind] = value -- Even a failed write may have persisted.
        if calls == failAt or (rollbackFails and calls == failAt + 1) then
            if mode == "throw" then error("injected storage exception") end
            return false, "injected verification failure"
        end
        return true
    end
    local names = { normalize = dofile("presets/names.lua").normalize,
        getContext = function() return "character" end,
        get = function(slot) return data[slot].name end,
        save = function(slot, value) return save(slot, "name", value) end }
    local colours = { get = function(slot, kind) return data[slot][kind] end,
        save = save }
    local icons = withIcons and { normalize = dofile("presets/icons.lua").normalize,
        get = function(slot) return data[slot].icon end,
        save = function(slot, value)
            test.equal(slot == 19, false, "Never write an icon for BoB")
            return save(slot, "icon", value)
        end }
    return factory.new(names, colours, icons), data, function() return calls end
end

for _, operation in ipairs({ "save", "swap" }) do
    for _, mode in ipairs({ "reject", "throw" }) do
        for index = 1, operation == "swap" and 6 or 3 do
            test.case(operation .. " recovers " .. mode .. " at write " .. index, function()
                local service, data = fixture(index, mode)
                local ok, _, result
                if operation == "swap" then ok, _, result = service.swap(1, 2)
                else ok, _, result = service.save(1, { name = "New", background = "#ABCDEF", text = "" }) end
                test.equal(ok, false)
                test.equal(result.status, "recovered")
                test.equal(data[1].name, "One")
                test.equal(data[1].background, "")
                test.equal(data[1].text, "#112233")
                test.equal(data[2].name, "Two")
                test.equal(data[2].background, "#445566")
                test.equal(data[2].text, "")
            end)
        end
    end
end

for _, mode in ipairs({ "reject", "throw" }) do
    test.case("Recovery failures remain visible and recovery continues: " .. mode, function()
        local service, data, calls = fixture(3, mode, true)
        local ok, message, result = service.save(1, { name = "New", background = "#ABCDEF", text = "" })
        test.equal(ok, false)
        test.equal(result.status, "recovery_failed")
        test.equal(message:find("recovery incomplete", 1, true) ~= nil, true)
        test.equal(#result.details, 2)
        test.equal(calls(), 6)
        test.equal(data[1].name, "One")
    end)
end

test.case("Grouped saves validate all fields before writing", function()
    local service, _, calls = fixture()
    for _, values in ipairs({ { name = "Bad<", background = "", text = "" },
        { name = "Good", background = "invalid", text = "" },
        { name = "Good", background = "", text = "invalid" } }) do
        test.equal(service.save(1, values), false)
    end
    test.equal(service.save(0, { name = "Good", background = "", text = "" }), false)
    test.equal(calls(), 0)
end)

for _, operation in ipairs({ "save", "swap" }) do
    for _, mode in ipairs({ "reject", "throw" }) do
        for index = 1, operation == "swap" and 8 or 4 do
            test.case("Icon-aware " .. operation .. " recovers " .. mode .. " at write " .. index, function()
                local service, data = fixture(index, mode, false, true)
                local ok, _, result
                if operation == "swap" then ok, _, result = service.swap(1, 2)
                else ok, _, result = service.save(1, {
                    name = "New", background = "#ABCDEF", text = "", icon = "skills:magic",
                }) end
                test.equal(ok, false)
                test.equal(result.status, "recovered")
                test.equal(data[1].name, "One")
                test.equal(data[1].background, "")
                test.equal(data[1].text, "#112233")
                test.equal(data[1].icon, "skills:farming")
                test.equal(data[2].name, "Two")
                test.equal(data[2].background, "#445566")
                test.equal(data[2].text, "")
                test.equal(data[2].icon, "skills:necromancy")
            end)
        end
    end
end

test.case("Grouped icon validation rejects invalid destinations before any writes", function()
    local service, _, calls = fixture(nil, nil, nil, true)
    for _, icon in ipairs({ "skills:unknown", false, 123 }) do
        test.equal(service.save(1, { name = "Good", background = "", text = "", icon = icon }), false)
    end
    test.equal(service.apply({
        { slot = 1, name = "Good", background = "", text = "", icon = "skills:magic" },
        { slot = 2, name = "Good", background = "", text = "", icon = "invalid" },
    }), false)
    test.equal(service.save(19, { name = "BoB", background = "", text = "", icon = "skills:magic" }), false)
    test.equal(calls(), 0)
end)

test.case("Grouped icon-only saves and explicit reset work without names or colours", function()
    local service, data = fixture(nil, nil, nil, true)
    test.equal(service.save(1, { name = "", background = "", text = "", icon = "skills:magic" }), true)
    test.equal(data[1].name, "")
    test.equal(data[1].icon, "skills:magic")
    test.equal(service.save(1, { name = "", background = "", text = "", icon = "" }), true)
    test.equal(data[1].icon, "")
end)

test.case("Omitted icons are preserved and BoB saves never write icon settings", function()
    local service, data, calls = fixture(nil, nil, nil, true)
    test.equal(service.save(1, { name = "New", background = "", text = "" }), true)
    test.equal(data[1].icon, "skills:farming")
    test.equal(calls(), 3)
    test.equal(service.save(19, { name = "New BoB", background = "", text = "", icon = "" }), true)
    test.equal(data[19].icon, nil)
    test.equal(calls(), 6)
end)

test.case("Swaps transfer two icons and an icon with a default number", function()
    local service, data = fixture(nil, nil, nil, true)
    test.equal(service.swap(1, 2), true)
    test.equal(data[1].icon, "skills:necromancy")
    test.equal(data[2].icon, "skills:farming")
    data[2].icon = ""
    test.equal(service.swap(1, 2), true)
    test.equal(data[1].icon, "")
    test.equal(data[2].icon, "skills:necromancy")
    test.equal(service.swap(1, 19), false)
end)

for _, mode in ipairs({ "reject", "throw" }) do
    test.case("Failed icon recovery remains visible and restores earlier fields: " .. mode, function()
        local service, data, calls = fixture(4, mode, true, true)
        local ok, message, result = service.save(1, {
            name = "New", background = "#ABCDEF", text = "", icon = "skills:magic",
        })
        test.equal(ok, false)
        test.equal(result.status, "recovery_failed")
        test.equal(message:find("recovery incomplete", 1, true) ~= nil, true)
        test.equal(result.details[2]:find("recovery slot 1 icon", 1, true) ~= nil, true)
        test.equal(calls(), 8)
        test.equal(data[1].name, "One")
        test.equal(data[1].background, "")
        test.equal(data[1].text, "#112233")
    end)
end

test.case("Grouped save and swap report complete success", function()
    local service, data = fixture()
    local ok, _, result = service.save(1, { name = " New ", background = "#ABCDEF", text = "" })
    test.equal(ok, true)
    test.equal(result.status, "success")
    test.equal(data[1].name, "New")
    test.equal(service.swap(1, 2), true)
    test.equal(data[2].name, "New")
end)
