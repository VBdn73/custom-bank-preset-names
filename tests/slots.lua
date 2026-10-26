local test = require("tests.test_helper")
local slots = require("presets/slots")

test.case("Preset slots share the binding count and validate boundaries", function()
    test.equal(require("bank/bindings").presetCount, slots.count)
    test.equal(slots.valid(1), true)
    test.equal(slots.valid(slots.count), true)
    for _, value in ipairs({ 0, -1, slots.count + 1, 1.5, "1", false, math.huge }) do
        test.equal(slots.valid(value), false)
    end
    test.equal(slots.valid(nil), false)
    test.equal(slots.valid(3, 2), false)
    test.equal(slots.valid(2, 2), true)
end)
