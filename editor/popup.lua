local nameEditor = require("editor/view")
local constants = require("constants")
local layout = require("editor/layout")
local theme = require("editor/theme")
local popup = {}
local layer, refresh, centre
local width, height = layout.popupWidth, layout.popupHeight

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
    layer, refresh, centre = nil, nil, nil
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
    -- Use the bank's root rather than the scrolling preset list, so the popup
    -- is not clipped to a single row or moved when the list scrolls.
    local parent = source.parent
    while parent and parent.parent and parent.parent.interfaceID == binding.interfaceID do
        parent = parent.parent
    end
    if not parent or parent.isRestricted then return end

    popup.close()
    layer = ui.Layer.new(parent)
    layer:SetSize(width, height)
    -- Nested native bank containers do not reliably apply percentage anchors
    -- to plugin layers. Use explicit local offsets, as the editor itself does.
    local lastWidth, lastHeight
    centre = function()
        if parent.width ~= lastWidth or parent.height ~= lastHeight then
            layer:SetPos(math.max(0, math.floor((parent.width - width) / 2)),
                math.max(0, math.floor((parent.height - height) / 2)))
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
    rectangle(layer, titleInset, titleInset, width - titleInset * 2,
        layout.popupTitleBarHeight, theme.colour(theme.titleBar), true)
    rectangle(layer, titleInset, titleInset + layout.popupTitleBarHeight,
        width - titleInset * 2, inset, border, true)

    local title = ui.Text.new(layer)
    local closeX = width - layout.popupPadding - layout.popupCloseSize
    title:SetPos(layout.popupTitleX, layout.popupTitleY)
    title:SetSize(closeX - layout.popupTitleX - layout.popupPadding, layout.popupTitleHeight)
    title.font = id.Font.MUSEO_SANS_15PT_REGULAR
    title.content = constants.editorTitle
    title.colour = theme.colour(theme.titleText)
    title.clickthrough = true
    local content = ui.Layer.new(layer)
    content:SetPos(0, layout.popupHeaderHeight)
    content:SetSize(width, layout.bodyHeight)
    refresh = nameEditor.build(content, names, bindings, slot, { hideTitle = true })
    local close = ui.Button.new(layer)
    close:SetPos(closeX, layout.popupTitleY)
    close:SetSize(layout.popupCloseSize, layout.popupCloseSize)
    close.stylesheetID = id.StyleSheet.BUTTON_DEFAULT
    close.label = "×"
    close.text.colour = theme.colour(theme.titleText)
    close:Subscribe(ui.Hook.ONBUTTONPRESSED, popup.close)
end

function popup.update()
    if refresh then
        local succeeded = pcall(function()
            centre()
            refresh()
        end)
        if not succeeded then popup.close() end
    end
end

return popup
