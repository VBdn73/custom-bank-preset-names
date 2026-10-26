local test = require("tests.test_helper")

local function fixture()
    local function copy(value)
        local result = {}
        for key, entry in pairs(value) do result[key] = entry end
        return result
    end
    local components = {}
    for _, staticID in ipairs({ 262, 263, 275, 291, 292, 293, 303, 304 }) do
        components[staticID] = { staticID = staticID,
            size = { width = 0, height = -150, widthParentPc = 1, heightParentPc = 1 },
            position = { x = 0, y = -150, xParentPc = 0, yParentPc = 1,
                xSelfPc = 0, ySelfPc = 0 },
        }
    end
    local environment = setmetatable({ ui = {
        Size = { new = copy }, Pos = { new = copy },
        Interfaces = { GetComponent = function(_, interfaceID, staticID)
            test.equal(interfaceID, 517)
            return components[staticID]
        end },
    } }, { __index = _G })
    return assert(loadfile("bank/preset_layout.lua", "t", environment))(), components
end

test.case("Hidden dropdown expands viewport without moving or clipping bank actions", function()
    local layout, components = fixture()
    layout.update(true, { height = 28 })
    for _, staticID in ipairs({ 262, 263, 275 }) do
        test.equal(components[staticID].size.height, -114)
        test.equal(components[staticID].size.heightParentPc, 1)
    end
    test.equal(components[291].position.y, -150)
    test.equal(components[291].position.yParentPc, 1)
    test.equal(components[291].size.height, -150, "Do not shrink the native clipping parent")
    test.equal(components[292].position.y, -114)
    test.equal(components[292].size.height, -186)
    test.equal(components[293].position.y, -114)
    test.equal(components[293].size.height, -150)
    for _, staticID in ipairs({ 303, 304 }) do
        test.equal(components[staticID].position.y, -150, "Bank actions stay in their native positions")
        test.equal(components[staticID].size.height, -150)
    end
    layout.update(true, { height = 28 })
    test.equal(components[263].size.height, -114, "Repeated updates do not accumulate")
    layout.update(false)
    test.equal(components[263].size.height, -150)
    test.equal(components[291].size.height, -150)
    test.equal(components[291].position.y, -150)
    test.equal(components[292].size.height, -150)
    test.equal(components[292].position.y, -150)
    test.equal(components[293].position.y, -150)
end)

test.case("Nested anchored scrollbars inherit expansion only once", function()
    local layout, components = fixture()
    components[275].parent = components[263]
    layout.update(true, { height = 28 })
    test.equal(components[275].size.height, -150)
    test.equal(components[263].size.height, -114)
    layout.restore()
    test.equal(components[263].size.height, -150)
end)

test.case("Overwrite and Exact Matching remain inside the original settings clipping bounds", function()
    local layout, components = fixture()
    local settings = components[291]
    settings.size.height, settings.size.heightParentPc = 140, 0
    settings.position.y, settings.position.yParentPc = 400, 0
    for _, staticID in ipairs({ 292, 293, 303, 304 }) do
        local component = components[staticID]
        component.parent = settings
        component.size.heightParentPc = 0
        component.position.yParentPc = 0
    end
    components[292].size.height, components[292].position.y = 140, 0
    components[293].size.height, components[293].position.y = 22, 8
    components[303].size.height, components[303].position.y = 24, 85
    components[304].size.height, components[304].position.y = 18, 116
    layout.update(true, { height = 28 })
    test.equal(settings.size.height, 140)
    test.equal(settings.position.y, 400)
    test.equal(components[293].position.y, 44)
    for _, staticID in ipairs({ 303, 304 }) do
        local action = components[staticID]
        test.equal(action.position.y + action.size.height <= settings.size.height, true,
            "Native bank action must not be clipped by its settings parent")
    end
    test.equal(components[293].position.y + components[293].size.height < components[303].position.y,
        true, "Moved checkboxes leave room for Overwrite")
    layout.restore()
    test.equal(components[293].position.y, 8)
end)

test.case("Bank resizing and rebuilt components retain their own original layouts", function()
    local layout, components = fixture()
    layout.update(true, { height = 28 })
    components[263].size.height = -200
    layout.update(true, { height = 28 })
    test.equal(components[263].size.height, -164)
    components[275] = nil
    components[262].isRestricted = true
    layout.update(true, { height = 28 })
    layout.restore()
    test.equal(components[263].size.height, -200)
end)

test.case("Layout restoration leaves newer game-side changes untouched", function()
    local layout, components = fixture()
    layout.update(true, { height = 28 })
    components[293].position.y = 99
    components[263].size.height = 42
    layout.restore()
    test.equal(components[293].position.y, 99)
    test.equal(components[263].size.height, 42)
end)
