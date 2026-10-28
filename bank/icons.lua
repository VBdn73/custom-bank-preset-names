local catalogue = require("presets/icon_catalogue")
local slots = require("presets/slots")
local renderer = {}
local states, errors = {}, {}
-- Native number labels sit close to the row border. Give replacement icons
-- a small inset like the editor preview, without moving native labels or hits.
local horizontalInset = 4
-- Keep injected children out of the native category-0 ID sequence. Both IDs
-- remain within the client's accepted range, as in the compact renderer.
local spriteCategory = 1

local function editable(number)
    return number and not number.isRestricted and number.type == ui.ComponentType.LABEL
end

local function release(slot)
    local state = states[slot]
    states[slot] = nil
    if not state then return end
    -- A bank rebuild may already have disposed the old components. Never undo
    -- newer native text, or modify labels that have become restricted.
    pcall(function()
        if editable(state.number) and state.number.content == "" then
            state.number.content = state.original
        end
    end)
    pcall(function() state.sprite:Destroy() end)
end

local function resolve(binding)
    return ui.Interfaces:GetComponent(binding.interfaceID, binding.staticID,
        binding.categoryID, binding.dynamicID)
end

local function apply(binding, store)
    local slot = binding.slot
    local spriteID, entry = catalogue.resolve(store.get(slot))
    local number = resolve(binding)
    if not spriteID or not editable(number) then release(slot); return end
    local parent = number.parent
    if not parent or parent.isRestricted then release(slot); return end
    local state = states[slot]
    if state and (state.number ~= number or state.parent ~= parent or state.spriteID ~= spriteID) then
        release(slot)
        state = nil
    end
    if not state then
        local sprite = ui.Sprite.new(parent, spriteCategory, slot)
        assert(sprite, "Native number parent rejected sprite creation.")
        -- Track immediately: any later setup failure must destroy our sprite.
        state = { number = number, parent = parent, sprite = sprite,
            spriteID = spriteID, original = number.content }
        states[slot] = state
        sprite.clickthrough = true
        sprite.enabled = false
        sprite.sprite = spriteID
        sprite.rgba = 0xFFFFFFFF
    elseif number.content ~= "" then
        -- Native scripts may redraw the number after Logic, including selection.
        state.original = number.content
    end
    local scale = math.min(number.width / entry.width, number.height / entry.height, 1)
    assert(scale > 0, "Number label has no drawable bounds.")
    local w = math.max(1, math.floor(entry.width * scale))
    local h = math.max(1, math.floor(entry.height * scale))
    state.sprite:SetSize(w, h)
    state.sprite:SetPos(number.x + horizontalInset + math.floor((number.width - w) / 2),
        number.y + math.floor((number.height - h) / 2))
    state.sprite.hidden = not number.visibleGlobal
    -- Selection scripts can reorder native sibling backgrounds after creation.
    -- Raise only our non-interactive child, without changing native hit targets.
    state.sprite:MoveToFront()
    assert(state.sprite.spriteID == spriteID, "Native sprite assignment was not accepted.")
    -- Sibling placement inherits native list scrolling/clipping without changing
    -- hit targets, row backgrounds, visibility, or input hooks. Only clear text
    -- after construction, resource assignment and layout have succeeded.
    if number.content ~= "" then number.content = "" end
end

function renderer.update(bindings, store)
    local active = {}
    for _, binding in ipairs(bindings or {}) do
        local slot = binding.slot
        if slots.valid(slot) then
            active[slot] = true
            local ok, err = pcall(apply, binding, store)
            if not ok then
                release(slot)
                local message = tostring(err)
                if errors[slot] ~= message then
                    print(("[Preset icons] Preset %d: number retained; %s"):format(slot, message))
                    errors[slot] = message
                end
            else
                errors[slot] = nil
            end
        end
    end
    for slot in pairs(states) do
        if not active[slot] then release(slot) end
    end
end

function renderer.restore()
    for slot in pairs(states) do release(slot) end
    states, errors = {}, {}
end

return renderer
