local test = require("tests.test_helper")

test.case("PrettyUI popup retains bank ownership, selected slot and safe cleanup", function()
    local previousEditor = package.loaded["editor/view"]
    local built, windows, infoClicks, sprites = {}, {}, 0, {}
    local root = { width = 900, height = 890 }
    local bank = { parent = root }
    local source = { parent = bank, visibleGlobal = true }
    local function control(parent)
        local c = { parent = parent }
        function c:SetPos(x, y) self.x, self.y = x, y end
        function c:SetSize(w, h) self.width, self.height = w, h end
        function c:Subscribe(_, callback) self.callback = callback end
        function c:Destroy() self.destroyed = true end
        return c
    end
    ui = { Interfaces = { GetComponent = function() return source end },
        Sprite = { new = function(parent)
            local c = control(parent)
            sprites[#sprites + 1] = c
            return c
        end }, Hook = { ONCLICK = 1 } }
    id = { Sprite = { RS3_BUTTON_INFO_PARENT_0 = 1,
        RS3_BUTTON_INFO_PARENT_1 = 2, RS3_BUTTON_INFO_PARENT_2 = 3 } }
    local library = { Window = { new = function(parent, options)
        local w = { root = control(parent), options = options, titleText = control(parent), overlays = {} }
        function w:_RegisterOverlay(c, _, position) self.overlays[c] = position end
        function w:_UnregisterOverlay(c) self.overlays[c] = nil end
        function w:_SyncOverlays(hidden)
            for c, position in pairs(self.overlays) do position(); c.hidden = hidden end
        end
        w.root:SetPos(options.x, options.y)
        w.root:SetSize(options.width, options.height)
        w.content = control(w.root)
        w.content:SetSize(options.width - 16, options.height - 40)
        function w:Destroy() self.destroyed = true end
        windows[#windows + 1] = w
        return w
    end } }
    package.loaded["editor/view"] = { build = function(parent, names, bindings, slot, options)
        built[#built + 1] = { parent = parent, slot = slot, options = options }
        return function() if parent.disposed then error("Disposed") end end,
            function() infoClicks = infoClicks + 1 end
    end }
    local popup = dofile("editor/popup.lua")
    package.loaded["editor/view"] = previousEditor
    local bindings = require("bank/bindings")
    popup.open(18, {}, bindings, library)
    local first = windows[1]
    test.equal(first.root.parent, root, "Host is outside the bank popover")
    test.equal(first.root.x, 274)
    test.equal(first.root.y, math.floor((890 - first.root.height) / 2))
    test.equal(first.options.scrollable, false)
    test.equal(built[1].slot, 18)
    test.equal(built[1].options.contentHost, first)
    test.equal(built[1].options.hideTitle, true)
    test.equal(built[1].options.externalInfoButton, true)
    test.equal(built[1].options.infoParent, first.root)
    local info = sprites[1]
    test.equal(info.parent, root, "Header info is above the sibling drag handle")
    test.equal(info.y, first.root.y + 6)
    test.equal(info.x, first.root.x + first.root.width - 54, "Help sits beside close")
    first.root:SetPos(100, 120)
    popup.update()
    test.equal(info.x, 100 + first.root.width - 54, "Help follows dragging")
    test.equal(info.y, 126)
    first.root.hidden = true
    popup.update()
    test.equal(info.hidden, true)
    first.root.hidden = false
    info.callback()
    test.equal(infoClicks, 1)
    test.equal(first.destroyed, nil, "Help must not close the window")
    info.isMouseOver = true
    popup.update()
    test.equal(info.sprite, 2)
    popup.open(2, {}, bindings, library)
    test.equal(first.destroyed, true)
    test.equal(info.destroyed, true, "Sibling overlay is explicitly destroyed")
    test.equal(next(first.overlays), nil)
    test.equal(built[2].slot, 2)
    windows[2].options.onClose()
    test.equal(windows[2].destroyed, true)
    popup.close()
    popup.open(3, {}, bindings, library)
    built[3].parent.disposed = true
    popup.update()
    test.equal(windows[3].destroyed, true)
    for _, unavailable in ipairs({ "hidden", "restricted", "replaced", "missing" }) do
        source = { parent = bank, visibleGlobal = true }
        popup.open(1, {}, bindings, library)
        local opened = windows[#windows]
        if unavailable == "hidden" then source.visibleGlobal = false
        elseif unavailable == "restricted" then source.isRestricted = true
        elseif unavailable == "replaced" then source = { parent = bank, visibleGlobal = true }
        else source = nil end
        popup.update()
        test.equal(opened.destroyed, true, "Close when bank source becomes " .. unavailable)
    end
    source = { parent = bank, visibleGlobal = true }
    popup.open(1, {}, { labels = bindings.labels, colours = {} }, library)
    local layout = require("editor/layout")
    test.equal(built[#built].options.formHeight, layout.compactBodyHeight + layout.colourHeight)
    test.equal(windows[#windows].content.height, built[#built].options.formHeight)
    popup.close()
    local count = #windows
    source.visibleGlobal = false
    popup.open(1, {}, bindings, library)
    source = nil
    popup.open(1, {}, bindings, library)
    test.equal(#windows, count)
end)
