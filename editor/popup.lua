local nameEditor = require("editor/view")
local constants = require("constants")
local layout = require("editor/layout")
local theme = require("editor/theme")
local popup = {}
local layer, refresh, centre, bankIsOpen, dragHandle
local width, height = layout.popupWidth, layout.compactPopupHeight

local function rectangle(parent, x, y, w, h, colour, fill)
    local control = ui.Rectangle.new(parent)
    control:SetPos(x, y)
    control:SetSize(w, h)
    control.colour = colour
    control.fill = fill
    control.clickthrough = true
    return control
end

function popup.close()
    local previous = layer
    if dragHandle then pcall(function() dragHandle:Destroy() end) end
    dragHandle = nil
    layer, refresh, centre, bankIsOpen = nil, nil, nil, nil
    if previous then
        -- The bank may already have disposed the popup's interface.
        pcall(function() previous:Destroy() end)
    end
end

function popup.open(slot, names, bindings)
    local binding = bindings.labels[slot]
    if not binding then return end
    local source = ui.Interfaces:GetComponent(binding.interfaceID, binding.staticID,
        binding.categoryID, binding.dynamicID)
    if not source or source.isRestricted then return end
    -- Cross interface boundaries: the bank's root is itself a constrained
    -- popover. Hosting there clips the editor and confines its drag region.
    local parent = source.parent
    while parent and parent.parent and not parent.parent.isRestricted do
        parent = parent.parent
    end
    if not parent or parent.isRestricted then return end

    popup.close()
    bankIsOpen = function()
        return ui.Interfaces:GetComponent(binding.interfaceID, binding.staticID,
            binding.categoryID, binding.dynamicID) == source
    end
    height = layout.compactPopupHeight
    layer = ui.Layer.new(parent)
    layer:SetSize(width, height)
    -- Nested native bank containers do not reliably apply percentage anchors
    -- to plugin layers. Use explicit local offsets, as the editor itself does.
    local lastWidth, lastHeight
    local moved = false
    local function position(x, y)
        layer:SetPos(math.max(0, math.min(x, math.max(0, parent.width - width))),
            math.max(0, math.min(y, math.max(0, parent.height - height))))
    end
    centre = function()
        if parent.width ~= lastWidth or parent.height ~= lastHeight then
            if moved then
                position(layer.x, layer.y)
            else
                position(math.floor((parent.width - width) / 2),
                    math.floor((parent.height - height) / 2))
            end
            lastWidth, lastHeight = parent.width, parent.height
        end
    end
    centre()
    layer.clickthrough = false
    local border = theme.colour(theme.border)
    local inset = layout.popupBorderInset
    local titleInset = layout.popupTitleBarInset
    rectangle(layer, 0, 0, width, height, theme.colour(theme.background), true)
    rectangle(layer, inset, inset, width - inset * 2, height - inset * 2, border, false)
    local titleBar = rectangle(layer, titleInset, titleInset, width - titleInset * 2,
        layout.popupTitleBarHeight, theme.colour(theme.titleBar), true)
    titleBar.clickthrough = false
    rectangle(layer, titleInset, titleInset + layout.popupTitleBarHeight,
        width - titleInset * 2, inset, border, true)

    local title = ui.Text.new(layer)
    local closeX = width - layout.popupPadding - layout.popupCloseSize
    title:SetPos(layout.popupTitleX, layout.popupTitleY)
    local infoX = closeX - layout.popupCloseSize - 4
    title:SetSize(infoX - layout.popupTitleX - layout.popupPadding, layout.popupTitleHeight)
    title.font = id.Font.MUSEO_SANS_15PT_REGULAR
    title.content = constants.editorTitle
    title.colour = theme.colour(theme.titleText)
    title.clickthrough = true
    local content = ui.Layer.new(layer)
    content:SetPos(0, layout.popupHeaderHeight)
    content:SetSize(width, layout.compactBodyHeight)
    local toggleInfo
    refresh, toggleInfo = nameEditor.build(content, names, bindings, slot,
        { hideTitle = true, externalInfoButton = true, infoParent = layer })
    local info = ui.Button.new(layer)
    info:SetPos(infoX, layout.popupTitleY)
    info:SetSize(layout.popupCloseSize, layout.popupCloseSize)
    info.stylesheetID = id.StyleSheet.BUTTON_DEFAULT
    info.label = "i"
    info.text.colour = theme.colour(theme.titleText)
    info:Subscribe(ui.Hook.ONBUTTONPRESSED, toggleInfo)
    local close = ui.Button.new(layer)
    close:SetPos(closeX, layout.popupTitleY)
    close:SetSize(layout.popupCloseSize, layout.popupCloseSize)
    close.stylesheetID = id.StyleSheet.BUTTON_DEFAULT
    close.label = "×"
    close.text.colour = theme.colour(theme.titleText)
    close:Subscribe(ui.Hook.ONBUTTONPRESSED, popup.close)

    -- A transparent handle above the controls expands to cover the host while
    -- held. Fast motion cannot outrun its hit region; all coordinates during
    -- capture are host-local, independent of the moving popup's position.
    local handle = ui.Layer.new(parent)
    dragHandle = handle
    local grabX, grabY
    local capturePending = false
    local function release()
        grabX, grabY = nil, nil
        capturePending = false
        handle:SetPos(layer.x + titleInset, layer.y + titleInset)
        handle:SetSize(infoX - titleInset, layout.popupTitleBarHeight)
    end
    local function capture()
        handle:SetPos(0, 0)
        handle:SetSize(parent.width, parent.height)
    end
    handle.clickthrough = false
    release()
    handle:Subscribe(ui.Hook.ONCLICK, function(_, x, y)
        grabX, grabY = x + titleInset, y + titleInset
        capturePending = true
        capture()
    end)
    handle:Subscribe(ui.Hook.ONHOLD, function(_, x, y)
        if grabX == nil then return end
        -- The client can queue the initial hold with coordinates from before
        -- ONCLICK moved the handle. Wait for the next sample in host space.
        if capturePending then
            capturePending = false
            return
        end
        moved = true
        position(x - grabX, y - grabY)
        capture()
    end)
    handle:Subscribe(ui.Hook.ONRELEASE, release)
    local updatePosition = centre
    centre = function()
        updatePosition()
        if grabX == nil then release() else capture() end
    end
end

function popup.update()
    if refresh then
        local succeeded = pcall(function()
            if not bankIsOpen() then popup.close(); return end
            centre()
            refresh()
        end)
        if not succeeded then popup.close() end
    end
end

return popup
