local appearance = {}
local states = {}
local function resolve(binding)
    return ui.Interfaces:GetComponent(517, binding.staticID, 0, binding.dynamicID)
end
function appearance.update(bindings, colours)
    for index, binding in ipairs(bindings) do
        local component = resolve(binding)
        if component and not component.isRestricted and component.type == ui.ComponentType[binding.kind] then
            local state = states[index]
            if not state or state.component ~= component then
                state = { component = component, original = component.rgba }
                states[index] = state
            elseif component.rgba ~= state.applied then
                state.original = component.rgba
            end
            local desired = colours.rgba(binding.slot, binding.colourKind) or state.original
            if component.rgba ~= desired then component.rgba = desired end
            state.applied = desired
        else
            states[index] = nil
        end
    end
end
function appearance.restore(bindings)
    for index, binding in ipairs(bindings) do
        local state, component = states[index], resolve(binding)
        if state and state.component == component and not component.isRestricted
            and component.type == ui.ComponentType[binding.kind] and component.rgba == state.applied then
            component.rgba = state.original
        end
    end
    states = {}
end
return appearance
