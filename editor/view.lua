local constants = require("constants")
local layout = require("editor/layout")
local theme = require("editor/theme")
local icons = require("editor/icon")
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
    local contentHeight = options.hideTitle and layout.compactBodyHeight or layout.compactHeight
    if bindings.colours then contentHeight = contentHeight + layout.colourHeight end
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
    local presetLabels = {}
    local function refreshPresetLabels()
        local labels, changed = {}, false
        for preset = 1, bindings.presetCount do
            local name = names.get(preset)
            local customized = name and name ~= ""
            if bindings.colours then
                customized = customized or bindings.colours.get(preset, "background") ~= ""
                    or bindings.colours.get(preset, "text") ~= ""
            end
            labels[preset] = "Preset " .. preset .. (customized and " *" or "")
            changed = changed or labels[preset] ~= presetLabels[preset]
        end
        if not changed then return end
        presetSelector:Clear()
        for preset = 1, bindings.presetCount do
            -- Native list IDs are zero-based; storage slots are one-based.
            presetSelector:Add(labels[preset], preset - 1)
        end
        presetSelector:SetEntrySelected(selectedSlot - 1, true, false)
        presetLabels = labels
    end
    refreshPresetLabels()
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
    if bindings.colours then
        statusLabel:SetSize(layout.controlWidth, layout.noteHeight)
    end
    trackPosition(statusLabel, layout.padding,
        bindings.colours and layout.rows.colourStatus or layout.rows.status)
    local function setStatus(message, succeeded)
        statusLabel.content = message
        statusLabel.colour = theme.colour(succeeded and theme.success or theme.error)
    end
    local infoVisible = false
    local colourControls = {}
    local pendingColours = {}
    local function refreshColours()
        if not bindings.colours then return end
        for kind, control in pairs(colourControls) do
            local value = pendingColours[kind]
            for index, item in ipairs(bindings.colours.palette) do
                if item.value == value then control:SetEntrySelected(index - 1, true, false) end
            end
        end
    end
    if bindings.colours then
        for index, kind in ipairs({ "background", "text" }) do
            local x = layout.padding + (index - 1) * (layout.buttonWidth + layout.buttonGap)
            trackPosition(createText(parent, kind == "background" and "Background" or "Text colour", smallFont),
                 x, layout.rows.colourLabel)
            local control = ui.List.new(parent)
            control:SetSize(layout.buttonWidth, layout.fieldHeight)
            control.stylesheetID = id.StyleSheet.DROPDOWN_DEFAULT
            control.dropdownMaxVisibleEntries = layout.dropdownVisibleEntries
            control.entryHeight = layout.textHeight
            trackPosition(control, x, layout.rows.colourInput)
            colourControls[kind] = control
            for paletteIndex, item in ipairs(bindings.colours.palette) do
                control:Add(item.name, paletteIndex - 1)
            end
            control:Subscribe(ui.Hook.ONSELECTIONCHANGED, function(_, entryID, event)
                if event ~= ui.SelectionChangeEvent.SELECTED then return end
                local item = bindings.colours.palette[entryID + 1]
                if not item then return end
                pendingColours[kind] = item.value
                statusLabel.content = ""
                refreshColours()
            end)
        end
    end
    local infoControls = {}
    local function positionInfo()
        local host = options.infoParent or parent
        local x = math.max(0, host.width - layout.padding - layout.controlWidth)
        local y = options.infoParent and layout.popupHeaderHeight or layout.padding + layout.popupCloseSize + 4
        for _, entry in ipairs(infoControls) do
            entry.control:SetPos(x + entry.x, y + entry.y)
        end
    end
    local function toggleInfo()
        infoVisible = not infoVisible
        if not infoVisible then
            for _, entry in ipairs(infoControls) do entry.control:Destroy() end
            infoControls = {}
            return
        end
        local host = options.infoParent or parent
        local height = layout.padding * 2 + layout.noteSpacing * 3
        for _, fill in ipairs({ true, false }) do
            local box = ui.Rectangle.new(host)
            box:SetSize(layout.controlWidth, height)
            box.fill = fill
            box.colour = theme.colour(fill and theme.background or theme.border)
            box.clickthrough = false
            infoControls[#infoControls + 1] = { control = box, x = 0, y = 0 }
        end
        for index, text in ipairs({ "Stored on this device, per character name.",
            "Changes names and colours only.", "Does not load presets or unlock slots." }) do
            local note = createText(host, text, smallFont)
            note:SetSize(layout.controlWidth - layout.padding * 2, layout.noteHeight)
            note.clickthrough = true
            infoControls[#infoControls + 1] = {
                control = note, x = layout.padding, y = layout.padding + (index - 1) * layout.noteSpacing,
            }
        end
        positionInfo()
    end

    -- Popup chrome supplies its own button; native settings chrome is owned by
    -- the client, so keep the embedded button in our content's top-right corner.
    local infoButton, updateInfo
    if not options.externalInfoButton then
        infoButton, updateInfo = icons.new(parent, id.Sprite.RS3_BUTTON_INFO_PARENT_0,
            id.Sprite.RS3_BUTTON_INFO_PARENT_1, id.Sprite.RS3_BUTTON_INFO_PARENT_2, toggleInfo)
    end

    local displayedCharacterContext = names.getContext()
    local function refreshSelectedName()
        displayedCharacterContext = names.getContext()
        if bindings.colours then
            for kind in pairs(colourControls) do
                pendingColours[kind] = bindings.colours.get(selectedSlot, kind)
            end
        end
        refreshColours()
        refreshPresetLabels()
        nameInput.content = names.get(selectedSlot) or ""
        statusLabel.content = displayedCharacterContext and "" or "Log in and wait for your character name."
    end

    local function saveValue(value, reset)
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
        if saveSucceeded then refreshPresetLabels() end
        if saveSucceeded and bindings.colours then
            for _, kind in ipairs({ "background", "text" }) do
                local ok, saved, colourMessage = pcall(bindings.colours.save,
                    selectedSlot, kind, reset and "" or pendingColours[kind])
                if not ok or not saved then
                    setStatus(ok and colourMessage or "Colour save error. See the client console.", false)
                    return false
                end
            end
            if reset then
                pendingColours.background, pendingColours.text = "", ""
                refreshColours()
            end
            message = reset and "Name and colours reset." or "Name and colours saved."
        end
        setStatus(message, saveSucceeded)
        if saveSucceeded then refreshPresetLabels() end
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
    local buttonsY = bindings.colours and layout.rows.colourButtons or layout.rows.buttons
    trackPosition(createButton(parent, "Save", saveInput), layout.padding, buttonsY)
    trackPosition(createButton(parent, "Reset", function()
        local saveSucceeded = saveValue("", true)
        if saveSucceeded then
            nameInput.content = ""
        end
    end), layout.resetX, buttonsY)
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
        if infoButton then
            infoButton:SetPos(math.max(0, parent.width - layout.padding - layout.popupCloseSize),
                layout.padding)
        end
        positionInfo()
    end
    centreContent()
    parent:Subscribe(ui.Hook.ONRESIZE, "presetNames.centre", centreContent)

    -- Called by main.lua each logic tick, not only when the editor is opened.
    return function()
        if updateInfo then updateInfo() end
        if names.getContext() ~= displayedCharacterContext then
            refreshSelectedName()
        end
        refreshPresetLabels()
        refreshColours()
    end, toggleInfo
end

return editor
