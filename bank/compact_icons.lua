local catalogue = require("presets/icon_catalogue")
local ids = require("bank/ids")
local renderer = {}
local states, errors = {}, {}
-- Explicit namespace for plugin children. Omitting these constructor arguments
-- inherits the native category and auto-increments its dynamic IDs.
-- Keep both constructor IDs within the client's accepted 0..256 range.
-- Category 1 is separate from the verified native labels in category 0;
-- creation must still fail safely if an address is already occupied.
local spriteCategory = 1
local backgroundInset = 2

local function editable(number)
    return number and not number.isRestricted and number.type == ui.ComponentType.LABEL
end

local function release(index)
    local state = states[index]
    states[index] = nil
    if not state then return end
    pcall(function()
        -- Restore only colour still owned by us. Never write native text.
        if editable(state.number) and state.number.rgba == state.applied then
            state.number.rgba = state.original
        end
    end)
    pcall(function() state.sprite:Destroy() end)
    if state.background then pcall(function() state.background:Destroy() end) end
    for _, cap in ipairs(state.backgroundCaps or {}) do pcall(function() cap:Destroy() end) end
end

local function displayedSlot(text, index)
    if type(text) ~= "string" or not text:match("^%d+$") then return nil end
    local slot = tonumber(text)
    if slot == index or slot == index + ids.compactPresetButtonCount then return slot end
end

local function apply(binding, store, colours)
    local index = binding.buttonIndex
    local number = ui.Interfaces:GetComponent(binding.interfaceID, binding.staticID,
        binding.categoryID, binding.dynamicID)
    if not editable(number) then release(index); return end
    local parent = number.parent
    local slot = displayedSlot(number.content, index)
    if not slot or not parent or parent.isRestricted then release(index); return end
    local spriteID, entry = catalogue.resolve(store.get(slot))
    if not spriteID then release(index); return end
    local state = states[index]
    if state and (state.number ~= number or state.parent ~= parent
        or state.slot ~= slot or state.spriteID ~= spriteID) then
        release(index)
        state = nil
    end
    if not state then
        local sprite = ui.Sprite.new(parent, spriteCategory, index)
        assert(sprite, "Native compact number parent rejected sprite creation.")
        state = { number = number, parent = parent, slot = slot, sprite = sprite,
            spriteID = spriteID, original = number.rgba }
        states[index] = state
        sprite.clickthrough = true
        sprite.enabled = false
        sprite.sprite = spriteID
        sprite.rgba = 0xFFFFFFFF
    elseif number.rgba ~= state.applied then
        state.original = number.rgba
    end
    state.text = number.content
    assert(number.width > 0 and number.height > 0, "Compact number label has no drawable bounds.")
    local scale = math.min(24 / entry.width, 24 / entry.height,
        number.width / entry.width, number.height / entry.height, 1)
    local w, h = math.max(1, math.floor(entry.width * scale)), math.max(1, math.floor(entry.height * scale))
    state.sprite:SetSize(w, h)
    state.sprite:SetPos(number.x + math.floor((number.width - w) / 2),
        number.y + math.floor((number.height - h) / 2))
    -- visibleGlobal on the number can become false because *we* made its
    -- colour transparent on the previous Draw. Using it here feeds our own
    -- suppression back into sibling visibility and can leave an empty button.
    -- Follow native local hiding and the unsuppressed parent's visibility.
    state.sprite.hidden = number.hidden == true or parent.visibleGlobal == false
    local background = colours and colours.rgba(slot, "background")
    if background then
        if not state.background then
            state.background = ui.Rectangle.new(parent, spriteCategory + 1, index)
            assert(state.background, "Native compact number parent rejected background creation.")
            state.background.fill = true
            state.background.clickthrough = true
            state.background.enabled = false
            state.backgroundCaps = {}
            for capIndex = 1, 2 do
                local cap = ui.Rectangle.new(parent, spriteCategory + 1, index + capIndex * 9)
                assert(cap, "Native compact number parent rejected background corner creation.")
                state.backgroundCaps[capIndex] = cap
                cap.fill, cap.clickthrough, cap.enabled = true, true, false
            end
        end
        -- The native number bounds include the button's bevel. Our sibling is
        -- raised above that frame, so keep the fill inside its inner edge.
        state.background:SetSize(math.max(1, number.width - backgroundInset * 2),
            math.max(1, number.height - backgroundInset * 2 - 2))
        state.background:SetPos(number.x + backgroundInset, number.y + backgroundInset + 1)
        state.background.rgba = background
        state.background.hidden = state.sprite.hidden
        state.background:MoveToFront()
        -- Narrow one-pixel end strips leave the four corner pixels clear.
        -- Non-overlapping rectangles preserve the saved colour's alpha.
        for capIndex, cap in ipairs(state.backgroundCaps) do
            cap:SetSize(math.max(1, number.width - backgroundInset * 2 - 2), 1)
            cap:SetPos(number.x + backgroundInset + 1,
                number.y + (capIndex == 1 and backgroundInset or number.height - backgroundInset - 1))
            cap.rgba, cap.hidden = background, state.sprite.hidden
            cap:MoveToFront()
        end
    elseif state.background then
        state.background:Destroy()
        state.background = nil
        for _, cap in ipairs(state.backgroundCaps) do cap:Destroy() end
        state.backgroundCaps = nil
    end
    -- Native redraws may add/reorder sibling backgrounds after our child was
    -- attached. Raise only our clickthrough sprite, never native components.
    state.sprite:MoveToFront()
    assert(state.sprite.spriteID == spriteID, "Native compact sprite assignment was not accepted.")
    -- visibleGlobal describes UI-tree visibility, not asset readiness. Do not
    -- use it as a loading gate. Report persistent tree invisibility separately.
    if not state.sprite.hidden and parent.visibleGlobal == true
        and state.sprite.visibleGlobal == false then
        state.invisibleFrames = (state.invisibleFrames or 0) + 1
        if state.invisibleFrames >= 3 and not state.visibilityWarned then
            print(("[Compact preset icons] Button %d, preset %d, sprite %d: "
                .. "tree visibility remains false (local=%s, hidden=%s, category=%s, dynamic=%s).")
                :format(index, slot, spriteID, tostring(state.sprite.visible),
                    tostring(state.sprite.hidden), tostring(state.sprite.categoryID),
                    tostring(state.sprite.dynamicID)))
            state.visibilityWarned = true
        end
    else
        state.invisibleFrames = 0
    end
    -- Keep native content readable on every Draw, including same-object page
    -- switches. Label-only alpha must be verified against native shadows live.
    state.applied = state.original & 0xFFFFFF00
    number.rgba = state.applied
    assert(number.rgba == state.applied, "Compact number transparency was not accepted.")
end

function renderer.update(bindings, store, colours)
    local active = {}
    for _, binding in ipairs(bindings or {}) do
        local index = binding.buttonIndex
        if type(index) == "number" and index % 1 == 0
            and index >= 1 and index <= ids.compactPresetButtonCount then
            active[index] = true
            local ok, err = pcall(apply, binding, store, colours)
            if not ok then
                release(index)
                local message = tostring(err)
                if errors[index] ~= message then
                    print(("[Compact preset icons] Button %d: number retained; %s"):format(index, message))
                    errors[index] = message
                end
            else
                errors[index] = nil
            end
        end
    end
    for index in pairs(states) do
        if not active[index] then release(index) end
    end
end

function renderer.restore()
    for index in pairs(states) do release(index) end
    states, errors = {}, {}
end

return renderer
