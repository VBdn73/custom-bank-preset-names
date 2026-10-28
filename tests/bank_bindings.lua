local test = require("tests.test_helper")

test.case("Compact bindings target nine native number labels and the fixed BoB icon", function()
    local bindings = dofile("bank/bindings.lua")
    local expectedDynamicIDs = { 9, 20, 31, 42, 53, 64, 75, 86, 97 }
    test.equal(#bindings.compactButtons, 10)
    for buttonIndex, dynamicID in ipairs(expectedDynamicIDs) do
        local binding = bindings.compactButtons[buttonIndex]
        test.equal(binding.buttonIndex, buttonIndex)
        test.equal(binding.interfaceID, 517)
        test.equal(binding.staticID, 117)
        test.equal(binding.categoryID, 0)
        test.equal(binding.dynamicID, dynamicID)
        test.equal(binding.slot, nil, "A physical button must not imply a permanent preset slot")
    end
    local bob = bindings.compactButtons[10]
    test.equal(bob.buttonIndex, 10)
    test.equal(bob.slot, 19)
    test.equal(bob.interfaceID, 517)
    test.equal(bob.staticID, 117)
    test.equal(bob.categoryID, 0)
    test.equal(bob.dynamicID, 133)
end)

test.case("Compact bindings leave management rows and Beast of Burden mappings unchanged", function()
    local bindings = dofile("bank/bindings.lua")
    test.equal(bindings.presetCount, 18)
    test.equal(bindings.entryCount, 19)
    test.equal(#bindings.numbers, 18)
    test.equal(#bindings.appearance, 38)
    for slot = 1, 18 do
        local number, label = bindings.numbers[slot], bindings.labels[slot]
        test.equal(number.slot, slot)
        test.equal(number.interfaceID, 517)
        test.equal(number.staticID, 266)
        test.equal(number.categoryID, 0)
        test.equal(number.dynamicID, (slot - 1) * 3)
        test.equal(label.slot, slot)
        test.equal(label.staticID, 266)
        test.equal(label.dynamicID, (slot - 1) * 3 + 1)
    end
    local bob = bindings.labels[19]
    test.equal(bob.slot, 19)
    test.equal(bob.staticID, 266)
    test.equal(bob.dynamicID, 55)
    test.equal(bindings.numbers[19], nil)
    test.equal(bindings.appearance[37].slot, 19)
    test.equal(bindings.appearance[37].staticID, 265)
    test.equal(bindings.appearance[37].dynamicID, 19)
    test.equal(bindings.appearance[38].slot, 19)
    test.equal(bindings.appearance[38].dynamicID, 55)
end)
