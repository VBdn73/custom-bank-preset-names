-- Reuse the hidden name row's space without changing the bank's outer bounds.
local bankIds = require("bank/ids")
local layout = {}
local states = {}
local rules = {
    [bankIds.presetListBackground] = { height = 1 },
    [bankIds.presetList] = { height = 1 }, -- Scroll viewport
    [bankIds.presetListScrollbar] = { height = 1 },
    -- Keep the preset settings parent itself unchanged: its native children use
    -- fixed offsets and are clipped to it, rather than following its bottom.
    [bankIds.presetSettingsBackground] = { height = -1, y = 1 }, -- Visual border only
    [bankIds.inventoryTickboxes] = { height = 0, y = 1 }, -- Use the hidden name row
}
local sizeFields = { "width", "height", "widthParentPc", "heightParentPc" }
local positionFields = { "x", "y", "xParentPc", "yParentPc", "xSelfPc", "ySelfPc" }

local function equal(a, b, fields)
    if not a or not b then return false end
    for _, field in ipairs(fields) do
        if a[field] ~= b[field] then return false end
    end
    return true
end

local function resolve(staticID)
    local component = ui.Interfaces:GetComponent(bankIds.interface, staticID)
    return component and not component.isRestricted and component or nil
end

function layout.restore()
    for staticID, state in pairs(states) do
        local component = resolve(staticID)
        if component == state.component then
            if equal(component.size, state.appliedSize, sizeFields) then component.size = state.size end
            if state.position and equal(component.position, state.appliedPosition, positionFields) then
                component.position = state.position
            end
        end
    end
    states = {}
end

function layout.update(hidden, dropdown)
    if not hidden then layout.restore(); return end
    if not dropdown or dropdown.isRestricted or dropdown.height <= 0 then return end
    local space = dropdown.height + 8

    -- Snapshot all original layouts before writing any parent layouts.
    for staticID, rule in pairs(rules) do
        local component = resolve(staticID)
        if component then
            local state = states[staticID]
            if not state or state.component ~= component then
                state = { component = component }
                states[staticID] = state
            end
            if not equal(component.size, state.appliedSize, sizeFields) then
                state.size = ui.Size.new(component.size)
            end
            if rule.y and not equal(component.position, state.appliedPosition, positionFields) then
                state.position = ui.Pos.new(component.position)
            end
        else
            states[staticID] = nil
        end
    end

    local function inheritedHeight(component, depth)
        if not component or component.isRestricted or depth > 16 then return 0 end
        local state = states[component.staticID]
        if state and state.component == component then return rules[component.staticID].height * space end
        return component.size.heightParentPc * inheritedHeight(component.parent, depth + 1)
    end
    for staticID, state in pairs(states) do
        local component, rule = state.component, rules[staticID]
        local parentDelta = inheritedHeight(component.parent, 0)
        local size = ui.Size.new(state.size)
        -- Some bank versions nest the scrollbar inside the viewport. Do not
        -- enlarge it twice when its percentage-based size already follows it.
        size.height = size.height + rule.height * space - size.heightParentPc * parentDelta
        if not equal(component.size, size, sizeFields) then component.size = size end
        state.appliedSize = ui.Size.new(size)
        if state.position then
            local position = ui.Pos.new(state.position)
            position.y = position.y + rule.y * space - position.yParentPc * parentDelta
                - position.ySelfPc * rule.height * space
            if not equal(component.position, position, positionFields) then component.position = position end
            state.appliedPosition = ui.Pos.new(position)
        end
    end
end

return layout
