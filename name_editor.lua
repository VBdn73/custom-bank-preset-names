local editor = {}

local function createText(parent, content, x, y, width)
    local label = ui.Text.new(parent)
    label:SetPos(x, y)
    label:SetSize(width, 28)
    label.font = id.Font.MUSEO_SANS_15PT_REGULAR
    label.content = content
    return label
end

local function createButton(parent, label, x, y, width, callback)
    local control = ui.Button.new(parent)
    control:SetPos(x, y)
    control:SetSize(width, 30)
    control.stylesheetID = id.StyleSheet.BUTTON_DEFAULT
    control.label = label
    control:Subscribe(ui.Hook.ONBUTTONPRESSED, callback)
    return control
end

function editor.build(parent, names, bindings, initialSlot, options)
    options = options or {}
    -- Position controls directly on the supplied layer. An extra nested layer
    -- is positioned unexpectedly by the beta client's settings host.
    local contentWidth, contentHeight = 336, 294
    if options.hideTitle then contentHeight = contentHeight - 32 end
    local controlPositions = {}
    local function trackPosition(component, x, y)
        controlPositions[#controlPositions + 1] = {
            component = component, x = x, y = y - (options.hideTitle and 32 or 0),
        }
        return component
    end

    -- Build the controls in display order, using offsets within the editor.
    local selectedSlot = initialSlot or 1
    if type(selectedSlot) ~= "number" or selectedSlot % 1 ~= 0
        or selectedSlot < 1 or selectedSlot > bindings.presetCount then
        selectedSlot = 1
    end
    if not options.hideTitle then
        trackPosition(createText(parent, "Custom bank preset names", 8, 8, 320), 8, 8)
    end
    local presetSelector = ui.List.new(parent)
    trackPosition(presetSelector, 8, 48)
    presetSelector:SetPos(8, 48)
    presetSelector:SetSize(320, 32)
    presetSelector.stylesheetID = id.StyleSheet.DROPDOWN_DEFAULT
    presetSelector.dropdownMaxVisibleEntries = 8
    presetSelector.entryHeight = 28
    for preset = 1, bindings.presetCount do
        -- Insert in display order with zero-based IDs, matching the native list.
        -- Storage and bank bindings remain one-based preset numbers.
        presetSelector:Add("Preset " .. preset, preset - 1)
    end
    presetSelector:SetEntrySelected(selectedSlot - 1, true, false)
    trackPosition(createText(parent, "Custom name (blank = predefined):", 8, 90, 320), 8, 90)

    local nameInput = ui.InputField.new(parent)
    trackPosition(nameInput, 8, 122)
    nameInput:SetPos(8, 122)
    nameInput:SetSize(320, 32)
    nameInput.stylesheetID = id.StyleSheet.INPUT_DEFAULT
    nameInput:Setup(ui.TextContentVisibilityMode.VISIBLE, ui.InputFieldFilterMode.NONE, 40)
    nameInput.emptyText = "Use predefined name"

    local statusLabel = createText(parent, "", 8, 198, 320)
    trackPosition(statusLabel, 8, 198)
    local storageNote = createText(parent, "Stored on this device, per character name.", 8, 226, 320)
    trackPosition(storageNote, 8, 226)
    storageNote.font = id.Font.MUSEO_SANS_11PT_REGULAR or id.Font.MUSEO_SANS_15PT_REGULAR
    storageNote:SetSize(320, 18)

    -- Explain the display-only scope where players edit names, not just in the README.
    for index, text in ipairs({ "Changes displayed names only.", "Does not load presets or unlock slots." }) do
        local y = 246 + (index - 1) * 20
        local note = createText(parent, text, 8, y, 320)
        trackPosition(note, 8, y)
        note.font = storageNote.font
        note:SetSize(320, 18)
    end

    local displayedCharacterContext = names.getContext()
    local function refreshSelectedName()
        displayedCharacterContext = names.getContext()
        nameInput.content = names.get(selectedSlot) or ""
        statusLabel.content = displayedCharacterContext and "" or "Log in and wait for your character name."
    end

    local function saveValue(value)
        -- Do not save an old character's unfinished edit under a new character.
        if names.getContext() ~= displayedCharacterContext then
            refreshSelectedName()
            statusLabel.content = "Character changed. Enter the name again."
            return false
        end

        -- pcall separates unexpected host errors from ordinary validation failures.
        local callSucceeded, saveSucceeded, message = pcall(names.save, selectedSlot, value)
        if not callSucceeded then
            print("[Preset names] Save error: " .. tostring(saveSucceeded))
            statusLabel.content = "Save error. See the client console."
            return false
        end
        statusLabel.content = message
        return saveSucceeded
    end

    local function saveInput()
        saveValue(nameInput.content)
    end

    -- Wire user actions after the controls and their shared state exist.
    presetSelector:Subscribe(ui.Hook.ONSELECTIONCHANGED, function(_, entryID, event)
        local selectedPreset = entryID + 1
        if event == ui.SelectionChangeEvent.SELECTED
            and selectedPreset >= 1 and selectedPreset <= bindings.presetCount
            and selectedPreset ~= selectedSlot then
            selectedSlot = selectedPreset
            refreshSelectedName()
        end
    end)
    trackPosition(createButton(parent, "Save", 8, 166, 150, saveInput), 8, 166)
    trackPosition(createButton(parent, "Reset", 178, 166, 150, function()
        local saveSucceeded = saveValue("")
        if saveSucceeded then
            nameInput.content = ""
        end
    end), 178, 166)
    nameInput:Subscribe(ui.Hook.ONCONTENTCHANGED, function(_, reason)
        if reason == ui.InputFieldActionResult.SUBMIT then
            saveInput()
        end
    end)
    refreshSelectedName()

    local function centreContent()
        local offsetX = math.max(0, math.floor((parent.width - contentWidth) / 2))
        local offsetY = math.max(0, math.floor((parent.height - contentHeight) / 2))
        for _, position in ipairs(controlPositions) do
            position.component:SetPos(offsetX + position.x, offsetY + position.y)
        end
    end
    centreContent()
    parent:Subscribe(ui.Hook.ONRESIZE, "presetNames.centre", centreContent)

    -- Called by main.lua each logic tick, not only when the editor is opened.
    return function()
        if names.getContext() ~= displayedCharacterContext then
            refreshSelectedName()
        end
    end
end

return editor
