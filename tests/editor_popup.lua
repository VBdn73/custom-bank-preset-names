local test = require("tests.test_helper")

test.case("Popup opens the requested slot, replaces old popups and closes safely", function()
    local previousEditor = package.loaded["editor/view"]
    local built, controls = {}, {}
    local infoClicks = 0
    local root = { interfaceID = 517, width = 900, height = 890 }
    local scroll = { interfaceID = 517, parent = root }
    local source = { parent = scroll }
    local function control(parent)
        local c = { parent = parent, text = {}, hooks = {} }
        function c:SetSize(w, h) self.width, self.height = w, h end
        function c:SetPos(...)
            self.position = { ... }
            self.x, self.y = self.position[1], self.position[2]
        end
        function c:Subscribe(hook, callback) self.hooks[hook] = callback; self.callback = callback end
        function c:Destroy() self.destroyed = true end
        controls[#controls + 1] = c
        return c
    end
    ui = {
        Interfaces = { GetComponent = function() return source end },
        Layer = { new = control }, Rectangle = { new = control }, Button = { new = control },
        Text = { new = control },
        Hook = { ONBUTTONPRESSED = 1 },
    }
    Vector4 = { new = function(...) return { ... } end }
    id = { StyleSheet = { BUTTON_DEFAULT = 1 }, Font = { MUSEO_SANS_15PT_REGULAR = 1 } }
    package.loaded["editor/view"] = { build = function(parent, names, bindings, slot, options)
        built[#built + 1] = { parent = parent, slot = slot, options = options }
        return function() if parent.disposed then error("Disposed") end end,
            function() infoClicks = infoClicks + 1 end
    end }
    local popup = dofile("editor/popup.lua")
    package.loaded["editor/view"] = previousEditor
    local bindings = require("bank/bindings")
    popup.open(18, {}, bindings)
    test.equal(built[1].slot, 18)
    test.equal(controls[1].parent, root, "Popup must not live inside the scrolling list")
    test.equal(controls[1].clickthrough, false)
    test.equal(controls[1].position[1], 274)
    test.equal(controls[1].position[2], 290)
    test.equal(controls[1].position[3], nil, "Avoid native percentage anchors")
    popup.update()
    root.width, root.height = 1000, 800
    popup.update()
    test.equal(controls[1].position[1], 324)
    test.equal(controls[1].position[2], 245)
    test.equal(built[1].options.hideTitle, true)
    test.equal(built[1].parent.y, 36, "Editor must sit below the title bar")
    test.equal(built[1].options.externalInfoButton, true)
    local info = controls[8]
    test.equal(info.label, "i")
    test.equal(info.x, 296)
    info.callback()
    test.equal(infoClicks, 1)
    test.equal(controls[1].destroyed, nil, "Info does not close the popup")
    local close = controls[9]
    test.equal(next(controls[1].hooks), nil, "Popup has no drag handlers")
    test.equal(next(controls[6].hooks), nil, "Title has no drag handlers")
    test.equal(close.label, "×")
    test.equal(close.x, 322)
    test.equal(close.y, 7)
    test.equal(close.width, 22)
    test.equal(controls[2].colour[1] > controls[2].colour[3], true, "Warm brown, not blue")
    popup.update()
    test.equal(controls[1].x, 324, "A tick preserves the centered position")
    root.width, root.height = 950, 780
    popup.update()
    test.equal(controls[1].x, 299, "Resize recenters the popup")
    test.equal(controls[1].y, 235)
    root.width, root.height = 300, 300
    popup.update()
    test.equal(controls[1].position[1], 0)
    test.equal(controls[1].position[2], 0)
    popup.open(2, {}, bindings)
    test.equal(controls[1].destroyed, true)
    test.equal(built[2].slot, 2)
    controls[#controls].callback()
    test.equal(built[2].parent.parent.destroyed, true)
    popup.close()
    popup.open(3, {}, bindings)
    built[3].parent.disposed = true
    popup.update()
    test.equal(built[3].parent.parent.destroyed, true)
    source = nil
    popup.open(1, {}, bindings)
    test.equal(#built, 3)
end)
