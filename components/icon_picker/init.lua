-- Reusable native-asset picker. PrettyUI supplies native pagination arrows.
local picker = {}
local defaultTheme = {
    border = { 0.58, 0.48, 0.28, 1 },
    background = { 0.14, 0.13, 0.11, 1 },
}

local function globalPosition(component)
    local position = component.xyGlobal
    if position then return position.x, position.y end
    local x, y = component.x or 0, component.y or 0
    if component.parent then
        local px, py = globalPosition(component.parent)
        x, y = x + px, y + py
    end
    return x, y
end

function picker.open(host, options)
    options = options or {}
    assert(type(options.onSelect) == "function", "Icon picker requires an onSelect callback.")
    local categories = options.categories or {}
    assert(#categories > 0, "Icon picker requires at least one category.")
    local parent = host
    while parent.parent and not parent.parent.isRestricted do parent = parent.parent end
    local root = ui.Layer.new(parent)
    local closed, detachOverlay = false, nil
    local function close()
        if closed then return end
        closed = true
        -- Disposed hosts and faulty overlay hooks must not leave the popup alive.
        if detachOverlay then pcall(detachOverlay) end
        pcall(function() root:Destroy() end)
        if options.onClose then options.onClose() end
    end
    local width, height
    local function updatePosition()
        if closed then return end
        local target = options.anchor or host
        local ax, ay = globalPosition(target)
        local px, py = globalPosition(parent)
        local x, y = ax - px + target.width + 8, ay - py
        if x + width > parent.width then x = ax - px - width - 8 end
        root:SetPos(math.max(0, math.min(x, parent.width - width)),
            math.max(0, math.min(y, parent.height - height)))
    end
    local function build()
        local theme = options.theme or defaultTheme
        local function rectangle(parent, x, y, w, h, filled, tint)
            local control = ui.Rectangle.new(parent)
            control:SetPos(x, y)
            control:SetSize(w, h)
            control.fill = filled
            control.colour = Vector4.new(tint[1], tint[2], tint[3], tint[4])
            control.clickthrough = not filled
            return control
        end
        local function text(parent, x, y, w, content)
            local control = ui.Text.new(parent)
            control:SetPos(x, y)
            control:SetSize(w, 24)
            control.font = id.Font.MUSEO_SANS_11PT_REGULAR or id.Font.MUSEO_SANS_15PT_REGULAR
            control.content = content
            control.clickthrough = true
            return control
        end
        local function button(parent, x, y, w, h, label, action)
            local control = ui.Button.new(parent)
            control:SetPos(x, y)
            control:SetSize(w, h)
            control.stylesheetID = id.StyleSheet.BUTTON_DEFAULT
            control.label = label
            control:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
                if not closed then action() end
            end)
            return control
        end
        local function select(key)
            if closed then return end
            close()
            options.onSelect(key)
        end
        width = math.min(288, parent.width)
        local innerWidth = math.max(1, width - 24)
        local columns = math.max(1, math.floor(innerWidth / 44))
        local largest = 0
        local categoryIndex = 1
        local initialName = "Use preset number"
        for index, category in ipairs(categories) do
            largest = math.max(largest, #(category.entries or {}))
            for _, entry in ipairs(category.entries or {}) do
                if entry.key == options.initial then
                    categoryIndex, initialName = index, entry.name
                end
            end
        end
        -- Pagination keeps larger future categories within the same popup layout.
        local rows = math.max(1, math.min(5, math.ceil(largest / columns),
            math.floor((parent.height - 176) / 44)))
        local capacity = rows * columns
        local paginated = largest > capacity
        local footerY = 76 + rows * 44
        height = footerY + (paginated and 100 or 68)
        root:SetSize(width, height)
        root.clickthrough = false
        root:Subscribe(ui.Hook.ONCLICK, function() return true end)
        rectangle(root, 0, 0, width, height, true, theme.border)
        rectangle(root, 1, 1, width - 2, height - 2, true, theme.background)
        text(root, 12, 8, math.max(1, width - 48), options.title or "Choose preset icon")
        local closeButton = ui.Sprite.new(root)
        closeButton:SetPos(width - 32, 8)
        closeButton:SetSize(20, 20)
        closeButton.clickthrough = false
        closeButton.sprite = id.Sprite.RS3_BTN_MODAL_WINDOW_1_CLOSE_NML
        closeButton:Subscribe(ui.Hook.ONMOUSEOVER, function()
            if not closed then closeButton.sprite = id.Sprite.RS3_BTN_MODAL_WINDOW_1_CLOSE_OVR end
        end)
        closeButton:Subscribe(ui.Hook.ONMOUSELEAVE, function()
            if not closed then closeButton.sprite = id.Sprite.RS3_BTN_MODAL_WINDOW_1_CLOSE_NML end
        end)
        closeButton:Subscribe(ui.Hook.ONCLICK, function() close(); return true end)
        local name = text(root, 12, footerY + 4, innerWidth, initialName)
        local page = 1
        -- Start on the page containing the current selection.
        for index, entry in ipairs(categories[categoryIndex].entries or {}) do
            if entry.key == options.initial then page = math.ceil(index / capacity) end
        end
        local grid, tabFrames, refresh = nil, {}, nil
        local reportedErrors = {}
        local pageLabel, previousButton, nextButton
        if paginated then
            local spriteButton = assert(options.prettyui and options.prettyui.SpriteButton,
                "PrettyUI SpriteButton is required for icon picker pagination.")
            previousButton = spriteButton.new(root, "ARROW_LEFT", function()
                if closed then return end
                page = math.max(1, page - 1)
                refresh()
            end, { x = 12, y = footerY + 30, size = 28 })
            pageLabel = text(root, 48, footerY + 32, math.max(1, innerWidth - 72), "")
            pageLabel.alignHorizontal = ui.AlignMode.CENTRE
            nextButton = spriteButton.new(root, "ARROW_RIGHT", function()
                if closed then return end
                page = math.min(math.max(1, math.ceil(#(categories[categoryIndex].entries or {}) / capacity)), page + 1)
                refresh()
            end, { x = width - 40, y = footerY + 30, size = 28 })
        end
        button(root, 12, height - 40, innerWidth, 28, "Use preset number", function() select("") end)
        for index, category in ipairs(categories) do
            local tabWidth = innerWidth / #categories
            local x = 12 + math.floor((index - 1) * tabWidth)
            button(root, x, 40, math.floor(tabWidth) - 2, 28, category.name, function()
                categoryIndex, page = index, 1
                name.content = initialName
                refresh()
            end)
            tabFrames[index] = rectangle(root, x, 40, math.floor(tabWidth) - 2, 28, false, theme.border)
        end
        refresh = function()
            if closed then return end
            if grid then grid:Destroy() end
            grid = ui.Layer.new(root)
            grid:SetPos(12, 76)
            grid:SetSize(innerWidth, rows * 44)
            grid.clickthrough = true
            for index, frame in ipairs(tabFrames) do frame.hidden = index ~= categoryIndex end
            local entries = categories[categoryIndex].entries or {}
            if pageLabel then
                local pages = math.max(1, math.ceil(#entries / capacity))
                pageLabel.content = page .. " / " .. pages
                previousButton:SetDisabled(page <= 1)
                nextButton:SetDisabled(page >= pages)
            end
            for offset = 1, capacity do
                local entry = entries[(page - 1) * capacity + offset]
                if entry then
                    local x, y = ((offset - 1) % columns) * 44, math.floor((offset - 1) / columns) * 44
                    local available = false
                    local target = button(grid, x, y, 40, 40, "", function()
                        if available then select(entry.key) end
                    end)
                    local sprite
                    local ok, err = pcall(function()
                        local spriteID
                        if options.resolve then spriteID = options.resolve(entry.key)
                        else spriteID = id.Sprite[entry.sprite] end
                        assert(type(spriteID) == "number" and spriteID >= 0 and spriteID % 1 == 0)
                        local w, h = entry.width or 24, entry.height or 24
                        assert(w > 0 and h > 0)
                        sprite = ui.Sprite.new(grid)
                        if options.apply then options.apply(sprite, spriteID, entry)
                        else
                            sprite.sprite = spriteID
                            assert(sprite.spriteID == spriteID)
                        end
                        local iconSize = entry.objectID and 32 or 24
                        local scale = math.min(iconSize / w, iconSize / h, 1)
                        w, h = math.max(1, math.floor(w * scale)), math.max(1, math.floor(h * scale))
                        sprite:SetSize(w, h)
                        sprite:SetPos(x + math.floor((40 - w) / 2), y + math.floor((40 - h) / 2))
                        sprite.rgba = 0xFFFFFFFF
                        sprite.clickthrough, sprite.enabled = true, false
                    end)
                    available = ok
                    if not ok then
                        if sprite then pcall(function() sprite:Destroy() end) end
                        target.label = "?"
                        local message = tostring(err)
                        if not reportedErrors[message] then
                            reportedErrors[message] = true
                            print("[Icon picker] Could not render " .. entry.key .. ": " .. message)
                        end
                    end
                    local function showName()
                        if not closed then name.content = entry.name .. (available and "" or " (unavailable)") end
                    end
                    target:Subscribe(ui.Hook.ONMOUSEOVER, showName)
                    -- Native buttons handle activation; ONKEY also exposes the
                    -- label when keyboard interaction is delivered to a tile.
                    target:Subscribe(ui.Hook.ONKEY, showName)
                    target:Subscribe(ui.Hook.ONMOUSELEAVE, function()
                        if not closed then name.content = initialName end
                    end)
                    if entry.key == options.initial then
                        rectangle(grid, x, y, 40, 40, false, theme.border)
                    end
                end
            end
        end
        refresh()
        updatePosition()
        if options.attachOverlay then detachOverlay = options.attachOverlay(root, updatePosition) end
    end
    local ok, err = pcall(build)
    if not ok then
        closed = true
        if detachOverlay then pcall(detachOverlay) end
        pcall(function() root:Destroy() end)
        error(err, 0)
    end
    return close, updatePosition
end

return picker
