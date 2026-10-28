-- Settings and ribbon panels share the bank display preferences.
local preferences = {}

function preferences.build(parent, settings, prettyui)
    local options = {
        { text = "Hide predefined-name dropdown", key = "hideDropdown",
            get = settings.hidePredefinedDropdown, set = settings.setHidePredefinedDropdown },
        { text = "Show background colours in small bank UI", key = "compactBackgrounds",
            get = settings.showCompactBackgrounds, set = settings.setShowCompactBackgrounds },
    }
    for _, option in ipairs(options) do
        local checkbox
        checkbox = prettyui.CheckboxButton.new(parent, {
            { text = option.text, value = option.key, selected = option.get() },
        }, {
            width = math.max(1, parent.width - 16),
            onChange = function(_, _, _, selected)
                if not option.set(selected) then
                    print("[Preset names] Could not save " .. option.key .. " preference.")
                    checkbox:SetSelected(option.key, option.get(), false)
                end
            end,
        })
        option.checkbox = checkbox
        local item = checkbox.items[1]
        item.label.font = id.Font.MUSEO_SANS_11PT_REGULAR
        item.label.maxLines = 3
        item.label.alignVertical = ui.AlignMode.TOPLEFT
        item.box:SetPos(0, 3)
    end
    local note = ui.Text.new(parent)
    note.font = id.Font.MUSEO_SANS_11PT_REGULAR
    note.content = "Presets can only be customised in the bank UI: right-click a preset and choose Customize preset."
    note.maxLines = 5
    note.clickthrough = true
    local function resize()
        local width = math.max(1, parent.width - 16)
        -- Reserve room for wrapped checkbox text, not an always-three-line row.
        local rowHeight = width >= 300 and 20 or (width >= 200 and 36 or 54)
        local y = 8
        for _, option in ipairs(options) do
            local checkbox = option.checkbox
            local item = checkbox.items[1]
            item.label:SetSize(-22, rowHeight, 1.0)
            item.row:SetSize(0, rowHeight, 1.0)
            checkbox.root:SetPos(8, y)
            checkbox.root:SetSize(width, rowHeight)
            y = y + rowHeight + 8
        end
        note:SetPos(8, y)
        note:SetSize(width, 64)
    end
    resize()
    parent:Subscribe(ui.Hook.ONRESIZE, "presetNames.preferences", resize)

    return function()
        for _, option in ipairs(options) do
            option.checkbox:SetSelected(option.key, option.get(), false)
        end
    end
end

return preferences
