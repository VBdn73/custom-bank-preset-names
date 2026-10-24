local editor = {}

local function text(parent, content, x, y, width)
    local label = ui.Text.new(parent)
    label:SetPos(x, y)
    label:SetSize(width, 28)
    label.font = id.Font.MUSEO_SANS_15PT_REGULAR
    label.content = content
    return label
end

local function button(parent, label, x, y, width, callback)
    local control = ui.Button.new(parent)
    control:SetPos(x, y)
    control:SetSize(width, 30)
    control.stylesheetID = id.StyleSheet.BUTTON_DEFAULT
    control.label = label
    control:Subscribe(ui.Hook.ONBUTTONPRESSED, callback)
    return control
end

function editor.build(parent, names, bindings)
    -- Position controls directly on the supplied layer. An extra nested layer
    -- is positioned unexpectedly by the beta client's settings host.
    local width, height = 336, 254
    local positions = {}
    local function track(component, x, y)
        positions[#positions + 1] = { component = component, x = x, y = y }
        return component
    end
    local slot = 1
    track(text(parent, "Custom bank preset names", 8, 8, 320), 8, 8)
    local selector = ui.List.new(parent)
    track(selector, 8, 48)
    selector:SetPos(8, 48)
    selector:SetSize(320, 32)
    selector.stylesheetID = id.StyleSheet.DROPDOWN_DEFAULT
    selector.dropdownMaxVisibleEntries = 8
    selector.entryHeight = 28
    for preset = 1, bindings.presetCount do
        -- Insert in display order with zero-based IDs, matching the native list.
        -- Storage and bank bindings remain one-based preset numbers.
        selector:Add("Preset " .. preset, preset - 1)
    end
    selector:SetEntrySelected(0, true, false)
    track(text(parent, "Custom name (blank = predefined):", 8, 90, 320), 8, 90)
    local input = ui.InputField.new(parent)
    track(input, 8, 122)
    input:SetPos(8, 122)
    input:SetSize(320, 32)
    input.stylesheetID = id.StyleSheet.INPUT_DEFAULT
    input:Setup(ui.TextContentVisibilityMode.VISIBLE, ui.InputFieldFilterMode.NONE, 40)
    input.emptyText = "Use predefined name"
    local status = text(parent, "", 8, 198, 320)
    track(status, 8, 198)
    local note = text(parent, "Stored on this device, per character name.", 8, 226, 320)
    track(note, 8, 226)
    note.font = id.Font.MUSEO_SANS_11PT_REGULAR or id.Font.MUSEO_SANS_15PT_REGULAR
    note:SetSize(320, 18)

    local context = names.getContext()
    local function refresh()
        context = names.getContext()
        input.content = names.get(slot) or ""
        status.content = context and "" or "Log in and wait for your character name."
    end
    local function saveValue(value)
        if names.getContext() ~= context then
            refresh()
            status.content = "Character changed. Enter the name again."
            return false
        end
        local called, ok, message = pcall(names.save, slot, value)
        if not called then
            print("[Preset names] Save error: " .. tostring(ok))
            status.content = "Save error. See the client console."
            return false
        end
        status.content = message
        return ok
    end
    local function save()
        saveValue(input.content)
    end
    selector:Subscribe(ui.Hook.ONSELECTIONCHANGED, function(_, entryID, event)
        local preset = entryID + 1
        if event == ui.SelectionChangeEvent.SELECTED
            and preset >= 1 and preset <= bindings.presetCount and preset ~= slot then
            slot = preset
            refresh()
        end
    end)
    track(button(parent, "Save", 8, 166, 150, save), 8, 166)
    track(button(parent, "Reset", 178, 166, 150, function()
        local ok = saveValue("")
        if ok then input.content = "" end
    end), 178, 166)
    input:Subscribe(ui.Hook.ONCONTENTCHANGED, function(_, reason)
        if reason == ui.InputFieldActionResult.SUBMIT then save() end
    end)
    refresh()
    local function centreContent()
        local x = math.max(0, math.floor((parent.width - width) / 2))
        local y = math.max(0, math.floor((parent.height - height) / 2))
        for _, position in ipairs(positions) do
            position.component:SetPos(x + position.x, y + position.y)
        end
    end
    centreContent()
    parent:Subscribe(ui.Hook.ONRESIZE, "presetNames.centre", centreContent)
    return function()
        if names.getContext() ~= context then refresh() end
    end
end

return editor
