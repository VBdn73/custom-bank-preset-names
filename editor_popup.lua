local nameEditor = require("name_editor")
local constants = require("constants")
local layout = require("editor_layout")
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
    local gold = Vector4.new(0.58, 0.48, 0.28, 1)
    rectangle(layer, 0, 0, width, height, Vector4.new(0.14, 0.13, 0.11, 1), true)
    rectangle(layer, 1, 1, width - 2, height - 2, gold, false)
    rectangle(layer, 4, 4, width - 8, 30, Vector4.new(0.20, 0.18, 0.14, 1), true)
    rectangle(layer, 4, 34, width - 8, 1, gold, true)

    local title = ui.Text.new(layer)
    title:SetPos(12, 7)
    title:SetSize(width - 52, 26)
    title.font = id.Font.MUSEO_SANS_15PT_REGULAR
    title.content = constants.editorTitle
    title.colour = Vector4.new(0.88, 0.72, 0.43, 1)
    title.clickthrough = true
    local content = ui.Layer.new(layer)
    content:SetPos(0, layout.popupHeaderHeight)
    content:SetSize(width, layout.bodyHeight)
    refresh = nameEditor.build(content, names, bindings, slot, { hideTitle = true })
    local close = ui.Button.new(layer)
    close:SetPos(width - 30, 7)
    close:SetSize(22, 22)
    close.stylesheetID = id.StyleSheet.BUTTON_DEFAULT
    close.label = "×"
    close.text.colour = Vector4.new(0.88, 0.72, 0.43, 1)
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
