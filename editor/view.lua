local constants = require("constants")
local layout = require("editor/layout")
local theme = require("editor/theme")
local icons = require("editor/icon")
local colourPicker = require("editor/colour_picker")
local colourValue = require("presets/colour_value")
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
    local host = parent
    local scrollView
    local contentHost = options.contentHost
    if options.scrollable then
        -- Receive dependency exports explicitly from the entry point.
        local prettyui = options.prettyui
        assert(prettyui,
            "PrettyUI is required for the ribbon editor.")
        assert(prettyui.SimpleView and prettyui.SimpleView.new,
            "The installed PrettyUI version does not provide SimpleView.")
        scrollView = prettyui.SimpleView.new(host, {
            width = math.max(1, host.width), height = math.max(1, host.height),
        })
        parent = scrollView.content
        contentHost = scrollView
    end
    -- Position controls directly on the supplied layer. An extra nested layer
    -- is positioned unexpectedly by the beta client's settings host.
    local contentWidth = layout.width
    local contentHeight = options.hideTitle and layout.compactBodyHeight or layout.compactHeight
    if bindings.colours then contentHeight = contentHeight + layout.colourHeight end
    if options.settings then contentHeight = contentHeight + 40 end
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

    local managedInput = contentHost and contentHost:AddTextField({
        absolute = true, x = 0, y = 0, width = layout.controlWidth,
        height = layout.fieldHeight, maxLength = constants.maximumNameLength,
        placeholder = "Use predefined name",
        -- SimpleView is itself the scroll controller; Window wraps one.
        _scrollController = contentHost._scroll or contentHost,
    })
    local nameInput = managedInput and managedInput.root or ui.InputField.new(parent)
    trackPosition(nameInput, layout.padding, layout.rows.input)
    nameInput:SetSize(layout.controlWidth, layout.fieldHeight)
    nameInput.stylesheetID = id.StyleSheet.INPUT_DEFAULT
    if not managedInput then
        nameInput:Setup(ui.TextContentVisibilityMode.VISIBLE, ui.InputFieldFilterMode.NONE,
            constants.maximumNameLength)
    end
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
    local defaultMarks = {}
    local defaultMarkKinds = {}
    local colourLabels = {}
    local pendingColours = {}
    local closePicker
    local updatePicker
    local pickerKind
    local function dismissPicker()
        if closePicker then closePicker(); closePicker = nil end
        updatePicker = nil
        pickerKind = nil
    end
    local function refreshColours()
        if not bindings.colours then return end
        for kind, control in pairs(colourControls) do
            local value = pendingColours[kind]
            local hex = colourValue.normalize(value)
            control.colour = theme.colour(hex and colourValue.vector(hex) or theme.background)
            for _, mark in ipairs(defaultMarks[kind]) do mark.hidden = hex ~= nil end
        end
    end
    if bindings.colours then
        for index, kind in ipairs({ "background", "text" }) do
            local y = layout.rows.colourLabel + (index - 1) * 32
            local label = createText(parent, kind == "background" and "Background colour:" or "Text colour:", smallFont)
            label:SetSize(layout.swatchX - layout.padding - 6, 20)
            label.clickthrough = true
            colourLabels[kind] = label
            trackPosition(label, layout.padding, y)
            local border = ui.Rectangle.new(parent)
            border:SetSize(34, 22)
            border.fill = true
            border.colour = theme.colour(theme.border)
            border.clickthrough = true
            trackPosition(border, layout.swatchX - 1, y - 1)
            local control = ui.Rectangle.new(parent)
            control:SetSize(32, 20)
            control.fill = true
            control.clickthrough = false
            trackPosition(control, layout.swatchX, y)
            colourControls[kind] = control
            defaultMarks[kind] = {}
            -- Draw thin diagonals with native rectangles, without relying on
            -- rotation support. Keep a small inset inside the swatch border.
            for column = 0, 27 do
                local offset = math.floor(column * 15 / 27 + 0.5)
                for _, row in ipairs({ offset, 15 - offset }) do
                    local mark = ui.Rectangle.new(parent)
                    mark:SetSize(1, 1)
                    mark.fill = true
                    mark.colour = theme.colour({ 1, 1, 1, 1 })
                    mark.clickthrough = true
                    trackPosition(mark, layout.swatchX + 2 + column, y + 2 + row)
                    defaultMarks[kind][#defaultMarks[kind] + 1] = mark
                    defaultMarkKinds[mark] = kind
                end
            end
            control:Subscribe(ui.Hook.ONCLICK, function()
                local toggleClosed = pickerKind == kind
                dismissPicker()
                if toggleClosed then return end
                pickerKind = kind
                local slot, context = selectedSlot, names.getContext()
                closePicker, updatePicker = colourPicker.open(host, colourValue.normalize(pendingColours[kind]), function(value)
                    closePicker = nil
                    updatePicker = nil
                    if selectedSlot ~= slot or names.getContext() ~= context then return end
                    pendingColours[kind] = value
                    statusLabel.content = ""
                    refreshColours()
                end, control, contentHost, function()
                    closePicker = nil
                    updatePicker = nil
                    pickerKind = nil
                end)
            end)
        end
    end
    local infoControls = {}
    local function positionInfo()
        local host = options.infoParent or host
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
        local host = options.infoParent or host
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
        infoButton, updateInfo = icons.new(host, id.Sprite.RS3_BUTTON_INFO_PARENT_0,
            id.Sprite.RS3_BUTTON_INFO_PARENT_1, id.Sprite.RS3_BUTTON_INFO_PARENT_2, toggleInfo)
    end

    local displayedCharacterContext = names.getContext()
    local function refreshSelectedName()
        dismissPicker()
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
        dismissPicker()
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

    local function actionButton(label, callback)
        if not contentHost then return createButton(parent, label, callback) end
        return contentHost:AddSimpleButton(label, callback, {
            absolute = true, x = 0, y = 0,
            width = layout.buttonWidth, height = layout.buttonHeight,
        }).root
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
    trackPosition(actionButton("Save", saveInput), layout.padding, buttonsY)
    trackPosition(actionButton("Reset", function()
        local saveSucceeded = saveValue("", true)
        if saveSucceeded then
            nameInput.content = ""
        end
    end), layout.resetX, buttonsY)
    if managedInput then
        managedInput.onSubmit = saveInput
    else
        nameInput:Subscribe(ui.Hook.ONCONTENTCHANGED, function(_, reason)
            if reason == ui.InputFieldActionResult.SUBMIT then
                saveInput()
            end
        end)
    end
    refreshSelectedName()

    -- This preference belongs only to the Plugin Hub settings layer.
    local dropdownCheckbox
    if options.settings then
        local y = (bindings.colours and layout.rows.colourStatus or layout.rows.status) + 28
        dropdownCheckbox = options.prettyui.CheckboxButton.new(parent, {
            { text = "Hide predefined-name dropdown", value = "hideDropdown",
                selected = options.settings.hidePredefinedDropdown() },
        }, {
            width = layout.controlWidth,
            onChange = function(_, _, _, hidden)
                if not options.settings.setHidePredefinedDropdown(hidden) then
                    setStatus("Could not save dropdown preference.", false)
                end
            end,
        })
        trackPosition(dropdownCheckbox.root, layout.padding, y)
    end

    for _, position in ipairs(controlPositions) do
        position.width, position.height = position.component.width, position.component.height
    end

    if scrollView then
        for _, position in ipairs(controlPositions) do
            -- Lists own their wheel events for navigating their entries.
            if position.component ~= presetSelector
                and not (managedInput and position.component == nameInput) then
                position.component:Subscribe(ui.Hook.ONSCROLLWHEEL, "presetNames.scroll", function(_, delta)
                    if not scrollView.scrollbarVisible then return true end
                    scrollView:ScrollBy(delta * layout.fieldHeight)
                    return false
                end)
            end
        end
    end

    local function updateClipping()
        if not scrollView then return end
        for _, position in ipairs(controlPositions) do
            local control = position.component
            local top = control.y - scrollView.scrollY
            -- Native input text can escape ancestor clipping; suppress controls
            -- crossing the viewport boundary, as in the previous ribbon editor.
            if not (managedInput and control == nameInput) then
                local kind = defaultMarkKinds[control]
                local customColour = kind and colourValue.normalize(pendingColours[kind]) ~= nil
                control.hidden = not not (customColour or top < 0 or top + control.height > host.height)
            end
        end
    end

    local function centreContent()
        dismissPicker()
        local hostHeight = options.formHeight or host.height
        local minimumHeight = (bindings.colours and 246 or 194)
            - (options.hideTitle and layout.titleHeight or 0)
            + (options.settings and 40 or 0)
        local overflowing = scrollView ~= nil and host.height < minimumHeight
        local compact = hostHeight < contentHeight
        local titleOffset = options.hideTitle and layout.titleHeight or 0
        local height = compact and minimumHeight or contentHeight
        if scrollView then
            scrollView:SetSize(host.width, host.height)
            scrollView:SetContentHeight(height)
        end
        local availableHostWidth = scrollView and scrollView.contentWidth or host.width
        local width = math.min(contentWidth, math.max(1, availableHostWidth))
        local controlWidth = math.max(1, width - layout.padding * 2)
        local buttonWidth = math.max(1, (controlWidth - layout.buttonGap) / 2)
        -- Tight ribbon panels need smaller gaps, not smaller text or fields.
        -- Leave the established popup/settings spacing alone when it fits.
        local compactRows = {
            [8] = 8, [48] = 36, [90] = 72, [122] = 94,
            [166] = 130, [198] = 162, [238] = 188, [270] = 220,
        }
        if options.settings then
            compactRows[298] = 248
            compactRows[226] = 198
        end
        if not bindings.colours then
            compactRows[166], compactRows[198] = 134, 166
        end
        local offsetX = math.max(0, math.floor((availableHostWidth - width) / 2))
        local offsetY = math.max(0, math.floor((hostHeight - height) / 2))
        for _, position in ipairs(controlPositions) do
            local control = position.component
            local x = position.x == layout.resetX
                and layout.padding + buttonWidth + layout.buttonGap or position.x
            local y = compact and (compactRows[position.y + titleOffset] or position.y + titleOffset)
                - titleOffset or position.y
            local isColumn = position.width == layout.buttonWidth
                or (bindings.colours and position.y + titleOffset == layout.rows.colourLabel)
            local availableWidth = isColumn and buttonWidth or controlWidth
            local isSwatch = position.x >= layout.swatchX - 1 and position.width <= 34
            local isColourLabel = control == colourLabels.background or control == colourLabels.text
            local swatchX = math.max(layout.padding, math.min(layout.swatchX, width - layout.padding - 34))
            if isSwatch then
                availableWidth = position.width
                x = swatchX + position.x - layout.swatchX
            elseif isColourLabel then
                availableWidth = math.max(1, swatchX - layout.padding - 6)
            end
            if isSwatch or isColourLabel then
                local row = position.y + titleOffset >= layout.rows.colourInput and layout.rows.colourInput
                    or layout.rows.colourLabel
                y = (compact and compactRows[row] or row) - titleOffset
                    + position.y + titleOffset - row
            end
            if control.content == constants.editorTitle or control.content == "Preset customisation" then
                control.content = width < layout.width and "Preset customisation" or constants.editorTitle
                availableWidth = math.max(1, controlWidth - layout.popupCloseSize - 4)
            end
            control:SetSize(availableWidth, compact and position.height == layout.textHeight
                and layout.noteHeight or position.height)
            control:SetPos(offsetX + x, offsetY + y)
        end
        if infoButton then
            infoButton.hidden = overflowing
            infoButton:SetPos(math.max(0, host.width - layout.padding - layout.popupCloseSize),
                layout.padding)
        end
        positionInfo()
        updateClipping()
        if managedInput then
            -- Refresh after repositioning too, not only when the user scrolls.
            (contentHost._scroll or contentHost):SetScrollPosition(contentHost.scrollY or 0)
        end
    end
    centreContent()
    host:Subscribe(ui.Hook.ONRESIZE, "presetNames.centre", centreContent)

    -- Called by main.lua each logic tick, not only when the editor is opened.
    return function()
        if host.visibleGlobal == false then dismissPicker() end
        if updatePicker then updatePicker() end
        if dropdownCheckbox then
            dropdownCheckbox:SetSelected("hideDropdown", options.settings.hidePredefinedDropdown(), false)
        end
        updateClipping()
        if updateInfo then updateInfo() end
        if names.getContext() ~= displayedCharacterContext then
            refreshSelectedName()
        end
        refreshPresetLabels()
        refreshColours()
        updateClipping()
    end, toggleInfo, function()
        dismissPicker()
        if scrollView then scrollView:Destroy() end
    end
end

return editor
