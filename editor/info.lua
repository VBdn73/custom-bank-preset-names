local layout = require("editor/layout")
local theme = require("editor/theme")
local info = {}

function info.new(host, options)
    options = options or {}
    local visible = false
    local controls = {}

    local function position()
        local width = math.min(layout.controlWidth, math.max(1, host.width - layout.padding * 2))
        local x = math.max(0, host.width - layout.padding - width)
        local y = options.header and layout.popupHeaderHeight or layout.padding + layout.popupCloseSize + 4
        for _, entry in ipairs(controls) do
            entry.control:SetSize(entry.x == 0 and width or math.max(1, width - layout.padding * 2),
                entry.control.height)
            entry.control:SetPos(x + entry.x, y + entry.y)
        end
    end

    local function toggle()
        visible = not visible
        if not visible then
            for _, entry in ipairs(controls) do entry.control:Destroy() end
            controls = {}
            return
        end
        local height = layout.padding * 2 + layout.noteSpacing * 3
        for _, fill in ipairs({ true, false }) do
            local box = ui.Rectangle.new(host)
            box:SetSize(layout.controlWidth, height)
            box.fill = fill
            box.colour = theme.colour(fill and theme.background or theme.border)
            box.clickthrough = false
            controls[#controls + 1] = { control = box, x = 0, y = 0 }
        end
        for index, text in ipairs({ "Stored on this device, per character name.",
            "Local appearance changes only.", "Does not load presets or unlock slots." }) do
            local note = ui.Text.new(host)
            note.font = id.Font.MUSEO_SANS_11PT_REGULAR or id.Font.MUSEO_SANS_15PT_REGULAR
            note.content = text
            note:SetSize(layout.controlWidth - layout.padding * 2, layout.noteHeight)
            note.clickthrough = true
            controls[#controls + 1] = {
                control = note, x = layout.padding, y = layout.padding + (index - 1) * layout.noteSpacing,
            }
        end
        position()
    end

    return toggle, position
end

return info
