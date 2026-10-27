-- Read native row decorations without changing the bank's components.
local preview = {}
local presetCount = require("presets/slots").count
local fallbackSprites = {
    "RS3_ICON_BANK_PRESET_BACKPACK",
    "RS3_ICON_BANK_PRESET_WORN_EQUIPMENT",
    "RS3_ICON_BANK_PRESET_BEAST_OF_BURDEN",
}

function preview.number(slot)
    if not ui.Interfaces then return end
    local component = ui.Interfaces:GetComponent(517, 266, 0, (slot - 1) * 3)
    if component and not component.isRestricted then return component end
end

function preview.icon(slot, index)
    if not ui.Interfaces then return end
    local number = preview.number(slot)
    -- Resolve by row position as dynamic sprite numbering can differ from
    -- the bank's background and label numbering.
    for dynamicID = 0, presetCount * 3 do
        local component = ui.Interfaces:GetComponent(517, 267 + index, 0, dynamicID)
        if component and not component.isRestricted and component.sprite ~= nil then
            local position = component.xyGlobal
            local row = number and number.xyGlobal
            if not row or (position and position.y + component.height / 2 >= row.y
                and position.y + component.height / 2 < row.y + number.height) then
                return component
            end
        end
    end
end

-- Settings and ribbon previews also work while the native bank is closed.
-- Generic icons do not claim to represent unavailable preset toggle states.
function preview.decoration(slot, index)
    local source = preview.icon(slot, index)
    if source then return source end
    if preview.number(slot) then return end
    local sprite = id.Sprite[fallbackSprites[index]]
    if sprite ~= nil then return { sprite = sprite, alpha = 1, rgba = 0xFFFFFFFF } end
end

return preview
