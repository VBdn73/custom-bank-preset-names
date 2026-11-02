local test = require("tests.test_helper")

test.case("Icon text validates and persists independently per character and slot", function()
    local context, db = "first", {}
    local environment = setmetatable({ PersistentDB = {
        GetString = function(_, key) return db[key] end,
        SetString = function(_, key, value) db[key] = value end,
    } }, { __index = _G })
    local storage = assert(loadfile("storage.lua", "t", environment))()
    environment.require = function(path)
        if path == "presets/names" then return { getContext = function() return context end } end
        if path == "storage" then return storage end
        return require(path)
    end
    local function load() return assert(loadfile("presets/icon_text.lua", "t", environment))() end
    local text = load()
    for _, value in ipairs({ "abcd", "a b", "!", "é", 42, false }) do
        test.equal(text.save(1, value), false)
    end
    test.equal(text.save(19, "A"), false)
    test.equal(text.save(1, "A12"), true)
    test.equal(load().get(1), "A12")
    test.equal(text.get(2), "")
    context = "second"
    test.equal(text.get(1), "")
    test.equal(text.save(1, "x"), true)
    context = "first"
    test.equal(text.get(1), "A12")
    test.equal(text.save(1, ""), true)
    test.equal(load().get(1), "")
end)
