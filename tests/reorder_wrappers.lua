local test = require("tests.test_helper")

test.case("Fresh client wrappers do not unsubscribe newly registered native drag hooks", function()
    local oldNames, oldSwap = package.loaded["presets/names"], package.loaded["presets/swap"]
    local oldUI = ui
    local context, swaps = "character", 0
    package.loaded["presets/names"] = { getContext = function() return context end }
    package.loaded["presets/swap"] = { apply = function(first, second)
        test.equal(first, 1)
        test.equal(second, 5)
        swaps = swaps + 1
        return true
    end }
    local listeners, subscriptions, removals = {}, 0, 0
    local function wrapper(staticID, dynamicID)
        local key = staticID .. ":" .. dynamicID
        return setmetatable({ interfaceID = 517, staticID = staticID, categoryID = 0,
            dynamicID = dynamicID, visibleGlobal = true,
            Subscribe = function(_, _, _, callback)
                subscriptions = subscriptions + 1
                listeners[key] = callback
            end,
            Unsubscribe = function()
                removals = removals + 1
                listeners[key] = nil
            end,
        }, { __index = function(_, field)
            if field == "parent" and staticID == 265 then
                -- Different wrappers from both rows still represent ONE parent.
                return wrapper(263, -1)
            end
        end })
    end
    ui = { Hook = { ONDRAGCOMPLETE = 1 }, Interfaces = {
        GetComponent = function(_, _, staticID, _, dynamicID)
            if staticID == 265 and (dynamicID == 1 or dynamicID == 5) then
                return wrapper(staticID, dynamicID)
            end
        end,
    } }
    local reorder = dofile("bank/reorder.lua")
    reorder.update({ presetCount = 18, labels = {} })
    test.equal(subscriptions, 3, "Two rows and their shared parent are subscribed once each")
    reorder.update({ presetCount = 18, labels = {} })
    test.equal(removals, 0, "Fresh wrappers must not cause cleanup of active native hooks")
    test.equal(type(listeners["265:1"]), "function")
    listeners["265:1"](wrapper(265, 1), wrapper(265, 5))
    test.equal(swaps, 1)
    -- A UI rebuild loses native listeners even if component IDs are unchanged.
    listeners = {}
    reorder.update({ presetCount = 18, labels = {} })
    test.equal(type(listeners["265:1"]), "function")
    context = nil
    reorder.update({ presetCount = 18, labels = {} })
    test.equal(next(listeners), nil, "Logout removes the tracked native hooks")
    test.equal(removals, 3)
    reorder.clear()
    package.loaded["presets/names"], package.loaded["presets/swap"] = oldNames, oldSwap
    ui = oldUI
end)
