local constants = require("constants")
local layout = require("editor_layout")
local theme = require("editor_theme")
local editor = {}

local function createText(parent, content, font)
    local label = ui.Text.new(parent)
    label:SetSize(layout.controlWidth, layout.textHeight)
    label.font = font or id.Font.MUSEO_SANS_15PT_REGULAR
    label.content = content
    return label
end

local function createButton(parent, label, callback)
    local control = ui.Button.new(parent)
    control:SetSize(layout.buttonWidth, layout.buttonHeight)
    control.stylesheetID = id.StyleSheet.BUTTON_DEFAULT
    control.label = label
    control:Subscribe(ui.Hook.ONBUTTONPRESSED, callback)
    return control
end

function editor.build(parent, names, bindings, initialSlot, options)
    options = options or {}
    -- Position controls directly on the supplied layer. An extra nested layer
    -- is positioned unexpectedly by the beta client's settings host.
    local contentWidth = layout.width
    local contentHeight = options.hideTitle and layout.bodyHeight or layout.height
    local controlPositions = {}
    local function trackPosition(component, x, y)
        controlPositions[#controlPositions + 1] = {
            component = component, x = x, y = y - (options.hideTitle and layout.titleHeight or 0),
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
        trackPosition(createText(parent, constants.editorTitle), layout.padding, layout.rows.title)
    end
    local presetSelector = ui.List.new(parent)
    trackPosition(presetSelector, layout.padding, layout.rows.selector)
    presetSelector:SetSize(layout.controlWidth, layout.fieldHeight)
    presetSelector.stylesheetID = id.StyleSheet.DROPDOWN_DEFAULT
    presetSelector.dropdownMaxVisibleEntries = layout.dropdownVisibleEntries
    presetSelector.entryHeight = layout.textHeight
    for preset = 1, bindings.presetCount do
        -- Insert in display order with zero-based IDs, matching the native list.
        -- Storage and bank bindings remain one-based preset numbers.
        presetSelector:Add("Preset " .. preset, preset - 1)
    end
    presetSelector:SetEntrySelected(selectedSlot - 1, true, false)
    local smallFont = id.Font.MUSEO_SANS_11PT_REGULAR or id.Font.MUSEO_SANS_15PT_REGULAR
    trackPosition(createText(parent, "Custom name (blank = predefined):", smallFont),
        layout.padding, layout.rows.nameLabel)

    local nameInput = ui.InputField.new(parent)
    trackPosition(nameInput, layout.padding, layout.rows.input)
    nameInput:SetSize(layout.controlWidth, layout.fieldHeight)
    nameInput.stylesheetID = id.StyleSheet.INPUT_DEFAULT
    nameInput:Setup(ui.TextContentVisibilityMode.VISIBLE, ui.InputFieldFilterMode.NONE,
        constants.maximumNameLength)
    nameInput.emptyText = "Use predefined name"

    local statusLabel = createText(parent, "", smallFont)
    trackPosition(statusLabel, layout.padding, layout.rows.status)
    local function setStatus(message, succeeded)
        statusLabel.content = message
        statusLabel.colour = theme.colour(succeeded and theme.success or theme.error)
    end
    local storageNote = createText(parent, "Stored on this device, per character name.", smallFont)
    trackPosition(storageNote, layout.padding, layout.rows.storageNote)
    storageNote:SetSize(layout.controlWidth, layout.noteHeight)

    -- Explain the display-only scope where players edit names, not just in the README.
    for index, text in ipairs({ "Changes displayed names only.", "Does not load presets or unlock slots." }) do
        local y = layout.rows.scopeNotes + (index - 1) * layout.noteSpacing
        local note = createText(parent, text, smallFont)
        trackPosition(note, layout.padding, y)
        note:SetSize(layout.controlWidth, layout.noteHeight)
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
            setStatus("Character changed. Enter the name again.", false)
            return false
        end

        -- pcall separates unexpected host errors from ordinary validation failures.
        local callSucceeded, saveSucceeded, message = pcall(names.save, selectedSlot, value)
        if not callSucceeded then
            print("[Preset names] Save error: " .. tostring(saveSucceeded))
            setStatus("Save error. See the client console.", false)
            return false
        end
        setStatus(message, saveSucceeded)
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
    trackPosition(createButton(parent, "Save", saveInput), layout.padding, layout.rows.buttons)
    trackPosition(createButton(parent, "Reset", function()
        local saveSucceeded = saveValue("")
        if saveSucceeded then
            nameInput.content = ""
        end
    end), layout.resetX, layout.rows.buttons)
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
