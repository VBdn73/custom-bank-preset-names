local test = require("tests.test_helper")
local storage = require("storage")

test.case("Verified writes require readback agreement and accept empty resets", function()
    local previous = PersistentDB
    local stored, result, mismatch
    PersistentDB = {
        SetString = function(_, key, value) stored = value; return result end,
        GetString = function() return mismatch or stored end,
    }
    local ok, message = pcall(function()
        test.equal(storage.writeVerified("key", "name"), true)
        test.equal(storage.writeVerified("key", ""), true)
        result = false
        test.equal(storage.writeVerified("key", "name"), false)
        result, mismatch = true, "other"
        test.equal(storage.writeVerified("key", "name"), false)
        PersistentDB.SetString = function() error("host error") end
        test.equal(pcall(storage.writeVerified, "key", "name"), false)
    end)
    PersistentDB = previous
    if not ok then error(message) end
end)
