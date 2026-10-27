local colourValue = require("components/colour_picker/value")
local picker = {}
local defaultTheme = {
    border = { 0.58, 0.48, 0.28, 1 },
    background = { 0.14, 0.13, 0.11, 1 },
}
local function colour(rgba)
    return Vector4.new(rgba[1], rgba[2], rgba[3], rgba[4])
end

-- A separate overlay avoids clipping by the ribbon's scrolling content.
-- Host integration is injected; this component knows nothing about the editor,
-- persistence or PrettyUI. attachOverlay may return a cleanup function.
function picker.open(host, options)
    options = options or {}
    local initial, onChange = options.initial, options.onChange
    local anchor, onClose = options.anchor, options.onClose
    local theme = options.theme or defaultTheme
    assert(type(onChange) == "function", "Colour picker requires an onChange callback.")
    local parent = host
    while parent.parent and not parent.parent.isRestricted do parent = parent.parent end
    local root = ui.Layer.new(parent)
    local closed = false
    local detachOverlay
    local function close()
        if closed then return end
        closed = true
        if detachOverlay then detachOverlay() end
        root:Destroy()
        if onClose then onClose() end
    end
    local function rect(x, y, w, h, colour, action)
        local box = ui.Rectangle.new(root)
        box:SetPos(x, y)
        box:SetSize(w, h)
        box.fill = true
        box.colour = Vector4.new(colour[1], colour[2], colour[3], colour[4])
        box.clickthrough = false
        if action then box:Subscribe(ui.Hook.ONCLICK, action) end
        return box
    end
    local function text(x, y, w, content)
        local label = ui.Text.new(root)
        label:SetPos(x, y)
        label:SetSize(w, 24)
        label.font = id.Font.MUSEO_SANS_11PT_REGULAR or id.Font.MUSEO_SANS_15PT_REGULAR
        label.content = content
        label.clickthrough = true
        return label
    end
    local width, height = 288, 288
    root:SetSize(width, height)
    root.clickthrough = false
    -- Empty popup space must consume clicks rather than forwarding them to
    -- the game world. Child controls retain their own pointer handlers.
    root:Subscribe(ui.Hook.ONCLICK, function() return true end)
    local function globalPosition(component)
        local position = component.xyGlobal
        if position then return position.x, position.y end
        -- Also supports simple local-coordinate hosts used in tests.
        local x, y = component.x or 0, component.y or 0
        if component.parent then
            local px, py = globalPosition(component.parent)
            x, y = x + px, y + py
        end
        return x, y
    end
    local function updatePosition()
        if closed then return end
        local target = anchor or host
        local ax, ay = globalPosition(target)
        local px, py = globalPosition(parent)
        local x, y = ax - px + target.width + 8, ay - py
        if x + width > parent.width then x = ax - px - width - 8 end
        root:SetPos(math.max(0, math.min(x, parent.width - width)),
            math.max(0, math.min(y, parent.height - height)))
    end
    updatePosition()
    local function consumeClick() return true end
    rect(0, 0, width, height, theme.border, consumeClick)
    rect(1, 1, width - 2, height - 2, theme.background, consumeClick)
    text(12, 8, 264, options.title or "Choose colour")
    local selected = colourValue.normalize(initial) or "#FFFFFF"
    local h, s, v = colourValue.toHSV(selected)
    local cells = {}
    local preview = rect(232, 226, 44, 28, colourValue.vector(selected))
    local input = ui.InputField.new(root)
    input:SetPos(12, 226)
    input:SetSize(208, 28)
    input.stylesheetID = id.StyleSheet.INPUT_DEFAULT
    input:Setup(ui.TextContentVisibilityMode.VISIBLE, ui.InputFieldFilterMode.NONE, 7)
    input.content = selected
    local status = text(12, 258, 264, "Hex colour: #RRGGBB")
    local shadeMarker, hueMarker
    local function positionMarkers()
        if shadeMarker then shadeMarker:SetPos(12 + s * 263 - 3, 36 + (1 - v) * 155 - 3) end
        if hueMarker then hueMarker:SetPos(12 + h * 263 - 1, 199) end
    end
    local function refresh()
        for _, cell in ipairs(cells) do
            cell.control.colour = colour(colourValue.vector(colourValue.fromHSV(h, cell.s, cell.v)))
        end
        preview.colour = colour(colourValue.vector(selected))
        input.content = selected
        status.content = "Hex colour: #RRGGBB"
        positionMarkers()
    end
    for row = 0, 11 do
        for column = 0, 23 do
            local cs, cv = column / 23, 1 - row / 11
            local control = rect(12 + column * 11, 36 + row * 13, 11, 13,
                colourValue.vector(colourValue.fromHSV(h, cs, cv)))
            cells[#cells + 1] = { control = control, s = cs, v = cv }
            control.clickthrough = true
        end
    end
    for index = 0, 23 do
        local hue = index / 24
        local control = rect(12 + index * 11, 200, 11, 18, colourValue.vector(colourValue.fromHSV(hue, 1, 1)))
        control.clickthrough = true
    end
    -- One hit target per gradient, rather than one per painted cell. Pointer
    -- hook coordinates are component-local interface units (also at UI scale).
    local function dragArea(x, y, w, height, update)
        local area = ui.Layer.new(root)
        area:SetPos(x, y)
        area:SetSize(w, height)
        area.clickthrough = false
        local function select(_, mx, my)
            if closed or type(mx) ~= "number" or type(my) ~= "number" then return false end
            update(math.max(0, math.min(1, mx / (w - 1))),
                math.max(0, math.min(1, my / (height - 1))))
            selected = colourValue.fromHSV(h, s, v)
            refresh()
            onChange(selected)
            return true
        end
        area:Subscribe(ui.Hook.ONCLICK, select)
        area:Subscribe(ui.Hook.ONHOLD, select)
        area:Subscribe(ui.Hook.ONRELEASE, select)
        return area
    end
    dragArea(12, 36, 264, 156, function(x, y) s, v = x, 1 - y end)
    dragArea(12, 200, 264, 18, function(x) h = x end)
    shadeMarker = rect(0, 0, 7, 7, { 1, 1, 1, 1 })
    shadeMarker.fill = false
    shadeMarker.clickthrough = true
    hueMarker = rect(0, 199, 3, 20, { 1, 1, 1, 1 })
    hueMarker.fill = false
    hueMarker.clickthrough = true
    positionMarkers()
    input:Subscribe(ui.Hook.ONCONTENTCHANGED, function()
        local hex = colourValue.normalize(input.content)
        if not hex then status.content = "Enter six hex digits, e.g. #38A4FF"; return end
        selected = hex
        h, s, v = colourValue.toHSV(hex)
        preview.colour = colour(colourValue.vector(hex))
        for _, cell in ipairs(cells) do
            cell.control.colour = colour(colourValue.vector(colourValue.fromHSV(h, cell.s, cell.v)))
        end
        status.content = "Hex colour: #RRGGBB"
        positionMarkers()
        onChange(selected)
    end)
    if options.attachOverlay then detachOverlay = options.attachOverlay(root, updatePosition) end
    return close, updatePosition
end
return picker
