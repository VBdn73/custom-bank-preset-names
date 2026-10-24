local bank = {}
local states = {}

local function resolve(binding)
    if binding.categoryID ~= nil and binding.dynamicID ~= nil then
        return ui.Interfaces:GetComponent(binding.interfaceID, binding.staticID,
            binding.categoryID, binding.dynamicID)
    end
    return ui.Interfaces:GetComponent(binding.interfaceID, binding.staticID)
end

function bank.update(bindings, names)
    for index, binding in ipairs(bindings) do
        local component = resolve(binding)
        if component and component.type == ui.ComponentType.LABEL and not component.isRestricted then
            local state = states[index]
            if not state or state.component ~= component then
                state = { component = component, original = component.content }
                states[index] = state
            elseif component.content ~= state.applied then
                -- Preserve new predefined names supplied by the game while overridden.
                state.original = component.content
            end
            local target = names.get(binding.slot) or state.original
            if component.content ~= target then
                component.content = target
            end
            state.applied = target
        else
            states[index] = nil
        end
    end
end

function bank.restore(bindings)
    for index, binding in ipairs(bindings) do
        local state = states[index]
        local component = resolve(binding)
        if state and component and component == state.component
            and component.type == ui.ComponentType.LABEL and component.content == state.applied then
            component.content = state.original
        end
    end
    states = {}
end

return bank
