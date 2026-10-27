-- The small ribbon panel only exposes the bank display preference.
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
    note.content = "To customise presets, right-click a preset in the bank and choose Customize preset."
    note.maxLines = 5
    note.clickthrough = true
    local function resize()
        checkbox.root:SetPos(8, 8)
        checkbox.root:SetSize(math.max(1, parent.width - 16), checkbox.root.height)
        note:SetPos(8, 8 + checkbox.root.height + 12)
        note:SetSize(math.max(1, parent.width - 16), 64)
    end
    resize()
    parent:Subscribe(ui.Hook.ONRESIZE, "presetNames.preferences", resize)

    return function()
        checkbox:SetSelected("hideDropdown", settings.hidePredefinedDropdown(), false)
    end
end

return preferences
