local test = require("tests.test_helper")

-- Mock only the native API used by the editor. No actual client UI is created.
local function createFixture()
    local f = { controls = {}, stored = { [18] = "Last preset" }, context = "first",
        saveCalls = 0, saveMode = "success" }
    local function createControl(kind, parent)
        local control = { kind = kind, parent = parent, entries = {}, hooks = {} }
        function control:SetPos(x, y, parentX, parentY, selfX, selfY)
            self.x, self.y = x, y
            self.parentX, self.selfX = parentX, selfX
        end
        function control:SetSize(width, height) self.width, self.height = width, height end
        function control:Setup(visibility, filter, limit)
            self.visibility, self.filter, self.limit = visibility, filter, limit
        end
        function control:Subscribe(hook, reference, callback) self.hooks[hook] = callback or reference end
        function control:Add(label, entryID) self.entries[entryID] = label end
        function control:SetEntrySelected(entryID, selected, triggerEvents)
            test.equal(selected, true)
            test.equal(triggerEvents, false, "Initialization must not trigger selection events")
            self.selectedID = entryID
        end
        f.controls[#f.controls + 1] = control
        return control
    end
    ui = {
        Text = { new = function(parent) return createControl("text", parent) end },
        Button = { new = function(parent) return createControl("button", parent) end },
        InputField = { new = function(parent) return createControl("input", parent) end },
        List = { new = function(parent) return createControl("list", parent) end },
        Hook = { ONBUTTONPRESSED = 1, ONCONTENTCHANGED = 2, ONSELECTIONCHANGED = 3, ONRESIZE = 4 },
        SelectionChangeEvent = { SELECTED = 1, DESELECTED = 0 },
        TextContentVisibilityMode = { VISIBLE = 0 }, InputFieldFilterMode = { NONE = 0 },
        InputFieldActionResult = { SUBMIT = 1 },
    }
    Vector4 = { new = function(...) return { ... } end }
    id = {
        Font = { MUSEO_SANS_15PT_REGULAR = 1, MUSEO_SANS_11PT_REGULAR = 2 },
        StyleSheet = { DROPDOWN_DEFAULT = 1, INPUT_DEFAULT = 2, BUTTON_DEFAULT = 3 },
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
        local firstNewControl = #self.controls + 1
        self.refresh = dofile("editor/view.lua").build(self.parent, self.names, { presetCount = 18 }, initialSlot, options)
        for index = firstNewControl, #self.controls do
            local control = self.controls[index]
            if control.kind == "list" then self.selector = control
            elseif control.kind == "input" then self.input = control
            elseif control.label == "Save" then self.save = control
            elseif control.label == "Reset" then self.reset = control
            elseif control.label == "i" then self.info = control
            elseif control.content == "Custom bank preset names" then self.title = control
            elseif control.kind == "text" and control.height == 18
                and control.y == math.max(0, math.floor((self.parent.height
                    - (options and options.hideTitle and 262 or 294)) / 2))
                    + 226 - (options and options.hideTitle and 32 or 0) then self.note = control
            elseif control.kind == "text" and control.content == "" and control.height == 28 then self.status = control end
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

test.case("Editor starts at preset 1 with all 18 zero-based dropdown entries", function()
    local f = createFixture()
    for slot = 1, 18 do test.equal(f.selector.entries[slot - 1], "Preset " .. slot) end
    test.equal(f.selector.entries[18], nil)
    test.equal(f.selector.selectedID, 0)
    test.equal(f.input.content, "")
    test.equal(f.input.limit, 40)
    test.equal(f.saveCalls, 0, "Opening must not save")
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
    f.parent.width, f.parent.height = 352, 262
    local first = #f.controls + 1
    f:open(18, { hideTitle = true })
    for index = first, #f.controls do
        local c = f.controls[index]
        test.equal(c.content == "Custom bank preset names", false)
        test.equal(c.y >= 0 and c.y + c.height <= 262, true, "Control fits popup content")
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
    test.equal(f.title.y, 41)
    test.equal(f.title.parent, f.parent, "Controls attach directly to supplied layer")
    test.equal(f.title.parentX, nil)
    test.equal(f.title.selfX, nil)
    f.parent.width, f.parent.height = 640, 400
    f.parent.hooks[ui.Hook.ONRESIZE]()
    test.equal(f.title.x, 160)
    test.equal(f.title.y, 61)
    f.parent.width, f.parent.height = 300, 200
    f.parent.hooks[ui.Hook.ONRESIZE]()
    test.equal(f.title.x, 8)
    test.equal(f.title.y, 8)
    test.equal(f.note.font, id.Font.MUSEO_SANS_11PT_REGULAR)
    test.equal(f.note.height, 18)
end)

test.case("Editor info button reveals and hides scope notes without saving or changing edits", function()
    local f = createFixture()
    test.equal(f.note.content, "")
    f.input.content = "Unsaved edit"
    f.info.hooks[ui.Hook.ONBUTTONPRESSED]()
    local text = {}
    for _, control in ipairs(f.controls) do
        if control.kind == "text" then text[control.content] = true end
    end
    test.equal(text["Changes displayed names only."], true)
    test.equal(text["Does not load presets or unlock slots."], true)
    test.equal(f.note.content, "Stored on this device, per character name.")
    f.info.hooks[ui.Hook.ONBUTTONPRESSED]()
    test.equal(f.note.content, "")
    test.equal(f.input.content, "Unsaved edit")
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
