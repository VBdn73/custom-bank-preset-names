-- Development proof only; not the final icon renderer or persistence API.
local ids = require("bank/ids")
local slots = require("presets/slots")
local probe = {}
local state
local lastMessage

local function report(message)
    if message ~= lastMessage then
        print("[Preset icon probe] " .. message)
        lastMessage = message
    end
end

function probe.restore()
    if not state then return end
    local old = state
    state = nil
    -- Old components may already have been disposed by a bank rebuild.
    pcall(function()
        if not old.number.isRestricted and old.number.content == "" then
            old.number.content = old.original
        end
    end)
    pcall(function() old.sprite:Destroy() end)
end

local function apply(config)
    if not slots.valid(config.slot, slots.count) then error("Slot must be 1..18") end
    local spriteID = id.Sprite[config.sprite]
    if type(spriteID) ~= "number" or spriteID < 0 then error("Sprite constant unavailable: " .. tostring(config.sprite)) end
    if type(config.width) ~= "number" or config.width <= 0
        or type(config.height) ~= "number" or config.height <= 0 then
        error("Asset dimensions must be positive")
    end
    local number = ui.Interfaces:GetComponent(ids.interface, ids.presetLabel,
        ids.category, (config.slot - 1) * ids.labelsPerPreset + ids.numberLabelOffset)
    if not number or number.isRestricted or number.type ~= ui.ComponentType.LABEL then
        probe.restore()
        report("Waiting for an unrestricted number label")
        return
    end
    local parent = number.parent
    if not parent or parent.isRestricted then error("Number parent unavailable or restricted") end
    if state and (state.number ~= number or state.parent ~= parent or state.id ~= spriteID) then
        probe.restore()
    end
    if not state then
        local sprite = ui.Sprite.new(parent)
        if not sprite then error("Native parent rejected sprite creation") end
        -- Retain immediately so a later setup failure still destroys the sprite.
        state = { number = number, parent = parent, sprite = sprite,
            original = number.content, id = spriteID }
        sprite.clickthrough = true
        sprite.enabled = false
        sprite.rgba = 0xFFFFFFFF
        sprite.sprite = spriteID
    elseif number.content ~= "" then
        state.original = number.content
    end
    local scale = math.min(number.width / config.width, number.height / config.height, 1)
    if scale <= 0 then error("Number label has no drawable bounds") end
    local width = math.max(1, math.floor(config.width * scale))
    local height = math.max(1, math.floor(config.height * scale))
    state.sprite:SetSize(width, height)
    state.sprite:SetPos(number.x + math.floor((number.width - width) / 2),
        number.y + math.floor((number.height - height) / 2))
    state.sprite.hidden = not number.visibleGlobal
    if state.sprite.spriteID ~= spriteID then error("Sprite assignment was not accepted") end
    -- Clear text, not visibility: hiding an ancestor could also hide the sprite.
    -- The number stays intact until all sprite setup operations have succeeded.
    number.content = ""
    report("Rendering " .. config.sprite .. " on preset " .. config.slot)
end

function probe.update(config)
    if not config.enabled then
        probe.restore()
        return
    end
    local ok, err = pcall(apply, config)
    if not ok then
        probe.restore()
        report("Number retained; " .. tostring(err))
    end
end

return probe
