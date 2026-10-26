local test = require("tests.test_helper")

-- Mock only the native API used by the editor. No actual client UI is created.
local function createFixture(colours)
    local f = { controls = {}, stored = { [18] = "Last preset" }, context = "first",
        saveCalls = 0, saveMode = "success" }
    local function createControl(kind, parent)
        local control = { kind = kind, parent = parent, entries = {}, hooks = {} }
        setmetatable(control, { __newindex = function(target, key, value)
            if key == "hidden" then
                test.equal(type(value), "boolean", "Native visibility requires a boolean")
            end
            rawset(target, key, value)
        end })
        function control:SetPos(x, y, parentX, parentY, selfX, selfY)
            self.x, self.y = x, y
            self.parentX, self.selfX = parentX, selfX
        end
        function control:SetSize(width, height) self.width, self.height = width, height end
        function control:Destroy() self.destroyed = true end
        function control:Setup(visibility, filter, limit)
            self.visibility, self.filter, self.limit = visibility, filter, limit
        end
        function control:Subscribe(hook, reference, callback) self.hooks[hook] = callback or reference end
        function control:Add(label, entryID) self.entries[entryID] = label end
        function control:Clear() self.entries = {} end
        function control:SetEntrySelected(entryID, selected, triggerEvents)
            test.equal(selected, true)
            test.equal(triggerEvents, false, "Initialization must not trigger selection events")
            self.selectedID = entryID
        end
        f.controls[#f.controls + 1] = control
        return control
    end
    ui = {
        Layer = { new = function(parent) return createControl("layer", parent) end },
        Rectangle = { new = function(parent) return createControl("rectangle", parent) end },
        Text = { new = function(parent) return createControl("text", parent) end },
        Button = { new = function(parent) return createControl("button", parent) end },
        Sprite = { new = function(parent) return createControl("sprite", parent) end },
        InputField = { new = function(parent) return createControl("input", parent) end },
        List = { new = function(parent) return createControl("list", parent) end },
        Hook = { ONBUTTONPRESSED = 1, ONCONTENTCHANGED = 2, ONSELECTIONCHANGED = 3, ONRESIZE = 4, ONCLICK = 5,
            ONSCROLLWHEEL = 6, ONHOLD = 7, ONRELEASE = 8,
            ONMOUSEOVER = 9, ONMOUSELEAVE = 10 },
        SelectionChangeEvent = { SELECTED = 1, DESELECTED = 0 },
        TextContentVisibilityMode = { VISIBLE = 0 }, InputFieldFilterMode = { NONE = 0 },
        InputFieldActionResult = { SUBMIT = 1 },
    }
    Vector4 = { new = function(...) return { ... } end }
    -- Mock the public PrettyUI interface, not its scrollbar implementation.
    prettyui = { CheckboxButton = { new = function(parent, choices, options)
        local root = createControl("checkbox", parent)
        root:SetSize(options.width, 22)
        local checkbox = { root = root, selected = choices[1].selected }
        function checkbox:SetSelected(value, selected, notify)
            test.equal(value, "hideDropdown")
            self.selected = selected
            if notify ~= false then options.onChange(self, {}, value, selected) end
        end
        f.checkbox = checkbox
        return checkbox
    end }, SimpleView = { new = function(parent, options)
        local view = { content = createControl("layer", parent), scrollY = 0,
            width = options.width, height = options.height, contentHeight = 0 }
        function view:ScrollBy(delta)
            self.scrollY = math.max(0, math.min(math.max(0, self.contentHeight - self.height),
                self.scrollY + delta))
        end
        function view:SetScrollPosition(value)
            self:ScrollBy(value - self.scrollY)
            if self.input then
                local root = self.input.root
                root.contentClipped = root.y - self.scrollY < 0
                    or root.y - self.scrollY + root.height > self.height
            end
        end
        function view:AddTextField(options)
            test.equal(options._scrollController, self)
            local root = createControl("input", self.content)
            root:SetPos(options.x, options.y)
            root:SetSize(options.width, options.height)
            root.limit = options.maxLength
            local field = { root = root }
            root:Subscribe(ui.Hook.ONCONTENTCHANGED, function(_, reason)
                if reason == ui.InputFieldActionResult.SUBMIT and field.onSubmit then field.onSubmit() end
            end)
            root:Subscribe(ui.Hook.ONSCROLLWHEEL, function(_, delta)
                self:SetScrollPosition(self.scrollY + delta * 32)
                return false
            end)
            self.input = field
            return field
        end
        function view:AddSimpleButton(label, callback, options)
            test.equal(options.absolute, true)
            local root = createControl("button", self.content)
            root.label = label
            root:SetPos(options.x, options.y)
            root:SetSize(options.width, options.height)
            root:Subscribe(ui.Hook.ONBUTTONPRESSED, callback)
            return { root = root }
        end
        function view:SetContentHeight(height)
            self.contentHeight = height
            self.scrollbarVisible = height > self.height
            self.contentWidth = self.width - (self.scrollbarVisible and 18 or 0)
            self.content:SetSize(self.contentWidth, math.max(self.height, height))
            self:ScrollBy(0)
        end
        function view:SetSize(width, height)
            self.width, self.height = width, height
            self:SetContentHeight(self.contentHeight)
        end
        function view:Destroy() self.destroyed = true end
        f.scrollView = view
        return view
    end } }
    id = {
        Font = { MUSEO_SANS_15PT_REGULAR = 1, MUSEO_SANS_11PT_REGULAR = 2 },
        StyleSheet = { DROPDOWN_DEFAULT = 1, INPUT_DEFAULT = 2, BUTTON_DEFAULT = 3 },
        Sprite = { RS3_BUTTON_INFO_PARENT_0 = 28787, RS3_BUTTON_INFO_PARENT_1 = 32135,
            RS3_BUTTON_INFO_PARENT_2 = 32136 },
    }
    f.names = {
        getContext = function() return f.context end,
        get = function(slot) return f.stored[slot] end,
        save = function(slot, value)
            f.saveCalls = f.saveCalls + 1
            if f.saveMode == "error" then error("Simulated storage exception") end
            if f.saveMode == "rejected" then return false, "Simulated validation failure" end
            f.stored[slot] = value
            return true, "Name saved."
        end,
    }
    f.host = createControl("host")
    f.host.width, f.host.height = 600, 400
    f.parent = createControl("parent", f.host)
    f.parent.width, f.parent.height = 580, 360
    function f:open(initialSlot, options)
        if options and (options.scrollable or options.settings) and options.prettyui == nil then
            options.prettyui = prettyui
        end
        local firstNewControl = #self.controls + 1
        self.refresh, self.toggleInfo, self.destroy = dofile("editor/view.lua").build(self.parent, self.names, { presetCount = 18, colours = colours }, initialSlot, options)
        for index = firstNewControl, #self.controls do
            local control = self.controls[index]
            if control.kind == "list" and control.entries[17] then self.selector = control
            elseif control.kind == "input" then self.input = control
            elseif control.label == "Save" then self.save = control
            elseif control.label == "Reset" then self.reset = control
            elseif control.kind == "sprite" and control.sprite == 28787 then self.info = control
            elseif control.content == "Custom bank preset names" then self.title = control
            elseif control.kind == "text" and control.height == 18
                and control.y == math.max(0, math.floor((self.parent.height
                     - (options and options.hideTitle and 194 or 226)) / 2))
                    + 226 - (options and options.hideTitle and 32 or 0) then self.note = control
            elseif control.kind == "text" and control.content == "" then self.status = control end
        end
    end
    function f:select(entryID, event)
        self.selector.hooks[ui.Hook.ONSELECTIONCHANGED](self.selector, entryID,
            event or ui.SelectionChangeEvent.SELECTED)
    end
    function f:clickSave() self.save.hooks[ui.Hook.ONBUTTONPRESSED]() end
    function f:clickReset() self.reset.hooks[ui.Hook.ONBUTTONPRESSED]() end
    f:open()
    return f
end

test.case("Dropdown visibility checkbox is opt-in for settings and saves immediately", function()
    local f = createFixture()
    test.equal(f.checkbox, nil, "Ribbon and popup builds do not expose this setting")
    local hidden = false
    f:open(nil, { hideTitle = true, settings = {
        hidePredefinedDropdown = function() return hidden end,
        setHidePredefinedDropdown = function(value) hidden = value; return true end,
    } })
    local control = f.checkbox
    test.equal(control.selected, false)
    control:SetSelected("hideDropdown", true)
    f.refresh()
    test.equal(hidden, true)
    test.equal(control.selected, true)
    test.equal(f.saveCalls, 0, "Preference does not save or change a preset name")
    control:SetSelected("hideDropdown", false)
    f.refresh()
    test.equal(hidden, false)
    test.equal(control.selected, false)
    f.parent.height = 230
    f.parent.hooks[ui.Hook.ONRESIZE]()
    test.equal(control.root.y + control.root.height <= 230, true)
end)

test.case("Bottom buttons save and reset names and staged colours for the selected slot", function()
    local values, calls = {}, 0
    local colours = {
        get = function(slot, kind) return values[slot .. kind] or "" end,
        save = function(slot, kind, value)
            calls = calls + 1
            values[slot .. kind] = value
            return true, "Colour saved."
        end,
    }
    local f = createFixture(colours)
    local controls = {}
    for _, control in ipairs(f.controls) do
        if control.kind == "rectangle" and control.width == 32 then controls[#controls + 1] = control end
    end
    local function choose(index, hex)
        controls[index].hooks[ui.Hook.ONCLICK]()
        local input, apply
        for _, control in ipairs(f.controls) do
            if not control.destroyed and control.kind == "input" and control.limit == 7 then input = control end
            if control.label == "Apply" then apply = control end
        end
        input.content = hex
        input.hooks[ui.Hook.ONCONTENTCHANGED]()
        apply.hooks[ui.Hook.ONBUTTONPRESSED]()
    end
    test.equal(#controls, 2)
    test.equal(f.save.y > controls[1].y + controls[1].height, true)
    test.equal(controls[2].y - controls[1].y, 32, "Colour rows are stacked")
    test.equal(f.reset.y, f.save.y)
    test.equal(f.status.y >= f.save.y + f.save.height, true,
        "Save and failure messages sit below the buttons")
    test.equal(calls, 0)
    f:select(17)
    choose(1, "#008000")
    choose(2, "#FF0000")
    f.refresh()
    test.equal(controls[1].colour[2], 128 / 255, "Ticks preserve unsaved colours")
    test.equal(calls, 0)
    test.equal(f.saveCalls, 0)
    f.input.content = "Coloured preset"
    f:clickSave()
    test.equal(values["18background"], "#008000")
    test.equal(values["18text"], "#FF0000")
    test.equal(f.stored[18], "Coloured preset")
    f:clickReset()
    test.equal(values["18background"], "")
    test.equal(values["18text"], "")
    test.equal(f.stored[18], "")
    test.equal(controls[1].colour[1], require("editor/theme").background[1])
    test.equal(f.selector.entries[17], "Preset 18")
    choose(1, "#FF0000")
    f:clickSave()
    test.equal(f.selector.entries[17], "Preset 18 *", "Background alone marks the preset")
    f:clickReset()
    test.equal(values["18background"], "")
    f.context = "second"
    choose(2, "#0080FF")
    f:clickSave()
    test.equal(calls, 8, "Character change blocks all stale writes")
    f.refresh()
    choose(2, "#0080FF")
    f:select(0)
    f:select(17)
    test.equal(controls[2].colour[1], require("editor/theme").background[1], "Switching slots discards unsaved colours")
    choose(2, "#0080FF")
    f:clickSave()
    test.equal(calls, 10)
    test.equal(f.selector.entries[17], "Preset 18 *", "Text colour alone marks the preset")
end)

test.case("Colour picker validates hex, previews colours, cancels and restores defaults", function()
    local f = createFixture()
    local applied = "unchanged"
    local picker = require("editor/colour_picker")
    local function open()
        local first = #f.controls + 1
        local close = picker.open(f.parent, "#38A4FF", function(value) applied = value end)
        local found = { close = close, root = f.controls[first] }
        for i = first, #f.controls do
            local control = f.controls[i]
            if control.kind == "input" then found.input = control end
            if control.label then found[control.label] = control end
            if control.kind == "rectangle" and control.width == 44 then found.preview = control end
            if control.kind == "rectangle" and control.x == 12 and control.y == 200 then found.hue = control end
            if control.kind == "rectangle" and control.x == 265 and control.y == 36 then found.shade = control end
        end
        return found
    end
    local p = open()
    p.hue.hooks[ui.Hook.ONCLICK]()
    p.shade.hooks[ui.Hook.ONCLICK]()
    test.equal(p.input.content, "#FF0000", "Hue and shade controls update the exact colour")
    p.input.content = "#INVALID"
    p.Apply.hooks[ui.Hook.ONBUTTONPRESSED]()
    test.equal(applied, "unchanged")
    test.equal(p.root.destroyed, nil)
    p.input.content = "#12ab34"
    p.input.hooks[ui.Hook.ONCONTENTCHANGED]()
    test.equal(p.preview.colour[2], 171 / 255)
    p.Apply.hooks[ui.Hook.ONBUTTONPRESSED]()
    test.equal(applied, "#12AB34")
    test.equal(p.root.destroyed, true)
    p = open()
    p.Cancel.hooks[ui.Hook.ONBUTTONPRESSED]()
    test.equal(applied, "#12AB34")
    test.equal(p.root.destroyed, true)
    p = open()
    p.Default.hooks[ui.Hook.ONBUTTONPRESSED]()
    test.equal(applied, "")
    test.equal(p.root.destroyed, true)
    p.close() -- Idempotent cleanup after an action.
end)

test.case("Open colour pickers close on slot changes, character changes, hide and disposal", function()
    local f = createFixture({ get = function() return "" end })
    local swatch
    for _, control in ipairs(f.controls) do
        if control.kind == "rectangle" and control.width == 32 then swatch = control; break end
    end
    local function open()
        local first = #f.controls + 1
        swatch.hooks[ui.Hook.ONCLICK]()
        return f.controls[first]
    end
    local root = open()
    f:select(17)
    test.equal(root.destroyed, true)
    root = open()
    f.context = "other"
    f.refresh()
    test.equal(root.destroyed, true)
    root = open()
    f.parent.visibleGlobal = false
    f.refresh()
    test.equal(root.destroyed, true)
    f.parent.visibleGlobal = true
    root = open()
    f.destroy()
    test.equal(root.destroyed, true)
end)

test.case("Colour swatches retain their size and fit narrow scrolled panels", function()
    local f = createFixture({ get = function() return "#000000" end })
    f.parent.width, f.parent.height = 200, 180
    f:open(nil, { scrollable = true })
    local swatches = 0
    for _, control in ipairs(f.controls) do
        if control.parent == f.scrollView.content and control.kind == "rectangle" and control.width == 32 then
            swatches = swatches + 1
            test.equal(control.x + control.width <= f.scrollView.contentWidth, true)
            test.equal(control.height, 20)
        end
    end
    test.equal(swatches, 2)
    f.destroy()
end)

test.case("Colour picker anchors beside its swatch, follows movement and clamps to the screen", function()
    local f = createFixture()
    f.host.xyGlobal = { x = 100, y = 200 }
    local anchor = { xyGlobal = { x = 300, y = 250 }, width = 32 }
    local first = #f.controls + 1
    local close, update = require("editor/colour_picker").open(f.parent, "#FFFFFF", function() end, anchor)
    local root = f.controls[first]
    test.equal(root.x, 240, "Picker opens just right of the swatch in the overlay's coordinates")
    test.equal(root.y, 50)
    anchor.xyGlobal = { x = 600, y = 390 }
    update()
    test.equal(root.x, 204, "Picker flips left when the right side does not fit")
    test.equal(root.y, 74, "Picker stays above the bottom screen edge")
    anchor.xyGlobal = { x = 80, y = 180 }
    update()
    test.equal(root.x >= 0, true)
    test.equal(root.y, 0)
    close()
    update() -- A disposed picker must not be repositioned.
end)

test.case("Colour picker joins the PrettyUI window overlay stack and unregisters on close", function()
    local f = createFixture()
    local owner = { overlays = {}, syncs = 0 }
    function owner:_RegisterOverlay(root, _, position)
        self.overlays[root] = position
    end
    function owner:_UnregisterOverlay(root)
        test.equal(root.destroyed, nil, "Unregister before disposing the native layer")
        self.overlays[root] = nil
    end
    function owner:_SyncOverlays(hidden)
        test.equal(hidden, false)
        self.syncs = self.syncs + 1
        for _, position in pairs(self.overlays) do position() end
    end
    local anchor = { xyGlobal = { x = 50, y = 50 }, width = 32 }
    local first = #f.controls + 1
    local close = require("editor/colour_picker").open(f.parent, "#FFFFFF", function() end, anchor, owner)
    local root = f.controls[first]
    test.equal(type(owner.overlays[root]), "function")
    test.equal(owner.syncs, 1, "Synchronize the newly opened overlay immediately")
    anchor.xyGlobal.x = 100
    owner:_SyncOverlays(false) -- Same synchronization used when PrettyUI moves/focuses its window.
    test.equal(root.x, 140)
    close()
    test.equal(owner.overlays[root], nil)
    test.equal(root.destroyed, true)
    close()
end)

test.case("Settings info uses the same native icon states as the popup", function()
    local f = createFixture()
    test.equal(f.info.sprite, 28787)
    test.equal(f.info.label, nil)
    test.equal(f.info.clickthrough, false)
    f.info.isMouseOver = true
    f.refresh()
    test.equal(f.info.sprite, 32135)
    f.info.isClicked = true
    f.refresh()
    test.equal(f.info.sprite, 32136)
    f.info.isMouseOver, f.info.isClicked = false, false
    f.refresh()
    test.equal(f.info.sprite, 28787)
end)

test.case("Editor starts at preset 1 with all 18 zero-based dropdown entries", function()
    local f = createFixture()
    for slot = 1, 18 do
        test.equal(f.selector.entries[slot - 1], "Preset " .. slot .. (slot == 18 and " *" or ""))
    end
    test.equal(f.selector.entries[18], nil)
    test.equal(f.selector.selectedID, 0)
    test.equal(f.input.content, "")
    test.equal(f.input.limit, 40)
    test.equal(f.saveCalls, 0, "Opening must not save")
end)

test.case("Preset markers follow saved names, blank saves, resets and external edits", function()
    local f = createFixture()
    f.input.content = "Custom"
    f.refresh()
    test.equal(f.selector.entries[0], "Preset 1")
    f:clickSave()
    test.equal(f.selector.entries[0], "Preset 1 *")
    f:clickReset()
    test.equal(f.selector.entries[0], "Preset 1")
    f:select(17)
    f.input.content = ""
    f:clickSave()
    test.equal(f.selector.entries[17], "Preset 18")
    test.equal(f.selector.selectedID, 17)
    f.stored[2] = "Another editor"
    f.input.content = "Keep unsaved edit"
    f.refresh()
    test.equal(f.selector.entries[1], "Preset 2 *")
    test.equal(f.input.content, "Keep unsaved edit")
    f.context, f.stored = "second", {}
    f.refresh()
    test.equal(f.selector.entries[1], "Preset 2")
end)

test.case("Custom name label and save status use the smaller font", function()
    local f = createFixture()
    local label
    for _, control in ipairs(f.controls) do
        if control.content == "Custom name (blank = predefined):" then label = control end
    end
    test.equal(label.font, id.Font.MUSEO_SANS_11PT_REGULAR)
    f:clickSave()
    test.equal(f.status.content, "Name saved.")
    test.equal(f.status.colour[2] > f.status.colour[1], true, "Success is green")
    test.equal(f.status.font, id.Font.MUSEO_SANS_11PT_REGULAR)
    test.equal(f.title.font, id.Font.MUSEO_SANS_15PT_REGULAR)
end)

test.case("Status colours switch between success and failure without icons", function()
    local f = createFixture()
    for _, control in ipairs(f.controls) do
        test.equal(control.kind == "line", false)
    end
    f:clickSave()
    test.equal(f.status.content, "Name saved.")
    test.equal(f.status.colour[2] > f.status.colour[1], true)
    f.saveMode = "rejected"
    f:clickSave()
    test.equal(f.status.content, "Simulated validation failure")
    test.equal(f.status.colour[1] > f.status.colour[2], true)
    f:select(17)
    test.equal(f.status.content, "")
end)

test.case("Direct editing starts at the clicked preset and saves only that slot", function()
    local f = createFixture()
    f:open(18)
    test.equal(f.selector.selectedID, 17)
    test.equal(f.input.content, "Last preset")
    test.equal(f.saveCalls, 0)
    f.input.content = "Direct edit"
    f:clickSave()
    test.equal(f.stored[18], "Direct edit")
    test.equal(f.stored[1], nil)
end)

test.case("Invalid direct-edit slots fall back to preset 1", function()
    local f = createFixture()
    for _, slot in ipairs({ 0, 19, 1.5, "18" }) do
        f:open(slot)
        test.equal(f.selector.selectedID, 0)
    end
end)

test.case("Popup editor omits its duplicate title and fits beneath window chrome", function()
    local f = createFixture()
    f.parent.width, f.parent.height = 352, 194
    local first = #f.controls + 1
    f:open(18, { hideTitle = true })
    for index = first, #f.controls do
        local c = f.controls[index]
        test.equal(c.content == "Custom bank preset names", false)
        if c.content ~= "" then
            test.equal(c.y >= 0 and c.y + c.height <= 194, true, "Visible control fits popup content")
        end
    end
    test.equal(f.selector.y, 16)
    test.equal(f.input.content, "Last preset")
end)

test.case("Editor centres controls without resizing host layers and clamps small layouts", function()
    local f = createFixture()
    test.equal(f.parent.width, 580)
    test.equal(f.parent.height, 360)
    test.equal(f.host.width, 600)
    test.equal(f.host.height, 400)
    test.equal(f.title.x, 130)
    test.equal(f.title.y, 75)
    test.equal(f.title.parent, f.parent, "Controls attach directly to supplied layer")
    test.equal(f.title.parentX, nil)
    test.equal(f.title.selfX, nil)
    f.parent.width, f.parent.height = 640, 400
    f.parent.hooks[ui.Hook.ONRESIZE]()
    test.equal(f.title.x, 160)
    test.equal(f.title.y, 95)
    f.parent.width, f.parent.height = 300, 200
    f.parent.hooks[ui.Hook.ONRESIZE]()
    test.equal(f.title.x, 8)
    test.equal(f.title.y, 11)
    test.equal(f.input.x + f.input.width <= 300, true)
    test.equal(f.status.y + f.status.height <= 200, true)
end)

test.case("Plugin Hub settings info stays at the top-right after resizing", function()
    local f = createFixture()
    f:open(nil, { hideTitle = true })
    for _, size in ipairs({ { 580, 360 }, { 700, 400 }, { 300, 240 } }) do
        f.parent.width, f.parent.height = size[1], size[2]
        f.parent.hooks[ui.Hook.ONRESIZE]()
        test.equal(f.info.hidden, false)
        test.equal(f.info.x, size[1] - 8 - 22)
        test.equal(f.info.y, 8)
    end
end)

test.case("Resizable ribbon fits narrow panels and restores the wide layout without losing edits", function()
    local colours = {
        get = function() return "" end,
        save = function() return true end,
    }
    local f = createFixture(colours)
    local first = #f.controls + 1
    f.parent.width, f.parent.height = 260, 260
    f:open(18)
    f.input.content = "Unsaved edit"
    for _, size in ipairs({ { 260, 260 }, { 300, 280 }, { 240, 246 }, { 580, 360 } }) do
        f.parent.width, f.parent.height = size[1], size[2]
        f.parent.hooks[ui.Hook.ONRESIZE]()
        for index = first, #f.controls do
            local c = f.controls[index]
            test.equal(c.x >= 0 and c.x + c.width <= size[1], true, "Control fits panel width")
            test.equal(c.y >= 0 and c.y + c.height <= size[2], true, "Control fits panel height")
        end
        test.equal(f.input.content, "Unsaved edit")
        test.equal(f.selector.selectedID, 17)
    end
    test.equal(f.input.width, 320)
    test.equal(f.title.content, "Custom bank preset names")
    test.equal(f.saveCalls, 0)
end)

test.case("Ribbon reports an unavailable PrettyUI dependency before creating controls", function()
    local f = createFixture()
    local dependency = prettyui
    prettyui = nil
    local before = #f.controls
    local ok, message = pcall(function() f:open(nil, { scrollable = true }) end)
    prettyui = dependency
    test.equal(ok, false)
    test.equal(tostring(message):find("PrettyUI is required", 1, true) ~= nil, true)
    test.equal(#f.controls, before)
end)

test.case("Ribbon uses the dependency passed by main even without a module global", function()
    local f = createFixture()
    local dependency = prettyui
    prettyui = nil
    local ok, message = pcall(function()
        f:open(18, { scrollable = true, prettyui = dependency })
    end)
    prettyui = dependency
    test.equal(ok, true, tostring(message))
    test.equal(f.input.parent, f.scrollView.content)
    test.equal(f.selector.selectedID, 17)
    f.destroy()
end)

test.case("Small ribbon panels scroll to Save and reset their offset when enlarged", function()
    local f = createFixture({
        get = function() return "" end, save = function() return true end,
    })
    f.parent.width, f.parent.height = 200, 120
    f:open(18, { scrollable = true })
    f.input.content = "Keep this edit"
    test.equal(f.save.hidden, true)
    test.equal(f.scrollView.scrollbarVisible, true)
    test.equal(f.input.parent, f.scrollView.content)
    test.equal(f.input.width <= f.scrollView.contentWidth, true)
    test.equal(f.input.hooks[ui.Hook.ONSCROLLWHEEL](f.input, 100), false)
    f.refresh()
    test.equal(f.save.hidden, false)
    local visibleY = f.save.y - f.scrollView.scrollY
    test.equal(visibleY >= 0 and visibleY + f.save.height <= 120, true)
    f.parent.width, f.parent.height = 580, 360
    f.parent.hooks[ui.Hook.ONRESIZE]()
    test.equal(f.scrollView.scrollbarVisible, false)
    test.equal(f.scrollView.scrollY, 0)
    test.equal(f.save.hidden, false)
    test.equal(f.input.content, "Keep this edit")
    test.equal(f.selector.selectedID, 17)
    test.equal(f.saveCalls, 0)
    f.destroy()
    test.equal(f.scrollView.destroyed, true)
end)

test.case("Managed ribbon input submits once and uses PrettyUI clipping", function()
    local f = createFixture()
    f.parent.width, f.parent.height = 200, 120
    f:open(18, { scrollable = true })
    test.equal(f.input.contentClipped, true)
    test.equal(f.input.hidden, nil, "PrettyUI clips input visuals rather than hiding the field")
    f.input.content = "Managed input"
    f.input.hooks[ui.Hook.ONCONTENTCHANGED](f.input, 0)
    test.equal(f.saveCalls, 0)
    f.input.hooks[ui.Hook.ONCONTENTCHANGED](f.input, ui.InputFieldActionResult.SUBMIT)
    test.equal(f.saveCalls, 1)
    test.equal(f.stored[18], "Managed input")
    f.parent.height = 400
    f.parent.hooks[ui.Hook.ONRESIZE]()
    test.equal(f.input.contentClipped, false)
    f.destroy()
end)

test.case("Editor info button reveals and hides scope notes without saving or changing edits", function()
    local f = createFixture()
    local originalY = f.input.y
    f.input.content = "Unsaved edit"
    f.info.hooks[ui.Hook.ONCLICK]()
    local text = {}
    for _, control in ipairs(f.controls) do
        if control.kind == "text" then text[control.content] = true end
    end
    test.equal(text["Changes names and colours only."], true)
    test.equal(text["Does not load presets or unlock slots."], true)
    test.equal(text["Stored on this device, per character name."], true)
    test.equal(f.input.y, originalY, "Help must not move the form")
    local note = f.controls[#f.controls]
    f.info.hooks[ui.Hook.ONCLICK]()
    test.equal(note.destroyed, true)
    test.equal(f.input.content, "Unsaved edit")
    test.equal(f.saveCalls, 0)
end)

test.case("Editor popover stays within its host without resizing or losing the selected preset", function()
    local f = createFixture()
    local heights = {}
    f:open(18, { hideTitle = true, externalInfoButton = true,
        onHeightChanged = function(height) heights[#heights + 1] = height end })
    f.toggleInfo()
    f.toggleInfo()
    local layout = require("editor/layout")
    test.equal(#heights, 0, "Popover never requests a layout resize")
    test.equal(f.parent.height, 360)
    test.equal(f.selector.selectedID, 17)
    test.equal(f.saveCalls, 0)
end)

test.case("Selecting the last entry saves and resets slot 18, not slot 17", function()
    local f = createFixture()
    f:select(17)
    test.equal(f.input.content, "Last preset")
    f.input.content = "Edited last preset"
    f:select(0, ui.SelectionChangeEvent.DESELECTED)
    test.equal(f.input.content, "Edited last preset")
    f:clickSave()
    test.equal(f.stored[18], "Edited last preset")
    test.equal(f.stored[17], nil)
    test.equal(f.stored[1], nil)
    f:clickReset()
    test.equal(f.stored[18], "")
    test.equal(f.input.content, "")
end)

test.case("Invalid selections and reselecting the current slot preserve unsaved edits", function()
    local f = createFixture()
    f.input.content = "Unsaved"
    for _, entryID in ipairs({ -1, 18, 999, 0 }) do
        f:select(entryID)
        test.equal(f.input.content, "Unsaved", "Ignored entry " .. entryID)
    end
    f:clickSave()
    test.equal(f.stored[1], "Unsaved")
end)

test.case("Switching slots discards unsaved edits without writing them", function()
    local f = createFixture()
    f.input.content = "Discard this"
    f:select(17)
    test.equal(f.input.content, "Last preset")
    test.equal(f.saveCalls, 0)
end)

test.case("Enter submits input but ordinary content-change events do not save", function()
    local f = createFixture()
    f.input.content = "Enter saved"
    f.input.hooks[ui.Hook.ONCONTENTCHANGED](f.input, 0)
    test.equal(f.saveCalls, 0)
    f.input.hooks[ui.Hook.ONCONTENTCHANGED](f.input, ui.InputFieldActionResult.SUBMIT)
    test.equal(f.stored[1], "Enter saved")
    test.equal(f.status.content, "Name saved.")
end)

test.case("Rejected saves and resets preserve edits and show the validation message", function()
    local f = createFixture()
    f.saveMode = "rejected"
    f.input.content = "Keep this edit"
    f:clickSave()
    test.equal(f.status.content, "Simulated validation failure")
    test.equal(f.status.colour[1] > f.status.colour[2], true, "Failure is red")
    f:clickReset()
    test.equal(f.input.content, "Keep this edit")
    test.equal(f.stored[1], nil)
end)

test.case("Storage exceptions are caught, logged, and displayed without clearing edits", function()
    local f = createFixture()
    f.saveMode = "error"
    f.input.content = "Keep this edit"
    local originalPrint, logged = print, nil
    print = function(message) logged = message end
    local succeeded, message = pcall(function() f:clickSave() end)
    print = originalPrint -- Restore even if the editor unexpectedly throws.
    test.equal(succeeded, true, message)
    test.equal(logged:find("Simulated storage exception", 1, true) ~= nil, true)
    test.equal(f.status.content, "Save error. See the client console.")
    test.equal(f.input.content, "Keep this edit")
end)

for _, action in ipairs({ "save", "reset" }) do
    test.case("Character changes block a stale " .. action, function()
        local f = createFixture()
        f.input.content = "Previous character edit"
        f.context, f.stored = "second", { [1] = "Other character" }
        if action == "save" then f:clickSave() else f:clickReset() end
        test.equal(f.saveCalls, 0)
        test.equal(f.input.content, "Other character")
        test.equal(f.status.content, "Character changed. Enter the name again.")
    end)
end

test.case("Tick refresh follows character changes and logout but preserves same-character edits", function()
    local f = createFixture()
    f.input.content = "Unsaved edit"
    f.refresh()
    test.equal(f.input.content, "Unsaved edit")
    f.context, f.stored = "second", { [1] = "Second character" }
    f.refresh()
    test.equal(f.input.content, "Second character")
    f.context, f.stored = nil, {}
    f.refresh()
    test.equal(f.input.content, "")
    test.equal(f.status.content, "Log in and wait for your character name.")
end)

test.case("Reopening starts at preset 1 without overwriting saved settings", function()
    local f = createFixture()
    f.stored[1] = "First preset"
    f:select(17)
    f:open()
    test.equal(f.selector.selectedID, 0)
    test.equal(f.input.content, "First preset")
    test.equal(f.stored[18], "Last preset")
    test.equal(f.saveCalls, 0)
end)
