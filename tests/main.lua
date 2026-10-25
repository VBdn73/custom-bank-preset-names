local test = require("tests.test_helper")

test.case("Entry point retains PrettyUI for later content events and disposes old views", function()
    local library = {}
    local built, destroyed = 0, 0
    local modules = {
        ["editor/view"] = { build = function(_, _, _, _, options)
            test.equal(options.prettyui, library)
            built = built + 1
            return function() end, nil, function() destroyed = destroyed + 1 end
        end },
    }
    local events = setmetatable({}, { __index = function(target, key)
        local event = { Subscribe = function(_, callback) target[key].callback = callback end }
        target[key] = event
        return event
    end })
    local environment = setmetatable({
        prettyui = library, Event = events,
        require = function(path)
            modules[path] = modules[path] or {}
            return modules[path]
        end,
    }, { __index = _G })
    assert(loadfile("main.lua", "t", environment))()
    -- Event execution must not depend on the global still containing the export.
    environment.prettyui = false
    events.ContentLayerReady.callback({ component = {} })
    events.ContentLayerReady.callback({ component = {} })
    test.equal(built, 2)
    test.equal(destroyed, 1)
end)
