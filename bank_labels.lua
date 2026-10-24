local bankLabels = {}
-- Keyed by binding index, with both the game's text and our last replacement.
local labelStates = {}

local function resolveComponent(binding)
    if binding.categoryID ~= nil and binding.dynamicID ~= nil then
        return ui.Interfaces:GetComponent(
            binding.interfaceID, binding.staticID, binding.categoryID, binding.dynamicID
        )
    end
    return ui.Interfaces:GetComponent(binding.interfaceID, binding.staticID)
end

local function isEditableLabel(component)
    return component and component.type == ui.ComponentType.LABEL and not component.isRestricted
end

function bankLabels.update(bindings, names)
    for index, binding in ipairs(bindings) do
        local component = resolveComponent(binding)
        if isEditableLabel(component) then
            local state = labelStates[index]
            if not state or state.component ~= component then
                state = { component = component, originalText = component.content }
                labelStates[index] = state
            elseif component.content ~= state.appliedText then
                -- Preserve new predefined names supplied by the game while overridden.
                state.originalText = component.content
            end
            local desiredText = names.get(binding.slot) or state.originalText
            if component.content ~= desiredText then
                component.content = desiredText
            end
            state.appliedText = desiredText
        else
            labelStates[index] = nil
        end
    end
end

function bankLabels.restore(bindings)
    for index, binding in ipairs(bindings) do
        local state = labelStates[index]
        local component = resolveComponent(binding)
        -- Only undo our own latest write, never a newer change from the game.
        if state and component and component == state.component
            and component.type == ui.ComponentType.LABEL and component.content == state.appliedText then
            component.content = state.originalText
        end
    end
    labelStates = {}
end

return bankLabels
