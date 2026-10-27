local test = require("tests.test_helper")
local preview = require("bank/preview")

test.case("Closed-bank previews use generic icons in settings and ribbon editors", function()
    local previousUI, previousID = ui, id
    ui = { Interfaces = { GetComponent = function() end } }
    id = { Sprite = {
        RS3_ICON_BANK_PRESET_BACKPACK = 15047,
        RS3_ICON_BANK_PRESET_WORN_EQUIPMENT = 15050,
        RS3_ICON_BANK_PRESET_BEAST_OF_BURDEN = 15053,
    } }
    local found = {}
    for index = 1, 3 do found[index] = preview.decoration(1, index) end
    ui, id = previousUI, previousID
    for index, sprite in ipairs({ 15047, 15050, 15053 }) do
        test.equal(found[index].sprite, sprite)
        test.equal(found[index].alpha, 1)
    end
end)

test.case("First-row preview finds icons beyond adjacent IDs and skips empty placeholders", function()
    local previous = ui
    local number = { xyGlobal = { y = 100 }, height = 32 }
    local icon = { xyGlobal = { y = 104 }, height = 24, sprite = 123 }
    ui = { Interfaces = { GetComponent = function(_, _, staticID, _, dynamicID)
        if staticID == 266 and dynamicID == 0 then return number end
        if staticID >= 268 and staticID <= 270 then
            if dynamicID == 0 then return { xyGlobal = { y = 104 }, height = 24 } end
            if dynamicID == 1 then
                return { xyGlobal = { y = 136 }, height = 24, sprite = 456 }
            end
            if dynamicID == 2 then return icon end
        end
    end } }
    local found = {}
    for index = 1, 3 do found[index] = preview.icon(1, index) end
    ui = previous
    for index = 1, 3 do test.equal(found[index], icon) end
end)
