-- Settings and ribbon panels only expose the bank display preference.
local preferences = {}

function preferences.build(parent, settings, prettyui)
    local checkbox
    checkbox = prettyui.CheckboxButton.new(parent, {
        { text = "Hide predefined-name dropdown", value = "hideDropdown",
            selected = settings.hidePredefinedDropdown() },
    }, {
        width = math.max(1, parent.width - 16),
        onChange = function(_, _, _, hidden)
            if not settings.setHidePredefinedDropdown(hidden) then
                print("[Preset names] Could not save dropdown preference.")
                checkbox:SetSelected("hideDropdown", settings.hidePredefinedDropdown(), false)
            end
        end,
    })
    local item = checkbox.items[1]
    item.label.font = id.Font.MUSEO_SANS_11PT_REGULAR
    item.label.maxLines = 3
    item.label.alignVertical = ui.AlignMode.TOPLEFT
    item.label:SetSize(-22, 54, 1.0)
    item.box:SetPos(0, 3)
    item.row:SetSize(0, 54, 1.0)
    checkbox.root:SetSize(math.max(1, parent.width - 16), 54)
    local note = ui.Text.new(parent)
    note.font = id.Font.MUSEO_SANS_11PT_REGULAR
    note.content = "Presets can only be customised in the bank UI: right-click a preset and choose Customize preset."
    note.maxLines = 5
    note.clickthrough = true
    local function resize()
        local width = math.max(1, parent.width - 16)
        -- Reserve room for wrapped checkbox text, not an always-three-line row.
        local rowHeight = width >= 300 and 20 or (width >= 200 and 36 or 54)
        item.label:SetSize(-22, rowHeight, 1.0)
        item.row:SetSize(0, rowHeight, 1.0)
        checkbox.root:SetPos(8, 8)
        checkbox.root:SetSize(width, rowHeight)
        note:SetPos(8, 8 + rowHeight + 8)
        note:SetSize(width, 64)
    end
    resize()
    parent:Subscribe(ui.Hook.ONRESIZE, "presetNames.preferences", resize)

    return function()
        checkbox:SetSelected("hideDropdown", settings.hidePredefinedDropdown(), false)
    end
end

return preferences
