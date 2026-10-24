local test = require("tests.test_helper")

-- Every scenario gets fresh storage, player state, and a fresh module cache.
local function createFixture()
    local fixture = { data = {}, displayName = "First Character", available = true,
        entityValid = true, entityMissing = false, reads = 0, writes = 0 }
    Player = {
        IsAvailable = function() return fixture.available end,
        GetEntity = function()
            if fixture.entityMissing then return nil end
            return { isValid = fixture.entityValid, displayName = fixture.displayName }
        end,
    }
    PersistentDB = {
        GetString = function(_, key)
            fixture.reads = fixture.reads + 1
            return fixture.data[key]
        end,
        SetString = function(_, key, value)
            fixture.writes = fixture.writes + 1
            fixture.data[key] = value
            return true
        end,
    }
    fixture.names = dofile("preset_names.lua")
    return fixture
end

test.case("Names are trimmed and survive a module reload", function()
    local f = createFixture()
    test.equal(f.names.get(1), nil, "New slot")
    test.equal(f.names.save(1, "  Bossing  "), true, "Save result")
    test.equal(f.names.get(1), "Bossing", "Cached name")
    test.equal(dofile("preset_names.lua").get(1), "Bossing", "Reloaded name")
end)

for _, character in ipairs({ "x", "é", "\240\159\152\128" }) do
    test.case("Names enforce the 40-code-point limit for " .. character, function()
        local f = createFixture()
        test.equal(f.names.save(1, string.rep(character, 40)), true, "40 characters allowed")
        test.equal(f.names.save(1, string.rep(character, 41)), false, "41 characters rejected")
        test.equal(f.names.get(1), string.rep(character, 40), "Failed save preserves previous name")
    end)
end

local invalidNames = {
    { "non-string input", false }, { "numeric input", 123 },
    { "opening markup delimiter", "<col=ff0000>Bad" },
    { "closing markup delimiter", "Bad>" }, { "embedded newline", "line\nbreak" },
    { "embedded tab", "a\tb" }, { "NUL byte", "a\0b" },
    { "DEL byte", "a\127b" }, { "malformed UTF-8", "\237\160\128" },
}
for _, example in ipairs(invalidNames) do
    test.case("Names reject " .. example[1] .. " without writing storage", function()
        local f = createFixture()
        local succeeded, message = f.names.save(1, example[2])
        test.equal(succeeded, false, "Save result")
        test.equal(type(message), "string", "User-facing explanation")
        test.equal(f.writes, 0, "Storage writes")
    end)
end

test.case("Nil input is rejected", function()
    local f = createFixture()
    test.equal(f.names.save(1, nil), false)
    test.equal(f.writes, 0)
end)

for _, example in ipairs({ { "Empty", "" }, { "Whitespace-only", " \t\n " } }) do
    test.case(example[1] .. " names reset only the selected slot", function()
        local f = createFixture()
        f.names.save(1, "Bossing")
        f.names.save(2, "Skilling")
        test.equal(f.names.save(1, example[2]), true)
        test.equal(f.names.get(1), nil, "Reset slot")
        test.equal(f.names.get(2), "Skilling", "Other slot")
        test.equal(dofile("preset_names.lua").get(1), nil, "Reset persists")
    end)
end

test.case("Character settings ignore case and surrounding spaces but stay isolated", function()
    local f = createFixture()
    f.names.save(1, "First name")
    f.displayName = "Second Character"
    test.equal(f.names.get(1), nil)
    f.names.save(1, "Second name")
    test.equal(dofile("preset_names.lua").get(1), "Second name")
    f.displayName = "  FIRST CHARACTER  "
    test.equal(f.names.get(1), "First name")
    f.displayName = "Renamed Character"
    test.equal(f.names.get(1), nil, "Renames start a separate context")
end)

local unavailableCases = {
    { "logged out", function(f) f.available = false end },
    { "missing entity", function(f) f.entityMissing = true end },
    { "invalid entity", function(f) f.entityValid = false end },
    { "missing display name", function(f) f.displayName = nil end },
    { "empty display name", function(f) f.displayName = "" end },
    { "whitespace display name", function(f) f.displayName = "   " end },
    { "non-string display name", function(f) f.displayName = 123 end },
}
for _, example in ipairs(unavailableCases) do
    test.case("Unavailable character: " .. example[1], function()
        local f = createFixture()
        f.names.save(1, "Previous name")
        example[2](f)
        test.equal(f.names.get(1), nil, "Previous character's name is hidden")
        test.equal(f.names.save(1, "Wrong character"), false, "Saving blocked")
        test.equal(f.writes, 1, "No additional write")
    end)
end

test.case("Cached names and missing slots avoid repeated storage reads", function()
    local f = createFixture()
    f.names.get(1)
    f.names.get(1)
    test.equal(f.reads, 1, "Missing slot cached")
    f.names.save(1, "Bossing")
    local readsAfterSave = f.reads
    f.names.get(1)
    test.equal(f.reads, readsAfterSave, "Saved name cached")
    f.available = false
    f.names.get(1)
    f.available = true
    test.equal(f.names.get(1), "Bossing")
    test.equal(f.reads, readsAfterSave + 1, "Logout invalidates cache")
end)

test.case("Invalid stored names are ignored and legacy shared keys are untouched", function()
    local f = createFixture()
    f.data["presetName.v3.displayName.first character.1"] = "<bad>"
    f.data["presetName.v1.1"] = "Legacy shared name"
    test.equal(f.names.get(1), nil)
    f.names.save(1, "New name")
    test.equal(f.data["presetName.v1.1"], "Legacy shared name")
end)

for _, mode in ipairs({ "false return", "no write", "mismatched read-back" }) do
    test.case("Storage failure preserves cached name: " .. mode, function()
        local f = createFixture()
        f.names.save(1, "Original")
        PersistentDB.SetString = function(_, key, value)
            if mode == "false return" then
                f.data[key] = value
                return false
            elseif mode == "mismatched read-back" then
                f.data[key] = "Unexpected value"
            end
            return true
        end
        local succeeded, message = f.names.save(1, "Replacement")
        test.equal(succeeded, false)
        test.equal(message, "Storage verification failed. See the client console.")
        test.equal(f.names.get(1), "Original")
    end)
end

test.case("Storage setter may omit its return if read-back verifies the write", function()
    local f = createFixture()
    PersistentDB.SetString = function(_, key, value) f.data[key] = value end
    test.equal(f.names.save(1, "Verified"), true)
    test.equal(dofile("preset_names.lua").get(1), "Verified")
end)
