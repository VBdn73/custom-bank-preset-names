local test = require("tests.test_helper")

local function fixture()
    local parent = {}
    local number = { parent = parent, content = "1", type = 1,
        width = 24, height = 30, x = 0, y = 10, visibleGlobal = true }
    local current = number
    local created = {}
    local fail = false
    local environment = setmetatable({
        print = function() end,
        id = { Sprite = { TEST = 42 } },
        ui = { ComponentType = { LABEL = 1 },
            Interfaces = { GetComponent = function() return current end },
            Sprite = { new = function(host)
                test.equal(host, parent)
                local sprite = {
                    SetSize = function(self, w, h)
                        if fail then error("layout failed") end
                        self.width, self.height = w, h
                    end,
                    SetPos = function(self, x, y) self.x, self.y = x, y end,
                    Destroy = function(self) self.destroyed = true end,
                }
                setmetatable(sprite, { __index = function(self, key)
                    if key == "spriteID" then return self.sprite end
                end })
                created[#created + 1] = sprite
                return sprite
            end },
        },
    }, { __index = _G })
    local probe = assert(loadfile("bank/icon_probe.lua", "t", environment))()
    return probe, number, created, function(value) current = value end,
        function() fail = true end
end

local function config()
    return { enabled = true, slot = 1, sprite = "TEST", width = 24, height = 24 }
end

test.case("Icon probe is opt-in and restores native text", function()
    local probe, number, created = fixture()
    probe.update({ enabled = false })
    test.equal(#created, 0)
    probe.update(config())
    test.equal(number.content, "")
    test.equal(created[1].y, 13)
    test.equal(created[1].clickthrough, true)
    test.equal(created[1].rgba, 0xFFFFFFFF)
    number.content = "Updated"
    probe.update(config())
    test.equal(#created, 1)
    probe.restore()
    probe.restore()
    test.equal(number.content, "Updated")
    test.equal(created[1].destroyed, true)
end)

test.case("Icon probe retains number on invalid resources, BoB, and layout failures", function()
    local probe, number, created, _, fail = fixture()
    local options = config()
    options.sprite = "MISSING"
    probe.update(options)
    test.equal(number.content, "1")
    options = config()
    options.slot = 19
    probe.update(options)
    test.equal(#created, 0)
    fail()
    probe.update(config())
    test.equal(number.content, "1")
    test.equal(created[1].destroyed, true)
end)

test.case("Icon probe releases stale components and skips restricted numbers", function()
    local probe, number, created, replace = fixture()
    probe.update(config())
    replace(nil)
    probe.update(config())
    test.equal(number.content, "1")
    test.equal(created[1].destroyed, true)
    number.isRestricted = true
    replace(number)
    probe.update(config())
    test.equal(#created, 1)
    number.isRestricted = false
    probe.update(config())
    test.equal(#created, 2)
    probe.update({ enabled = false })
    test.equal(number.content, "1")
end)
