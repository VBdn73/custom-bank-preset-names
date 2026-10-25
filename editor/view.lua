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
        local width = math.min(layout.controlWidth, math.max(1, host.width - layout.padding * 2))
        local x = math.max(0, host.width - layout.padding - width)
        local y = options.infoParent and layout.popupHeaderHeight or layout.padding + layout.popupCloseSize + 4
        for _, entry in ipairs(infoControls) do
            entry.control:SetSize(entry.x == 0 and width or math.max(1, width - layout.padding * 2),
                entry.control.height)
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

    for _, position in ipairs(controlPositions) do
        position.width, position.height = position.component.width, position.component.height
    end

    local scrollY, maxScroll = 0, 0
    local scrollUp, scrollDown
    local centreContent
    local function scrollBy(amount)
        scrollY = math.max(0, math.min(maxScroll, scrollY + amount))
        centreContent()
    end
    if options.scrollable then
        scrollUp = createButton(parent, "^", function() scrollBy(-layout.fieldHeight) end)
        scrollDown = createButton(parent, "v", function() scrollBy(layout.fieldHeight) end)
        local function onWheel(_, delta)
            if maxScroll == 0 then return true end
            scrollBy(delta * layout.fieldHeight)
            return false
        end
        parent:Subscribe(ui.Hook.ONSCROLLWHEEL, "presetNames.scroll", onWheel)
        for _, position in ipairs(controlPositions) do
            -- Lists own their wheel events for navigating their entries.
            if position.component ~= presetSelector
                and position.component ~= colourControls.background
                and position.component ~= colourControls.text then
                position.component:Subscribe(ui.Hook.ONSCROLLWHEEL, "presetNames.scroll", onWheel)
            end
        end
    end

    centreContent = function()
        local minimumHeight = (bindings.colours and 246 or 194)
            - (options.hideTitle and layout.titleHeight or 0)
        local overflowing = options.scrollable == true and parent.height < minimumHeight
        local gutter = overflowing and layout.popupCloseSize + 4 or 0
        local width = math.min(contentWidth, math.max(1, parent.width - gutter))
        local controlWidth = math.max(1, width - layout.padding * 2)
        local buttonWidth = math.max(1, (controlWidth - layout.buttonGap) / 2)
        -- Tight ribbon panels need smaller gaps, not smaller text or fields.
        -- Leave the established popup/settings spacing alone when it fits.
        local compact = parent.height < contentHeight
        local compactRows = {
            [8] = 8, [48] = 36, [90] = 72, [122] = 94,
            [166] = 130, [198] = 150, [238] = 188, [270] = 220,
        }
        if not bindings.colours then
            compactRows[166], compactRows[198] = 134, 166
        end
        local titleOffset = options.hideTitle and layout.titleHeight or 0
        local height = compact and ((bindings.colours and 246 or 194) - titleOffset) or contentHeight
        maxScroll = options.scrollable and math.max(0, height - parent.height) or 0
        scrollY = math.min(scrollY, maxScroll)
        local offsetX = math.max(0, math.floor((parent.width - gutter - width) / 2))
        local offsetY = math.max(0, math.floor((parent.height - height) / 2))
        for _, position in ipairs(controlPositions) do
            local control = position.component
            local x = position.x == layout.resetX
                and layout.padding + buttonWidth + layout.buttonGap or position.x
            local y = compact and (compactRows[position.y + titleOffset] or position.y + titleOffset)
                - titleOffset or position.y
            local isColumn = position.width == layout.buttonWidth
                or (bindings.colours and position.y + titleOffset == layout.rows.colourLabel)
            local availableWidth = isColumn and buttonWidth or controlWidth
            if control.content == constants.editorTitle or control.content == "Preset customisation" then
                control.content = width < layout.width and "Preset customisation" or constants.editorTitle
                availableWidth = math.max(1, controlWidth - layout.popupCloseSize - 4)
            end
            control:SetSize(availableWidth, compact and position.height == layout.textHeight
                and layout.noteHeight or position.height)
            control:SetPos(offsetX + x, offsetY + y - scrollY)
            -- Do not let offscreen controls intercept clicks outside the panel.
            control.hidden = options.scrollable and (offsetY + y - scrollY < 0
                or offsetY + y - scrollY + control.height > parent.height) or false
        end
        if scrollUp then
            for index, control in ipairs({ scrollUp, scrollDown }) do
                control.hidden = not overflowing
                control:SetSize(layout.popupCloseSize, math.min(layout.popupCloseSize, parent.height / 2))
                control:SetPos(math.max(0, parent.width - layout.popupCloseSize),
                    index == 1 and 0 or parent.height - control.height)
            end
            scrollUp.enabled, scrollDown.enabled = scrollY > 0, scrollY < maxScroll
        end
        if infoButton then
            infoButton.hidden = overflowing
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
